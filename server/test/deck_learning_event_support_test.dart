import 'dart:io';

import 'package:test/test.dart';

import '../lib/ai/deck_learning_event_support.dart';

void main() {
  group('isolated E2E write policy', () {
    const validToken = 'resolution_validation_20260716';

    test('keeps product learning and housekeeping enabled by default', () {
      expect(shouldWriteProductLearning(environment: const {}), isTrue);
      expect(shouldRunGlobalHousekeeping(environment: const {}), isTrue);
    });

    test('requires both explicit isolation flag and a valid run token', () {
      expect(
        shouldWriteProductLearning(
          environment: const {'MANALOOM_E2E_ISOLATED_RUNTIME': '1'},
        ),
        isTrue,
      );
      expect(
        shouldWriteProductLearning(
          environment: const {
            'MANALOOM_E2E_ISOLATED_RUNTIME': '1',
            'MANALOOM_E2E_VALIDATION_RUN_TOKEN': 'invalid token',
          },
        ),
        isTrue,
      );
      expect(
        shouldWriteProductLearning(
          environment: const {
            'MANALOOM_E2E_ISOLATED_RUNTIME': '1',
            'MANALOOM_E2E_VALIDATION_RUN_TOKEN': validToken,
          },
        ),
        isFalse,
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
      final feedbackSupport =
          File('lib/ai/optimize_feedback_support.dart').readAsStringSync();

      expect(deckRoute, contains('if (productLearningEnabled)'));
      expect(deckRoute, contains("'product_learning_writes_suppressed': true"));
      expect(cacheSupport, contains('if (shouldRunGlobalHousekeeping())'));
      expect(jobSupport, contains('if (shouldRunGlobalHousekeeping())'));
      expect(
        generateJobSupport,
        contains('if (!shouldRunGlobalHousekeeping()) return;'),
      );
      expect(generateJobSupport, contains('_cleanupInterval'));
      expect(
        feedbackSupport,
        contains('!shouldWriteProductLearning(environment: environment)'),
      );
    });

    test('all deck-learning writers enforce isolation internally', () {
      final source =
          File('lib/ai/deck_learning_event_support.dart').readAsStringSync();
      expect(
        RegExp(
          r'if \(!shouldWriteProductLearning\(environment: environment\)\) return;',
        ).allMatches(source),
        hasLength(4),
      );
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
