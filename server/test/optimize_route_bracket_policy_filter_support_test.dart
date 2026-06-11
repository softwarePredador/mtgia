import 'package:server/ai/optimize_route_bracket_policy_filter_support.dart';
import 'package:test/test.dart';

void main() {
  test('blocks additions that exceed current bracket budget', () {
    final result = filterOptimizeAdditionsByBracketPolicy(
      bracket: 1,
      currentDeckCards: const [
        {
          'name': 'Sol Ring',
          'type_line': 'Artifact',
          'oracle_text': '{T}: Add {C}{C}.',
          'quantity': 1,
        },
      ],
      additionsCardsData: const [
        {
          'name': 'Mana Crypt',
          'type_line': 'Artifact',
          'oracle_text':
              'At the beginning of your upkeep, flip a coin. {T}: Add {C}{C}.',
          'quantity': 1,
        },
        {
          'name': 'Cultivate',
          'type_line': 'Sorcery',
          'oracle_text':
              'Search your library for up to two basic land cards, reveal them.',
          'quantity': 1,
        },
      ],
      validAdditions: const ['Mana Crypt', 'Cultivate'],
    );

    expect(result.additions, ['Cultivate']);
    expect(result.blockedByBracket, hasLength(1));
    expect(result.blockedByBracket.single['name'], 'Mana Crypt');
  });

  test('preserves repeated allowed additions from route validAdditions list',
      () {
    final result = filterOptimizeAdditionsByBracketPolicy(
      bracket: 4,
      currentDeckCards: const [],
      additionsCardsData: const [
        {
          'name': 'Mountain',
          'type_line': 'Basic Land — Mountain',
          'oracle_text': '({T}: Add {R}.)',
          'quantity': 1,
        },
      ],
      validAdditions: const ['Mountain', 'Mountain', 'Mountain'],
    );

    expect(result.additions, ['Mountain', 'Mountain', 'Mountain']);
    expect(result.blockedByBracket, isEmpty);
  });

  test('buildOptimizeBracketAdditionCardData normalizes nullable fields', () {
    final data = buildOptimizeBracketAdditionCardData(
      name: 'Arcane Signet',
      typeLine: null,
      oracleText: null,
    );

    expect(data, {
      'name': 'Arcane Signet',
      'type_line': '',
      'oracle_text': '',
      'quantity': 1,
    });
  });
}
