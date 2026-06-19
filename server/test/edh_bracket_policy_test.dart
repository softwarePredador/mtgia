import 'package:server/edh_bracket_policy.dart';
import 'package:test/test.dart';

void main() {
  group('EDH bracket policy tags', () {
    test('does not classify land search ramp as tutor', () {
      final cultivate = tagCardForBracket(
        name: 'Cultivate',
        typeLine: 'Sorcery',
        oracleText:
            'Search your library for up to two basic land cards, reveal those cards, put one onto the battlefield tapped and the other into your hand.',
      );
      final demonicTutor = tagCardForBracket(
        name: 'Demonic Tutor',
        typeLine: 'Sorcery',
        oracleText:
            'Search your library for a card, put that card into your hand, then shuffle.',
      );

      expect(cultivate.categories, isNot(contains(BracketCategory.tutor)));
      expect(
          cultivate.categories, isNot(contains(BracketCategory.gameChanger)));
      expect(demonicTutor.categories, contains(BracketCategory.tutor));
      expect(demonicTutor.categories, contains(BracketCategory.gameChanger));
    });

    test('keeps official gamechanger names tagged without suppressing roles',
        () {
      final field = tagCardForBracket(
        name: 'Field of the Dead',
        typeLine: 'Land',
        oracleText:
            'Whenever Field of the Dead or another land enters the battlefield under your control, if you control seven or more lands with different names, create a 2/2 black Zombie creature token.',
      );
      final breach = tagCardForBracket(
        name: 'Underworld Breach',
        typeLine: 'Enchantment',
        oracleText:
            'Each nonland card in your graveyard has escape. The escape cost is equal to the card\'s mana cost plus exile three other cards from your graveyard.',
      );

      expect(field.categories, contains(BracketCategory.gameChanger));
      expect(field.categories, contains(BracketCategory.valueEngine));
      expect(breach.categories, contains(BracketCategory.gameChanger));
      expect(breach.categories, contains(BracketCategory.infiniteCombo));
    });

    test('aligns curated infinite combo pieces with optimize roles', () {
      for (final name in const [
        'Basalt Monolith',
        'Demonic Consultation',
        'Dramatic Reversal',
        'Grand Architect',
        'Power Artifact',
        'Sensei\'s Divining Top',
        'Tainted Pact',
        'Thassa\'s Oracle',
        'Underworld Breach',
      ]) {
        final tags = tagCardForBracket(
          name: name,
          typeLine: 'Permanent',
          oracleText: '',
        );

        expect(
          tags.categories,
          contains(BracketCategory.infiniteCombo),
          reason: name,
        );
      }
    });

    test('detects curated free interaction even when oracle text is missing',
        () {
      final tags = tagCardForBracket(
        name: 'Fierce Guardianship',
        typeLine: 'Instant',
        oracleText: '',
      );

      expect(tags.categories, contains(BracketCategory.freeInteraction));
      expect(tags.categories, contains(BracketCategory.protection));
      expect(tags.categories, contains(BracketCategory.gameChanger));
    });

    test('detects curated fast mana lands', () {
      for (final name in const [
        'Gaea\'s Cradle',
        'Serra\'s Sanctum',
        'Mishra\'s Workshop',
      ]) {
        final tags = tagCardForBracket(
          name: name,
          typeLine: 'Legendary Land',
          oracleText: '',
        );

        expect(tags.categories, contains(BracketCategory.fastMana));
        expect(tags.categories, contains(BracketCategory.gameChanger));
      }
    });

    test('detects curated value engines without oracle text', () {
      for (final name in const [
        'Tergrid, God of Fright',
        'Consecrated Sphinx',
        'Field of the Dead',
        'Smothering Tithe',
        'The One Ring',
      ]) {
        final tags = tagCardForBracket(
          name: name,
          typeLine: 'Legendary Permanent',
          oracleText: '',
        );

        expect(
          tags.categories,
          contains(BracketCategory.valueEngine),
          reason: name,
        );
        expect(
          tags.categories,
          contains(BracketCategory.gameChanger),
          reason: name,
        );
      }
    });

    test('detects curated and text-based gamechanger stax pieces', () {
      for (final card in const [
        {
          'name': 'Narset, Parter of Veils',
          'oracle': 'Each opponent can\'t draw more than one card each turn.',
        },
        {
          'name': 'Grand Arbiter Augustin IV',
          'oracle': 'Spells your opponents cast cost {1} more to cast.',
        },
      ]) {
        final tags = tagCardForBracket(
          name: card['name']!,
          typeLine: 'Legendary Creature',
          oracleText: card['oracle']!,
        );

        expect(
          tags.categories,
          contains(BracketCategory.stax),
          reason: card['name'],
        );
        expect(
          tags.categories,
          contains(BracketCategory.gameChanger),
          reason: card['name'],
        );
      }
    });
  });
}
