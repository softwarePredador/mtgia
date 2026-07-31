import 'optimize_runtime_support.dart';
import 'optimize_route_outcome_support.dart';
import 'optimize_state_support.dart';

int countOptimizeResponseSwaps({
  required Map<String, dynamic> responseBody,
  required String effectiveMode,
}) {
  final mode = responseBody['mode']?.toString() ?? effectiveMode;
  if (mode == 'complete') {
    final detailed = responseBody['additions_detailed'];
    if (detailed is List) {
      return countOptimizeDetailedPhysicalCards(detailed);
    }
    return (responseBody['additions'] as List?)?.length ?? 0;
  }
  final removalsCount = (responseBody['removals'] as List?)?.length ?? 0;
  final additionsCount = (responseBody['additions'] as List?)?.length ?? 0;
  return removalsCount < additionsCount ? removalsCount : additionsCount;
}

int countOptimizeDetailedPhysicalCards(Iterable<dynamic> detailed) {
  var total = 0;
  for (final raw in detailed) {
    if (raw is! Map) {
      total += 1;
      continue;
    }
    final rawQuantity = raw['quantity'];
    final quantity = switch (rawQuantity) {
      null => 1,
      int value => value,
      num value when value == value.roundToDouble() => value.toInt(),
      String value => int.tryParse(value.trim()),
      _ => null,
    };
    if (quantity != null && quantity > 0) {
      total += quantity;
    }
  }
  return total;
}

Map<String, dynamic>? buildCachedOptimizeResponse({
  required Map<String, dynamic> cachedResponse,
  required String cacheKey,
  required OptimizeIntensityConfig intensity,
  required String effectiveMode,
  required Map<String, dynamic> timings,
  required bool hasBracketOverride,
  required bool hasKeepThemeOverride,
  required bool keepTheme,
  required Map<String, dynamic> userPreferences,
  int? bracket,
}) {
  if (!isReusableCachedOptimizeResponse(
    cachedResponse,
    effectiveMode: effectiveMode,
  )) {
    return null;
  }
  if (bracket != null) {
    final rawBracketPolicy = cachedResponse['bracket_policy'];
    if (rawBracketPolicy is! Map) return null;
    final bracketPolicy = rawBracketPolicy.cast<String, dynamic>();
    final cachedBracket = switch (bracketPolicy['bracket']) {
      int value => value,
      num value => value.toInt(),
      String value => int.tryParse(value.trim()),
      _ => null,
    };
    if (cachedBracket != bracket || bracketPolicy['hard_compliant'] != true) {
      return null;
    }
    final actionableOptimize =
        effectiveMode == 'optimize' &&
        cachedResponse['outcome_code'] == 'optimized' &&
        cachedResponse['can_apply'] != false;
    if (actionableOptimize &&
        !isSatisfiedReusableFunctionalRolePolicy(
          cachedResponse['functional_role_policy'],
          expectedBracket: bracket,
        )) {
      return null;
    }
  }
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

bool isSatisfiedReusableFunctionalRolePolicy(
  Object? raw, {
  int? expectedBracket,
}) {
  if (raw is! Map) return false;
  final policy = raw.cast<Object?, Object?>();
  final policyBracket = _readOptimizePolicyInt(policy['bracket']);
  final archetype = policy['archetype']?.toString().trim().toLowerCase() ?? '';
  if (policy['policy'] != commanderFunctionalRoleFloorPolicyVersion ||
      archetype.isEmpty ||
      policyBracket == null ||
      (expectedBracket != null && policyBracket != expectedBracket) ||
      policy['applies'] != true ||
      policy['satisfied'] != true ||
      (_readOptimizePolicyInt(policy['total_cards']) ?? 0) < 90) {
    return false;
  }
  final minimumCounts = _readOptimizePolicyCounts(policy['minimum_counts']);
  final actualCounts = _readOptimizePolicyCounts(policy['actual_counts']);
  final deficits = _readOptimizePolicyCounts(policy['deficits']);
  if (!hasCanonicalCommanderFunctionalRoleMinimumCounts(
        counts: minimumCounts,
        targetArchetype: archetype,
        bracket: policyBracket,
      ) ||
      deficits.isNotEmpty) {
    return false;
  }
  for (final entry in minimumCounts.entries) {
    if ((actualCounts[entry.key] ?? -1) < entry.value) return false;
  }
  return true;
}

Map<String, int> _readOptimizePolicyCounts(Object? raw) {
  if (raw is! Map) return const <String, int>{};
  final counts = <String, int>{};
  for (final entry in raw.entries) {
    final key = entry.key.toString().trim().toLowerCase();
    final value = _readOptimizePolicyInt(entry.value);
    if (key.isNotEmpty && value != null && value >= 0) {
      counts[key] = value;
    }
  }
  return counts;
}

int? _readOptimizePolicyInt(Object? raw) => switch (raw) {
  int value => value,
  num value => value.toInt(),
  String value => int.tryParse(value.trim()),
  _ => null,
};

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

Map<String, dynamic> buildOptimizeStructuralRebuildGuidedOutcome({
  required String explanation,
  required String trigger,
  required String policyKey,
  required Map<String, dynamic> policy,
  required String applyBlocker,
  required OptimizeIntensityConfig intensity,
  required DeckOptimizationStateResult deckState,
  required String deckId,
  required int? bracket,
  required String archetype,
  required DeckThemeProfileResult themeProfile,
  required Map<String, dynamic> deckAnalysis,
}) {
  final response = buildOptimizeRebuildGuidedOutcome(
    explanation: explanation,
    trigger: trigger,
    qualityCode: 'OPTIMIZE_NEEDS_REPAIR',
    intensity: intensity,
    deckState: deckState,
    deckId: deckId,
    bracket: bracket,
    archetype: archetype,
    themeProfile: themeProfile,
    deckAnalysis: deckAnalysis,
  );
  final qualityError =
      (response['quality_error'] as Map).cast<String, dynamic>();
  qualityError[policyKey] = policy;
  final nextAction = (response['next_action'] as Map).cast<String, dynamic>();
  final nextActionPayload =
      (nextAction['payload'] as Map).cast<String, dynamic>();
  if (policyKey == 'bracket_policy') {
    nextActionPayload['rebuild_scope'] = 'full_non_commander_rebuild';
  }
  nextAction['payload'] = nextActionPayload;
  response
    ..['error'] = explanation
    ..['quality_error'] = qualityError
    ..['next_action'] = nextAction
    ..[policyKey] = policy
    ..['deck_state'] = {
      ...deckState.toJson(),
      'status': 'needs_repair',
      'recommended_mode': 'rebuild_guided',
      'suggested_scope': 'structural_rebuild',
      'severity_score':
          deckState.severityScore < 70 ? 70 : deckState.severityScore,
      'reasons': {...deckState.reasons, trigger}.toList(growable: false),
      'repair_plan': {
        ...deckState.repairPlan,
        'structural_trigger': trigger,
        policyKey: policy,
      },
    }
    ..['can_apply'] = false
    ..['learning_eligible'] = false
    ..['apply_blockers'] = [applyBlocker];
  return response;
}
