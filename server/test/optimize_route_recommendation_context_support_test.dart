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
        estimateOptimizePriceBrl(
          priceUsd: null,
          priceUsdFoil: null,
        ),
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
      expect(owned['source'], 'collection');
      expect(purchase['collection_match'], isFalse);
      expect(purchase['purchase_required'], isTrue);
      expect(purchase['source'], 'market');
      expect(purchase['budget_cost_brl'], 18.9);
      expect(purchase['price_brl'], 'R\$ 18.90');
    });
  });
}
