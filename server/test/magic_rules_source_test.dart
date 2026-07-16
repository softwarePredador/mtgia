import 'dart:io';

import 'package:test/test.dart';

void main() {
  group('magicrules.txt official source snapshot', () {
    late final String rulesText;

    setUpAll(() {
      rulesText = File('magicrules.txt').readAsStringSync();
    });

    // Latest-source freshness is additionally proved against the official
    // Wizards URL and PostgreSQL by `bin/sync_rules.dart --check`.
    test('pins the reviewed official 2026-06-19 snapshot', () {
      expect(
        rulesText,
        contains('These rules are effective as of June 19, 2026.'),
      );
      expect(
        rulesText,
        isNot(contains('These rules are effective as of April 17, 2026.')),
      );
      expect(
        rulesText,
        isNot(contains('These rules are effective as of February 27, 2026.')),
      );
    });

    test('contains the modern rules used by the ManaLoom battle matrix', () {
      for (final ruleHeading in const [
        '720. Omen Cards',
        '721. Station Cards',
        '722. Preparation Cards',
        '702.184. Station',
        '702.185. Warp',
        '701.67. Waterbend',
        '702.187. Mayhem',
        '702.188. Web-slinging',
        '802. Attack Multiple Players Option',
        '903.3. Each deck has a legendary card designated as its commander.',
        '903.12c Each deck has a legendary card designated as its commander.',
      ]) {
        expect(rulesText, contains(ruleHeading), reason: ruleHeading);
      }
    });

    test('keeps 2026 Commander and modern-mechanic rule anchors intact', () {
      for (final ruleText in const [
        'That card must be either (a) a creature card, (b) a Vehicle card, or (c) a Spacecraft card with one or more power/toughness boxes.',
        'If a card has any alternative characteristics, such as those of adventurer cards',
        'As long as this permanent has N or more charge counters on it, it has [abilities].',
        'You may cast this card from your hand by paying [cost] rather than its mana cost',
        'As a permanent with a prepare spell gains the prepared designation or phases in prepared',
        'As the attacking player declares each attacking creature, they choose a defending player',
      ]) {
        expect(rulesText, contains(ruleText), reason: ruleText);
      }
    });

    test('keeps hybrid identity strict for Commander references', () {
      expect(
        rulesText,
        contains('A hybrid mana symbol is all of its component colors.'),
      );
      expect(
        rulesText,
        contains(
          'The Commander variant uses color identity to determine what cards can be in a deck with a certain commander.',
        ),
      );
    });
  });
}
