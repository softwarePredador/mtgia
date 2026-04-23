import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manaloom/core/api/api_client.dart';
import 'package:manaloom/features/auth/providers/auth_provider.dart';
import 'package:manaloom/features/cards/providers/card_provider.dart';
import 'package:manaloom/features/decks/providers/deck_provider.dart';
import 'package:manaloom/features/decks/screens/deck_details_screen.dart';
import 'package:manaloom/features/decks/widgets/deck_optimize_sheet_widgets.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeApiClient extends ApiClient {
  _FakeApiClient({
    Map<String, ApiResponse Function(Map<String, dynamic>)>? postHandlers,
    Map<String, ApiResponse Function()>? getHandlers,
    Map<String, ApiResponse Function(Map<String, dynamic>)>? putHandlers,
  }) : _postHandlers = postHandlers ?? const {},
       _getHandlers = getHandlers ?? const {},
       _putHandlers = putHandlers ?? const {};

  final Map<String, ApiResponse Function(Map<String, dynamic>)> _postHandlers;
  final Map<String, ApiResponse Function()> _getHandlers;
  final Map<String, ApiResponse Function(Map<String, dynamic>)> _putHandlers;

  final List<String> postCalls = [];
  final List<Map<String, dynamic>> postBodies = [];
  final List<String> putCalls = [];
  final List<Map<String, dynamic>> putBodies = [];
  final List<String> getCalls = [];

  @override
  Future<ApiResponse> post(
    String endpoint,
    Map<String, dynamic> body, {
    Duration? timeout,
  }) async {
    postCalls.add(endpoint);
    postBodies.add(body);
    final handler = _postHandlers[endpoint];
    if (handler == null) {
      throw UnimplementedError('No POST handler for $endpoint');
    }
    return handler(body);
  }

  @override
  Future<ApiResponse> get(String endpoint) async {
    getCalls.add(endpoint);
    final handler = _getHandlers[endpoint];
    if (handler == null) {
      throw UnimplementedError('No GET handler for $endpoint');
    }
    return handler();
  }

  @override
  Future<ApiResponse> put(String endpoint, Map<String, dynamic> body) async {
    putCalls.add(endpoint);
    putBodies.add(body);
    final handler = _putHandlers[endpoint];
    if (handler == null) {
      throw UnimplementedError('No PUT handler for $endpoint');
    }
    return handler(body);
  }
}

class _IdleDeckProvider extends DeckProvider {
  _IdleDeckProvider({required ApiClient apiClient})
    : super(apiClient: apiClient);

  @override
  Future<void> fetchDeckDetails(
    String deckId, {
    bool forceRefresh = false,
  }) async {
    // Mantém a tela sem deck carregado para exercitar o estado vazio.
  }
}

class _LoadingDeckProvider extends DeckProvider {
  _LoadingDeckProvider({required ApiClient apiClient})
    : super(apiClient: apiClient);

  @override
  bool get isLoading => true;

  @override
  Future<void> fetchDeckDetails(
    String deckId, {
    bool forceRefresh = false,
  }) async {
    // Mantém a tela em loading para exercitar o estado.
  }
}

Map<String, dynamic> _buildDeckDetailsJson(
  Map<String, int> cardsById, {
  required String deckId,
  required String name,
  String archetype = 'control',
}) {
  Map<String, dynamic> card(
    String id,
    String cardName, {
    required int quantity,
    bool isCommander = false,
    List<String> colors = const <String>[],
    List<String> colorIdentity = const <String>[],
    String typeLine = 'Artifact',
    String manaCost = '{2}',
  }) => {
    'id': id,
    'name': cardName,
    'mana_cost': manaCost,
    'type_line': typeLine,
    'oracle_text': '',
    'colors': colors,
    'color_identity': colorIdentity,
    'image_url': null,
    'set_code': 'tst',
    'set_name': 'Test Set',
    'set_release_date': '2026-01-01',
    'rarity': 'rare',
    'quantity': quantity,
    'is_commander': isCommander,
    'condition': 'NM',
  };

  return {
    'id': deckId,
    'name': name,
    'format': 'commander',
    'description': 'Deck para smoke',
    'archetype': archetype,
    'is_public': false,
    'created_at': '2026-03-24T00:00:00.000Z',
    'color_identity': const ['U'],
    'stats': {
      'total_cards': cardsById.values.fold<int>(0, (sum, qty) => sum + qty),
    },
    'commander': [
      card(
        'cmd-1',
        'Talrand, Sky Summoner',
        quantity: 1,
        isCommander: true,
        colors: const ['U'],
        colorIdentity: const ['U'],
        typeLine: 'Legendary Creature — Merfolk Wizard',
        manaCost: '{2}{U}{U}',
      ),
    ],
    'main_board': {
      'Artifacts': [
        if ((cardsById['remove-1'] ?? 0) > 0)
          card('remove-1', 'Mind Stone', quantity: cardsById['remove-1']!),
        if ((cardsById['add-1'] ?? 0) > 0)
          card('add-1', 'Arcane Signet', quantity: cardsById['add-1']!),
      ],
      'Instants': [
        card(
          'spell-1',
          'Opt',
          quantity: cardsById['spell-1'] ?? 1,
          colors: const ['U'],
          colorIdentity: const ['U'],
          typeLine: 'Instant',
          manaCost: '{U}',
        ),
      ],
      'Lands': List.generate(
        cardsById['land-1'] ?? 36,
        (index) => card(
          'land-$index',
          'Island',
          quantity: 1,
          colors: const <String>[],
          colorIdentity: const <String>[],
          typeLine: 'Basic Land — Island',
          manaCost: '',
        ),
      ),
    },
  };
}

