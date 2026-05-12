import 'package:server/ai/commander_reference_deck_corpus_support.dart';
import 'package:test/test.dart';

void main() {
  group('Commander Reference Deck Corpus v1', () {
    test('parses corpus decks and builds stable source keys', () {
      final decks = parseCommanderReferenceDeckCorpus({
        'commander': 'Lorehold, the Historian',
        'decks': [
          {
            'source': 'manual_reference_deck_v1',
            'source_url': 'https://example.test/deck/1',
            'power_lane': 'casual',
            'theme': 'topdeck_big_spells',
            'cards': [
              {'name': 'Lorehold, the Historian', 'board': 'commander'},
              {'name': 'Plains', 'quantity': 99},
            ],
          }
        ],
      });

      expect(decks, hasLength(1));
      expect(decks.single.commanderName, equals('Lorehold, the Historian'));
      expect(decks.single.sourceDeckKey, hasLength(24));
      expect(decks.single.cards.first.board, equals('commander'));
    });

    test('accepts a complete resolved commander deck', () {
      final deck = _deck(cards: [
        const CommanderReferenceDeckCardInput(
          name: 'Lorehold, the Historian',
          quantity: 1,
          board: 'commander',
        ),
        const CommanderReferenceDeckCardInput(
          name: 'Plains',
          quantity: 87,
          board: 'main',
        ),
        const CommanderReferenceDeckCardInput(
          name: 'Sol Ring',
          quantity: 1,
          board: 'main',
        ),
        const CommanderReferenceDeckCardInput(
          name: 'Swords to Plowshares',
          quantity: 1,
          board: 'main',
        ),
        const CommanderReferenceDeckCardInput(
          name: 'Boros Charm',
          quantity: 1,
          board: 'main',
        ),
        const CommanderReferenceDeckCardInput(
          name: 'Sun Titan',
          quantity: 1,
          board: 'main',
        ),
        const CommanderReferenceDeckCardInput(
          name: 'Austere Command',
          quantity: 1,
          board: 'main',
        ),
        const CommanderReferenceDeckCardInput(
          name: 'Faithless Looting',
          quantity: 1,
          board: 'main',
        ),
        const CommanderReferenceDeckCardInput(
          name: 'Reconstruct History',
          quantity: 1,
          board: 'main',
        ),
        const CommanderReferenceDeckCardInput(
          name: 'Arcane Signet',
          quantity: 1,
          board: 'main',
        ),
        const CommanderReferenceDeckCardInput(
          name: 'Mountain',
          quantity: 4,
          board: 'main',
        ),
      ]);

      final analysis = analyzeCommanderReferenceDeck(
        deck: deck,
        resolvedCardsByName: _resolvedCards,
      );

      expect(analysis.accepted, isTrue);
      expect(analysis.mainQuantity, equals(99));
      expect(analysis.commanderQuantity, equals(1));
      expect(analysis.unresolvedCardNames, isEmpty);
      expect(analysis.offColorCardNames, isEmpty);
      expect(analysis.singletonViolations, isEmpty);
      expect(analysis.roleSummary['lands'], equals(91));
      expect(analysis.roleSummary['ramp'], greaterThanOrEqualTo(2));
    });

    test('rejects unresolved, off-color and singleton violations', () {
      final deck = _deck(cards: [
        const CommanderReferenceDeckCardInput(
          name: 'Lorehold, the Historian',
          quantity: 1,
          board: 'commander',
        ),
        const CommanderReferenceDeckCardInput(
          name: 'Plains',
          quantity: 96,
          board: 'main',
        ),
        const CommanderReferenceDeckCardInput(
          name: 'Counterspell',
          quantity: 1,
          board: 'main',
        ),
        const CommanderReferenceDeckCardInput(
          name: 'Sol Ring',
          quantity: 2,
          board: 'main',
        ),
        const CommanderReferenceDeckCardInput(
          name: 'Unknown Test Card',
          quantity: 1,
          board: 'main',
        ),
      ]);

      final analysis = analyzeCommanderReferenceDeck(
        deck: deck,
        resolvedCardsByName: _resolvedCards,
      );

      expect(analysis.accepted, isFalse);
      expect(analysis.rejectionReasons, contains('unresolved_cards'));
      expect(analysis.rejectionReasons, contains('off_color_cards'));
      expect(analysis.rejectionReasons, contains('singleton_violations'));
      expect(analysis.offColorCardNames, contains('Counterspell'));
      expect(analysis.singletonViolations['Sol Ring'], equals(2));
    });

    test('summarizes accepted corpus decks into role averages and top cards',
        () {
      final accepted = analyzeCommanderReferenceDeck(
        deck: _deck(cards: [
          const CommanderReferenceDeckCardInput(
            name: 'Lorehold, the Historian',
            quantity: 1,
            board: 'commander',
          ),
          const CommanderReferenceDeckCardInput(
            name: 'Plains',
            quantity: 97,
            board: 'main',
          ),
          const CommanderReferenceDeckCardInput(
            name: 'Sol Ring',
            quantity: 1,
            board: 'main',
          ),
          const CommanderReferenceDeckCardInput(
            name: 'Swords to Plowshares',
            quantity: 1,
            board: 'main',
          ),
        ]),
        resolvedCardsByName: _resolvedCards,
      );

      final summary = summarizeCommanderReferenceDeckCorpus([accepted]);

      expect(summary.deckCount, equals(1));
      expect(summary.acceptedDeckCount, equals(1));
      expect(summary.averageRoleCounts['lands'], equals(97));
      expect(
        summary.topCards.map((card) => card['card_name']),
        containsAll(['Sol Ring', 'Swords to Plowshares']),
      );
    });
  });
}

