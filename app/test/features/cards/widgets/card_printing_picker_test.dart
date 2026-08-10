import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manaloom/core/theme/app_theme.dart';
import 'package:manaloom/features/cards/widgets/card_edition_metadata.dart';
import 'package:manaloom/features/cards/widgets/card_printing_picker.dart';
import 'package:manaloom/features/decks/models/deck_card_item.dart';

DeckCardItem _baseCard() {
  return DeckCardItem(
    id: 'base-printing',
    oracleId: 'oracle-sol-ring',
    name: 'Sol Ring',
    manaCost: '{1}',
    typeLine: 'Artifact',
    oracleText: '{T}: Add {C}{C}.',
    setCode: 'tst',
    setName: 'Test Set',
    setReleaseDate: '2026-01-01',
    rarity: 'uncommon',
    printingCount: 2,
    quantity: 3,
    isCommander: false,
    collectorNumber: '1',
    foil: false,
    condition: CardCondition.lp,
  );
}

List<Map<String, dynamic>> _printings() {
  return [
    {
      'id': 'printing-normal',
      'oracle_id': 'oracle-sol-ring',
      'name': 'Sol Ring',
      'mana_cost': '{1}',
      'type_line': 'Artifact',
      'image_url': 'https://cards.scryfall.io/normal/front/a/b/normal.jpg',
      'set_code': 'tst',
      'set_name': 'Test Set',
      'set_release_date': '2026-01-01',
      'collector_number': '1',
      'rarity': 'uncommon',
      'foil': false,
      'price': 1.5,
      'price_currency': 'USD',
      'price_source': 'scryfall',
    },
    {
      'id': 'printing-reference',
      'oracle_id': 'oracle-sol-ring',
      'name': 'Sol Ring',
      'mana_cost': '{1}',
      'type_line': 'Artifact',
      'image_url': null,
      'set_code': 'oth',
      'set_name': 'Other Set',
      'set_release_date': '2025-02-03',
      'collector_number': '7',
      'rarity': 'rare',
      'foil': true,
    },
  ];
}

void main() {
  testWidgets(
    'keeps set, collector and catalog finish visible at compact width',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: const Scaffold(
            body: Align(
              alignment: Alignment.topLeft,
              child: SizedBox(
                width: 210,
                child: CardEditionMetadataLine(
                  setCode: 'tst',
                  collectorNumber: '001',
                  setName: 'S3-07 Visual Fixture Set',
                  setReleaseDate: '2026-07-21',
                  rarity: 'uncommon',
                  foil: false,
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.text('TST #001'), findsOneWidget);
      expect(find.text('Sem foil'), findsOneWidget);
      expect(
        find.text('S3-07 Visual Fixture Set • 2026 • Uncommon'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('keeps physical finish distinct from catalog availability', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        home: const Scaffold(
          body: CardEditionMetadataLine(
            setCode: 'tst',
            foil: false,
            finishContext: CardFinishContext.physicalCopy,
          ),
        ),
      ),
    );

    expect(find.text('Non-foil'), findsOneWidget);
    expect(find.text('Sem foil'), findsNothing);
  });

  test(
    'never borrows physical identity from a different fallback printing',
    () {
      final option = CardPrintingOption.fromJson({
        'id': 'printing-with-incomplete-metadata',
        'name': 'Sol Ring',
      }, fallbackCard: _baseCard());

      expect(option.card.setCode, isEmpty);
      expect(option.card.setName, isNull);
      expect(option.card.setReleaseDate, isNull);
      expect(option.card.collectorNumber, isNull);
      expect(option.card.rarity, isEmpty);
      expect(option.card.foil, isNull);
      expect(option.hasExactArtwork, isFalse);
    },
  );

  testWidgets(
    'requires an explicit printing and returns its exact catalog identity',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(390, 844);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);

      DeckCardItem? selected;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: Scaffold(
            body: Builder(
              builder: (context) => Center(
                child: FilledButton(
                  onPressed: () async {
                    selected = await showCardPrintingPicker(
                      context: context,
                      card: _baseCard(),
                      loadPrintings: (_) async => _printings(),
                    );
                  },
                  child: const Text('abrir'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('abrir'));
      await tester.pumpAndSettle();

      expect(find.text('Escolha a impressão'), findsOneWidget);
      expect(find.text('TST #1'), findsOneWidget);
      expect(find.text('OTH #7'), findsOneWidget);
      expect(find.textContaining('Sem foil'), findsOneWidget);
      expect(find.textContaining('Foil disponível'), findsOneWidget);
      expect(find.text('US\$ 1,50'), findsOneWidget);
      expect(
        find.text('Arte de referência; confirme pelos metadados.'),
        findsOneWidget,
      );

      final confirmBeforeSelection = tester.widget<FilledButton>(
        find.byKey(const Key('card-printing-picker-confirm')),
      );
      expect(confirmBeforeSelection.onPressed, isNull);

      await tester.tap(
        find.byKey(const Key('card-printing-option-printing-reference')),
      );
      await tester.pumpAndSettle();

      expect(find.text('OTH #7 selecionada'), findsOneWidget);
      final confirmAfterSelection = tester.widget<FilledButton>(
        find.byKey(const Key('card-printing-picker-confirm')),
      );
      expect(confirmAfterSelection.onPressed, isNotNull);

      await tester.tap(find.byKey(const Key('card-printing-picker-confirm')));
      await tester.pumpAndSettle();

      expect(selected, isNotNull);
      expect(selected!.id, 'printing-reference');
      expect(selected!.oracleId, 'oracle-sol-ring');
      expect(selected!.setCode, 'oth');
      expect(selected!.collectorNumber, '7');
      expect(selected!.foil, isTrue);
      expect(selected!.quantity, 3);
      expect(selected!.condition, CardCondition.lp);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('keeps a failed load recoverable inside the picker', (
    tester,
  ) async {
    var calls = 0;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        home: Scaffold(
          body: Builder(
            builder: (context) => FilledButton(
              onPressed: () {
                showCardPrintingPicker(
                  context: context,
                  card: _baseCard(),
                  loadPrintings: (_) async {
                    calls++;
                    if (calls == 1) throw Exception('controlled');
                    return _printings();
                  },
                );
              },
              child: const Text('abrir'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();

    expect(find.text('Impressões indisponíveis'), findsOneWidget);
    expect(find.byKey(const Key('card-printing-picker-retry')), findsOneWidget);

    await tester.tap(find.byKey(const Key('card-printing-picker-retry')));
    await tester.pumpAndSettle();

    expect(calls, 2);
    expect(
      find.byKey(const Key('card-printing-picker-options')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}
