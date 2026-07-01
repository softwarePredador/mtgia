import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manaloom/core/theme/app_theme.dart';
import 'package:manaloom/features/decks/models/deck_analysis.dart';
import 'package:manaloom/features/decks/models/deck_card_item.dart';
import 'package:manaloom/features/decks/models/deck_details.dart';
import 'package:manaloom/features/decks/widgets/deck_diagnostic_panel.dart';

void main() {
  DeckCardItem card({
    required String id,
    required String name,
    required String typeLine,
    String? manaCost,
    String? oracleText,
    int quantity = 1,
    bool isCommander = false,
  }) {
    return DeckCardItem(
      id: id,
      name: name,
      typeLine: typeLine,
      manaCost: manaCost,
      oracleText: oracleText,
      setCode: 'TST',
      rarity: 'common',
      quantity: quantity,
      isCommander: isCommander,
    );
  }

  DeckDetails makeHealthyCommanderDeck() {
    return DeckDetails(
      id: 'deck-healthy',
      name: 'Talrand Tempo',
      format: 'commander',
      commanderName: 'Talrand, Sky Summoner',
      isPublic: false,
      createdAt: DateTime(2026, 3, 18),
      cardCount: 100,
      stats: const {},
      commander: [
        card(
          id: 'cmdr',
          name: 'Talrand, Sky Summoner',
          typeLine: 'Legendary Creature — Merfolk Wizard',
          manaCost: '{2}{U}{U}',
          quantity: 1,
          isCommander: true,
        ),
      ],
      mainBoard: {
        'Mainboard': [
          card(
            id: 'land',
            name: 'Island',
            typeLine: 'Basic Land — Island',
            quantity: 36,
          ),
          card(
            id: 'ramp',
            name: 'Arcane Signet',
            typeLine: 'Artifact',
            manaCost: '{2}',
            oracleText: '{T}: Add one mana of any color.',
            quantity: 9,
          ),
          card(
            id: 'draw',
            name: 'Chart a Course',
            typeLine: 'Sorcery',
            manaCost: '{1}{U}',
            oracleText:
                'Draw two cards. Then discard a card unless you attacked this turn.',
            quantity: 8,
          ),
          card(
            id: 'interaction',
            name: 'Counterspell',
            typeLine: 'Instant',
            manaCost: '{U}{U}',
            oracleText: 'Counter target spell.',
            quantity: 10,
          ),
          card(
            id: 'wipe',
            name: 'Aetherize',
            typeLine: 'Instant',
            manaCost: '{3}{U}',
            oracleText:
                'Return all attacking creatures to their owner\'s hand.',
            quantity: 2,
          ),
          card(
            id: 'filler',
            name: 'Pteramander',
            typeLine: 'Creature — Salamander Drake',
            manaCost: '{U}',
            oracleText: 'Flying',
            quantity: 34,
          ),
        ],
      },
    );
  }

  DeckDetails makeUnhealthyCommanderDeck() {
    return DeckDetails(
      id: 'deck-unhealthy',
      name: 'Greedy Battlecruiser',
      format: 'commander',
      commanderName: 'The Ur-Dragon',
      isPublic: false,
      createdAt: DateTime(2026, 3, 18),
      cardCount: 100,
      stats: const {},
      commander: [
        card(
          id: 'cmdr2',
          name: 'The Ur-Dragon',
          typeLine: 'Legendary Creature — Dragon Avatar',
          manaCost: '{4}{W}{U}{B}{R}{G}',
          quantity: 1,
          isCommander: true,
        ),
      ],
      mainBoard: {
        'Mainboard': [
          card(
            id: 'land2',
            name: 'Forest',
            typeLine: 'Basic Land — Forest',
            quantity: 28,
          ),
          card(
            id: 'ramp2',
            name: 'Rampant Growth',
            typeLine: 'Sorcery',
            manaCost: '{1}{G}',
            oracleText:
                'Search your library for a basic land card, put that card onto the battlefield tapped, then shuffle.',
            quantity: 2,
          ),
          card(
            id: 'draw2',
            name: 'Divination',
            typeLine: 'Sorcery',
            manaCost: '{2}{U}',
            oracleText: 'Draw two cards.',
            quantity: 2,
          ),
          card(
            id: 'interaction2',
            name: 'Murder',
            typeLine: 'Instant',
            manaCost: '{1}{B}{B}',
            oracleText: 'Destroy target creature.',
            quantity: 3,
          ),
          card(
            id: 'threat',
            name: 'Ancient Silver Dragon',
            typeLine: 'Creature — Elder Dragon',
            manaCost: '{6}{U}{U}',
            oracleText: 'Flying',
            quantity: 64,
          ),
        ],
      },
    );
  }

  DeckDetails makeCardAdvantageCommanderDeck() {
    return DeckDetails(
      id: 'deck-card-advantage',
      name: 'Boros Value',
      format: 'commander',
      commanderName: 'Lorehold, the Historian',
      isPublic: false,
      createdAt: DateTime(2026, 5, 15),
      cardCount: 100,
      stats: const {},
      commander: [
        card(
          id: 'cmdr3',
          name: 'Lorehold, the Historian',
          typeLine: 'Legendary Creature — Human Cleric',
          manaCost: '{R}{W}',
          quantity: 1,
          isCommander: true,
        ),
      ],
      mainBoard: {
        'Mainboard': [
          card(
            id: 'land3',
            name: 'Mountain',
            typeLine: 'Basic Land — Mountain',
            quantity: 35,
          ),
          card(
            id: 'draw-a-card',
            name: 'Esper Sentinel',
            typeLine: 'Artifact Creature — Human Soldier',
            manaCost: '{W}',
            oracleText:
                'Whenever an opponent casts their first noncreature spell each turn, draw a card unless that player pays {X}.',
          ),
          card(
            id: 'impulse',
            name: 'Reckless Impulse',
            typeLine: 'Sorcery',
            manaCost: '{1}{R}',
            oracleText:
                'Exile the top two cards of your library. Until the end of your next turn, you may play those cards.',
          ),
          card(
            id: 'look-hand',
            name: 'Thrill of Possibility',
            typeLine: 'Instant',
            manaCost: '{1}{R}',
            oracleText:
                'As an additional cost to cast this spell, discard a card. Draw two cards.',
          ),
          card(
            id: 'tutor',
            name: 'Enlightened Tutor',
            typeLine: 'Instant',
            manaCost: '{W}',
            oracleText:
                'Search your library for an artifact or enchantment card, reveal it, then shuffle and put that card on top.',
          ),
          card(
            id: 'filler3',
            name: 'Boros Recruit',
            typeLine: 'Creature — Goblin Soldier',
            manaCost: '{R/W}',
            oracleText: 'First strike.',
            quantity: 60,
          ),
        ],
      },
    );
  }

  DeckDetails makeLoreholdThirtyThreeLandDeck() {
    return DeckDetails(
      id: 'deck-lorehold-33',
      name: 'Lorehold Learned Control',
      format: 'commander',
      commanderName: 'Lorehold, the Historian',
      isPublic: false,
      createdAt: DateTime(2026, 6, 19),
      cardCount: 100,
      stats: const {},
      commander: [
        card(
          id: 'cmdr-lorehold',
          name: 'Lorehold, the Historian',
          typeLine: 'Legendary Creature — Human Cleric',
          manaCost: '{R}{W}',
          quantity: 1,
          isCommander: true,
        ),
      ],
      mainBoard: {
        'Mainboard': [
          card(
            id: 'lorehold-land',
            name: 'Sacred Foundry',
            typeLine: 'Land — Mountain Plains',
            quantity: 33,
          ),
          card(
            id: 'lorehold-ramp',
            name: 'Arcane Signet',
            typeLine: 'Artifact',
            manaCost: '{2}',
            oracleText: '{T}: Add one mana of any color.',
            quantity: 8,
          ),
          card(
            id: 'lorehold-draw',
            name: 'Reckless Impulse',
            typeLine: 'Sorcery',
            manaCost: '{1}{R}',
            oracleText:
                'Exile the top two cards of your library. Until the end of your next turn, you may play those cards.',
            quantity: 8,
          ),
          card(
            id: 'lorehold-interaction',
            name: 'Swords to Plowshares',
            typeLine: 'Instant',
            manaCost: '{W}',
            oracleText: 'Exile target creature.',
            quantity: 8,
          ),
          card(
            id: 'lorehold-wipe',
            name: 'Wrath of God',
            typeLine: 'Sorcery',
            manaCost: '{2}{W}{W}',
            oracleText: "Destroy all creatures. They can't be regenerated.",
            quantity: 2,
          ),
          card(
            id: 'lorehold-filler',
            name: 'Lorehold Apprentice',
            typeLine: 'Creature — Human Cleric',
            manaCost: '{1}{R}{W}',
            oracleText: 'Magecraft — Create a 3/2 Spirit creature token.',
            quantity: 40,
          ),
        ],
      },
    );
  }

  Widget createSubject(
    DeckDetails deck, {
    double width = 400,
    DeckAnalysisData? analysis,
  }) {
    return MaterialApp(
      theme: AppTheme.darkTheme,
      home: Scaffold(
        body: SizedBox(
          width: width,
          child: SingleChildScrollView(
            child: DeckDiagnosticPanel(
              deck: deck,
              analysis: analysis,
              onOpenAnalysis: () {},
            ),
          ),
        ),
      ),
    );
  }

  group('DeckDiagnosticPanel', () {
    testWidgets('shows core metrics and quick insights for a healthy deck', (
      tester,
    ) async {
      await tester.pumpWidget(createSubject(makeHealthyCommanderDeck()));
      await tester.pumpAndSettle();

      expect(find.text('Leitura rápida do deck'), findsOneWidget);
      expect(find.text('Indicadores principais'), findsOneWidget);
      expect(find.text('Terrenos'), findsOneWidget);
      expect(find.text('Ramp'), findsOneWidget);
      expect(find.text('Compra'), findsOneWidget);
      expect(find.text('Interação'), findsOneWidget);
      expect(find.text('CMC médio'), findsOneWidget);
      expect(find.text('O que entrou na conta'), findsOneWidget);
      expect(find.text('Compra (8)'), findsOneWidget);
      expect(find.text('Chart a Course x8'), findsOneWidget);
      expect(
        find.text('Base de mana na faixa esperada para o formato.'),
        findsOneWidget,
      );
      expect(
        find.text(
          'Boa densidade de interação para segurar o ritmo da partida.',
        ),
        findsOneWidget,
      );
      expect(find.text('Análise completa'), findsOneWidget);
    });

    testWidgets('renders backend launch readiness signals when available', (
      tester,
    ) async {
      final deck = makeHealthyCommanderDeck();
      final analysis = DeckAnalysisData.fromJson({
        'deck_id': deck.id,
        'format': 'commander',
        'stats': {
          'composition': {
            'ramp': 10,
            'draw': 10,
            'removal': 9,
            'board_wipes': 2,
          },
        },
        'readiness': {
          'schema_version': 'deck_readiness_v1_2026-07-01',
          'status': 'valid_commander_deck',
          'is_commander': true,
          'commander_count': 1,
          'total_cards': 100,
          'error_count': 0,
          'warning_count': 0,
          'blockers': [],
          'next_actions': [],
          'advanced_intelligence_enabled': true,
        },
        'battle_readiness': {
          'schema_version': 'deck_battle_readiness_v1_2026-07-01',
          'status': 'partial_simulation',
          'total_copies': 100,
          'verified_simulation_copies': 72,
          'partial_simulation_copies': 8,
          'pending_adapter_copies': 20,
          'rules_text_only_copies': 0,
          'verified_ratio': 0.72,
          'samples': {
            'verified_simulation': ['Counterspell'],
            'pending_adapter': ['Pteramander'],
          },
        },
        'card_battle_readiness': [
          {
            'schema_version': 'card_battle_readiness_v1_2026-07-01',
            'card_id': 'cmdr',
            'name': 'Talrand, Sky Summoner',
            'quantity': 1,
            'is_commander': true,
            'status': 'verified_simulation',
            'status_label': 'Simulação verificada',
            'battle_rule_count': 2,
            'verified_battle_rule_count': 1,
            'source_coverage': {'has_verified_battle_rules': true},
            'detail': '1 regra verificada para battle.',
          },
          {
            'schema_version': 'card_battle_readiness_v1_2026-07-01',
            'card_id': 'ptera',
            'name': 'Pteramander',
            'quantity': 34,
            'is_commander': false,
            'status': 'pending_adapter',
            'status_label': 'Adaptador pendente',
            'battle_rule_count': 0,
            'verified_battle_rule_count': 0,
            'source_coverage': {},
            'detail': 'Texto Oracle presente.',
          },
        ],
        'understanding_summary': {
          'schema_version': 'deck_understanding_summary_v1_2026-07-01',
          'source': 'card_intelligence_snapshot',
          'total_copies': 100,
          'functional_tagged_copies': 82,
          'semantic_tagged_copies': 77,
          'verified_battle_rule_copies': 72,
          'functional_coverage_ratio': 0.82,
          'verified_battle_ratio': 0.72,
        },
        'commander_contract': {
          'schema_version': 'commander_contract_summary_v1_2026-07-01',
          'source_version': 'commander_deckbuilding_contract_v2_2026-06-29',
          'status': 'ready_for_battle_gate',
          'status_label': 'Pronto para battle gate',
          'is_commander_applicable': true,
          'commander_name': 'Talrand, Sky Summoner',
          'total_cards': 100,
          'commander_count': 1,
          'summary':
              'Estrutura e fontes suficientes; falta validar em battle gate igualado.',
          'battle_gate': {
            'required': true,
            'status': 'pending',
            'label': 'Pendente',
          },
          'gates': {
            'commander_present': true,
            'validation_valid': true,
            'unresolved_cards_zero': true,
            'has_reference_lane': true,
            'deterministic_reference_ready': true,
          },
          'source_lanes': [
            {
              'key': 'reference_card_stats',
              'label': 'Estatísticas de cartas',
              'available': true,
              'count': 18,
            },
          ],
          'planning_flow': [
            {
              'key': 'commander_intent_and_archetype',
              'label': 'Plano do comandante',
            },
          ],
          'overview_fields': [
            {'key': 'commander_plan_sentence', 'label': 'Frase do plano'},
          ],
          'blockers': [],
          'warnings': [],
          'next_actions': ['Rodar battle gate igualado.'],
        },
      });

      await tester.pumpWidget(createSubject(deck, analysis: analysis));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('deck-launch-readiness-card')),
        findsOneWidget,
      );
      expect(find.byKey(const Key('deck-launch-battle-card')), findsOneWidget);
      expect(
        find.byKey(const Key('deck-launch-understanding-card')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('deck-launch-commander-contract-card')),
        findsOneWidget,
      );
      expect(find.text('Prontidão'), findsOneWidget);
      expect(find.text('Commander válido'), findsOneWidget);
      expect(find.text('Inteligência avançada liberada.'), findsOneWidget);
      expect(find.text('Simulação parcial'), findsOneWidget);
      expect(find.text('72/100 cópias verificadas'), findsOneWidget);
      expect(find.text('82% classificado'), findsOneWidget);
      expect(find.text('Plano Commander'), findsOneWidget);
      expect(find.text('Pronto para battle gate'), findsOneWidget);
      expect(find.text('Battle gate: Pendente'), findsOneWidget);
      expect(
        find.byKey(const Key('deck-card-battle-readiness-badges')),
        findsOneWidget,
      );
      expect(find.text('Battle por carta'), findsOneWidget);
      expect(
        find.byKey(
          const Key('deck-card-battle-readiness-Talrand, Sky Summoner'),
        ),
        findsOneWidget,
      );
      expect(find.text('Simulação verificada'), findsOneWidget);
      expect(find.text('Adaptador pendente'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('avoids overflow and surfaces warnings for a greedy deck', (
      tester,
    ) async {
      await tester.pumpWidget(
        createSubject(makeUnhealthyCommanderDeck(), width: 280),
      );
      await tester.pumpAndSettle();

      expect(find.text('Ramp curto'), findsOneWidget);
      expect(find.text('Compra curta'), findsOneWidget);
      expect(
        find.text('Base de mana curta para o tamanho atual da lista.'),
        findsOneWidget,
      );
      expect(
        find.text(
          'Interação curta; a lista pode sofrer para responder à mesa.',
        ),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets(
      'explains card advantage count without treating tutors as draw',
      (tester) async {
        await tester.pumpWidget(
          createSubject(makeCardAdvantageCommanderDeck()),
        );
        await tester.pumpAndSettle();

        expect(find.text('Compra (3)'), findsOneWidget);
        expect(
          find.text(
            'Esper Sentinel • Reckless Impulse • Thrill of Possibility',
          ),
          findsOneWidget,
        );
        expect(find.textContaining('Enlightened Tutor'), findsNothing);
      },
    );

    testWidgets(
      'treats 33 Commander lands as in range for Lorehold-style deck',
      (tester) async {
        await tester.pumpWidget(
          createSubject(makeLoreholdThirtyThreeLandDeck()),
        );
        await tester.pumpAndSettle();

        expect(find.text('Alvo 33-38'), findsOneWidget);
        expect(find.text('Na faixa'), findsOneWidget);
        expect(
          find.text('Base de mana curta para o tamanho atual da lista.'),
          findsNothing,
        );
        expect(
          find.text('Base de mana na faixa esperada para o formato.'),
          findsOneWidget,
        );
      },
    );

    testWidgets('prefers backend functional tags over local oracle heuristics', (
      tester,
    ) async {
      final deck = DeckDetails(
        id: 'deck-lorehold-backend-tags',
        name: 'Lorehold Backend Tags',
        format: 'commander',
        commanderName: 'Lorehold, the Historian',
        isPublic: false,
        createdAt: DateTime(2026, 6, 19),
        cardCount: 100,
        stats: const {},
        commander: [
          card(
            id: 'cmdr-backend',
            name: 'Lorehold, the Historian',
            typeLine: 'Legendary Creature — Human Cleric',
            manaCost: '{R}{W}',
            quantity: 1,
            isCommander: true,
          ),
        ],
        mainBoard: {
          'Mainboard': [
            card(
              id: 'land-backend',
              name: 'Sacred Foundry',
              typeLine: 'Land — Mountain Plains',
              quantity: 33,
            ),
            card(
              id: 'ruby-medallion',
              name: 'Ruby Medallion',
              typeLine: 'Artifact',
              manaCost: '{2}',
              oracleText: 'Red spells you cast cost {1} less to cast.',
            ),
            card(
              id: 'scroll-rack',
              name: 'Scroll Rack',
              typeLine: 'Artifact',
              manaCost: '{2}',
              oracleText:
                  '{1}, {T}: Exile any number of cards from your hand face down. Put that many cards from the top of your library into your hand.',
            ),
            card(
              id: 'chaos-warp',
              name: 'Chaos Warp',
              typeLine: 'Instant',
              manaCost: '{2}{R}',
              oracleText:
                  'The owner of target permanent shuffles it into their library.',
            ),
            card(
              id: 'filler-backend',
              name: 'Lorehold Apprentice',
              typeLine: 'Creature — Human Cleric',
              manaCost: '{1}{R}{W}',
              oracleText: 'Magecraft — Create a 3/2 Spirit creature token.',
              quantity: 64,
            ),
          ],
        },
      );
      final analysis = DeckAnalysisData.fromJson({
        'deck_id': deck.id,
        'format': 'commander',
        'stats': {
          'composition': {
            'ramp': 0,
            'draw': 0,
            'removal': 0,
            'board_wipes': 0,
            'protection': 0,
          },
        },
        'functional_tags': {
          'schema_version': 'functional_card_tags_v1_2026_05_18',
          'semantic_schema_version': 'semantic_layer_v2_2026_05_18',
          'source': {
            'priority': 'persisted_then_heuristic',
            'persisted_rows': 3,
            'persisted_copies': 3,
            'heuristic_rows': 0,
            'heuristic_copies': 0,
          },
          'counts': {'ramp': 1, 'draw': 1, 'removal': 1},
          'sample_details': {
            'ramp': [
              {'name': 'Ruby Medallion', 'evidence': 'persisted_semantic_v2'},
            ],
            'draw': [
              {'name': 'Scroll Rack', 'evidence': 'persisted_semantic_v2'},
            ],
            'removal': [
              {'name': 'Chaos Warp', 'evidence': 'persisted_semantic_v2'},
            ],
          },
          'coverage': {
            'card_rows': 5,
            'card_copies': 100,
            'tagged_rows': 3,
            'tagged_copies': 3,
            'other_rows': 2,
            'other_copies': 97,
          },
        },
      });

      await tester.pumpWidget(createSubject(deck, analysis: analysis));
      await tester.pumpAndSettle();

      expect(find.text('Ramp (1)'), findsOneWidget);
      expect(find.text('Compra (1)'), findsOneWidget);
      expect(find.text('Interação (1)'), findsOneWidget);
      expect(find.text('Ruby Medallion'), findsOneWidget);
      expect(find.text('Scroll Rack'), findsOneWidget);
      expect(find.text('Chaos Warp'), findsOneWidget);
    });
  });
}
