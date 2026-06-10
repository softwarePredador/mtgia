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
      expect(demonicTutor.categories, contains(BracketCategory.tutor));
    });

    test('keeps known false-positive gamechanger names untagged by default',
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

      expect(field.categories, isEmpty);
      expect(breach.categories, isEmpty);
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
      }
    });

    test('detects curated value engines without oracle text', () {
      final tags = tagCardForBracket(
        name: 'Tergrid, God of Fright',
        typeLine: 'Legendary Creature - God',
        oracleText: '',
      );

      expect(tags.categories, contains(BracketCategory.valueEngine));
    });
  });
}
