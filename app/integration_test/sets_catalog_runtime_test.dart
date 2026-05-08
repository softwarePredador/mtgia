import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:manaloom/core/theme/app_theme.dart';
import 'package:manaloom/features/collection/screens/sets_catalog_screen.dart';

import 'runtime_test_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'sets catalog searches and opens set detail against live backend',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          title: 'ManaLoom Sets Runtime',
          theme: AppTheme.darkTheme,
          home: const SetsCatalogScreen(),
        ),
      );

      await pumpUntilFound(tester, find.text('Coleções MTG'));
      await pumpUntilFound(tester, find.byKey(const Key('setsCatalogList')));

      await tester.enterText(
        find.byKey(const Key('setsSearchField')),
        'Marvel',
      );
      await tester.pump(const Duration(milliseconds: 500));
      await pumpUntilFound(tester, find.text('Marvel Super Heroes'));

      final marvelTile = find.byKey(const Key('set-tile-spm'));
      final marvelTileUpper = find.byKey(const Key('set-tile-SPM'));
      await pumpUntilAnyFound(tester, [marvelTile, marvelTileUpper]);
      await tester.tap(
        marvelTile.evaluate().isNotEmpty ? marvelTile : marvelTileUpper,
      );
      await tester.pumpAndSettle();

      final cardsList = find.byKey(const Key('setCardsList'));
      final emptyState = find.byKey(const Key('setCardsEmptyState'));
      await pumpUntilAnyFound(tester, [cardsList, emptyState]);

      expect(
        cardsList.evaluate().isNotEmpty || emptyState.evaluate().isNotEmpty,
        isTrue,
      );

      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('setsCatalogList')), findsOneWidget);

      await tester.enterText(find.byKey(const Key('setsSearchField')), 'OM2');
      await tester.pump(const Duration(milliseconds: 500));
      await pumpUntilFound(tester, find.text('Through the Omenpaths 2'));

      final omenpathsTile = find.byKey(const Key('set-tile-om2'));
      final omenpathsTileUpper = find.byKey(const Key('set-tile-OM2'));
      await pumpUntilAnyFound(tester, [omenpathsTile, omenpathsTileUpper]);
      await tester.tap(
        omenpathsTile.evaluate().isNotEmpty
            ? omenpathsTile
            : omenpathsTileUpper,
      );
      await tester.pumpAndSettle();
      await pumpUntilFound(
        tester,
        find.text('Dados parciais de coleção futura'),
      );

      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('setsCatalogList')), findsOneWidget);
    },
  );
}
