import 'package:dotenv/dotenv.dart';
import 'package:test/test.dart';

import '../lib/ai_generate_job.dart';
import '../lib/ai_generate_performance_support.dart';
import '../lib/openai_runtime_config.dart';

void main() {
  group('AI generate performance support', () {
    group('request input contract', () {
      test('normalizes valid request fields once for sync and async paths', () {
        final input = parseAiGenerateRequestInput({
          'prompt': '  Boros miracle  ',
          'format': '  Commander ',
          'commander_name': ' Lorehold, the Historian ',
          'bracket': ' 4 ',
          'async': true,
          'request_key': ' generate:request-1 ',
        });

        expect(input.prompt, equals('Boros miracle'));
        expect(input.format, equals('Commander'));
        expect(input.commanderName, equals('Lorehold, the Historian'));
        expect(input.body['prompt'], equals(input.prompt));
        expect(input.body['format'], equals(input.format));
        expect(input.body['commander_name'], equals(input.commanderName));
        expect(input.body['bracket'], equals(4));
        expect(input.constraints.isRequested, isFalse);
        expect(isAiGenerateAsyncRequested(input.body), isTrue);
        expect(input.body['request_key'], 'generate:request-1');
      });

      test('normalizes hard generation constraints', () {
        final input = parseAiGenerateRequestInput({
          'prompt': 'Boros budget',
          'generation_constraints': {
            'prefer_collection': false,
            'collection_only': true,
            'budget_limit_brl': 250,
          },
        });

        expect(input.constraints.preferCollection, isTrue);
        expect(input.constraints.collectionOnly, isTrue);
        expect(input.constraints.budgetLimitBrl, 250);
        expect(input.body['generation_constraints'], {
          'prefer_collection': true,
          'collection_only': true,
          'budget_limit_brl': 250,
        });
      });

      test('uses Commander and removes blank optional commander', () {
        final input = parseAiGenerateRequestInput({
          'prompt': ' deck de artefatos ',
          'format': '   ',
          'commander_name': '   ',
        });

        expect(input.format, equals('Commander'));
        expect(input.commanderName, isNull);
        expect(input.body.containsKey('commander_name'), isFalse);
      });

      test(
        'rejects non-object, missing, blank, and incorrectly typed input',
        () {
          for (final decoded in <Object?>[
            null,
            const ['prompt'],
            const <String, dynamic>{},
            const {'prompt': '   '},
            const {'prompt': 42},
            const {'prompt': 'valid', 'format': 42},
            const {'prompt': 'valid', 'commander_name': true},
            const {'prompt': 'valid', 'bracket': true},
            const {'prompt': 'valid', 'bracket': 0},
            const {'prompt': 'valid', 'bracket': 6},
            const {'prompt': 'valid', 'request_key': 'contains whitespace'},
            const {'prompt': 'valid', 'generation_constraints': true},
            const {
              'prompt': 'valid',
              'generation_constraints': {'collection_only': 'yes'},
            },
            const {
              'prompt': 'valid',
              'generation_constraints': {'budget_limit_brl': -1},
            },
            const {
              'prompt': 'valid',
              'generation_constraints': {'unknown': true},
            },
          ]) {
            expect(
              () => parseAiGenerateRequestInput(decoded),
              throwsA(isA<AiGenerateRequestValidationException>()),
              reason: 'decoded=$decoded',
            );
          }
        },
      );

      test('rejects fields beyond provider cost and contract bounds', () {
        expect(
          () => parseAiGenerateRequestInput({
            'prompt': 'p' * (aiGenerateMaxPromptLength + 1),
          }),
          throwsA(isA<AiGenerateRequestValidationException>()),
        );
        expect(
          () => parseAiGenerateRequestInput({
            'prompt': 'valid',
            'format': 'f' * (aiGenerateMaxFormatLength + 1),
          }),
          throwsA(isA<AiGenerateRequestValidationException>()),
        );
        expect(
          () => parseAiGenerateRequestInput({
            'prompt': 'valid',
            'commander_name': 'c' * (aiGenerateMaxCommanderNameLength + 1),
          }),
          throwsA(isA<AiGenerateRequestValidationException>()),
        );
      });
    });

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
        expect(first, startsWith('ai_generate:v3:'));
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
      expect(v5, startsWith('ai_generate:v3:'));
    });

    test('generation constraints participate in the cache key', () {
      final unrestricted = buildAiGenerateCacheKey(
        prompt: 'boros artifacts',
        format: 'commander',
      );
      final budget100 = buildAiGenerateCacheKey(
        prompt: 'boros artifacts',
        format: 'commander',
        constraints: const AiGenerateConstraints(
          preferCollection: true,
          collectionOnly: false,
          budgetLimitBrl: 100,
        ),
      );
      final budget200 = buildAiGenerateCacheKey(
        prompt: 'boros artifacts',
        format: 'commander',
        constraints: const AiGenerateConstraints(
          preferCollection: true,
          collectionOnly: false,
          budgetLimitBrl: 200,
        ),
      );

      expect(budget100, isNot(unrestricted));
      expect(budget200, isNot(budget100));
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
        'request_key': 'generate:request-1',
        'bracket': 3,
        'generation_constraints': {'budget_limit_brl': 100},
      });

      expect(payload['prompt'], equals('mono blue tempo'));
      expect(payload['format'], equals('commander'));
      expect(payload['bracket'], equals(3));
      expect(payload['generation_constraints'], {'budget_limit_brl': 100});
      expect(payload.containsKey('async'), isFalse);
      expect(payload.containsKey('profile'), isFalse);
      expect(payload.containsKey('response_mode'), isFalse);
      expect(payload.containsKey('request_key'), isFalse);
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
