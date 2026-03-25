import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manaloom/features/decks/models/deck.dart';
import 'package:manaloom/features/decks/widgets/deck_card.dart';

void main() {
  Widget buildCard(Deck deck) {
    return MaterialApp(
      home: Scaffold(body: DeckCard(deck: deck, onTap: () {}, onDelete: () {})),
    );
  }

  testWidgets('exibe linha de comandante quando deck possui commanderName', (
    tester,
  ) async {
    final deck = Deck(
      id: 'deck-1',
      name: 'Atraxa Control',
      format: 'commander',
      isPublic: false,
      createdAt: DateTime(2025, 6, 15),
      cardCount: 100,
      commanderName: 'Atraxa, Praetors\' Voice',
      commanderImageUrl:
          'https://cards.scryfall.io/large/front/0/d/0d9573ce-e15b-4f10-b914-1d876b5ad152.jpg',
      colorIdentity: const ['W', 'U', 'B', 'G'],
    );

    await tester.pumpWidget(buildCard(deck));
    await tester.pump();

    expect(find.text('Atraxa Control'), findsOneWidget);
    expect(find.text('Comandante: Atraxa, Praetors\' Voice'), findsOneWidget);
  });
}
