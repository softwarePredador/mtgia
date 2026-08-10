import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manaloom/core/api/api_client.dart';
import 'package:manaloom/core/theme/app_theme.dart';
import 'package:manaloom/features/binder/providers/binder_provider.dart';
import 'package:manaloom/features/binder/widgets/binder_item_editor.dart';
import 'package:manaloom/features/cards/providers/card_provider.dart';
import 'package:provider/provider.dart';

class _PrintingCardProvider extends CardProvider {
  _PrintingCardProvider(this.printings) : super(apiClient: ApiClient());

  final List<Map<String, dynamic>> printings;

  @override
  Future<List<Map<String, dynamic>>> fetchPrintingsByName(String name) async =>
      printings;
}

class _RetryPrintingCardProvider extends CardProvider {
  _RetryPrintingCardProvider() : super(apiClient: ApiClient());

  int calls = 0;

  @override
  Future<List<Map<String, dynamic>>> fetchPrintingsByName(String name) async {
    calls += 1;
    if (calls == 1) throw TimeoutException('printing lookup timeout');
    return const [
      {
        'id': 'card-validation-1',
        'name': 'Sol Ring',
        'set_code': 'CMM',
        'collector_number': '396',
        'set_name': 'Commander Masters',
        'set_release_date': '2023-08-04',
        'rarity': 'uncommon',
        'foil': false,
      },
      {
        'id': 'card-validation-2',
        'name': 'Sol Ring',
        'set_code': 'LTC',
        'collector_number': '284',
        'set_name': 'Tales of Middle-earth Commander',
        'set_release_date': '2023-06-23',
        'rarity': 'uncommon',
        'foil': true,
      },
    ];
  }
}

BinderItem _binderItem() {
  return BinderItem(
    id: 'binder-validation-1',
    cardId: 'card-validation-1',
    cardName: 'Sol Ring',
    listType: 'have',
  );
}

