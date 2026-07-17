import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manaloom/core/theme/app_theme.dart';
import 'package:manaloom/core/widgets/app_state_panel.dart';

void main() {
  Widget createSubject() {
    return MaterialApp(
      theme: AppTheme.darkTheme,
      home: Scaffold(
        body: SizedBox(
          width: 280,
          height: 180,
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

      final root =
          tester
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
}
