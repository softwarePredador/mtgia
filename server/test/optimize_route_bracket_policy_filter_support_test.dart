import 'package:server/ai/optimize_route_bracket_policy_filter_support.dart';
import 'package:test/test.dart';

void main() {
  test('blocks current Game Changers in bracket 1', () {
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
          'name': 'Mana Vault',
          'type_line': 'Artifact',
          'oracle_text': '{T}: Add {C}{C}{C}.',
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
      validAdditions: const ['Mana Vault', 'Cultivate'],
    );

    expect(result.additions, ['Cultivate']);
    expect(result.blockedByBracket, hasLength(1));
    expect(result.blockedByBracket.single['name'], 'Mana Vault');
  });

  test(
    'preserves repeated allowed additions from route validAdditions list',
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
    },
  );

  test('bracket 3 evaluates additions after projected removals', () {
    final result = filterOptimizeAdditionsByBracketPolicy(
      bracket: 3,
      currentDeckCards: const [
        {
          'name': "Lion's Eye Diamond",
          'type_line': 'Artifact',
          'oracle_text': '',
          'quantity': 1,
        },
        {
          'name': 'Grim Monolith',
          'type_line': 'Artifact',
          'oracle_text': '',
          'quantity': 1,
        },
        {
          'name': 'Mox Diamond',
          'type_line': 'Artifact',
          'oracle_text': '',
          'quantity': 1,
        },
      ],
      additionsCardsData: const [
        {
          'name': 'Mana Vault',
          'type_line': 'Artifact',
          'oracle_text': '',
          'quantity': 1,
        },
      ],
      validAdditions: const ['Mana Vault'],
      projectedRemovals: const ["Lion's Eye Diamond"],
    );

    expect(result.additions, ['Mana Vault']);
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

  test('projected deck must repair pre-existing Core violations', () {
    const original = [
      {'name': "Lion's Eye Diamond", 'type_line': 'Artifact', 'quantity': 1},
      {
        'name': 'Cori-Steel Cutter',
        'type_line': 'Artifact — Equipment',
        'quantity': 1,
      },
    ];

    final unrepaired = assessOptimizeProjectedDeckBracket(
      bracket: 2,
      projectedDeckCards: buildOptimizeProjectedDeckForBracket(
        originalDeckCards: original,
        removals: const [],
        additionsCardsData: const [],
      ),
    );
    final repaired = assessOptimizeProjectedDeckBracket(
      bracket: 2,
      projectedDeckCards: buildOptimizeProjectedDeckForBracket(
        originalDeckCards: original,
        removals: const ["Lion's Eye Diamond"],
        additionsCardsData: const [
          {'name': 'Wear // Tear', 'type_line': 'Instant', 'quantity': 1},
        ],
      ),
    );

    expect(unrepaired.hardCompliant, isFalse);
    expect(repaired.hardCompliant, isTrue);
    expect(
      repaired.counts.values.fold<int>(0, (sum, count) => sum + count),
      greaterThanOrEqualTo(0),
    );
  });
}
