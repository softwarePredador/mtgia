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

    test('builds aggregate guidance prompt without copying full decklists', () {
      const guidance = CommanderReferenceDeckCorpusGuidance(
        commanderName: 'Lorehold, the Historian',
        source: 'commander_reference_deck_corpus_v1',
        deckCount: 3,
        acceptedDeckCount: 3,
        averageRoleCounts: {
          'lands': 32,
          'ramp': 14.67,
          'interaction': 6,
        },
        topCards: [
          {
            'card_name': 'Arid Mesa',
            'deck_count': 3,
            'total_quantity': 3,
            'role': 'lands',
          },
          {
            'card_name': 'Arcane Signet',
            'deck_count': 3,
            'total_quantity': 3,
            'role': 'ramp',
          },
          {
            'card_name': 'Call Forth the Tempest',
            'deck_count': 3,
            'total_quantity': 3,
            'role': 'board_wipe',
          },
          {
            'card_name': 'Young Pyromancer',
            'deck_count': 2,
            'total_quantity': 2,
            'role': 'spellslinger',
          },
          {
            'card_name': 'Wear // Tear',
            'deck_count': 1,
            'total_quantity': 1,
            'role': 'interaction',
          },
          {
            'card_name': 'Test Context Card',
            'deck_count': 1,
            'total_quantity': 1,
            'role': 'other',
          },
        ],
        themeCounts: {
          'lorehold_reference_spellslinger_big_spells': 3,
        },
      );

      final prompt = buildCommanderReferenceDeckCorpusPrompt(guidance);
      final diagnostics = guidance.toDiagnostics();
      final cacheVersion = commanderReferenceDeckCorpusCacheVersion(guidance);
      final packages = guidance.packages;

      expect(
          prompt, contains('Corpus size: 3 accepted public reference decks'));
      expect(prompt, contains('Use this as aggregate structure only'));
      expect(prompt, contains('Reference deck corpus v4 active'));
      expect(prompt, contains('ramp: 14.7 avg'));
      expect(prompt, isNot(contains('lands: 32.0 avg')));
      expect(prompt, contains('core_package'));
      expect(prompt, contains('Arcane Signet [ramp] (3/3)'));
      expect(prompt, contains('Call Forth the Tempest [board_wipe] (3/3)'));
      expect(prompt, contains('theme_package'));
      expect(prompt, contains('Young Pyromancer [spellslinger] (2/3)'));
      expect(prompt, contains('support_package'));
      expect(prompt, contains('Wear // Tear [interaction] (1/3)'));
      expect(prompt, isNot(contains('Test Context Card')));
      expect(
          prompt, contains('optional_contextual is excluded from the prompt'));
      expect(prompt, isNot(contains('cards":')));
      expect(
        prompt.indexOf('Call Forth the Tempest'),
        lessThan(prompt.indexOf('Arid Mesa')),
      );
      expect(diagnostics['reference_deck_corpus_used'], isTrue);
      expect(diagnostics['accepted_reference_deck_count'], equals(3));
      expect(diagnostics['corpus_package_counts'], {
        'core_package': 3,
        'theme_package': 1,
        'support_package': 1,
        'optional_contextual': 1,
      });
      expect(packages.corePackage.map((card) => card['card_name']), [
        'Arcane Signet',
        'Arid Mesa',
        'Call Forth the Tempest',
      ]);
      expect(packages.optionalContextual.single['card_name'],
          equals('Test Context Card'));
      expect(cacheVersion, startsWith('reference_deck_corpus_v4:'));
    });

    test('uses compact prompt when core package is complete', () {
      final topCards = <Map<String, dynamic>>[
        for (var i = 0; i < 26; i++)
          {
            'card_name': 'Core Test Card $i',
            'deck_count': 3,
            'total_quantity': 3,
            'role': i < 4 ? 'lands' : 'miracle_topdeck',
          },
        for (var i = 0; i < 4; i++)
          {
            'card_name': 'Theme Test Card $i',
            'deck_count': 2,
            'total_quantity': 2,
            'role': 'spellslinger',
          },
        for (var i = 0; i < 6; i++)
          {
            'card_name': 'Support Test Card $i',
            'deck_count': 1,
            'total_quantity': 1,
            'role': 'interaction',
          },
        {
          'card_name': 'Optional Noise Card',
          'deck_count': 1,
          'total_quantity': 1,
          'role': 'other',
        },
      ];
      final guidance = CommanderReferenceDeckCorpusGuidance(
        commanderName: 'Lorehold, the Historian',
        source: 'unit_test',
        deckCount: 3,
        acceptedDeckCount: 3,
        averageRoleCounts: const {
          'lands': 32,
          'ramp': 10,
          'interaction': 6,
          'draw_value': 5,
          'other': 4,
          'recursion': 3,
        },
        topCards: topCards,
        themeCounts: const {'topdeck_big_spells': 3},
      );

      final prompt = buildCommanderReferenceDeckCorpusPrompt(guidance);

      expect(shouldUseCompactCommanderReferenceCorpusPrompt(guidance), isTrue);
      expect(prompt, contains('Compact prompt mode active'));
      expect(prompt, isNot(contains('Optional Noise Card')));
      expect(prompt, isNot(contains('recursion: 3.0 avg')));
      expect(commanderReferenceCorpusCoreCardNames(guidance), hasLength(26));
      expect(prompt, contains('Core Test Card 0'));
      expect(prompt, isNot(contains('Core Test Card 25')));
    });

    test('evaluates generated deck coverage against corpus packages', () {
      const guidance = CommanderReferenceDeckCorpusGuidance(
        commanderName: 'Lorehold, the Historian',
        source: 'commander_reference_deck_corpus_v1',
        deckCount: 3,
        acceptedDeckCount: 3,
        averageRoleCounts: {'lands': 32},
        topCards: [
          {
            'card_name': "Sensei's Divining Top",
            'deck_count': 3,
            'total_quantity': 3,
            'role': 'miracle_topdeck',
          },
          {
            'card_name': 'Call Forth the Tempest',
            'deck_count': 3,
            'total_quantity': 3,
            'role': 'big_spell_payoff',
          },
          {
            'card_name': 'Young Pyromancer',
            'deck_count': 2,
            'total_quantity': 2,
            'role': 'spellslinger',
          },
          {
            'card_name': 'Wear // Tear',
            'deck_count': 1,
            'total_quantity': 1,
            'role': 'interaction',
          },
        ],
        themeCounts: {'topdeck_big_spells': 3},
      );

      final evaluation = evaluateGeneratedDeckAgainstReferenceCorpusPackages(
        guidance: guidance,
        generatedDeck: {
          'cards': [
            {'name': "Sensei's Divining Top", 'quantity': 1},
            {'name': 'Young Pyromancer', 'quantity': 1},
            {'name': 'Plains', 'quantity': 37},
          ],
        },
      );

      expect(evaluation, isNotNull);
      expect(evaluation!['policy_version'], equals('reference_deck_corpus_v4'));
      expect(evaluation['core_package_available'], equals(2));
      expect(evaluation['core_package_matched'], equals(1));
      expect(evaluation['core_package_coverage_ratio'], equals(0.5));
      final packageCoverage =
          (evaluation['package_coverage'] as Map).cast<String, dynamic>();
      final core =
          (packageCoverage['core_package'] as Map).cast<String, dynamic>();
      expect(core['matched'], equals(1));
      expect(
        (core['missed_top_cards'] as List).single['card_name'],
        equals('Call Forth the Tempest'),
      );
      expect(
        (evaluation['role_coverage'] as Map)['miracle_topdeck'],
        equals(1),
      );
      expect((evaluation['role_coverage'] as Map)['spellslinger'], equals(1));
    });

    test('classifies Lorehold-specific roles before generic buckets', () {
      expect(
        classifyCommanderReferenceDeckCardRole(
          "Sensei's Divining Top",
          _card(
            id: 'top-id',
            name: "Sensei's Divining Top",
            typeLine: 'Artifact',
          ),
        ),
        equals('miracle_topdeck'),
      );
      expect(
        classifyCommanderReferenceDeckCardRole(
          'Arcane Bombardment',
          _card(
            id: 'bombardment-id',
            name: 'Arcane Bombardment',
            typeLine: 'Enchantment',
            oracleText: 'Whenever you cast your first instant or sorcery spell',
          ),
        ),
        equals('spellslinger'),
      );
      expect(
        classifyCommanderReferenceDeckCardRole(
          'Hit the Mother Lode',
          _card(
            id: 'mother-lode-id',
            name: 'Hit the Mother Lode',
            typeLine: 'Sorcery',
            oracleText: 'Discover 10.',
          ),
        ),
        equals('big_spell_payoff'),
      );
      expect(
        classifyCommanderReferenceDeckCardRole(
          'Call Forth the Tempest',
          _card(
            id: 'tempest-id',
            name: 'Call Forth the Tempest',
            typeLine: 'Sorcery',
            oracleText: 'Discover 8.',
          ),
        ),
        equals('big_spell_payoff'),
      );
      expect(
        classifyCommanderReferenceDeckCardRole(
          'Enlightened Tutor',
          _card(
            id: 'tutor-id',
            name: 'Enlightened Tutor',
            typeLine: 'Instant',
            oracleText:
                'Search your library for an artifact or enchantment card.',
          ),
        ),
        equals('tutor'),
      );
      expect(
        classifyCommanderReferenceDeckCardRole(
          'Deflecting Swat',
          _card(
            id: 'swat-id',
            name: 'Deflecting Swat',
            typeLine: 'Instant',
            oracleText:
                'If you control a commander, you may cast this spell without paying its mana cost.',
          ),
        ),
        equals('protection'),
      );
      expect(
        classifyCommanderReferenceDeckCardRole(
          "Jeska's Will",
          _card(
            id: 'jeska-id',
            name: "Jeska's Will",
            typeLine: 'Sorcery',
            oracleText: 'Add {R} for each card in target opponent hand.',
          ),
        ),
        equals('ritual_treasure'),
      );
      expect(
        classifyCommanderReferenceDeckCardRole(
          'Underworld Breach',
          _card(
            id: 'breach-id',
            name: 'Underworld Breach',
            typeLine: 'Enchantment',
            oracleText: 'Each nonland card in your graveyard has escape.',
          ),
        ),
        equals('recursion'),
      );
      expect(
        classifyCommanderReferenceDeckCardRole(
          'Wheel of Fortune',
          _card(
            id: 'wheel-id',
            name: 'Wheel of Fortune',
            typeLine: 'Sorcery',
            oracleText:
                'Each player discards their hand, then draws seven cards.',
          ),
        ),
        equals('exile_value'),
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
