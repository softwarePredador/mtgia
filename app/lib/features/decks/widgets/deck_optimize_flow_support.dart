import 'dart:convert';

import '../providers/deck_provider_support.dart';
import 'deck_optimize_ui_support.dart';

enum DeckAiFailureKind { needsRepair, nearPeak, noSafeUpgradeFound, generic }

enum OptimizeApplyMode { none, addBulk, applyWithIds, applyByNames }

class DeckAiFailurePresentation {
  final DeckAiFailureKind kind;
  final String title;
  final String message;
  final List<String> reasons;

  const DeckAiFailurePresentation({
    required this.kind,
    required this.title,
    required this.message,
    this.reasons = const <String>[],
  });
}

class GuidedRebuildRequest {
  final String archetype;
  final String? theme;
  final int bracket;
  final String rebuildScope;
  final String saveMode;

  const GuidedRebuildRequest({
    required this.archetype,
    required this.theme,
    required this.bracket,
    required this.rebuildScope,
    required this.saveMode,
  });
}

class GuidedRebuildOutcome {
  final String? draftDeckId;
  final bool hasSavedDraft;

  const GuidedRebuildOutcome({
    required this.draftDeckId,
    required this.hasSavedDraft,
  });
}

class OptimizeApplyPlan {
  final OptimizeApplyMode mode;
  final List<Map<String, dynamic>> bulkCards;
  final List<Map<String, dynamic>> removalsDetailed;
  final List<Map<String, dynamic>> additionsDetailed;
  final List<String> removals;
  final List<String> additions;

  const OptimizeApplyPlan({
    required this.mode,
    this.bulkCards = const <Map<String, dynamic>>[],
    this.removalsDetailed = const <Map<String, dynamic>>[],
    this.additionsDetailed = const <Map<String, dynamic>>[],
    this.removals = const <String>[],
    this.additions = const <String>[],
  });
}

typedef OptimizeAddBulkExecutor =
    Future<void> Function(String deckId, List<Map<String, dynamic>> cards);
typedef OptimizeApplyWithIdsExecutor =
    Future<void> Function(
      String deckId,
      List<Map<String, dynamic>> removalsDetailed,
      List<Map<String, dynamic>> additionsDetailed,
    );
typedef OptimizeApplyByNamesExecutor =
    Future<void> Function(
      String deckId,
      List<String> removals,
      List<String> additions,
    );
typedef GuidedRebuildExecutor =
    Future<Map<String, dynamic>> Function(
      String deckId, {
      required String archetype,
      required String? theme,
      required int bracket,
      required String rebuildScope,
      required String saveMode,
    });
typedef DeckDetailsRefreshExecutor =
    Future<void> Function(String deckId, {bool forceRefresh});
typedef DeckAiNeedsRepairHandler = Future<void> Function();
typedef DeckAiInfoPresenter =
    Future<void> Function({
      required String title,
      required String message,
      required List<String> reasons,
    });
typedef DeckAiErrorPresenter = void Function(String message);
typedef OptimizeRequestExecutor =
    Future<Map<String, dynamic>> Function(
      String deckId,
      String archetype, {
      required int bracket,
      required bool keepTheme,
      required void Function(String, int?, int?) onProgress,
    });
typedef DeckStrategyUpdateExecutor =
    Future<void> Function({
      required String deckId,
      required String archetype,
      required int bracket,
    });
typedef GuidedRebuildPreviewHandler = Future<void> Function();
typedef GuidedRebuildDraftHandler = Future<void> Function(String draftDeckId);
typedef GuidedRebuildAiErrorHandler =
    Future<void> Function(DeckAiFlowException error);
typedef GuidedRebuildErrorHandler = void Function(Object error);
typedef OptimizePreviewConfirmationPresenter =
    Future<bool?> Function(OptimizeRequestOutcome outcome);
typedef OptimizeApplyStartHandler = void Function();
typedef OptimizeNoChangesHandler = void Function();
typedef OptimizeSuccessHandler = void Function();
typedef OptimizeAiErrorHandler =
    Future<void> Function(DeckAiFlowException error);
typedef OptimizeGenericErrorHandler = void Function(Object error);
typedef GuidedRebuildLoadingHandler = void Function();
typedef GuidedRebuildCloseLoadingHandler = void Function();

