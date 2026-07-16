import 'optimize_runtime_support.dart';
import 'optimize_state_support.dart';

int countOptimizeResponseSwaps({
  required Map<String, dynamic> responseBody,
  required String effectiveMode,
}) {
  final mode = responseBody['mode']?.toString() ?? effectiveMode;
  if (mode == 'complete') {
    return (responseBody['additions_detailed'] as List?)?.length ??
        (responseBody['additions'] as List?)?.length ??
        0;
  }
  final removalsCount = (responseBody['removals'] as List?)?.length ?? 0;
  final additionsCount = (responseBody['additions'] as List?)?.length ?? 0;
  return removalsCount < additionsCount ? removalsCount : additionsCount;
}

Map<String, dynamic> buildCachedOptimizeResponse({
  required Map<String, dynamic> cachedResponse,
  required String cacheKey,
  required OptimizeIntensityConfig intensity,
  required String effectiveMode,
  required Map<String, dynamic> timings,
  required bool hasBracketOverride,
  required bool hasKeepThemeOverride,
  required bool keepTheme,
  required Map<String, dynamic> userPreferences,
}) {
  final response = Map<String, dynamic>.from(cachedResponse);
  response['cache'] = {'hit': true, 'cache_key': cacheKey};
  response['intensity'] ??= intensity.selected;
  response['optimize_intensity'] ??= intensity.toJson(
    returnedSwaps: countOptimizeResponseSwaps(
      responseBody: response,
      effectiveMode: effectiveMode,
    ),
  );
  response['timings'] = timings;
  response['stage_telemetry'] = timings;
  response['preferences'] = {
    'memory_applied': !hasBracketOverride || !hasKeepThemeOverride,
    'keep_theme': keepTheme,
    'preferred_bracket': userPreferences['preferred_bracket'],
  };
  return response;
}

void mergeOptimizeReasonBuckets(
  Map<String, int> target,
  Map<String, int> source,
) {
  for (final entry in source.entries) {
    target[entry.key] = (target[entry.key] ?? 0) + entry.value;
  }
}

Map<String, dynamic> buildAggressiveCandidateQualityDiagnostics({
  required Map<String, dynamic> diagnostics,
  required Map<String, int> rejectionReasonBuckets,
  required OptimizeIntensityConfig intensity,
  int? returnedSwaps,
}) {
  final requested =
      (diagnostics['requested_target_swaps'] as int?) ?? intensity.targetMax;
  final returned = returnedSwaps ?? 0;
  final lowCoverage = diagnostics['low_candidate_coverage'] ?? false;
  return {
    'requested_target_swaps': requested,
    'removal_candidates': diagnostics['removal_candidates'] ?? 0,
    'replacement_candidates': diagnostics['replacement_candidates'] ?? 0,
    'pairs_generated': diagnostics['pairs_generated'] ?? 0,
    'rejected_reason_buckets': rejectionReasonBuckets,
    'returned_swaps': returned,
    'safety_reduced_scope':
        returned < requested || rejectionReasonBuckets.isNotEmpty,
    'low_candidate_coverage': lowCoverage,
    'ranked_before_quality_gate':
        diagnostics['ranked_before_quality_gate'] ?? false,
    'candidate_sources': diagnostics['candidate_sources'] ?? const <String>[],
    'utility_signal': buildAggressiveOptimizeUtilitySignal(
      requestedSwaps: requested,
      returnedSwaps: returned,
      rejectionBuckets: rejectionReasonBuckets,
      lowCandidateCoverage: lowCoverage == true,
    ),
  };
}

Map<String, dynamic> buildOptimizeRebuildGuidedOutcome({
  required String explanation,
  required String trigger,
  String qualityCode = 'OPTIMIZE_REBUILD_GUIDED',
  required OptimizeIntensityConfig intensity,
  required DeckOptimizationStateResult deckState,
  required String deckId,
  required int? bracket,
  required String archetype,
  required DeckThemeProfileResult themeProfile,
  required Map<String, dynamic> deckAnalysis,
}) {
  return {
    'mode': 'rebuild_guided',
    'strategy_source': 'state_gate',
    'outcome_code': 'rebuild_guided',
    'intensity': intensity.selected,
    'optimize_intensity': intensity.toJson(returnedSwaps: 0),
    'message': explanation,
    'quality_error': {
      'code': qualityCode,
      'message': explanation,
      'trigger': trigger,
      'reasons': deckState.reasons,
      'recommended_mode': deckState.recommendedMode,
      'repair_plan': deckState.repairPlan,
    },
    'next_action': {
      'type': 'rebuild_guided',
      'endpoint': '/ai/rebuild',
      'explanation':
          'Revise uma reconstrucao guiada em draft antes de aplicar ao deck original.',
      'payload': {
        'deck_id': deckId,
        'bracket': bracket,
        'archetype': archetype,
        'theme': themeProfile.theme,
        'rebuild_scope': 'auto',
        'save_mode': 'draft_clone',
      },
    },
    'deck_analysis': deckAnalysis,
    'theme': themeProfile.toJson(),
  };
}
