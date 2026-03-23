import 'package:dotenv/dotenv.dart';
import 'package:test/test.dart';

import '../lib/openai_runtime_config.dart';

void main() {
  group('OpenAiRuntimeConfig fallback policy', () {
    test('allows invalid-key fallback in dev profile', () {
      final env = DotEnv()..addAll({'ENVIRONMENT': 'development'});
      final config = OpenAiRuntimeConfig(env);

      expect(
        config.shouldUseFallbackForInvalidApiKey(
          statusCode: 401,
          responseBody: '{"error":{"code":"invalid_api_key"}}',
        ),
        isTrue,
      );
    });

    test('blocks invalid-key fallback in prod profile', () {
      final env = DotEnv()..addAll({'ENVIRONMENT': 'production'});
      final config = OpenAiRuntimeConfig(env);

      expect(
        config.shouldUseFallbackForInvalidApiKey(
          statusCode: 401,
          responseBody: '{"error":{"code":"invalid_api_key"}}',
        ),
        isFalse,
      );
    });

    test('does not fallback for non-auth errors', () {
      final env = DotEnv()..addAll({'ENVIRONMENT': 'development'});
      final config = OpenAiRuntimeConfig(env);

      expect(
        config.shouldUseFallbackForInvalidApiKey(
          statusCode: 500,
          responseBody: '{"error":"upstream timeout"}',
        ),
        isFalse,
      );
    });
  });
}