class OptimizePreviewData {
  final List<String> removals;
  final List<String> additions;
  final String reasoning;
  final Map<String, dynamic> warnings;
  final Map<String, dynamic> themeInfo;
  final Map<String, dynamic> constraints;
  final String mode;
  final List<Map<String, dynamic>> additionsDetailed;
  final List<Map<String, dynamic>> removalsDetailed;
  final Map<String, dynamic> deckAnalysis;
  final Map<String, dynamic> postAnalysis;
  final Map<String, dynamic>? qualityWarning;
  final List<Map<String, dynamic>> displayRemovals;
  final List<Map<String, dynamic>> displayAdditions;

  const OptimizePreviewData({
    required this.removals,
    required this.additions,
    required this.reasoning,
    required this.warnings,
    required this.themeInfo,
    required this.constraints,
    required this.mode,
    required this.additionsDetailed,
    required this.removalsDetailed,
    required this.deckAnalysis,
    required this.postAnalysis,
    required this.qualityWarning,
    required this.displayRemovals,
    required this.displayAdditions,
  });

  bool get hasChanges => removals.isNotEmpty || additions.isNotEmpty;

  factory OptimizePreviewData.fromResult(Map<String, dynamic> result) {
    final removals = (result['removals'] as List).cast<String>();
    final additions = (result['additions'] as List).cast<String>();
    final additionsDetailed =
        (result['additions_detailed'] as List?)
            ?.whereType<Map>()
            .map((m) => m.cast<String, dynamic>())
            .toList() ??
        const <Map<String, dynamic>>[];
    final removalsDetailed =
        (result['removals_detailed'] as List?)
            ?.whereType<Map>()
            .map((m) => m.cast<String, dynamic>())
            .toList() ??
        const <Map<String, dynamic>>[];

    return OptimizePreviewData(
      removals: removals,
      additions: additions,
      reasoning: result['reasoning'] as String? ?? '',
      warnings:
          (result['warnings'] is Map)
              ? (result['warnings'] as Map).cast<String, dynamic>()
              : const <String, dynamic>{},
      themeInfo:
          (result['theme'] is Map)
              ? (result['theme'] as Map).cast<String, dynamic>()
              : const <String, dynamic>{},
      constraints:
          (result['constraints'] is Map)
              ? (result['constraints'] as Map).cast<String, dynamic>()
              : const <String, dynamic>{},
      mode: (result['mode'] as String?) ?? 'optimize',
      additionsDetailed: additionsDetailed,
      removalsDetailed: removalsDetailed,
      deckAnalysis:
          (result['deck_analysis'] as Map?)?.cast<String, dynamic>() ??
          const <String, dynamic>{},
      postAnalysis:
          (result['post_analysis'] as Map?)?.cast<String, dynamic>() ??
          const <String, dynamic>{},
      qualityWarning:
          (result['quality_warning'] is Map)
              ? (result['quality_warning'] as Map).cast<String, dynamic>()
              : null,
      displayRemovals:
          removalsDetailed.isNotEmpty
              ? removalsDetailed
              : removals.map((name) => {'name': name}).toList(),
      displayAdditions:
          additionsDetailed.isNotEmpty
              ? additionsDetailed
              : additions.map((name) => {'name': name}).toList(),
    );
  }
}

class OptimizeRequestOutcome {
  final Map<String, dynamic> result;
  final OptimizePreviewData preview;
  final OptimizeApplyPlan applyPlan;

  const OptimizeRequestOutcome({
    required this.result,
    required this.preview,
    required this.applyPlan,
  });
}

String buildOptimizeDebugJson({
  required String deckId,
  required String archetype,
  required int bracket,
  required bool keepTheme,
  required Map<String, dynamic> result,
}) {
  final debugJson = {
    'request': {
      'deck_id': deckId,
      'archetype': archetype,
      'bracket': bracket,
      'keep_theme': keepTheme,
    },
    'response': result,
  };
  return const JsonEncoder.withIndent('  ').convert(debugJson);
}

FlowProgressState buildInitialOptimizeProgressState({int totalStages = 5}) {
  return FlowProgressState(
    stage: 'Preparando análise do deck...',
    stageNumber: 0,
    totalStages: totalStages,
  );
}

