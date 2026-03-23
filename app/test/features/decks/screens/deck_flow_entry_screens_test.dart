import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manaloom/features/decks/screens/deck_generate_screen.dart';
import 'package:manaloom/features/decks/screens/deck_import_screen.dart';

void main() {
  Widget wrap(Widget child) {
    return MaterialApp(home: child);
  }

  testWidgets('DeckGenerateScreen aplica o formato inicial vindo do fluxo', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap(const DeckGenerateScreen(initialFormat: 'modern')),
    );

    expect(find.text('Modern'), findsOneWidget);
    expect(find.text('Commander'), findsNothing);
  });

  testWidgets('DeckImportScreen aplica o formato inicial vindo do fluxo', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap(const DeckImportScreen(initialFormat: 'pauper')),
    );

    expect(find.text('Pauper'), findsOneWidget);
    expect(find.text('Commander'), findsNothing);
  });
}
