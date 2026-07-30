import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manaloom/core/theme/app_theme.dart';
import 'package:manaloom/features/binder/providers/binder_provider.dart';
import 'package:manaloom/features/binder/widgets/binder_item_editor.dart';

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
  BinderItem? item,
  String? cardId,
  Future<bool> Function(Map<String, dynamic> data)? onSave,
}) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.darkTheme,
      home: Scaffold(
        body: BinderItemEditor(item: item, cardId: cardId, onSave: onSave),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
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
}
