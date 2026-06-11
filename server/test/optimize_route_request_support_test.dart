import 'package:server/ai/optimize_route_request_support.dart';
import 'package:test/test.dart';

void main() {
  test('parseOptimizeRouteRequest preserves defaults and omitted overrides',
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
  });

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

  test('parseOptimizeRouteRequest tracks invalid intensity and missing fields',
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
  });
}
