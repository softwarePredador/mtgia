import 'dart:convert';

import 'package:crypto/crypto.dart';

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

class AggressiveCandidateQualityDiagnostics {
  final int? requestedTargetSwaps;
  final int? removalCandidates;
  final int? replacementCandidates;
  final int? pairsGenerated;
  final int? returnedSwaps;
  final Map<String, int> rejectedReasonBuckets;
  final bool lowCandidateCoverage;
  final bool safetyReducedScope;
  final bool rankedBeforeQualityGate;
  final List<String> candidateSources;

  const AggressiveCandidateQualityDiagnostics({
    required this.requestedTargetSwaps,
    required this.removalCandidates,
    required this.replacementCandidates,
    required this.pairsGenerated,
    required this.returnedSwaps,
    required this.rejectedReasonBuckets,
    required this.lowCandidateCoverage,
    required this.safetyReducedScope,
    required this.rankedBeforeQualityGate,
    required this.candidateSources,
  });

  int? get candidatesAnalyzed {
    final removalCount = removalCandidates;
    final replacementCount = replacementCandidates;
    if (removalCount == null && replacementCount == null) return null;
    return (removalCount ?? 0) + (replacementCount ?? 0);
  }

  String? get primaryRejectedBucket {
    if (rejectedReasonBuckets.isEmpty) return null;
    final entries =
        rejectedReasonBuckets.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));
    return entries.first.key;
  }

  bool get hasUserFacingSignals =>
      candidatesAnalyzed != null ||
      pairsGenerated != null ||
      returnedSwaps != null ||
      primaryRejectedBucket != null ||
      lowCandidateCoverage;

  List<String> get userFacingReasons {
    final lines = <String>[];
    final analyzed = candidatesAnalyzed;
    if (analyzed != null) {
      lines.add('Candidatos analisados: $analyzed.');
    }
    if (pairsGenerated != null) {
      lines.add('Pares avaliados: $pairsGenerated.');
    }
    if (returnedSwaps != null) {
      lines.add('Swaps seguros retornados: $returnedSwaps.');
    }
    final primary = primaryRejectedBucket;
    if (primary != null) {
      lines.add('Principal bloqueio: ${friendlyRejectedBucketLabel(primary)}.');
    }
    if (lowCandidateCoverage) {
      lines.add(
        'Faltaram candidatos seguros suficientes para este comandante e bracket.',
      );
    }
    return lines;
  }

  static AggressiveCandidateQualityDiagnostics? fromPayload(
    Map<String, dynamic> payload,
  ) {
    final sources = <Map<String, dynamic>>[
      asDynamicMap(payload['optimize_diagnostics']),
      asDynamicMap(payload['aggressive_candidate_quality']),
    ];

    final qualityError = asDynamicMap(payload['quality_error']);
    sources
      ..add(asDynamicMap(qualityError['optimize_diagnostics']))
      ..add(asDynamicMap(qualityError['aggressive_candidate_quality']));

    final qualityResponse = asDynamicMap(qualityError['response']);
    sources.add(asDynamicMap(qualityResponse['optimize_diagnostics']));

    final result = asDynamicMap(payload['result']);
    sources.add(asDynamicMap(result['optimize_diagnostics']));

    for (final source in sources) {
      final direct =
          source.containsKey('aggressive_candidate_quality')
              ? asDynamicMap(source['aggressive_candidate_quality'])
              : source;
      final parsed = fromMap(direct);
      if (parsed != null) return parsed;
    }
    return null;
  }

  static AggressiveCandidateQualityDiagnostics? fromMap(
    Map<String, dynamic> value,
  ) {
    if (value.isEmpty) return null;
    final diagnostics = AggressiveCandidateQualityDiagnostics(
      requestedTargetSwaps: _readInt(value['requested_target_swaps']),
      removalCandidates: _readInt(value['removal_candidates']),
      replacementCandidates: _readInt(value['replacement_candidates']),
      pairsGenerated: _readInt(value['pairs_generated']),
      returnedSwaps: _readInt(value['returned_swaps']),
      rejectedReasonBuckets: _readRejectedReasonBuckets(
        value['rejected_reason_buckets'],
      ),
      lowCandidateCoverage: _readBool(value['low_candidate_coverage']),
      safetyReducedScope: _readBool(value['safety_reduced_scope']),
      rankedBeforeQualityGate: _readBool(value['ranked_before_quality_gate']),
      candidateSources:
          (value['candidate_sources'] as List?)
              ?.map((entry) => entry.toString())
              .where((entry) => entry.trim().isNotEmpty)
              .toList() ??
          const <String>[],
    );
    return diagnostics.hasUserFacingSignals ? diagnostics : null;
  }
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
  final String? expectedDeckSignature;

  const OptimizeApplyPlan({
    required this.mode,
    this.bulkCards = const <Map<String, dynamic>>[],
    this.removalsDetailed = const <Map<String, dynamic>>[],
    this.additionsDetailed = const <Map<String, dynamic>>[],
    this.removals = const <String>[],
    this.additions = const <String>[],
    this.expectedDeckSignature,
  });
}

