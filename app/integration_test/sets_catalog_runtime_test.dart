import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:manaloom/core/theme/app_theme.dart';
import 'package:manaloom/features/collection/screens/sets_catalog_screen.dart';

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

      await _pumpUntilFound(tester, find.text('Coleções MTG'));
      await _pumpUntilFound(tester, find.byKey(const Key('setsCatalogList')));

      await tester.enterText(
        find.byKey(const Key('setsSearchField')),
        'Marvel',
      );
      await tester.pump(const Duration(milliseconds: 500));
      await _pumpUntilFound(tester, find.text('Marvel Super Heroes'));

      await tester.tap(find.text('Marvel Super Heroes'));
      await tester.pumpAndSettle();
      await _pumpUntilFound(tester, find.text('Marvel Super Heroes'));

      final cardsList = find.byKey(const Key('setCardsList'));
      final partialState = find.text('Dados parciais de set futuro');
      await _pumpUntilAnyFound(tester, [cardsList, partialState]);

      expect(
        cardsList.evaluate().isNotEmpty || partialState.evaluate().isNotEmpty,
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

  fail('Expected at least one runtime success state to render.');
}
