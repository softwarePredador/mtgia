import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manaloom/core/api/api_client.dart';
import 'package:manaloom/core/widgets/cached_card_image.dart';
import 'package:manaloom/core/theme/app_theme.dart';
import 'package:manaloom/features/cards/providers/card_provider.dart';
import 'package:manaloom/features/cards/screens/card_detail_screen.dart';
import 'package:manaloom/features/cards/screens/card_search_screen.dart';
import 'package:manaloom/features/decks/models/deck_card_item.dart';
import 'package:provider/provider.dart';

class _FixedCardProvider extends CardProvider {
  _FixedCardProvider(this._results);

  final List<DeckCardItem> _results;

  @override
  List<DeckCardItem> get searchResults => _results;

  @override
  bool get isLoading => false;

  @override
  bool get isLoadingMore => false;

  @override
  bool get hasMore => false;
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

DeckCardItem _sampleCard() {
  return DeckCardItem(
    id: 'card-1',
    name: 'Atraxa, Praetors\' Voice',
    manaCost: '{G}{W}{U}{B}',
    typeLine: 'Legendary Creature — Phyrexian Angel',
    oracleText: 'Flying, vigilance, deathtouch, lifelink',
    setCode: 'c16',
    setName: 'Commander 2016',
    rarity: 'mythic',
    quantity: 1,
    isCommander: false,
  );
}

void main() {
  testWidgets(
    'search result opens details only from image and adds only from plus button',
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
      expect(find.byType(CardDetailScreen), findsNothing);

      await tester.tap(find.text(card.name));
      await tester.pumpAndSettle();
      expect(find.byType(CardDetailScreen), findsNothing);

      await tester.tap(find.byType(CachedCardImage).first);
      await tester.pumpAndSettle();
      expect(find.byType(CardDetailScreen), findsOneWidget);

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
}
