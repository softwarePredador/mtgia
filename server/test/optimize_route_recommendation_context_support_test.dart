import 'package:server/ai/optimize_route_recommendation_context_support.dart';
import 'package:test/test.dart';

void main() {
  group('optimize recommendation context support', () {
    test('estimates BRL price from the cheapest known USD print price', () {
      expect(
        estimateOptimizePriceBrl(
          priceUsd: '2.00',
          priceUsdFoil: 10,
          usdToBrlRate: 5.5,
        ),
        11.0,
      );
      expect(
        estimateOptimizePriceBrl(
          priceUsd: null,
          priceUsdFoil: 3,
          usdToBrlRate: 5,
        ),
        15.0,
      );
      expect(
        estimateOptimizePriceBrl(priceUsd: null, priceUsdFoil: null),
        isNull,
      );
    });

    test('builds market detail for owned and purchase-required cards', () {
      final owned = buildOptimizeRecommendationMarketDetail(
        ownedQuantity: 2,
        estimatedPriceBrl: 18.9,
        usdToBrlRate: 5.5,
      );
      final purchase = buildOptimizeRecommendationMarketDetail(
        ownedQuantity: 0,
        estimatedPriceBrl: 18.9,
        usdToBrlRate: 5.5,
      );

      expect(owned['collection_match'], isTrue);
      expect(owned['purchase_required'], isFalse);
      expect(owned['source'], 'collection_free');
      expect(purchase['collection_match'], isFalse);
      expect(purchase['purchase_required'], isTrue);
      expect(purchase['source'], 'market');
      expect(purchase['price_available'], isTrue);
      expect(purchase['price_status'], 'estimated');
      expect(purchase['budget_cost_brl'], 18.9);
      expect(purchase['price_brl'], 'R\$ 18.90');

      final missing = buildOptimizeRecommendationMarketDetail(
        ownedQuantity: 0,
        estimatedPriceBrl: null,
        usdToBrlRate: 5.5,
      );
      expect(missing['price_available'], isFalse);
      expect(missing['price_status'], 'missing');
      expect(missing.containsKey('budget_cost_brl'), isFalse);
    });

    test('blocks missing price and cumulative over-budget purchases', () {
      final result = applyOptimizeBudgetConstraint(
        additions: const [
          'Owned Once',
          'Owned Once',
          'Missing Price',
          'Affordable',
          'Too Expensive',
        ],
        detailsByNameLower: {
          'owned once': buildOptimizeRecommendationMarketDetail(
            ownedQuantity: 1,
            estimatedPriceBrl: 20,
            usdToBrlRate: 5.5,
          ),
          'missing price': buildOptimizeRecommendationMarketDetail(
            ownedQuantity: 0,
            estimatedPriceBrl: null,
            usdToBrlRate: 5.5,
          ),
          'affordable': buildOptimizeRecommendationMarketDetail(
            ownedQuantity: 0,
            estimatedPriceBrl: 30,
            usdToBrlRate: 5.5,
          ),
          'too expensive': buildOptimizeRecommendationMarketDetail(
            ownedQuantity: 0,
            estimatedPriceBrl: 60,
            usdToBrlRate: 5.5,
          ),
        },
        budgetLimitBrl: 50,
      );

      expect(result.additions, ['Owned Once', 'Owned Once', 'Affordable']);
      expect(result.collectionMatchedCount, 1);
      expect(result.purchaseRequiredCount, 2);
      expect(result.budgetUsedBrl, 50);
      expect(result.missingPriceBlockedCount, 1);
      expect(result.budgetExceededBlockedCount, 1);
      expect(result.blockedAdditions.map((entry) => entry['reason']), [
        'missing_price',
        'budget_exceeded',
      ]);
    });

    test('zero budget is a hard no-purchase constraint', () {
      final result = applyOptimizeBudgetConstraint(
        additions: const ['Owned', 'Market'],
        detailsByNameLower: {
          'owned': buildOptimizeRecommendationMarketDetail(
            ownedQuantity: 1,
            estimatedPriceBrl: null,
            usdToBrlRate: 5.5,
          ),
          'market': buildOptimizeRecommendationMarketDetail(
            ownedQuantity: 0,
            estimatedPriceBrl: 0.5,
            usdToBrlRate: 5.5,
          ),
        },
        budgetLimitBrl: 0,
      );

      expect(result.additions, ['Owned']);
      expect(result.budgetExceededBlockedCount, 1);
    });

    test('allocated copies do not count as available collection', () {
      final result = applyOptimizeBudgetConstraint(
        additions: const ['Allocated'],
        detailsByNameLower: {
          'allocated': buildOptimizeRecommendationMarketDetail(
            ownedQuantity: 1,
            availableQuantity: 0,
            estimatedPriceBrl: 10,
            usdToBrlRate: 5.5,
          ),
        },
        budgetLimitBrl: 0,
      );

      expect(result.additions, isEmpty);
      expect(result.collectionMatchedCount, 0);
      expect(result.budgetExceededBlockedCount, 1);
    });
  });
}
