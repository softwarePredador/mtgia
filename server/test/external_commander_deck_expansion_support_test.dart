import 'package:test/test.dart';

import '../lib/meta/external_commander_deck_expansion_support.dart';

void main() {
  group('edhTop16TournamentIdFromUrl', () {
    test('extracts tournament slug', () {
      expect(
        edhTop16TournamentIdFromUrl(
          'https://edhtop16.com/tournament/cedh-arcanum-sanctorum-57',
        ),
        'cedh-arcanum-sanctorum-57',
      );
    });

    test('rejects non tournament URL', () {
      expect(
        () => edhTop16TournamentIdFromUrl('https://edhtop16.com/about'),
        throwsFormatException,
      );
    });
  });

  group('parseEdhTop16TournamentEntries', () {
    test('parses standings and decklist URLs from GraphQL payload', () {
      final entries = parseEdhTop16TournamentEntries(
        <String, dynamic>{
          'data': <String, dynamic>{
            'tournament': <String, dynamic>{
              'entries': <Map<String, dynamic>>[
                <String, dynamic>{
                  'standing': 1,
                  'decklist': 'https://topdeck.gg/deck/event/player',
                  'player': <String, dynamic>{'name': 'Player 1'},
                  'commander': <String, dynamic>{
                    'name': 'Scion of the Ur-Dragon',
                  },
                },
              ],
            },
          },
        },
      );

      expect(entries, hasLength(1));
      expect(entries.single.standing, 1);
      expect(entries.single.playerName, 'Player 1');
      expect(entries.single.commanderLabel, 'Scion of the Ur-Dragon');
      expect(
          entries.single.decklistUrl, 'https://topdeck.gg/deck/event/player');
    });
  });

  group('parseTopDeckDeckObjectFromHtml', () {
    test('extracts commanders, mainboard and card list from deckObj', () {
      final html = '''
<html><script>
    const deckObj = {"Commanders":[{"count":1,"name":"Kraum, Ludevic's Opus"},{"count":1,"name":"Tymna the Weaver"}],"Mainboard":[{"count":2,"name":"Island"},{"count":96,"name":"Plains"}],"metadata":{"importedFrom":"https://moxfield.com/decks/example"}};
    const playerName = "Tester";
</script></html>
''';

      final deck = parseTopDeckDeckObjectFromHtml(html);

      expect(deck.commanderCount, 2);
      expect(deck.mainboardCount, 98);
      expect(deck.totalCards, 100);
      expect(
          deck.commanderNames, ['Kraum, Ludevic\'s Opus', 'Tymna the Weaver']);
      expect(deck.importedFrom, 'https://moxfield.com/decks/example');
      expect(
        deck.cardList,
        contains('1 Kraum, Ludevic\'s Opus\n1 Tymna the Weaver\n2 Island'),
      );
    });

    test('falls back to copyDecklist template when deckObj is absent', () {
      final html = '''
<html>
  <body>
    <a title="View Original Source" href="https://moxfield.com/decks/example"></a>
    <script>
      function copyDecklist() {
        const decklistContent = `~~Commanders~~
1 Malcolm, Keen-Eyed Navigator
1 Vial Smasher the Fierce

~~Mainboard~~
98 Island
`;
        navigator.clipboard.writeText(decklistContent);
      }
    </script>
  </body>
</html>
''';

      final deck = parseTopDeckDeckObjectFromHtml(html);

      expect(deck.commanderCount, 2);
      expect(deck.mainboardCount, 98);
      expect(deck.totalCards, 100);
      expect(
        deck.commanderNames,
        ['Malcolm, Keen-Eyed Navigator', 'Vial Smasher the Fierce'],
      );
      expect(deck.importedFrom, 'https://moxfield.com/decks/example');
    });
  });

  group('buildExternalCommanderCandidateFromExpansion', () {
    test('builds import-compatible candidate from expanded deck', () {
      final candidate = buildExternalCommanderCandidateFromExpansion(
        tournamentUrl:
            'https://edhtop16.com/tournament/cedh-arcanum-sanctorum-57',
        tournamentId: 'cedh-arcanum-sanctorum-57',
        entry: const EdhTop16TournamentEntry(
          standing: 1,
          decklistUrl: 'https://topdeck.gg/deck/event/player',
          playerName: 'Player 1',
          commanderLabel: 'Scion of the Ur-Dragon',
        ),
        expandedDeck: const ExpandedTopDeckDeck(
          commanders: <ExpandedDeckCard>[
            ExpandedDeckCard(name: 'Scion of the Ur-Dragon', quantity: 1),
          ],
          mainboard: <ExpandedDeckCard>[
            ExpandedDeckCard(name: 'Island', quantity: 99),
          ],
          cardList: '1 Scion of the Ur-Dragon\n99 Island',
          importedFrom: 'https://moxfield.com/decks/example',
        ),
      );

      expect(candidate['source_name'], 'EDHTop16');
      expect(candidate['source_url'], endsWith('#standing-1'));
      expect(candidate['subformat'], 'competitive_commander');
      expect(candidate['commander_name'], 'Scion of the Ur-Dragon');
      expect(candidate['card_list'], contains('99 Island'));
      expect(
        (candidate['research_payload'] as Map<String, dynamic>)['source_chain'],
        ['edhtop16_graphql', 'topdeck_deck_page'],
      );
    });
  });
}
