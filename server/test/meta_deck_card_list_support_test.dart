import 'package:test/test.dart';

import '../lib/meta/meta_deck_card_list_support.dart';

void main() {
  group('parseMetaDeckCardList', () {
    test('keeps normal format sideboard out of effective cards', () {
      final parsed = parseMetaDeckCardList(
        format: 'MO',
        cardList: '''
4 Lightning Bolt
2 Island
Sideboard
1 Blood Moon
''',
      );

      expect(parsed.mainboardTotal, 6);
      expect(parsed.sideboardTotal, 1);
      expect(parsed.effectiveTotal, 6);
      expect(parsed.effectiveCards, isNot(contains('Blood Moon')));
      expect(parsed.includesSideboardAsCommanderZone, isFalse);
    });

    test('counts EDH sideboard as commander zone in effective cards', () {
      final parsed = parseMetaDeckCardList(
        format: 'EDH',
        cardList: '''
1 Counterspell
98 Island
Sideboard
1 Ertai Resurrected
''',
      );

      expect(parsed.mainboardTotal, 99);
      expect(parsed.sideboardTotal, 1);
      expect(parsed.effectiveTotal, 100);
      expect(parsed.effectiveCards['Ertai Resurrected'], 1);
      expect(parsed.includesSideboardAsCommanderZone, isTrue);
    });

    test('counts cEDH partner commanders from sideboard', () {
      final parsed = parseMetaDeckCardList(
        format: 'cEDH',
        cardList: '''
1 Sol Ring
97 Island
Sideboard
1 Kraum, Ludevic's Opus
1 Tymna the Weaver
''',
      );

      expect(parsed.mainboardTotal, 98);
      expect(parsed.sideboardTotal, 2);
      expect(parsed.effectiveTotal, 100);
      expect(parsed.effectiveCards['Kraum, Ludevic\'s Opus'], 1);
      expect(parsed.effectiveCards['Tymna the Weaver'], 1);
    });

    test('normalizes optional set codes', () {
      final parsed = parseMetaDeckCardList(
        format: 'EDH',
        cardList: '''
1 Sol Ring (CMM)
Sideboard
1 Atraxa, Praetors' Voice (2XM)
''',
      );

      expect(parsed.effectiveCards['Sol Ring'], 1);
      expect(parsed.effectiveCards["Atraxa, Praetors' Voice"], 1);
    });
  });
}
