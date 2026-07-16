import 'package:server/ai/optimize_route_request_support.dart';
import 'package:test/test.dart';

void main() {
  test(
    'parseOptimizeRouteRequest preserves defaults and omitted overrides',
    () {
      final request = parseOptimizeRouteRequest({
        'deck_id': 'deck-1',
        'archetype': 'control',
      });

      expect(request.deckId, 'deck-1');
      expect(request.archetype, 'control');
      expect(request.parsedBracket, isNull);
      expect(request.parsedKeepTheme, isNull);
      expect(request.requestedModeRaw, '');
      expect(request.requestMode, 'optimize');
      expect(request.intensity.selected, 'focused');
      expect(request.forceSyncExecutor, isFalse);
      expect(request.asyncRequested, isNull);
      expect(request.hasBracketOverride, isFalse);
      expect(request.hasKeepThemeOverride, isFalse);
      expect(request.hasRequiredDeckFields, isTrue);
      expect(request.telemetryDeckId, 'deck-1');
      expect(request.validationError, isNull);
    },
  );

  test('parseOptimizeRouteRequest rejects unsafe field types and sizes', () {
    final wrongType = parseOptimizeRouteRequest({
      'deck_id': 42,
      'archetype': 'control',
      'keep_theme': 'yes',
    });
    final oversized = parseOptimizeRouteRequest({
      'deck_id': 'deck-1',
      'archetype': 'x' * 121,
    });

    expect(wrongType.validationError, 'deck_id must be a string');
    expect(wrongType.hasRequiredDeckFields, isFalse);
    expect(oversized.validationError, 'archetype exceeds the allowed size');
    expect(oversized.hasRequiredDeckFields, isFalse);
  });

  test('parseOptimizeRouteRequest accepts strict public request fields', () {
    final request = parseOptimizeRouteRequest({
      'deck_id': 'deck-2',
      'archetype': 'aggro',
      'bracket': '3',
      'keep_theme': false,
      'mode': ' complete ',
      'intensity': 'aggressive',
      'async': false,
    });

    expect(request.parsedBracket, 3);
    expect(request.parsedKeepTheme, isFalse);
    expect(request.requestedModeRaw, 'complete');
    expect(request.requestMode, 'complete');
    expect(request.intensity.selected, 'aggressive');
    expect(request.forceSyncExecutor, isFalse);
    expect(request.asyncRequested, isFalse);
    expect(request.hasBracketOverride, isTrue);
    expect(request.hasKeepThemeOverride, isTrue);
    expect(request.validationError, isNull);
  });

  test('parseOptimizeRouteRequest reserves force sync for internal calls', () {
    final publicRequest = parseOptimizeRouteRequest({
      'deck_id': 'deck-2',
      'archetype': 'aggro',
      '_force_sync': true,
    });
    final legacyPublicRequest = parseOptimizeRouteRequest({
      'deck_id': 'deck-2',
      'archetype': 'aggro',
      'force_sync': true,
    });
    final internalRequest = parseOptimizeRouteRequest({
      'deck_id': 'deck-2',
      'archetype': 'aggro',
      '_force_sync': true,
      'async': false,
    }, allowForceSync: true);

    expect(
      publicRequest.validationError,
      'force_sync is not a public request field',
    );
    expect(publicRequest.forceSyncExecutor, isFalse);
    expect(
      legacyPublicRequest.validationError,
      'force_sync is not a public request field',
    );
    expect(legacyPublicRequest.forceSyncExecutor, isFalse);
    expect(internalRequest.validationError, isNull);
    expect(internalRequest.forceSyncExecutor, isTrue);
  });

  test('parseOptimizeRouteRequest rejects ambiguous modes and field types', () {
    final invalidMode = parseOptimizeRouteRequest({
      'deck_id': 'deck-2',
      'archetype': 'aggro',
      'mode': 'incomplete draft',
    });
    final invalidAsync = parseOptimizeRouteRequest({
      'deck_id': 'deck-2',
      'archetype': 'aggro',
      'async': 'true',
    });
    final invalidContext = parseOptimizeRouteRequest({
      'deck_id': 'deck-2',
      'archetype': 'aggro',
      'recommendation_context': 'collection-first',
    });

    expect(invalidMode.validationError, 'mode must be optimize or complete');
    expect(invalidAsync.validationError, 'async must be a boolean');
    expect(
      invalidContext.validationError,
      'recommendation_context must be an object',
    );
  });

  test(
    'parseOptimizeRouteRequest tracks invalid intensity and missing fields',
    () {
      final request = parseOptimizeRouteRequest({
        'bracket': 'not-a-number',
        'intensity': 'reckless',
        'async': true,
      });

      expect(request.deckId, isNull);
      expect(request.archetype, isNull);
      expect(request.parsedBracket, isNull);
      expect(request.intensity.valid, isFalse);
      expect(request.asyncRequested, isTrue);
      expect(request.hasRequiredDeckFields, isFalse);
      expect(request.telemetryDeckId, 'unknown');
      expect(request.validationError, 'bracket must be an integer');
    },
  );

  test('parseOptimizeRouteRequest rejects out-of-range brackets', () {
    for (final bracket in [0, 6]) {
      final request = parseOptimizeRouteRequest({
        'deck_id': 'deck-2',
        'archetype': 'aggro',
        'bracket': bracket,
      });

      expect(request.parsedBracket, isNull);
      expect(request.hasBracketOverride, isFalse);
      expect(request.validationError, 'bracket must be between 1 and 5');
    }
  });

  test('parseOptimizeRouteRequest accepts recommendation context from app', () {
    final request = parseOptimizeRouteRequest({
      'deck_id': 'deck-3',
      'archetype': 'spellslinger',
      'recommendation_context': {
        'prefer_collection': true,
        'budget_limit_brl': 125.6,
        'rebuild_intent': 'Upgraded',
        'report': 'before_after_shareable',
        'explain_swaps': true,
        'include_price_risk_curve_bracket': true,
        'future_toggle': 'ignored',
      },
    });

    final context = request.recommendationContext;
    expect(context.isPresent, isTrue);
    expect(context.preferCollection, isTrue);
    expect(context.budgetLimitBrl, 126);
    expect(context.rebuildIntent, 'upgraded');
    expect(context.report, 'before_after_shareable');
    expect(context.explainSwaps, isTrue);
    expect(context.includePriceRiskCurveBracket, isTrue);
    expect(context.unknownKeys, ['future_toggle']);
    expect(context.cacheSignature, contains('budget_limit_brl=126'));
  });

  test('recommendation context changes cache scope only when present', () {
    const baseCacheKey = 'v8:base';
    final withoutContext =
        parseOptimizeRouteRequest({
          'deck_id': 'deck-4',
          'archetype': 'control',
        }).recommendationContext;
    final withBudget =
        parseOptimizeRouteRequest({
          'deck_id': 'deck-4',
          'archetype': 'control',
          'recommendation_context': {
            'prefer_collection': true,
            'budget_limit_brl': 100,
            'rebuild_intent': 'casual',
          },
        }).recommendationContext;
    final withDifferentBudget =
        parseOptimizeRouteRequest({
          'deck_id': 'deck-4',
          'archetype': 'control',
          'recommendation_context': {
            'prefer_collection': true,
            'budget_limit_brl': 300,
            'rebuild_intent': 'casual',
          },
        }).recommendationContext;

    expect(
      qualifyOptimizeCacheKeyWithRecommendationContext(
        baseCacheKey,
        withoutContext,
      ),
      baseCacheKey,
    );
    expect(
      qualifyOptimizeCacheKeyWithRecommendationContext(
        baseCacheKey,
        withBudget,
      ),
      isNot(baseCacheKey),
    );
    expect(
      qualifyOptimizeCacheKeyWithRecommendationContext(
        baseCacheKey,
        withDifferentBudget,
      ),
      isNot(
        qualifyOptimizeCacheKeyWithRecommendationContext(
          baseCacheKey,
          withBudget,
        ),
      ),
    );
  });

  test('attachRecommendationContextToOptimizeResponse exposes diagnostics', () {
    final context =
        parseOptimizeRouteRequest({
          'deck_id': 'deck-5',
          'archetype': 'control',
          'recommendation_context': {
            'prefer_collection': true,
            'budget_limit_brl': 100,
            'rebuild_intent': 'optimized',
            'report': 'before_after_shareable',
            'explain_swaps': true,
          },
        }).recommendationContext;
    final response = <String, dynamic>{
      'constraints': {'keep_theme': true},
      'optimize_diagnostics': {'existing': true},
    };

    attachRecommendationContextToOptimizeResponse(response, context);

    expect(
      (response['constraints'] as Map)['recommendation_context'],
      containsPair('budget_limit_brl', 100),
    );
    final diagnostics =
        (response['optimize_diagnostics'] as Map)['recommendation_context']
            as Map;
    expect(diagnostics['requested'], isTrue);
    expect((diagnostics['values'] as Map)['rebuild_intent'], 'optimized');
    expect(
      (diagnostics['server_support'] as Map)['prefer_collection'],
      'accepted_for_binder_priority',
    );
    expect(
      (diagnostics['server_support'] as Map)['budget_limit_brl'],
      'accepted_for_budget_filter',
    );
    expect((response['optimize_diagnostics'] as Map)['existing'], isTrue);
  });
}
