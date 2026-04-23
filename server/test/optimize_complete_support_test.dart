import 'package:test/test.dart';

import '../lib/ai/optimize_complete_support.dart';

void main() {
  group('optimize complete mana balancing helpers', () {
    test('calculateCompleteMaxBasicAdditions caps basic overflow at 40', () {
      expect(calculateCompleteMaxBasicAdditions(38), equals(40));
      expect(calculateCompleteMaxBasicAdditions(36), equals(40));
      expect(calculateCompleteMaxBasicAdditions(32), equals(36));
    });

    test('buildWeightedBasicLandPlan favors the color with highest deficit',
        () {
      final currentDeck = [
        _card(
          name: 'Talrand, Sky Summoner',
          typeLine: 'Legendary Creature',
          manaCost: '{2}{U}{U}',
          oracleText:
              'Whenever you cast an instant or sorcery spell, create a 2/2 blue Drake creature token with flying.',
          quantity: 1,
          colors: const ['U'],
          cmc: 4,
        ),
        _card(
          name: 'Counterspell',
          typeLine: 'Instant',
          manaCost: '{U}{U}',
          oracleText: 'Counter target spell.',
          quantity: 8,
          colors: const ['U'],
          cmc: 2,
        ),
        _card(
          name: 'Growth Spiral',
          typeLine: 'Instant',
          manaCost: '{G}{U}',
          oracleText:
              'Draw a card. You may put a land card from your hand onto the battlefield.',
          quantity: 2,
          colors: const ['G', 'U'],
          cmc: 2,
        ),
        _card(
          name: 'Forest',
          typeLine: 'Basic Land',
          manaCost: '',
          oracleText: '{T}: Add {G}.',
          quantity: 4,
          cmc: 0,
        ),
        _card(
          name: 'Island',
          typeLine: 'Basic Land',
          manaCost: '',
          oracleText: '{T}: Add {U}.',
          quantity: 1,
          cmc: 0,
        ),
      ];

      final plan = buildWeightedBasicLandPlan(
        currentDeck: currentDeck,
        commanderColorIdentity: {'U', 'G'},
        slotsToAdd: 6,
      );

      expect(plan.length, equals(6));
      expect(
        plan.where((name) => name == 'Island').length,
        greaterThan(plan.where((name) => name == 'Forest').length),
      );
    });

    test('buildWeightedBasicLandPlan returns wastes for colorless identity',
        () {
      final plan = buildWeightedBasicLandPlan(
        currentDeck: const [],
        commanderColorIdentity: const <String>{},
        slotsToAdd: 3,
      );

      expect(plan, equals(const ['Wastes', 'Wastes', 'Wastes']));
    });
  });
}

Map<String, dynamic> _card({
  required String name,
  required String typeLine,
  required String manaCost,
  required String oracleText,
  required int quantity,
  required double cmc,
  List<String> colors = const <String>[],
}) {
  return {
    'name': name,
    'type_line': typeLine,
    'mana_cost': manaCost,
    'oracle_text': oracleText,
    'quantity': quantity,
    'colors': colors,
    'color_identity': colors,
    'cmc': cmc,
  };
}
