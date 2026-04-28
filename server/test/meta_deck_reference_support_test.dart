import 'package:test/test.dart';

import '../lib/meta/meta_deck_reference_support.dart';

void main() {
  group('buildMetaDeckReferenceQueryParts', () {
    test('omits commander placeholders for keyword-only generate lookups', () {
      final parts = buildMetaDeckReferenceQueryParts(
        formatCodes: const ['cEDH'],
        keywordPatterns: const ['%kraum%', '%tymna%'],
        limit: 20,
      );

      expect(parts.hasFilters, isTrue);
      expect(parts.parameters.containsKey('formats'), isTrue);
      expect(parts.parameters.containsKey('limit'), isTrue);
      expect(parts.parameters.containsKey('keyword_patterns'), isTrue);
      expect(parts.parameters.containsKey('commander_names'), isFalse);
      expect(parts.parameters.containsKey('commander_like_patterns'), isFalse);
    });

    test('includes commander placeholders when optimize lookup has commanders',
        () {
      final parts = buildMetaDeckReferenceQueryParts(
        formatCodes: const ['cEDH'],
        commanderNames: const ['Kraum, Ludevic\'s Opus', 'Tymna the Weaver'],
        keywordPatterns: const ['%kraum%'],
        limit: 20,
      );

      expect(parts.hasFilters, isTrue);
      expect(parts.parameters.containsKey('commander_names'), isTrue);
      expect(parts.parameters.containsKey('commander_like_patterns'), isTrue);
      expect(parts.parameters.containsKey('keyword_patterns'), isTrue);
    });
  });

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

    test('does not leak competitive commander rows into duel commander scope',
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
            sourceUrl: 'https://edhtop16.com/tournament/sample#standing-8',
            cardList: '''
1 Kraum, Ludevic's Opus
1 Tymna the Weaver
1 Thassa's Oracle
97 Island
''',
            placement: '8',
            createdAt: DateTime.utc(2026, 4, 27),
            sourceName: 'EDHTop16',
            sourceHost: 'edhtop16.com',
            sourceChain: const ['edhtop16_graphql', 'topdeck_deck_page'],
          ),
        ],
        commanderNames: const [
          'Kraum, Ludevic\'s Opus',
          'Tymna the Weaver',
        ],
        keywordPatterns: const ['blue farm'],
        commanderScope: 'duel_commander',
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

  group('buildMetaDeckEvidencePayload', () {
    MetaDeckReferenceSelectionResult buildSelection() {
      return selectMetaDeckReferenceCandidates(
        candidates: [
          MetaDeckReferenceCandidate(
            format: 'cEDH',
            archetype: 'Blue Farm',
            commanderName: 'Kraum, Ludevic\'s Opus',
            partnerCommanderName: 'Tymna the Weaver',
            shellLabel: 'Kraum, Ludevic\'s Opus + Tymna the Weaver',
            strategyArchetype: 'combo',
            sourceUrl:
                'https://edhtop16.com/tournament/cedh-arcanum-sanctorum-57#standing-1',
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
            researchPayload: const <String, dynamic>{
              'collection_method': 'edhtop16_graphql_topdeck_deck_page_dry_run',
              'source_context': 'edhtop16_tournament_entry',
              'source_chain': <String>[
                'edhtop16_graphql',
                'topdeck_deck_page',
              ],
              'tournament_id': 'cedh-arcanum-sanctorum-57',
              'player_name': 'ThePapaSquats',
              'standing': 1,
            },
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
            sourceChain: const <String>[],
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
    }

    test('captures provenance event ranking and influenced cards', () {
      final payload = buildMetaDeckEvidencePayload(
        buildSelection(),
        maxPriorityCards: 8,
        maxReferences: 2,
      );

      expect(payload['selection_reason_code'], 'exact_shell_match');
      expect(payload['priority_source'], 'competitive_meta_exact_shell_match');

      final references = (payload['references'] as List)
          .whereType<Map>()
          .map((entry) => entry.cast<String, dynamic>())
          .toList(growable: false);
      expect(references, hasLength(2));
      expect(references.first['selection_rank'], 1);
      expect(
        references.first['commanders'],
        containsAll(const [
          'Kraum, Ludevic\'s Opus',
          'Tymna the Weaver',
        ]),
      );
      expect(
        (references.first['event'] as Map)['id'],
        'cedh-arcanum-sanctorum-57',
      );
      expect(
        ((references.first['event'] as Map)['label'] as String),
        contains('cEDH'),
      );
      expect(
        (references.first['provenance'] as Map)['collection_method'],
        'edhtop16_graphql_topdeck_deck_page_dry_run',
      );

      final influencedCards = (payload['influenced_cards'] as List)
          .whereType<Map>()
          .map((entry) => entry.cast<String, dynamic>())
          .toList(growable: false);
      final oracle = influencedCards.firstWhere(
        (card) => card['name'] == 'Thassa\'s Oracle',
      );
      expect(oracle['reference_count'], 2);
      expect(oracle['reason'], contains('Repeated across selected meta'));
    });

    test('matches returned output cards against influenced references', () {
      final payload = buildMetaDeckEvidencePayload(
        buildSelection(),
        maxPriorityCards: 8,
        maxReferences: 2,
      );
      final augmented = augmentMetaDeckEvidencePayloadWithOutputMatches(
        payload,
        outputCardNames: const ['Thassa\'s Oracle', 'Mystic Remora', 'Island'],
      );

      final matchedCards = (augmented['suggested_cards_influenced'] as List)
          .whereType<Map>()
          .map((entry) => entry.cast<String, dynamic>())
          .toList(growable: false);
      expect(matchedCards, hasLength(2));
      expect(
        matchedCards.map((entry) => entry['name']),
        containsAll(const ['Thassa\'s Oracle', 'Mystic Remora']),
      );
      expect(
        matchedCards.first['reason'],
        contains('selected meta references'),
      );
    });
  });
}
