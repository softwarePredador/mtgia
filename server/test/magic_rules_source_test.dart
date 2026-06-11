import 'dart:io';

import 'package:test/test.dart';

void main() {
  group('magicrules.txt official source snapshot', () {
    late final String rulesText;

    setUpAll(() {
      rulesText = File('magicrules.txt').readAsStringSync();
    });

    test('uses the current official 2026-04-17 Comprehensive Rules snapshot',
        () {
      expect(
        rulesText,
        contains('These rules are effective as of April 17, 2026.'),
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
        '903.3. Each deck has a legendary card designated as its commander.',
        '903.12c Each deck has a legendary card designated as its commander.',
      ]) {
        expect(rulesText, contains(ruleHeading), reason: ruleHeading);
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
