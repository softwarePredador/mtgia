import 'package:test/test.dart';

import '../lib/ai/commander_learned_deck_support.dart';

void main() {
  group('parseCommanderLearnedDeckCards', () {
    test('parses quantities and merges duplicate card names', () {
      final cards = parseCommanderLearnedDeckCards('''
1 Korvold, Fae-Cursed King
2 Forest
- 1 Sol Ring # ramp
1 Command Tower (CMM) 123
''');

      expect(
        cards.map((card) => (card.name, card.quantity)).toList(),
        containsAll([
          ('Korvold, Fae-Cursed King', 1),
          ('Forest', 2),
          ('Sol Ring', 1),
          ('Command Tower', 1),
        ]),
      );
    });
  });
}
