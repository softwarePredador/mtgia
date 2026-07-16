import 'package:test/test.dart';

import '../lib/ai/optimize_route_outcome_support.dart';
import '../lib/ai/optimize_state_support.dart';

void main() {
  group('deriveOptimizeOutcomeCode', () {
    Map<String, dynamic> actionableOptimizeBody() => {
      'mode': 'optimize',
      'removals': ['Old Card'],
      'additions': ['New Card'],
      'removals_detailed': [
        {'name': 'Old Card', 'card_id': 'old-card-id', 'quantity': 1},
      ],
      'additions_detailed': [
        {'name': 'New Card', 'card_id': 'new-card-id', 'quantity': 1},
      ],
    };

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
          body: actionableOptimizeBody(),
          deckState: healthyDeckState,
        ),
        equals('optimized'),
      );
      expect(
        deriveOptimizeOutcomeCode(
          statusCode: 200,
          body: const {
            'mode': 'complete',
            'additions': ['New Card'],
            'additions_detailed': [
              {'name': 'New Card', 'card_id': 'new-card-id', 'quantity': 1},
            ],
          },
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

    test('fails closed for an empty successful optimize body', () {
      final body = <String, dynamic>{'mode': 'optimize'};

      expect(
        deriveOptimizeOutcomeCode(
          statusCode: 200,
          body: body,
          deckState: healthyDeckState,
        ),
        equals('no_safe_upgrade_found'),
      );

      enforceSuccessfulOptimizeOutcomeSafety(body);
      expect(body['outcome_code'], equals('no_safe_upgrade_found'));
      expect(body['can_apply'], isFalse);
      expect(body['learning_eligible'], isFalse);
    });

    test('rejects unbalanced or non-detailed swaps as optimized', () {
      final unbalanced =
          actionableOptimizeBody()
            ..['additions'] = <String>[]
            ..['additions_detailed'] = <Map<String, dynamic>>[];
      final missingCardId =
          actionableOptimizeBody()
            ..['additions_detailed'] = [
              {'name': 'New Card', 'quantity': 1},
            ];
      final nonUnitQuantity =
          actionableOptimizeBody()
            ..['additions_detailed'] = [
              {'name': 'New Card', 'card_id': 'new-card-id', 'quantity': 2},
            ];
      final overlappingCard =
          actionableOptimizeBody()
            ..['additions'] = ['Old Card']
            ..['additions_detailed'] = [
              {'name': 'Old Card', 'card_id': 'old-card-id', 'quantity': 1},
            ];

      expect(hasActionableOptimizeSwaps(unbalanced), isFalse);
      expect(hasActionableOptimizeSwaps(missingCardId), isFalse);
      expect(hasActionableOptimizeSwaps(nonUnitQuantity), isFalse);
      expect(hasActionableOptimizeSwaps(overlappingCard), isFalse);
      expect(
        deriveOptimizeOutcomeCode(
          statusCode: 200,
          body: unbalanced,
          deckState: healthyDeckState,
        ),
        equals('no_safe_upgrade_found'),
      );
      expect(
        deriveOptimizeOutcomeCode(
          statusCode: 200,
          body: missingCardId,
          deckState: healthyDeckState,
        ),
        equals('no_safe_upgrade_found'),
      );
    });

    test('maps healthy no-safe-swap rejection to safe no-op outcome', () {
      final outcome = deriveOptimizeOutcomeCode(
        statusCode: 422,
        body: const {
          'quality_error': {'code': 'OPTIMIZE_NO_SAFE_SWAPS'},
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
            'validation': {'deck_health_score': 84, 'improvement_score': 18},
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
              'validation': {'deck_health_score': 22, 'improvement_score': 9},
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
              'validation': {'deck_health_score': 30, 'improvement_score': 70},
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
