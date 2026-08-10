import 'package:server/ai/optimize_printing_identity_support.dart';
import 'package:test/test.dart';

void main() {
  test('removal id always comes from a concrete printing in the deck', () {
    final cards = [
      {
        'name': 'Sol Ring',
        'card_id': 'printing-b',
        'quantity': 1,
        'is_commander': false,
      },
      {
        'name': 'Sol Ring',
        'card_id': 'printing-a',
        'quantity': 2,
        'is_commander': false,
      },
      {
        'name': 'Commander Name',
        'card_id': 'commander-printing',
        'quantity': 1,
        'is_commander': true,
      },
      {
        'name': 'Commander Name',
        'card_id': 'mainboard-printing',
        'quantity': 1,
        'is_commander': false,
      },
    ];

    final indexed = indexDeckRemovalPrintingsByName(cards);

    expect(indexed['sol ring']?['card_id'], 'printing-a');
    expect(indexed['commander name']?['card_id'], 'mainboard-printing');
    expect(
      cards.map((card) => card['card_id']),
      contains(indexed['sol ring']?['card_id']),
    );
  });

  test('ties are deterministic by printing id', () {
    final indexed = indexDeckRemovalPrintingsByName([
      {'name': 'Counterspell', 'card_id': 'printing-z', 'quantity': 1},
      {'name': 'counterspell', 'card_id': 'printing-a', 'quantity': 1},
    ]);

    expect(indexed['counterspell']?['card_id'], 'printing-a');
  });
}