typedef OptimizeAddBulkExecutor =
    Future<bool> Function(String deckId, List<Map<String, dynamic>> cards);
typedef OptimizeApplyWithIdsExecutor =
    Future<bool> Function(
      String deckId,
      List<Map<String, dynamic>> removalsDetailed,
      List<Map<String, dynamic>> additionsDetailed, {
      String? expectedDeckSignature,
    });
typedef OptimizeApplyByNamesExecutor =
    Future<bool> Function(
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
      required OptimizeIntensity intensity,
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
    Future<OptimizeApplyPlan?> Function(OptimizeRequestOutcome outcome);
typedef OptimizeApplyStartHandler = void Function();
typedef OptimizeNoChangesHandler =
    Future<void> Function(OptimizeRequestOutcome? outcome);
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
  final Map<String, dynamic> metaReferenceContext;
  final List<Map<String, dynamic>> displayRemovals;
  final List<Map<String, dynamic>> displayAdditions;
  final OptimizeIntensity intensity;
  final Map<String, dynamic> optimizeIntensity;
  final String? outcomeCode;
  final OptimizeSwapIntegrityPayload? swapIntegrity;

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
    required this.metaReferenceContext,
    required this.displayRemovals,
    required this.displayAdditions,
    required this.intensity,
    required this.optimizeIntensity,
    required this.outcomeCode,
    required this.swapIntegrity,
  });

  bool get hasChanges => removals.isNotEmpty || additions.isNotEmpty;

  factory OptimizePreviewData.fromResult(Map<String, dynamic> result) {
    final optimizeIntensity =
        (result['optimize_intensity'] is Map)
            ? (result['optimize_intensity'] as Map).cast<String, dynamic>()
            : const <String, dynamic>{};
    final selectedIntensity =
        result['intensity']?.toString() ??
        optimizeIntensity['selected']?.toString();
    final removals =
        (result['removals'] as List?)
            ?.map((entry) => entry.toString())
            .toList() ??
        const <String>[];
    final additions =
        (result['additions'] as List?)
            ?.map((entry) => entry.toString())
            .toList() ??
        const <String>[];
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
    final swapIntegrity =
        result['swap_integrity'] is Map
            ? OptimizeSwapIntegrityPayload.fromJson(
              (result['swap_integrity'] as Map).cast<String, dynamic>(),
            )
            : null;

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
      metaReferenceContext:
          (result['meta_reference_context'] is Map)
              ? (result['meta_reference_context'] as Map)
                  .cast<String, dynamic>()
              : const <String, dynamic>{},
      displayRemovals:
          removalsDetailed.isNotEmpty
              ? removalsDetailed
              : removals.map((name) => {'name': name}).toList(),
      displayAdditions:
          additionsDetailed.isNotEmpty
              ? additionsDetailed
              : additions.map((name) => {'name': name}).toList(),
      intensity: OptimizeIntensity.fromApiValue(selectedIntensity),
      optimizeIntensity: optimizeIntensity,
      outcomeCode: result['outcome_code']?.toString(),
      swapIntegrity: swapIntegrity,
    );
  }
}

