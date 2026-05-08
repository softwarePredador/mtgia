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
                      loadPrintings:
                          (_) async => [
                            {
                              'id': 'card-1',
                              'set_code': 'TST',
                              'set_name': 'Test Set',
                              'set_release_date': '2026-01-01',
                              'rarity': 'rare',
                              'foil': false,
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

    await tester.enterText(
      find.byKey(const Key('deck-card-edit-quantity-field')),
      '0',
    );
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
                      loadPrintings:
                          (_) async => [
                            {
                              'id': 'card-1',
                              'set_code': 'TST',
                              'set_name': 'Test Set',
                              'set_release_date': '2026-01-01',
                              'rarity': 'rare',
                              'foil': false,
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

    expect(find.textContaining('Non-foil'), findsAtLeastNWidgets(1));
    expect(find.textContaining('Rare'), findsAtLeastNWidgets(1));

    await tester.enterText(
      find.byKey(const Key('deck-card-edit-quantity-field')),
      '2',
    );
    await tester.tap(find.text('Salvar'));
    await tester.pumpAndSettle();

    expect(savedQty, 2);
    expect(savedCardId, 'card-1');
    expect(savedConsolidate, isTrue);
    expect(find.text('Editar carta'), findsNothing);
  });

  testWidgets('showDeckCardEditDialog keeps commander quantity fixed', (
    tester,
  ) async {
    final card = _buildCard().copyWith(
      isCommander: true,
      collectorNumber: '42',
    );
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
                      loadPrintings:
                          (_) async => [
                            {
                              'id': 'card-1',
                              'set_code': 'TST',
                              'set_name': 'Test Set',
                              'set_release_date': '2026-01-01',
                              'collector_number': '42',
                              'rarity': 'mythic',
                              'foil': false,
                            },
                            {
                              'id': 'card-2',
                              'set_code': 'OTH',
                              'set_name': 'Other Set',
                              'set_release_date': '2025-01-01',
                              'collector_number': '7',
                              'rarity': 'mythic',
                              'foil': false,
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

    expect(find.text('Editar comandante'), findsOneWidget);
    expect(find.text('1 cópia fixa para comandante'), findsOneWidget);

    await tester.tap(find.byType(DropdownButton<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('OTH').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Salvar'));
    await tester.pumpAndSettle();

    expect(savedQty, 1);
    expect(savedCardId, 'card-2');
    expect(savedConsolidate, isTrue);
  });
}
