import 'package:flutter_test/flutter_test.dart';
import 'package:manaloom/features/decks/providers/deck_provider_support.dart';

void main() {
  test('buildOptimizeRequestPayload includes recommendation context', () {
    final payload = buildOptimizeRequestPayload(
      deckId: 'deck-1',
      archetype: 'spellslinger',
      bracket: 2,
      keepTheme: true,
      intensity: OptimizeIntensity.focused,
      recommendationContext: const {
        'prefer_collection': true,
        'budget_limit_brl': 100,
        'rebuild_intent': 'upgraded',
      },
    );

    expect(payload['deck_id'], 'deck-1');
    expect(payload['recommendation_context'], {
      'prefer_collection': true,
      'budget_limit_brl': 100,
      'rebuild_intent': 'upgraded',
    });
  });
}
