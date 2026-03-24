import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manaloom/features/decks/models/deck_card_item.dart';
import 'package:manaloom/features/decks/widgets/deck_card_edit_dialog.dart';

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
  testWidgets('showDeckCardEditDialog validates quantity before save', (
    tester,
  ) async {
    final card = _buildCard();
    var saveCalls = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            return Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () async {
                    await showDeckCardEditDialog(
                      context: context,
                      card: card,
                      deckFormat: 'commander',
                      loadPrintings: (_) async => [
                        {
                          'id': 'card-1',
                          'set_code': 'TST',
                          'set_name': 'Test Set',
                          'set_release_date': '2026-01-01',
                        },
                      ],
                      onSave: ({
                        required selectedCardId,
                        required quantity,
                        required selectedCondition,
                        required consolidateSameName,
                      }) async {
                        saveCalls++;
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

    await tester.enterText(find.byType(TextField), '0');
    await tester.tap(find.text('Salvar'));
    await tester.pumpAndSettle();

    expect(find.text('Quantidade inválida'), findsOneWidget);
    expect(saveCalls, 0);
  });

  testWidgets('showDeckCardEditDialog dispatches save and closes on success', (
    tester,
  ) async {
    final card = _buildCard();
    int? savedQty;
    String? savedCardId;
    bool? savedConsolidate;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            return Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () async {
                    await showDeckCardEditDialog(
                      context: context,
                      card: card,
                      deckFormat: 'commander',
                      loadPrintings: (_) async => [
                        {
                          'id': 'card-1',
                          'set_code': 'TST',
                          'set_name': 'Test Set',
                          'set_release_date': '2026-01-01',
                        },
                      ],
                      onSave: ({
                        required selectedCardId,
                        required quantity,
                        required selectedCondition,
                        required consolidateSameName,
                      }) async {
                        savedQty = quantity;
                        savedCardId = selectedCardId;
                        savedConsolidate = consolidateSameName;
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

    await tester.enterText(find.byType(TextField), '2');
    await tester.tap(find.text('Salvar'));
    await tester.pumpAndSettle();

    expect(savedQty, 2);
    expect(savedCardId, 'card-1');
    expect(savedConsolidate, isTrue);
    expect(find.text('Editar carta'), findsNothing);
  });
}