Future<OptimizeRequestOutcome> requestOptimizePreview({
  required String deckId,
  required String archetype,
  required int bracket,
  required bool keepTheme,
  required OptimizeRequestExecutor executeRequest,
  required void Function(FlowProgressState) onProgressUpdate,
}) async {
  final result = await executeRequest(
    deckId,
    archetype,
    bracket: bracket,
    keepTheme: keepTheme,
    onProgress: (stage, stageNumber, totalStages) {
      onProgressUpdate(
        FlowProgressState(
          stage: stage,
          stageNumber: stageNumber ?? 0,
          totalStages: totalStages ?? 0,
        ),
      );
    },
  );

  final preview = OptimizePreviewData.fromResult(result);
  final applyPlan = buildOptimizeApplyPlan(preview);

  return OptimizeRequestOutcome(
    result: result,
    preview: preview,
    applyPlan: applyPlan,
  );
}

DeckAiFailurePresentation describeDeckAiFailure(
  DeckAiFlowException error,
  List<String> reasons,
) {
  if (error.isNeedsRepair) {
    return DeckAiFailurePresentation(
      kind: DeckAiFailureKind.needsRepair,
      title: 'Deck precisa de reconstrução',
      message: error.message,
      reasons: reasons,
    );
  }

  if (error.isNearPeak) {
    return DeckAiFailurePresentation(
      kind: DeckAiFailureKind.nearPeak,
      title: 'Deck já está bem ajustado',
      message:
          error.message.isNotEmpty
              ? error.message
              : 'O deck já está perto do pico atual e não houve upgrade seguro suficiente.',
      reasons: reasons,
    );
  }

  if (error.isNoSafeUpgradeFound) {
    return DeckAiFailurePresentation(
      kind: DeckAiFailureKind.noSafeUpgradeFound,
      title: 'Nenhuma melhoria segura encontrada',
      message:
          error.message.isNotEmpty
              ? error.message
              : 'As sugestões geradas não passaram pelo gate de segurança.',
      reasons: reasons,
    );
  }

  return DeckAiFailurePresentation(
    kind: DeckAiFailureKind.generic,
    title: 'Falha ao otimizar',
    message: error.message,
    reasons: reasons,
  );
}

GuidedRebuildRequest buildGuidedRebuildRequest({
  required DeckAiFlowException error,
  required String fallbackArchetype,
  required int selectedBracket,
}) {
  final nextAction = error.nextAction;
  final nextPayload =
      (nextAction['payload'] is Map)
          ? (nextAction['payload'] as Map).cast<String, dynamic>()
          : const <String, dynamic>{};
  final themeInfo =
      (error.payload['theme'] is Map)
          ? (error.payload['theme'] as Map).cast<String, dynamic>()
          : const <String, dynamic>{};

  return GuidedRebuildRequest(
    archetype: nextPayload['archetype']?.toString() ?? fallbackArchetype,
    theme: nextPayload['theme']?.toString() ?? themeInfo['theme']?.toString(),
    bracket: nextPayload['bracket'] as int? ?? selectedBracket,
    rebuildScope: nextPayload['rebuild_scope']?.toString() ?? 'auto',
    saveMode: nextPayload['save_mode']?.toString() ?? 'draft_clone',
  );
}

OptimizeApplyPlan buildOptimizeApplyPlan(OptimizePreviewData preview) {
  if (!preview.hasChanges) {
    return const OptimizeApplyPlan(mode: OptimizeApplyMode.none);
  }

  if (preview.mode == 'complete' && preview.additionsDetailed.isNotEmpty) {
    return OptimizeApplyPlan(
      mode: OptimizeApplyMode.addBulk,
      bulkCards:
          preview.additionsDetailed
              .where((m) => m['card_id'] != null)
              .map(
                (m) => {
                  'card_id': m['card_id'],
                  'quantity': (m['quantity'] as int?) ?? 1,
                  'is_commander': false,
                },
              )
              .toList(),
    );
  }

  if (preview.removalsDetailed.isNotEmpty ||
      preview.additionsDetailed.isNotEmpty) {
    return OptimizeApplyPlan(
      mode: OptimizeApplyMode.applyWithIds,
      removalsDetailed: preview.removalsDetailed,
      additionsDetailed: preview.additionsDetailed,
    );
  }

  return OptimizeApplyPlan(
    mode: OptimizeApplyMode.applyByNames,
    removals: preview.removals,
    additions: preview.additions,
  );
}

Future<void> executeOptimizeApplyPlan({
  required String deckId,
  required OptimizeApplyPlan plan,
  required OptimizeAddBulkExecutor addBulk,
  required OptimizeApplyWithIdsExecutor applyWithIds,
  required OptimizeApplyByNamesExecutor applyByNames,
}) async {
  switch (plan.mode) {
    case OptimizeApplyMode.none:
      return;
    case OptimizeApplyMode.addBulk:
      await addBulk(deckId, plan.bulkCards);
      return;
    case OptimizeApplyMode.applyWithIds:
      await applyWithIds(deckId, plan.removalsDetailed, plan.additionsDetailed);
      return;
    case OptimizeApplyMode.applyByNames:
      await applyByNames(deckId, plan.removals, plan.additions);
      return;
  }
}

