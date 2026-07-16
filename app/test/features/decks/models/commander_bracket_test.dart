import 'package:flutter_test/flutter_test.dart';
import 'package:manaloom/features/decks/models/commander_bracket.dart';

void main() {
  test('exposes the current five official Commander bracket labels', () {
    expect(commanderBracketOptions.map((option) => option.label), [
      'Exhibition',
      'Core',
      'Upgraded',
      'Optimized',
      'cEDH',
    ]);
    expect(commanderBracketLabel(4), 'Optimized');
    expect(commanderBracketLabel(5), 'cEDH');
  });

  test('rejects values outside the Commander bracket contract', () {
    expect(isCommanderBracket(null), isFalse);
    expect(isCommanderBracket(0), isFalse);
    expect(isCommanderBracket(1), isTrue);
    expect(isCommanderBracket(5), isTrue);
    expect(isCommanderBracket(6), isFalse);
    expect(commanderBracketLabel(6), 'Bracket desconhecido');
  });
}
