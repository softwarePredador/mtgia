import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manaloom/features/decks/models/deck_card_item.dart';
import 'package:manaloom/features/decks/models/deck_details.dart';
import 'package:manaloom/features/decks/widgets/deck_progress_indicator.dart';

void main() {
  final deck = DeckDetails(
    id: 'deck-1',
    name: 'Deck de teste',
    format: 'commander',
    isPublic: false,
    createdAt: DateTime.parse('2026-07-17T00:00:00Z'),
    stats: const {},
    commander: const <DeckCardItem>[],
    mainBoard: const <String, List<DeckCardItem>>{},
  );

  Widget subject({required int totalCards}) {
    return MaterialApp(
      home: Scaffold(
        body: DeckProgressIndicator(
          deck: deck,
          totalCards: totalCards,
          maxCards: 100,
          hasCommander: true,
        ),
      ),
    );
  }

  testWidgets('does not present count completeness as legal readiness', (
    tester,
  ) async {
    await tester.pumpWidget(subject(totalCards: 100));

    expect(
      find.text('Contagem completa — valide a legalidade'),
      findsOneWidget,
    );
    expect(find.text('Contagem OK'), findsOneWidget);
    expect(find.text('Deck completo!'), findsNothing);
    expect(find.text('Pronto'), findsNothing);
  });

  testWidgets('reports cards above the format limit as invalid', (
    tester,
  ) async {
    await tester.pumpWidget(subject(totalCards: 101));

    expect(find.text('Excede em 1 carta'), findsOneWidget);
    expect(find.text('Contagem OK'), findsNothing);
  });
}
