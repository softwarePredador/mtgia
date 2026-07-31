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

  test('explains the distinct intent of all five brackets', () {
    final expectations = <int, List<String>>{
      1: ['Exhibition', '0 Game Changers', 'turno 9'],
      2: ['Core', '0 Game Changers', 'turno 8'],
      3: ['Upgraded', 'até 3 Game Changers', 'turno 6'],
      4: ['Optimized', 'turno 4', 'sem tratar a mesa como cEDH'],
      5: ['cEDH', 'sem piso de turno', 'vitória como prioridade'],
    };

    for (final entry in expectations.entries) {
      final guidance = commanderBracketGuidance(entry.key);
      for (final fragment in entry.value) {
        expect(
          guidance,
          contains(fragment),
          reason: 'Bracket ${entry.key} deve explicar "$fragment".',
        );
      }
    }
  });
}
