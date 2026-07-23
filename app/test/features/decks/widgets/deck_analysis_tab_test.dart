import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manaloom/core/api/api_client.dart';
import 'package:manaloom/core/theme/app_theme.dart';
import 'package:manaloom/core/widgets/cached_card_image.dart';
import 'package:manaloom/features/decks/models/deck_card_item.dart';
import 'package:manaloom/features/decks/models/deck_details.dart';
import 'package:manaloom/features/decks/providers/deck_provider.dart';
import 'package:manaloom/features/decks/widgets/deck_analysis_tab.dart';
import 'package:provider/provider.dart';

import '../../../support/list_tile_material_test_support.dart';

class _FakeApiClient extends ApiClient {
  _FakeApiClient(
    this.analysisPayload, {
    Map<String, dynamic>? aiAnalysisPayload,
  }) : aiAnalysisPayload =
           aiAnalysisPayload ??
           {
             'deck_id': 'deck',
             'synergy_score': 70,
             'strengths': 'Leitura gerada em teste.',
             'weaknesses': 'Sem pontos críticos no teste.',
           };

  final Map<String, dynamic> analysisPayload;
  final Map<String, dynamic> aiAnalysisPayload;
  final List<_RecordedPost> postRequests = [];

  @override
  Future<ApiResponse> get(String endpoint) async {
    if (endpoint.endsWith('/analysis')) {
      return ApiResponse(200, analysisPayload);
    }
    throw UnimplementedError('No GET handler for $endpoint');
  }

  @override
  Future<ApiResponse> post(
    String endpoint,
    Map<String, dynamic> body, {
    Duration? timeout,
  }) async {
    if (endpoint.endsWith('/ai-analysis')) {
      postRequests.add(
        _RecordedPost(endpoint, Map<String, dynamic>.from(body)),
      );
      return ApiResponse(200, aiAnalysisPayload);
    }
    throw UnimplementedError('No POST handler for $endpoint');
  }
}

class _RecordedPost {
  const _RecordedPost(this.endpoint, this.body);

  final String endpoint;
  final Map<String, dynamic> body;
}

DeckDetails _makeDeck({
  required String id,
  required String name,
  int? synergyScore,
  String? strengths,
  String? weaknesses,
  int cardCount = 100,
  double? pricingTotal,
  String? pricingCurrency,
  int? pricingMissingCards,
  Map<String, dynamic> stats = const {},
}) {
  return DeckDetails(
    id: id,
    name: name,
    format: 'commander',
    description: 'Deck de teste',
    archetype: 'tempo',
    bracket: 2,
    colorIdentity: const ['U'],
    isPublic: false,
    createdAt: DateTime(2026, 3, 25),
    cardCount: cardCount,
    synergyScore: synergyScore,
    strengths: strengths,
    weaknesses: weaknesses,
    pricingTotal: pricingTotal,
    pricingCurrency: pricingCurrency,
    pricingMissingCards: pricingMissingCards,
    stats: stats,
    commander: [
      DeckCardItem(
        id: 'cmd-1',
        name: 'Talrand, Sky Summoner',
        manaCost: '{2}{U}{U}',
        typeLine: 'Legendary Creature — Merfolk Wizard',
        oracleText: '',
        colors: ['U'],
        colorIdentity: ['U'],
        imageUrl: null,
        setCode: 'm13',
        setName: 'Magic 2013',
        rarity: 'rare',
        quantity: 1,
        isCommander: true,
      ),
    ],
    mainBoard: {
      'Instants': [
        DeckCardItem(
          id: 'spell-1',
          name: 'Opt',
          manaCost: '{U}',
          typeLine: 'Instant',
          oracleText: '',
          colors: ['U'],
          colorIdentity: ['U'],
          imageUrl: null,
          setCode: 'dom',
          setName: 'Dominaria',
          rarity: 'common',
          quantity: 4,
          isCommander: false,
        ),
      ],
      'Artifacts': [
        DeckCardItem(
          id: 'artifact-1',
          name: 'Mind Stone',
          manaCost: '{2}',
          typeLine: 'Artifact',
          oracleText: '',
          colors: [],
          colorIdentity: [],
          imageUrl: null,
          setCode: 'war',
          setName: 'War of the Spark',
          rarity: 'uncommon',
          quantity: 2,
          isCommander: false,
        ),
      ],
    },
  );
}

