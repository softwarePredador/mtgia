import 'package:server/ai/optimize_route_response_support.dart';
import 'package:server/ai/optimize_runtime_support.dart';
import 'package:server/ai/optimize_state_support.dart';
import 'package:test/test.dart';

void main() {
  const focused = OptimizeIntensityConfig(
    selected: 'focused',
    requested: null,
    source: 'test',
    targetMin: 2,
    targetMax: 4,
  );

  group('countOptimizeResponseSwaps', () {
    test('counts complete additions and optimize swap pairs', () {
      expect(
        countOptimizeResponseSwaps(
          responseBody: {
            'mode': 'complete',
            'additions_detailed': [
              {'name': 'A'},
              {'name': 'B'},
            ],
          },
          effectiveMode: 'optimize',
        ),
        2,
      );

      expect(
        countOptimizeResponseSwaps(
          responseBody: {
            'removals': ['A', 'B', 'C'],
            'additions': ['D', 'E'],
          },
          effectiveMode: 'optimize',
        ),
        2,
      );
    });
  });

  group('buildCachedOptimizeResponse', () {
    test('adds cache metadata without mutating cached body', () {
      final cached = {
        'mode': 'optimize',
        'strategy_source': 'deterministic_first',
        'outcome_code': 'optimized',
        'removals': ['A'],
        'additions': ['B'],
        'removals_detailed': [
          {'name': 'A', 'card_id': 'card-a', 'quantity': 1},
        ],
        'additions_detailed': [
          {'name': 'B', 'card_id': 'card-b', 'quantity': 1},
        ],
      };

      final response = buildCachedOptimizeResponse(
        cachedResponse: cached,
        cacheKey: 'cache-1',
        intensity: focused,
        effectiveMode: 'optimize',
        timings: {'total_ms': 12},
        hasBracketOverride: false,
        hasKeepThemeOverride: true,
        keepTheme: false,
        userPreferences: {'preferred_bracket': 3},
      );

      expect(response, isNotNull);
      final hydrated = response!;
      expect(cached.containsKey('cache'), isFalse);
      expect(hydrated['outcome_code'], 'optimized');
      expect(hydrated['cache'], {'hit': true, 'cache_key': 'cache-1'});
      expect(hydrated['intensity'], 'focused');
      expect(hydrated['timings'], {'total_ms': 12});
      expect(hydrated['stage_telemetry'], {'total_ms': 12});
      expect(hydrated['preferences'], {
        'memory_applied': true,
        'keep_theme': false,
        'preferred_bracket': 3,
      });
      expect((hydrated['optimize_intensity'] as Map)['returned_swaps'], 1);
    });

    test('rejects legacy empty cache without outcome or provenance', () {
      final response = buildCachedOptimizeResponse(
        cachedResponse: const {
          'mode': 'optimize',
          'removals': <String>[],
          'additions': <String>[],
        },
        cacheKey: 'legacy-empty',
        intensity: focused,
        effectiveMode: 'optimize',
        timings: const {'total_ms': 1},
        hasBracketOverride: false,
        hasKeepThemeOverride: false,
        keepTheme: true,
        userPreferences: const {'preferred_bracket': null},
      );

      expect(response, isNull);
    });

    test('does not trust an explicit optimized outcome with zero swaps', () {
      final response = buildCachedOptimizeResponse(
        cachedResponse: const {
          'mode': 'optimize',
          'strategy_source': 'ai_primary',
          'outcome_code': 'optimized',
          'removals': <String>[],
          'additions': <String>[],
          'removals_detailed': <Map<String, dynamic>>[],
          'additions_detailed': <Map<String, dynamic>>[],
        },
        cacheKey: 'unsafe-empty',
        intensity: focused,
        effectiveMode: 'optimize',
        timings: const {'total_ms': 1},
        hasBracketOverride: false,
        hasKeepThemeOverride: false,
        keepTheme: true,
        userPreferences: const {'preferred_bracket': null},
      );

      expect(response, isNull);
    });

    test('preserves an explicit provenance-backed safe no-op cache hit', () {
      final response = buildCachedOptimizeResponse(
        cachedResponse: const {
          'mode': 'optimize',
          'strategy_source': 'deterministic_first',
          'outcome_code': 'no_safe_upgrade_found',
          'can_apply': false,
          'learning_eligible': false,
          'removals': <String>[],
          'additions': <String>[],
        },
        cacheKey: 'safe-no-op',
        intensity: focused,
        effectiveMode: 'optimize',
        timings: const {'total_ms': 2},
        hasBracketOverride: false,
        hasKeepThemeOverride: false,
        keepTheme: true,
        userPreferences: const {'preferred_bracket': null},
      );

      expect(response, isNotNull);
      expect(response!['outcome_code'], equals('no_safe_upgrade_found'));
      expect(response['can_apply'], isFalse);
      expect(response['learning_eligible'], isFalse);
      expect(response['cache'], {'hit': true, 'cache_key': 'safe-no-op'});
    });

    test('does not reuse mock payloads as safe no-op cache hits', () {
      final response = buildCachedOptimizeResponse(
        cachedResponse: const {
          'mode': 'optimize',
          'strategy_source': 'mock_fallback',
          'outcome_code': 'mock_non_actionable',
          'is_mock': true,
          'can_apply': false,
          'learning_eligible': false,
          'removals': <String>[],
          'additions': <String>[],
        },
        cacheKey: 'mock-no-op',
        intensity: focused,
        effectiveMode: 'optimize',
        timings: const {'total_ms': 2},
        hasBracketOverride: false,
        hasKeepThemeOverride: false,
        keepTheme: true,
        userPreferences: const {'preferred_bracket': null},
      );

      expect(response, isNull);
    });
  });

  group('buildAggressiveCandidateQualityDiagnostics', () {
    test('merges reason buckets and reports reduced scope', () {
      final buckets = <String, int>{'off_identity': 1};
      mergeOptimizeReasonBuckets(buckets, {'off_identity': 2, 'duplicate': 1});

      final diagnostics = buildAggressiveCandidateQualityDiagnostics(
        diagnostics: {
          'requested_target_swaps': 4,
          'removal_candidates': 7,
          'replacement_candidates': 6,
          'pairs_generated': 3,
          'ranked_before_quality_gate': true,
          'candidate_sources': ['reference'],
        },
        rejectionReasonBuckets: buckets,
        intensity: focused,
        returnedSwaps: 2,
      );

      expect(diagnostics['rejected_reason_buckets'], {
        'off_identity': 3,
        'duplicate': 1,
      });
      expect(diagnostics['safety_reduced_scope'], isTrue);
      expect(diagnostics['returned_swaps'], 2);
      expect(diagnostics['candidate_sources'], ['reference']);
      expect(diagnostics['utility_signal'], isA<Map<String, dynamic>>());
    });
  });

  group('buildOptimizeRebuildGuidedOutcome', () {
    test('builds stable rebuild payload', () {
      const deckState = DeckOptimizationStateResult(
        status: 'needs_repair',
        recommendedMode: 'rebuild_guided',
        suggestedScope: 'full',
        reasons: ['too_few_cards'],
        severityScore: 10,
        repairPlan: {'add_cards': true},
      );
      const theme = DeckThemeProfileResult(
        theme: 'spellslinger',
        confidence: 'high',
        matchScore: 0.88,
        coreCards: ['Commander'],
      );

      final outcome = buildOptimizeRebuildGuidedOutcome(
        explanation: 'Needs rebuild.',
        trigger: 'deck_state_needs_repair',
        qualityCode: 'OPTIMIZE_NEEDS_REPAIR',
        intensity: focused,
        deckState: deckState,
        deckId: 'deck-1',
        bracket: 2,
        archetype: 'control',
        themeProfile: theme,
        deckAnalysis: {'average_cmc': 3.1},
      );

      expect(outcome['mode'], 'rebuild_guided');
      expect(outcome['strategy_source'], 'state_gate');
      expect(outcome['outcome_code'], 'rebuild_guided');
      expect(
        (outcome['quality_error'] as Map)['code'],
        'OPTIMIZE_NEEDS_REPAIR',
      );
      expect((outcome['next_action'] as Map)['endpoint'], '/ai/rebuild');
      expect(
        ((outcome['next_action'] as Map)['payload'] as Map)['theme'],
        'spellslinger',
      );
      expect((outcome['theme'] as Map)['confidence'], 'high');
    });
  });
}
