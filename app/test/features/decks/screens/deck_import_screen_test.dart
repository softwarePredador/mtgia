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

class _PartialSuccessDeckProvider extends DeckProvider {
  _PartialSuccessDeckProvider() : super(apiClient: _NoopApiClient());

  @override
  Future<Map<String, dynamic>> importDeckFromList({
    required String name,
    required String format,
    required String list,
    String? description,
    String? commander,
  }) async {
    return {
      'success': true,
      'deck': {'id': 'deck-1'},
      'cards_imported': 9,
      'not_found_lines': const ['1 Dragao Pira Funesta'],
      'warnings': const [
        'Comandante informado ("Kaalia of the Vast") foi adicionado ao slot de comandante.',
      ],
      'is_partial': true,
      'deck_state': 'draft',
      'requires_review': true,
      'commander_detected': true,
      'missing_commander': false,
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
  test('detected count sums quantities and ignores invalid lines', () {
    expect(
      detectedImportCardCount('1 Sol Ring\n4 Island\n2x Mountain\nSideboard'),
      7,
    );
  });

  testWidgets('uses a padded single-column layout at 390px', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(_buildSubject());
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('deck-import-desktop-panes')), findsNothing);
    expect(tester.takeException(), isNull);

    final frameSize = tester.getSize(
      find.byKey(const Key('deck-import-content-frame')),
    );
    final ctaSize = tester.getSize(
      find.byKey(const Key('deck-import-cta-frame')),
    );
    expect(frameSize.width, closeTo(358, 0.1));
    expect(ctaSize.width, closeTo(frameSize.width, 0.1));
  });

  testWidgets('uses bounded metadata and list panes at 1280px', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1280, 900);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(_buildSubject());
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('deck-import-desktop-panes')), findsOneWidget);
    expect(tester.takeException(), isNull);

    final frameSize = tester.getSize(
      find.byKey(const Key('deck-import-content-frame')),
    );
    final metadataSize = tester.getSize(
      find.byKey(const Key('deck-import-metadata-pane')),
    );
    final ctaSize = tester.getSize(
      find.byKey(const Key('deck-import-cta-frame')),
    );
    expect(frameSize.width, lessThanOrEqualTo(1120));
    expect(metadataSize.width, closeTo(460, 0.1));
    expect(ctaSize.width, lessThanOrEqualTo(320));
  });

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

    expect(find.text('13 cartas detectadas'), findsOneWidget);
  });

  testWidgets('shows softer inline error presentation after failed import', (
    tester,
  ) async {
    await tester.pumpWidget(
      _buildSubject(provider: _ImportFailureDeckProvider()),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('deck-import-screen-name-field')),
      'Deck de teste',
    );
    await tester.enterText(
      find.byKey(const Key('deck-import-screen-list-field')),
      '1 Sol Ring',
    );
    await tester.pumpAndSettle();

    final submitButton = find.byKey(
      const Key('deck-import-screen-submit-button'),
    );
    await tester.ensureVisible(submitButton);
    await tester.tap(submitButton);
    await tester.pumpAndSettle();

    expect(find.text('Não foi possível importar agora'), findsOneWidget);
    expect(find.text('Falha ao processar a lista informada.'), findsOneWidget);
  });

  testWidgets('shows partial import dialog when review is still needed', (
    tester,
  ) async {
    await tester.pumpWidget(
      _buildSubject(provider: _PartialSuccessDeckProvider()),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('deck-import-screen-name-field')),
      'Kaalia import',
    );
    await tester.enterText(
      find.byKey(const Key('deck-import-screen-commander-field')),
      'Kaalia da Vastidão',
    );
    await tester.enterText(
      find.byKey(const Key('deck-import-screen-list-field')),
      '1 Sol Ring\n1 Dragao Pira Funesta',
    );
    await tester.pumpAndSettle();

    final submitButton = find.byKey(
      const Key('deck-import-screen-submit-button'),
    );
    await tester.ensureVisible(submitButton);
    await tester.tap(submitButton);
    await tester.pumpAndSettle();

    expect(find.text('Importação parcial'), findsOneWidget);
    expect(
      find.text(
        'O deck foi criado, mas ainda precisa de revisão antes de análise ou otimização.',
      ),
      findsOneWidget,
    );
    expect(find.text('Abrir rascunho'), findsOneWidget);
    expect(find.text('1 cartas não identificadas'), findsOneWidget);
  });
}