Widget _subject(
  DeckDetails deck, {
  Map<String, dynamic>? analysisPayload,
  _FakeApiClient? apiClient,
}) {
  return MaterialApp(
    theme: AppTheme.darkTheme.copyWith(splashFactory: InkRipple.splashFactory),
    home: ChangeNotifierProvider(
      create: (_) => DeckProvider(
        apiClient:
            apiClient ??
            _FakeApiClient(
              analysisPayload ??
                  {
                    'deck_id': deck.id,
                    'stats': {
                      'composition': {
                        'ramp': 0,
                        'draw': 0,
                        'removal': 0,
                        'board_wipes': 0,
                        'protection': 0,
                      },
                    },
                  },
            ),
      ),
      child: Scaffold(
        body: SingleChildScrollView(child: DeckAnalysisTab(deck: deck)),
      ),
    ),
  );
}

void main() {
  testWidgets('renders executive AI summary when analysis exists', (
    tester,
  ) async {
    final deck = _makeDeck(
      id: 'deck-ready',
      name: 'Talrand Tempo',
      synergyScore: 82,
      strengths:
          'Boa densidade de mágicas instantâneas e geração consistente de valor.',
      weaknesses:
          'Pode sofrer se faltar ramp cedo ou se a mesa acelerar demais.',
    );

    await tester.pumpWidget(_subject(deck));
    await tester.pumpAndSettle();

    expect(find.text('Análise do deck'), findsOneWidget);
    expect(find.text('Leitura pronta'), findsOneWidget);
    expect(find.text('Atualizar análise'), findsOneWidget);
    expect(find.text('Leitura de sinergia'), findsOneWidget);
    expect(find.text('Pontos fortes'), findsOneWidget);
    expect(find.text('Pontos fracos'), findsOneWidget);
    expect(
      find.byKey(Key('deck-analysis-functional-section-${deck.id}')),
      findsOneWidget,
    );
    expect(find.text('Curva de mana'), findsOneWidget);
    expect(find.text('Distribuição de cores'), findsOneWidget);
  });

  testWidgets('renders pending state when AI summary does not exist yet', (
    tester,
  ) async {
    final deck = _makeDeck(
      id: 'deck-pending',
      name: 'Novo Talrand',
      cardCount: 30,
    );
    final apiClient = _FakeApiClient({
      'deck_id': deck.id,
      'stats': {
        'composition': {
          'ramp': 0,
          'draw': 0,
          'removal': 0,
          'board_wipes': 0,
          'protection': 0,
        },
      },
    });

    await tester.pumpWidget(_subject(deck, apiClient: apiClient));
    await tester.pumpAndSettle();

    expect(find.text('Leitura pendente'), findsOneWidget);
    expect(find.text('Gerar análise'), findsOneWidget);
    expect(find.text('Sinergia ainda não gerada'), findsOneWidget);
    expect(apiClient.postRequests, isEmpty);
  });

  testWidgets('summary metrics keep price and actions legible', (tester) async {
    final deck = _makeDeck(
      id: 'deck-priced',
      name: 'Talrand Priced',
      synergyScore: 82,
      strengths: 'Plano consistente.',
      weaknesses: 'Poucos pontos críticos.',
      pricingTotal: 1234.56,
      pricingCurrency: 'BRL',
      pricingMissingCards: 2,
    );

    await tester.pumpWidget(_subject(deck));
    await tester.pumpAndSettle();

    expect(find.text('Preço total'), findsOneWidget);
    expect(find.text('R\$ 1.234,56'), findsOneWidget);
    expect(find.text('2 sem preço'), findsOneWidget);
    expect(find.text('R\$ ...'), findsNothing);
    expect(find.text('Leitura pronta'), findsOneWidget);
    expect(find.text('Atualizar análise'), findsOneWidget);
  });

  testWidgets('generates AI summary only after an explicit player action', (
    tester,
  ) async {
    final deck = _makeDeck(
      id: 'deck-auto-ai',
      name: 'Auto Talrand',
      cardCount: 60,
    );
    final apiClient = _FakeApiClient(
      {
        'deck_id': deck.id,
        'stats': {
          'composition': {
            'ramp': 0,
            'draw': 0,
            'removal': 0,
            'board_wipes': 0,
            'protection': 0,
          },
        },
      },
      aiAnalysisPayload: {
        'deck_id': deck.id,
        'synergy_score': 76,
        'strengths': 'Plano funcional para o teste.',
        'weaknesses': 'Base ainda precisa de revisão.',
      },
    );

    await tester.pumpWidget(_subject(deck, apiClient: apiClient));
    await tester.pumpAndSettle();

    expect(apiClient.postRequests, isEmpty);
    await tester.tap(find.text('Gerar análise'));
    await tester.pumpAndSettle();

    expect(apiClient.postRequests, hasLength(1));
    expect(
      apiClient.postRequests.single.endpoint,
      '/decks/deck-auto-ai/ai-analysis',
    );
    expect(apiClient.postRequests.single.body, equals({'force': false}));
  });

  testWidgets('renders functional tag counts and expandable samples', (
    tester,
  ) async {
    final deck = _makeDeck(
      id: 'deck-functional',
      name: 'Talrand Tags',
      synergyScore: 82,
    );

    await tester.pumpWidget(
      _subject(
        deck,
        analysisPayload: {
          'deck_id': deck.id,
          'format': 'commander',
          'stats': {
            'composition': {
              'ramp': 9,
              'draw': 12,
              'removal': 8,
              'board_wipes': 2,
              'protection': 4,
            },
          },
          'functional_tags': {
            'schema_version': 'functional_card_tags_v1_2026_05_18',
            'semantic_schema_version': 'semantic_layer_v2_2026_05_18',
            'source': {
              'priority': 'persisted_then_heuristic',
              'persisted_rows': 30,
              'persisted_copies': 41,
              'heuristic_rows': 5,
              'heuristic_copies': 7,
            },
            'counts': {
              'ramp': 10,
              'draw': 12,
              'removal': 8,
              'board_wipe': 2,
              'protection': 4,
            },
            'samples': {
              'ramp': ['Sol Ring', 'Arcane Signet'],
              'draw': [
                {
                  'name': 'Skullclamp',
                  'reason': 'Conta como compra porque repõe cartas.',
                  'evidence': 'card_draw_text',
                  'confidence': 0.91,
                  'card_advantage_type': 'card_draw',
                  'mana_efficiency': 'cheap',
                },
              ],
              'removal': ['Swords to Plowshares'],
              'board_wipe': ['Wrath of God'],
              'protection': ['Ephemerate'],
            },
            'coverage': {
              'card_rows': 80,
              'card_copies': 100,
              'tagged_rows': 46,
              'tagged_copies': 63,
              'other_rows': 34,
              'other_copies': 37,
            },
          },
        },
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Funções do deck'), findsOneWidget);
    expectListTileInkIsUnobscured(tester);
    expect(
      find.byKey(
        const Key('deck-analysis-functional-bucket-deck-functional-ramp'),
      ),
      findsOneWidget,
    );
    expect(
      find.byKey(
        const Key('deck-analysis-functional-count-deck-functional-ramp'),
      ),
      findsOneWidget,
    );

    final rampBucket = find.byKey(
      const Key('deck-analysis-functional-bucket-deck-functional-ramp'),
    );
    await tester.ensureVisible(rampBucket);
    await tester.tap(rampBucket);
    await tester.pumpAndSettle();

    expect(find.text('Sol Ring'), findsOneWidget);
    expect(find.text('Arcane Signet'), findsOneWidget);
    expect(
      find.textContaining('Cartas deste grupo: mostrando 2 de 10'),
      findsOneWidget,
    );
    expect(find.textContaining('Como é contado:'), findsNothing);
    expect(find.textContaining('Origem da contagem'), findsNothing);
    expect(find.textContaining('functional_tags'), findsNothing);
    expect(find.textContaining('functional_card_tags'), findsNothing);
    expect(find.textContaining('persistidas'), findsNothing);
    expect(find.textContaining('cópias analisadas'), findsNothing);
    expect(find.textContaining('cópias classificadas'), findsNothing);
    expect(find.text('Abra um grupo para ver as cartas'), findsOneWidget);
    expect(find.textContaining('Ajuda a acelerar'), findsWidgets);

    final rampImages = tester.widgetList<CachedCardImage>(
      find.byType(CachedCardImage),
    );
    expect(
      rampImages.any(
        (image) =>
            image.imageUrl != null &&
            image.imageUrl!.startsWith('https://api.scryfall.com/'),
      ),
      isTrue,
    );

    final solRingSample = find.byKey(
      const Key('deck-analysis-functional-sample-deck-functional-ramp-0'),
    );
    await tester.ensureVisible(solRingSample);
    await tester.tap(solRingSample);
    await tester.pumpAndSettle();

    expect(find.byType(Dialog), findsOneWidget);
    expect(find.text('Sol Ring'), findsWidgets);
    await tester.tap(find.byTooltip('Fechar'));
    await tester.pumpAndSettle();

    final drawBucket = find.byKey(
      const Key('deck-analysis-functional-bucket-deck-functional-draw'),
    );
    await tester.ensureVisible(drawBucket);
    await tester.tap(drawBucket);
    await tester.pumpAndSettle();

    expect(find.text('Skullclamp'), findsWidgets);
    expect(find.textContaining('Ajuda a manter cartas'), findsWidgets);
    expect(find.textContaining('Conta como compra'), findsNothing);
    expect(find.textContaining('confiança'), findsNothing);
    expect(find.text('compra carta'), findsNothing);
    expect(find.textContaining('baixo custo'), findsNothing);
    expect(find.textContaining('Evidência:'), findsNothing);
  });

  testWidgets('renders legacy composition counts without samples', (
    tester,
  ) async {
    final deck = _makeDeck(
      id: 'deck-legacy',
      name: 'Legacy Analysis',
      synergyScore: 82,
    );

    await tester.pumpWidget(
      _subject(
        deck,
        analysisPayload: {
          'deck_id': deck.id,
          'format': 'commander',
          'stats': {
            'composition': {
              'ramp': 7,
              'draw': 9,
              'removal': 5,
              'board_wipes': 1,
              'protection': 2,
            },
          },
        },
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.text(
        'Esta leitura mostra os totais, mas ainda não trouxe a lista de cartas de cada função.',
      ),
      findsOneWidget,
    );
    final rampBucket = find.byKey(
      const Key('deck-analysis-functional-bucket-deck-legacy-ramp'),
    );
    await tester.ensureVisible(rampBucket);
    await tester.tap(rampBucket);
    await tester.pumpAndSettle();

    expect(find.textContaining('Leitura básica do deck'), findsWidgets);
    expect(find.textContaining('stats.composition'), findsNothing);
    expect(find.textContaining('backend'), findsNothing);
    expect(find.textContaining('Resposta legada'), findsNothing);
    expect(
      find.text('Ainda não há uma lista de cartas para este indicador.'),
      findsOneWidget,
    );
  });

  testWidgets(
    'renders the Commander planning contract and all flow steps for protected Lorehold',
    (tester) async {
      final deck = _makeDeck(
        id: 'deck-commander-contract',
        name: 'Lorehold Contract',
        synergyScore: 82,
      );
      final planningFlow = List.generate(
        12,
        (index) => {
          'key': 'step_$index',
          'label': index == 9
              ? 'Staples por impacto e função'
              : 'Etapa ${index + 1}',
        },
      );

      await tester.pumpWidget(
        _subject(
          deck,
          analysisPayload: {
            'deck_id': deck.id,
            'format': 'commander',
            'stats': {
              'composition': {
                'ramp': 8,
                'draw': 10,
                'removal': 8,
                'board_wipes': 3,
                'protection': 4,
              },
            },
            'commander_contract': {
              'schema_version': 'commander_contract_summary_v3_2026-07-22',
              'source_version': 'commander_deckbuilding_contract_v6_2026-07-22',
              'status': 'ready_for_battle_gate',
              'status_label': 'Pronto para Battle gate',
              'is_commander_applicable': true,
              'commander_name': 'Lorehold, the Historian',
              'total_cards': 100,
              'commander_count': 1,
              'summary': 'Estrutura validada; falta comprovação em Battle.',
              'battle_gate': {
                'required': true,
                'status': 'pending',
                'label': 'Pendente',
              },
              'baseline_policy': {
                'applies': true,
                'baseline_deck_id': '607',
                'status': 'experimental_blocked',
                'label': 'Experimental: candidato bloqueado',
                'detail': 'O deck 607 permanece como baseline protegido.',
                'candidate_decision': 'rejected_historical_paired_seed_design',
                'seed_pairing_claim': false,
                'definitive_claim_allowed': false,
                'automatic_candidate_apply_allowed': false,
                'next_gate': 'Rodar amostras independentes.',
              },
              'gates': {
                'commander_present': true,
                'validation_valid': true,
                'unresolved_cards_zero': true,
                'has_reference_lane': true,
                'deterministic_reference_ready': false,
              },
              'source_lanes': [
                {
                  'key': 'reference_profile',
                  'label': 'Perfil do comandante',
                  'available': true,
                  'count': 1,
                },
                {
                  'key': 'battle_gate',
                  'label': 'Battle gate',
                  'available': false,
                  'count': 0,
                },
              ],
              'provenance': {
                'schema_version': 'commander_public_provenance_v1_2026-07-22',
                'lanes': [
                  {
                    'key': 'verified_oracle',
                    'label': 'Oracle verificado',
                    'available': false,
                    'confidence': 'not_provided_to_contract',
                  },
                  {
                    'key': 'price',
                    'label': 'Preço',
                    'available': false,
                    'confidence': 'not_provided_to_contract',
                  },
                  {
                    'key': 'public_popularity',
                    'label': 'Popularidade pública',
                    'available': true,
                    'confidence': 'source_backed',
                  },
                  {
                    'key': 'reference_corpus',
                    'label': 'Corpus de referência',
                    'available': true,
                    'confidence': 'aggregate_only',
                  },
                  {
                    'key': 'learned_usage',
                    'label': 'Uso aprendido',
                    'available': true,
                    'confidence': 'observed_usage',
                  },
                  {
                    'key': 'ai_suggestion',
                    'label': 'Sugestão de IA',
                    'available': true,
                    'confidence': 'advisory_only',
                  },
                ],
                'internal_source_references_exposed': false,
              },
              'planning_coverage': {
                'required_count': 12,
                'ready_count': 7,
                'partial_count': 3,
                'pending_count': 2,
                'items': [
                  for (var index = 0; index < 12; index++)
                    {
                      'key': 'step_$index',
                      'label': 'Etapa ${index + 1}',
                      'status': index < 7
                          ? 'ready'
                          : index < 10
                          ? 'partial'
                          : 'pending',
                    },
                ],
              },
              'planning_flow': planningFlow,
              'overview_fields': const <Map<String, dynamic>>[],
              'blockers': const <String>[],
              'warnings': const <String>[],
              'next_actions': const [
                'Rodar Battle com exposição natural das cartas.',
              ],
            },
          },
        ),
      );
      await tester.pumpAndSettle();

      expectListTileInkIsUnobscured(tester);
      final section = find.byKey(
        const Key('deck-analysis-commander-plan-deck-commander-contract'),
      );
      await tester.ensureVisible(section);
      expect(section, findsOneWidget);
      expect(find.text('Plano Commander'), findsOneWidget);
      expect(find.text('Experimental: candidato bloqueado'), findsOneWidget);
      expect(
        find.text('O deck 607 permanece como baseline protegido.'),
        findsOneWidget,
      );
      expect(
        find.text('Baseline 607 protegido; aplicação automática bloqueada'),
        findsOneWidget,
      );
      expect(find.text('12 etapas do planejamento'), findsOneWidget);
      expect(find.text('7/12 etapas prontas'), findsOneWidget);

      await tester.tap(
        find.byKey(const Key('deck-analysis-commander-plan-flow')),
      );
      await tester.pumpAndSettle();
      expect(find.text('Staples por impacto e função'), findsOneWidget);

      await tester.tap(
        find.byKey(const Key('deck-analysis-commander-plan-flow')),
      );
      await tester.pumpAndSettle();
      final provenance = find.byKey(
        const Key('deck-analysis-commander-provenance'),
      );
      await tester.ensureVisible(provenance);
      await tester.tap(provenance);
      await tester.pumpAndSettle();
      expect(find.text('Oracle verificado'), findsOneWidget);
      expect(find.text('Não disponível'), findsWidgets);
      expect(find.text('Popularidade pública'), findsOneWidget);
      expect(find.text('Fonte verificada'), findsOneWidget);
      expect(find.text('Uso aprendido'), findsOneWidget);
      expect(find.text('Uso observado'), findsOneWidget);
      expect(find.textContaining('/private/'), findsNothing);
    },
  );
}
