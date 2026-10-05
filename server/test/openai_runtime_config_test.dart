import 'dart:io';

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

      expect(config.allowsMockFallbacks, isFalse);
      expect(
        config.shouldUseFallbackForInvalidApiKey(
          statusCode: 401,
          responseBody: '{"error":{"code":"invalid_api_key"}}',
        ),
        isFalse,
      );
    });

    test(
      'production environment cannot be downgraded by an explicit profile',
      () {
        final env =
            DotEnv()
              ..addAll({'ENVIRONMENT': 'production', 'OPENAI_PROFILE': 'dev'});
        final config = OpenAiRuntimeConfig(env);

        expect(config.profile, 'prod');
        expect(config.isProductionLike, isTrue);
        expect(config.allowsMockFallbacks, isFalse);
      },
    );

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
      final env =
          DotEnv()..addAll({
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

    test('keeps generate model configurable for staging experiments', () {
      final env =
          DotEnv()..addAll({
            'ENVIRONMENT': 'staging',
            'OPENAI_MODEL_GENERATE': 'gpt-5.4-mini',
          });
      final config = OpenAiRuntimeConfig(env);

      expect(
        config.modelFor(
          key: 'OPENAI_MODEL_GENERATE',
          fallback: 'gpt-4o-mini',
          stagingFallback: 'gpt-4o-mini',
          prodFallback: 'gpt-4o-mini',
        ),
        equals('gpt-5.4-mini'),
      );
    });

    test('production optimize defaults use the validated current model', () {
      final runtimeSource =
          File('lib/openai_runtime_config.dart').readAsStringSync();
      final exampleEnvironment = File('.env.example').readAsStringSync();

      expect(
        RegExp(r"prodFallback: 'gpt-5\.4-mini'").allMatches(runtimeSource),
        hasLength(2),
      );
      expect(runtimeSource, isNot(contains("prodFallback: 'gpt-4o'")));
      expect(
        exampleEnvironment,
        contains('OPENAI_MODEL_OPTIMIZE=gpt-5.4-mini'),
      );
      expect(
        exampleEnvironment,
        contains('OPENAI_MODEL_COMPLETE=gpt-5.4-mini'),
      );
    });
  });

  group('OpenAiRuntimeConfig base URL (D-83, BT-AI-029)', () {
    const fixed = 'https://api.openai.com/v1/chat/completions';

    OpenAiRuntimeConfig config(Map<String, String> values) =>
        OpenAiRuntimeConfig(DotEnv()..addAll(values));

    test('sem OPENAI_BASE_URL a chamada vai para a URL fixa', () {
      for (final environment in const ['development', 'staging', 'production']) {
        final value = config({'ENVIRONMENT': environment});
        expect(value.chatCompletionsUri.toString(), fixed, reason: environment);
        expect(value.ignoresBaseUrlOverride, isFalse, reason: environment);
      }
      expect(
        config({'ENVIRONMENT': 'development', 'OPENAI_BASE_URL': '  '})
            .chatCompletionsUri
            .toString(),
        fixed,
      );
    });

    test('na produção a URL é fixa, mesmo com loopback', () {
      for (final values in const [
        {'ENVIRONMENT': 'production', 'OPENAI_BASE_URL': 'http://127.0.0.1:9/v1'},
        {'ENVIRONMENT': 'prod', 'OPENAI_BASE_URL': 'http://localhost:9/v1'},
        {'OPENAI_PROFILE': 'prod', 'OPENAI_BASE_URL': 'http://[::1]:9/v1'},
        {
          'ENVIRONMENT': 'production',
          'OPENAI_PROFILE': 'dev',
          'OPENAI_BASE_URL': 'http://127.0.0.1:9/v1',
        },
      ]) {
        final value = config(values);
        expect(value.chatCompletionsUri.toString(), fixed, reason: '$values');
        expect(value.acceptedBaseUrlOverride, isNull, reason: '$values');
        expect(value.ignoresBaseUrlOverride, isTrue, reason: '$values');
      }
    });

    test('fora da produção aceita só loopback', () {
      for (final (raw, expected) in const [
        ('http://127.0.0.1:58193/v1', 'http://127.0.0.1:58193/v1/chat/completions'),
        ('http://127.0.0.1:58193/v1/', 'http://127.0.0.1:58193/v1/chat/completions'),
        ('https://127.1.2.3:8443/v1', 'https://127.1.2.3:8443/v1/chat/completions'),
        ('http://localhost:8080/v1', 'http://localhost:8080/v1/chat/completions'),
        ('http://LOCALHOST:8080', 'http://localhost:8080/chat/completions'),
        ('http://[::1]:9000/v1', 'http://[::1]:9000/v1/chat/completions'),
      ]) {
        for (final environment in const ['development', 'staging']) {
          final value = config({
            'ENVIRONMENT': environment,
            'OPENAI_BASE_URL': raw,
          });
          expect(
            value.chatCompletionsUri.toString(),
            expected,
            reason: '$environment $raw',
          );
          expect(value.ignoresBaseUrlOverride, isFalse, reason: raw);
        }
      }
    });

    test('fora do loopback, ou com forma estranha, é ignorada', () {
      for (final raw in const [
        'http://10.0.0.1:9/v1',
        'https://api.example.com/v1',
        'http://localhost.example.com/v1',
        'http://127.0.0.1.example.com/v1',
        'http://0.0.0.0:9/v1',
        'http://192.168.0.10:9/v1',
        'ftp://127.0.0.1/v1',
        'file:///tmp/v1',
        '127.0.0.1:9/v1',
        'http://usuario:senha@127.0.0.1:9/v1',
        'http://127.0.0.1:9/v1?chave=1',
        'http://127.0.0.1:9/v1#frag',
        'nao e url',
      ]) {
        final value = config({'ENVIRONMENT': 'development', 'OPENAI_BASE_URL': raw});
        expect(value.chatCompletionsUri.toString(), fixed, reason: raw);
        expect(value.acceptedBaseUrlOverride, isNull, reason: raw);
        expect(value.ignoresBaseUrlOverride, isTrue, reason: raw);
      }
    });
  });
}
