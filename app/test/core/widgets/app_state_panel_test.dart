import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manaloom/core/theme/app_theme.dart';
import 'package:manaloom/core/widgets/app_state_panel.dart';
import 'package:manaloom/core/widgets/manaloom_glyph.dart';

import '../../ui/support/manaloom_ui_audit_harness.dart';

void main() {
  Widget createSubject({double width = 280, double height = 180}) {
    return MaterialApp(
      theme: AppTheme.darkTheme,
      home: Scaffold(
        body: SizedBox(
          width: width,
          height: height,
          child: AppStatePanel(
            icon: Icons.info_outline_rounded,
            title: 'Nenhum conteúdo por aqui',
            message:
                'Quando algo importante aparecer, esse estado ajuda o usuário a entender o que fazer.',
            accent: AppTheme.primarySoft,
            actionLabel: 'Atualizar',
            onAction: () {},
          ),
        ),
      ),
    );
  }

  testWidgets('renders without overflow on narrow layouts', (tester) async {
    await tester.pumpWidget(createSubject());
    await tester.pumpAndSettle();

    expect(find.text('Nenhum conteúdo por aqui'), findsOneWidget);
    expect(find.text('Atualizar'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('announces state changes as a live status region', (
    tester,
  ) async {
    await tester.pumpWidget(createSubject());
    await tester.pumpAndSettle();

    final liveRegions = tester.widgetList<Semantics>(
      find.byWidgetPredicate(
        (widget) => widget is Semantics && widget.properties.liveRegion == true,
      ),
    );
    expect(liveRegions, hasLength(1));
    expect(
      liveRegions.single.properties.label,
      contains('Nenhum conteúdo por aqui'),
    );
  });

  testWidgets('announces status once while keeping its action accessible', (
    tester,
  ) async {
    final semanticsHandle = tester.ensureSemantics();
    try {
      await tester.pumpWidget(createSubject());
      await tester.pumpAndSettle();

      final labels = <String>[];
      void collectLabels(SemanticsNode node) {
        if (node.label.isNotEmpty) labels.add(node.label);
        node.visitChildren((child) {
          collectLabels(child);
          return true;
        });
      }

      final root = tester
          .binding
          .renderViews
          .single
          .owner!
          .semanticsOwner!
          .rootSemanticsNode!;
      collectLabels(root);

      expect(
        labels.where((label) => label.contains('Nenhum conteúdo por aqui')),
        hasLength(1),
      );
      expect(labels.where((label) => label == 'Atualizar'), hasLength(1));
    } finally {
      semanticsHandle.dispose();
    }
  });

  testWidgets('loading state exposes one live label and a progress indicator', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        home: const Scaffold(
          body: AppStatePanel.loading(
            key: Key('state-loading'),
            title: 'Carregando coleção',
            message: 'Buscando suas cartas.',
            accent: AppTheme.frost400,
          ),
        ),
      ),
    );

    expect(find.byKey(const Key('state-loading')), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    final semantics = tester.widget<Semantics>(
      find.byWidgetPredicate(
        (widget) => widget is Semantics && widget.properties.liveRegion == true,
      ),
    );
    expect(
      semantics.properties.label,
      'Carregando. Carregando coleção. Buscando suas cartas.',
    );
  });

  testWidgets('supports a themed domain glyph without duplicating semantics', (
    tester,
  ) async {
    final semanticsHandle = tester.ensureSemantics();
    try {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: const Scaffold(
            body: AppStatePanel(
              iconWidget: ManaLoomGlyph(ManaLoomGlyphKind.collection),
              title: 'Coleção vazia',
              message: 'Adicione sua primeira carta.',
              accent: AppTheme.brass400,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is ManaLoomGlyph &&
              widget.kind == ManaLoomGlyphKind.collection,
        ),
        findsOneWidget,
      );
      final stateSemantics = tester.widget<Semantics>(
        find.byWidgetPredicate(
          (widget) =>
              widget is Semantics && widget.properties.liveRegion == true,
        ),
      );
      expect(
        stateSemantics.properties.label,
        'Coleção vazia. Adicione sua primeira carta.',
      );
    } finally {
      semanticsHandle.dispose();
    }
  });

  testWidgets('state panel passes labels, 48px targets and WCAG contrast', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(createSubject(width: 390, height: 844));
    await tester.pumpAndSettle();

    await expectManaLoomBaselineAccessibility(tester);
    semantics.dispose();
  });
}
