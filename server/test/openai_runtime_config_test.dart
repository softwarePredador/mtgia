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

    test('uses bounded generate timeout override', () {
      final env = DotEnv()
        ..addAll({
          'ENVIRONMENT': 'staging',
          'OPENAI_TIMEOUT_GENERATE_SECONDS': '1',
        });
      final config = OpenAiRuntimeConfig(env);

      expect(
        config.timeoutFor(
          key: 'OPENAI_TIMEOUT_GENERATE_SECONDS',
          fallback: const Duration(seconds: 20),
          stagingFallback: const Duration(seconds: 10),
          min: const Duration(seconds: 3),
          max: const Duration(seconds: 90),
        ),
        equals(const Duration(seconds: 3)),
      );
    });

    test('uses profile fallback for integer limits', () {
      final env = DotEnv()..addAll({'ENVIRONMENT': 'production'});
      final config = OpenAiRuntimeConfig(env);

      expect(
        config.intFor(
          key: 'OPENAI_MAX_TOKENS_GENERATE',
          fallback: 2200,
          prodFallback: 3800,
          max: 6000,
        ),
        equals(3800),
      );
    });
  });
}
