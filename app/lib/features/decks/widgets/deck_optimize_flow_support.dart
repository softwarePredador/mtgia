import 'dart:convert';

import '../providers/deck_provider_support.dart';

enum DeckAiFailureKind {
  needsRepair,
  nearPeak,
  noSafeUpgradeFound,
  generic,
}

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
