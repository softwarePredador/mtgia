import 'package:server/ai/commander_reference_card_stats_support.dart';
import 'package:server/ai/commander_reference_deck_corpus_support.dart';
import 'package:server/ai/commander_reference_generate_fallback_support.dart';
import 'package:server/ai/commander_reference_profile_support.dart';
import 'package:test/test.dart';

void main() {
  group('Commander Reference Card Stats v1 | Lorehold', () {
    test('flattens expected packages into normalized, scoreable stats', () {
      final profile = buildLoreholdReferenceProfilePayload(
        updatedAt: DateTime.utc(2026, 5, 11, 12),
      );
      final stats = buildLoreholdReferenceCardStatsFromProfile(
        profile: profile,
        resolvedCardsByName: {
          'sensei\'s divining top': _resolvedCard(
            id: 'top-id',
            name: 'Sensei\'s Divining Top',
          ),
          'primal amulet': _resolvedCard(
            id: 'amulet-id',
            name: 'Primal Amulet // Primal Wellspring',
          ),
        },
      );

      expect(stats, isNotEmpty);
      final top = stats.singleWhere(
        (stat) => stat.cardName == "Sensei's Divining Top",
      );
      expect(top.cardId, equals('top-id'));
      expect(top.packageKey, equals('topdeck_and_miracle_setup'));
      expect(top.role, equals('topdeck_miracle_setup'));
      expect(top.score, greaterThanOrEqualTo(90));
      expect(
          top.confidenceRank,
          greaterThanOrEqualTo(
            commanderReferenceConfidenceRank('medium'),
          ));
      expect(top.unresolved, isFalse);

      final amulet = stats.singleWhere(
        (stat) => stat.cardName == 'Primal Amulet // Primal Wellspring',
      );
      expect(amulet.cardId, equals('amulet-id'));
      expect(amulet.unresolved, isFalse);

      final unresolved = stats.singleWhere(
        (stat) => stat.cardName == 'Scroll Rack',
      );
      expect(unresolved.cardId, isNull);
      expect(unresolved.unresolved, isTrue);
    });

    test('builds deterministic diagnostics and cache versions', () {
      final stats = [
        _stat(
          cardName: "Sensei's Divining Top",
          cardId: 'top-id',
          packageKey: 'topdeck_and_miracle_setup',
          role: 'topdeck_miracle_setup',
          score: 94,
          confidence: 'high',
        ),
        _stat(
          cardName: 'Scroll Rack',
          cardId: 'rack-id',
          packageKey: 'topdeck_and_miracle_setup',
          role: 'topdeck_miracle_setup',
          score: 94,
          confidence: 'high',
        ),
      ];
      final reversed = stats.reversed.toList();

      expect(
        commanderReferenceCardStatsCacheVersion(stats),
        equals(commanderReferenceCardStatsCacheVersion(reversed)),
      );

      final diagnostics = buildCommanderReferenceCardStatsDiagnostics(
        stats: stats,
        unresolvedCardNames: const ['Unresolved Test Card'],
      );
      expect(diagnostics['reference_card_stats_used'], isTrue);
      expect(diagnostics['on_theme_candidate_count'], equals(2));
      expect(
          diagnostics['package_keys'], equals(['topdeck_and_miracle_setup']));
      expect(diagnostics.toString().toLowerCase(), isNot(contains('secret')));
    });

    test('prompt uses stats as guidance without forcing every card', () {
      final prompt = buildCommanderReferenceCardStatsPrompt([
        _stat(
          cardName: "Sensei's Divining Top",
          cardId: 'top-id',
          packageKey: 'topdeck_and_miracle_setup',
          role: 'topdeck_miracle_setup',
          score: 94,
          confidence: 'high',
        ),
      ]);

      expect(prompt, contains('Reference card stats v1 active'));
      expect(prompt, contains("Sensei's Divining Top"));
      expect(prompt, contains('Do not force every card'));
    });

    test('compact prompt caps package cards and prioritizes corpus core', () {
      final stats = [
        for (var i = 0; i < 8; i++)
          _stat(
            cardName: 'Setup Card $i',
            cardId: 'setup-$i',
            packageKey: 'topdeck_and_miracle_setup',
            role: 'topdeck_miracle_setup',
            score: (90 - i).toDouble(),
            confidence: 'high',
          ),
        _stat(
          cardName: 'Priority Core Card',
          cardId: 'priority-id',
          packageKey: 'topdeck_and_miracle_setup',
          role: 'topdeck_miracle_setup',
          score: 10,
          confidence: 'high',
        ),
      ];

      final compactPrompt = buildCommanderReferenceCardStatsPrompt(
        stats,
        compact: true,
        priorityCardNames: const {'Priority Core Card'},
      );
      final fullPrompt = buildCommanderReferenceCardStatsPrompt(stats);

      expect(compactPrompt, contains('Compact mode'));
      expect(compactPrompt, contains('Priority Core Card'));
      expect(compactPrompt, contains('Setup Card 4'));
      expect(compactPrompt, isNot(contains('Setup Card 5')));
      expect(fullPrompt, contains('Setup Card 7'));
    });

    test('builds lower-confidence archetype reuse prompt', () {
      final prompt = buildCommanderReferenceArchetypeStatsPrompt(
        commanderName: 'Test Boros Commander',
        sourceCommanderNames: const [loreholdReferenceCommanderName],
        stats: [
          _stat(
            cardName: "Sensei's Divining Top",
            cardId: 'top-id',
            packageKey: 'topdeck_and_miracle_setup',
            role: 'topdeck_miracle_setup',
            score: 67,
            confidence: 'medium',
          ),
        ],
      );

      expect(prompt, contains('Test Boros Commander'));
      expect(prompt, contains(loreholdReferenceCommanderName));
      expect(prompt, contains('lower than an exact commander profile'));
      expect(prompt, contains('not as a decklist to copy'));
      expect(prompt, contains("Sensei's Divining Top"));
    });

    test('builds archetype reuse diagnostics without claiming exact profile',
        () {
      final diagnostics = buildCommanderReferenceArchetypeStatsDiagnostics(
        sourceCommanderNames: const [loreholdReferenceCommanderName],
        commanderColorIdentity: const ['R', 'W'],
        stats: [
          _stat(
            cardName: "Sensei's Divining Top",
            cardId: 'top-id',
            packageKey: 'topdeck_and_miracle_setup',
            role: 'topdeck_miracle_setup',
            score: 67,
            confidence: 'medium',
          ),
        ],
      );

      expect(diagnostics['reference_profile_used'], isFalse);
      expect(diagnostics['reference_card_stats_used'], isFalse);
      expect(diagnostics['archetype_reference_used'], isTrue);
      expect(diagnostics['archetype_candidate_count'], equals(1));
      expect(
        diagnostics['archetype_package_keys'],
        equals(['topdeck_and_miracle_setup']),
      );
      expect(
        diagnostics['archetype_source_commanders'],
        equals([loreholdReferenceCommanderName]),
      );
      expect(diagnostics['archetype_confidence'], equals('medium_low'));
    });

    test(
        'builds deterministic reference fallback from stats and corpus packages',
        () {
      final profile = buildLoreholdReferenceProfilePayload(
        updatedAt: DateTime.utc(2026, 5, 11, 12),
      );
      final deck = buildDeterministicReferenceDeck(
        profile: profile,
        referenceCardStats: [
          _stat(
            cardName: 'Arcane Signet',
            cardId: 'signet-id',
            packageKey: 'ramp_package',
            role: 'ramp',
            score: 80,
            confidence: 'high',
          ),
          _stat(
            cardName: 'Lorehold, the Historian',
            cardId: 'commander-id',
            packageKey: 'commander_package',
            role: 'commander',
            score: 100,
            confidence: 'high',
          ),
          _stat(
            cardName: 'Scroll Rack',
            cardId: 'rack-id',
            packageKey: 'topdeck_and_miracle_setup',
            role: 'topdeck_miracle_setup',
            score: 94,
            confidence: 'high',
          ),
        ],
        referenceDeckCorpusGuidance: const CommanderReferenceDeckCorpusGuidance(
          commanderName: 'Lorehold, the Historian',
          source: 'unit_test',
          deckCount: 3,
          acceptedDeckCount: 3,
          averageRoleCounts: {'lands': 37},
          topCards: [
            {
              'card_name': "Sensei's Divining Top",
              'deck_count': 3,
              'total_quantity': 3,
              'role': 'miracle_topdeck',
            },
            {
              'card_name': 'Young Pyromancer',
              'deck_count': 2,
              'total_quantity': 2,
              'role': 'spellslinger',
            },
          ],
          themeCounts: {'topdeck_big_spells': 3},
        ),
      );

      expect((deck['commander'] as Map)['name'],
          equals('Lorehold, the Historian'));
      final cards = (deck['cards'] as List).cast<Map>();
      final mainQuantity = cards.fold<int>(
        0,
        (total, card) => total + (card['quantity'] as int),
      );
      expect(mainQuantity, equals(99));
      expect(cards.where((card) => card['name'] == 'Lorehold, the Historian'),
          isEmpty);
      expect(
          cards.where((card) => card['name'] == 'Arcane Signet'), hasLength(1));
      expect(
          cards.where((card) => card['name'] == 'Scroll Rack'), hasLength(1));
      expect(
        cards.where((card) => card['name'] == "Sensei's Divining Top"),
        hasLength(1),
      );
      expect(cards.where((card) => card['name'] == 'Plains').single['quantity'],
          greaterThan(0));
      expect(
          cards.where((card) => card['name'] == 'Mountain').single['quantity'],
          greaterThan(0));
    });

    test('filters off-color generated cards before reference validation repair',
        () {
      final profile = buildLoreholdReferenceProfilePayload(
        updatedAt: DateTime.utc(2026, 5, 13, 12),
      );
      final result = filterReferenceGeneratedCardsByCommanderIdentity(
        profile: profile,
        commanderName: loreholdReferenceCommanderName,
        cards: [
          {'name': loreholdReferenceCommanderName, 'quantity': 1},
          {'name': "Sensei's Divining Top", 'quantity': 1},
          {'name': 'Temporal Mastery', 'quantity': 1},
          {'name': 'Swords to Plowshares', 'quantity': 1},
          {'name': 'Unknown Local Test Card', 'quantity': 1},
        ],
        resolvedCardsByName: {
          'sensei\'s divining top': _resolvedCard(
            id: 'top-id',
            name: "Sensei's Divining Top",
          ),
          'temporal mastery': _resolvedCard(
            id: 'temporal-id',
            name: 'Temporal Mastery',
            colorIdentity: const ['U'],
            typeLine: 'Sorcery',
          ),
          'swords to plowshares': _resolvedCard(
            id: 'swords-id',
            name: 'Swords to Plowshares',
            colorIdentity: const ['W'],
            typeLine: 'Instant',
          ),
        },
      );

      expect(result.removedOffColorNames, equals(['Temporal Mastery']));
      expect(
          result.removedUnresolvedNames, equals(['Unknown Local Test Card']));
      expect(
        result.cards.map((card) => card['name']),
        containsAll([
          "Sensei's Divining Top",
          'Swords to Plowshares',
        ]),
      );
      expect(
        result.cards.map((card) => card['name']),
        isNot(contains('Unknown Local Test Card')),
      );
      expect(
        result.cards.map((card) => card['name']),
        isNot(contains(loreholdReferenceCommanderName)),
      );
      expect(
        result.cards.map((card) => card['name']),
        isNot(contains('Temporal Mastery')),
      );
    });

    test('reference fallback skips avoid-pattern examples from candidate stats',
        () {
      final profile = buildLoreholdReferenceProfilePayload(
        updatedAt: DateTime.utc(2026, 5, 13, 12),
      );
      final deck = buildDeterministicReferenceDeck(
        profile: profile,
        targetMainQuantity: 12,
        referenceCardStats: [
          _stat(
            cardName: 'Temporal Mastery',
            cardId: 'temporal-id',
            packageKey: 'topdeck_and_miracle_setup',
            role: 'topdeck_miracle_setup',
            score: 99,
            confidence: 'high',
          ),
          _stat(
            cardName: "Sensei's Divining Top",
            cardId: 'top-id',
            packageKey: 'topdeck_and_miracle_setup',
            role: 'topdeck_miracle_setup',
            score: 94,
            confidence: 'high',
          ),
        ],
      );
      final cardNames =
          ((deck['cards'] as List).cast<Map>()).map((card) => card['name']);

      expect(cardNames, contains("Sensei's Divining Top"));
      expect(cardNames, isNot(contains('Temporal Mastery')));
    });

    test('flattens generic commander package stats', () {
      final profile = buildCommanderReferenceProfilePayload(
        commanderName: 'Test Commander',
        version: 'test_profile_v1',
        source: 'manual_reference_profile_v1',
        confidence: 'medium',
        sourceCount: 1,
        colorIdentity: const ['G'],
        themes: const [
          {'name': 'ramp_value', 'confidence': 'medium'}
        ],
        roleTargets: const {},
        expectedPackages: const {
          'ramp_package': ['Cultivate'],
        },
        avoidPatterns: const [],
      );

      final stats = buildCommanderReferenceCardStatsFromProfile(
        profile: profile,
        resolvedCardsByName: {
          'cultivate': _resolvedCard(id: 'cultivate-id', name: 'Cultivate'),
        },
      );

      expect(stats, hasLength(1));
      expect(stats.single.commanderName, equals('Test Commander'));
      expect(stats.single.packageKey, equals('ramp_package'));
      expect(stats.single.role, equals('ramp_package'));
      expect(stats.single.cardId, equals('cultivate-id'));
      expect(buildCommanderReferenceCardStatsPrompt(stats),
          contains('Test Commander'));
    });

    test('audits off-color reference cards before profile apply', () {
      final profile = buildCommanderReferenceProfilePayload(
        commanderName: 'Test Commander',
        version: 'test_profile_v1',
        source: 'manual_reference_profile_v1',
        confidence: 'medium',
        sourceCount: 1,
        colorIdentity: const ['G'],
        themes: const [
          {'name': 'green_value', 'confidence': 'medium'}
        ],
        roleTargets: const {},
        expectedPackages: const {
          'mixed_package': ['Cultivate', 'Lightning Bolt'],
        },
        avoidPatterns: const [],
      );
      final resolvedCardsByName = {
        'cultivate': _resolvedCard(id: 'cultivate-id', name: 'Cultivate'),
        'lightning bolt': _resolvedCard(
          id: 'bolt-id',
          name: 'Lightning Bolt',
          colorIdentity: const ['R'],
          typeLine: 'Instant',
        ),
      };
      final stats = buildCommanderReferenceCardStatsFromProfile(
        profile: profile,
        resolvedCardsByName: resolvedCardsByName,
      );

      expect(
        findOffColorCommanderReferenceCards(
          profile: profile,
          stats: stats,
          resolvedCardsByName: resolvedCardsByName,
        ),
        equals(['Lightning Bolt']),
      );
    });

    test('requires exact local commander card resolution before apply', () {
      final resolved = findResolvedCommanderReferenceCommanderCard(
        commanderName: 'Aziza, Mage Tower Captain',
        resolvedCardsByName: {
          'aziza, mage tower captain': _resolvedCard(
            id: 'aziza-id',
            name: 'Aziza, Mage Tower Captain',
            colorIdentity: const ['R', 'W'],
            typeLine: 'Legendary Creature - Human Wizard',
          ),
        },
      );

      expect(resolved.resolved, isTrue);
      expect(resolved.cardId, equals('aziza-id'));
      expect(resolved.cardName, equals('Aziza, Mage Tower Captain'));

      final wrongCard = findResolvedCommanderReferenceCommanderCard(
        commanderName: 'Zaffai and the Tempests',
        resolvedCardsByName: {
          'zaffai, thunder conductor': _resolvedCard(
            id: 'old-zaffai-id',
            name: 'Zaffai, Thunder Conductor',
            colorIdentity: const ['R', 'U'],
            typeLine: 'Legendary Creature - Human Shaman',
          ),
        },
      );

      expect(wrongCard.resolved, isFalse);
      expect(wrongCard.cardId, isNull);
    });

    test('evaluator respects generic profile color identity', () {
      final profile = buildCommanderReferenceProfilePayload(
        commanderName: 'Test Commander',
        version: 'test_profile_v1',
        source: 'manual_reference_profile_v1',
        confidence: 'medium',
        sourceCount: 1,
        colorIdentity: const ['G'],
        themes: const [],
        roleTargets: const {},
        expectedPackages: const {},
        avoidPatterns: const [],
      );
      final evaluation = evaluateGeneratedDeckAgainstReferenceStats(
        generatedDeck: {
          'cards': [
            {'name': 'Lightning Bolt', 'quantity': 1},
          ],
        },
        profile: profile,
        stats: const [],
        cardMetadataByName: {
          'lightning bolt': _resolvedCard(
            id: 'bolt-id',
            name: 'Lightning Bolt',
            colorIdentity: const ['R'],
            typeLine: 'Instant',
          ),
        },
      );

      expect(evaluation.counts['off_theme'], equals(1));
      expect(evaluation.classification, equals('off_theme'));
    });

    test('evaluator classifies on-theme, generic, questionable and off-theme',
        () {
      final profile = buildLoreholdReferenceProfilePayload(
        updatedAt: DateTime.utc(2026, 5, 11, 12),
      );
      final evaluation = evaluateGeneratedDeckAgainstReferenceStats(
        generatedDeck: {
          'cards': [
            {'name': "Sensei's Divining Top", 'quantity': 1},
            {'name': 'Sol Ring', 'quantity': 1},
            {'name': 'Plains', 'quantity': 10},
            {'name': 'Temporal Mastery', 'quantity': 1},
            {'name': 'Unknown Haymaker', 'quantity': 1},
          ],
        },
        profile: profile,
        stats: [
          _stat(
            cardName: "Sensei's Divining Top",
            cardId: 'top-id',
            packageKey: 'topdeck_and_miracle_setup',
            role: 'topdeck_miracle_setup',
            score: 94,
            confidence: 'high',
          ),
        ],
        cardMetadataByName: {
          'sol ring': _resolvedCard(
            id: 'sol-ring-id',
            name: 'Sol Ring',
            typeLine: 'Artifact',
            oracleText: 'Add two colorless mana.',
          ),
          'temporal mastery': _resolvedCard(
            id: 'temporal-id',
            name: 'Temporal Mastery',
            colorIdentity: const ['U'],
            typeLine: 'Sorcery',
          ),
        },
      );

      expect(evaluation.counts['on_theme'], equals(1));
      expect(evaluation.counts['generic'], equals(11));
      expect(evaluation.counts['questionable'], equals(1));
      expect(evaluation.counts['off_theme'], equals(1));
      expect(evaluation.classification, equals('off_theme'));
    });

    test('non-Lorehold commander is not a reference stats candidate', () {
      expect(
        isLoreholdCommanderReferenceCandidate('Atraxa, Praetors\' Voice'),
        isFalse,
      );
    });
  });
}

Map<String, dynamic> _resolvedCard({
  required String id,
  required String name,
  List<String> colorIdentity = const [],
  String typeLine = 'Artifact',
  String? oracleText,
}) {
  return {
    'id': id,
    'name': name,
    'type_line': typeLine,
    'color_identity': colorIdentity,
    'colors': colorIdentity,
    'oracle_text': oracleText,
    'mana_cost': '',
  };
}

CommanderReferenceCardStat _stat({
  required String cardName,
  required String cardId,
  required String packageKey,
  required String role,
  required double score,
  required String confidence,
}) {
  return CommanderReferenceCardStat(
    commanderName: loreholdReferenceCommanderName,
    commanderNameNormalized: normalizeCommanderReferenceName(
      loreholdReferenceCommanderName,
    ),
    cardName: cardName,
    cardNameNormalized: normalizeCommanderReferenceCardName(cardName),
    cardId: cardId,
    packageKey: packageKey,
    role: role,
    score: score,
    confidence: confidence,
    confidenceRank: commanderReferenceConfidenceRank(confidence),
    source: loreholdReferenceProfileSource,
    evidenceCount: 4,
    unresolved: false,
  );
}
