import 'dart:io';

import 'package:postgres/postgres.dart';
import 'package:test/test.dart';

import '../lib/ai/deck_learning_event_support.dart';

void main() {
  group('isolated E2E write policy', () {
    const validToken = 'resolution_validation_20260716';

    test('keeps product learning fail-closed by default', () {
      expect(shouldWriteProductLearning(environment: const {}), isFalse);
      expect(shouldRunGlobalHousekeeping(environment: const {}), isTrue);
    });

    test('product learning requires the exact explicit opt-in', () {
      expect(
        shouldWriteProductLearning(
          environment: const {'MANALOOM_ENABLE_PRODUCT_LEARNING_WRITES': '1'},
        ),
        isTrue,
      );
      for (final value in const ['', '0', 'true', 'yes', '2']) {
        expect(
          shouldWriteProductLearning(
            environment: {'MANALOOM_ENABLE_PRODUCT_LEARNING_WRITES': value},
          ),
          isFalse,
          reason: 'Unexpected opt-in value: $value',
        );
      }
    });

    test('environment template keeps product learning disabled', () {
      final environmentTemplate = File('.env.example').readAsStringSync();

      expect(
        environmentTemplate,
        contains('MANALOOM_ENABLE_PRODUCT_LEARNING_WRITES=0'),
      );
      expect(
        environmentTemplate,
        isNot(contains('MANALOOM_ENABLE_PRODUCT_LEARNING_WRITES=1')),
      );
      expect(
        environmentTemplate,
        contains('MANALOOM_ENABLE_COMMANDER_USAGE_CORPUS_READS=0'),
      );
      expect(
        environmentTemplate,
        isNot(contains('MANALOOM_ENABLE_COMMANDER_USAGE_CORPUS_READS=1')),
      );
    });

    test('any isolated E2E request suppresses product learning', () {
      expect(
        shouldWriteProductLearning(
          environment: const {
            'MANALOOM_ENABLE_PRODUCT_LEARNING_WRITES': '1',
            'MANALOOM_E2E_ISOLATED_RUNTIME': '1',
          },
        ),
        isFalse,
      );
      expect(
        shouldWriteProductLearning(
          environment: const {
            'MANALOOM_ENABLE_PRODUCT_LEARNING_WRITES': '1',
            'MANALOOM_E2E_ISOLATED_RUNTIME': '1',
            'MANALOOM_E2E_VALIDATION_RUN_TOKEN': 'invalid token',
          },
        ),
        isFalse,
      );
      expect(
        shouldWriteProductLearning(
          environment: const {
            'MANALOOM_ENABLE_PRODUCT_LEARNING_WRITES': '1',
            'MANALOOM_E2E_ISOLATED_RUNTIME': '1',
            'MANALOOM_E2E_VALIDATION_RUN_TOKEN': validToken,
          },
        ),
        isFalse,
      );
    });

    test('housekeeping keeps the existing validated-isolation policy', () {
      expect(
        shouldRunGlobalHousekeeping(
          environment: const {'MANALOOM_E2E_ISOLATED_RUNTIME': '1'},
        ),
        isTrue,
      );
      expect(
        shouldRunGlobalHousekeeping(
          environment: const {
            'MANALOOM_E2E_ISOLATED_RUNTIME': '1',
            'MANALOOM_E2E_VALIDATION_RUN_TOKEN': 'invalid token',
          },
        ),
        isTrue,
      );
      expect(
        shouldRunGlobalHousekeeping(
          environment: const {
            'MANALOOM_E2E_ISOLATED_RUNTIME': '1',
            'MANALOOM_E2E_VALIDATION_RUN_TOKEN': validToken,
          },
        ),
        isFalse,
      );
    });

    test('write sites honor the centralized isolated-runtime policy', () {
      final deckRoute = File('routes/decks/index.dart').readAsStringSync();
      final cacheSupport =
          File('lib/ai/optimize_cache_support.dart').readAsStringSync();
      final jobSupport = File('lib/ai/optimize_job.dart').readAsStringSync();
      final generateJobSupport =
          File('lib/ai_generate_job.dart').readAsStringSync();

      expect(deckRoute, contains('if (productLearningEnabled)'));
      expect(deckRoute, contains('else if (isolatedE2eRuntime)'));
      expect(deckRoute, contains("'product_learning_writes_suppressed': true"));
      expect(deckRoute, contains("'reason': 'product_learning_disabled'"));
      expect(
        deckRoute,
        isNot(contains("else {\n      newDeck['e2e_validation'] = const {")),
      );
      expect(cacheSupport, contains('if (shouldRunGlobalHousekeeping())'));
      expect(jobSupport, contains('if (shouldRunGlobalHousekeeping())'));
      expect(
        generateJobSupport,
        contains('if (!shouldRunGlobalHousekeeping()) return;'),
      );
      expect(generateJobSupport, contains('_cleanupInterval'));
    });

    test('all deck-learning writers enforce isolation internally', () {
      final source =
          File('lib/ai/deck_learning_event_support.dart').readAsStringSync();
      expect(
        RegExp(
          r'if \(!shouldWriteProductLearning\(environment: environment\)\) return;',
        ).allMatches(source),
        hasLength(3),
      );
    });

    test('generic deck-learning writer accepts only saved user decks', () {
      final source =
          File('lib/ai/deck_learning_event_support.dart').readAsStringSync();

      expect(
        source,
        contains('if (source != deckLearningUserCreatedSource) return;'),
      );
      expect(source, isNot(contains("String source = 'ai_generated'")));
    });

    test('user-created commander learning is atomic', () {
      final support =
          File('lib/ai/deck_learning_event_support.dart').readAsStringSync();
      final deckRoute = File('routes/decks/index.dart').readAsStringSync();

      expect(support, contains('Future<void> recordUserCreatedDeckLearning'));
      expect(support, contains('await pool.runTx((session) async'));
      expect(support, contains('ignoreRowErrors: false'));
      expect(deckRoute, contains('await recordUserCreatedDeckLearning('));
    });
  });

  test(
    'loadUsageHotCards SQL avoids cards join fanout across multiple printings',
    () {
      final sql = loadUsageHotCardsSql.toLowerCase();

      expect(sql, contains('left join lateral'));
      expect(sql, contains('limit 1'));
      expect(sql, contains('coalesce(card_lookup.canonical_name'));
      expect(
        sql,
        isNot(
          contains(
            "join cards c on lower(split_part(c.name, ' // ', 1)) = ccu.card_name_normalized",
          ),
        ),
      );
    },
  );

  test('historical commander usage reads require the exact opt-in', () {
    expect(commanderUsageCorpusReadsEnabled(environment: const {}), isFalse);
    for (final value in const ['0', 'true', 'TRUE', ' 1 ', 'yes']) {
      expect(
        commanderUsageCorpusReadsEnabled(
          environment: {commanderUsageCorpusReadsEnvironment: value},
        ),
        isFalse,
        reason: 'value=$value must remain fail-closed',
      );
    }
    expect(
      commanderUsageCorpusReadsEnabled(
        environment: const {commanderUsageCorpusReadsEnvironment: '1'},
      ),
      isTrue,
    );
  });

  test('loadUsageHotCards does not touch PG while disabled', () async {
    final pool = _UsageCorpusReadTrapPool();

    final result = await loadUsageHotCards(
      pool: pool,
      commanderName: 'Talrand, Sky Summoner',
      environment: const {},
    );

    expect(result, isEmpty);
    expect(pool.executeCalls, isZero);
  });

  test('loadUsageHotCards reaches PG only with explicit opt-in', () async {
    final pool = _UsageCorpusReadTrapPool();

    final result = await loadUsageHotCards(
      pool: pool,
      commanderName: 'Talrand, Sky Summoner',
      environment: const {commanderUsageCorpusReadsEnvironment: '1'},
    );

    // The loader intentionally remains non-blocking on a database failure.
    expect(result, isEmpty);
    expect(pool.executeCalls, equals(1));
  });

  test('historical prompt never claims cards were saved by users', () {
    final prompt = buildUsageHotCardsPrompt(const [
      {
        'canonical_name': 'Arcane Signet',
        'card_name_normalized': 'arcane signet',
        'usage_count': 7,
      },
    ]);

    expect(prompt, contains('Quarantined historical aggregate signals'));
    expect(prompt, contains('provenance pending'));
    expect(prompt, isNot(contains('saved')));
    expect(prompt, isNot(contains('by users')));
    expect(prompt, isNot(contains('Real-player')));

    final referenceRoute =
        File('routes/ai/commander-reference/index.dart').readAsStringSync();
    expect(referenceRoute, contains('commanderUsageCorpusReadsEnabled()'));
    expect(
      referenceRoute,
      contains("'historical_observation_count': hotCards.fold<int>"),
    );
    expect(referenceRoute, isNot(contains("'total_users'")));
  });

  test('usageHotCardCanonicalNames caps and prefers canonical names', () {
    final names = usageHotCardCanonicalNames([
      {
        'canonical_name': 'Jeska\'s Will',
        'card_name_normalized': 'jeskas will',
      },
      {'canonical_name': '', 'card_name_normalized': 'unexpected windfall'},
      {
        'canonical_name': 'Arcane Signet',
        'card_name_normalized': 'arcane signet',
      },
    ], limit: 2);

    expect(names, equals(['Jeska\'s Will', 'unexpected windfall']));
  });

  test('usageHotCardCanonicalNames defaults to generation candidate limit', () {
    final hotCards = [
      for (
        var index = 0;
        index < usageHotCardsGenerationCandidateLimit + 5;
        index++
      )
        {
          'canonical_name': 'Usage Card $index',
          'card_name_normalized': 'usage card $index',
        },
    ];

    final names = usageHotCardCanonicalNames(hotCards);

    expect(names, hasLength(usageHotCardsGenerationCandidateLimit));
    expect(names.first, equals('Usage Card 0'));
    expect(
      names.last,
      equals('Usage Card ${usageHotCardsGenerationCandidateLimit - 1}'),
    );
  });
}

class _UsageCorpusReadTrapPool implements Pool {
  int executeCalls = 0;

  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #execute) {
      executeCalls++;
      throw StateError('PostgreSQL read reached test trap.');
    }
    return super.noSuchMethod(invocation);
  }
}
