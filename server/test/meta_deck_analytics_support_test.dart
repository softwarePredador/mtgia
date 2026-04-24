import 'package:test/test.dart';

import '../lib/meta/meta_deck_analytics_support.dart';

void main() {
  group('classifyMetaDeckSource', () {
    test('classifies mtgtop8 URLs as mtgtop8', () {
      expect(
        classifyMetaDeckSource('https://www.mtgtop8.com/event?e=123&d=456'),
        metaDeckSourceMtgTop8,
      );
    });

    test('classifies non-mtgtop8 URLs as external', () {
      expect(
        classifyMetaDeckSource(
          'https://edhtop16.com/tournament/sample#standing-1',
        ),
        metaDeckSourceExternal,
      );
    });
  });

  group('resolveMetaDeckAnalyticsContext', () {
    test('keeps mtgtop8 EDH decks commander-aware via sideboard', () {
      final context = resolveMetaDeckAnalyticsContext(
        format: 'EDH',
        sourceUrl: 'https://www.mtgtop8.com/event?e=1&d=1',
        rawArchetype: 'Ertai Control',
        cardList: '''
1 Counterspell
98 Island
Sideboard
1 Ertai Resurrected
''',
      );

      expect(context.source, metaDeckSourceMtgTop8);
      expect(context.commanderSubformat, 'duel_commander');
      expect(context.commanderShell.commanderName, 'Ertai Resurrected');
      expect(context.commanderShell.shellLabel, 'Ertai Resurrected');
      expect(context.commanderShell.strategyArchetype, 'control');
      expect(context.parsedCardList.includesSideboardAsCommanderZone, isTrue);
      expect(context.parsedCardList.effectiveCards['Ertai Resurrected'], 1);
      expect(context.totalCards, 100);
    });

    test('keeps mtgtop8 cEDH partner shells commander-aware via sideboard', () {
      final context = resolveMetaDeckAnalyticsContext(
        format: 'cEDH',
        sourceUrl: 'https://www.mtgtop8.com/event?e=2&d=2',
        rawArchetype: 'Kraum + Tymna',
        cardList: '''
1 Thassa's Oracle
1 Demonic Consultation
1 Tainted Pact
1 Ad Nauseam
1 Underworld Breach
1 Brain Freeze
92 Island
Sideboard
1 Kraum, Ludevic's Opus
1 Tymna the Weaver
''',
      );

      expect(context.source, metaDeckSourceMtgTop8);
      expect(context.commanderSubformat, 'competitive_commander');
      expect(context.commanderShell.commanderName, 'Kraum, Ludevic\'s Opus');
      expect(context.commanderShell.partnerCommanderName, 'Tymna the Weaver');
      expect(
        context.commanderShell.shellLabel,
        'Kraum, Ludevic\'s Opus + Tymna the Weaver',
      );
      expect(context.commanderShell.strategyArchetype, 'combo');
      expect(context.parsedCardList.includesSideboardAsCommanderZone, isTrue);
      expect(context.totalCards, 100);
    });

    test('treats external cEDH mainboard lists as commander-aware too', () {
      final context = resolveMetaDeckAnalyticsContext(
        format: 'cEDH',
        sourceUrl: 'https://edhtop16.com/tournament/sample#standing-1',
        rawArchetype: 'Atraxa Combo',
        commanderName: 'Atraxa, Praetors\' Voice',
        cardList: '''
1 Atraxa, Praetors' Voice
1 Thassa's Oracle
1 Demonic Consultation
97 Island
''',
      );

      expect(context.source, metaDeckSourceExternal);
      expect(context.commanderSubformat, 'competitive_commander');
      expect(context.commanderShell.commanderName, 'Atraxa, Praetors\' Voice');
      expect(context.commanderShell.shellLabel, 'Atraxa Combo');
      expect(context.commanderShell.strategyArchetype, 'combo');
      expect(context.parsedCardList.includesSideboardAsCommanderZone, isTrue);
      expect(
        context.parsedCardList.effectiveCards["Atraxa, Praetors' Voice"],
        1,
      );
      expect(context.totalCards, 100);
    });
  });
}
