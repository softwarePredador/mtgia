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
            'mana_foundation_satisfied': true,
            'target_additions': 1,
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

    test('complete requires an explicit verified mana foundation', () {
      const legacyUnsafeBody = {
        'mode': 'complete',
        'strategy_source': 'complete_pipeline',
        'outcome_code': 'deck_completed',
        'additions': ['New Card'],
        'additions_detailed': [
          {'name': 'New Card', 'card_id': 'new-card-id', 'quantity': 1},
        ],
      };
      const verifiedBody = {
        ...legacyUnsafeBody,
        'mana_foundation_satisfied': true,
        'target_additions': 1,
      };

      expect(
        deriveOptimizeOutcomeCode(
          statusCode: 200,
          body: legacyUnsafeBody,
          deckState: healthyDeckState,
        ),
        equals('no_safe_upgrade_found'),
      );
      expect(
        isReusableCachedOptimizeResponse(
          legacyUnsafeBody,
          effectiveMode: 'complete',
        ),
        isFalse,
      );
      expect(
        isReusableCachedOptimizeResponse(
          verifiedBody,
          effectiveMode: 'complete',
        ),
        isTrue,
      );
    });

    test('complete requires the exact physical target and coherent totals', () {
      final partialBody = <String, dynamic>{
        'mode': 'complete',
        'mana_foundation_satisfied': true,
        'target_additions': 25,
        'additions': ['Plains'],
        'additions_detailed': [
          {'name': 'Plains', 'card_id': 'plains-id', 'quantity': 9},
        ],
        'deck_analysis': {'total_cards': 75},
        'post_analysis': {'total_cards': 84},
      };
      final incoherentTotalsBody = <String, dynamic>{
        ...partialBody,
        'target_additions': 9,
        'post_analysis': {'total_cards': 83},
      };
      final completeBody = <String, dynamic>{
        ...partialBody,
        'target_additions': 9,
        'post_analysis': {'total_cards': 84},
      };

      enforceSuccessfulOptimizeOutcomeSafety(partialBody);
      expect(partialBody['outcome_code'], 'no_safe_upgrade_found');
      expect(partialBody['can_apply'], isFalse);
      expect(partialBody['learning_eligible'], isFalse);

      enforceSuccessfulOptimizeOutcomeSafety(incoherentTotalsBody);
      expect(incoherentTotalsBody['outcome_code'], 'no_safe_upgrade_found');
      expect(incoherentTotalsBody['can_apply'], isFalse);

      enforceSuccessfulOptimizeOutcomeSafety(completeBody);
      expect(completeBody['outcome_code'], 'deck_completed');
      expect(completeBody['can_apply'], isNot(false));
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

    test(
      'maps bracket and functional-floor rejection to a safe preserved deck',
      () {
        for (final code in const [
          'OPTIMIZE_BRACKET_VIOLATION',
          'OPTIMIZE_FUNCTIONAL_ROLE_FLOOR',
        ]) {
          expect(
            deriveOptimizeOutcomeCode(
              statusCode: 422,
              body: {
                'quality_error': {'code': code},
              },
              deckState: healthyDeckState,
            ),
            equals('no_safe_upgrade_found'),
          );
          expect(
            deriveOptimizeOutcomeCode(
              statusCode: 422,
              body: {
                'quality_error': {'code': code},
              },
              deckState: repairDeckState,
            ),
            equals('needs_repair'),
          );
        }
      },
    );

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

    test('failed optimize outcomes cannot apply or feed learning', () {
      final body = <String, dynamic>{
        'outcome_code': 'execution_failed',
        'removals': ['Old Card'],
        'additions': ['New Card'],
        'can_apply': true,
        'learning_eligible': true,
      };

      enforceFailedOptimizeOutcomeSafety(body);

      expect(body['can_apply'], isFalse);
      expect(body['learning_eligible'], isFalse);
      expect(body['outcome_code'], 'execution_failed');
    });
  });
}
