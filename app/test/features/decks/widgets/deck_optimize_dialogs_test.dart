import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manaloom/features/decks/widgets/deck_optimize_dialogs.dart';
import 'package:manaloom/features/decks/widgets/deck_optimize_ui_support.dart';

void main() {
  testWidgets('guided rebuild dialog renders expected copy', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: GuidedRebuildLoadingDialog()),
      ),
    );

    expect(find.text('Criando versão reconstruída...'), findsOneWidget);
    expect(find.textContaining('rascunho novo'), findsOneWidget);
  });

  testWidgets('optimize progress dialog reacts to progress state', (
    tester,
  ) async {
    final progress = ValueNotifier<FlowProgressState>(
      const FlowProgressState(
        stage: 'Consultando IA para sugestões',
        stageNumber: 2,
        totalStages: 5,
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: OptimizeProgressDialog(progressState: progress)),
      ),
    );
    await tester.pump();

    expect(find.text('Consultando a IA para sugestões'), findsOneWidget);
    expect(find.text('Etapa 2 de 5'), findsOneWidget);
  });

  testWidgets('apply optimization loading helper opens dialog', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            return Scaffold(
              body: TextButton(
                onPressed: () => showApplyOptimizationLoading(context),
                child: const Text('open'),
              ),
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pump();

    expect(find.text('Aplicando mudanças...'), findsOneWidget);
    expect(find.textContaining('Salvando trocas'), findsOneWidget);
  });

  testWidgets('optimize no changes helper shows snackbar', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            return Scaffold(
              body: TextButton(
                onPressed: () => showOptimizeNoChangesSnackBar(context),
                child: const Text('snack'),
              ),
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('snack'));
    await tester.pump();

    expect(find.text('Nenhuma mudança sugerida para aplicar.'), findsOneWidget);
  });

  testWidgets('guided rebuild created helper shows snackbar', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            return Scaffold(
              body: TextButton(
                onPressed: () => showGuidedRebuildCreatedSnackBar(context),
                child: const Text('rebuild'),
              ),
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('rebuild'));
    await tester.pump();

    expect(
      find.textContaining('versão reconstruída em rascunho'),
      findsOneWidget,
    );
  });

  testWidgets('guided rebuild failure helper opens dialog', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            return Scaffold(
              body: TextButton(
                onPressed:
                    () => showGuidedRebuildFailureDialog(
                      context,
                      message: 'Falha no rebuild',
                      reasons: const ['Gate'],
                    ),
                child: const Text('failure'),
              ),
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('failure'));
    await tester.pumpAndSettle();

    expect(find.text('Falha ao reconstruir'), findsOneWidget);
    expect(find.text('Falha no rebuild'), findsOneWidget);
    expect(find.text('• Gate'), findsOneWidget);
  });

  testWidgets('deck ai generic error helper shows snackbar', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            return Scaffold(
              body: TextButton(
                onPressed:
                    () => showDeckAiErrorSnackBar(context, 'Erro genérico'),
                child: const Text('error'),
              ),
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('error'));
    await tester.pump();

    expect(find.text('Erro genérico'), findsOneWidget);
  });
}
