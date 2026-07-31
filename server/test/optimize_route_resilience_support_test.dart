import 'dart:io';

import 'package:server/ai/optimize_route_recommendation_context_support.dart';
import 'package:server/ai/optimize_route_request_support.dart';
import 'package:server/ai/optimize_route_resilience_support.dart';
import 'package:test/test.dart';

void main() {
  group('constraint pair preservation', () {
    test('keeps the original removal paired with each surviving addition', () {
      final result = preserveOptimizePairsAfterConstraintFilter(
        removals: const ['Remove A', 'Remove B', 'Remove C'],
        additions: const ['Blocked A', 'Allowed B', 'Allowed C'],
        allowedAdditions: const ['Allowed B', 'Allowed C'],
      );

      expect(result.removals, const ['Remove B', 'Remove C']);
      expect(result.additions, const ['Allowed B', 'Allowed C']);
      expect(result.droppedPairCount, 1);
    });

    test('tracks duplicate additions as a multiset without shifting pairs', () {
      final result = preserveOptimizePairsAfterConstraintFilter(
        removals: const ['Remove A', 'Remove B', 'Remove C'],
        additions: const ['Shared', 'Blocked', 'Shared'],
        allowedAdditions: const ['Shared'],
      );

      expect(result.removals, const ['Remove A']);
      expect(result.additions, const ['Shared']);
      expect(result.droppedPairCount, 2);
    });
  });

  group('cached recommendation constraint result', () {
    test('recomputes collection-sensitive and constrained no-op hits', () {
      final collectionPreference = parseOptimizeRecommendationContext({
        'prefer_collection': true,
      });
      final budgetOnly = parseOptimizeRecommendationContext({
        'prefer_collection': false,
        'budget_limit_brl': 50,
      });

      expect(
        cachedRecommendationSelectionRequiresRecompute(
          context: collectionPreference,
          hasSelectedAdditions: true,
        ),
        isTrue,
      );
      expect(
        cachedRecommendationSelectionRequiresRecompute(
          context: budgetOnly,
          hasSelectedAdditions: false,
        ),
        isTrue,
      );
      expect(
        cachedRecommendationSelectionRequiresRecompute(
          context: budgetOnly,
          hasSelectedAdditions: true,
        ),
        isFalse,
      );
    });

    test(
      'refreshes current market details when all additions remain valid',
      () {
        final response = <String, dynamic>{
          'mode': 'optimize',
          'additions': ['Arcane Signet'],
          'additions_detailed': [
            {
              'name': 'Arcane Signet',
              'card_id': 'card-1',
              'quantity': 1,
              'available_quantity': 1,
            },
          ],
          'validation_warnings': ['existing'],
        };
        final result = OptimizeRecommendationConstraintResult(
          additions: const ['Arcane Signet'],
          diagnostics: const {
            'input_count': 1,
            'output_count': 1,
            'budget_limit_brl': 50.0,
            'budget_used_brl': 12.5,
          },
          detailsByNameLower: const {
            'arcane signet': {
              'available_quantity': 0,
              'purchase_required': true,
              'estimated_price_brl': '12.50',
            },
          },
          validationWarnings: const ['refreshed'],
        );

        final reusable = applyCachedOptimizeRecommendationConstraintResult(
          responseBody: response,
          originalAdditions: const ['Arcane Signet'],
          result: result,
        );

        expect(reusable, isTrue);
        expect(
          ((response['additions_detailed'] as List).single
              as Map)['available_quantity'],
          0,
        );
        expect(
          ((response['optimize_diagnostics']
                  as Map)['recommendation_constraints']
              as Map)['enforcement'],
          'optimize_cache_revalidated',
        );
        expect(response['validation_warnings'], const [
          'existing',
          'refreshed',
        ]);
      },
    );

    test('rejects a cache hit when current truth blocks an addition', () {
      final response = <String, dynamic>{
        'mode': 'optimize',
        'additions': ['Expensive', 'Affordable'],
        'additions_detailed': [
          {'name': 'Expensive', 'card_id': 'card-1', 'quantity': 1},
          {'name': 'Affordable', 'card_id': 'card-2', 'quantity': 1},
        ],
      };
      final before = Map<String, dynamic>.from(response);
      final result = OptimizeRecommendationConstraintResult(
        additions: const ['Affordable'],
        diagnostics: const {'input_count': 2, 'output_count': 1},
        detailsByNameLower: const {},
        validationWarnings: const [],
      );

      final reusable = applyCachedOptimizeRecommendationConstraintResult(
        responseBody: response,
        originalAdditions: const ['Expensive', 'Affordable'],
        result: result,
      );

      expect(reusable, isFalse);
      expect(response, before);
    });
  });

  test('unexpected Complete async payload has a fail-closed quality error', () {
    final error = buildUnexpectedCompleteAsyncPayloadQualityError({
      'mode': 'optimize',
      'additions': ['Unexpected'],
    });

    expect(error['code'], 'COMPLETE_ASYNC_UNEXPECTED_PAYLOAD');
    expect(error['observed_mode'], 'optimize');
    expect(error['has_additions_detailed'], isFalse);
  });

  test('route revalidates a cache hit before issuing apply authorization', () {
    final source = File('routes/ai/optimize/index.dart').readAsStringSync();
    final cacheBlock = source.indexOf('if (cachedResponse != null)');
    final revalidation = source.indexOf(
      'revalidateCachedOptimizeRecommendationConstraints',
      cacheBlock,
    );
    final authorization = source.indexOf(
      'attachOptimizeApplyAuthorizationToResponse',
      revalidation,
    );

    expect(cacheBlock, greaterThanOrEqualTo(0));
    expect(revalidation, greaterThan(cacheBlock));
    expect(authorization, greaterThan(revalidation));
  });

  test('Complete async unexpected payload fails instead of being cached', () {
    final source =
        File('lib/ai/optimize_route_internal.dart').readAsStringSync();

    expect(source, contains('buildUnexpectedCompleteAsyncPayloadQualityError'));
    expect(source, isNot(contains("'complete_pipeline_fallback'")));
    expect(
      source.toLowerCase(),
      contains('complete mode produziu um resultado'),
    );
  });
}
