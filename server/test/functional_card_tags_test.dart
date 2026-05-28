import 'package:server/ai/functional_card_tags.dart';
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
      };

      for (final entry in cases.entries) {
        final tags = inferFunctionalCardTags(
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
      final ephemerateTags = inferFunctionalCardTags(
        name: 'Ephemerate',
        typeLine: 'Instant',
        oracleText:
            'Exile target creature you control, then return it to the battlefield under its owner\'s control.',
        manaCost: '{W}',
      ).map((tag) => tag.tag).toSet();

      expect(ephemerateTags, isNot(contains('removal')));

      final hushwingTags = inferFunctionalCardTags(
        name: 'Hushwing Gryff',
        typeLine: 'Creature - Hippogriff',
        oracleText:
            'Creatures entering the battlefield don\'t cause abilities to trigger.',
        manaCost: '{2}{W}',
      ).map((tag) => tag.tag).toSet();

      expect(hushwingTags, isNot(contains('etb')));

      final natureLoreTags = inferFunctionalCardTags(
        name: 'Nature\'s Lore',
        typeLine: 'Sorcery',
        oracleText:
            'Search your library for a Forest card, put that card onto the battlefield, then shuffle.',
        manaCost: '{1}{G}',
      ).map((tag) => tag.tag).toSet();

      expect(natureLoreTags, contains('ramp'));
      expect(natureLoreTags, isNot(contains('tutor')));

      final erebosTags = inferFunctionalCardTags(
        name: 'Erebos, God of the Dead',
        typeLine: 'Legendary Enchantment Creature - God',
        oracleText:
            'Indestructible. Your opponents can\'t gain life. Pay 2 life: Draw a card.',
        manaCost: '{3}{B}',
      ).map((tag) => tag.tag).toSet();

      expect(erebosTags, isNot(contains('lifegain')));

      final arcadesTags = inferFunctionalCardTags(
        name: 'Arcades, the Strategist',
        typeLine: 'Legendary Creature - Elder Dragon',
        oracleText:
            'Each creature you control with defender assigns combat damage equal to its toughness rather than its power.',
        manaCost: '{1}{G}{W}{U}',
      ).map((tag) => tag.tag).toSet();

      expect(arcadesTags, isNot(contains('board_wipe')));

      final anthemTags = inferFunctionalCardTags(
        name: 'Glorious Anthem',
        typeLine: 'Enchantment',
        oracleText: 'Creatures you control get +1/+1.',
        manaCost: '{1}{W}{W}',
      ).map((tag) => tag.tag).toSet();

      expect(anthemTags, isNot(contains('board_wipe')));
    });

    test('keeps protection and wipe positives after mass-audit refinements',
        () {
      final wardTags = inferFunctionalCardTags(
        name: 'Coppercoat Vanguard',
        typeLine: 'Creature - Human Soldier',
        oracleText: 'Each other Human you control has ward {1}.',
        manaCost: '{1}{W}',
      ).map((tag) => tag.tag).toSet();

      expect(wardTags, contains('protection'));

      final blasphemousActTags = inferFunctionalCardTags(
        name: 'Blasphemous Act',
        typeLine: 'Sorcery',
        oracleText:
            'This spell costs {1} less to cast for each creature on the battlefield. Blasphemous Act deals 13 damage to each creature.',
        manaCost: '{8}{R}',
      ).map((tag) => tag.tag).toSet();

      expect(blasphemousActTags, contains('board_wipe'));

      final drownTags = inferFunctionalCardTags(
        name: 'Drown in Sorrow',
        typeLine: 'Sorcery',
        oracleText: 'All creatures get -2/-2 until end of turn. Scry 1.',
        manaCost: '{1}{B}{B}',
      ).map((tag) => tag.tag).toSet();

      expect(drownTags, contains('board_wipe'));
    });

    test('reduces generic payoff and enabler false positives', () {
      final blasphemousActTags = inferFunctionalCardTags(
        name: 'Blasphemous Act',
        typeLine: 'Sorcery',
        oracleText:
            'This spell costs {1} less to cast for each creature on the battlefield. Blasphemous Act deals 13 damage to each creature.',
        manaCost: '{8}{R}',
      ).map((tag) => tag.tag).toSet();

      expect(blasphemousActTags, contains('board_wipe'));
      expect(blasphemousActTags, isNot(contains('payoff')));

      final glimpseTags = inferFunctionalCardTags(
        name: 'Glimpse the Unthinkable',
        typeLine: 'Sorcery',
        oracleText: 'Target player mills ten cards.',
        manaCost: '{U}{B}',
      ).map((tag) => tag.tag).toSet();

      expect(glimpseTags, isNot(contains('enabler')));

      final greavesTags = inferFunctionalCardTags(
        name: 'Lightning Greaves',
        typeLine: 'Artifact - Equipment',
        oracleText: 'Equipped creature has haste and shroud. Equip {0}.',
        manaCost: '{2}',
      ).map((tag) => tag.tag).toSet();

      expect(greavesTags, containsAll({'enabler', 'protection'}));
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
          summary.toJson()['schema_version'], functionalCardTagsSchemaVersion);
      expect(summary.toJson()['semantic_schema_version'],
          equals(semanticLayerV2SchemaVersion));
    });

    test('prefers persisted tags and falls back to heuristic tags per row', () {
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
      expect(summary.count('removal'), equals(0));
      expect(summary.persistedRows, equals(1));
      expect(summary.persistedCopies, equals(2));
      expect(summary.heuristicRows, equals(2));
      expect(summary.heuristicCopies, equals(4));
      expect(summary.otherCopies, equals(3));

      final source = summary.toJson()['source'] as Map<String, dynamic>;
      expect(source['priority'], equals('persisted_then_heuristic'));
      expect(source['persisted_rows'], equals(1));
    });
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