CommanderReferenceDeckInput _deck({
  required List<CommanderReferenceDeckCardInput> cards,
}) =>
    CommanderReferenceDeckInput(
      commanderName: 'Lorehold, the Historian',
      sourceDeckKey: 'test_deck',
      source: 'unit_test',
      sourceUrl: 'https://example.test/deck',
      powerLane: 'casual',
      theme: 'topdeck_big_spells',
      cards: cards,
    );

Map<String, Map<String, dynamic>> get _resolvedCards => {
      'lorehold, the historian': _card(
        id: 'commander-id',
        name: 'Lorehold, the Historian',
        colorIdentity: const ['R', 'W'],
        typeLine: 'Legendary Creature — Spirit',
      ),
      'plains': _card(id: 'plains-id', name: 'Plains', typeLine: 'Basic Land'),
      'mountain': _card(
        id: 'mountain-id',
        name: 'Mountain',
        typeLine: 'Basic Land',
      ),
      'sol ring': _card(
        id: 'sol-ring-id',
        name: 'Sol Ring',
        typeLine: 'Artifact',
        oracleText: '{T}: Add {C}{C}.',
      ),
      'arcane signet': _card(
        id: 'signet-id',
        name: 'Arcane Signet',
        typeLine: 'Artifact',
        oracleText: '{T}: Add one mana of any color.',
      ),
      'swords to plowshares': _card(
        id: 'swords-id',
        name: 'Swords to Plowshares',
        colorIdentity: const ['W'],
        typeLine: 'Instant',
        oracleText: 'Exile target creature.',
      ),
      'boros charm': _card(
        id: 'boros-charm-id',
        name: 'Boros Charm',
        colorIdentity: const ['R', 'W'],
        typeLine: 'Instant',
        oracleText: 'Permanents you control gain indestructible.',
      ),
      'sun titan': _card(
        id: 'sun-titan-id',
        name: 'Sun Titan',
        colorIdentity: const ['W'],
        typeLine: 'Creature — Giant',
      ),
      'austere command': _card(
        id: 'austere-id',
        name: 'Austere Command',
        colorIdentity: const ['W'],
        typeLine: 'Sorcery',
        oracleText: 'Destroy all artifacts. Destroy all enchantments.',
      ),
      'faithless looting': _card(
        id: 'looting-id',
        name: 'Faithless Looting',
        colorIdentity: const ['R'],
        typeLine: 'Sorcery',
        oracleText: 'Draw two cards, then discard two cards.',
      ),
      'reconstruct history': _card(
        id: 'history-id',
        name: 'Reconstruct History',
        colorIdentity: const ['R', 'W'],
        typeLine: 'Sorcery',
      ),
      'counterspell': _card(
        id: 'counterspell-id',
        name: 'Counterspell',
        colorIdentity: const ['U'],
        typeLine: 'Instant',
        oracleText: 'Counter target spell.',
      ),
    };

Map<String, dynamic> _card({
  required String id,
  required String name,
  String typeLine = 'Instant',
  List<String> colorIdentity = const [],
  String? oracleText,
}) =>
    {
      'id': id,
      'name': name,
      'type_line': typeLine,
      'color_identity': colorIdentity,
      'colors': colorIdentity,
      'oracle_text': oracleText,
      'mana_cost': '',
    };
