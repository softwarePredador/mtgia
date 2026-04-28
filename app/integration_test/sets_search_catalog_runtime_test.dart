import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:manaloom/core/widgets/cached_card_image.dart';
import 'package:manaloom/core/theme/app_theme.dart';
import 'package:manaloom/features/cards/providers/card_provider.dart';
import 'package:manaloom/features/cards/screens/card_detail_screen.dart';
import 'package:manaloom/features/cards/screens/card_search_screen.dart';
import 'package:provider/provider.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

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

      await _pumpUntilFound(tester, find.widgetWithText(Tab, 'Cartas'));
      await tester.enterText(find.byType(TextField).first, 'Black Lotus');
      await tester.pump(const Duration(milliseconds: 500));
      await _pumpUntilFound(tester, find.text('Black Lotus'));
      expect(find.byType(CardDetailScreen), findsNothing);

      await tester.tap(find.text('Black Lotus').first);
      await tester.pumpAndSettle();
      expect(find.byType(CardDetailScreen), findsNothing);

      await tester.tap(find.byType(CachedCardImage).first);
      await tester.pumpAndSettle();
      await _pumpUntilFound(tester, find.byType(CardDetailScreen));
      expect(find.text('Detalhes'), findsWidgets);

      Navigator.of(tester.element(find.byType(CardDetailScreen))).pop();
      await tester.pumpAndSettle();
      await _pumpUntilFound(tester, find.text('Black Lotus'));

      await _pumpUntilFound(tester, find.widgetWithText(Tab, 'Coleções'));
      await tester.tap(find.widgetWithText(Tab, 'Coleções'));
      await tester.pumpAndSettle();

      await _pumpUntilFound(tester, find.byKey(const Key('setsSearchField')));
      await tester.enterText(find.byKey(const Key('setsSearchField')), 'ECC');
      await tester.pump(const Duration(milliseconds: 500));
      await _pumpUntilFound(tester, find.text('Lorwyn Eclipsed Commander'));

      await tester.tap(find.text('Lorwyn Eclipsed Commander'));
      await tester.pumpAndSettle();
      await _pumpUntilFound(tester, find.text('Lorwyn Eclipsed Commander'));

      final cardsList = find.byKey(const Key('setCardsList'));
      final emptyState = find.text('Nenhuma carta local nesta coleção');
      await _pumpUntilAnyFound(tester, [cardsList, emptyState]);

      expect(
        cardsList.evaluate().isNotEmpty || emptyState.evaluate().isNotEmpty,
        isTrue,
      );

      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('setsCatalogList')), findsOneWidget);
    },
  );
}

Future<void> _pumpUntilFound(
  WidgetTester tester,
  Finder finder, {
  Duration timeout = const Duration(seconds: 20),
}) async {
  final end = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(end)) {
    await tester.pump(const Duration(milliseconds: 250));
    if (finder.evaluate().isNotEmpty) return;
  }
  expect(finder, findsOneWidget);
}

Future<void> _pumpUntilAnyFound(
  WidgetTester tester,
  List<Finder> finders, {
  Duration timeout = const Duration(seconds: 20),
}) async {
  final end = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(end)) {
    await tester.pump(const Duration(milliseconds: 250));
    if (finders.any((finder) => finder.evaluate().isNotEmpty)) return;
  }

  fail('Expected at least one search-to-set runtime state to render.');
}
