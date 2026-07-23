import 'package:server/ai_generate_constraints_support.dart';
import 'package:server/ai_generate_performance_support.dart';
import 'package:test/test.dart';

void main() {
  group('AI generate constraints', () {
    test('audits collection, basic lands, missing price and total budget', () {
      final audit = evaluateAiGenerateConstraints(
        generatedDeck: const {
          'commander': {'name': 'Commander Card'},
          'cards': [
            {'name': 'Plains', 'quantity': 10},
            {'name': 'Owned Once', 'quantity': 2},
            {'name': 'Missing Price', 'quantity': 1},
            {'name': 'Market Card', 'quantity': 1},
          ],
        },
        constraints: const AiGenerateConstraints(
          preferCollection: true,
          collectionOnly: false,
          budgetLimitBrl: 50,
        ),
        marketByNameLower: const {
          'commander card': AiGenerateCardMarketState(
            availableQuantity: 1,
            estimatedUnitPriceBrl: 80,
          ),
          'owned once': AiGenerateCardMarketState(
            availableQuantity: 1,
            estimatedUnitPriceBrl: 10,
          ),
          'missing price': AiGenerateCardMarketState(
            availableQuantity: 0,
            estimatedUnitPriceBrl: null,
          ),
          'market card': AiGenerateCardMarketState(
            availableQuantity: 0,
            estimatedUnitPriceBrl: 45,
          ),
        },
      );

      expect(audit.canSave, isFalse);
      expect(audit.requiredQuantity, 15);
      expect(audit.collectionMatchedQuantity, 12);
      expect(audit.purchaseRequiredQuantity, 3);
      expect(audit.missingPriceQuantity, 1);
      expect(audit.estimatedPurchaseTotalBrl, 55);
      expect(audit.blockers.map((blocker) => blocker['code']), [
        'missing_price',
        'budget_exceeded',
      ]);
      final plains = audit.cardDetails.firstWhere(
        (detail) => detail['name'] == 'Plains',
      );
      expect(plains['price_status'], 'basic_land_zero_cost');
    });

    test('collection-only is hard and reports unavailable quantities', () {
      final audit = evaluateAiGenerateConstraints(
        generatedDeck: const {
          'cards': [
            {'name': 'Owned Once', 'quantity': 2},
          ],
        },
        constraints: const AiGenerateConstraints(
          preferCollection: true,
          collectionOnly: true,
          budgetLimitBrl: null,
        ),
        marketByNameLower: const {
          'owned once': AiGenerateCardMarketState(
            availableQuantity: 1,
            estimatedUnitPriceBrl: 10,
          ),
        },
      );

      expect(audit.canSave, isFalse);
      expect(audit.blockers.single['code'], 'collection_only_unavailable');
      expect(audit.blockers.single['quantity'], 1);
    });

    test('passes when all purchases have price and remain in budget', () {
      final audit = evaluateAiGenerateConstraints(
        generatedDeck: const {
          'cards': [
            {'name': 'Market Card', 'quantity': 2},
          ],
        },
        constraints: const AiGenerateConstraints(
          preferCollection: false,
          collectionOnly: false,
          budgetLimitBrl: 20,
        ),
        marketByNameLower: const {
          'market card': AiGenerateCardMarketState(
            availableQuantity: 0,
            estimatedUnitPriceBrl: 10,
          ),
        },
      );

      expect(audit.canSave, isTrue);
      expect(audit.blockers, isEmpty);
      expect(audit.estimatedPurchaseTotalBrl, 20);
    });
  });
}
