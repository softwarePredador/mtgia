import 'package:server/battle/battle_deck_admission.dart';
import 'package:test/test.dart';

void main() {
  const validCards = [
    {'name': 'Commander', 'quantity': 1, 'is_commander': true},
    {'name': 'Main deck', 'quantity': 99, 'is_commander': false},
  ];

  test('admits only validated Commander decks with exactly 100/1', () {
    expect(
      battleDeckAdmissionFailure(
        format: 'commander',
        validationState: 'validated',
        cards: validCards,
      ),
      isNull,
    );
  });

  test('rejects direct execution when preflight state is not validated', () {
    expect(
      battleDeckAdmissionFailures(
        format: 'modern',
        validationState: 'unknown',
        cards: const [
          {'name': 'Only card', 'quantity': 1, 'is_commander': false},
        ],
      ),
      containsAll([
        BattleDeckAdmissionFailure.format,
        BattleDeckAdmissionFailure.validation,
        BattleDeckAdmissionFailure.size,
        BattleDeckAdmissionFailure.commander,
      ]),
    );
  });

  test('rejects malformed quantities before runtime dispatch', () {
    expect(
      battleDeckAdmissionFailures(
        format: 'commander',
        validationState: 'validated',
        cards: const [
          {'name': 'Commander', 'quantity': 0, 'is_commander': true},
        ],
      ),
      contains(BattleDeckAdmissionFailure.quantity),
    );
  });
}
