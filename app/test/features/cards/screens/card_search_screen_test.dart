import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manaloom/core/api/api_client.dart';
import 'package:manaloom/core/theme/app_theme.dart';
import 'package:manaloom/features/cards/providers/card_provider.dart';
import 'package:manaloom/features/cards/screens/card_detail_screen.dart';
import 'package:manaloom/features/cards/screens/card_search_screen.dart';
import 'package:manaloom/features/decks/models/deck_card_item.dart';
import 'package:manaloom/features/decks/providers/deck_provider.dart';
import 'package:provider/provider.dart';

class _FixedCardProvider extends CardProvider {
  _FixedCardProvider(this._results, {this.errorMessageOverride});

  final List<DeckCardItem> _results;
  final String? errorMessageOverride;

  @override
  List<DeckCardItem> get searchResults => _results;

  @override
  bool get isLoading => false;

  @override
  bool get isLoadingMore => false;

  @override
  bool get hasMore => false;

  @override
  String? get errorMessage => errorMessageOverride;
}

class _FakeSetsApiClient extends ApiClient {
  final List<String> requests = [];

  @override
  Future<ApiResponse> get(String endpoint) async {
    requests.add(endpoint);

    if (endpoint.startsWith('/sets?') && endpoint.contains('q=soc')) {
      return ApiResponse(200, {
        'data': [
          {
            'code': 'SOC',
            'name': 'Secrets of Strixhaven Commander',
            'release_date': '2026-04-24',
            'type': 'commander',
            'card_count': 1,
            'status': 'new',
          },
        ],
        'page': 1,
        'limit': 50,
        'total_returned': 1,
      });
    }

    if (endpoint.startsWith('/sets?')) {
      return ApiResponse(200, {
        'data': [
          {
            'code': 'MSH',
            'name': 'Marvel Super Heroes',
            'release_date': '2026-06-26',
            'type': 'expansion',
            'card_count': 14,
            'status': 'future',
          },
        ],
        'page': 1,
        'limit': 50,
        'total_returned': 1,
      });
    }

    if (endpoint.startsWith('/cards?set=SOC')) {
      return ApiResponse(200, {
        'data': [
          {
            'id': 'soc-card-1',
            'name': 'Strixhaven Archive Adept',
            'mana_cost': '{1}{U}',
            'type_line': 'Creature — Human Wizard',
            'oracle_text': 'Draw a card.',
            'colors': ['U'],
            'color_identity': ['U'],
            'image_url': null,
            'set_code': 'soc',
            'set_name': 'Secrets of Strixhaven Commander',
            'set_release_date': '2026-04-24',
            'rarity': 'rare',
          },
        ],
        'page': 1,
        'limit': 100,
        'total_returned': 1,
      });
    }

    return ApiResponse(404, {'error': 'not found'});
  }
}

class _FakeDeckApiClient extends ApiClient {
  final List<Map<String, dynamic>> postBodies = [];

  @override
  Future<ApiResponse> get(String endpoint) async {
    if (endpoint == '/decks/deck-1') {
      return ApiResponse(200, _deckDetailsJson());
    }
    return ApiResponse(404, {'error': 'not found'});
  }

  @override
  Future<ApiResponse> post(
    String endpoint,
    Map<String, dynamic> body, {
    Duration? timeout,
  }) async {
    if (endpoint == '/decks/deck-1/cards') {
      postBodies.add(body);
      return ApiResponse(200, {'ok': true});
    }
    return ApiResponse(404, {'error': 'not found'});
  }
}

DeckCardItem _sampleCard() {
  return DeckCardItem(
    id: 'card-1',
    name: 'Atraxa, Praetors\' Voice',
    manaCost: '{G}{W}{U}{B}',
    typeLine: 'Legendary Creature — Phyrexian Angel',
    oracleText: 'Flying, vigilance, deathtouch, lifelink',
    setCode: 'c16',
    setName: 'Commander 2016',
    setReleaseDate: '2016-11-11',
    rarity: 'mythic',
    collectorNumber: '28',
    foil: false,
    quantity: 1,
    isCommander: false,
  );
}

Map<String, dynamic> _deckDetailsJson() {
  return {
    'id': 'deck-1',
    'name': 'Lorehold Draft',
    'format': 'commander',
    'description': null,
    'is_public': false,
    'created_at': '2026-05-21T10:00:00.000Z',
    'color_identity': <String>[],
    'stats': {'total_cards': 0},
    'commander': <Map<String, dynamic>>[],
    'main_board': <String, List<Map<String, dynamic>>>{},
  };
}

