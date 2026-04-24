import 'package:test/test.dart';

import '../lib/meta/meta_deck_reference_support.dart';

void main() {
  group('selectMetaDeckReferenceCandidates', () {
    test(
        'prefers external competitive commander shell with exact partner match',
        () {
      final selection = selectMetaDeckReferenceCandidates(
        candidates: [
          MetaDeckReferenceCandidate(
            format: 'cEDH',
            archetype: 'Blue Farm',
            commanderName: 'Kraum, Ludevic\'s Opus',
            partnerCommanderName: 'Tymna the Weaver',
            shellLabel: 'Kraum, Ludevic\'s Opus + Tymna the Weaver',
            strategyArchetype: 'combo',
            sourceUrl: 'https://topdeck.gg/deck/example-1',
            cardList: '''
1 Kraum, Ludevic's Opus
1 Tymna the Weaver
1 Thassa's Oracle
1 Demonic Consultation
1 Underworld Breach
96 Island
''',
            placement: '1',
            createdAt: DateTime.utc(2026, 4, 24),
            sourceName: 'EDHTop16',
            sourceHost: 'edhtop16.com',
            sourceChain: const ['edhtop16_graphql', 'topdeck_deck_page'],
          ),
          MetaDeckReferenceCandidate(
            format: 'cEDH',
            archetype: 'Blue Farm',
            commanderName: 'Kraum, Ludevic\'s Opus',
            partnerCommanderName: 'Tymna the Weaver',
            shellLabel: 'Kraum, Ludevic\'s Opus + Tymna the Weaver',
            strategyArchetype: 'combo',
            sourceUrl: 'https://www.mtgtop8.com/event?e=1&d=1',
            cardList: '''
1 Kraum, Ludevic's Opus
1 Tymna the Weaver
1 Thassa's Oracle
1 Mystic Remora
1 Ad Nauseam
96 Island
''',
            placement: '2',
            createdAt: DateTime.utc(2026, 4, 23),
            sourceName: 'MTGTop8',
            sourceHost: 'mtgtop8.com',
            sourceChain: const [],
          ),
        ],
        commanderNames: const [
          'Kraum, Ludevic\'s Opus',
          'Tymna the Weaver',
        ],
        keywordPatterns: const ['blue farm'],
        commanderScope: 'competitive_commander',
        deckLimit: 2,
        priorityCardLimit: 8,
        preferExternalCompetitive: true,
      );

      expect(selection.hasReferences, isTrue);
      expect(selection.selectionReason, equals('exact_shell_match'));
      expect(selection.optimizePrioritySource,
          equals('competitive_meta_exact_shell_match'));
      expect(selection.references.first.sourceUrl,
          equals('https://topdeck.gg/deck/example-1'));
      expect(selection.sourceBreakdown['external'], equals(1));
      expect(selection.priorityCardNames, contains('Thassa\'s Oracle'));
      expect(selection.priorityCardNames, contains('Underworld Breach'));
    });

    test('does not mix duel commander rows into competitive commander scope',
        () {
      final selection = selectMetaDeckReferenceCandidates(
        candidates: [
          MetaDeckReferenceCandidate(
            format: 'EDH',
            archetype: 'Talrand Control',
            commanderName: 'Talrand, Sky Summoner',
            partnerCommanderName: '',
            shellLabel: 'Talrand, Sky Summoner',
            strategyArchetype: 'control',
            sourceUrl: 'https://www.mtgtop8.com/event?e=2&d=2',
            cardList: '''
1 Talrand, Sky Summoner
1 Counterspell
98 Island
''',
            placement: '1',
            createdAt: DateTime.utc(2026, 4, 24),
            sourceName: 'MTGTop8',
            sourceHost: 'mtgtop8.com',
            sourceChain: const [],
          ),
        ],
        commanderNames: const ['Talrand, Sky Summoner'],
        keywordPatterns: const ['talrand'],
        commanderScope: 'competitive_commander',
        deckLimit: 2,
        priorityCardLimit: 8,
        preferExternalCompetitive: true,
      );

      expect(selection.hasReferences, isFalse);
      expect(selection.priorityCardNames, isEmpty);
    });
  });

  group('buildMetaDeckEvidenceText', () {
    test('explains source_chain without leaking raw URLs', () {
      final selection = selectMetaDeckReferenceCandidates(
        candidates: [
          MetaDeckReferenceCandidate(
            format: 'cEDH',
            archetype: 'Atraxa Midrange',
            commanderName: 'Atraxa, Praetors\' Voice',
            partnerCommanderName: '',
            shellLabel: 'Atraxa, Praetors\' Voice',
            strategyArchetype: 'midrange',
            sourceUrl: 'https://topdeck.gg/deck/example-2',
            cardList: '''
1 Atraxa, Praetors' Voice
1 Mystic Remora
1 Rhystic Study
97 Island
''',
            placement: '3',
            createdAt: DateTime.utc(2026, 4, 24),
            sourceName: 'EDHTop16',
            sourceHost: 'edhtop16.com',
            sourceChain: const ['edhtop16_graphql', 'topdeck_deck_page'],
          ),
        ],
        commanderNames: const ['Atraxa, Praetors\' Voice'],
        keywordPatterns: const ['atraxa'],
        commanderScope: 'competitive_commander',
        deckLimit: 1,
        priorityCardLimit: 6,
        preferExternalCompetitive: true,
      );

      final text = buildMetaDeckEvidenceText(selection);

      expect(text, contains('source_chain note'));
      expect(text, contains('EDHTop16 standings -> TopDeck deck page'));
      expect(text, contains('Repeated priority cards'));
      expect(text.contains('http://') || text.contains('https://'), isFalse);
    });
  });
}