Future<void> _pumpEditor(
  WidgetTester tester, {
  Size viewport = const Size(390, 844),
  BinderItem? item,
  String? cardId,
  String? cardName,
  Map<String, dynamic>? initialPrinting,
  CardProvider? cardProvider,
  Future<bool> Function(Map<String, dynamic> data)? onSave,
  Future<bool> Function()? onDelete,
}) async {
  tester.view.physicalSize = viewport;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final subject = MaterialApp(
    theme: AppTheme.darkTheme,
    home: Scaffold(
      body: BinderItemEditor(
        item: item,
        cardId: cardId,
        cardName: cardName,
        initialPrinting: initialPrinting,
        onSave: onSave,
        onDelete: onDelete,
      ),
    ),
  );
  await tester.pumpWidget(
    cardProvider == null
        ? subject
        : ChangeNotifierProvider<CardProvider>.value(
            value: cardProvider,
            child: subject,
          ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('wide editor keeps controls in a centered working frame', (
    tester,
  ) async {
    await _pumpEditor(
      tester,
      viewport: const Size(1920, 1080),
      item: _binderItem(),
    );

    final frame = find.byKey(const Key('binder-editor-content-frame'));
    expect(frame, findsOneWidget);
    final rect = tester.getRect(frame);
    expect(rect.width, lessThanOrEqualTo(1120));
    expect(rect.width, greaterThan(900));
    expect(rect.center.dx, closeTo(960, 1));
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'printing failure offers retry and deletion exposes bounded confirmation anchors',
    (tester) async {
      final provider = _RetryPrintingCardProvider();
      addTearDown(provider.dispose);
      var deleteCalls = 0;
      await _pumpEditor(
        tester,
        item: _binderItem(),
        cardProvider: provider,
        onDelete: () async {
          deleteCalls += 1;
          return false;
        },
      );

      expect(
        find.byKey(const Key('binder-editor-printings-error')),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const Key('binder-editor-printings-retry')));
      await tester.pumpAndSettle();

      expect(provider.calls, 2);
      expect(
        find.byKey(const Key('binder-editor-printings-list')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('binder-editor-printings-hint')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('binder-editor-printings-next')),
        findsOneWidget,
      );
      expect(
        find.byKey(
          const Key('binder-editor-printing-option-card-validation-2'),
        ),
        findsOneWidget,
      );

      final remove = find.byKey(const Key('binder-editor-remove-button'));
      await tester.ensureVisible(remove);
      await tester.tap(remove);
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('binder-editor-delete-dialog')),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const Key('binder-editor-delete-cancel')));
      await tester.pumpAndSettle();
      expect(deleteCalls, 0);
      expect(find.byKey(const Key('binder-editor-sheet')), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('validates sale price inside editor before calling persistence', (
    tester,
  ) async {
    final saved = <Map<String, dynamic>>[];
    await _pumpEditor(
      tester,
      item: _binderItem(),
      onSave: (data) async {
        saved.add(data);
        return false;
      },
    );

    final saleSwitch = find.byKey(const Key('binder-editor-for-sale-switch'));
    await tester.ensureVisible(saleSwitch);
    await tester.tap(saleSwitch);
    await tester.pumpAndSettle();

    final save = find.byKey(const Key('binder-editor-save-button'));
    await tester.ensureVisible(save);
    await tester.tap(save);
    await tester.pump();

    expect(saved, isEmpty);
    expect(find.byKey(const Key('binder-editor-save-error')), findsOneWidget);
    expect(
      find.text('Informe um preço válido maior que zero.'),
      findsOneWidget,
    );
    final priceField = tester.widget<TextField>(
      find.byKey(const Key('binder-editor-price-field')),
    );
    expect(priceField.focusNode?.hasFocus, isTrue);
    expect(find.byType(SnackBar), findsNothing);

    await tester.enterText(
      find.byKey(const Key('binder-editor-price-field')),
      '12,50',
    );
    await tester.pump();
    expect(find.byKey(const Key('binder-editor-save-error')), findsNothing);

    await tester.ensureVisible(save);
    await tester.tap(save);
    await tester.pump();

    expect(saved, hasLength(1));
    expect(saved.single['for_sale'], isTrue);
    expect(saved.single['price'], 12.5);
    expect(
      find.text(
        'Não foi possível salvar esta carta. Revise os dados e tente novamente.',
      ),
      findsOneWidget,
    );
    expect(find.byType(SnackBar), findsNothing);
    await tester.pumpAndSettle();
    final error = find.byKey(const Key('binder-editor-save-error'));
    final logicalViewportHeight =
        tester.view.physicalSize.height / tester.view.devicePixelRatio;
    expect(
      tester.getBottomRight(error).dy,
      lessThanOrEqualTo(logicalViewportHeight),
      reason: 'O feedback de persistência deve ficar integralmente visível.',
    );
    expect(
      tester.getBottomRight(save).dy,
      lessThanOrEqualTo(logicalViewportHeight),
      reason: 'A ação de tentar novamente deve permanecer visível.',
    );
  });

  testWidgets('transport failure preserves form and exposes a friendly retry', (
    tester,
  ) async {
    var calls = 0;
    await _pumpEditor(
      tester,
      item: _binderItem(),
      onSave: (_) async {
        calls += 1;
        throw TimeoutException('provider timeout');
      },
    );

    final notes = find.byKey(const Key('binder-editor-notes-field'));
    await tester.ensureVisible(notes);
    await tester.enterText(notes, 'cópia para o deck principal');

    final save = find.byKey(const Key('binder-editor-save-button'));
    await tester.ensureVisible(save);
    await tester.tap(save);
    await tester.pump();

    expect(calls, 1);
    expect(
      find.text(
        'A conexão demorou mais que o esperado. Tente novamente em instantes.',
      ),
      findsOneWidget,
    );
    expect(find.textContaining('provider timeout'), findsNothing);
    expect(find.text('cópia para o deck principal'), findsOneWidget);
    expect(
      tester.widget<ElevatedButton>(save).onPressed,
      isNotNull,
      reason: 'O usuário precisa conseguir tentar salvar novamente.',
    );
  });

  testWidgets('rejects non-finite price and clears it when sale is disabled', (
    tester,
  ) async {
    final saved = <Map<String, dynamic>>[];
    await _pumpEditor(
      tester,
      item: _binderItem(),
      onSave: (data) async {
        saved.add(data);
        return true;
      },
    );

    final saleSwitch = find.byKey(const Key('binder-editor-for-sale-switch'));
    await tester.ensureVisible(saleSwitch);
    await tester.tap(saleSwitch);
    await tester.pumpAndSettle();

    final price = find.byKey(const Key('binder-editor-price-field'));
    await tester.enterText(price, 'NaN');
    final save = find.byKey(const Key('binder-editor-save-button'));
    await tester.ensureVisible(save);
    await tester.tap(save);
    await tester.pump();

    expect(saved, isEmpty);
    expect(
      find.text('Informe um preço válido maior que zero.'),
      findsOneWidget,
    );

    await tester.ensureVisible(saleSwitch);
    await tester.tap(saleSwitch);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('binder-editor-save-error')), findsNothing);
    expect(price, findsNothing);

    await tester.ensureVisible(save);
    await tester.tap(save);
    await tester.pumpAndSettle();
    expect(saved, hasLength(1));
    expect(saved.single['for_sale'], isFalse);
    expect(saved.single['price'], isNull);
  });

  testWidgets('missing printing error remains inside the editor', (
    tester,
  ) async {
    await _pumpEditor(tester, onSave: (_) async => true);

    final save = find.byKey(const Key('binder-editor-save-button'));
    await tester.ensureVisible(save);
    await tester.tap(save);
    await tester.pump();

    expect(find.text('Selecione uma edição válida da carta.'), findsOneWidget);
    expect(find.byKey(const Key('binder-editor-save-error')), findsOneWidget);
    expect(find.byType(SnackBar), findsNothing);
  });

  testWidgets('unmatched printing preserves the received card id', (
    tester,
  ) async {
    final saved = <Map<String, dynamic>>[];
    final provider = _PrintingCardProvider(const [
      {'id': 'printing-a', 'name': 'Card', 'set_code': 'AAA'},
      {'id': 'printing-b', 'name': 'Card', 'set_code': 'BBB'},
    ]);
    addTearDown(provider.dispose);

    await _pumpEditor(
      tester,
      cardId: 'printing-original',
      cardName: '',
      cardProvider: provider,
      onSave: (data) async {
        saved.add(data);
        return true;
      },
    );

    expect(
      find.byKey(const Key('binder-editor-original-printing-warning')),
      findsOneWidget,
    );
    final save = find.byKey(const Key('binder-editor-save-button'));
    await tester.ensureVisible(save);
    await tester.tap(save);
    await tester.pumpAndSettle();

    expect(saved, hasLength(1));
    expect(saved.single['card_id'], 'printing-original');
  });

  testWidgets('received printing metadata survives complementary lookup', (
    tester,
  ) async {
    final saved = <Map<String, dynamic>>[];
    final provider = _PrintingCardProvider(const [
      {'id': 'printing-other', 'name': 'Sol Ring', 'set_code': 'CMM'},
      {'id': 'printing-another', 'name': 'Sol Ring', 'set_code': 'LTC'},
    ]);
    addTearDown(provider.dispose);

    await _pumpEditor(
      tester,
      cardId: 'printing-original',
      cardName: 'Sol Ring',
      initialPrinting: const {
        'id': 'printing-original',
        'name': 'Sol Ring',
        'set_code': 'C16',
        'collector_number': '272',
        'set_name': 'Commander 2016',
        'set_release_date': '2016-11-11',
        'rarity': 'uncommon',
        'foil': false,
      },
      cardProvider: provider,
      onSave: (data) async {
        saved.add(data);
        return true;
      },
    );

    expect(
      find.byKey(const Key('binder-editor-printing-metadata')),
      findsOneWidget,
    );
    expect(find.textContaining('C16 #272'), findsOneWidget);
    expect(find.textContaining('Commander 2016'), findsOneWidget);

    final save = find.byKey(const Key('binder-editor-save-button'));
    await tester.ensureVisible(save);
    await tester.tap(save);
    await tester.pumpAndSettle();

    expect(saved.single['card_id'], 'printing-original');
  });

  testWidgets(
    'existing item sends card_id only after explicit printing change',
    (tester) async {
      final saved = <Map<String, dynamic>>[];
      final provider = _PrintingCardProvider(const [
        {
          'id': 'card-validation-1',
          'name': 'Sol Ring',
          'set_code': 'CMM',
          'collector_number': '396',
        },
        {
          'id': 'card-validation-2',
          'name': 'Sol Ring',
          'set_code': 'LTC',
          'collector_number': '284',
        },
      ]);
      addTearDown(provider.dispose);

      await _pumpEditor(
        tester,
        item: _binderItem(),
        cardProvider: provider,
        onSave: (data) async {
          saved.add(data);
          return true;
        },
      );

      await tester.ensureVisible(find.text('LTC #284'));
      await tester.tap(find.text('LTC #284'));
      await tester.pumpAndSettle();

      final save = find.byKey(const Key('binder-editor-save-button'));
      await tester.ensureVisible(save);
      await tester.tap(save);
      await tester.pumpAndSettle();

      expect(saved, hasLength(1));
      expect(saved.single['card_id'], 'card-validation-2');
    },
  );
}
