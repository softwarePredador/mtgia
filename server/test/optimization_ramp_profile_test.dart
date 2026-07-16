import 'package:test/test.dart';

import '../lib/ai/optimization_ramp_profile.dart';

void main() {
  group('optimization ramp profile generic floor', () {
    test('counts reusable mana rocks and dorks', () {
      final cases = {
        'Sol Ring': classifyOptimizationRampProfile(
          name: 'Sol Ring',
          typeLine: 'Artifact',
          oracleText: '{T}: Add {C}{C}.',
        ),
        'Arcane Signet': classifyOptimizationRampProfile(
          name: 'Arcane Signet',
          typeLine: 'Artifact',
          oracleText:
              '{T}: Add one mana of any color in your commander\'s color identity.',
        ),
        'Llanowar Elves': classifyOptimizationRampProfile(
          name: 'Llanowar Elves',
          typeLine: 'Creature — Elf Druid',
          oracleText: '{T}: Add {G}.',
        ),
      };

      expect(
        cases['Sol Ring']!.primaryKind,
        OptimizationRampProfileKind.manaRock,
      );
      expect(
        cases['Arcane Signet']!.primaryKind,
        OptimizationRampProfileKind.manaRock,
      );
      expect(
        cases['Llanowar Elves']!.primaryKind,
        OptimizationRampProfileKind.manaDork,
      );
      for (final profile in cases.values) {
        expect(profile.countsTowardGenericFloor, isTrue);
        expect(profile.requiresContextualPolicy, isFalse);
      }
    });

    test('counts land-to-battlefield and additional-land development', () {
      final lore = classifyOptimizationRampProfile(
        name: "Nature's Lore",
        typeLine: 'Sorcery',
        oracleText:
            'Search your library for a Forest card, put that card onto the battlefield, then shuffle.',
      );
      final exploration = classifyOptimizationRampProfile(
        name: 'Exploration',
        typeLine: 'Enchantment',
        oracleText: 'You may play an additional land on each of your turns.',
      );
      final walkingAtlas = classifyOptimizationRampProfile(
        name: 'Walking Atlas',
        typeLine: 'Artifact Creature — Construct',
        oracleText:
            '{T}: You may put a land card from your hand onto the battlefield.',
      );

      expect(lore.primaryKind, OptimizationRampProfileKind.landToBattlefield);
      expect(exploration.primaryKind, OptimizationRampProfileKind.extraLand);
      expect(
        walkingAtlas.kinds,
        contains(OptimizationRampProfileKind.landToBattlefield),
      );
      expect(lore.countsTowardGenericFloor, isTrue);
      expect(exploration.countsTowardGenericFloor, isTrue);
      expect(walkingAtlas.countsTowardGenericFloor, isTrue);
    });

    test('does not count fixing-only or library-to-hand effects', () {
      final fixing = classifyOptimizationRampProfile(
        name: 'Joiner Adept',
        typeLine: 'Creature — Elf Druid',
        oracleText: 'Lands you control have "{T}: Add one mana of any color."',
      );
      final landToHand = classifyOptimizationRampProfile(
        name: 'Sylvan Scrying',
        typeLine: 'Sorcery',
        oracleText:
            'Search your library for a land card, reveal it, put it into your hand, then shuffle.',
      );

      expect(fixing.primaryKind, OptimizationRampProfileKind.manaFixingOnly);
      expect(fixing.countsTowardGenericFloor, isFalse);
      expect(fixing.isAcceleration, isFalse);
      expect(landToHand.countsTowardGenericFloor, isFalse);
      expect(landToHand.isAcceleration, isFalse);
    });

    test('does not confuse nonland search-to-battlefield with land ramp', () {
      final treasureChest = classifyOptimizationRampProfile(
        name: 'Treasure Chest',
        typeLine: 'Artifact',
        oracleText:
            'Search your library for a card. If it is an artifact card, you '
            'may put it onto the battlefield. Otherwise, put it into your hand.',
      );
      final planeswalkerTutor = classifyOptimizationRampProfile(
        name: 'The Legend of Arena',
        typeLine: 'Legendary Enchantment — Saga',
        oracleText:
            'Search your library for a planeswalker card, put it onto the '
            'battlefield, then shuffle.',
      );

      expect(treasureChest.countsTowardGenericFloor, isFalse);
      expect(planeswalkerTutor.countsTowardGenericFloor, isFalse);
    });

    test('keeps cost reduction contextual', () {
      final profile = classifyOptimizationRampProfile(
        name: 'Ruby Medallion',
        typeLine: 'Artifact',
        oracleText: 'Red spells you cast cost {1} less to cast.',
      );

      expect(profile.primaryKind, OptimizationRampProfileKind.costReduction);
      expect(profile.isAcceleration, isTrue);
      expect(profile.countsTowardGenericFloor, isFalse);
      expect(profile.requiresContextualPolicy, isTrue);
    });

    test('keeps rituals and consumable mana outside generic floor', () {
      final ritual = classifyOptimizationRampProfile(
        name: 'Seething Song',
        typeLine: 'Instant',
        oracleText: 'Add {R}{R}{R}{R}{R}.',
      );
      final petal = classifyOptimizationRampProfile(
        name: 'Lotus Petal',
        typeLine: 'Artifact',
        oracleText: '{T}, Sacrifice this artifact: Add one mana of any color.',
      );

      expect(ritual.primaryKind, OptimizationRampProfileKind.ritual);
      expect(petal.primaryKind, OptimizationRampProfileKind.consumableMana);
      expect(ritual.countsTowardGenericFloor, isFalse);
      expect(petal.countsTowardGenericFloor, isFalse);
      expect(ritual.requiresContextualPolicy, isTrue);
      expect(petal.requiresContextualPolicy, isTrue);
    });

    test('keeps land untap outside generic floor', () {
      final profile = classifyOptimizationRampProfile(
        name: 'Early Harvest',
        typeLine: 'Instant',
        oracleText: 'Target player untaps all basic lands they control.',
      );

      expect(profile.primaryKind, OptimizationRampProfileKind.landUntap);
      expect(profile.countsTowardGenericFloor, isFalse);
      expect(profile.requiresContextualPolicy, isTrue);
    });

    test('keeps Treasure creation and multipliers contextual', () {
      final oneShot = classifyOptimizationRampProfile(
        name: 'Big Score',
        typeLine: 'Instant',
        oracleText:
            'As an additional cost to cast this spell, discard a card. Draw two cards and create two Treasure tokens.',
      );
      final multiplier = classifyOptimizationRampProfile(
        name: 'Xorn',
        typeLine: 'Creature — Elemental',
        oracleText:
            'If you would create one or more Treasure tokens, instead create those tokens plus an additional Treasure token.',
      );

      expect(
        oneShot.kinds,
        contains(OptimizationRampProfileKind.treasureCreation),
      );
      expect(
        multiplier.kinds,
        contains(OptimizationRampProfileKind.treasureMultiplier),
      );
      expect(oneShot.countsTowardGenericFloor, isFalse);
      expect(multiplier.countsTowardGenericFloor, isFalse);
      expect(oneShot.requiresContextualPolicy, isTrue);
      expect(multiplier.requiresContextualPolicy, isTrue);
    });

    test('does not turn opponent Treasure compensation into acceleration', () {
      final profile = classifyOptimizationRampProfile(
        name: 'An Offer You Cannot Refuse',
        typeLine: 'Instant',
        oracleText:
            'Counter target noncreature spell. Its controller creates two Treasure tokens.',
      );

      expect(profile.primaryKind, OptimizationRampProfileKind.none);
      expect(profile.isAcceleration, isFalse);
      expect(profile.countsTowardGenericFloor, isFalse);
    });

    test('keeps lands in the mana-base lane', () {
      final profile = classifyOptimizationRampProfile(
        name: 'Command Tower',
        typeLine: 'Land',
        oracleText:
            '{T}: Add one mana of any color in your commander\'s color identity.',
      );

      expect(profile.primaryKind, OptimizationRampProfileKind.landManaBase);
      expect(profile.isAcceleration, isFalse);
      expect(profile.countsTowardGenericFloor, isFalse);
    });

    test('serializes the additive contract deterministically', () {
      final json =
          classifyOptimizationRampProfile(
            name: 'Ruby Medallion',
            typeLine: 'Artifact',
            oracleText: 'Red spells you cast cost {1} less to cast.',
          ).toJson();

      expect(json['schema_version'], optimizationRampProfileSchemaVersion);
      expect(json['primary_kind'], 'cost_reduction');
      expect(json['kinds'], ['cost_reduction']);
      expect(json['counts_toward_generic_floor'], isFalse);
      expect(json['is_acceleration'], isTrue);
      expect(json['requires_contextual_policy'], isTrue);
    });

    test('supports optimizer card maps without changing shared call sites', () {
      final profile = optimizationRampProfileForCard(const {
        'name': 'Arcane Signet',
        'type_line': 'Artifact',
        'oracle_text':
            '{T}: Add one mana of any color in your commander\'s color identity.',
        'mana_cost': '{2}',
        'cmc': 2,
      });

      expect(profile.primaryKind, OptimizationRampProfileKind.manaRock);
      expect(profile.countsTowardGenericFloor, isTrue);
    });

    test(
      'aggregates structural and contextual ramp without counting lands',
      () {
        final summary = summarizeOptimizationRampProfilesForDeck(const [
          {
            'name': 'Sol Ring',
            'type_line': 'Artifact',
            'oracle_text': '{T}: Add {C}{C}.',
            'quantity': 2,
          },
          {
            'name': 'Big Score',
            'type_line': 'Instant',
            'oracle_text': 'Draw two cards and create two Treasure tokens.',
            'quantity': 3,
          },
          {
            'name': 'Ruby Medallion',
            'type_line': 'Artifact',
            'oracle_text': 'Red spells you cast cost {1} less to cast.',
          },
          {
            'name': 'Command Tower',
            'type_line': 'Land',
            'oracle_text': '{T}: Add one mana of any color.',
            'quantity': 4,
          },
        ]);

        expect(summary.rampFloor, 2);
        expect(summary.rampContextual, 4);
        expect(summary.rampProfiled, 6);
        expect(summary.kindCounts['mana_rock'], 2);
        expect(summary.kindCounts['treasure_creation'], 3);
        expect(summary.kindCounts['cost_reduction'], 1);
        expect(summary.kindCounts, isNot(contains('land_mana_base')));
        expect(summary.toJson()['ramp_floor'], 2);
        expect(summary.toJson()['ramp_contextual'], 4);
      },
    );
  });
}
