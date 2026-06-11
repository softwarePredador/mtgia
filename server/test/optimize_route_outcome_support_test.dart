import 'package:test/test.dart';

import '../lib/ai/optimize_route_outcome_support.dart';
import '../lib/ai/optimize_state_support.dart';

void main() {
  group('deriveOptimizeOutcomeCode', () {
    const healthyDeckState = DeckOptimizationStateResult(
      status: 'healthy',
      recommendedMode: 'optimize',
      suggestedScope: 'micro_swaps',
      reasons: <String>[],
      severityScore: 0,
    );

    const repairDeckState = DeckOptimizationStateResult(
      status: 'needs_repair',
      recommendedMode: 'repair',
      suggestedScope: 'rebuild_core',
      reasons: <String>['Deck fora do plano do comandante.'],
      severityScore: 88,
      repairPlan: <String, dynamic>{'target_land_count': 36},
    );

    test('maps successful modes to stable product outcomes', () {
      expect(
        deriveOptimizeOutcomeCode(
          statusCode: 200,
          body: const {'mode': 'optimize'},
          deckState: healthyDeckState,
        ),
        equals('optimized'),
      );
      expect(
        deriveOptimizeOutcomeCode(
          statusCode: 200,
          body: const {'mode': 'complete'},
          deckState: healthyDeckState,
        ),
        equals('deck_completed'),
      );
      expect(
        deriveOptimizeOutcomeCode(
          statusCode: 200,
          body: const {'mode': 'rebuild_guided'},
          deckState: repairDeckState,
        ),
        equals('rebuild_guided'),
      );
    });

    test('maps healthy no-safe-swap rejection to safe no-op outcome', () {
      final outcome = deriveOptimizeOutcomeCode(
        statusCode: 422,
        body: const {
          'quality_error': {
            'code': 'OPTIMIZE_NO_SAFE_SWAPS',
          },
        },
        deckState: healthyDeckState,
      );

      expect(outcome, equals('no_safe_upgrade_found'));
    });

    test('maps near-peak quality rejection using validation payload', () {
      final outcome = deriveOptimizeOutcomeCode(
        statusCode: 422,
        body: const {
          'quality_error': {
            'code': 'OPTIMIZE_QUALITY_REJECTED',
            'validation': {
              'deck_health_score': 84,
              'improvement_score': 18,
            },
          },
        },
        deckState: healthyDeckState,
      );

      expect(outcome, equals('near_peak'));
    });

    test('maps structural rejection and low health to repair outcome', () {
      expect(
        deriveOptimizeOutcomeCode(
          statusCode: 422,
          body: const {
            'quality_error': {
              'code': 'OPTIMIZE_QUALITY_REJECTED',
              'validation': {
                'deck_health_score': 22,
                'improvement_score': 9,
              },
            },
          },
          deckState: repairDeckState,
        ),
        equals('needs_repair'),
      );

      expect(
        deriveOptimizeOutcomeCode(
          statusCode: 422,
          body: const {
            'quality_error': {
              'code': 'OPTIMIZE_SEMANTIC_V2_REJECTED',
              'validation': {
                'deck_health_score': 30,
                'improvement_score': 70,
              },
            },
          },
          deckState: healthyDeckState,
        ),
        equals('needs_repair'),
      );
    });

    test('maps execution failures by deck state and HTTP class', () {
      expect(
        deriveOptimizeOutcomeCode(
          statusCode: 422,
          body: const {
            'quality_error': {'code': 'OPTIMIZE_EXECUTION_FAILED'},
          },
          deckState: healthyDeckState,
        ),
        equals('no_safe_upgrade_found'),
      );
      expect(
        deriveOptimizeOutcomeCode(
          statusCode: 500,
          body: const {},
          deckState: healthyDeckState,
        ),
        equals('execution_failed'),
      );
      expect(
        deriveOptimizeOutcomeCode(
          statusCode: 400,
          body: const {},
          deckState: healthyDeckState,
        ),
        equals('blocked'),
      );
    });
  });
}
