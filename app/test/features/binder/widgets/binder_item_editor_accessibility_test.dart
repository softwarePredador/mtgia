import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manaloom/core/theme/app_theme.dart';
import 'package:manaloom/features/binder/providers/binder_provider.dart';
import 'package:manaloom/features/binder/widgets/binder_item_editor.dart';

import '../../../ui/support/manaloom_ui_audit_harness.dart';

void main() {
  testWidgets('lista Tenho e Quero exposes selection and 48px targets', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        home: Scaffold(
          body: BinderItemEditor(
            item: BinderItem(
              id: 'binder-1',
              cardId: 'card-1',
              cardName: 'Sol Ring',
              listType: 'have',
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final haveSemantics = tester.widget<Semantics>(
      find
          .ancestor(
            of: find.byKey(const Key('binder-editor-list-have')),
            matching: find.byType(Semantics),
          )
          .first,
    );
    expect(haveSemantics.properties.button, isTrue);
    expect(haveSemantics.properties.selected, isTrue);
    expect(
      tester.getSize(find.byKey(const Key('binder-editor-list-have'))).height,
      greaterThanOrEqualTo(48),
    );
    expect(
      tester.getSize(find.byKey(const Key('binder-editor-list-want'))).height,
      greaterThanOrEqualTo(48),
    );

    await tester.tap(find.byKey(const Key('binder-editor-list-want')));
    await tester.pumpAndSettle();

    final wantSemantics = tester.widget<Semantics>(
      find
          .ancestor(
            of: find.byKey(const Key('binder-editor-list-want')),
            matching: find.byType(Semantics),
          )
          .first,
    );
    expect(wantSemantics.properties.selected, isTrue);
    await expectManaLoomBaselineAccessibility(tester);
    semantics.dispose();
  });
}
