import 'package:postgres/postgres.dart';

import 'optimize_route_recommendation_context_support.dart';
import 'optimize_route_request_support.dart';

class OptimizeConstraintPairResult {
  const OptimizeConstraintPairResult({
    required this.removals,
    required this.additions,
    required this.droppedPairCount,
  });

  final List<String> removals;
  final List<String> additions;
  final int droppedPairCount;
}

/// Applies a filtered additions list to positional remove/add pairs without
/// assigning a surviving addition to a different removal.
OptimizeConstraintPairResult preserveOptimizePairsAfterConstraintFilter({
  required List<String> removals,
  required List<String> additions,
  required List<String> allowedAdditions,
}) {
  final allowedCounts = <String, int>{};
  for (final addition in allowedAdditions) {
    final key = addition.trim().toLowerCase();
    if (key.isEmpty) continue;
    allowedCounts[key] = (allowedCounts[key] ?? 0) + 1;
  }

  final keptRemovals = <String>[];
  final keptAdditions = <String>[];
  final pairCount =
      removals.length < additions.length ? removals.length : additions.length;
  for (var index = 0; index < pairCount; index++) {
    final addition = additions[index];
    final key = addition.trim().toLowerCase();
    final remaining = allowedCounts[key] ?? 0;
    if (remaining <= 0) continue;

    keptRemovals.add(removals[index]);
    keptAdditions.add(addition);
    if (remaining == 1) {
      allowedCounts.remove(key);
    } else {
      allowedCounts[key] = remaining - 1;
    }
  }

  return OptimizeConstraintPairResult(
    removals: keptRemovals,
    additions: keptAdditions,
    droppedPairCount: pairCount - keptAdditions.length,
  );
}

bool cachedRecommendationSelectionRequiresRecompute({
  required OptimizeRecommendationContext context,
  required bool hasSelectedAdditions,
}) {
  if (context.preferCollection == true) return true;
  return context.budgetLimitBrl != null && !hasSelectedAdditions;
}

/// Rechecks mutable price and collection truth before a cached response is
/// authorized for application. `false` means the caller must discard the hit
/// and recompute from the current PostgreSQL snapshot.
Future<bool> revalidateCachedOptimizeRecommendationConstraints({
  required Pool pool,
  required String userId,
  required Map<String, dynamic> responseBody,
  required OptimizeRecommendationContext context,
}) async {
  final constraintsRequested =
      context.preferCollection == true || context.budgetLimitBrl != null;
  if (!constraintsRequested) return true;
  if (userId.trim().isEmpty) return false;
  // The current payload only describes selected additions. It cannot prove
  // that newly free collection cards would not change a preference-based
  // ranking, so collection-sensitive hits must run the selector again.
  if (cachedRecommendationSelectionRequiresRecompute(
    context: context,
    hasSelectedAdditions: true,
  )) {
    return false;
  }

  final mode = responseBody['mode']?.toString().trim().toLowerCase() ?? '';
  if (mode == 'complete') {
    await auditCompleteRecommendationConstraints(
      pool: pool,
      userId: userId,
      responseBody: responseBody,
      context: context,
    );
    if (responseBody['quality_error'] is Map) return false;
    final diagnostics = responseBody['recommendation_constraints'];
    if (diagnostics is! Map || diagnostics['satisfied'] != true) return false;
    responseBody['recommendation_constraints'] = {
      ...diagnostics.cast<String, dynamic>(),
      'enforcement': 'complete_cache_revalidated',
      'satisfied': true,
    };
    return true;
  }

  if (mode != 'optimize') return false;
  final additions = ((responseBody['additions'] as List?) ?? const [])
      .map((entry) => entry.toString().trim())
      .where((name) => name.isNotEmpty)
      .toList(growable: false);
  // A prior no-op cannot be reaudited against cards that were excluded by old
  // prices. Recompute so a newly affordable candidate is not hidden for 6h.
  if (cachedRecommendationSelectionRequiresRecompute(
    context: context,
    hasSelectedAdditions: additions.isNotEmpty,
  )) {
    return false;
  }

  final result = await applyOptimizeRecommendationConstraints(
    pool: pool,
    userId: userId,
    validAdditions: additions,
    context: context,
  );
  return applyCachedOptimizeRecommendationConstraintResult(
    responseBody: responseBody,
    originalAdditions: additions,
    result: result,
  );
}

bool applyCachedOptimizeRecommendationConstraintResult({
  required Map<String, dynamic> responseBody,
  required List<String> originalAdditions,
  required OptimizeRecommendationConstraintResult result,
}) {
  if (!_sameNormalizedSequence(originalAdditions, result.additions)) {
    return false;
  }

  final details = result.detailsByNameLower;
  final rawDetailed = responseBody['additions_detailed'];
  if (rawDetailed is List && details.isNotEmpty) {
    responseBody['additions_detailed'] = rawDetailed
        .map((raw) {
          if (raw is! Map) return raw;
          final item = raw.cast<String, dynamic>();
          final name = item['name']?.toString().trim().toLowerCase() ?? '';
          return {...item, ...?details[name]};
        })
        .toList(growable: false);
  }

  final existingDiagnostics =
      responseBody['optimize_diagnostics'] is Map
          ? (responseBody['optimize_diagnostics'] as Map)
              .cast<String, dynamic>()
          : <String, dynamic>{};
  responseBody['optimize_diagnostics'] = {
    ...existingDiagnostics,
    'recommendation_constraints': {
      ...result.diagnostics,
      'enforcement': 'optimize_cache_revalidated',
      'satisfied': true,
    },
  };

  final warnings = <String>{
    ...((responseBody['validation_warnings'] as List?) ?? const []).map(
      (warning) => warning.toString(),
    ),
    ...result.validationWarnings,
  };
  responseBody['validation_warnings'] = warnings.toList(growable: false);
  return true;
}

Map<String, dynamic> buildUnexpectedCompleteAsyncPayloadQualityError(
  Map<String, dynamic> payload,
) {
  return {
    'code': 'COMPLETE_ASYNC_UNEXPECTED_PAYLOAD',
    'message':
        'Complete bloqueado: o pipeline assíncrono produziu um payload '
        'incompatível com a validação final.',
    'observed_mode': payload['mode']?.toString(),
    'has_additions_detailed': payload['additions_detailed'] is List,
  };
}

bool _sameNormalizedSequence(List<String> left, List<String> right) {
  if (left.length != right.length) return false;
  for (var index = 0; index < left.length; index++) {
    if (left[index].trim().toLowerCase() != right[index].trim().toLowerCase()) {
      return false;
    }
  }
  return true;
}
