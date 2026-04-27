import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:manaloom/core/api/api_client.dart';
import 'package:manaloom/features/auth/providers/auth_provider.dart';
import 'package:manaloom/features/auth/screens/login_screen.dart';
import 'package:manaloom/features/auth/screens/register_screen.dart';
import 'package:manaloom/features/cards/providers/card_provider.dart';
import 'package:manaloom/features/decks/providers/deck_provider.dart';
import 'package:manaloom/features/decks/screens/deck_details_screen.dart';
import 'package:manaloom/features/decks/screens/deck_generate_screen.dart';
import 'package:manaloom/features/decks/screens/deck_list_screen.dart';
import 'package:manaloom/features/decks/widgets/deck_optimize_sheet_widgets.dart';
import 'package:manaloom/features/messages/providers/message_provider.dart';
import 'package:manaloom/features/notifications/providers/notification_provider.dart';
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
  final List<String> getCalls = [];
  final List<String> putCalls = [];
  final List<Map<String, dynamic>> putBodies = [];

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

Map<String, dynamic> _buildDeckDetailsJson(
  Map<String, int> cardsById, {
  required String deckId,
  required String name,
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
    'description': 'Deck runtime widget flow',
    'archetype': 'control',
    'is_public': false,
    'created_at': '2026-04-27T00:00:00.000Z',
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

GoRouter _buildRouter(AuthProvider authProvider) {
  return GoRouter(
    initialLocation: '/register',
    refreshListenable: authProvider,
    redirect: (context, state) {
      final location = state.matchedLocation;
      final isAuthRoute = location == '/login' || location == '/register';
      final isProtectedRoute =
          location == '/decks' ||
          location == '/decks/generate' ||
          location.startsWith('/decks/');

      if (isProtectedRoute && !authProvider.isAuthenticated) {
        return '/register';
      }

      if (isAuthRoute && authProvider.isAuthenticated) {
        return '/decks';
      }

      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/decks',
        builder: (context, state) => const DeckListScreen(),
      ),
      GoRoute(
        path: '/decks/generate',
        builder: (context, state) => const DeckGenerateScreen(),
      ),
      GoRoute(
        path: '/decks/:id',
        builder: (context, state) {
          final deckId = state.pathParameters['id']!;
          return DeckDetailsScreen(deckId: deckId);
        },
      ),
    ],
  );
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    ApiClient.setToken(null);
  });

  testWidgets(
    'runtime widget flow: register -> generate -> save -> details -> optimize -> apply -> validate',
    (tester) async {
      var deckCreated = false;
      final currentCards = <String, int>{
        'remove-1': 1,
        'spell-1': 1,
        'land-1': 36,
      };

      final apiClient = _FakeApiClient(
        getHandlers: {
          '/decks': () {
            if (!deckCreated) {
              return ApiResponse(200, const <Map<String, dynamic>>[]);
            }

            return ApiResponse(200, [
              {
                'id': 'deck-1',
                'name': 'Runtime Talrand',
                'format': 'commander',
                'description': 'Talrand spellslinger runtime proof',
                'commander_name': 'Talrand, Sky Summoner',
                'is_public': false,
                'created_at': '2026-04-27T00:00:00.000Z',
                'card_count': 38,
                'color_identity': const <String>[],
              },
            ]);
          },
          '/decks/deck-1':
              () => ApiResponse(
                200,
                _buildDeckDetailsJson(
                  currentCards,
                  deckId: 'deck-1',
                  name: 'Runtime Talrand',
                ),
              ),
          '/cards?name=Arcane%20Signet&limit=1':
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
          '/auth/register': (body) {
            expect(body['username'], 'runtime_user');
            expect(body['email'], 'runtime.widget@example.com');
            expect(body['password'], '123456');
            return ApiResponse(201, {
              'token': 'runtime-token',
              'user': {
                'id': 'user-1',
                'username': 'runtime_user',
                'email': 'runtime.widget@example.com',
              },
            });
          },
          '/ai/generate': (body) {
            expect(body['format'], 'commander');
            expect(
              body['prompt'],
              'Talrand commander de spellslinger azul com instants baratos',
            );
            return ApiResponse(200, {
              'generated_deck': {
                'commander': {'name': 'Talrand, Sky Summoner'},
                'cards': const [
                  {'name': 'Opt', 'quantity': 1},
                  {'name': 'Mind Stone', 'quantity': 1},
                ],
              },
              'validation': const {'is_valid': true, 'errors': <String>[]},
            });
          },
          '/cards/resolve/batch': (body) {
            final names = (body['names'] as List).cast<String>();
            expect(
              names,
              equals(['Talrand, Sky Summoner', 'Opt', 'Mind Stone']),
            );
            return ApiResponse(200, {
              'data': const [
                {
                  'input_name': 'Talrand, Sky Summoner',
                  'card_id': 'cmd-1',
                  'matched_name': 'Talrand, Sky Summoner',
                },
                {
                  'input_name': 'Opt',
                  'card_id': 'spell-1',
                  'matched_name': 'Opt',
                },
                {
                  'input_name': 'Mind Stone',
                  'card_id': 'remove-1',
                  'matched_name': 'Mind Stone',
                },
              ],
              'unresolved': const <String>[],
              'ambiguous': const <Map<String, dynamic>>[],
              'total_input': 3,
              'total_resolved': 3,
            });
          },
          '/decks': (body) {
            deckCreated = true;
            expect(body['name'], 'Runtime Talrand');
            expect(body['format'], 'commander');
            expect(
              body['cards'],
              equals([
                {'card_id': 'cmd-1', 'quantity': 1, 'is_commander': true},
                {'card_id': 'spell-1', 'quantity': 1, 'is_commander': false},
                {'card_id': 'remove-1', 'quantity': 1, 'is_commander': false},
              ]),
            );
            return ApiResponse(201, {
              'id': 'deck-1',
              'name': 'Runtime Talrand',
              'format': 'commander',
              'description':
                  'Talrand commander de spellslinger azul com instants baratos',
              'commander_name': 'Talrand, Sky Summoner',
              'is_public': false,
              'created_at': '2026-04-27T00:00:00.000Z',
              'card_count': 38,
              'color_identity': const <String>[],
            });
          },
          '/decks/deck-1/pricing':
              (_) => ApiResponse(200, {
                'currency': 'USD',
                'estimated_total_usd': 120.0,
                'missing_price_cards': 0,
                'items': const [],
              }),
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
                'constraints': const {'keep_theme': true},
                'theme_info': const {'theme': 'spellslinger'},
                'warnings': const <String, dynamic>{},
                'deck_analysis': const {
                  'average_cmc': 3.1,
                  'mana_curve_assessment': 'ok',
                },
                'post_analysis': const {
                  'average_cmc': 2.9,
                  'improvements': <String>['Mais ramp'],
                },
              }),
          '/decks/deck-1/validate':
              (_) => ApiResponse(200, {
                'ok': true,
                'valid': true,
                'errors': const <String>[],
              }),
        },
        putHandlers: {
          '/decks/deck-1': (body) {
            final cards = (body['cards'] as List).cast<Map<String, dynamic>>();
            currentCards
              ..clear()
              ..addEntries(
                cards
                    .where((item) => item['is_commander'] != true)
                    .map(
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

      final authProvider = AuthProvider(apiClient: apiClient);
      final deckProvider = DeckProvider(
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
      final router = _buildRouter(authProvider);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
            ChangeNotifierProvider<DeckProvider>.value(value: deckProvider),
            ChangeNotifierProvider<CardProvider>(
              create: (_) => CardProvider(apiClient: apiClient),
            ),
            ChangeNotifierProvider<MessageProvider>(
              create: (_) => MessageProvider(),
            ),
            ChangeNotifierProvider<NotificationProvider>(
              create: (_) => NotificationProvider(),
            ),
          ],
          child: MaterialApp.router(routerConfig: router),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Criar Conta'), findsAtLeastNWidgets(1));

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Nome de Usuário'),
        'runtime_user',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Email'),
        'runtime.widget@example.com',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Senha').first,
        '123456',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Confirmar Senha'),
        '123456',
      );
      final registerSubmit = find.widgetWithText(InkWell, 'Criar Conta');
      await tester.ensureVisible(registerSubmit);
      await tester.tap(registerSubmit);
      await tester.pumpAndSettle();

      expect(find.text('Gerar com IA'), findsOneWidget);

      await tester.tap(find.widgetWithText(OutlinedButton, 'Gerar com IA'));
      await tester.pumpAndSettle();

      expect(find.text('Gerar Deck'), findsAtLeastNWidgets(1));

      await tester.enterText(
        find.byType(TextField).first,
        'Talrand commander de spellslinger azul com instants baratos',
      );
      await tester.tap(find.widgetWithText(ElevatedButton, 'Gerar Deck'));
      await tester.pumpAndSettle();

      expect(find.text('Preview do Deck'), findsOneWidget);
      expect(find.text('1x Talrand, Sky Summoner'), findsOneWidget);

      await tester.enterText(
        find.widgetWithText(TextField, 'Nome do Deck'),
        'Runtime Talrand',
      );

      final generateScrollable = find.byType(Scrollable).first;
      await tester.scrollUntilVisible(
        find.text('Salvar Deck'),
        200,
        scrollable: generateScrollable,
      );
      await tester.tap(find.widgetWithText(ElevatedButton, 'Salvar Deck'));
      await tester.pumpAndSettle();

      expect(find.text('Runtime Talrand'), findsOneWidget);
      expect(find.textContaining('Talrand, Sky Summoner'), findsOneWidget);

      await tester.tap(find.text('Runtime Talrand'));
      await tester.pumpAndSettle();

      expect(find.text('Detalhes do Deck'), findsOneWidget);
      expect(find.text('Runtime Talrand'), findsOneWidget);

      await tester.tap(find.byTooltip('Otimizar deck'));
      await tester.pumpAndSettle();

      expect(find.text('Otimizar Deck'), findsOneWidget);
      final optimizeScrollable = find.byType(Scrollable).last;
      await tester.scrollUntilVisible(
        find.text('Ver sugestões'),
        200,
        scrollable: optimizeScrollable,
      );
      await tester.tap(find.byType(StrategyOptionCard).first);
      await tester.pumpAndSettle();

      expect(find.text('Sugestões para control'), findsOneWidget);
      expect(find.text('Aplicar mudanças'), findsOneWidget);

      await tester.tap(find.text('Aplicar mudanças'));
      await tester.pumpAndSettle();

      expect(find.text('Sugestões para control'), findsNothing);
      expect(apiClient.postCalls, contains('/auth/register'));
      expect(apiClient.postCalls, contains('/ai/generate'));
      expect(apiClient.postCalls, contains('/cards/resolve/batch'));
      expect(apiClient.postCalls, contains('/ai/optimize'));
      expect(apiClient.postCalls, contains('/decks/deck-1/validate'));
      expect(apiClient.putCalls, contains('/decks/deck-1'));
      expect(currentCards.containsKey('add-1'), isTrue);
      expect(currentCards.containsKey('remove-1'), isFalse);
    },
  );
}
