import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manaloom/features/decks/models/deck_card_item.dart';
import 'package:manaloom/features/decks/widgets/deck_details_dialogs.dart';
import 'dart:async';

import '../../../support/layout_test_tools.dart';

DeckCardItem _buildCard() => DeckCardItem(
  id: 'card-1',
  name: 'Arcane Signet',
  typeLine: 'Artifact',
  oracleText: '{T}: Add one mana of any color.',
  setCode: 'tst',
  setName: 'Test Set',
  setReleaseDate: '2026-01-01',
  collectorNumber: '42',
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
    await tester.enterText(
      find.byKey(const Key('deck-description-editor-field')),
      'Plano atualizado',
    );
    await tester.tap(
      find.byKey(const Key('deck-description-editor-save-button')),
    );
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
                      loadPrintings: (_) async => [
                        {
                          'id': 'card-1',
                          'set_code': 'TST',
                          'set_name': 'Test Set',
                          'set_release_date': '2026-01-01',
                          'collector_number': '42',
                          'rarity': 'common',
                          'image_url': null,
                        },
                        {
                          'id': 'card-2',
                          'set_code': 'OTH',
                          'set_name': 'Other Set',
                          'set_release_date': '2025-01-01',
                          'collector_number': '7',
                          'foil': true,
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
    expect(find.text('OTH #7 foil'), findsOneWidget);
    expect(find.text('Other Set • 2025-01-01 • rare'), findsOneWidget);

    await tester.tap(find.text('OTH #7 foil'));
    await tester.pumpAndSettle();

    expect(replacedId, 'card-2');
  });

  testWidgets('showDeckCardDetailsDialog renders actions and callbacks', (
    tester,
  ) async {
    final card = _buildCard().copyWith(manaCost: '{2}');
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
    expect(
      find.byKey(const Key('deck-card-details-dialog-card-1')),
      findsOneWidget,
    );
    final imageSize = tester.getSize(
      find.byKey(const Key('deck-card-details-image-card-1')),
    );
    expect(imageSize.height, greaterThan(imageSize.width));
    expect(imageSize.height / imageSize.width, closeTo(1.397, 0.02));
    expect(find.text('TST #42'), findsOneWidget);
    expect(find.text('Test Set • 2026-01-01 • common'), findsOneWidget);
    expect(
      find.byKey(const Key('deck-card-change-edition-card-1')),
      findsOneWidget,
    );
    expect(find.text('Explicar com IA'), findsOneWidget);
    expect(find.text('Ver Detalhes'), findsOneWidget);

    await tester.tap(find.text('Explicar com IA'));
    await tester.pumpAndSettle();
    expect(explanationCalls, 1);

    await tester.tap(find.text('Ver Detalhes'));
    await tester.pumpAndSettle();
    expect(detailsCalls, 1);

    await tester.tap(find.text('Fechar'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('deck-card-change-edition-card-1')));
    await tester.pumpAndSettle();
    expect(editionCalls, 1);
    expect(
      find.byKey(const Key('deck-card-change-edition-card-1')),
      findsNothing,
    );
  });

  testWidgets(
    'showDeckCardDetailsDialog keeps footer actions tappable on compact mobile layout',
    (tester) async {
      enableFatalHitTestWarnings();
      setTestViewport(tester, const Size(320, 568));

      final card = _buildCard().copyWith(manaCost: '{2}');
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
                        onShowAiExplanation: () async {},
                        onShowEditionPicker: () async {},
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
      final imageSize = tester.getSize(
        find.byKey(const Key('deck-card-details-image-card-1')),
      );
      expect(imageSize.height, greaterThan(imageSize.width));
      expect(imageSize.height / imageSize.width, closeTo(1.397, 0.02));
      expect(find.text('Ver Detalhes'), findsOneWidget);
      expect(find.text('Fechar'), findsOneWidget);

      await tester.tap(find.text('Ver Detalhes'));
      await tester.pumpAndSettle();
      expect(detailsCalls, 1);

      await tester.tap(find.text('Fechar'));
      await tester.pumpAndSettle();
      expectNoLayoutExceptions(tester);
    },
  );

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
    expect(find.text('Arcane Signet'), findsOneWidget);
    expect(
      find.textContaining('Você poderá adicioná-la novamente pela busca.'),
      findsOneWidget,
    );

    await tester.tap(find.text('Remover'));
    await tester.pumpAndSettle();

    expect(confirmed, isTrue);
  });

  testWidgets(
    'showDeckAiExplanationFlow maps technical errors to friendly copy',
    (tester) async {
      final card = _buildCard();

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
                        explainCard: (_) async => throw Exception(
                          'SocketException: failed host lookup',
                        ),
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
      await tester.pumpAndSettle();

      expect(find.textContaining('Exception'), findsNothing);
      expect(find.textContaining('SocketException'), findsNothing);
      expect(
        find.text(
          'Sem conexão com o servidor. Confira sua internet e tente novamente.',
        ),
        findsOneWidget,
      );
    },
  );

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
                        'currency': 'USD',
                        'price_source': 'scryfall',
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
    expect(find.text('Total estimado: US\$ 42,50'), findsOneWidget);
    expect(find.text('Fonte: Scryfall'), findsOneWidget);
    expect(find.text('1× Arcane Signet'), findsOneWidget);
    expect(find.text('US\$ 2,50'), findsWidgets);
  });

  testWidgets('pricing sheet keeps an unavailable total explicit', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: ElevatedButton(
              onPressed: () => showDeckPricingDetailsSheet(
                context: context,
                pricing: const {
                  'estimated_total_usd': null,
                  'currency': 'USD',
                  'missing_price_cards': 100,
                  'items': [],
                },
              ),
              child: const Text('abrir sem preço'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('abrir sem preço'));
    await tester.pumpAndSettle();

    expect(find.text('Total indisponível'), findsOneWidget);
    expect(find.textContaining('100 carta(s) sem preço'), findsOneWidget);
    expect(find.textContaining('0,00'), findsNothing);
  });
}
