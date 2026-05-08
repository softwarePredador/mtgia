import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:manaloom/core/widgets/cached_card_image.dart';
import 'package:manaloom/core/theme/app_theme.dart';
import 'package:manaloom/features/cards/providers/card_provider.dart';
import 'package:manaloom/features/cards/screens/card_detail_screen.dart';
import 'package:manaloom/features/cards/screens/card_search_screen.dart';
import 'package:provider/provider.dart';

import 'runtime_test_helpers.dart';
import 'visual_capture_helpers.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  testWidgets(
    'search collections tab searches and opens set detail against live backend',
    (tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider<CardProvider>(
          create: (_) => CardProvider(),
          child: MaterialApp(
            title: 'ManaLoom Search Sets Runtime',
            theme: AppTheme.darkTheme,
            home: const CardSearchScreen(deckId: 'runtime', mode: 'binder'),
          ),
        ),
      );

      await pumpUntilFound(tester, find.widgetWithText(Tab, 'Cartas'));
      await tester.enterText(
        find.byKey(const Key('card-search-field')),
        'Black Lotus',
      );
      await tester.pump(const Duration(milliseconds: 500));
      await pumpUntilFound(tester, find.text('Black Lotus'));
      await captureVisualProof(binding, tester, 'sets_search_01_cards_results');
      expect(find.byType(CardDetailScreen), findsNothing);

      await tester.tap(find.text('Black Lotus').first);
      await tester.pumpAndSettle();
      expect(find.byType(CardDetailScreen), findsNothing);

      await tester.tap(find.byType(CachedCardImage).first);
      await tester.pumpAndSettle();
      await pumpUntilFound(tester, find.byType(CardDetailScreen));
      expect(find.text('Detalhes'), findsWidgets);
      await captureVisualProof(binding, tester, 'sets_search_02_card_detail');

      Navigator.of(tester.element(find.byType(CardDetailScreen))).pop();
      await tester.pumpAndSettle();
      await pumpUntilFound(tester, find.text('Black Lotus'));

      await pumpUntilFound(tester, find.widgetWithText(Tab, 'Coleções'));
      await tester.tap(find.widgetWithText(Tab, 'Coleções'));
      await tester.pumpAndSettle();

      await pumpUntilFound(tester, find.byKey(const Key('setsSearchField')));
      await tester.enterText(find.byKey(const Key('setsSearchField')), 'ECC');
      await tester.pump(const Duration(milliseconds: 500));
      await pumpUntilFound(tester, find.text('Lorwyn Eclipsed Commander'));
      await captureVisualProof(
        binding,
        tester,
        'sets_search_03_collections_results',
      );

      await tester.tap(find.text('Lorwyn Eclipsed Commander'));
      await tester.pumpAndSettle();
      await pumpUntilFound(tester, find.text('Lorwyn Eclipsed Commander'));

      final cardsList = find.byKey(const Key('setCardsList'));
      final emptyState = find.text('Nenhuma carta local nesta coleção');
      await pumpUntilAnyFound(tester, [cardsList, emptyState]);

      expect(
        cardsList.evaluate().isNotEmpty || emptyState.evaluate().isNotEmpty,
        isTrue,
      );
      await captureVisualProof(binding, tester, 'sets_search_04_set_detail');

      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('setsCatalogList')), findsOneWidget);
    },
  );
}
