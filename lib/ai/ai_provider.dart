import 'package:dio/dio.dart';

import '../models/domain.dart';
import 'ai_error.dart';
import 'reply_schema.dart';

abstract class AIProvider {
  Future<List<String>> models(String key, CancelToken token);
  Future<String> conversation({
    required String key,
    required String model,
    required String system,
    required List<Message> messages,
    required CancelToken token,
    bool structured = false,
  });
  Future<void> test(String key, String model, CancelToken token) async {
    await conversation(
      key: key,
      model: model,
      system: 'Réponds simplement OK.',
      messages: [const Message('user', 'Test de connexion')],
      token: token,
    );
  }
}

class ProviderRegistry {
  final Dio dio;
  ProviderRegistry([Dio? client])
    : dio =
          client ??
          Dio(
            BaseOptions(
              connectTimeout: const Duration(seconds: 20),
              receiveTimeout: const Duration(seconds: 90),
              sendTimeout: const Duration(seconds: 20),
            ),
          );
  AIProvider get(ProviderId id) => OfficialProvider(id, dio);
}

class OfficialProvider extends AIProvider {
  final ProviderId id;
  final Dio dio;
  OfficialProvider(this.id, this.dio);
  String get base => switch (id) {
    ProviderId.openai => 'https://api.openai.com/v1',
    ProviderId.anthropic => 'https://api.anthropic.com/v1',
    ProviderId.gemini => 'https://generativelanguage.googleapis.com/v1beta',
    ProviderId.mistral => 'https://api.mistral.ai/v1',
    ProviderId.grok => 'https://api.x.ai/v1',
    ProviderId.perplexity => 'https://api.perplexity.ai',
  };
  Options options(String key) => Options(
    headers: {
      'Content-Type': 'application/json',
      if (id == ProviderId.anthropic) ...{
        'x-api-key': key,
        'anthropic-version': '2023-06-01',
      } else if (id == ProviderId.gemini)
        'x-goog-api-key': key
      else
        'Authorization': 'Bearer $key',
    },
  );
  @override
  Future<List<String>> models(String key, CancelToken token) async {
    // Sonar has a documented catalogue rather than a models-list endpoint.
    if (id == ProviderId.perplexity) {
      return ['sonar', 'sonar-pro', 'sonar-reasoning-pro'];
    }
    try {
      final result = <String>[];
      String? next;
      do {
        final response = await dio.get(
          '$base/models',
          options: options(key),
          cancelToken: token,
          queryParameters: {
            if (id == ProviderId.gemini) 'pageSize': 1000,
            if (id == ProviderId.anthropic) 'limit': 100,
            (id == ProviderId.gemini ? 'pageToken' : 'after_id'): ?next,
          },
        );
        final data = response.data as Map;
        for (final item
            in (data[id == ProviderId.gemini ? 'models' : 'data'] as List? ??
                [])) {
          if (id == ProviderId.gemini &&
              !(item['supportedGenerationMethods'] as List? ?? []).contains(
                'generateContent',
              )) {
            continue;
          }
          if (id == ProviderId.mistral &&
              item['capabilities']?['completion_chat'] == false) {
            continue;
          }
          final name = (item[id == ProviderId.gemini ? 'name' : 'id'] as String)
              .replaceFirst(RegExp(r'^models/'), '');
          result.add(name);
        }
        next = id == ProviderId.gemini
            ? data['nextPageToken'] as String?
            : id == ProviderId.anthropic && data['has_more'] == true
            ? data['last_id'] as String?
            : null;
      } while (next != null && next.isNotEmpty);
      result.sort();
      return result;
    } catch (e) {
      throw AiError.from(e);
    }
  }

  @override
  Future<String> conversation({
    required String key,
    required String model,
    required String system,
    required List<Message> messages,
    required CancelToken token,
    bool structured = false,
  }) async {
    if (key.trim().isEmpty) {
      throw const AiError(
        'Ajoute une clé API dans Réglages → Fournisseurs IA.',
      );
    }
    if (model.trim().isEmpty) {
      throw const AiError(
        'Choisis un modèle dans les réglages du fournisseur.',
      );
    }
    try {
      late String path;
      late Map<String, dynamic> body;
      if (id == ProviderId.anthropic) {
        path = '/messages';
        body = {
          'model': model,
          'max_tokens': 2048,
          'system': system,
          if (structured)
            'output_config': {
              'format': {'type': 'json_schema', 'schema': replySchema},
            },
          'messages': messages.map((m) => m.toJson()).toList(),
        };
      } else if (id == ProviderId.gemini) {
        path =
            '/models/${Uri.encodeComponent(model.replaceFirst(RegExp(r'^models/'), ''))}:generateContent';
        body = {
          'systemInstruction': {
            'parts': [
              {'text': system},
            ],
          },
          'contents': messages
              .map(
                (m) => {
                  'role': m.role == 'assistant' ? 'model' : 'user',
                  'parts': [
                    {'text': m.text},
                  ],
                },
              )
              .toList(),
          'generationConfig': {
            'maxOutputTokens': 4096,
            if (structured) 'responseMimeType': 'application/json',
          },
        };
      } else {
        path = id == ProviderId.perplexity ? '/v1/sonar' : '/chat/completions';
        body = {
          'model': model,
          'messages': [
            {'role': 'system', 'content': system},
            ...messages.map((m) => m.toJson()),
          ],
          if (structured &&
              (id == ProviderId.openai ||
                  id == ProviderId.mistral ||
                  id == ProviderId.grok))
            'response_format': {'type': 'json_object'},
          if (id == ProviderId.perplexity) 'disable_search': true,
          if (structured && id == ProviderId.perplexity)
            'response_format': {
              'type': 'json_schema',
              'json_schema': {'schema': replySchema},
            },
        };
      }
      final r = await dio.post(
        '$base$path',
        data: body,
        options: options(key),
        cancelToken: token,
      );
      final data = r.data as Map;
      String text;
      if (id == ProviderId.anthropic) {
        text = (data['content'] as List? ?? [])
            .where((p) => p['type'] == 'text')
            .map((p) => p['text'])
            .join('\n');
      } else if (id == ProviderId.gemini) {
        final candidates = data['candidates'] as List? ?? [];
        text = candidates.isEmpty
            ? ''
            : (candidates.first['content']?['parts'] as List? ?? [])
                  .where((p) => p['thought'] != true)
                  .map((p) => p['text'] ?? '')
                  .join('\n');
      } else {
        final choices = data['choices'] as List? ?? [];
        text = choices.isEmpty
            ? ''
            : choices.first['message']?['content'] as String? ?? '';
      }
      if (text.trim().isEmpty) {
        throw const AiError(
          'Le fournisseur a renvoyé une réponse vide ou bloquée. Reformule la situation ou change de modèle.',
        );
      }
      return text.trim();
    } catch (e) {
      throw AiError.from(e);
    }
  }
}