Future<void> executeConfirmedOptimization({
  required String deckId,
  required String archetype,
  required int bracket,
  required OptimizeApplyPlan plan,
  required OptimizeAddBulkExecutor addBulk,
  required OptimizeApplyWithIdsExecutor applyWithIds,
  required OptimizeApplyByNamesExecutor applyByNames,
  required DeckStrategyUpdateExecutor updateDeckStrategy,
}) async {
  await executeOptimizeApplyPlan(
    deckId: deckId,
    plan: plan,
    addBulk: addBulk,
    applyWithIds: applyWithIds,
    applyByNames: applyByNames,
  );

  await updateDeckStrategy(
    deckId: deckId,
    archetype: archetype,
    bracket: bracket,
  );
}

Future<void> executeOptimizeFlow({
  required String deckId,
  required String archetype,
  required int bracket,
  required bool keepTheme,
  required OptimizeRequestExecutor executeRequest,
  required void Function(FlowProgressState) onProgressUpdate,
  required OptimizePreviewConfirmationPresenter confirmPreview,
  required OptimizeApplyStartHandler onApplyStart,
  required OptimizeNoChangesHandler onNoChanges,
  required OptimizeSuccessHandler onSuccess,
  required OptimizeAiErrorHandler onAiError,
  required OptimizeGenericErrorHandler onGenericError,
  required OptimizeAddBulkExecutor addBulk,
  required OptimizeApplyWithIdsExecutor applyWithIds,
  required OptimizeApplyByNamesExecutor applyByNames,
  required DeckStrategyUpdateExecutor updateDeckStrategy,
}) async {
  try {
    final optimizeOutcome = await requestOptimizePreview(
      deckId: deckId,
      archetype: archetype,
      bracket: bracket,
      keepTheme: keepTheme,
      executeRequest: executeRequest,
      onProgressUpdate: onProgressUpdate,
    );

    if (optimizeOutcome.applyPlan.mode == OptimizeApplyMode.none) {
      onNoChanges();
      return;
    }

    final confirmed = await confirmPreview(optimizeOutcome);
    if (confirmed != true) return;

    onApplyStart();

    await executeConfirmedOptimization(
      deckId: deckId,
      archetype: archetype,
      bracket: bracket,
      plan: optimizeOutcome.applyPlan,
      addBulk: addBulk,
      applyWithIds: applyWithIds,
      applyByNames: applyByNames,
      updateDeckStrategy: updateDeckStrategy,
    );

    onSuccess();
  } on DeckAiFlowException catch (error) {
    await onAiError(error);
  } catch (error) {
    onGenericError(error);
  }
}

Future<GuidedRebuildOutcome> executeGuidedRebuildRequest({
  required String deckId,
  required GuidedRebuildRequest request,
  required GuidedRebuildExecutor rebuildDeck,
  required DeckDetailsRefreshExecutor refreshDeckDetails,
}) async {
  final rebuildResult = await rebuildDeck(
    deckId,
    archetype: request.archetype,
    theme: request.theme,
    bracket: request.bracket,
    rebuildScope: request.rebuildScope,
    saveMode: request.saveMode,
  );

  final draftDeckId = rebuildResult['draft_deck_id']?.toString();
  final hasSavedDraft = draftDeckId != null && draftDeckId.isNotEmpty;

  if (hasSavedDraft) {
    await refreshDeckDetails(draftDeckId, forceRefresh: true);
  }

  return GuidedRebuildOutcome(
    draftDeckId: hasSavedDraft ? draftDeckId : null,
    hasSavedDraft: hasSavedDraft,
  );
}

