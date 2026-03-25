import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
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
}
