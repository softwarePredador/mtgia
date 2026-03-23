import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manaloom/core/theme/app_theme.dart';
import 'package:manaloom/features/decks/models/deck_card_item.dart';
import 'package:manaloom/features/decks/models/deck_details.dart';
import 'package:manaloom/features/decks/widgets/sample_hand_widget.dart';

void main() {
  DeckCardItem card({
    required String id,
    required String name,
    required String typeLine,
    String? manaCost,
    String? oracleText,
    int quantity = 1,
    bool isCommander = false,
  }) {
    return DeckCardItem(
      id: id,
      name: name,
      typeLine: typeLine,
      manaCost: manaCost,
      oracleText: oracleText,
      setCode: 'TST',
      rarity: 'common',
      quantity: quantity,
      isCommander: isCommander,
    );
  }

  DeckDetails makeDeck() {
    return DeckDetails(
      id: 'deck-sample-hand',
      name: 'Talrand Tempo',
      format: 'commander',
      commanderName: 'Talrand, Sky Summoner',
      isPublic: false,
      createdAt: DateTime(2026, 3, 18),
      cardCount: 100,
      stats: const {},
      commander: [
        card(
          id: 'cmdr',
          name: 'Talrand, Sky Summoner',
          typeLine: 'Legendary Creature — Merfolk Wizard',
          manaCost: '{2}{U}{U}',
          quantity: 1,
          isCommander: true,
        ),
      ],
      mainBoard: {
        'Mainboard': [
          card(
            id: 'land',
            name: 'Island',
            typeLine: 'Basic Land — Island',
            quantity: 35,
          ),
          card(
            id: 'signet',
            name: 'Arcane Signet',
            typeLine: 'Artifact',
            manaCost: '{2}',
            oracleText: '{T}: Add one mana of any color.',
            quantity: 4,
          ),
          card(
            id: 'counterspell',
            name: 'Counterspell',
            typeLine: 'Instant',
            manaCost: '{U}{U}',
            oracleText: 'Counter target spell.',
            quantity: 8,
          ),
          card(
            id: 'chart',
            name: 'Chart a Course',
            typeLine: 'Sorcery',
            manaCost: '{1}{U}',
            oracleText:
                'Draw two cards. Then discard a card unless you attacked this turn.',
            quantity: 8,
          ),
          card(
            id: 'cantrip',
            name: 'Consider',
            typeLine: 'Instant',
            manaCost: '{U}',
            oracleText:
                'Look at the top card of your library. You may put that card into your graveyard. Draw a card.',
            quantity: 8,
          ),
          card(
            id: 'filler',
            name: 'Pteramander',
            typeLine: 'Creature — Salamander Drake',
            manaCost: '{U}',
            oracleText: 'Flying',
            quantity: 37,
          ),
        ],
      },
    );
  }

  Widget createSubject({bool compact = false}) {
    return MaterialApp(
      theme: AppTheme.darkTheme,
      home: Scaffold(
        body: SizedBox(
          width: 300,
          child: SingleChildScrollView(
            child: SampleHandWidget(
              deck: makeDeck(),
              compact: compact,
              randomSeed: 7,
            ),
          ),
        ),
      ),
    );
  }

  group('SampleHandWidget', () {
    testWidgets('draws a hand without the commander and shows assessment', (
      tester,
    ) async {
      await tester.pumpWidget(createSubject());
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('sample-hand-draw')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('sample-hand-assessment')), findsOneWidget);
      expect(find.textContaining('cartas'), findsOneWidget);
      expect(find.text('Talrand, Sky Summoner'), findsNothing);

      final assessmentTexts =
          tester
              .widgetList<Text>(
                find.descendant(
                  of: find.byKey(const Key('sample-hand-assessment')),
                  matching: find.byType(Text),
                ),
              )
              .map((text) => text.data ?? '')
              .toList();
      expect(
        assessmentTexts.any(
          (text) => {
            'Keep provável',
            'Arriscada',
            'Borderline',
            'Mulligan',
          }.contains(text),
        ),
        isTrue,
      );
    });

    testWidgets('supports compact mode and mulligan without overflow', (
      tester,
    ) async {
      await tester.pumpWidget(createSubject(compact: true));
      await tester.pumpAndSettle();

      expect(find.text('Playtest rápido'), findsOneWidget);

      await tester.tap(find.byKey(const Key('sample-hand-draw')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('sample-hand-mulligan')));
      await tester.pumpAndSettle();

      expect(find.text('6 cartas'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
