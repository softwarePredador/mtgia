import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manaloom/features/decks/providers/deck_provider_support.dart';
import 'package:manaloom/features/decks/widgets/deck_optimize_dialogs.dart';
import 'package:manaloom/features/decks/widgets/deck_optimize_flow_support.dart';
import 'package:manaloom/features/decks/widgets/deck_optimize_sections.dart';
import 'package:manaloom/features/decks/widgets/deck_optimize_ui_support.dart';

void main() {
  testWidgets('guided rebuild dialog renders expected copy', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: GuidedRebuildLoadingDialog())),
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

  testWidgets('optimize no changes feedback explains aggressive diagnostics', (
    tester,
  ) async {
    final result = {
      'mode': 'optimize',
      'intensity': 'aggressive',
      'removals': const <String>[],
      'additions': const <String>[],
      'optimize_diagnostics': {
        'aggressive_candidate_quality': {
          'removal_candidates': 10,
          'replacement_candidates': 20,
          'pairs_generated': 12,
          'returned_swaps': 0,
          'rejected_reason_buckets': {'quality_gate_rejected': 9},
          'low_candidate_coverage': true,
        },
      },
    };
    final preview = OptimizePreviewData.fromResult(result);
    final outcome = OptimizeRequestOutcome(
      result: result,
      preview: preview,
      applyPlan: buildOptimizeApplyPlan(preview),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            return Scaffold(
              body: TextButton(
                onPressed:
                    () => showOptimizeNoChangesFeedback(context, outcome),
                child: const Text('diagnostics'),
              ),
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('diagnostics'));
    await tester.pumpAndSettle();

    expect(find.text('Nenhuma melhoria segura encontrada'), findsOneWidget);
    expect(find.textContaining('gate bloqueou as inseguras'), findsOneWidget);
    expect(find.text('• Candidatos analisados: 30.'), findsOneWidget);
    expect(find.text('• Pares avaliados: 12.'), findsOneWidget);
    expect(find.text('• Swaps seguros retornados: 0.'), findsOneWidget);
    expect(
      find.text('• Principal bloqueio: qualidade final insuficiente.'),
      findsOneWidget,
    );
    expect(find.textContaining('Faltaram candidatos seguros'), findsOneWidget);
  });

  testWidgets('optimize no changes feedback keeps friendly fallback', (
    tester,
  ) async {
    final result = {
      'mode': 'optimize',
      'intensity': 'aggressive',
      'removals': const <String>[],
      'additions': const <String>[],
    };
    final preview = OptimizePreviewData.fromResult(result);
    final outcome = OptimizeRequestOutcome(
      result: result,
      preview: preview,
      applyPlan: buildOptimizeApplyPlan(preview),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            return Scaffold(
              body: TextButton(
                onPressed:
                    () => showOptimizeNoChangesFeedback(context, outcome),
                child: const Text('fallback'),
              ),
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('fallback'));
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

  testWidgets('optimization preview explains meta references before apply', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            return Scaffold(
              body: TextButton(
                onPressed:
                    () => showOptimizationPreviewDialog(
                      context,
                      mode: 'optimize',
                      archetype: 'control',
                      keepTheme: true,
                      preservedTheme: 'spellslinger',
                      reasoning: 'Ajuste leve com referência meta.',
                      intensity: OptimizeIntensity.aggressive,
                      optimizeIntensity: const {
                        'target_swaps': {'min': 10, 'max': 20},
                      },
                      qualityWarning: null,
                      deckAnalysis: const {'average_cmc': 3.2},
                      postAnalysis: const {'average_cmc': 3.0},
                      warnings: const <String, dynamic>{},
                      metaReferenceContext: const {
                        'meta_scope': {'label': 'Competitive Commander / cEDH'},
                        'selection_reason': 'Exact shell match',
                        'priority_source': 'competitive_meta_exact_shell_match',
                        'references': [
                          {
                            'selection_rank': 1,
                            'shell_label': 'Talrand Tempo',
                            'source': 'EDHTop16',
                            'meta_scope': 'Competitive Commander / cEDH',
                            'strategy_archetype': 'Tempo',
                          },
                        ],
                        'suggested_cards_influenced': [
                          {'name': 'Mystic Remora', 'reference_count': 2},
                        ],
                      },
                      displayRemovals: const [
                        {'name': 'Cancel'},
                      ],
                      displayAdditions: const [
                        {'name': 'Mystic Remora'},
                      ],
                    ),
                child: const Text('preview'),
              ),
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('preview'));
    await tester.pumpAndSettle();

    expect(find.text('Referências meta usadas'), findsOneWidget);
    expect(find.textContaining('Agressivo'), findsOneWidget);
    expect(find.text('Atenção ao ajuste agressivo'), findsOneWidget);
    expect(find.textContaining('não como cópia cega'), findsOneWidget);
    expect(find.text('#1 Talrand Tempo'), findsOneWidget);
    expect(find.text('Mystic Remora'), findsAtLeastNWidgets(1));
    expect(find.text('Ajuste competitivo guiado'), findsOneWidget);
  });

  testWidgets('optimization preview allows deselecting suggestions', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1000, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    OptimizePreviewSelection? selection;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            return Scaffold(
              body: TextButton(
                onPressed: () async {
                  selection = await showOptimizationPreviewDialog(
                    context,
                    mode: 'optimize',
                    archetype: 'control',
                    keepTheme: true,
                    preservedTheme: null,
                    reasoning: 'Trocas seguras.',
                    intensity: OptimizeIntensity.focused,
                    optimizeIntensity: const {
                      'target_swaps': {'min': 6, 'max': 10},
                    },
                    qualityWarning: null,
                    deckAnalysis: const <String, dynamic>{},
                    postAnalysis: const <String, dynamic>{},
                    warnings: const <String, dynamic>{},
                    metaReferenceContext: const <String, dynamic>{},
                    displayRemovals: const [
                      {'name': 'Mind Stone'},
                      {'name': 'Cancel'},
                    ],
                    displayAdditions: const [
                      {'name': 'Arcane Signet'},
                      {'name': 'Counterspell'},
                    ],
                  );
                },
                child: const Text('preview-selectable'),
              ),
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('preview-selectable'));
    await tester.pumpAndSettle();

    final checkboxes = find.byType(Checkbox);
    expect(checkboxes, findsNWidgets(4));
    await tester.tap(checkboxes.first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Aplicar mudanças'));
    await tester.pumpAndSettle();

    expect(selection, isNotNull);
    expect(selection!.selectedRemovalIndexes, isNot(contains(0)));
    expect(selection!.selectedRemovalIndexes, contains(1));
    expect(selection!.selectedAdditionIndexes.length, 2);
  });

  testWidgets(
    'optimization options exposes fallback when archetypes are empty',
    (tester) async {
      String? selected;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: OptimizationOptionsSection(
              snapshot: const AsyncSnapshot.withData(
                ConnectionState.done,
                <Map<String, dynamic>>[],
              ),
              showAllStrategies: true,
              accent: Colors.blue,
              onRetry: () {},
              onSelectArchetype: (value) => selected = value,
            ),
          ),
        ),
      );

      expect(find.text('midrange'), findsOneWidget);
      expect(find.textContaining('Ajuste leve padrão'), findsOneWidget);

      await tester.tap(find.text('Ver sugestões'));
      await tester.pumpAndSettle();

      expect(selected, 'midrange');
    },
  );
}
