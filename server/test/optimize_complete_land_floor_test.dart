import 'package:server/ai/optimize_complete_support.dart';
import 'package:test/test.dart';

void main() {
  test(
    'complete payload fails closed when final Commander deck has 9 lands',
    () {
      final cards = <Map<String, dynamic>>[
        const {
          'card_id': 'commander',
          'name': 'Lorehold, the Historian',
          'type_line': 'Legendary Creature — Elder Dragon',
          'quantity': 1,
          'is_commander': true,
        },
        const {
          'card_id': 'command-tower',
          'name': 'Command Tower',
          'type_line': 'Land',
          'quantity': 1,
        },
        for (var index = 0; index < 8; index++)
          {
            'card_id': 'land-$index',
            'name': 'Utility Land $index',
            'type_line': 'Land',
            'quantity': 1,
          },
        for (var index = 0; index < 90; index++)
          {
            'card_id': 'spell-$index',
            'name': 'Spell $index',
            'type_line': 'Sorcery',
            'quantity': 1,
          },
      ];
      final state = CompleteBuildAccumulator.fromDeck(
        allCardData: cards,
        originalCountsById: {
          for (final card in cards)
            card['card_id'] as String: card['quantity'] as int,
        },
        currentTotalCards: 100,
      );

      final payload = buildCompleteIntermediatePayload(
        state: state,
        maxTotal: 100,
        currentTotalCards: 100,
        targetArchetype: 'midrange',
        deckFormat: 'commander',
      );

      expect(
        (payload['quality_error'] as Map)['code'],
        'COMPLETE_QUALITY_LAND_FLOOR',
      );
      expect(
        (payload['consistency_slo'] as Map)['land_floor_satisfied'],
        isFalse,
      );
      expect(payload['mana_foundation_satisfied'], isFalse);
    },
  );

  test('complete payload accepts the strategic floor of 34 lands', () {
    final cards = <Map<String, dynamic>>[
      const {
        'card_id': 'commander',
        'name': 'Lorehold, the Historian',
        'type_line': 'Legendary Creature — Elder Dragon',
        'quantity': 1,
        'is_commander': true,
      },
      const {
        'card_id': 'plains',
        'name': 'Plains // Plains',
        'type_line': 'Basic Land — Plains',
        'quantity': 17,
      },
      const {
        'card_id': 'mountain',
        'name': 'Mountain // Mountain',
        'type_line': 'Basic Land — Mountain',
        'quantity': 17,
      },
      for (var index = 0; index < 65; index++)
        {
          'card_id': 'spell-$index',
          'name': 'Spell $index',
          'type_line': 'Sorcery',
          'quantity': 1,
        },
    ];
    final state = CompleteBuildAccumulator.fromDeck(
      allCardData: cards,
      originalCountsById: {
        for (final card in cards)
          card['card_id'] as String: card['quantity'] as int,
      },
      currentTotalCards: 100,
    );

    final payload = buildCompleteIntermediatePayload(
      state: state,
      maxTotal: 100,
      currentTotalCards: 100,
      targetArchetype: 'midrange',
      deckFormat: 'commander',
    );

    expect(payload['quality_error'], isNull);
    expect((payload['consistency_slo'] as Map)['land_floor_satisfied'], isTrue);
    expect(payload['mana_foundation_satisfied'], isTrue);
  });
}