void main() {
  testWidgets(
    'search result opens details from the full tile and adds from plus button',
    (tester) async {
      Map<String, dynamic>? selectedCard;
      final card = _sampleCard();

      await tester.pumpWidget(
        ChangeNotifierProvider<CardProvider>(
          create: (_) => _FixedCardProvider([card]),
          child: MaterialApp(
            theme: AppTheme.darkTheme,
            home: CardSearchScreen(
              deckId: 'binder-1',
              mode: 'binder',
              onCardSelectedForBinder: (cardData) => selectedCard = cardData,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(card.name), findsOneWidget);
      expect(find.textContaining('C16 #28'), findsOneWidget);
      expect(find.textContaining('Non-foil'), findsNothing);
      expect(find.byType(CardDetailScreen), findsNothing);

      await tester.tap(find.byKey(Key('card-search-result-${card.id}')));
      await tester.pumpAndSettle();
      expect(find.byType(CardDetailScreen), findsOneWidget);
      expect(find.text('Código'), findsOneWidget);
      expect(find.text('C16 #28'), findsOneWidget);
      expect(find.text('Acabamento'), findsOneWidget);
      expect(find.text('Non-foil'), findsOneWidget);

      Navigator.of(tester.element(find.byType(CardDetailScreen))).pop();
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Adicionar'));
      await tester.pumpAndSettle();

      expect(selectedCard, isNotNull);
      expect(selectedCard!['id'], card.id);
    },
  );

  testWidgets('search area exposes collections tab and opens set detail', (
    tester,
  ) async {
    final apiClient = _FakeSetsApiClient();

    await tester.pumpWidget(
      ChangeNotifierProvider<CardProvider>(
        create: (_) => _FixedCardProvider([_sampleCard()]),
        child: MaterialApp(
          theme: AppTheme.darkTheme,
          home: CardSearchScreen(
            deckId: 'binder-1',
            mode: 'binder',
            setsApiClient: apiClient,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(Tab, 'Coleções'));
    await tester.pumpAndSettle();

    expect(find.text('Catálogo de Coleções'), findsOneWidget);
    expect(find.text('Marvel Super Heroes'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('setsSearchField')), 'soc');
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();

    expect(find.text('Secrets of Strixhaven Commander'), findsOneWidget);

    await tester.tap(find.text('Secrets of Strixhaven Commander'));
    await tester.pumpAndSettle();

    expect(find.text('Strixhaven Archive Adept'), findsOneWidget);
    expect(apiClient.requests.any((r) => r.contains('q=soc')), isTrue);
    expect(
      apiClient.requests.any((r) => r.startsWith('/cards?set=SOC')),
      isTrue,
    );
  });

  testWidgets('card search exposes keyed empty and error states', (
    tester,
  ) async {
    await tester.pumpWidget(
      ChangeNotifierProvider<CardProvider>(
        create: (_) => _FixedCardProvider(const []),
        child: MaterialApp(
          theme: AppTheme.darkTheme,
          home: const CardSearchScreen(deckId: 'binder-1', mode: 'binder'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('card-search-empty-state')), findsOneWidget);
    expect(find.byKey(const Key('card-search-error')), findsNothing);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();

    await tester.pumpWidget(
      ChangeNotifierProvider<CardProvider>(
        create:
            (_) => _FixedCardProvider(
              const [],
              errorMessageOverride: 'Falha controlada',
            ),
        child: MaterialApp(
          key: UniqueKey(),
          theme: AppTheme.darkTheme,
          home: CardSearchScreen(
            key: UniqueKey(),
            deckId: 'binder-1',
            mode: 'binder',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('card-search-error')), findsOneWidget);
    expect(find.byKey(const Key('card-search-empty-state')), findsNothing);
  });

  testWidgets(
    'commander deck without commander shows guided commander choice',
    (tester) async {
      final card = _sampleCard();
      final apiClient = _FakeDeckApiClient();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<CardProvider>(
              create: (_) => _FixedCardProvider([card]),
            ),
            ChangeNotifierProvider<DeckProvider>(
              create: (_) => DeckProvider(apiClient: apiClient),
            ),
          ],
          child: MaterialApp(
            theme: AppTheme.darkTheme,
            home: const CardSearchScreen(deckId: 'deck-1'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Adicionar'));
      await tester.pumpAndSettle();

      expect(find.text('Adicionar carta ao deck'), findsOneWidget);
      expect(
        find.byKey(const Key('card-search-add-quantity-stepper')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('card-search-commander-choice-card')),
        findsOneWidget,
      );
      expect(find.text('Definir como comandante'), findsOneWidget);
      expect(find.text('Adicionar como carta comum'), findsOneWidget);
      expect(find.textContaining('Defina esta carta agora'), findsOneWidget);

      await tester.ensureVisible(find.text('Adicionar como carta comum'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Adicionar como carta comum'));
      await tester.pumpAndSettle();
      final confirmButton = find.byKey(
        Key('card-search-add-confirm-${card.id}'),
      );
      await tester.ensureVisible(confirmButton);
      await tester.pumpAndSettle();
      await tester.tap(confirmButton);
      await tester.pumpAndSettle();

      expect(apiClient.postBodies, isNotEmpty);
      expect(apiClient.postBodies.single['card_id'], card.id);
      expect(apiClient.postBodies.single['quantity'], 1);
      expect(apiClient.postBodies.single['is_commander'], isFalse);
    },
  );
}
