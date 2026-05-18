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
        'Reanimate': _card(
          typeLine: 'Sorcery',
          manaCost: '{B}',
          oracleText:
              'Put target creature card from a graveyard onto the battlefield under your control. You lose life equal to its mana value.',
          expected: const {'recursion', 'graveyard_synergy'},
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
      expect(
          summary.toJson()['schema_version'], functionalCardTagsSchemaVersion);
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
