import 'dart:io';

import 'package:server/ai/optimize_route_recommendation_context_support.dart';
import 'package:server/ai/optimize_route_request_support.dart';
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

      final basic = buildOptimizeRecommendationMarketDetail(
        ownedQuantity: 0,
        estimatedPriceBrl: null,
        usdToBrlRate: 5.5,
        isBasicLand: true,
      );
      expect(basic['purchase_required'], isFalse);
      expect(basic['source'], 'basic_land_zero_cost');
      expect(basic['price_status'], 'not_required');
      expect(basic['budget_cost_brl'], 0.0);
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

    test('basic lands never consume the purchase budget', () {
      final result = applyOptimizeBudgetConstraint(
        additions: const ['Plains', 'Snow-Covered Mountain', 'Market'],
        detailsByNameLower: {
          'market': buildOptimizeRecommendationMarketDetail(
            ownedQuantity: 0,
            estimatedPriceBrl: 1,
            usdToBrlRate: 5.5,
          ),
        },
        budgetLimitBrl: 0,
      );

      expect(result.additions, ['Plains', 'Snow-Covered Mountain']);
      expect(result.budgetUsedBrl, 0);
      expect(result.budgetExceededBlockedCount, 1);
    });

    test(
      'shared Complete ledger cannot reuse collection or restart budget across batches',
      () {
        final ledger = OptimizeRecommendationConstraintLedger();
        final details = {
          'single free copy': buildOptimizeRecommendationMarketDetail(
            ownedQuantity: 1,
            availableQuantity: 1,
            estimatedPriceBrl: 40,
            usdToBrlRate: 5.5,
          ),
          'market a': buildOptimizeRecommendationMarketDetail(
            ownedQuantity: 0,
            estimatedPriceBrl: 30,
            usdToBrlRate: 5.5,
          ),
          'market b': buildOptimizeRecommendationMarketDetail(
            ownedQuantity: 0,
            estimatedPriceBrl: 25,
            usdToBrlRate: 5.5,
          ),
        };

        final first = applyOptimizeBudgetConstraint(
          additions: const ['Single Free Copy', 'Market A'],
          detailsByNameLower: details,
          budgetLimitBrl: 50,
          ledger: ledger,
        );
        final second = applyOptimizeBudgetConstraint(
          additions: const ['Single Free Copy', 'Market B'],
          detailsByNameLower: details,
          budgetLimitBrl: 50,
          ledger: ledger,
        );

        expect(first.additions, ['Single Free Copy', 'Market A']);
        expect(first.collectionMatchedCount, 1);
        expect(first.budgetUsedBrl, 30);
        expect(second.additions, isEmpty);
        expect(second.collectionMatchedCount, 0);
        expect(second.budgetExceededBlockedCount, 2);
        expect(ledger.budgetUsedBrl, 30);
      },
    );

    test('expands Complete quantities before cumulative budget audit', () {
      expect(
        expandCompleteRecommendationAdditionNames({
          'additions_detailed': [
            {'name': 'Plains', 'quantity': 3},
            {'name': 'Arcane Signet', 'quantity': 1},
          ],
        }),
        ['Plains', 'Plains', 'Plains', 'Arcane Signet'],
      );
    });

    test(
      'Complete budget audit makes an over-budget preview non-actionable',
      () {
        final response = <String, dynamic>{
          'mode': 'complete',
          'can_apply': true,
          'learning_eligible': true,
          'additions_detailed': [
            {'name': 'Plains', 'quantity': 35},
            {'name': 'Mox Diamond', 'quantity': 1},
          ],
        };
        final context = parseOptimizeRecommendationContext({
          'prefer_collection': true,
          'budget_limit_brl': 100,
        });
        final result = OptimizeRecommendationConstraintResult(
          additions: List<String>.filled(35, 'Plains'),
          diagnostics: const {
            'input_count': 36,
            'output_count': 35,
            'budget_limit_brl': 100.0,
            'budget_used_brl': 0.0,
            'budget_exceeded_blocked_count': 1,
          },
          detailsByNameLower: {
            'mox diamond': buildOptimizeRecommendationMarketDetail(
              ownedQuantity: 0,
              estimatedPriceBrl: 3000,
              usdToBrlRate: 5.5,
            ),
          },
          validationWarnings: const [
            'Orçamento aplicado: uma carta foi bloqueada.',
          ],
        );

        applyCompleteRecommendationConstraintAuditResult(
          responseBody: response,
          result: result,
          context: context,
        );

        expect(
          (response['quality_error'] as Map)['code'],
          'COMPLETE_RECOMMENDATION_CONSTRAINTS_UNSATISFIED',
        );
        expect(response['can_apply'], isFalse);
        expect(response['learning_eligible'], isFalse);
        expect(
          response['apply_blockers'],
          contains('complete_recommendation_constraints_unsatisfied'),
        );
        expect(
          (response['recommendation_constraints'] as Map)['satisfied'],
          isFalse,
        );
        expect(
          ((response['additions_detailed'] as List).last
              as Map)['estimated_price_brl'],
          '3000.00',
        );
      },
    );

    test('sync and async Complete audit budget before accepting result', () {
      final sources = {
        'routes/ai/optimize/index.dart':
            'auditCompleteRecommendationConstraints',
        'lib/ai/optimize_route_internal.dart':
            'auditCompleteRecommendationConstraints',
      };
      for (final entry in sources.entries) {
        final source = File(entry.key).readAsStringSync();
        final audit = source.indexOf(entry.value);
        final qualityRead = source.indexOf(
          "finalQualityError = responseBody['quality_error']",
          audit,
        );
        expect(audit, greaterThanOrEqualTo(0), reason: entry.key);
        expect(qualityRead, greaterThan(audit), reason: entry.key);
      }
    });

    test('Complete AI receives collection and budget constraints', () {
      final serviceSource = File('lib/ai/otimizacao.dart').readAsStringSync();
      final routeSource =
          File('lib/ai/optimize_route_internal.dart').readAsStringSync();
      final completePromptStart = serviceSource.indexOf(
        'Future<Map<String, dynamic>> _callOpenAIComplete',
      );

      expect(completePromptStart, greaterThanOrEqualTo(0));
      expect(
        serviceSource.indexOf(
          '"prefer_collection": preferCollection',
          completePromptStart,
        ),
        greaterThan(completePromptStart),
      );
      expect(
        serviceSource.indexOf(
          '"budget_limit_brl": budgetLimitBrl',
          completePromptStart,
        ),
        greaterThan(completePromptStart),
      );
      expect(
        routeSource,
        contains(
          'preferCollection: recommendationContext.preferCollection == true',
        ),
      );
      expect(
        routeSource,
        contains('budgetLimitBrl: recommendationContext.budgetLimitBrl'),
      );
    });
  });
}
