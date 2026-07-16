import 'package:server/ai/functional_card_tags.dart';
import 'package:server/ai/optimization_functional_roles.dart';
import 'package:test/test.dart';

void main() {
  group('Functional Card Tags v1', () {
    test('infers requested deterministic tags for Commander staples', () {
      final cases = <String, Map<String, Object>>{
        'Sol Ring': _card(
          typeLine: 'Artifact',
          manaCost: '{1}',
          oracleText: '{T}: Add {C}{C}.',
          expected: const {'ramp'},
        ),
        'Arcane Signet': _card(
          typeLine: 'Artifact',
          manaCost: '{2}',
          oracleText:
              '{T}: Add one mana of any color in your commander\'s color identity.',
          expected: const {'ramp'},
        ),
        'Swords to Plowshares': _card(
          typeLine: 'Instant',
          manaCost: '{W}',
          oracleText: 'Exile target creature. Its controller gains life.',
          expected: const {'removal'},
        ),
        'Wrath of God': _card(
          typeLine: 'Sorcery',
          manaCost: '{2}{W}{W}',
          oracleText: 'Destroy all creatures. They can\'t be regenerated.',
          expected: const {'board_wipe'},
        ),
        'Skullclamp': _card(
          typeLine: 'Artifact - Equipment',
          manaCost: '{1}',
          oracleText:
              'Equipped creature gets +1/-1. Whenever equipped creature dies, draw two cards.',
          expected: const {'draw'},
        ),
        'Kozilek, Butcher of Truth': _card(
          typeLine: 'Legendary Creature - Eldrazi',
          manaCost: '{10}',
          oracleText:
              'When you cast this spell, draw four cards. Annihilator 4.',
          expected: const {'draw'},
        ),
        'Midnight Clock': _card(
          typeLine: 'Artifact',
          manaCost: '{2}{U}',
          oracleText:
              'When the twelfth hour counter is put on Midnight Clock, shuffle your hand and graveyard into your library, then draw seven cards.',
          expected: const {'draw'},
        ),
        'Reanimate': _card(
          typeLine: 'Sorcery',
          manaCost: '{B}',
          oracleText:
              'Put target creature card from a graveyard onto the battlefield under your control. You lose life equal to its mana value.',
          expected: const {'recursion', 'graveyard_synergy'},
        ),
        'Demonic Tutor': _card(
          typeLine: 'Sorcery',
          manaCost: '{1}{B}',
          oracleText: 'Search your library for a card, put it into your hand.',
          expected: const {'tutor', 'enabler'},
        ),
        'Thassa\'s Oracle': _card(
          typeLine: 'Creature - Merfolk Wizard',
          manaCost: '{U}{U}',
          oracleText:
              'When Thassa\'s Oracle enters, if your devotion to blue is greater than or equal to the number of cards in your library, you win the game.',
          expected: const {'wincon', 'combo_piece'},
        ),
        'Blood Artist': _card(
          typeLine: 'Creature - Vampire',
          manaCost: '{1}{B}',
          oracleText:
              'Whenever Blood Artist or another creature dies, target player loses 1 life and you gain 1 life.',
          expected: const {'aristocrat_payoff', 'drain', 'lifegain'},
        ),
        'Young Pyromancer': _card(
          typeLine: 'Creature - Human Shaman',
          manaCost: '{1}{R}',
          oracleText:
              'Whenever you cast an instant or sorcery spell, create a 1/1 red Elemental creature token.',
          expected: const {'token_maker', 'spellslinger'},
        ),
        'Ephemerate': _card(
          typeLine: 'Instant',
          manaCost: '{W}',
          oracleText:
              'Exile target creature you control, then return it to the battlefield under its owner\'s control.',
          expected: const {'blink', 'protection'},
        ),
        'Jeska\'s Will': _card(
          typeLine: 'Sorcery',
          manaCost: '{2}{R}',
          oracleText:
              'Choose one. If you control a commander as you cast this spell, you may choose both. Add {R} for each card in target opponent\'s hand. Exile the top three cards of your library. You may play them this turn.',
          expected: const {'ritual', 'big_spell', 'exile_value'},
        ),
        'Seething Song': _card(
          typeLine: 'Instant',
          manaCost: '{2}{R}',
          oracleText: 'Add {R}{R}{R}{R}{R}.',
          expected: const {'ramp', 'ritual'},
        ),
        'Pyretic Ritual': _card(
          typeLine: 'Instant',
          manaCost: '{1}{R}',
          oracleText: 'Add {R}{R}{R}.',
          expected: const {'ramp', 'ritual'},
        ),
      };

      for (final entry in cases.entries) {
        final tags =
            inferFunctionalCardTags(
              name: entry.key,
              typeLine: entry.value['type_line']! as String,
              oracleText: entry.value['oracle_text']! as String,
              manaCost: entry.value['mana_cost']! as String,
            ).map((tag) => tag.tag).toSet();

        expect(
          tags,
          containsAll(entry.value['expected']! as Set<String>),
          reason: entry.key,
        );
      }
    });

    test('avoids known false positives for owner-target and ETB hate text', () {
      final ephemerateTags =
          inferFunctionalCardTags(
            name: 'Ephemerate',
            typeLine: 'Instant',
            oracleText:
                'Exile target creature you control, then return it to the battlefield under its owner\'s control.',
            manaCost: '{W}',
          ).map((tag) => tag.tag).toSet();

      expect(ephemerateTags, isNot(contains('removal')));

      final hushwingTags =
          inferFunctionalCardTags(
            name: 'Hushwing Gryff',
            typeLine: 'Creature - Hippogriff',
            oracleText:
                'Creatures entering the battlefield don\'t cause abilities to trigger.',
            manaCost: '{2}{W}',
          ).map((tag) => tag.tag).toSet();

      expect(hushwingTags, isNot(contains('etb')));

      final natureLoreTags =
          inferFunctionalCardTags(
            name: 'Nature\'s Lore',
            typeLine: 'Sorcery',
            oracleText:
                'Search your library for a Forest card, put that card onto the battlefield, then shuffle.',
            manaCost: '{1}{G}',
          ).map((tag) => tag.tag).toSet();

      expect(natureLoreTags, contains('ramp'));
      expect(natureLoreTags, isNot(contains('tutor')));
      expect(natureLoreTags, isNot(contains('enabler')));

      final bloodstainedMireTags =
          inferFunctionalCardTags(
            name: 'Bloodstained Mire',
            typeLine: 'Land',
            oracleText:
                '{T}, Pay 1 life, Sacrifice this land: Search your library for a Swamp or Mountain card, put it onto the battlefield, then shuffle.',
          ).map((tag) => tag.tag).toSet();

      expect(bloodstainedMireTags, contains('land'));
      expect(bloodstainedMireTags, isNot(contains('ramp')));

      final lotusPetalTags =
          inferFunctionalCardTags(
            name: 'Lotus Petal',
            typeLine: 'Artifact',
            oracleText:
                '{T}, Sacrifice this artifact: Add one mana of any color.',
            manaCost: '{0}',
          ).map((tag) => tag.tag).toSet();

      expect(lotusPetalTags, contains('ramp'));
      expect(lotusPetalTags, isNot(contains('sacrifice_outlet')));

      final bloodstainedSemantic = inferSemanticCardAnalysisV2(
        name: 'Bloodstained Mire',
        typeLine: 'Land',
        oracleText:
            '{T}, Pay 1 life, Sacrifice this land: Search your library for a Swamp or Mountain card, put it onto the battlefield, then shuffle.',
      );
      expect(bloodstainedSemantic.tags.map((tag) => tag.tag), equals(['land']));
      expect(bloodstainedSemantic.enabler, isFalse);
      expect(bloodstainedSemantic.explanationReason, 'land_or_mana_source');

      final lotusPetalSemantic = inferSemanticCardAnalysisV2(
        name: 'Lotus Petal',
        typeLine: 'Artifact',
        oracleText: '{T}, Sacrifice this artifact: Add one mana of any color.',
        manaCost: '{0}',
      );
      expect(lotusPetalSemantic.tags.map((tag) => tag.tag), equals(['ramp']));
      expect(lotusPetalSemantic.enabler, isTrue);

      final erebosTags =
          inferFunctionalCardTags(
            name: 'Erebos, God of the Dead',
            typeLine: 'Legendary Enchantment Creature - God',
            oracleText:
                'Indestructible. Your opponents can\'t gain life. Pay 2 life: Draw a card.',
            manaCost: '{3}{B}',
          ).map((tag) => tag.tag).toSet();

      expect(erebosTags, isNot(contains('lifegain')));

      final arcadesTags =
          inferFunctionalCardTags(
            name: 'Arcades, the Strategist',
            typeLine: 'Legendary Creature - Elder Dragon',
            oracleText:
                'Each creature you control with defender assigns combat damage equal to its toughness rather than its power.',
            manaCost: '{1}{G}{W}{U}',
          ).map((tag) => tag.tag).toSet();

      expect(arcadesTags, isNot(contains('board_wipe')));

      final anthemTags =
          inferFunctionalCardTags(
            name: 'Glorious Anthem',
            typeLine: 'Enchantment',
            oracleText: 'Creatures you control get +1/+1.',
            manaCost: '{1}{W}{W}',
          ).map((tag) => tag.tag).toSet();

      expect(anthemTags, isNot(contains('board_wipe')));
    });

    test('detects external activated sacrifice costs without self/reminder noise', () {
      final cases = <String, ({String oracle, bool expected})>{
        'Altar of Dementia': (
          oracle:
              'Sacrifice a creature: Target player mills cards equal to the sacrificed creature\'s power.',
          expected: true,
        ),
        'Army Ants': (
          oracle: '{T}, Sacrifice a land: Destroy target land.',
          expected: true,
        ),
        'Alquist Proft, Master Sleuth': (
          oracle:
              'When Alquist Proft enters, investigate. (Create a Clue token. It\'s an artifact with "{2}, Sacrifice this token: Draw a card.")\n{X}{W}{U}{U}, {T}, Sacrifice a Clue: You draw X cards and gain X life.',
          expected: true,
        ),
        'Angel\'s Herald': (
          oracle:
              '{2}{W}, {T}, Sacrifice a green creature, a white creature, and a blue creature: Search your library for a card named Empyrial Archangel.',
          expected: true,
        ),
        'Baba Lysaga, Night Witch': (
          oracle:
              '{T}, Sacrifice up to three permanents: If there were three or more card types among them, draw three cards.',
          expected: true,
        ),
        'Animal Boneyard': (
          oracle:
              'Enchant land\nEnchanted land has "{T}, Sacrifice a creature: You gain life equal to its toughness."',
          expected: true,
        ),
        'Choice Vessel': (
          oracle: 'Sacrifice this artifact or another artifact: Add {C}{C}.',
          expected: true,
        ),
        'Lotus Petal': (
          oracle: '{T}, Sacrifice this artifact: Add one mana of any color.',
          expected: false,
        ),
        'Abandoned Outpost': (
          oracle:
              '{T}: Add {W}.\n{T}, Sacrifice this land: Add one mana of any color.',
          expected: false,
        ),
        'Arek, False Goldwarden': (
          oracle:
              '{3}{W}{B}, {T}, Sacrifice Arek, False Goldwarden: Target opponent loses X life.',
          expected: false,
        ),
        'Adric, Mathematical Genius': (
          oracle:
              'Ultimate Sacrifice — {1}{U}, Sacrifice Adric: Counter target activated or triggered ability.',
          expected: false,
        ),
        'A-Haywire Mite': (
          oracle:
              '{G}, Sacrifice Haywire Mite: Exile target noncreature artifact or enchantment.',
          expected: false,
        ),
        'Placeholder Vessel': (
          oracle: '{1}, Sacrifice ~: Draw a card.',
          expected: false,
        ),
        'Ancestors\' Aid': (
          oracle:
              'Create a Treasure token. (It\'s an artifact with "{T}, Sacrifice this token: Add one mana of any color.")',
          expected: false,
        ),
        'Apocalypse Demon': (
          oracle:
              'At the beginning of your upkeep, tap this creature unless you sacrifice another creature.',
          expected: false,
        ),
        'Ashad, the Lone Cyberman': (
          oracle:
              'The first artifact spell you cast each turn has casualty 2. (As you cast it, you may sacrifice a creature with power 2 or greater. When you do, copy it.)',
          expected: false,
        ),
        'Village Rites': (
          oracle:
              'As an additional cost to cast this spell, sacrifice a creature. Draw two cards.',
          expected: false,
        ),
        'Alchemist\'s Talent': (
          oracle:
              'Treasures you control have "{T}, Sacrifice this artifact: Add two mana of any one color."',
          expected: false,
        ),
      };

      for (final entry in cases.entries) {
        expect(
          looksLikeExternalSacrificeOutlet(
            name: entry.key,
            oracleText: entry.value.oracle,
          ),
          entry.value.expected,
          reason: entry.key,
        );
        final inferred = inferFunctionalCardTags(
          name: entry.key,
          typeLine: 'Artifact Creature — Test',
          oracleText: entry.value.oracle,
        );
        final outlet = inferred.where((tag) => tag.tag == 'sacrifice_outlet');
        expect(outlet.isNotEmpty, entry.value.expected, reason: entry.key);
        if (entry.value.expected) {
          expect(
            outlet.single.evidence,
            'external_activated_sacrifice_outlet_cost',
            reason: entry.key,
          );
        }
      }
    });

    test('keeps protection and wipe positives after mass-audit refinements', () {
      final wardTags =
          inferFunctionalCardTags(
            name: 'Coppercoat Vanguard',
            typeLine: 'Creature - Human Soldier',
            oracleText: 'Each other Human you control has ward {1}.',
            manaCost: '{1}{W}',
          ).map((tag) => tag.tag).toSet();

      expect(wardTags, contains('protection'));

      final blasphemousActTags =
          inferFunctionalCardTags(
            name: 'Blasphemous Act',
            typeLine: 'Sorcery',
            oracleText:
                'This spell costs {1} less to cast for each creature on the battlefield. Blasphemous Act deals 13 damage to each creature.',
            manaCost: '{8}{R}',
          ).map((tag) => tag.tag).toSet();

      expect(blasphemousActTags, contains('board_wipe'));

      final drownTags =
          inferFunctionalCardTags(
            name: 'Drown in Sorrow',
            typeLine: 'Sorcery',
            oracleText: 'All creatures get -2/-2 until end of turn. Scry 1.',
            manaCost: '{1}{B}{B}',
          ).map((tag) => tag.tag).toSet();

      expect(drownTags, contains('board_wipe'));
    });

    test('reduces generic payoff and enabler false positives', () {
      final blasphemousActTags =
          inferFunctionalCardTags(
            name: 'Blasphemous Act',
            typeLine: 'Sorcery',
            oracleText:
                'This spell costs {1} less to cast for each creature on the battlefield. Blasphemous Act deals 13 damage to each creature.',
            manaCost: '{8}{R}',
          ).map((tag) => tag.tag).toSet();

      expect(blasphemousActTags, contains('board_wipe'));
      expect(blasphemousActTags, isNot(contains('payoff')));

      final glimpseTags =
          inferFunctionalCardTags(
            name: 'Glimpse the Unthinkable',
            typeLine: 'Sorcery',
            oracleText: 'Target player mills ten cards.',
            manaCost: '{U}{B}',
          ).map((tag) => tag.tag).toSet();

      expect(glimpseTags, isNot(contains('enabler')));

      final greavesTags =
          inferFunctionalCardTags(
            name: 'Lightning Greaves',
            typeLine: 'Artifact - Equipment',
            oracleText: 'Equipped creature has haste and shroud. Equip {0}.',
            manaCost: '{2}',
          ).map((tag) => tag.tag).toSet();

      expect(greavesTags, containsAll({'enabler', 'protection'}));

      final oneRingTags =
          inferFunctionalCardTags(
            name: 'The One Ring',
            typeLine: 'Legendary Artifact',
            oracleText:
                'When The One Ring enters, if you cast it, you gain protection from everything until your next turn. {T}: Put a burden counter on The One Ring, then draw a card for each burden counter on it.',
            manaCost: '{4}',
          ).map((tag) => tag.tag).toSet();

      expect(oneRingTags, containsAll({'draw', 'protection'}));
      expect(oneRingTags, isNot(contains('payoff')));

      final impactTremorsTags =
          inferFunctionalCardTags(
            name: 'Impact Tremors',
            typeLine: 'Enchantment',
            oracleText:
                'Whenever a creature enters the battlefield under your control, Impact Tremors deals 1 damage to each opponent.',
            manaCost: '{1}{R}',
          ).map((tag) => tag.tag).toSet();

      expect(impactTremorsTags, contains('payoff'));
    });

    test(
      'preserves explicit alternate wins and recurring engines without reminder collisions',
      () {
        Set<String> tags({
          required String name,
          required String typeLine,
          required String oracleText,
        }) =>
            inferFunctionalCardTags(
              name: name,
              typeLine: typeLine,
              oracleText: oracleText,
            ).map((tag) => tag.tag).toSet();

        expect(
          tags(
            name: 'Door to Nothingness',
            typeLine: 'Artifact',
            oracleText:
                '{W}{W}{U}{U}{B}{B}{R}{R}{G}{G}, {T}, Sacrifice this artifact: Target player loses the game.',
          ),
          contains('wincon'),
        );
        expect(
          tags(
            name: "Maze's End",
            typeLine: 'Land',
            oracleText:
                'If you control ten or more Gates with different names, you win the game.',
          ),
          contains('wincon'),
        );
        expect(
          tags(
            name: 'Angel of Destiny',
            typeLine: 'Creature — Angel Cleric',
            oracleText:
                'At the beginning of your end step, if you have at least 15 life more than your starting life total, each player this creature attacked this turn loses the game.',
          ),
          contains('wincon'),
        );
        expect(
          tags(
            name: 'Vraska the Unseen',
            typeLine: 'Legendary Planeswalker — Vraska',
            oracleText:
                'Create three Assassin tokens with "Whenever this token deals combat damage to a player, that player loses the game."',
          ),
          contains('wincon'),
        );

        expect(
          tags(
            name: 'Fynn, the Fangbearer',
            typeLine: 'Legendary Creature — Human Warrior',
            oracleText:
                'Deathtouch. Whenever a creature you control with deathtouch deals combat damage to a player, that player gets two poison counters. (A player with ten or more poison counters loses the game.)',
          ),
          isNot(contains('wincon')),
        );
        expect(
          tags(
            name: 'Blood Artist',
            typeLine: 'Creature — Vampire',
            oracleText:
                'Whenever another creature dies, target opponent loses 1 life and you gain 1 life.',
          ),
          isNot(contains('wincon')),
        );
        expect(
          tags(
            name: 'Curse of Vengeance',
            typeLine: 'Enchantment — Aura Curse',
            oracleText:
                'When enchanted player loses the game, you gain X life and draw X cards.',
          ),
          isNot(contains('wincon')),
        );

        expect(
          tags(
            name: 'Cosmos Elixir',
            typeLine: 'Artifact',
            oracleText:
                'At the beginning of your end step, if your life total is greater than your starting life total, draw a card. Otherwise, you gain 2 life.',
          ),
          contains('engine'),
        );
        expect(
          tags(
            name: 'Adeline, Resplendent Cathar',
            typeLine: 'Legendary Creature — Human Knight',
            oracleText:
                'Whenever you attack, for each opponent, create a 1/1 white Human creature token that is tapped and attacking that player or a planeswalker they control.',
          ),
          contains('engine'),
        );
        expect(
          tags(
            name: 'A-Celebrity Fencer',
            typeLine: 'Creature — Elf Druid',
            oracleText:
                'Whenever another creature enters under your control, put a +1/+1 counter on this creature.',
          ),
          isNot(contains('engine')),
        );
      },
    );

    test('recognizes direct ETB triggers without cast-trigger spillover', () {
      Set<String> tags(String name, String oracleText) =>
          inferFunctionalCardTags(
            name: name,
            typeLine: 'Creature',
            oracleText: oracleText,
          ).map((tag) => tag.tag).toSet();

      expect(
        tags(
          'Angel of Unity',
          'Whenever this creature enters and whenever you cast a party spell, choose a party creature card in your hand.',
        ),
        contains('etb'),
      );
      expect(
        tags(
          'Malik, Grim Manipulator',
          'When Malik, Grim Manipulator enters, target opponent sacrifices a creature.',
        ),
        contains('etb'),
      );
      expect(
        tags(
          'Junkyard Scrapper',
          'Whenever a nontoken artifact you control enters, exile a card from your library.',
        ),
        contains('etb'),
      );
      expect(
        tags(
          'Arcane Archery',
          'When you cast a creature spell, that creature enters with an additional +1/+1 counter on it.',
        ),
        isNot(contains('etb')),
      );
    });

    test('shares strategic heuristic roles with optimize role adapter', () {
      final samples = <String, Map<String, Object>>{
        'Impact Tremors': {
          'type_line': 'Enchantment',
          'oracle_text':
              'Whenever a creature enters the battlefield under your control, Impact Tremors deals 1 damage to each opponent.',
          'expected_roles': {'payoff'},
        },
        'Isochron Scepter': {
          'type_line': 'Artifact',
          'oracle_text':
              'Imprint — When Isochron Scepter enters the battlefield, you may exile an instant card with mana value 2 or less from your hand. You may copy the exiled card. If you do, you may cast the copy without paying its mana cost.',
          'expected_roles': {'combo_piece'},
        },
        'The One Ring': {
          'type_line': 'Legendary Artifact',
          'oracle_text':
              'When The One Ring enters, if you cast it, you gain protection from everything until your next turn. {T}: Put a burden counter on The One Ring, then draw a card for each burden counter on it.',
          'expected_roles': {'engine'},
        },
        'Aetherflux Reservoir': {
          'type_line': 'Artifact',
          'oracle_text':
              'Whenever you cast a spell, you gain 1 life for each spell you\'ve cast this turn. Pay 50 life: Aetherflux Reservoir deals 50 damage to any target.',
          'expected_roles': {'wincon'},
        },
        'Demonic Tutor': {
          'type_line': 'Sorcery',
          'oracle_text':
              'Search your library for a card, put that card into your hand, then shuffle.',
          'expected_roles': {'enabler'},
        },
      };

      for (final entry in samples.entries) {
        final card = {
          'name': entry.key,
          'type_line': entry.value['type_line']! as String,
          'oracle_text': entry.value['oracle_text']! as String,
        };
        final optimizeRoles = optimizationFunctionalRolesForCard(card);
        final tagRoles =
            inferFunctionalCardTags(
              name: entry.key,
              typeLine: card['type_line']!,
              oracleText: card['oracle_text']!,
            ).map((tag) => tag.tag).toSet();
        final expectedRoles = entry.value['expected_roles']! as Set<String>;

        expect(optimizeRoles, containsAll(expectedRoles), reason: entry.key);
        expect(tagRoles, containsAll(expectedRoles), reason: entry.key);
      }
    });

    test('covers current Oracle families used by product Commander decks', () {
      final cases = <String, Map<String, Object>>{
        'Chaos Warp': _card(
          typeLine: 'Instant',
          manaCost: '{2}{R}',
          oracleText:
              'The owner of target permanent shuffles it into their library, then reveals the top card of their library.',
          expected: const {'removal'},
        ),
        'Back to Basics': _card(
          typeLine: 'Enchantment',
          manaCost: '{2}{U}',
          oracleText:
              "Nonbasic lands don't untap during their controllers' untap steps.",
          expected: const {'protection'},
        ),
        'Displacement Wave': _card(
          typeLine: 'Sorcery',
          manaCost: '{X}{U}{U}',
          oracleText:
              'Return all nonland permanents with mana value X or less to their owners\' hands.',
          expected: const {'board_wipe'},
        ),
        'Engulf the Shore': _card(
          typeLine: 'Instant',
          manaCost: '{3}{U}',
          oracleText:
              "Return to their owners' hands all creatures with toughness less than or equal to the number of Islands you control.",
          expected: const {'board_wipe'},
        ),
        'High Tide': _card(
          typeLine: 'Instant',
          manaCost: '{U}',
          oracleText:
              'Until end of turn, whenever a player taps an Island for mana, that player adds an additional {U}.',
          expected: const {'ramp'},
        ),
        'Sapphire Medallion': _card(
          typeLine: 'Artifact',
          manaCost: '{2}',
          oracleText: 'Blue spells you cast cost {1} less to cast.',
          expected: const {'ramp', 'enabler'},
        ),
        'Aggravated Assault': _card(
          typeLine: 'Enchantment',
          manaCost: '{2}{R}',
          oracleText:
              'Untap all creatures you control. After this main phase, there is an additional combat phase followed by an additional main phase.',
          expected: const {'wincon', 'engine'},
        ),
        'Manifold Key': _card(
          typeLine: 'Artifact',
          manaCost: '{1}',
          oracleText:
              "{1}, {T}: Untap another target artifact. {3}, {T}: Target creature can't be blocked this turn.",
          expected: const {'engine'},
        ),
        'Phyrexian Metamorph': _card(
          typeLine: 'Artifact Creature — Phyrexian Shapeshifter',
          manaCost: '{3}{U/P}',
          oracleText:
              "You may have this creature enter as a copy of any artifact or creature on the battlefield, except it's an artifact in addition to its other types.",
          expected: const {'engine'},
        ),
        'Rings of Brighthearth': _card(
          typeLine: 'Artifact',
          manaCost: '{3}',
          oracleText:
              "Whenever you activate an ability, if it isn't a mana ability, you may pay {2}. If you do, copy that ability.",
          expected: const {'engine'},
        ),
        'Strionic Resonator': _card(
          typeLine: 'Artifact',
          manaCost: '{2}',
          oracleText:
              '{2}, {T}: Copy target triggered ability you control. You may choose new targets for the copy.',
          expected: const {'engine'},
        ),
        'Branching Evolution': _card(
          typeLine: 'Enchantment',
          manaCost: '{2}{G}',
          oracleText:
              'If one or more +1/+1 counters would be put on a creature you control, twice that many +1/+1 counters are put on that creature instead.',
          expected: const {'engine'},
        ),
        'Hardened Scales': _card(
          typeLine: 'Enchantment',
          manaCost: '{G}',
          oracleText:
              'If one or more +1/+1 counters would be put on a creature you control, that many plus one +1/+1 counters are put on it instead.',
          expected: const {'engine'},
        ),
        'Duskshell Crawler': _card(
          typeLine: 'Creature — Insect',
          manaCost: '{1}{G}',
          oracleText:
              'When this creature enters, put a +1/+1 counter on target creature. Each creature you control with a +1/+1 counter on it has trample.',
          expected: const {'engine', 'etb'},
        ),
        'Kaalia of the Vast': _card(
          typeLine: 'Legendary Creature — Human Cleric',
          manaCost: '{1}{R}{W}{B}',
          oracleText:
              'Flying. Whenever Kaalia attacks an opponent, you may put an Angel, Demon, or Dragon creature card from your hand onto the battlefield tapped and attacking that opponent.',
          expected: const {'engine'},
        ),
        'Isshin, Two Heavens as One': _card(
          typeLine: 'Legendary Creature — Human Samurai',
          manaCost: '{R}{W}{B}',
          oracleText:
              'If a creature attacking causes a triggered ability of a permanent you control to trigger, that ability triggers an additional time.',
          expected: const {'engine'},
        ),
        'Karlach, Fury of Avernus': _card(
          typeLine: 'Legendary Creature — Tiefling Barbarian',
          manaCost: '{4}{R}',
          oracleText:
              "Whenever you attack, if it's the first combat phase of the turn, untap all attacking creatures. After this phase, there is an additional combat phase.",
          expected: const {'wincon', 'engine'},
        ),
        'Master of Cruelties': _card(
          typeLine: 'Creature — Demon',
          manaCost: '{3}{B}{R}',
          oracleText:
              "Whenever this creature attacks a player and isn't blocked, that player's life total becomes 1.",
          expected: const {'wincon'},
        ),
        'Quicksilver Amulet': _card(
          typeLine: 'Artifact',
          manaCost: '{4}',
          oracleText:
              '{4}, {T}: You may put a creature card from your hand onto the battlefield.',
          expected: const {'engine'},
        ),
        'Relentless Assault': _card(
          typeLine: 'Sorcery',
          manaCost: '{2}{R}{R}',
          oracleText:
              'Untap all creatures that attacked this turn. After this main phase, there is an additional combat phase followed by an additional main phase.',
          expected: const {'wincon', 'engine'},
        ),
        'Peregrine Drake': _card(
          typeLine: 'Creature — Drake',
          manaCost: '{4}{U}',
          oracleText:
              'Flying. When this creature enters, untap up to five lands.',
          expected: const {'ramp', 'etb'},
        ),
        'Ancestral Statue': _card(
          typeLine: 'Artifact Creature — Golem',
          manaCost: '{4}',
          oracleText:
              "When this creature enters, return a nonland permanent you control to its owner's hand.",
          expected: const {'engine', 'etb'},
        ),
        'Shrieking Drake': _card(
          typeLine: 'Creature — Drake',
          manaCost: '{U}',
          oracleText:
              "Flying. When this creature enters, return a creature you control to its owner's hand.",
          expected: const {'engine', 'etb'},
        ),
        'Surrak Dragonclaw': _card(
          typeLine: 'Legendary Creature — Human Warrior',
          manaCost: '{2}{G}{U}{R}',
          oracleText:
              "Flash. This spell can't be countered. Creature spells you control can't be countered. Other creatures you control have trample.",
          expected: const {'protection'},
        ),
        'The Earth Crystal': _card(
          typeLine: 'Legendary Artifact',
          manaCost: '{2}{G}',
          oracleText:
              'Green spells you cast cost {1} less to cast. If one or more +1/+1 counters would be put on a creature you control, twice that many +1/+1 counters are put on that creature instead.',
          expected: const {'ramp', 'engine', 'enabler'},
        ),
        'The Ozolith': _card(
          typeLine: 'Legendary Artifact',
          manaCost: '{1}',
          oracleText:
              'Whenever a creature you control leaves the battlefield, if it had counters on it, put those counters on The Ozolith. At the beginning of combat on your turn, you may move all counters from The Ozolith onto target creature.',
          expected: const {'engine'},
        ),
      };

      for (final entry in cases.entries) {
        final tags =
            inferFunctionalCardTags(
              name: entry.key,
              typeLine: entry.value['type_line']! as String,
              oracleText: entry.value['oracle_text']! as String,
              manaCost: entry.value['mana_cost']! as String,
            ).map((tag) => tag.tag).toSet();
        final optimizeRoles = optimizationFunctionalRolesForCard({
          'name': entry.key,
          'type_line': entry.value['type_line']! as String,
          'oracle_text': entry.value['oracle_text']! as String,
          'mana_cost': entry.value['mana_cost']! as String,
        });

        expect(
          tags,
          containsAll(entry.value['expected']! as Set<String>),
          reason: 'functional tags: ${entry.key}',
        );
        expect(
          optimizeRoles,
          containsAll(
            (entry.value['expected']! as Set<String>).map(
              (role) => role == 'board_wipe' ? 'wipe' : role,
            ),
          ),
          reason: 'optimizer roles: ${entry.key}',
        );
      }
    });

    test('summarizes counts and bounded samples using quantities', () {
      final summary = summarizeFunctionalTagsForDeck([
        {
          'name': 'Sol Ring',
          'type_line': 'Artifact',
          'oracle_text': '{T}: Add {C}{C}.',
          'mana_cost': '{1}',
          'quantity': 2,
        },
        {
          'name': 'Swords to Plowshares',
          'type_line': 'Instant',
          'oracle_text': 'Exile target creature.',
          'mana_cost': '{W}',
          'quantity': 1,
        },
        {
          'name': 'Vanilla Bear',
          'type_line': 'Creature',
          'oracle_text': '',
          'mana_cost': '{1}{G}',
          'quantity': 3,
        },
      ]);

      expect(summary.count('ramp'), equals(2));
      expect(summary.count('removal'), equals(1));
      expect(summary.otherCopies, equals(3));
      expect(summary.samples['ramp'], equals(const ['Sol Ring']));
      expect(summary.sampleDetails['ramp']?.first['reason'], contains('ramp'));
      expect(
        summary.toJson()['schema_version'],
        functionalCardTagsSchemaVersion,
      );
      expect(
        summary.toJson()['semantic_schema_version'],
        equals(semanticLayerV2SchemaVersion),
      );
    });

    test(
      'prefers persisted tags, semantic v2 and then heuristic tags per row',
      () {
        final summary = summarizeFunctionalTagsForDeck([
          {
            'name': 'Semantic Cache Hit',
            'type_line': 'Creature',
            'oracle_text': '',
            'quantity': 2,
            'functional_tags': [
              {'tag': 'draw', 'confidence': 0.9, 'source': 'test'},
            ],
          },
          {
            'name': 'Sol Ring',
            'type_line': 'Artifact',
            'oracle_text': '{T}: Add {C}{C}.',
            'mana_cost': '{1}',
            'quantity': 1,
            'functional_tags': const [],
          },
          {
            'name': 'Semantic V2 Only',
            'type_line': 'Instant',
            'oracle_text': '',
            'quantity': 4,
            'functional_tags': const [],
            'semantic_tags_v2': [
              {
                'tags': [
                  {'tag': 'removal', 'confidence': 0.91},
                ],
                'role_confidence': 0.91,
                'speed': 'instant_speed',
                'interaction_scope': 'single_target',
                'explanation_reason': 'persisted semantic v2 fixture',
                'source': 'test_semantic_v2',
              },
            ],
          },
          {
            'name': 'Low Confidence Persisted',
            'type_line': 'Creature',
            'oracle_text': '',
            'quantity': 3,
            'functional_tags': [
              {'tag': 'removal', 'confidence': 0.2, 'source': 'test'},
            ],
          },
        ]);

        expect(summary.count('draw'), equals(2));
        expect(summary.count('ramp'), equals(1));
        expect(summary.count('removal'), equals(4));
        expect(summary.persistedRows, equals(2));
        expect(summary.persistedCopies, equals(6));
        expect(summary.heuristicRows, equals(2));
        expect(summary.heuristicCopies, equals(4));
        expect(summary.otherCopies, equals(3));
        expect(summary.samples['removal'], equals(const ['Semantic V2 Only']));
        expect(
          summary.sampleDetails['removal']?.first['evidence'],
          equals('persisted semantic v2 fixture'),
        );

        final source = summary.toJson()['source'] as Map<String, dynamic>;
        expect(
          source['priority'],
          equals('functional_tags_then_semantic_v2_then_heuristic'),
        );
        expect(source['persisted_rows'], equals(2));
      },
    );

    test(
      'keeps legacy samples bounded but exposes complete sample details',
      () {
        final cards = List.generate(
          7,
          (index) => {
            'name': 'Draw Fixture ${index + 1}',
            'type_line': 'Instant',
            'oracle_text': 'Draw a card.',
            'mana_cost': '{1}{U}',
            'quantity': 1,
          },
        );

        final summary = summarizeFunctionalTagsForDeck(
          cards,
          sampleLimit: 2,
          countedTags: const {'draw'},
        );

        expect(summary.count('draw'), equals(7));
        expect(
          summary.samples['draw'],
          equals(const ['Draw Fixture 1', 'Draw Fixture 2']),
        );
        expect(summary.sampleDetails['draw'], hasLength(7));
        expect(
          summary.sampleDetails['draw']?.last['name'],
          equals('Draw Fixture 7'),
        );
      },
    );
  });
}

Map<String, Object> _card({
  required String typeLine,
  required String manaCost,
  required String oracleText,
  required Set<String> expected,
}) {
  return {
    'type_line': typeLine,
    'mana_cost': manaCost,
    'oracle_text': oracleText,
    'expected': expected,
  };
}
