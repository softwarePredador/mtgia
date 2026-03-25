import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manaloom/core/api/api_client.dart';
import 'package:manaloom/core/theme/app_theme.dart';
import 'package:manaloom/features/decks/providers/deck_provider.dart';
import 'package:manaloom/features/decks/screens/deck_import_screen.dart';
import 'package:provider/provider.dart';

class _NoopApiClient extends ApiClient {}

class _ImportFailureDeckProvider extends DeckProvider {
  _ImportFailureDeckProvider() : super(apiClient: _NoopApiClient());

  @override
  Future<Map<String, dynamic>> importDeckFromList({
    required String name,
    required String format,
    required String list,
    String? description,
    String? commander,
  }) async {
    return {
      'success': false,
      'error': 'Falha ao processar a lista informada.',
      'not_found_lines': const <String>[],
      'warnings': const <String>[],
      'cards_imported': 0,
    };
  }
}

Widget _buildSubject({DeckProvider? provider}) {
  return MaterialApp(
    theme: AppTheme.darkTheme,
    home: ChangeNotifierProvider<DeckProvider>.value(
      value: provider ?? DeckProvider(apiClient: _NoopApiClient()),
      child: const DeckImportScreen(),
    ),
  );
}

void main() {
  testWidgets('shows calmer initial import state and example updates count', (
    tester,
  ) async {
    await tester.pumpWidget(_buildSubject());
    await tester.pumpAndSettle();

    expect(find.text('Importar Lista'), findsWidgets);
    expect(
      find.text(
        'Cole sua lista e transforme isso em um deck editável em poucos passos.',
      ),
      findsOneWidget,
    );
    expect(find.text('Moxfield / Archidekt / EDHRec'), findsOneWidget);
    expect(
      find.text('Cole a lista ou use um exemplo para começar'),
      findsOneWidget,
    );
    expect(find.text('Não foi possível importar agora'), findsNothing);

    await tester.ensureVisible(find.text('Exemplo'));
    await tester.tap(find.text('Exemplo'));
    await tester.pumpAndSettle();

    expect(find.text('7 cartas detectadas'), findsOneWidget);
  });

  testWidgets('shows softer inline error presentation after failed import', (
    tester,
  ) async {
    await tester.pumpWidget(
      _buildSubject(provider: _ImportFailureDeckProvider()),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).at(0), 'Deck de teste');
    await tester.enterText(find.byType(TextField).last, '1 Sol Ring');
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Criar Deck'));
    await tester.tap(find.text('Criar Deck'));
    await tester.pumpAndSettle();

    expect(find.text('Não foi possível importar agora'), findsOneWidget);
    expect(find.text('Falha ao processar a lista informada.'), findsOneWidget);
  });
}
