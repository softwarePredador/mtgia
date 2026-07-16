import 'package:dotenv/dotenv.dart';
import 'package:test/test.dart';

import '../lib/ai_generate_job.dart';
import '../lib/ai_generate_performance_support.dart';
import '../lib/openai_runtime_config.dart';

void main() {
  group('AI generate performance support', () {
    test(
      'builds stable cache keys from normalized prompt format and bracket',
      () {
        final first = buildAiGenerateCacheKey(
          prompt: '  Mono   Red Aggro  ',
          format: 'STANDARD',
          bracket: 2,
        );
        final second = buildAiGenerateCacheKey(
          prompt: 'mono red aggro',
          format: 'standard',
          bracket: '2',
        );
        final differentBracket = buildAiGenerateCacheKey(
          prompt: 'mono red aggro',
          format: 'standard',
          bracket: 3,
        );

        expect(first, equals(second));
        expect(first, isNot(equals(differentBracket)));
        expect(first, startsWith('ai_generate:v2:'));
        expect(first, isNot(contains('mono red')));
      },
    );

    test('omits commander profile material unless explicitly supplied', () {
      final legacy = buildAiGenerateCacheKey(
        prompt: 'boros miracle big spells',
        format: 'Commander',
      );
      final stillLegacy = buildAiGenerateCacheKey(
        prompt: '  Boros   Miracle Big Spells ',
        format: 'edh',
        commanderName: '',
        referenceProfileVersion: '',
      );
      final loreholdProfile = buildAiGenerateCacheKey(
        prompt: 'boros miracle big spells',
        format: 'Commander',
        commanderName: 'Lorehold, the Historian',
        referenceProfileVersion: 'lorehold_reference_profile_v1_2026-05-11',
      );
      final loreholdProfileV2 = buildAiGenerateCacheKey(
        prompt: 'boros miracle big spells',
        format: 'Commander',
        commanderName: 'Lorehold, the Historian',
        referenceProfileVersion: 'future_profile_version',
      );

      expect(legacy, equals(stillLegacy));
      expect(loreholdProfile, isNot(equals(legacy)));
      expect(loreholdProfileV2, isNot(equals(loreholdProfile)));
      expect(loreholdProfile, isNot(contains('Lorehold')));
    });

    test('reference prompt policy version changes cache key material', () {
      final v4 = buildAiGenerateCacheKey(
        prompt: 'boros miracle big spells',
        format: 'Commander',
        commanderName: 'Lorehold, the Historian',
        referenceProfileVersion:
            'ai_generate_reference_prompt_v4:profile:stats:corpus',
      );
      final v5 = buildAiGenerateCacheKey(
        prompt: 'boros miracle big spells',
        format: 'Commander',
        commanderName: 'Lorehold, the Historian',
        referenceProfileVersion:
            'ai_generate_reference_prompt_v5:profile:stats:corpus',
      );

      expect(v5, isNot(equals(v4)));
      expect(v5, startsWith('ai_generate:v2:'));
    });

    test('returns cache hits as cloned payloads with cache metadata', () {
      final cacheKey = buildAiGenerateCacheKey(
        prompt: 'azorius control',
        format: 'standard',
      );
      final payload = {
        'prompt': 'azorius control',
        'format': 'Standard',
        'generated_deck': {
          'cards': [
            {'name': 'Island', 'quantity': 30},
            {'name': 'Plains', 'quantity': 30},
          ],
        },
        'validation': {'is_valid': true},
        'timings': {'openai_ms': 9000, 'total_ms': 10000},
      };

      writeAiGenerateCache(
        cacheKey: cacheKey,
        payload: payload,
        ttl: const Duration(minutes: 5),
      );

      final firstHit = readAiGenerateCache(cacheKey);
      expect(firstHit, isNotNull);
      expect((firstHit!['cache'] as Map)['hit'], isTrue);
      expect((firstHit['cache'] as Map)['cache_key'], equals(cacheKey));
      expect(firstHit['timings'], isNull);

      ((firstHit['generated_deck'] as Map)['cards'] as List).clear();
      final secondHit = readAiGenerateCache(cacheKey);
      expect(
        ((secondHit!['generated_deck'] as Map)['cards'] as List).length,
        equals(2),
      );
    });

    test('detects async opt-in without changing sync default', () {
      expect(isAiGenerateAsyncRequested({'prompt': 'x'}), isFalse);
      expect(isAiGenerateAsyncRequested({'async': true}), isTrue);
      expect(isAiGenerateAsyncRequested({'async': 'true'}), isTrue);
      expect(isAiGenerateAsyncRequested({'profile': 'async'}), isTrue);
      expect(
        isAiGenerateAsyncRequested({'response_mode': 'background'}),
        isTrue,
      );
    });

    test('strips async-only flags before background sync execution', () {
      final payload = buildAiGenerateSyncPayloadForAsyncJob({
        'prompt': 'mono blue tempo',
        'format': 'commander',
        'async': true,
        'profile': 'async',
        'response_mode': 'background',
        'bracket': 3,
      });

      expect(payload['prompt'], equals('mono blue tempo'));
      expect(payload['format'], equals('commander'));
      expect(payload['bracket'], equals(3));
      expect(payload.containsKey('async'), isFalse);
      expect(payload.containsKey('profile'), isFalse);
      expect(payload.containsKey('response_mode'), isFalse);
    });

    test(
      'keeps legacy generate timeout when reference guidance is inactive',
      () {
        final config = OpenAiRuntimeConfig(
          DotEnv()..addAll({'ENVIRONMENT': 'staging'}),
        );

        final selection = selectAiGenerateOpenAiTimeout(
          config: config,
          normalizedFormat: 'commander',
          referenceGuidanceEnabled: false,
        );

        expect(selection.timeout, equals(const Duration(seconds: 8)));
        expect(selection.envKey, equals('OPENAI_TIMEOUT_GENERATE_SECONDS'));
        expect(selection.referenceGuidanceBudget, isFalse);
      },
    );

    test('uses larger default timeout for Commander reference guidance', () {
      final config = OpenAiRuntimeConfig(
        DotEnv()..addAll({'ENVIRONMENT': 'staging'}),
      );

      final selection = selectAiGenerateOpenAiTimeout(
        config: config,
        normalizedFormat: 'commander',
        referenceGuidanceEnabled: true,
      );

      expect(selection.timeout, equals(const Duration(seconds: 24)));
      expect(
        selection.envKey,
        equals('OPENAI_TIMEOUT_GENERATE_REFERENCE_SECONDS'),
      );
      expect(selection.referenceGuidanceBudget, isTrue);
    });

    test('does not use reference timeout outside Commander or Brawl', () {
      final config = OpenAiRuntimeConfig(
        DotEnv()..addAll({
          'ENVIRONMENT': 'staging',
          'OPENAI_TIMEOUT_GENERATE_REFERENCE_SECONDS': '20',
        }),
      );

      final selection = selectAiGenerateOpenAiTimeout(
        config: config,
        normalizedFormat: 'standard',
        referenceGuidanceEnabled: true,
      );

      expect(selection.timeout, equals(const Duration(seconds: 8)));
      expect(selection.referenceGuidanceBudget, isFalse);
    });

    test('honors bounded explicit reference timeout override', () {
      final lowConfig = OpenAiRuntimeConfig(
        DotEnv()..addAll({
          'ENVIRONMENT': 'production',
          'OPENAI_TIMEOUT_GENERATE_REFERENCE_SECONDS': '2',
        }),
      );
      final highConfig = OpenAiRuntimeConfig(
        DotEnv()..addAll({
          'ENVIRONMENT': 'production',
          'OPENAI_TIMEOUT_GENERATE_REFERENCE_SECONDS': '120',
        }),
      );

      expect(
        selectAiGenerateOpenAiTimeout(
          config: lowConfig,
          normalizedFormat: 'commander',
          referenceGuidanceEnabled: true,
        ).timeout,
        equals(const Duration(seconds: 3)),
      );
      expect(
        selectAiGenerateOpenAiTimeout(
          config: highConfig,
          normalizedFormat: 'brawl',
          referenceGuidanceEnabled: true,
        ).timeout,
        equals(const Duration(seconds: 90)),
      );
    });

    test('serializes async job lifecycle state with result status', () {
      final createdAt = DateTime.utc(2026, 5, 5, 12);
      final updatedAt = DateTime.utc(2026, 5, 5, 12, 1);
      final job = AiGenerateJob.fromRow({
        'id': 'job-1',
        'user_id': 'user-1',
        'cache_key': 'ai_generate:v1:hash',
        'format': 'Commander',
        'status': 'completed',
        'stage': 'Concluido',
        'stage_number': 4,
        'total_stages': 4,
        'result_status_code': 200,
        'result': '{"validation":{"is_valid":true}}',
        'created_at': createdAt,
        'updated_at': updatedAt,
      });

      expect(job.userId, equals('user-1'));
      expect(job.status, equals('completed'));
      expect(job.resultStatusCode, equals(200));
      expect(job.result?['validation'], equals({'is_valid': true}));

      final json = job.toJson();
      expect(json['job_id'], equals('job-1'));
      expect(json['cache_key'], equals('ai_generate:v1:hash'));
      expect(json['result_status_code'], equals(200));
      expect(
        json['result'],
        equals({
          'validation': {'is_valid': true},
        }),
      );
    });
  });
}
