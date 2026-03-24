import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manaloom/features/decks/models/deck_card_item.dart';
import 'package:manaloom/features/decks/widgets/deck_details_dialogs.dart';
import 'dart:async';

DeckCardItem _buildCard() => DeckCardItem(
  id: 'card-1',
  name: 'Arcane Signet',
  typeLine: 'Artifact',
  oracleText: '{T}: Add one mana of any color.',
  setCode: 'tst',
  rarity: 'common',
  quantity: 1,
  isCommander: false,
);

void main() {
  testWidgets('showDeckDescriptionEditorDialog returns edited description', (
    tester,
  ) async {
    String? result;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            return Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () async {
                    result = await showDeckDescriptionEditorDialog(
                      context: context,
                      currentDescription: 'Plano inicial',
                    );
                  },
                  child: const Text('abrir'),
                ),
              ),
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();

    expect(find.text('Descrição do deck'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'Plano atualizado');
    await tester.tap(find.text('Salvar'));
    await tester.pumpAndSettle();

    expect(result, 'Plano atualizado');
  });

  testWidgets('showDeckAiExplanationFlow renders explanation dialog', (
    tester,
  ) async {
    final card = _buildCard();
    final completer = Completer<String?>();

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            return Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () async {
                    await showDeckAiExplanationFlow(
                      context: context,
                      card: card,
                      explainCard: (_) => completer.future,
                    );
                  },
                  child: const Text('abrir'),
                ),
              ),
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('abrir'));
    await tester.pump();
    expect(find.text('Analisando a carta...'), findsOneWidget);

    completer.complete('Carta de aceleração para o deck.');
    await tester.pumpAndSettle();
    expect(find.text('Análise: Arcane Signet'), findsOneWidget);
    expect(find.text('Carta de aceleração para o deck.'), findsOneWidget);
    expect(find.text('Entendi'), findsOneWidget);
  });

  testWidgets('showDeckEditionPicker lists printings and dispatches replace', (
    tester,
  ) async {
    final card = _buildCard();
    String? replacedId;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            return Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () async {
                    await showDeckEditionPicker(
                      context: context,
                      card: card,
                      loadPrintings:
                          (_) async => [
                            {
                              'id': 'card-1',
                              'set_name': 'Test Set',
                              'set_release_date': '2026-01-01',
                              'rarity': 'common',
                              'image_url': null,
                            },
                            {
                              'id': 'card-2',
                              'set_name': 'Other Set',
                              'set_release_date': '2025-01-01',
                              'rarity': 'rare',
                              'price': 1.5,
                              'image_url': null,
                            },
                          ],
                      onReplaceEdition: (newCardId) async {
                        replacedId = newCardId;
                      },
                    );
                  },
                  child: const Text('abrir'),
                ),
              ),
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();

    expect(find.text('Edições disponíveis'), findsOneWidget);
    expect(find.text('Other Set'), findsOneWidget);

    await tester.tap(find.text('Other Set'));
    await tester.pumpAndSettle();

    expect(replacedId, 'card-2');
  });

  testWidgets('showDeckCardDetailsDialog renders actions and callbacks', (
    tester,
  ) async {
    final card = _buildCard().copyWith(
      manaCost: '{2}',
      setName: 'Test Set',
      setReleaseDate: '2026-01-01',
    );
    var explanationCalls = 0;
    var editionCalls = 0;
    var detailsCalls = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            return Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () async {
                    await showDeckCardDetailsDialog(
                      context: context,
                      card: card,
                      onShowAiExplanation: () async {
                        explanationCalls++;
                      },
                      onShowEditionPicker: () async {
                        editionCalls++;
                      },
                      onOpenFullDetails: () {
                        detailsCalls++;
                      },
                    );
                  },
                  child: const Text('abrir'),
                ),
              ),
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();

    expect(find.text('Arcane Signet'), findsOneWidget);
    expect(find.text('Trocar edição'), findsOneWidget);
    expect(find.text('Explicar'), findsOneWidget);
    expect(find.text('Ver Detalhes'), findsOneWidget);

    await tester.tap(find.text('Trocar edição'));
    await tester.pumpAndSettle();
    expect(editionCalls, 1);

    await tester.tap(find.text('Explicar'));
    await tester.pumpAndSettle();
    expect(explanationCalls, 1);

    await tester.tap(find.text('Ver Detalhes'));
    await tester.pumpAndSettle();
    expect(detailsCalls, 1);
  });

  testWidgets('showDeckRemoveCardConfirmationDialog returns confirmation', (
    tester,
  ) async {
    final card = _buildCard();
    bool? confirmed;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            return Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () async {
                    confirmed = await showDeckRemoveCardConfirmationDialog(
                      context: context,
                      card: card,
                    );
                  },
                  child: const Text('abrir'),
                ),
              ),
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();

    expect(find.text('Remover carta'), findsOneWidget);
    expect(find.text('Remover "Arcane Signet" do deck?'), findsOneWidget);

    await tester.tap(find.text('Remover'));
    await tester.pumpAndSettle();

    expect(confirmed, isTrue);
  });

  testWidgets('showDeckPricingDetailsSheet renders pricing breakdown', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            return Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () async {
                    await showDeckPricingDetailsSheet(
                      context: context,
                      pricing: {
                        'estimated_total_usd': 42.5,
                        'items': const [
                          {
                            'name': 'Arcane Signet',
                            'quantity': 1,
                            'set_code': 'tst',
                            'unit_price_usd': 2.5,
                            'line_total_usd': 2.5,
                          },
                        ],
                      },
                    );
                  },
                  child: const Text('abrir'),
                ),
              ),
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();

    expect(find.text('Custo do deck'), findsOneWidget);
    expect(find.text('Total estimado: \$42.5'), findsOneWidget);
    expect(find.text('1× Arcane Signet'), findsOneWidget);
    expect(find.text('\$2.50'), findsWidgets);
  });
}