class OptimizeSwapIntegrityPayload {
  final String version;
  final String algo;
  final String hash;
  final String deckSignature;
  final int? removalCount;
  final int? additionCount;

  const OptimizeSwapIntegrityPayload({
    required this.version,
    required this.algo,
    required this.hash,
    required this.deckSignature,
    required this.removalCount,
    required this.additionCount,
  });

  factory OptimizeSwapIntegrityPayload.fromJson(Map<String, dynamic> json) {
    return OptimizeSwapIntegrityPayload(
      version: json['version']?.toString() ?? '',
      algo: json['algo']?.toString() ?? '',
      hash: json['hash']?.toString() ?? '',
      deckSignature: json['deck_signature']?.toString() ?? '',
      removalCount: (json['removal_count'] as num?)?.toInt(),
      additionCount: (json['addition_count'] as num?)?.toInt(),
    );
  }
}

class OptimizePreviewSelection {
  final Set<int> selectedRemovalIndexes;
  final Set<int> selectedAdditionIndexes;

  const OptimizePreviewSelection({
    required this.selectedRemovalIndexes,
    required this.selectedAdditionIndexes,
  });

  int get selectedCount =>
      selectedRemovalIndexes.length + selectedAdditionIndexes.length;
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

List<String> _canonicalOptimizeSwapEntries(
  List<Map<String, dynamic>> detailed,
) {
  final entries = <String>[];
  for (final item in detailed) {
    final id = (item['card_id'] ?? item['name'] ?? '').toString().trim();
    if (id.isEmpty) continue;
    final quantity = (item['quantity'] as num?)?.toInt() ?? 1;
    entries.add('$id:$quantity');
  }
  entries.sort();
  return entries;
}

String computeOptimizeSwapIntegrityHash({
  required String deckId,
  required String deckSignature,
  required List<Map<String, dynamic>> removalsDetailed,
  required List<Map<String, dynamic>> additionsDetailed,
}) {
  final canonical =
      StringBuffer()
        ..write('v1')
        ..write('|deck=')
        ..write(deckId)
        ..write('|sig=')
        ..write(deckSignature)
        ..write('|R=')
        ..write(_canonicalOptimizeSwapEntries(removalsDetailed).join(','))
        ..write('|A=')
        ..write(_canonicalOptimizeSwapEntries(additionsDetailed).join(','));
  return sha256.convert(utf8.encode(canonical.toString())).toString();
}

String? validateOptimizeSwapIntegrity({
  required String deckId,
  required OptimizePreviewData preview,
}) {
  final integrity = preview.swapIntegrity;
  if (integrity == null) return null;
  if (integrity.version != 'v1') return 'unsupported_version';
  if (integrity.algo != 'sha256') return 'unsupported_algorithm';
  if (integrity.hash.isEmpty || integrity.deckSignature.isEmpty) {
    return 'missing_integrity_fields';
  }

  final removals = _canonicalOptimizeSwapEntries(preview.removalsDetailed);
  final additions = _canonicalOptimizeSwapEntries(preview.additionsDetailed);
  if (integrity.removalCount != null &&
      integrity.removalCount != removals.length) {
    return 'removal_count_mismatch';
  }
  if (integrity.additionCount != null &&
      integrity.additionCount != additions.length) {
    return 'addition_count_mismatch';
  }

  final expectedHash = computeOptimizeSwapIntegrityHash(
    deckId: deckId,
    deckSignature: integrity.deckSignature,
    removalsDetailed: preview.removalsDetailed,
    additionsDetailed: preview.additionsDetailed,
  );
  if (expectedHash != integrity.hash) return 'hash_mismatch';
  return null;
}

String buildOptimizeDebugJson({
  required String deckId,
  required String archetype,
  required int bracket,
  required bool keepTheme,
  required OptimizeIntensity intensity,
  required Map<String, dynamic> result,
}) {
  final debugJson = {
    'request': {
      'deck_id': deckId,
      'archetype': archetype,
      'bracket': bracket,
      'keep_theme': keepTheme,
      'intensity': intensity.apiValue,
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

int? _readInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value.trim());
  if (value is Map) {
    final map = value.cast<String, dynamic>();
    return _readInt(map['max'] ?? map['target'] ?? map['value']);
  }
  return null;
}

bool _readBool(dynamic value) {
  if (value is bool) return value;
  if (value is String) return value.trim().toLowerCase() == 'true';
  if (value is num) return value != 0;
  return false;
}

Map<String, int> _readRejectedReasonBuckets(dynamic value) {
  if (value is Map) {
    final result = value.map((key, bucketValue) {
      return MapEntry(key.toString(), _readInt(bucketValue) ?? 0);
    });
    result.removeWhere((_, bucketValue) => bucketValue <= 0);
    return result;
  }
  if (value is List) {
    final counts = <String, int>{};
    for (final entry in value) {
      final key = entry.toString().trim();
      if (key.isEmpty) continue;
      counts[key] = (counts[key] ?? 0) + 1;
    }
    return counts;
  }
  return const <String, int>{};
}

String friendlyRejectedBucketLabel(String bucket) {
  return switch (bucket.trim().toLowerCase()) {
    'incomplete_card_data' => 'dados insuficientes para validar a troca',
    'role_mismatch' => 'mudança de função arriscada',
    'curve_or_role_mismatch' => 'curva ou função ficaria incoerente',
    'mana_or_land_safety' => 'risco na base de mana ou terrenos',
    'quality_gate_rejected' => 'qualidade final insuficiente',
    'scope_cap' => 'limite de mudanças da intensidade escolhida',
    _ => 'segurança do deck',
  };
}

DeckAiFailurePresentation? describeOptimizeNoChanges(
  OptimizeRequestOutcome outcome,
) {
  final diagnostics = AggressiveCandidateQualityDiagnostics.fromPayload(
    outcome.result,
  );
  if (outcome.preview.intensity != OptimizeIntensity.aggressive ||
      diagnostics == null) {
    return null;
  }

  return DeckAiFailurePresentation(
    kind: DeckAiFailureKind.noSafeUpgradeFound,
    title: 'Nenhuma melhoria segura encontrada',
    message:
        'A IA encontrou ideias, mas o gate bloqueou as inseguras para preservar seu deck.',
    reasons: diagnostics.userFacingReasons,
  );
}

Future<OptimizeRequestOutcome> requestOptimizePreview({
  required String deckId,
  required String archetype,
  required int bracket,
  required bool keepTheme,
  required OptimizeIntensity intensity,
  required OptimizeRequestExecutor executeRequest,
  required void Function(FlowProgressState) onProgressUpdate,
}) async {
  final result = await executeRequest(
    deckId,
    archetype,
    bracket: bracket,
    keepTheme: keepTheme,
    intensity: intensity,
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
  final integrityError = validateOptimizeSwapIntegrity(
    deckId: deckId,
    preview: preview,
  );
  if (integrityError != null) {
    throw DeckAiFlowException(
      message:
          'A assinatura da otimização não confere. Atualize a análise e tente novamente.',
      code: 'OPTIMIZE_SWAP_INTEGRITY_INVALID',
      outcomeCode: 'swap_integrity_invalid',
      payload: {'integrity_error': integrityError},
    );
  }
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
    final diagnostics = AggressiveCandidateQualityDiagnostics.fromPayload(
      error.payload,
    );
    final diagnosticReasons =
        diagnostics?.userFacingReasons ?? const <String>[];
    return DeckAiFailurePresentation(
      kind: DeckAiFailureKind.noSafeUpgradeFound,
      title: 'Nenhuma melhoria segura encontrada',
      message:
          diagnostics == null
              ? (error.message.isNotEmpty
                  ? error.message
                  : 'As sugestões geradas não passaram pelo gate de segurança.')
              : 'A IA encontrou ideias, mas o gate bloqueou as inseguras para preservar seu deck.',
      reasons: diagnosticReasons.isNotEmpty ? diagnosticReasons : reasons,
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

List<T> _selectByIndexes<T>(List<T> values, Set<int>? selectedIndexes) {
  if (selectedIndexes == null) return values;
  return [
    for (var index = 0; index < values.length; index++)
      if (selectedIndexes.contains(index)) values[index],
  ];
}

OptimizeApplyPlan buildOptimizeApplyPlan(
  OptimizePreviewData preview, {
  OptimizePreviewSelection? selection,
}) {
  if (!preview.hasChanges) {
    return const OptimizeApplyPlan(mode: OptimizeApplyMode.none);
  }

  final selectedAdditionsDetailed = _selectByIndexes(
    preview.additionsDetailed,
    selection?.selectedAdditionIndexes,
  );
  final selectedRemovalsDetailed = _selectByIndexes(
    preview.removalsDetailed,
    selection?.selectedRemovalIndexes,
  );
  final selectedAdditions = _selectByIndexes(
    preview.additions,
    selection?.selectedAdditionIndexes,
  );
  final selectedRemovals = _selectByIndexes(
    preview.removals,
    selection?.selectedRemovalIndexes,
  );

  final hasSelectedChanges =
      selectedAdditionsDetailed.isNotEmpty ||
      selectedRemovalsDetailed.isNotEmpty ||
      selectedAdditions.isNotEmpty ||
      selectedRemovals.isNotEmpty;
  if (!hasSelectedChanges) {
    return const OptimizeApplyPlan(mode: OptimizeApplyMode.none);
  }

  if (preview.mode == 'complete' && selectedAdditionsDetailed.isNotEmpty) {
    return OptimizeApplyPlan(
      mode: OptimizeApplyMode.addBulk,
      bulkCards:
          selectedAdditionsDetailed
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

  if (selectedRemovalsDetailed.isNotEmpty ||
      selectedAdditionsDetailed.isNotEmpty) {
    return OptimizeApplyPlan(
      mode: OptimizeApplyMode.applyWithIds,
      removalsDetailed: selectedRemovalsDetailed,
      additionsDetailed: selectedAdditionsDetailed,
      expectedDeckSignature: preview.swapIntegrity?.deckSignature,
    );
  }

  return OptimizeApplyPlan(
    mode: OptimizeApplyMode.applyByNames,
    removals: selectedRemovals,
    additions: selectedAdditions,
  );
}

Future<bool> executeOptimizeApplyPlan({
  required String deckId,
  required OptimizeApplyPlan plan,
  required OptimizeAddBulkExecutor addBulk,
  required OptimizeApplyWithIdsExecutor applyWithIds,
  required OptimizeApplyByNamesExecutor applyByNames,
}) async {
  switch (plan.mode) {
    case OptimizeApplyMode.none:
      return false;
    case OptimizeApplyMode.addBulk:
      return addBulk(deckId, plan.bulkCards);
    case OptimizeApplyMode.applyWithIds:
      return applyWithIds(
        deckId,
        plan.removalsDetailed,
        plan.additionsDetailed,
        expectedDeckSignature: plan.expectedDeckSignature,
      );
    case OptimizeApplyMode.applyByNames:
      return applyByNames(deckId, plan.removals, plan.additions);
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
  final applied = await executeOptimizeApplyPlan(
    deckId: deckId,
    plan: plan,
    addBulk: addBulk,
    applyWithIds: applyWithIds,
    applyByNames: applyByNames,
  );
  if (!applied) {
    throw Exception(
      'A otimização foi recusada pela validação final. Revise o deck antes de continuar.',
    );
  }

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
  required OptimizeIntensity intensity,
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
      intensity: intensity,
      executeRequest: executeRequest,
      onProgressUpdate: onProgressUpdate,
    );

    if (optimizeOutcome.applyPlan.mode == OptimizeApplyMode.none) {
      await onNoChanges(optimizeOutcome);
      return;
    }

    final confirmedPlan = await confirmPreview(optimizeOutcome);
    if (confirmedPlan == null) return;
    if (confirmedPlan.mode == OptimizeApplyMode.none) {
      await onNoChanges(null);
      return;
    }

    onApplyStart();

    await executeConfirmedOptimization(
      deckId: deckId,
      archetype: archetype,
      bracket: bracket,
      plan: confirmedPlan,
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
