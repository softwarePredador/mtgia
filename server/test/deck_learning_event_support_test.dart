import 'package:server/ai/deck_learning_event_support.dart';
import 'package:test/test.dart';

void main() {
  group('deck learning event support', () {
    test('filters commander and duplicate cards from usage hot-card input', () {
      final cards = learningUsageCardsForCommander(
        commanderName: 'Lorehold, the Historian',
        cards: [
          {
            'name': 'Lorehold, the Historian',
            'quantity': 1,
            'is_commander': true,
          },
          {'name': 'Sol Ring', 'quantity': 1},
          {'name': 'sol ring', 'quantity': 1},
          {'name': 'Arcane Signet', 'quantity': 1},
          {'name': 'Lorehold, the Historian', 'quantity': 1},
          {'quantity': 1},
        ],
      );

      expect(
        cards.map((card) => card['name']),
        equals(['Sol Ring', 'Arcane Signet']),
      );
    });

    test('quantity total sums card quantities for learning events', () {
      expect(
        learningCardQuantityTotal([
          {'name': 'Commander', 'quantity': 1, 'is_commander': true},
          {'name': 'Mountain', 'quantity': 37},
          {'name': 'Sol Ring', 'quantity': '1'},
          {'name': 'Bad Input', 'quantity': 0},
        ]),
        equals(40),
      );
    });
  });
}
