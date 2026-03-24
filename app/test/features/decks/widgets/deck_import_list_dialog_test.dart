import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manaloom/core/theme/app_theme.dart';
import 'package:manaloom/features/decks/widgets/deck_import_list_dialog.dart';

void main() {
  testWidgets('showDeckImportListDialog imports list and refreshes deck', (
    tester,
  ) async {
    final importCalls = <Map<String, dynamic>>[];
    final refreshedDecks = <String>[];
    String? snackMessage;
    Color? snackColor;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        home: Builder(
          builder: (context) {
            return Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () {
                    showDeckImportListDialog(
                      context: context,
                      deckId: 'deck-1',
                      importListToDeck: ({
                        required deckId,
                        required list,
                        required replaceAll,
                      }) async {
                        importCalls.add({
                          'deckId': deckId,
                          'list': list,
                          'replaceAll': replaceAll,
                        });
                        return {
                          'success': true,
                          'cards_imported': 2,
                          'not_found_lines': const [],
                        };
                      },
                      refreshDeckDetails: (deckId) async {
                        refreshedDecks.add(deckId);
                      },
                      showSnackBar: ({
                        required message,
                        required backgroundColor,
                      }) {
                        snackMessage = message;
                        snackColor = backgroundColor;
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

    expect(find.text('Importar Lista'), findsOneWidget);
    await tester.enterText(find.byType(TextField), '1 Sol Ring\n1 Arcane Signet');
    await tester.tap(find.text('Importar'));
    await tester.pumpAndSettle();

    expect(importCalls, hasLength(1));
    expect(importCalls.first['deckId'], 'deck-1');
    expect(refreshedDecks, ['deck-1']);
    expect(snackMessage, '2 cartas importadas!');
    expect(snackColor, AppTheme.darkTheme.colorScheme.primary);
  });
}
