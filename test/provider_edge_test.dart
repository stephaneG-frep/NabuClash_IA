import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nabuclash_ai/ai/ai_error.dart';
import 'package:nabuclash_ai/ai/ai_provider.dart';
import 'package:nabuclash_ai/models/domain.dart';

void main() {
  test('Gemini paginates models and filters non-generation models', () async {
    final dio = Dio();
    var calls = 0;
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (r, h) {
          calls++;
          expect(r.headers['x-goog-api-key'], 'fixture');
          if (calls == 1) {
            h.resolve(
              Response(
                requestOptions: r,
                statusCode: 200,
                data: {
                  'models': [
                    {
                      'name': 'models/text-one',
                      'supportedGenerationMethods': ['generateContent'],
                    },
                    {
                      'name': 'models/embed-only',
                      'supportedGenerationMethods': ['embedContent'],
                    },
                  ],
                  'nextPageToken': 'page-two',
                },
              ),
            );
          } else {
            expect(r.queryParameters['pageToken'], 'page-two');
            h.resolve(
              Response(
                requestOptions: r,
                statusCode: 200,
                data: {
                  'models': [
                    {
                      'name': 'models/text-two',
                      'supportedGenerationMethods': ['generateContent'],
                    },
                  ],
                },
              ),
            );
          }
        },
      ),
    );
    expect(
      await ProviderRegistry(dio)
          .get(ProviderId.gemini)
          .models('fixture', CancelToken()),
      ['text-one', 'text-two'],
    );
    expect(calls, 2);
  });
  test('Anthropic paginates via after_id', () async {
    final dio = Dio();
    var calls = 0;
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (r, h) {
          calls++;
          h.resolve(
            Response(
              requestOptions: r,
              statusCode: 200,
              data: calls == 1
                  ? {
                      'data': [
                        {'id': 'first'},
                      ],
                      'has_more': true,
                      'last_id': 'first',
                    }
                  : {
                      'data': [
                        {'id': 'second'},
                      ],
                      'has_more': false,
                    },
            ),
          );
          if (calls == 2) {
            expect(r.queryParameters['after_id'], 'first');
          }
        },
      ),
    );
    expect(
      await ProviderRegistry(dio)
          .get(ProviderId.anthropic)
          .models('fixture', CancelToken()),
      ['first', 'second'],
    );
  });
  test(
    'Perplexity model catalogue does not pretend to test credentials',
    () async {
      final dio = Dio();
      var called = false;
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (r, h) {
            called = true;
            h.reject(DioException(requestOptions: r));
          },
        ),
      );
      expect(
        await ProviderRegistry(dio)
            .get(ProviderId.perplexity)
            .models('fixture', CancelToken()),
        contains('sonar'),
      );
      expect(called, false);
    },
  );
  for (final id in ProviderId.values) {
    test(
      '${id.name} JSON disabled leaves plain generation and chat unaffected',
      () async {
        final dio = Dio();
        dio.interceptors.add(
          InterceptorsWrapper(
            onRequest: (r, h) {
              final body = r.data as Map;
              expect(body.containsKey('response_format'), false);
              expect(body.containsKey('output_config'), false);
              if (id == ProviderId.gemini) {
                expect(
                  (body['generationConfig'] as Map).containsKey(
                    'responseMimeType',
                  ),
                  false,
                );
              }
              h.resolve(
                Response(
                  requestOptions: r,
                  statusCode: 200,
                  data: switch (id) {
                    ProviderId.gemini => {
                      'candidates': [
                        {
                          'content': {
                            'parts': [
                              {'text': 'ok'},
                            ],
                          },
                        },
                      ],
                    },
                    ProviderId.anthropic => {
                      'content': [
                        {'type': 'text', 'text': 'ok'},
                      ],
                    },
                    _ => {
                      'choices': [
                        {
                          'message': {'content': 'ok'},
                        },
                      ],
                    },
                  },
                ),
              );
            },
          ),
        );
        expect(
          await ProviderRegistry(dio)
              .get(id)
              .conversation(
                key: 'fixture',
                model: 'model',
                system: 'system',
                messages: [const Message('user', 'prompt')],
                token: CancelToken(),
              ),
          'ok',
        );
      },
    );
  }
  test(
    'HTTP cancellation is translated, without a fabricated fallback',
    () async {
      final dio = Dio();
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (r, h) => h.reject(
            DioException(requestOptions: r, type: DioExceptionType.cancel),
          ),
        ),
      );
      expect(
        () => ProviderRegistry(dio)
            .get(ProviderId.mistral)
            .conversation(
              key: 'fixture',
              model: 'model',
              system: 'system',
              messages: [const Message('user', 'prompt')],
              token: CancelToken(),
            ),
        throwsA(
          isA<AiError>().having(
            (e) => e.message,
            'message',
            contains('annulée'),
          ),
        ),
      );
    },
  );
}
