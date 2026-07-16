import 'dart:io';

import 'package:server/ai/commander_learned_deck_support.dart';
import 'package:server/ai/commander_reference_profile_support.dart';
import 'package:test/test.dart';

void main() {
  group('Commander learned deck support', () {
    test('parses raw Hermes learned deck payload into idempotent PG input', () {
      final input = parseCommanderLearnedDeckInput({
        'id': 82,
        'commander': 'Lorehold, the Historian',
        'deck_name': 'Lorehold Best-of Learned No Premium Mox 2026-06-02',
        'source_url': 'manual-import:f3d63c68be1f3fa7',
        'archetype': 'fast-mana-copy-combo-big-spells-no-premium-mox',
        'card_list': '1 Lorehold, the Historian\n1 Sol Ring\n2 Mountain',
        'score': 136.5,
        'metadata': {'hermes_active_deck_id': 6},
      });

      expect(input.sourceSystem, equals('hermes'));
      expect(input.sourceRef, equals('learned_deck:82'));
      expect(input.commanderNameNormalized, equals('lorehold, the historian'));
      expect(input.cardCount, equals(4));
      expect(input.cards.map((card) => card.name), contains('Sol Ring'));
      expect(input.metadata['hermes_learned_deck_id'], equals(82));
      expect(input.metadata['hermes_active_deck_id'], equals(6));
      expect(input.isActive, isTrue);
    });

    test(
      'parses bullets, comments, collection suffixes and duplicate names',
      () {
        final cards = parseCommanderLearnedDeckCards('''
1 Korvold, Fae-Cursed King
2 Forest
- 1 Sol Ring # ramp
1 Command Tower (CMM) 123
''');

        expect(
          cards.map((card) => (card.name, card.quantity)).toList(),
          containsAll([
            ('Korvold, Fae-Cursed King', 1),
            ('Forest', 2),
            ('Sol Ring', 1),
            ('Command Tower', 1),
          ]),
        );
      },
    );

    test(
      'parses JSON-array card lists used by learned-deck metadata audits',
      () {
        final input = parseCommanderLearnedDeckInput({
          'id': 82,
          'commander': 'Lorehold, the Historian',
          'card_list': '''
[
  {"name": "Lorehold, the Historian", "quantity": 1},
  {"name": "Lim-Dûl’s Vault", "quantity": 1},
  {"card_name": "Troll of Khazad-dûm", "qty": 2},
  {"name": "Command Tower"},
  "1 Sol Ring"
]
''',
        });

        expect(input.cardCount, equals(6));
        expect(
          input.cards.map((card) => (card.name, card.quantity)).toList(),
          containsAll([
            ('Lorehold, the Historian', 1),
            ('Lim-Dûl’s Vault', 1),
            ('Troll of Khazad-dûm', 2),
            ('Command Tower', 1),
            ('Sol Ring', 1),
          ]),
        );
      },
    );

    test('validates Commander 100-card learned deck gate', () {
      final main = List.generate(99, (index) => '1 Learned Card $index');
      final input = parseCommanderLearnedDeckInput({
        'id': 82,
        'commander': 'Lorehold, the Historian',
        'card_list': ['1 Lorehold, the Historian', ...main].join('\n'),
        'card_count': 100,
        'legal_status': 'commander_legal',
      });

      final validation = validateCommanderLearnedDeckInput(input);

      expect(validation.ok, isTrue);
      expect(validation.parsedCardCount, equals(100));
      expect(validation.commanderQuantity, equals(1));
      expect(validation.mainQuantity, equals(99));
      expect(validation.blockers, isEmpty);
    });

    test(
      'blocks learned deck import when count or commander slot is invalid',
      () {
        final input = parseCommanderLearnedDeckInput({
          'id': 83,
          'commander': 'Lorehold, the Historian',
          'card_list': '1 Sol Ring\n1 Mountain',
          'card_count': 100,
        });

        final validation = validateCommanderLearnedDeckInput(input);

        expect(validation.ok, isFalse);
        expect(
          validation.blockers.join('\n'),
          contains('card_count declarado (100) difere do total parseado (2)'),
        );
        expect(
          validation.blockers.join('\n'),
          contains('exatamente 1 comandante'),
        );
      },
    );

    test(
      'runtime completeness helper rejects partial active learned decks',
      () {
        final input = parseCommanderLearnedDeckInput({
          'source_system': 'edhrec',
          'source_ref': 'learned_deck:7',
          'commander_name': 'Korvold, Fae-Cursed King',
          'deck_name': 'EDHREC Average - Korvold, Fae-Cursed King',
          'card_list': List.generate(
            90,
            (index) => '1 Korvold Card $index',
          ).join('\n'),
          'card_count': 90,
        });

        expect(isCompleteCommanderLearnedDeckInput(input), isFalse);
        expect(
          validateCommanderLearnedDeckInput(input).blockers.join('\n'),
          contains('deck Commander aprendido precisa ter 100 cartas'),
        );
      },
    );

    test(
      'runtime completeness rejects learned decks without confirmed legality',
      () {
        final main = List.generate(99, (index) => '1 Learned Card $index');
        final input = parseCommanderLearnedDeckInput({
          'id': 84,
          'commander': 'Lorehold, the Historian',
          'card_list': ['1 Lorehold, the Historian', ...main].join('\n'),
          'card_count': 100,
          'legal_status': 'registered_pending_card_rule_validation',
        });

        final validation = validateCommanderLearnedDeckInput(input);

        expect(validation.ok, isFalse);
        expect(isCompleteCommanderLearnedDeckInput(input), isFalse);
        expect(
          validation.blockers.join('\n'),
          contains(
            'legal_status precisa estar confirmado como legal ou commander_legal',
          ),
        );
      },
    );

    test('runtime completeness rejects a missing legal status', () {
      final main = List.generate(99, (index) => '1 Learned Card $index');
      final input = parseCommanderLearnedDeckInput({
        'id': 85,
        'commander': 'Lorehold, the Historian',
        'card_list': ['1 Lorehold, the Historian', ...main].join('\n'),
        'card_count': 100,
      });

      final validation = validateCommanderLearnedDeckInput(input);

      expect(input.legalStatus, isNull);
      expect(validation.ok, isFalse);
      expect(validation.blockers.join('\n'), contains('recebeu vazio'));
    });

    test('computes canonical learned deck role summary from multi-tags', () {
      final summary = computeCommanderLearnedDeckRoleSummary(
        cards: const [
          CommanderLearnedDeckCardLine(
            name: 'Lorehold, the Historian',
            quantity: 1,
          ),
          CommanderLearnedDeckCardLine(name: 'Plains', quantity: 2),
          CommanderLearnedDeckCardLine(name: 'Sol Ring', quantity: 1),
          CommanderLearnedDeckCardLine(name: 'Boros Charm', quantity: 1),
          CommanderLearnedDeckCardLine(name: 'Big Score', quantity: 1),
        ],
        commanderNameNormalized: 'lorehold, the historian',
        tagsByName: const {
          'plains': {'land', 'ramp'},
          'sol ring': {'ramp'},
          'boros charm': {'protection', 'removal'},
          'big score': {'draw', 'ramp'},
        },
        landNames: const {'plains'},
      );

      expect(summary['total_lands'], equals(2));
      expect(summary['ramp_count'], equals(2));
      expect(summary['draw_count'], equals(1));
      expect(summary['removal_count'], equals(1));
      expect(summary['protection_count'], equals(1));
    });

    test('canonical Lorehold learned deck metadata resolves 33 lands', () {
      final lands = List.generate(
        33,
        (index) => CommanderLearnedDeckCardLine(
          name: 'Lorehold Land $index',
          quantity: 1,
        ),
      );
      final spells = List.generate(
        66,
        (index) => CommanderLearnedDeckCardLine(
          name: 'Lorehold Spell $index',
          quantity: 1,
        ),
      );
      final cards = [
        const CommanderLearnedDeckCardLine(
          name: 'Lorehold, the Historian',
          quantity: 1,
        ),
        ...lands,
        ...spells,
      ];
      final summary = computeCommanderLearnedDeckRoleSummary(
        cards: cards,
        commanderNameNormalized: 'lorehold, the historian',
        tagsByName: const {},
        landNames: lands.map((card) => card.name.toLowerCase()).toSet(),
      );

      expect(
        cards.fold<int>(0, (sum, card) => sum + card.quantity),
        equals(100),
      );
      expect(summary['total_lands'], equals(33));
    });

    test(
      'canonical learned deck metadata covers Lorehold critical role gaps',
      () {
        final summary = computeCommanderLearnedDeckRoleSummary(
          cards: const [
            CommanderLearnedDeckCardLine(
              name: 'Lorehold, the Historian',
              quantity: 1,
            ),
            CommanderLearnedDeckCardLine(name: "Orim's Chant", quantity: 1),
            CommanderLearnedDeckCardLine(name: 'Ruby Medallion', quantity: 1),
            CommanderLearnedDeckCardLine(name: 'Scroll Rack', quantity: 1),
            CommanderLearnedDeckCardLine(name: 'Victory Chimes', quantity: 1),
            CommanderLearnedDeckCardLine(name: 'Land Tax', quantity: 1),
            CommanderLearnedDeckCardLine(name: 'Plains', quantity: 1),
          ],
          commanderNameNormalized: 'lorehold, the historian',
          tagsByName: const {},
          landNames: const {'plains'},
        );

        expect(summary['total_lands'], equals(1));
        expect(summary['protection_count'], equals(1));
        expect(summary['ramp_count'], equals(3));
        expect(summary['draw_count'], equals(1));
        expect(summary['engine_count'], equals(2));
        expect(summary['tutor_count'], equals(1));
      },
    );

    test('metadata canonicalization result exposes safe fallback diagnostics', () {
      final result =
          CommanderLearnedDeckMetadataCanonicalizationResult.persistedFallback(
            const {'total_lands': 30},
            reason:
                commanderLearnedDeckRoleSummaryFallbackReasonCanonicalizationFailed,
          );

      expect(result.metadata['total_lands'], equals(30));
      expect(
        result.source,
        equals(commanderLearnedDeckRoleSummarySourcePersistedFallback),
      );
      expect(
        result.fallbackReason,
        equals(
          commanderLearnedDeckRoleSummaryFallbackReasonCanonicalizationFailed,
        ),
      );
      expect(result.usedFallback, isTrue);
    });

    test(
      'route prefers promoted learned deck before deterministic fallback',
      () {
        final route =
            File('routes/ai/commander-reference/index.dart').readAsStringSync();
        final promotedIndex = route.indexOf(
          '_buildPromotedCommanderLearningDeck',
        );
        final fallbackIndex = route.indexOf('_buildReferenceLearningDeck');

        expect(promotedIndex, greaterThanOrEqualTo(0));
        expect(fallbackIndex, greaterThanOrEqualTo(0));
        expect(promotedIndex, lessThan(fallbackIndex));
        expect(route, contains("'source': 'promoted_learned_deck_pg'"));
      },
    );

    test('dedicated route exposes promoted learned deck payload', () {
      final route =
          File('routes/ai/commander-learning/index.dart').readAsStringSync();

      expect(route, contains('commander_learned_decks'));
      expect(route, contains("'source': 'pg_commander_learned_deck_summary'"));
      expect(route, contains("'source': 'pg_commander_learned_decks'"));
      expect(route, contains("'commanders': activeDecks"));
      expect(route, contains('WITH active AS'));
      expect(route, contains('AND card_count = 100'));
      expect(
        route,
        contains("AND card_list ILIKE '%' || commander_name || '%'"),
      );
      expect(route, isNot(contains('FROM commander_learning_snapshot')));
      expect(route, contains("'recommended_deck': recommendedDeck"));
      expect(route, contains("'source': 'promoted_learned_deck_pg'"));
      expect(route, contains("'source_confidence': _sourceConfidence"));
      expect(route, contains("'win_conditions': _winConditions"));
      expect(
        route,
        contains('canonicalizeCommanderLearnedDeckMetadataWithStatus'),
      );
      expect(route, contains("'role_summary': _roleSummaryFromMetadata"));
      expect(route, contains("'role_summary_source': roleSummarySource"));
      expect(
        route,
        contains("'role_summary_fallback_reason': roleSummaryFallbackReason"),
      );
      expect(route, isNot(contains("'metadata': learnedDeck.metadata")));
      expect(route, isNot(contains("'metadata': deck.metadata")));
      expect(
        route,
        isNot(contains("'role_summary': _roleSummary(learnedDeck)")),
      );
      expect(route, isNot(contains("'role_summary': _roleSummary(deck)")));
    });

    test('commander learning list route exposes safe summary fields only', () {
      final route =
          File('routes/ai/commander-learning/index.dart').readAsStringSync();
      final listLoader = _sectionBetween(
        route,
        'Future<List<Map<String, dynamic>>> _loadActiveLearnedDeckSummaries',
        'CommanderLearnedDeckInput _learnedDeckFromRow',
      );

      for (final field in const [
        "'commander'",
        "'deck_name'",
        "'source_system'",
        "'source_ref'",
        "'source_url'",
        "'archetype'",
        "'card_count'",
        "'score'",
        "'legal_status'",
        "'promoted_at'",
        "'last_synced_at'",
        "'active_learned_deck_count'",
        "'learned_archetypes'",
      ]) {
        expect(listLoader, contains(field));
      }
      for (final forbiddenField in const [
        "'win_conditions'",
        "'role_summary'",
        "'promoted_deck'",
        "'recommended_deck'",
        "'decklist'",
        "'cards'",
        "'metadata'",
      ]) {
        expect(listLoader, isNot(contains(forbiddenField)));
      }
    });

    test('Commander Learning API doc separates list and detail contracts', () {
      final doc =
          File('doc/COMMANDER_LEARNING_API_2026-06-03.md').readAsStringSync();
      final listSection = _sectionBetween(
        doc,
        '## Listar Decks Aprendidos Ativos',
        '## Buscar Deck Aprendido De Um Comandante',
      );
      final sourceSection = _sectionBetween(
        doc,
        '## Fonte De Dados',
        '## Garantias Esperadas Para Lorehold',
      );

      expect(listSection, contains('pg_commander_learned_deck_summary'));
      expect(listSection, contains('Nao retorna `win_conditions`'));
      expect(listSection, isNot(contains('"win_conditions"')));
      expect(listSection, isNot(contains('"role_summary"')));
      expect(
        sourceSection,
        contains('canonicalizeCommanderLearnedDeckMetadata'),
      );
      expect(sourceSection, contains('role_summary_source'));
      expect(sourceSection, contains('persisted_metadata_fallback'));
      expect(sourceSection, contains('recomputados em tempo de leitura'));
      expect(
        sourceSection,
        contains('pode continuar defasado ate um backfill aprovado'),
      );
    });

    test('commander reference does not expose raw learned deck metadata', () {
      final route =
          File('routes/ai/commander-reference/index.dart').readAsStringSync();

      expect(route, contains("'source': 'promoted_learned_deck_pg'"));
      expect(route, isNot(contains("'metadata': learnedDeck['metadata']")));
    });

    test('read-only AI helper routes stay auth-only in AI middleware', () {
      final middleware = File('routes/ai/_middleware.dart').readAsStringSync();

      expect(middleware, contains("'/ai/commander-learning'"));
      expect(middleware, contains("'/ai/generate/jobs/'"));
      expect(middleware, contains("'/ai/optimize/jobs/'"));
      expect(middleware, contains('authOnlyHandler'));
      expect(middleware, contains('costlyAiHandler'));
      expect(
        middleware.indexOf("'/ai/commander-learning'"),
        lessThan(middleware.indexOf('return costlyAiHandler(context)')),
      );
      expect(
        middleware.indexOf("'/ai/generate/jobs/'"),
        lessThan(middleware.indexOf('return costlyAiHandler(context)')),
      );
      expect(
        middleware.indexOf("'/ai/optimize/jobs/'"),
        lessThan(middleware.indexOf('return costlyAiHandler(context)')),
      );
    });

    test(
      'canonical learned deck metadata uses card identity bridge for split and alias resolution',
      () {
        final source =
            File(
              'lib/ai/commander_learned_deck_support.dart',
            ).readAsStringSync();

        expect(source, contains('LEFT JOIN card_identity_bridge cib'));
        expect(source, contains("cib.normalized_lookup_name = w.lowered_name"));
        expect(
          source,
          contains(
            "cib.normalized_canonical_name LIKE w.lowered_name || ' // %'",
          ),
        );
        expect(
          source,
          contains('CommanderLearnedDeckMetadataCanonicalizationResult'),
        );
        expect(source, contains('metadata_canonicalization_failed'));
        expect(
          source,
          isNot(contains('catch (_) {\n    return input.metadata;\n  }')),
        );
      },
    );

    test('commander learning card ids resolve through card identity bridge', () {
      final route =
          File('routes/ai/commander-learning/index.dart').readAsStringSync();
      final helpers =
          File('lib/ai/commander_reference_helpers.dart').readAsStringSync();

      expect(route, contains('loadCardMetadataByName('));
      expect(helpers, contains('JOIN card_identity_bridge cib'));
      expect(
        helpers,
        contains('cib.normalized_lookup_name = input_names.input_name'),
      );
      expect(
        helpers,
        contains(
          "cib.normalized_canonical_name LIKE input_names.input_name || ' // %'",
        ),
      );
      expect(helpers, contains('isUndefinedIdentityBridgeError'));
      expect(helpers, contains('JOIN cards c'));
    });

    test('commander learning role summary is rederived before response', () {
      final route =
          File('routes/ai/commander-learning/index.dart').readAsStringSync();

      expect(
        route,
        contains('await canonicalizeCommanderLearnedDeckMetadataWithStatus'),
      );
      expect(route, contains('roleMetadata: roleMetadata'));
      expect(route, contains('roleSummarySource: roleMetadataResult.source'));
      expect(route, contains('_roleSummaryFromMetadata(roleMetadata)'));
      expect(route, isNot(contains('_roleSummary(learnedDeck)')));
      expect(route, isNot(contains('_roleSummary(deck)')));
    });

    test(
      'commander learning snapshot excludes partial active learned decks',
      () {
        final support =
            File(
              'lib/ai/commander_learning_snapshot_support.dart',
            ).readAsStringSync();

        expect(support, contains('WHERE is_active = TRUE'));
        expect(support, contains('AND card_count = 100'));
        expect(
          support,
          contains("AND card_list ILIKE '%' || commander_name || '%'"),
        );
      },
    );

    test(
      'learned Lorehold response normalizes to POST /decks Commander payload',
      () {
        final lands = List.generate(33, (index) => '1 Lorehold Land $index');
        final spells = List.generate(66, (index) => '1 Lorehold Spell $index');
        final learnedDeck = parseCommanderLearnedDeckInput({
          'id': 82,
          'commander': 'Lorehold, the Historian',
          'deck_name': 'Lorehold Best-of Learned No Premium Mox 2026-06-02',
          'card_list': [
            '1 Lorehold, the Historian',
            ...lands,
            ...spells,
          ].join('\n'),
          'card_count': 100,
          'legal_status': 'commander_legal',
        });
        final metadataByName = {
          for (final entry in learnedDeck.cards.indexed)
            normalizeCommanderReferenceName(entry.$2.name): {
              'id': 'card-${entry.$1}',
              'name': entry.$2.name,
              'type_line':
                  entry.$2.name.contains('Land')
                      ? 'Basic Land - Plains'
                      : 'Sorcery',
              'commander_legal_status': 'legal',
            },
        };

        final decklist = buildCommanderLearnedDeckResponseDecklist(
          learnedDeck: learnedDeck,
          metadataByName: metadataByName,
        );
        final postCards = normalizeCommanderLearnedDecklistForDeckCreate(
          decklist,
        );
        final commanderCardId =
            metadataByName[learnedDeck.commanderNameNormalized]!['id'];
        final commanderRows =
            postCards.where((card) => card['is_commander'] == true).toList();
        final commanderQuantity = commanderRows.fold<int>(
          0,
          (sum, card) => sum + (card['quantity'] as int),
        );
        final totalQuantity = postCards.fold<int>(
          0,
          (sum, card) => sum + (card['quantity'] as int),
        );
        final mainCommanderDuplicates = postCards.where(
          (card) =>
              card['is_commander'] != true &&
              card['card_id'] == commanderCardId,
        );

        expect(validateCommanderLearnedDeckInput(learnedDeck).ok, isTrue);
        expect(decklist, hasLength(100));
        expect(postCards, hasLength(100));
        expect(totalQuantity, equals(100));
        expect(commanderRows, hasLength(1));
        expect(commanderQuantity, equals(1));
        expect(mainCommanderDuplicates, isEmpty);
        expect(
          postCards.every(
            (card) =>
                card['card_id'] is String &&
                (card['card_id'] as String).isNotEmpty,
          ),
          isTrue,
        );
        expect(postCards.any((card) => card.containsKey('name')), isFalse);
      },
    );
  });
}

String _sectionBetween(String source, String startMarker, String endMarker) {
  final start = source.indexOf(startMarker);
  if (start < 0) {
    throw StateError('Missing start marker: $startMarker');
  }
  final end = source.indexOf(endMarker, start + startMarker.length);
  if (end < 0) {
    throw StateError('Missing end marker: $endMarker');
  }
  return source.substring(start, end);
}