Future<void> executeGuidedRebuildFlow({
  required String deckId,
  required GuidedRebuildRequest request,
  required GuidedRebuildExecutor rebuildDeck,
  required DeckDetailsRefreshExecutor refreshDeckDetails,
  required GuidedRebuildLoadingHandler onLoadingStart,
  required GuidedRebuildCloseLoadingHandler onLoadingClose,
  required GuidedRebuildPreviewHandler onPreviewOnly,
  required GuidedRebuildDraftHandler onDraftReady,
  required GuidedRebuildAiErrorHandler onAiError,
  required GuidedRebuildErrorHandler onGenericError,
}) async {
  try {
    onLoadingStart();
    final outcome = await executeGuidedRebuildRequest(
      deckId: deckId,
      request: request,
      rebuildDeck: rebuildDeck,
      refreshDeckDetails: refreshDeckDetails,
    );

    if (!outcome.hasSavedDraft || outcome.draftDeckId == null) {
      onLoadingClose();
      await onPreviewOnly();
      return;
    }

    onLoadingClose();
    await onDraftReady(outcome.draftDeckId!);
  } on DeckAiFlowException catch (error) {
    onLoadingClose();
    await onAiError(error);
  } catch (error) {
    onLoadingClose();
    onGenericError(error);
  }
}

Future<void> executeDeckAiFailureAction({
  required DeckAiFailurePresentation presentation,
  required DeckAiNeedsRepairHandler onNeedsRepair,
  required DeckAiInfoPresenter showInfo,
  required DeckAiErrorPresenter showError,
}) async {
  switch (presentation.kind) {
    case DeckAiFailureKind.needsRepair:
      await onNeedsRepair();
      return;
    case DeckAiFailureKind.nearPeak:
    case DeckAiFailureKind.noSafeUpgradeFound:
      await showInfo(
        title: presentation.title,
        message: presentation.message,
        reasons: presentation.reasons,
      );
      return;
    case DeckAiFailureKind.generic:
      showError(presentation.message);
      return;
  }
}

Future<void> executeOptimizeNeedsRepairFlow({
  required String deckId,
  required DeckAiFlowException error,
  required String fallbackArchetype,
  required int selectedBracket,
  required GuidedRebuildExecutor rebuildDeck,
  required DeckDetailsRefreshExecutor refreshDeckDetails,
  required GuidedRebuildLoadingHandler onLoadingStart,
  required GuidedRebuildCloseLoadingHandler onLoadingClose,
  required GuidedRebuildPreviewHandler onPreviewOnly,
  required GuidedRebuildDraftHandler onDraftReady,
  required GuidedRebuildAiErrorHandler onAiError,
  required GuidedRebuildErrorHandler onGenericError,
}) async {
  final rebuildRequest = buildGuidedRebuildRequest(
    error: error,
    fallbackArchetype: fallbackArchetype,
    selectedBracket: selectedBracket,
  );

  await executeGuidedRebuildFlow(
    deckId: deckId,
    request: rebuildRequest,
    rebuildDeck: rebuildDeck,
    refreshDeckDetails: refreshDeckDetails,
    onLoadingStart: onLoadingStart,
    onLoadingClose: onLoadingClose,
    onPreviewOnly: onPreviewOnly,
    onDraftReady: onDraftReady,
    onAiError: onAiError,
    onGenericError: onGenericError,
  );
}

Future<void> executeOptimizeFailureFlow({
  required String deckId,
  required DeckAiFlowException error,
  required String fallbackArchetype,
  required int selectedBracket,
  required GuidedRebuildExecutor rebuildDeck,
  required DeckDetailsRefreshExecutor refreshDeckDetails,
  required GuidedRebuildLoadingHandler onLoadingStart,
  required GuidedRebuildCloseLoadingHandler onLoadingClose,
  required GuidedRebuildPreviewHandler onPreviewOnly,
  required GuidedRebuildDraftHandler onDraftReady,
  required GuidedRebuildAiErrorHandler onRebuildAiError,
  required GuidedRebuildErrorHandler onRebuildGenericError,
  required DeckAiInfoPresenter showInfo,
  required DeckAiErrorPresenter showError,
}) async {
  final presentation = describeDeckAiFailure(
    error,
    extractDeckAiReasons(error),
  );

  await executeDeckAiFailureAction(
    presentation: presentation,
    onNeedsRepair:
        () => executeOptimizeNeedsRepairFlow(
          deckId: deckId,
          error: error,
          fallbackArchetype: fallbackArchetype,
          selectedBracket: selectedBracket,
          rebuildDeck: rebuildDeck,
          refreshDeckDetails: refreshDeckDetails,
          onLoadingStart: onLoadingStart,
          onLoadingClose: onLoadingClose,
          onPreviewOnly: onPreviewOnly,
          onDraftReady: onDraftReady,
          onAiError: onRebuildAiError,
          onGenericError: onRebuildGenericError,
        ),
    showInfo: showInfo,
    showError: showError,
  );
}
