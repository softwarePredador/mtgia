import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manaloom/core/theme/app_theme.dart';
import 'package:manaloom/features/decks/models/deck_card_item.dart';
import 'package:manaloom/features/decks/models/deck_details.dart';
import 'package:manaloom/features/decks/widgets/deck_diagnostic_panel.dart';

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

  DeckDetails makeHealthyCommanderDeck() {
    return DeckDetails(
      id: 'deck-healthy',
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
            quantity: 36,
          ),
          card(
            id: 'ramp',
            name: 'Arcane Signet',
            typeLine: 'Artifact',
            manaCost: '{2}',
            oracleText: '{T}: Add one mana of any color.',
            quantity: 9,
          ),
          card(
            id: 'draw',
            name: 'Chart a Course',
            typeLine: 'Sorcery',
            manaCost: '{1}{U}',
            oracleText:
                'Draw two cards. Then discard a card unless you attacked this turn.',
            quantity: 8,
          ),
          card(
            id: 'interaction',
            name: 'Counterspell',
            typeLine: 'Instant',
            manaCost: '{U}{U}',
            oracleText: 'Counter target spell.',
            quantity: 10,
          ),
          card(
            id: 'wipe',
            name: 'Aetherize',
            typeLine: 'Instant',
            manaCost: '{3}{U}',
            oracleText:
                'Return all attacking creatures to their owner\'s hand.',
            quantity: 2,
          ),
          card(
            id: 'filler',
            name: 'Pteramander',
            typeLine: 'Creature — Salamander Drake',
            manaCost: '{U}',
            oracleText: 'Flying',
            quantity: 34,
          ),
        ],
      },
    );
  }

  DeckDetails makeUnhealthyCommanderDeck() {
    return DeckDetails(
      id: 'deck-unhealthy',
      name: 'Greedy Battlecruiser',
      format: 'commander',
      commanderName: 'The Ur-Dragon',
      isPublic: false,
      createdAt: DateTime(2026, 3, 18),
      cardCount: 100,
      stats: const {},
      commander: [
        card(
          id: 'cmdr2',
          name: 'The Ur-Dragon',
          typeLine: 'Legendary Creature — Dragon Avatar',
          manaCost: '{4}{W}{U}{B}{R}{G}',
          quantity: 1,
          isCommander: true,
        ),
      ],
      mainBoard: {
        'Mainboard': [
          card(
            id: 'land2',
            name: 'Forest',
            typeLine: 'Basic Land — Forest',
            quantity: 28,
          ),
          card(
            id: 'ramp2',
            name: 'Rampant Growth',
            typeLine: 'Sorcery',
            manaCost: '{1}{G}',
            oracleText:
                'Search your library for a basic land card, put that card onto the battlefield tapped, then shuffle.',
            quantity: 2,
          ),
          card(
            id: 'draw2',
            name: 'Divination',
            typeLine: 'Sorcery',
            manaCost: '{2}{U}',
            oracleText: 'Draw two cards.',
            quantity: 2,
          ),
          card(
            id: 'interaction2',
            name: 'Murder',
            typeLine: 'Instant',
            manaCost: '{1}{B}{B}',
            oracleText: 'Destroy target creature.',
            quantity: 3,
          ),
          card(
            id: 'threat',
            name: 'Ancient Silver Dragon',
            typeLine: 'Creature — Elder Dragon',
            manaCost: '{6}{U}{U}',
            oracleText: 'Flying',
            quantity: 64,
          ),
        ],
      },
    );
  }

  Widget createSubject(DeckDetails deck, {double width = 400}) {
    return MaterialApp(
      theme: AppTheme.darkTheme,
      home: Scaffold(
        body: SizedBox(
          width: width,
          child: SingleChildScrollView(
            child: DeckDiagnosticPanel(deck: deck, onOpenAnalysis: () {}),
          ),
        ),
      ),
    );
  }

  group('DeckDiagnosticPanel', () {
    testWidgets('shows core metrics and quick insights for a healthy deck', (
      tester,
    ) async {
      await tester.pumpWidget(createSubject(makeHealthyCommanderDeck()));
      await tester.pumpAndSettle();

      expect(find.text('Diagnóstico rápido'), findsOneWidget);
      expect(find.text('Terrenos'), findsOneWidget);
      expect(find.text('Ramp'), findsOneWidget);
      expect(find.text('Compra'), findsOneWidget);
      expect(find.text('Interação'), findsOneWidget);
      expect(find.text('CMC médio'), findsOneWidget);
      expect(
        find.text('Base de mana na faixa esperada para o formato.'),
        findsOneWidget,
      );
      expect(
        find.text(
          'Boa densidade de interação para segurar o ritmo da partida.',
        ),
        findsOneWidget,
      );
      expect(find.text('Ver análise'), findsOneWidget);
    });

    testWidgets('avoids overflow and surfaces warnings for a greedy deck', (
      tester,
    ) async {
      await tester.pumpWidget(
        createSubject(makeUnhealthyCommanderDeck(), width: 280),
      );
      await tester.pumpAndSettle();

      expect(find.text('Ramp curto'), findsOneWidget);
      expect(find.text('Compra curta'), findsOneWidget);
      expect(
        find.text('Base de mana curta para o tamanho atual da lista.'),
        findsOneWidget,
      );
      expect(
        find.text(
          'Interação curta; a lista pode sofrer para responder à mesa.',
        ),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });
  });
}
