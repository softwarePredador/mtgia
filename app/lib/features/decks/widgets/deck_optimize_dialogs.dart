import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import 'deck_optimize_sheet_widgets.dart';
import 'deck_optimize_ui_support.dart';
import 'deck_ui_components.dart';

class GuidedRebuildLoadingDialog extends StatelessWidget {
  const GuidedRebuildLoadingDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: FlowLoadingDialog(
        title: 'Criando versão reconstruída...',
        subtitle: 'Montando um rascunho novo sem alterar o deck original.',
        accent: AppTheme.mythicGold,
        icon: Icons.auto_fix_high_rounded,
        tips: [
          'O deck original continua intacto durante a reconstrução.',
          'O rebuild respeita comandante, identidade de cor e bracket.',
          'Quando a lista está muito quebrada, reconstruir é melhor do que forçar trocas pequenas.',
        ],
      ),
    );
  }
}

void showGuidedRebuildLoading(BuildContext context) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => const GuidedRebuildLoadingDialog(),
  );
}

class OptimizeProgressDialog extends StatelessWidget {
  final ValueListenable<FlowProgressState> progressState;

  const OptimizeProgressDialog({super.key, required this.progressState});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ValueListenableBuilder<FlowProgressState>(
        valueListenable: progressState,
        builder: (_, state, __) {
          final presentation = describeOptimizeProgress(state);
          return FlowLoadingDialog(
            title: presentation.title,
            subtitle: presentation.subtitle,
            accent: presentation.accent,
            icon: presentation.icon,
            progress: presentation.progress,
            stepNumber: presentation.stepNumber,
            totalSteps: presentation.totalSteps,
            tips: presentation.tips,
          );
        },
      ),
    );
  }
}

class ApplyOptimizationLoadingDialog extends StatelessWidget {
  const ApplyOptimizationLoadingDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: FlowLoadingDialog(
        title: 'Aplicando mudanças...',
        subtitle: 'Salvando trocas e atualizando a estratégia do deck.',
        accent: AppTheme.success,
        icon: Icons.check_circle_outline_rounded,
        tips: [
          'Estamos gravando as mudanças e recarregando o deck.',
          'As trocas aprovadas entram no deck só depois do salvamento final.',
          'Logo em seguida o app atualiza os detalhes e a estratégia da lista.',
        ],
      ),
    );
  }
}

void showOptimizeProgressLoading(
  BuildContext context,
  ValueListenable<FlowProgressState> progressState,
) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => OptimizeProgressDialog(progressState: progressState),
  );
}

void showApplyOptimizationLoading(BuildContext context) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => const ApplyOptimizationLoadingDialog(),
  );
}

void closeRootLoadingDialog(BuildContext context) {
  Navigator.of(context, rootNavigator: true).pop();
}

Future<void> showOutcomeInfoDialog(
  BuildContext context, {
  required String title,
  required String message,
  List<String> reasons = const <String>[],
}) {
  return showDialog<void>(
    context: context,
    builder:
        (_) => OutcomeInfoDialog(
          title: title,
          message: message,
          reasons: reasons,
        ),
  );
}

Future<bool?> showOptimizationPreviewDialog(
  BuildContext context, {
  required String mode,
  required String archetype,
  required bool keepTheme,
  required String? preservedTheme,
  required String reasoning,
  required Map<String, dynamic>? qualityWarning,
  required Map<String, dynamic> deckAnalysis,
  required Map<String, dynamic> postAnalysis,
  required Map<String, dynamic> warnings,
  required List<Map<String, dynamic>> displayRemovals,
  required List<Map<String, dynamic>> displayAdditions,
  Future<void> Function()? onCopyDebug,
}) {
  return showDialog<bool>(
    context: context,
    builder:
        (ctx) => OptimizationPreviewDialog(
          mode: mode,
          archetype: archetype,
          keepTheme: keepTheme,
          preservedTheme: preservedTheme,
          reasoning: reasoning,
          qualityWarning: qualityWarning,
          deckAnalysis: deckAnalysis,
          postAnalysis: postAnalysis,
          warnings: warnings,
          displayRemovals: displayRemovals,
          displayAdditions: displayAdditions,
          onCancel: () => Navigator.pop(ctx, false),
          onConfirm: () => Navigator.pop(ctx, true),
          onCopyDebug: onCopyDebug,
        ),
  );
}

void showOptimizeNoChangesSnackBar(BuildContext context) {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text('Nenhuma mudança sugerida para aplicar.'),
    ),
  );
}

void showOptimizeDebugCopiedSnackBar(BuildContext context) {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('Debug copiado')),
  );
}

void showOptimizeSuccessSnackBar(BuildContext context) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: const Text('Otimização aplicada com sucesso!'),
      backgroundColor: Theme.of(context).colorScheme.primary,
    ),
  );
}

void closeOptimizeSheetAndShowSuccess(BuildContext context) {
  Navigator.pop(context);
  showOptimizeSuccessSnackBar(context);
}

void showOptimizeApplyErrorSnackBar(BuildContext context, Object error) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text('Erro ao aplicar: $error'),
      backgroundColor: AppTheme.error,
    ),
  );
}

Future<void> showGuidedRebuildPreviewInfoDialog(BuildContext context) {
  return showOutcomeInfoDialog(
    context,
    title: 'Reconstrução gerada',
    message:
        'A reconstrução foi gerada em preview, mas nenhum draft salvo foi retornado.',
  );
}

Future<void> showGuidedRebuildFailureDialog(
  BuildContext context, {
  required String message,
  List<String> reasons = const <String>[],
}) {
  return showOutcomeInfoDialog(
    context,
    title: 'Falha ao reconstruir',
    message: message,
    reasons: reasons,
  );
}

void showGuidedRebuildCreatedSnackBar(BuildContext context) {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text(
        'Criamos uma versão reconstruída em rascunho. O deck original não foi alterado.',
      ),
    ),
  );
}

void showGuidedRebuildErrorSnackBar(BuildContext context, Object error) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text('Erro ao criar reconstrução: $error'),
      backgroundColor: AppTheme.error,
    ),
  );
}

void showDeckAiErrorSnackBar(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: AppTheme.error,
    ),
  );
}
