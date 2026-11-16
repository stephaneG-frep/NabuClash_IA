import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nabuclash_ai/ai/ai_error.dart';
import 'package:nabuclash_ai/ai/ai_provider.dart';
import 'package:nabuclash_ai/models/domain.dart';
import 'package:nabuclash_ai/services/app_state.dart';
import 'package:nabuclash_ai/services/prompt_builder.dart';
import 'package:nabuclash_ai/services/reply_parser.dart';
import 'package:nabuclash_ai/storage/local_store.dart';

class MemorySecrets implements SecretStore {
  final values = <String, String>{};
  @override
  Future<String?> read(String id) async => values[id];
  @override
  Future<void> write(String id, String value) async {
    values[id] = value;
  }

  @override
  Future<void> delete(String id) async {
    values.remove(id);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'Prompts include every contextual control and original data on refinement',
    () {
      const s = Situation(
        text: 'Ma voiture est préhistorique',
        context: 'Devant les autres',
        person: 'Patron',
        setting: 'Travail',
        style: 'Diplomatique',
        intensity: 5,
      );
      final p = PromptBuilder.replies(
        s,
        modifier: 'Plus court',
        previous: [const Reply('ancienne', 'style', 3)],
      );
      for (final v in [
        'Ma voiture',
        'Devant les autres',
        'Patron',
        'Travail',
        'Diplomatique',
        '5',
        'Plus court',
        'ancienne',
      ]) {
        expect(p, contains(v));
      }
      expect(PromptBuilder.system('Absurde', 'English'), contains('Absurde'));
      expect(PromptBuilder.system('Absurde', 'English'), contains('English'));
      expect(
        PromptBuilder.replies(s, rescue: true),
        contains('Réponse tranquille'),
      );
      expect(
        PromptBuilder.dojoReview('remarque', 'réponse'),
        contains('élégance'),
      );
    },
  );
  test('Parses fenced JSON, imperfect fields and plain text, rejects raw broken JSON', () {
    expect(
      ReplyParser.parse(
        '```json\n{"replies":[{"text":"Bonjour","intensity":9}]}\n```',
      ).single.intensity,
      5,
    );
    expect(
      ReplyParser.parse(
        'Voici : {"replies":[{"text":"Bien vu","style":"Subtil","intensity":2}]}',
      ).single.text,
      'Bien vu',
    );
    expect(ReplyParser.parse('1. Un\n2. Deux').length, 2);
    expect(
      () => ReplyParser.parse('{"replies":[oops'),
      throwsA(isA<AiError>()),
    );
    expect(() => ReplyParser.parse('{"replies":[]}'), throwsA(isA<AiError>()));
    expect(() => ReplyParser.parse(''), throwsA(isA<AiError>()));
  });
  for (final code in [400, 401, 403, 404, 422, 429, 500, 503]) {
    test('HTTP $code yields a friendly error without secrets', () {
      final r = RequestOptions(path: 'https://example.test');
      final e = AiError.from(
        DioException(
          requestOptions: r,
          response: Response(
            requestOptions: r,
            statusCode: code,
            data: 'SECRET',
          ),
          type: DioExceptionType.badResponse,
        ),
      );
      expect(e.message, isNot(contains('SECRET')));
      expect(e.message, isNot(contains('Exception')));
    });
  }
  test('Timeout, cancellation and network errors are distinct', () {
    expect(
      AiError.from(
        DioException(
          requestOptions: RequestOptions(),
          type: DioExceptionType.receiveTimeout,
        ),
      ).message,
      contains('temps'),
    );
    expect(
      AiError.from(
        DioException(
          requestOptions: RequestOptions(),
          type: DioExceptionType.cancel,
        ),
      ).message,
      contains('annulée'),
    );
    expect(
      AiError.from(
        DioException(
          requestOptions: RequestOptions(),
          type: DioExceptionType.connectionError,
        ),
      ).message,
      contains('Internet'),
    );
  });
  test('Local persistence, favorites, conversation, provider switch and secure deletion', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final secrets = MemorySecrets();
    final app = AppState(LocalStore(prefs), secrets);
    await app.initialize();
    await app.configure(ProviderId.mistral, 'test-secret', 'model-a', true);
    await app.select(ProviderId.mistral);
    app.personality = '🌀 Absurde';
    app.language = 'English';
    final r = SavedReply(
      id: 'id',
      date: 'date',
      provider: 'Mistral',
      model: 'model-a',
      situation: const Situation(text: 'situation'),
      reply: const Reply('reply', 'style', 3),
    );
    app.history.add(r);
    await app.favorite(r);
    final c = await app.newChat();
    c.messages.add(const Message('user', 'Bonjour'));
    await app.persist();
    expect(prefs.getString('nabuclash.v1'), isNot(contains('test-secret')));
    final restored = AppState(LocalStore(prefs), secrets);
    await restored.initialize();
    expect(restored.selected, ProviderId.mistral);
    expect(restored.history.single.favorite, true);
    expect(restored.chats.single.messages.single.text, 'Bonjour');
    expect(restored.language, 'English');
    await restored.configure(
      ProviderId.gemini,
      'other-secret',
      'model-b',
      false,
    );
    await restored.select(ProviderId.gemini);
    expect(restored.selected, ProviderId.gemini);
    await restored.removeProvider(ProviderId.mistral);
    expect(await secrets.read('mistral'), null);
    await restored.deleteReply(restored.history.single);
    await restored.deleteChat(restored.chats.single);
    expect(restored.history, isEmpty);
    expect(restored.chats, isEmpty);
  });
  for (final id in ProviderId.values) {
    test(
      '${id.name}: official request, context and response mapping',
      () async {
        final dio = Dio();
        RequestOptions? sent;
        dio.interceptors.add(
          InterceptorsWrapper(
            onRequest: (r, h) {
              sent = r;
              h.resolve(
                Response(
                  requestOptions: r,
                  statusCode: 200,
                  data: switch (id) {
                    ProviderId.anthropic => {
                      'content': [
                        {'type': 'text', 'text': 'réponse'},
                      ],
                    },
                    ProviderId.gemini => {
                      'candidates': [
                        {
                          'content': {
                            'parts': [
                              {'text': 'réponse'},
                            ],
                          },
                        },
                      ],
                    },
                    _ => {
                      'choices': [
                        {
                          'message': {'content': 'réponse'},
                        },
                      ],
                    },
                  },
                ),
              );
            },
          ),
        );
        final provider = ProviderRegistry(dio).get(id);
        final result = await provider.conversation(
          key: 'test-key',
          model: 'test-model',
          system: 'system',
          messages: [
            const Message('user', 'first'),
            const Message('assistant', 'context'),
            const Message('user', 'second'),
          ],
          token: CancelToken(),
          structured: true,
        );
        expect(result, 'réponse');
        expect(jsonEncode(sent!.data), contains('context'));
        expect(sent!.uri.scheme, 'https');
        expect(sent!.uri.toString(), isNot(contains('test-key')));
        if (id == ProviderId.anthropic) {
          expect(sent!.headers['x-api-key'], 'test-key');
          expect(sent!.path, endsWith('/messages'));
        } else if (id == ProviderId.gemini) {
          expect(sent!.headers['x-goog-api-key'], 'test-key');
          expect(
            sent!.data['generationConfig']['responseMimeType'],
            'application/json',
          );
        } else {
          expect(sent!.headers['Authorization'], 'Bearer test-key');
          expect(
            sent!.path,
            endsWith(
              id == ProviderId.perplexity ? '/v1/sonar' : '/chat/completions',
            ),
          );
          if (id == ProviderId.perplexity) {
            expect(sent!.data['disable_search'], true);
            expect(sent!.data['response_format']['type'], 'json_schema');
          }
        }
      },
    );
  }
  test(
    'Missing keys and empty replies never produce fabricated answers',
    () async {
      final dio = Dio();
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (r, h) => h.resolve(
            Response(requestOptions: r, statusCode: 200, data: {'choices': []}),
          ),
        ),
      );
      final p = ProviderRegistry(dio).get(ProviderId.openai);
      expect(
        () => p.conversation(
          key: '',
          model: 'x',
          system: 's',
          messages: [],
          token: CancelToken(),
        ),
        throwsA(isA<AiError>()),
      );
      expect(
        () => p.conversation(
          key: 'key',
          model: 'x',
          system: 's',
          messages: [],
          token: CancelToken(),
        ),
        throwsA(isA<AiError>()),
      );
    },
  );
  test('Generation saves real adapter output and model provenance', () async {
    SharedPreferences.setMockInitialValues({});
    final dio = Dio();
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (r, h) => h.resolve(
          Response(
            requestOptions: r,
            statusCode: 200,
            data: {
              'choices': [
                {
                  'message': {
                    'content': '{"replies":[{"text":"sortie du transport de test","style":"Subtil","intensity":3}]}',
                  },
                },
              ],
            },
          ),
        ),
      ),
    );
    final app = AppState(
      LocalStore(await SharedPreferences.getInstance()),
      MemorySecrets(),
      providers: ProviderRegistry(dio),
    );
    await app.configure(ProviderId.openai, 'test', 'test-model', true);
    final replies = await app.generate(
      const Situation(text: 'original'),
      CancelToken(),
    );
    expect(replies.single.reply.text, 'sortie du transport de test');
    expect(app.history.single.situation.text, 'original');
    expect(app.history.single.model, 'test-model');
  });
}
