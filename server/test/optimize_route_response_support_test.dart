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
        'removals': ['A'],
        'additions': ['B'],
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

      expect(cached.containsKey('cache'), isFalse);
      expect(response['cache'], {'hit': true, 'cache_key': 'cache-1'});
      expect(response['intensity'], 'focused');
      expect(response['timings'], {'total_ms': 12});
      expect(response['stage_telemetry'], {'total_ms': 12});
      expect(
        response['preferences'],
        {
          'memory_applied': true,
          'keep_theme': false,
          'preferred_bracket': 3,
        },
      );
      expect(
        (response['optimize_intensity'] as Map)['returned_swaps'],
        1,
      );
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
      expect(outcome['outcome_code'], 'rebuild_guided');
      expect(
          (outcome['quality_error'] as Map)['code'], 'OPTIMIZE_NEEDS_REPAIR');
      expect((outcome['next_action'] as Map)['endpoint'], '/ai/rebuild');
      expect(
        ((outcome['next_action'] as Map)['payload'] as Map)['theme'],
        'spellslinger',
      );
      expect((outcome['theme'] as Map)['confidence'], 'high');
    });
  });
}