Future<void> _pumpScreen(
  WidgetTester tester, {
  required ApiClient apiClient,
  required DeckProvider provider,
}) async {
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<DeckProvider>.value(value: provider),
        ChangeNotifierProvider<CardProvider>(
          create: (_) => CardProvider(apiClient: apiClient),
        ),
        ChangeNotifierProvider<AuthProvider>(
          create: (_) => AuthProvider(apiClient: apiClient),
        ),
      ],
      child: const MaterialApp(home: DeckDetailsScreen(deckId: 'deck-1')),
    ),
  );
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('DeckDetailsScreen shows loading state while fetching details', (
    tester,
  ) async {
    final apiClient = _FakeApiClient();
    final provider = _LoadingDeckProvider(apiClient: apiClient);
    await _pumpScreen(tester, apiClient: apiClient, provider: provider);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets(
    'DeckDetailsScreen shows unauthorized state when deck fetch returns 401',
    (tester) async {
      final apiClient = _FakeApiClient(
        getHandlers: {
          '/decks/deck-1':
              () => ApiResponse(401, {
                'message': 'Sessão expirada. Faça login novamente.',
              }),
        },
      );

      final provider = DeckProvider(apiClient: apiClient);
      await _pumpScreen(tester, apiClient: apiClient, provider: provider);
      await tester.pumpAndSettle();

      expect(
        find.text('Sessão expirada. Faça login novamente.'),
        findsOneWidget,
      );
      expect(find.text('Fazer login novamente'), findsOneWidget);
    },
  );

  testWidgets(
    'DeckDetailsScreen retry action recovers from generic error state',
    (tester) async {
      var attempts = 0;
      final apiClient = _FakeApiClient(
        getHandlers: {
          '/decks/deck-1': () {
            attempts++;
            if (attempts == 1) {
              return ApiResponse(500, {'error': 'falhou'});
            }
            return ApiResponse(
              200,
              _buildDeckDetailsJson(
                {'spell-1': 1, 'land-1': 36},
                deckId: 'deck-1',
                name: 'Recovered Deck',
              ),
            );
          },
        },
      );

      final provider = DeckProvider(apiClient: apiClient);
      await _pumpScreen(tester, apiClient: apiClient, provider: provider);
      await tester.pumpAndSettle();

      expect(find.text('Tentar Novamente'), findsOneWidget);

      await tester.tap(find.text('Tentar Novamente'));
      await tester.pumpAndSettle();

      expect(find.text('Recovered Deck'), findsOneWidget);
      expect(attempts, 2);
    },
  );

  testWidgets('DeckDetailsScreen shows empty state when no deck is selected', (
    tester,
  ) async {
    final apiClient = _FakeApiClient();
    final provider = _IdleDeckProvider(apiClient: apiClient);

    await _pumpScreen(tester, apiClient: apiClient, provider: provider);
    await tester.pumpAndSettle();

    expect(find.text('Deck não encontrado'), findsOneWidget);
  });

  testWidgets(
    'DeckDetailsScreen shows calm onboarding state for a newly created empty deck',
    (tester) async {
      final apiClient = _FakeApiClient(
        getHandlers: {
          '/decks/deck-1':
              () => ApiResponse(200, {
                'id': 'deck-1',
                'name': 'Novo Deck',
                'format': 'commander',
                'description': null,
                'archetype': null,
                'is_public': false,
                'created_at': '2026-03-25T00:00:00.000Z',
                'color_identity': const <String>[],
                'stats': const {'total_cards': 0},
                'commander': const <Map<String, dynamic>>[],
                'main_board': const <String, dynamic>{},
              }),
        },
      );

      final provider = DeckProvider(apiClient: apiClient);
      await _pumpScreen(tester, apiClient: apiClient, provider: provider);
      await tester.pumpAndSettle();

      expect(find.text('Novo Deck'), findsOneWidget);
      expect(find.text('Deck pronto para começar'), findsOneWidget);
      expect(find.text('Selecionar comandante'), findsOneWidget);
      expect(find.text('Buscar cartas'), findsOneWidget);
      expect(find.text('Colar lista'), findsOneWidget);
      expect(find.text('Inválido'), findsNothing);
      expect(find.text('Estratégia'), findsNothing);
      expect(apiClient.postCalls, isEmpty);
    },
  );

  testWidgets('DeckDetailsScreen shows commander section in Cartas tab', (
    tester,
  ) async {
    final apiClient = _FakeApiClient(
      getHandlers: {
        '/decks/deck-1':
            () => ApiResponse(
              200,
              _buildDeckDetailsJson(
                {'remove-1': 1, 'spell-1': 1, 'land-1': 36},
                deckId: 'deck-1',
                name: 'Talrand Tempo',
              ),
            ),
      },
    );

    final provider = DeckProvider(apiClient: apiClient);
    await _pumpScreen(tester, apiClient: apiClient, provider: provider);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Cartas'));
    await tester.pumpAndSettle();

    expect(find.text('Comandante'), findsOneWidget);
    expect(find.byIcon(Icons.workspace_premium_rounded), findsOneWidget);
    expect(
      find.text('Carta que define identidade e regras do deck.'),
      findsNothing,
    );
    expect(find.text('Deck principal'), findsNothing);
    expect(find.text('Talrand, Sky Summoner'), findsOneWidget);
  });

  testWidgets(
    'DeckDetailsScreen smoke: optimize -> preview -> apply -> validate',
    (tester) async {
      final cardsById = <String, int>{
        'remove-1': 1,
        'spell-1': 1,
        'land-1': 36,
      };

      final apiClient = _FakeApiClient(
        getHandlers: {
          '/decks/deck-1':
              () => ApiResponse(
                200,
                _buildDeckDetailsJson(
                  cardsById,
                  deckId: 'deck-1',
                  name: 'Smoke Deck',
                ),
              ),
          '/cards?name=Arcane+Signet&limit=1':
              () => ApiResponse(200, {
                'data': const [
                  {
                    'id': 'add-1',
                    'name': 'Arcane Signet',
                    'type_line': 'Artifact',
                    'color_identity': <String>[],
                  },
                ],
              }),
        },
        postHandlers: {
          '/decks/deck-1/pricing':
              (_) => ApiResponse(200, {
                'currency': 'USD',
                'estimated_total_usd': 120.0,
                'missing_price_cards': 0,
                'items': const [],
              }),
          '/decks/deck-1/validate': (_) => ApiResponse(200, {'ok': true}),
          '/ai/archetypes':
              (_) => ApiResponse(200, {
                'options': const [
                  {
                    'title': 'control',
                    'description': 'Controle e valor.',
                    'difficulty': 'mid',
                  },
                ],
              }),
          '/ai/optimize':
              (_) => ApiResponse(200, {
                'mode': 'optimize',
                'removals': const ['Mind Stone'],
                'additions': const ['Arcane Signet'],
                'removals_detailed': const [
                  {
                    'card_id': 'remove-1',
                    'name': 'Mind Stone',
                    'type_line': 'Artifact',
                    'color_identity': <String>[],
                  },
                ],
                'additions_detailed': const [
                  {
                    'card_id': 'add-1',
                    'name': 'Arcane Signet',
                    'type_line': 'Artifact',
                    'color_identity': <String>[],
                  },
                ],
                'reasoning': 'Mais aceleração e menos peça lenta.',
                'constraints': {'keep_theme': true},
                'theme_info': {'theme': 'spellslinger'},
                'warnings': const <String, dynamic>{},
                'deck_analysis': {
                  'average_cmc': 3.1,
                  'mana_curve_assessment': 'ok',
                },
                'post_analysis': {
                  'average_cmc': 2.9,
                  'improvements': const ['Mais ramp'],
                },
              }),
        },
        putHandlers: {
          '/decks/deck-1': (body) {
            final cards = (body['cards'] as List).cast<Map<String, dynamic>>();
            cardsById
              ..clear()
              ..addEntries(
                cards.map(
                  (item) => MapEntry(
                    item['card_id'].toString(),
                    item['quantity'] as int? ?? 1,
                  ),
                ),
              );
            return ApiResponse(200, {'ok': true});
          },
        },
      );

      final provider = DeckProvider(
        apiClient: apiClient,
        trackActivationEvent:
            (
              String eventName, {
              String? format,
              String? deckId,
              String source = 'app',
              Map<String, dynamic>? metadata,
            }) async {},
      );

      await _pumpScreen(tester, apiClient: apiClient, provider: provider);
      await tester.pumpAndSettle();

      expect(find.text('Smoke Deck'), findsOneWidget);

      await tester.tap(find.byTooltip('Otimizar deck'));
      await tester.pumpAndSettle();

      expect(find.text('Otimizar Deck'), findsOneWidget);
      final optimizeScrollable = find.byType(Scrollable).last;
      await tester.scrollUntilVisible(
        find.text('Ver sugestões'),
        200,
        scrollable: optimizeScrollable,
      );
      final optimizeStrategyCard = find.byType(StrategyOptionCard).first;
      await tester.tap(optimizeStrategyCard);
      await tester.pumpAndSettle();

      expect(find.text('Sugestões para control'), findsOneWidget);
      expect(find.text('Aplicar mudanças'), findsOneWidget);

      await tester.tap(find.text('Aplicar mudanças'));
      await tester.pumpAndSettle();

      expect(find.text('Sugestões para control'), findsNothing);
      expect(apiClient.putCalls, contains('/decks/deck-1'));
      expect(
        apiClient.postCalls.where((call) => call == '/decks/deck-1/validate'),
        isNotEmpty,
      );
    },
  );

  testWidgets(
    'DeckDetailsScreen smoke: needs_repair -> rebuild_guided -> abre draft',
    (tester) async {
      final apiClient = _FakeApiClient(
        getHandlers: {
          '/decks/deck-1':
              () => ApiResponse(
                200,
                _buildDeckDetailsJson(
                  {'remove-1': 1, 'spell-1': 1, 'land-1': 36},
                  deckId: 'deck-1',
                  name: 'Broken Deck',
                ),
              ),
          '/decks/draft-1':
              () => ApiResponse(
                200,
                _buildDeckDetailsJson(
                  {'add-1': 1, 'spell-1': 1, 'land-1': 37},
                  deckId: 'draft-1',
                  name: 'Draft Deck',
                ),
              ),
        },
        postHandlers: {
          '/decks/deck-1/pricing':
              (_) => ApiResponse(200, {
                'currency': 'USD',
                'estimated_total_usd': 80.0,
                'missing_price_cards': 0,
                'items': const [],
              }),
          '/decks/deck-1/validate': (_) => ApiResponse(200, {'ok': true}),
          '/decks/draft-1/pricing':
              (_) => ApiResponse(200, {
                'currency': 'USD',
                'estimated_total_usd': 90.0,
                'missing_price_cards': 0,
                'items': const [],
              }),
          '/decks/draft-1/validate': (_) => ApiResponse(200, {'ok': true}),
          '/ai/archetypes':
              (_) => ApiResponse(200, {
                'options': const [
                  {
                    'title': 'control',
                    'description': 'Controle e valor.',
                    'difficulty': 'mid',
                  },
                ],
              }),
          '/ai/optimize':
              (_) => ApiResponse(422, {
                'error': 'O deck precisa de reparo estrutural.',
                'outcome_code': 'needs_repair',
                'quality_error': {
                  'code': 'OPTIMIZE_NEEDS_REPAIR',
                  'message': 'O deck atual está fora da faixa de optimize.',
                  'reasons': ['Poucas mágicas relevantes para o comandante.'],
                },
                'next_action': {
                  'type': 'rebuild_guided',
                  'endpoint': '/ai/rebuild',
                  'payload': {
                    'deck_id': 'deck-1',
                    'rebuild_scope': 'auto',
                    'save_mode': 'draft_clone',
                  },
                },
              }),
          '/ai/rebuild':
              (_) => ApiResponse(200, {
                'mode': 'rebuild_guided',
                'outcome_code': 'rebuild_created',
                'draft_deck_id': 'draft-1',
                'rebuild_scope_selected': 'full_non_commander_rebuild',
              }),
        },
      );

      final provider = DeckProvider(
        apiClient: apiClient,
        trackActivationEvent:
            (
              String eventName, {
              String? format,
              String? deckId,
              String source = 'app',
              Map<String, dynamic>? metadata,
            }) async {},
      );

      await _pumpScreen(tester, apiClient: apiClient, provider: provider);
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Otimizar deck'));
      await tester.pumpAndSettle();
      final rebuildScrollable = find.byType(Scrollable).last;
      await tester.scrollUntilVisible(
        find.text('Ver sugestões'),
        200,
        scrollable: rebuildScrollable,
      );
      final rebuildStrategyCard = find.byType(StrategyOptionCard).first;
      await tester.tap(rebuildStrategyCard);
      await tester.pumpAndSettle();

      expect(find.text('Draft Deck'), findsOneWidget);
      expect(apiClient.postCalls, contains('/ai/rebuild'));
      expect(apiClient.getCalls, contains('/decks/draft-1'));
    },
  );
}
