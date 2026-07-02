import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manaloom/features/decks/widgets/deck_add_cards_menu.dart';

void main() {
  Future<void> pumpMenu(
    WidgetTester tester, {
    required bool scannerEnabled,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: DeckAddCardsMenu(
              scannerEnabled: scannerEnabled,
              onSelected: (_) {},
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('hides scanner action in the default launch scope', (
    tester,
  ) async {
    await pumpMenu(tester, scannerEnabled: false);

    await tester.tap(find.byType(PopupMenuButton<String>));
    await tester.pumpAndSettle();

    expect(find.text('Buscar Carta'), findsOneWidget);
    expect(find.text('Escanear Carta'), findsNothing);
    expect(find.text('Usar câmera (OCR)'), findsNothing);
  });

  testWidgets('shows scanner action only when explicitly enabled', (
    tester,
  ) async {
    await pumpMenu(tester, scannerEnabled: true);

    await tester.tap(find.byType(PopupMenuButton<String>));
    await tester.pumpAndSettle();

    expect(find.text('Buscar Carta'), findsOneWidget);
    expect(find.text('Escanear Carta'), findsOneWidget);
    expect(find.text('Usar câmera (OCR)'), findsOneWidget);
  });
}
