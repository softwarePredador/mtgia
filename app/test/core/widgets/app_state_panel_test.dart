import 'package:flutter/material.dart';
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
}
