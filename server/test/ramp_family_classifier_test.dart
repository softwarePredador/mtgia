import 'package:server/ai/candidate_quality_data_support.dart';
import 'package:server/ai/functional_card_tags.dart';
import 'package:server/ai/optimization_functional_roles.dart';
import 'package:test/test.dart';

void main() {
  group('ramp family structural contract', () {
    test('Treasure beneficiary and transformation negatives stay out of ramp', () {
      final cases = <
        String,
        ({
          String typeLine,
          String oracle,
          OptimizationTreasureRampSignal signal,
        })
      >{
        "An Offer You Can't Refuse": (
          typeLine: 'Instant',
          signal: OptimizationTreasureRampSignal.objectControllerCompensation,
          oracle:
              'Counter target noncreature spell. Its controller creates two '
              'Treasure tokens. (They are artifacts with "{T}, Sacrifice this '
              'token: Add one mana of any color.")',
        ),
        'Buy Your Silence': (
          typeLine: 'Sorcery',
          signal: OptimizationTreasureRampSignal.objectControllerCompensation,
          oracle:
              'Exile target nonland permanent. Its controller creates a '
              'Treasure token. (It is an artifact with "{T}, Sacrifice this '
              'token: Add one mana of any color.")',
        ),
        'Wanted Scoundrels': (
          typeLine: 'Creature — Human Pirate',
          signal: OptimizationTreasureRampSignal.opponentOnly,
          oracle:
              'When this creature dies, target opponent creates two Treasure '
              'tokens. (They are artifacts with "{T}, Sacrifice this token: '
              'Add one mana of any color.")',
        ),
        'Blooming Blast': (
          typeLine: 'Instant',
          signal: OptimizationTreasureRampSignal.opponentOnly,
          oracle:
              'Gift a Treasure (You may promise an opponent a gift as you cast '
              'this spell. If you do, they create a Treasure token. It is an '
              'artifact with "{T}, Sacrifice this token: Add one mana of any '
              'color.")\nBlooming Blast deals 2 damage to target creature.',
        ),
        'Dockbreacher': (
          typeLine: 'Creature — Merfolk Pirate',
          signal: OptimizationTreasureRampSignal.replacementOrPreventionOnly,
          oracle:
              'Flash\nIf an opponent would create a Treasure token beyond the '
              'first one they create each turn, instead you draw a card.',
        ),
        'Kitesail Larcenist': (
          typeLine: 'Creature — Human Pirate',
          signal: OptimizationTreasureRampSignal.transformationOnly,
          oracle:
              'Chosen permanents become Treasure artifacts with "{T}, '
              'Sacrifice this artifact: Add one mana of any color" and lose '
              'all other abilities.',
        ),
        'Minimus Containment': (
          typeLine: 'Enchantment — Aura',
          signal: OptimizationTreasureRampSignal.transformationOnly,
          oracle:
              'Enchant nonland permanent\nEnchanted permanent is a Treasure '
              'artifact with "{T}, Sacrifice this artifact: Add one mana of '
              'any color," and it loses all other abilities.',
        ),
        "Vraska, Betrayal's Sting": (
          typeLine: 'Legendary Planeswalker — Vraska',
          signal: OptimizationTreasureRampSignal.transformationOnly,
          oracle:
              '[−2]: Target creature becomes a Treasure artifact with "{T}, '
              'Sacrifice this artifact: Add one mana of any color" and loses '
              'all other card types and abilities.',
        ),
        'Erestor of the Council': (
          typeLine: 'Legendary Creature — Elf Noble',
          signal: OptimizationTreasureRampSignal.opponentOnly,
          oracle:
              'Whenever players finish voting, each opponent who voted for a '
              'choice you voted for creates a Treasure token. You scry X.',
        ),
        'North Pole Research Base': (
          typeLine: 'Plane — Earth',
          signal: OptimizationTreasureRampSignal.opponentOnly,
          oracle:
              'At the beginning of your upkeep, target opponent draws a card '
              'and creates a Treasure token.',
        ),
      };

      for (final entry in cases.entries) {
        final value = entry.value;
        final functional =
            inferFunctionalCardTags(
              name: entry.key,
              typeLine: value.typeLine,
              oracleText: value.oracle,
            ).map((tag) => tag.tag).toSet();
        final candidate =
            inferCandidateFunctionTags(
              name: entry.key,
              typeLine: value.typeLine,
              oracleText: value.oracle,
            ).map((tag) => tag.tag).toSet();
        final semantic = inferSemanticCardAnalysisV2(
          name: entry.key,
          typeLine: value.typeLine,
          oracleText: value.oracle,
        );
        final roles = buildCandidateRoleScores(
          name: entry.key,
          typeLine: value.typeLine,
          oracleText: value.oracle,
        );

        expect(
          classifyOptimizationTreasureRampText(value.oracle),
          value.signal,
          reason: entry.key,
        );
        expect(
          looksLikeOptimizationRampText(value.oracle),
          isFalse,
          reason: entry.key,
        );
        expect(functional, isNot(contains('ramp')), reason: entry.key);
        expect(functional, isNot(contains('token_maker')), reason: entry.key);
        expect(candidate, isNot(contains('ramp')), reason: entry.key);
        expect(candidate, isNot(contains('mana_fixing')), reason: entry.key);
        expect(candidate, isNot(contains('token')), reason: entry.key);
        expect(
          semantic.tags.map((tag) => tag.tag),
          isNot(contains('ramp')),
          reason: entry.key,
        );
        expect(
          roles.map((score) => score.role),
          isNot(contains('ramp')),
          reason: entry.key,
        );
      }
    });

    test('controller, shared, selectable and granted Treasure remain ramp', () {
      final cases = <
        String,
        ({
          String typeLine,
          String oracle,
          OptimizationTreasureRampSignal signal,
        })
      >{
        "Ancestors' Aid": (
          typeLine: 'Instant',
          signal: OptimizationTreasureRampSignal.directSelf,
          oracle:
              'Target creature gets +2/+0 and gains first strike until end of '
              'turn.\nCreate a Treasure token.',
        ),
        'Bloodroot Apothecary': (
          typeLine: 'Creature — Squirrel Druid',
          signal: OptimizationTreasureRampSignal.sharedIncludesSelf,
          oracle:
              'When this creature enters, you and target opponent each create '
              'a Treasure token.',
        ),
        'Gonti, Night Minister': (
          typeLine: 'Legendary Creature — Aetherborn Rogue',
          signal: OptimizationTreasureRampSignal.anyPlayerIncludesSelf,
          oracle:
              'Whenever a player casts a spell they do not own, that player '
              'creates a Treasure token.',
        ),
        'Prismari Command': (
          typeLine: 'Instant',
          signal: OptimizationTreasureRampSignal.targetPlayerSelectable,
          oracle: 'Choose two —\n• Target player creates a Treasure token.',
        ),
        "Bootleggers' Stash": (
          typeLine: 'Artifact',
          signal: OptimizationTreasureRampSignal.controlledGrantedAbility,
          oracle: 'Lands you control have "{T}: Create a Treasure token."',
        ),
        'Diamond Pick-Axe': (
          typeLine: 'Artifact — Equipment',
          signal: OptimizationTreasureRampSignal.controlledGrantedAbility,
          oracle:
              'Equipped creature gets +1/+1 and has "Whenever this creature '
              'attacks, create a Treasure token."\nEquip {2}',
        ),
      };

      for (final entry in cases.entries) {
        final value = entry.value;
        expect(
          classifyOptimizationTreasureRampText(value.oracle),
          value.signal,
          reason: entry.key,
        );
        expect(
          looksLikeOptimizationRampText(value.oracle),
          isTrue,
          reason: entry.key,
        );
        expect(
          inferFunctionalCardTags(
            name: entry.key,
            typeLine: value.typeLine,
            oracleText: value.oracle,
          ).map((tag) => tag.tag),
          contains('ramp'),
          reason: entry.key,
        );
        expect(
          inferCandidateFunctionTags(
            name: entry.key,
            typeLine: value.typeLine,
            oracleText: value.oracle,
          ).map((tag) => tag.tag),
          contains('ramp'),
          reason: entry.key,
        );
      }
    });

    test('quoted mana abilities require controller-owned grant context', () {
      const positive =
          'Creatures you control have "{T}: Add one mana of any color."';
      const negative =
          'Target creature becomes an artifact with "{T}: Add one mana of any '
          'color" and loses all other abilities.';

      expect(looksLikeOptimizationRampText(positive), isTrue);
      expect(
        looksLikeOptimizationWordedAnyManaProductionText(positive),
        isTrue,
      );
      expect(looksLikeOptimizationRampText(negative), isFalse);
      expect(
        looksLikeOptimizationWordedAnyManaProductionText(negative),
        isFalse,
      );
      const toxicrene =
          'Reach, deathtouch\nHypertoxic Miasma — All lands have '
          '"{T}: Add one mana of any color" and lose all other abilities.';
      expect(looksLikeOptimizationRampText(toxicrene), isFalse);
      expect(
        looksLikeOptimizationWordedAnyManaProductionText(toxicrene),
        isFalse,
      );
    });

    test('legacy contextual mana effects remain ramp when controller benefits', () {
      const cases = <String, String>{
        'Charmed Pendant':
            '{T}, Mill a card: For each colored mana symbol in the milled '
            'card\'s mana cost, add one mana of that color.',
        'Diabolical Salvation':
            'Create four 4/4 red Devil creature tokens with haste and "When '
            'this creature dies, create a colorless Treasure artifact token '
            'with \'{T}, Sacrifice this artifact: Add one mana of any color.\'"',
        'Done for the Day':
            'At the beginning of your end step, if you control an Employee, '
            'you may get {TK} or create a Treasure token.',
        "Garruk's Lost Wolf":
            'When this creature enters, create a Huntsman Role token attached '
            'to another target creature you control. (Enchanted creature gets '
            '+1/+1 and has "{T}: Add {G}")',
        'Gluntch, the Bestower':
            'Choose a player to draw a card. Then choose a third player to '
            'create two Treasure tokens.',
        'Hoarding Ogre':
            'Whenever this creature attacks, roll a d20.\n1—9 | Create a '
            'Treasure token.\n10—19 | Create two Treasure tokens.',
        'Item Crate':
            'Create a tapped colorless token at random with the listed name '
            'and ability.\n• Banana with "{T}, Sacrifice this token: Add {R} '
            'or {G}."',
        'Kibo, Uktabi Prince':
            '{T}: Each player creates a colorless artifact token named Banana '
            'with "{T}, Sacrifice this token: Add {R} or {G}."',
        'Oddric, Lunar Marquis':
            'At the beginning of each combat, creatures you control gain '
            'banding if a creature you control has banding. The same is true '
            'for many abilities and the activated ability "Sacrifice this '
            'creature: Add {C}."',
        'Pain Distributor':
            'Whenever a player casts their first spell each turn, they create '
            'a Treasure token.',
        'Racketeer Boss':
            'Choose up to two creature cards in your hand. They perpetually '
            'gain "When you cast this spell, create a Treasure token."',
        'You Compleat Me':
            'You get an emblem with "Pay 2 life: Add one mana of any color".',
      };

      for (final entry in cases.entries) {
        expect(
          looksLikeOptimizationRampText(entry.value),
          isTrue,
          reason: entry.key,
        );
      }
    });

    test('opponent-only fixing and transformation remain outside ramp', () {
      const cases = <String, String>{
        'Alpine Moon':
            'Lands your opponents control lose all abilities and they gain '
            '"{T}: Add one mana of any color."',
        'Dwarven Confluencer':
            'Destroy target nontoken land. Its controller creates a Mana '
            'Confluence token.',
        'Emergency Eject':
            'Destroy target nonland permanent. Its controller creates a Lander '
            'token.',
        'Honest Work':
            'Enchant creature an opponent controls. Enchanted creature loses '
            'all abilities and gains "{T}: Add {C}."',
        'Imprisoned in the Moon':
            'Enchanted permanent is a colorless land with "{T}: Add {C}" and '
            'loses all other card types and abilities.',
        'Zhao, the Moon Slayer':
            'Nonbasic lands are Mountains. They lose all other land types and '
            'abilities and have "{T}: Add {R}."',
        "Spara's Adjudicators":
            'Exile this card from your hand: Target land gains '
            '"{T}: Add {G}, {W}, or {U}."',
        'Toxicrene':
            'All lands have "{T}: Add one mana of any color" and lose all '
            'other abilities.',
      };

      for (final entry in cases.entries) {
        expect(
          looksLikeOptimizationRampText(entry.value),
          isFalse,
          reason: entry.key,
        );
      }
    });

    test(
      'target-land fixing stays out while net-positive grant remains ramp',
      () {
        expect(
          looksLikeOptimizationRampText(
            'Exile this card from your hand: Target land gains '
            '"{T}: Add {U}, {B}, or {R}."',
          ),
          isFalse,
        );
        expect(
          looksLikeOptimizationRampText(
            'Target land gains "{T}: Add {G}{G}{G}" until end of turn.',
          ),
          isTrue,
        );
      },
    );

    test('compound tap mana ability is ramp but not ritual', () {
      const oracle =
          'When this creature enters, you may discard a card. If you do, draw '
          'a card.\n{T}, Exile a card from your graveyard: Add {R}. When you '
          'do, this creature deals 1 damage to each opponent.';
      final functional =
          inferFunctionalCardTags(
            name: 'Rubble Rouser',
            typeLine: 'Creature — Dwarf Sorcerer',
            oracleText: oracle,
          ).map((tag) => tag.tag).toSet();
      final candidate =
          inferCandidateFunctionTags(
            name: 'Rubble Rouser',
            typeLine: 'Creature — Dwarf Sorcerer',
            oracleText: oracle,
          ).map((tag) => tag.tag).toSet();

      expect(functional, contains('ramp'));
      expect(functional, isNot(contains('ritual')));
      expect(candidate, contains('ramp'));
      expect(candidate, isNot(contains('ritual')));
    });

    test('payment permission is not mana production in any Dart lane', () {
      const cases = <String, String>{
        'Nita, Forum Conciliator':
            'Whenever you cast a spell you don\'t own, put a +1/+1 counter '
            'on each creature you control.\n'
            '{2}, Sacrifice another creature: Exile target instant or '
            'sorcery card from an opponent\'s graveyard. You may cast it '
            'this turn, and mana of any type can be spent to cast that '
            'spell. If that spell would be put into a graveyard, exile it '
            'instead. Activate only as a sorcery.',
        'Generic color permission':
            'You may cast that spell, and mana of any color can be spent to '
            'cast it.',
        'As though permission':
            'You may spend mana as though it were mana of any color to cast '
            'spells from exile.',
      };

      for (final entry in cases.entries) {
        final functional =
            inferFunctionalCardTags(
              name: entry.key,
              typeLine: 'Legendary Creature — Human Advisor',
              oracleText: entry.value,
            ).map((tag) => tag.tag).toSet();
        final candidate =
            inferCandidateFunctionTags(
              name: entry.key,
              typeLine: 'Legendary Creature — Human Advisor',
              oracleText: entry.value,
            ).map((tag) => tag.tag).toSet();
        final semantic = inferSemanticCardAnalysisV2(
          name: entry.key,
          typeLine: 'Legendary Creature — Human Advisor',
          oracleText: entry.value,
        );
        final roles = buildCandidateRoleScores(
          name: entry.key,
          typeLine: 'Legendary Creature — Human Advisor',
          oracleText: entry.value,
        );

        expect(
          looksLikeOptimizationRampText(entry.value),
          isFalse,
          reason: entry.key,
        );
        expect(functional, isNot(contains('ramp')), reason: entry.key);
        expect(candidate, isNot(contains('ramp')), reason: entry.key);
        expect(
          semantic.tags.map((tag) => tag.tag),
          isNot(contains('ramp')),
          reason: entry.key,
        );
        expect(
          roles.map((score) => score.role),
          isNot(contains('ramp')),
          reason: entry.key,
        );
      }
    });

    test('explicit worded mana producers remain ramp in every Dart lane', () {
      const cases = <String, String>{
        'Ronin, Shadow Stalker':
            'Pay 2 life: Add two mana of any one color. Spend this mana only '
            'to cast Equipment spells or activate equip abilities. Activate '
            'only once each turn.',
        'Arcane Signet':
            '{T}: Add one mana of any color in your commander\'s color '
            'identity.',
      };

      for (final entry in cases.entries) {
        final typeLine =
            entry.key == 'Arcane Signet'
                ? 'Artifact'
                : 'Legendary Creature — Human Rogue Hero';
        final functional =
            inferFunctionalCardTags(
              name: entry.key,
              typeLine: typeLine,
              oracleText: entry.value,
            ).map((tag) => tag.tag).toSet();
        final candidate =
            inferCandidateFunctionTags(
              name: entry.key,
              typeLine: typeLine,
              oracleText: entry.value,
            ).map((tag) => tag.tag).toSet();
        final semantic = inferSemanticCardAnalysisV2(
          name: entry.key,
          typeLine: typeLine,
          oracleText: entry.value,
        );
        final roles = buildCandidateRoleScores(
          name: entry.key,
          typeLine: typeLine,
          oracleText: entry.value,
        );

        expect(
          looksLikeOptimizationRampText(entry.value),
          isTrue,
          reason: entry.key,
        );
        expect(functional, contains('ramp'), reason: entry.key);
        expect(candidate, contains('ramp'), reason: entry.key);
        expect(
          semantic.tags.map((tag) => tag.tag),
          contains('ramp'),
          reason: entry.key,
        );
        expect(
          roles.map((score) => score.role),
          contains('ramp'),
          reason: entry.key,
        );
      }
    });

    test('alternate acceleration survives permission-text cleanup', () {
      final cases = <
        String,
        ({String typeLine, String oracle, String expectedSignal})
      >{
        'Gonti, Canny Acquisitor': (
          typeLine: 'Legendary Creature — Aetherborn Rogue',
          expectedSignal: 'qualified cost reduction',
          oracle:
              'Spells you cast but don\'t own cost {1} less to cast.\n'
              'Whenever one or more creatures you control deal combat damage '
              'to a player, look at the top card of that player\'s library, '
              'then exile it face down. You may play that card for as long as '
              'it remains exiled, and mana of any type can be spent to cast '
              'that spell.',
        ),
        'Gonti, Night Minister': (
          typeLine: 'Legendary Creature — Aetherborn Rogue',
          expectedSignal: 'Treasure production',
          oracle:
              'Whenever a player casts a spell they don\'t own, that player '
              'creates a Treasure token.\n'
              'Whenever a creature deals combat damage to one of your '
              'opponents, its controller looks at the top card of that '
              'opponent\'s library and exiles it face down. They may play that '
              'card for as long as it remains exiled. Mana of any type can be '
              'spent to cast a spell this way.',
        ),
        'Manascape Refractor': (
          typeLine: 'Artifact',
          expectedSignal: 'copied land mana abilities',
          oracle:
              'This artifact enters tapped.\n'
              'This artifact has all activated abilities of all lands on the '
              'battlefield.\n'
              'You may spend mana as though it were mana of any color to pay '
              'the activation costs of this artifact\'s abilities.',
        ),
        'The Snapstone Wielder': (
          typeLine: 'Legendary Creature — Human Gamer',
          expectedSignal: 'mana counters',
          oracle:
              'If The Snapstone Wielder is your commander and your deck '
              'contains no land cards, your starting hand size is four and '
              'for the rest of the game, at the beginning of your upkeep, '
              'you get a mana counter. During each of your turns, you can '
              'spend mana of any color equal to the number of mana counters '
              'you have. (You want mana on opponent\'s turns, you\'re on your '
              'own. Who needs instant-speed interaction?)\n'
              'Whenever The Snapstone Wielder enters or attacks, cast a '
              'random nonland Magic card without paying its mana cost. If it '
              'has targets, choose the targets at random.',
        ),
        'Fallaji Wayfarer': (
          typeLine: 'Creature — Human Scout',
          expectedSignal: 'granted convoke',
          oracle:
              'Fallaji Wayfarer is all colors. This ability doesn\'t affect '
              'its color identity. (It can be in any deck whose commander\'s '
              'color identity includes green.)\n'
              'Multicolored spells you cast have convoke. (Your creatures '
              'can help cast those spells. Each creature you tap while '
              'casting a multicolored spell pays for {1} or one mana of a '
              'color that creature is.)',
        ),
        'The Paradise Bird': (
          typeLine: 'Legendary Creature — Bird',
          expectedSignal: 'Birds of Paradise token',
          oracle:
              'Flying\n'
              'Other Birds you control get +1/+1.\n'
              '{G}, {T}: Create a Birds of Paradise token.\n'
              'If The Paradise Bird is your commander, your deck can include '
              'cards of any color identity.',
        ),
      };

      for (final entry in cases.entries) {
        final value = entry.value;
        final functional =
            inferFunctionalCardTags(
              name: entry.key,
              typeLine: value.typeLine,
              oracleText: value.oracle,
            ).map((tag) => tag.tag).toSet();
        final candidate =
            inferCandidateFunctionTags(
              name: entry.key,
              typeLine: value.typeLine,
              oracleText: value.oracle,
            ).map((tag) => tag.tag).toSet();
        final semantic = inferSemanticCardAnalysisV2(
          name: entry.key,
          typeLine: value.typeLine,
          oracleText: value.oracle,
        );
        final roles = buildCandidateRoleScores(
          name: entry.key,
          typeLine: value.typeLine,
          oracleText: value.oracle,
        );

        expect(
          looksLikeOptimizationRampText(value.oracle),
          isTrue,
          reason: '${entry.key}: ${value.expectedSignal}',
        );
        expect(functional, contains('ramp'), reason: entry.key);
        expect(candidate, contains('ramp'), reason: entry.key);
        expect(
          semantic.tags.map((tag) => tag.tag),
          contains('ramp'),
          reason: entry.key,
        );
        expect(
          roles.map((score) => score.role),
          contains('ramp'),
          reason: entry.key,
        );
      }
    });

    test('mechanic and token-name collisions do not become ramp', () {
      expect(
        looksLikeOptimizationRampText(
          'Firebending Lesson deals 3 damage to any target.',
        ),
        isFalse,
      );
      expect(
        looksLikeOptimizationRampText(
          'Whenever equipped creature attacks, create a 2/2 gold Dragon '
          'creature token with flying.',
        ),
        isFalse,
      );
      expect(
        looksLikeOptimizationRampText(
          'Creatures you control have firebending 1.',
        ),
        isTrue,
      );
      expect(looksLikeOptimizationRampText('Create a Gold token.'), isTrue);
    });

    test('Ronin deterministic heuristic rows stay exact for PG876', () {
      const name = 'Ronin, Shadow Stalker';
      const typeLine = 'Legendary Creature — Human Rogue Hero';
      const oracle =
          'Pay 2 life: Add two mana of any one color. Spend this mana only '
          'to cast Equipment spells or activate equip abilities. Activate '
          'only once each turn.\n'
          '{T}, Sacrifice an Equipment attached to Ronin: Target creature '
          'gets -4/-4 until end of turn. Activate only as a sorcery.';

      final functions = {
        for (final tag in inferCandidateFunctionTags(
          name: name,
          typeLine: typeLine,
          oracleText: oracle,
          manaCost: '{2}{B}',
        ))
          tag.tag: '${tag.confidence.toStringAsFixed(3)}|${tag.evidence}',
      };
      final roles = {
        for (final role in buildCandidateRoleScores(
          name: name,
          typeLine: typeLine,
          oracleText: oracle,
          manaCost: '{2}{B}',
          cmc: 0,
        ))
          role.role:
              '${role.score}|${role.bracketScope}|${role.budgetTier}|'
              '${role.evidence}',
      };

      expect(functions, {
        'ramp': '0.880|mana_or_land_ramp_text',
        'removal': '0.830|targeted_interaction_text',
        'sacrifice': '0.800|external_activated_sacrifice_outlet_cost;alias=v1',
        'sacrifice_outlet': '0.800|external_activated_sacrifice_outlet_cost',
      });
      expect(roles, {
        'ramp': '63|any|unknown|mana_or_land_ramp_text',
        'removal': '60|any|unknown|targeted_interaction_text',
        'sacrifice':
            '58|any|unknown|external_activated_sacrifice_outlet_cost;alias=v1',
      });
    });

    test('lands remain land or fixing, never generic ramp', () {
      final cases = <String, ({String oracle, String typeLine})>{
        'Bloodstained Mire': (
          typeLine: 'Land',
          oracle:
              '{T}, Pay 1 life, Sacrifice this land: Search your library for a Swamp or Mountain card, put it onto the battlefield, then shuffle.',
        ),
        'Restless Spire': (typeLine: 'Land', oracle: '{T}: Add {U} or {R}.'),
        'Ancient Tomb': (
          typeLine: 'Land',
          oracle: '{T}: Add {C}{C}. Ancient Tomb deals 2 damage to you.',
        ),
        'Cabal Coffers': (
          typeLine: 'Land',
          oracle: '{2}, {T}: Add {B} for each Swamp you control.',
        ),
      };

      for (final entry in cases.entries) {
        final functional =
            inferFunctionalCardTags(
              name: entry.key,
              typeLine: entry.value.typeLine,
              oracleText: entry.value.oracle,
            ).map((tag) => tag.tag).toSet();
        final candidate =
            inferCandidateFunctionTags(
              name: entry.key,
              typeLine: entry.value.typeLine,
              oracleText: entry.value.oracle,
            ).map((tag) => tag.tag).toSet();
        final semantic = inferSemanticCardAnalysisV2(
          name: entry.key,
          typeLine: entry.value.typeLine,
          oracleText: entry.value.oracle,
        );

        expect(functional, contains('land'), reason: entry.key);
        expect(functional, isNot(contains('ramp')), reason: entry.key);
        expect(candidate, contains('land'), reason: entry.key);
        expect(candidate, isNot(contains('ramp')), reason: entry.key);
        expect(semantic.tags.map((tag) => tag.tag), contains('land'));
        expect(semantic.tags.map((tag) => tag.tag), isNot(contains('ramp')));
        expect(
          buildCandidateRoleScores(
            name: entry.key,
            typeLine: entry.value.typeLine,
            oracleText: entry.value.oracle,
          ).map((score) => score.role),
          isNot(contains('ramp')),
          reason: entry.key,
        );
      }
    });

    test('nonland land-search, rocks and rituals remain ramp', () {
      final cases = <String, ({String oracle, String typeLine, String cost})>{
        "Nature's Lore": (
          typeLine: 'Sorcery',
          cost: '{1}{G}',
          oracle:
              'Search your library for a Forest card, put that card onto the battlefield, then shuffle.',
        ),
        'Sol Ring': (
          typeLine: 'Artifact',
          cost: '{1}',
          oracle: '{T}: Add {C}{C}.',
        ),
        'Lotus Petal': (
          typeLine: 'Artifact',
          cost: '{0}',
          oracle: '{T}, Sacrifice this artifact: Add one mana of any color.',
        ),
        'Seething Song': (
          typeLine: 'Instant',
          cost: '{2}{R}',
          oracle: 'Add {R}{R}{R}{R}{R}.',
        ),
      };

      for (final entry in cases.entries) {
        final functional =
            inferFunctionalCardTags(
              name: entry.key,
              typeLine: entry.value.typeLine,
              oracleText: entry.value.oracle,
              manaCost: entry.value.cost,
            ).map((tag) => tag.tag).toSet();
        final candidate =
            inferCandidateFunctionTags(
              name: entry.key,
              typeLine: entry.value.typeLine,
              oracleText: entry.value.oracle,
              manaCost: entry.value.cost,
            ).map((tag) => tag.tag).toSet();

        expect(functional, contains('ramp'), reason: entry.key);
        expect(candidate, contains('ramp'), reason: entry.key);
        expect(functional, isNot(contains('land')), reason: entry.key);
      }
    });

    test('Lander creature subtype is never classified as a land', () {
      const name = 'Lander Rizzi';
      const typeLine = 'Legendary Artifact Creature — Lander Rogue';
      const oracle = '{T}: Add one mana of any color.';

      final functional =
          inferFunctionalCardTags(
            name: name,
            typeLine: typeLine,
            oracleText: oracle,
          ).map((tag) => tag.tag).toSet();
      final candidate =
          inferCandidateFunctionTags(
            name: name,
            typeLine: typeLine,
            oracleText: oracle,
          ).map((tag) => tag.tag).toSet();

      expect(functional, isNot(contains('land')));
      expect(candidate, isNot(contains('land')));
      expect(
        classifyOptimizationFunctionalRole({
          'name': name,
          'type_line': typeLine,
          'oracle_text': oracle,
        }),
        isNot('land'),
      );
    });

    test('land search to hand is fixing, not net mana acceleration', () {
      const oracle =
          'When this creature enters, you may search your library for a basic land card, reveal it, put it into your hand, then shuffle.';

      final functional =
          inferFunctionalCardTags(
            name: 'Environmental Scientist',
            typeLine: 'Creature — Human Druid',
            oracleText: oracle,
            manaCost: '{2}',
          ).map((tag) => tag.tag).toSet();
      final candidate =
          inferCandidateFunctionTags(
            name: 'Environmental Scientist',
            typeLine: 'Creature — Human Druid',
            oracleText: oracle,
            manaCost: '{2}',
          ).map((tag) => tag.tag).toSet();

      expect(functional, isNot(contains('ramp')));
      expect(candidate, isNot(contains('ramp')));
      expect(functional, isNot(contains('tutor')));
      expect(candidate, isNot(contains('tutor')));
    });
  });
}
