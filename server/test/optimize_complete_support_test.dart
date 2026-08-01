import 'package:postgres/postgres.dart';
import 'package:test/test.dart';

import '../lib/ai/optimize_complete_support.dart';

void main() {
  test('AI suggestion row accepts PostgreSQL NUMERIC CMC strings', () {
    final candidate = mapCompleteAiSuggestionCandidateRow(
      ResultRow(
        values: const [
          'card-id',
          'Test Card',
          'Sorcery',
          'Draw two cards.',
          ['U'],
          ['U'],
          '{2}{U}',
          '3.0',
          ['draw'],
          <Map<String, dynamic>>[],
          80,
        ],
        schema: ResultSchema(const []),
      ),
    );

    expect(candidate['cmc'], 3.0);
    expect(candidate['functional_tags'], const ['draw']);
    expect(candidate['best_role_score'], 80.0);
  });

  group('optimize complete mana balancing helpers', () {
    test('calculateCompleteMaxBasicAdditions caps basic overflow at 40', () {
      expect(calculateCompleteMaxBasicAdditions(38), equals(40));
      expect(calculateCompleteMaxBasicAdditions(36), equals(40));
      expect(calculateCompleteMaxBasicAdditions(32), equals(36));
    });

    test('Brawl uses a 60-card land target and cap', () {
      expect(resolveCompleteTargetLandCount(deckFormat: 'brawl'), equals(25));
      expect(
        resolveCompleteTargetLandCount(
          deckFormat: 'brawl',
          averageNonLandCmc: 4.2,
        ),
        equals(27),
      );
      expect(
        calculateCompleteMaxBasicAdditions(null, deckFormat: 'brawl'),
        equals(28),
      );
    });

    test('Commander target never drops below the automatic floor', () {
      expect(
        resolveCompleteTargetLandCount(
          deckFormat: 'commander',
          recommendedLandCount: 29,
        ),
        equals(34),
      );
    });

    test('average CMC is quantity-weighted and recovers missing metadata', () {
      final average = calculateCompleteAverageNonLandCmc([
        {
          'name': 'Known spell',
          'type_line': 'Sorcery',
          'mana_cost': '{1}{U}',
          'cmc': 2,
          'quantity': 2,
        },
        {
          'name': 'Recovered spell',
          'type_line': 'Creature',
          'mana_cost': '{4}{G}{G}',
          'quantity': 1,
        },
        {
          'name': 'Ignored land',
          'type_line': 'Basic Land — Forest',
          'quantity': 30,
        },
      ]);

      expect(average, closeTo(10 / 3, 0.0001));
      expect(
        calculateCompleteAverageNonLandCmc(const [
          {'name': 'Unknown spell', 'type_line': 'Enchantment', 'quantity': 1},
        ]),
        4,
      );
      expect(
        calculateCompleteAverageNonLandCmc(const [
          {
            'name': 'Plains',
            'type_line': 'Basic Land — Plains',
            'quantity': 20,
          },
        ]),
        3.5,
      );
    });

    test('buildWeightedBasicLandPlan favors the color with highest deficit', () {
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

    test(
      'buildWeightedBasicLandPlan returns wastes for colorless identity',
      () {
        final plan = buildWeightedBasicLandPlan(
          currentDeck: const [],
          commanderColorIdentity: const <String>{},
          slotsToAdd: 3,
        );

        expect(plan, equals(const ['Wastes', 'Wastes', 'Wastes']));
      },
    );

    test('virtual basics preserve canonical colored-source metadata', () {
      expect(buildVirtualBasicLandMetadata('Plains'), {
        'type_line': 'Basic Land — Plains',
        'oracle_text': '{T}: Add {W}.',
        'colors': const <String>[],
        'color_identity': const ['W'],
      });
      expect(buildVirtualBasicLandMetadata('Wastes'), {
        'type_line': 'Basic Land — Wastes',
        'oracle_text': '{T}: Add {C}.',
        'colors': const <String>[],
        'color_identity': const <String>[],
      });
    });

    test('second mana stage accounts for basics added by the first stage', () {
      final forestMetadata = buildVirtualBasicLandMetadata('Forest');
      final currentDeck = [
        _card(
          name: 'Simic commander',
          typeLine: 'Legendary Creature',
          manaCost: '{G}{U}',
          oracleText: '',
          quantity: 1,
          colors: const ['G', 'U'],
          cmc: 2,
        ),
        {
          'name': 'Forest',
          ...forestMetadata,
          'mana_cost': '',
          'quantity': 8,
          'cmc': 0.0,
        },
      ];

      final plan = buildWeightedBasicLandPlan(
        currentDeck: currentDeck,
        commanderColorIdentity: const {'G', 'U'},
        slotsToAdd: 4,
      );

      expect(
        plan.where((name) => name == 'Island').length,
        greaterThan(plan.where((name) => name == 'Forest').length),
      );
    });

    test(
      'buildCompleteColorDemandMap falls back to color identity when mana cost has no explicit symbols',
      () {
        final demand = buildCompleteColorDemandMap(
          currentDeck: [
            _card(
              name: 'Colorless Simic Spell',
              typeLine: 'Sorcery',
              manaCost: '{3}',
              oracleText: 'Draw a card.',
              quantity: 2,
              colors: const ['G', 'U'],
              cmc: 3,
            ),
          ],
          commanderColorIdentity: {'G', 'U'},
        );

        expect(demand['G'], equals(2));
        expect(demand['U'], equals(2));
      },
    );
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
