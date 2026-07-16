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
    },
  );

  test('parseOptimizeRouteRequest preserves route quirks intentionally', () {
    final request = parseOptimizeRouteRequest({
      'deck_id': 'deck-2',
      'archetype': 'aggro',
      'bracket': '3',
      'keep_theme': false,
      'mode': ' incomplete draft ',
      'intensity': 'aggressive',
      '_force_sync': false,
      'force_sync': true,
      'async': 'truthy but not true',
    });

    expect(request.parsedBracket, 3);
    expect(request.parsedKeepTheme, isFalse);
    expect(request.requestedModeRaw, 'incomplete draft');
    expect(request.requestMode, 'complete');
    expect(request.intensity.selected, 'aggressive');
    expect(request.forceSyncExecutor, isTrue);
    expect(request.asyncRequested, isFalse);
    expect(request.hasBracketOverride, isTrue);
    expect(request.hasKeepThemeOverride, isTrue);
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
    },
  );

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
