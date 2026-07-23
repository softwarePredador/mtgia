import 'optimization_validator.dart';
import 'optimize_state_support.dart';

const _safeNoOpOptimizeOutcomes = <String>{
  'mock_non_actionable',
  'near_peak',
  'no_safe_upgrade_found',
};

const _cacheableSafeNoOpOptimizeOutcomes = <String>{
  'near_peak',
  'no_safe_upgrade_found',
};

List<String>? _recommendationNames(dynamic raw) {
  if (raw is! List) return null;
  final names = <String>[];
  for (final entry in raw) {
    if (entry is! String || entry.trim().isEmpty) return null;
    names.add(entry.trim().toLowerCase());
  }
  return names;
}

class _DetailedRecommendations {
  const _DetailedRecommendations({required this.names, required this.cardIds});

  final List<String> names;
  final List<String> cardIds;
}

_DetailedRecommendations? _detailedRecommendations(
  dynamic raw, {
  required bool requireUnitQuantity,
}) {
  if (raw is! List) return null;
  final names = <String>[];
  final cardIds = <String>[];
  for (final entry in raw) {
    if (entry is! Map) return null;
    final name = entry['name']?.toString().trim() ?? '';
    final cardId = entry['card_id']?.toString().trim() ?? '';
    final rawQuantity = entry['quantity'];
    if (name.isEmpty ||
        cardId.isEmpty ||
        rawQuantity is! int ||
        rawQuantity <= 0 ||
        (requireUnitQuantity && rawQuantity != 1)) {
      return null;
    }
    names.add(name.toLowerCase());
    cardIds.add(cardId.toLowerCase());
  }
  return _DetailedRecommendations(names: names, cardIds: cardIds);
}

bool _allUnique(List<String> values) => values.toSet().length == values.length;

bool _optionalResponseFlagsAreWellTyped(Map<String, dynamic> body) {
  for (final key in const ['is_mock', 'can_apply', 'learning_eligible']) {
    if (body.containsKey(key) && body[key] is! bool) return false;
  }
  return true;
}

bool _sameNameMultiset(List<String> left, List<String> right) {
  if (left.length != right.length) return false;
  final counts = <String, int>{};
  for (final name in left) {
    counts[name] = (counts[name] ?? 0) + 1;
  }
  for (final name in right) {
    final remaining = counts[name];
    if (remaining == null || remaining <= 0) return false;
    if (remaining == 1) {
      counts.remove(name);
    } else {
      counts[name] = remaining - 1;
    }
  }
  return counts.isEmpty;
}

/// Returns true only when an optimize response contains real, balanced swap
/// pairs in both the display lists and the apply-ready detailed lists.
bool hasActionableOptimizeSwaps(Map<String, dynamic> body) {
  final removals = _recommendationNames(body['removals']);
  final additions = _recommendationNames(body['additions']);
  final detailedRemovals = _detailedRecommendations(
    body['removals_detailed'],
    requireUnitQuantity: true,
  );
  final detailedAdditions = _detailedRecommendations(
    body['additions_detailed'],
    requireUnitQuantity: true,
  );

  if (removals == null ||
      additions == null ||
      detailedRemovals == null ||
      detailedAdditions == null ||
      removals.isEmpty ||
      removals.length != additions.length ||
      removals.length != detailedRemovals.names.length ||
      additions.length != detailedAdditions.names.length) {
    return false;
  }
  if (!_sameNameMultiset(removals, detailedRemovals.names) ||
      !_sameNameMultiset(additions, detailedAdditions.names) ||
      !_allUnique(removals) ||
      !_allUnique(additions) ||
      !_allUnique(detailedRemovals.cardIds) ||
      !_allUnique(detailedAdditions.cardIds) ||
      detailedRemovals.names
          .toSet()
          .intersection(detailedAdditions.names.toSet())
          .isNotEmpty ||
      detailedRemovals.cardIds
          .toSet()
          .intersection(detailedAdditions.cardIds.toSet())
          .isNotEmpty) {
    return false;
  }
  if (!_optionalResponseFlagsAreWellTyped(body) ||
      body['is_mock'] == true ||
      body['can_apply'] == false ||
      body['learning_eligible'] == false ||
      body.containsKey('quality_error')) {
    return false;
  }
  return true;
}

bool _hasActionableCompleteAdditions(Map<String, dynamic> body) {
  final additions = _recommendationNames(body['additions']);
  final detailedAdditions = _detailedRecommendations(
    body['additions_detailed'],
    requireUnitQuantity: false,
  );
  return additions != null &&
      detailedAdditions != null &&
      additions.isNotEmpty &&
      _sameNameMultiset(additions, detailedAdditions.names) &&
      _optionalResponseFlagsAreWellTyped(body) &&
      body['is_mock'] != true &&
      body['can_apply'] != false &&
      !body.containsKey('quality_error');
}

String _deriveSuccessfulOptimizeOutcome(Map<String, dynamic> body) {
  final mode = body['mode']?.toString().trim().toLowerCase() ?? 'optimize';
  final explicitOutcome =
      body['outcome_code']?.toString().trim().toLowerCase() ?? '';

  if (mode == 'rebuild_guided') return 'rebuild_guided';
  if (_safeNoOpOptimizeOutcomes.contains(explicitOutcome)) {
    return explicitOutcome;
  }
  if (mode == 'complete') {
    return _hasActionableCompleteAdditions(body)
        ? 'deck_completed'
        : 'no_safe_upgrade_found';
  }
  return hasActionableOptimizeSwaps(body)
      ? 'optimized'
      : 'no_safe_upgrade_found';
}

/// Normalizes a successful response before it can be cached, returned, or fed
/// into learning. An empty/malformed 2xx response is an explicit safe no-op.
void enforceSuccessfulOptimizeOutcomeSafety(Map<String, dynamic> body) {
  final outcome = _deriveSuccessfulOptimizeOutcome(body);
  body['outcome_code'] = outcome;
  if (outcome != 'optimized' && outcome != 'deck_completed') {
    body['can_apply'] = false;
    body['learning_eligible'] = false;
  }
}

/// Failed optimize responses are diagnostic only. They must never become an
/// apply preview or enter the learned-deck feedback path.
void enforceFailedOptimizeOutcomeSafety(Map<String, dynamic> body) {
  body['can_apply'] = false;
  body['learning_eligible'] = false;
}

/// Cached optimize payloads must already carry explicit outcome/provenance.
/// This deliberately rejects legacy empty payloads instead of promoting them
/// to `optimized` during cache hydration.
bool isReusableCachedOptimizeResponse(
  Map<String, dynamic> body, {
  required String effectiveMode,
}) {
  final rawOutcome = body['outcome_code'];
  final rawStrategySource = body['strategy_source'];
  if (rawOutcome is! String || rawStrategySource is! String) return false;
  final explicitOutcome = rawOutcome.trim().toLowerCase();
  final strategySource = rawStrategySource.trim();
  if (explicitOutcome.isEmpty || strategySource.isEmpty) return false;

  final mode =
      body['mode']?.toString().trim().toLowerCase() ??
      effectiveMode.trim().toLowerCase();
  if (mode == 'complete') {
    return explicitOutcome == 'deck_completed' &&
        _hasActionableCompleteAdditions(body);
  }
  if (mode != 'optimize') return false;
  if (explicitOutcome == 'optimized') {
    return hasActionableOptimizeSwaps(body);
  }
  return _cacheableSafeNoOpOptimizeOutcomes.contains(explicitOutcome) &&
      _optionalResponseFlagsAreWellTyped(body) &&
      body['is_mock'] != true &&
      body['can_apply'] == false &&
      body['learning_eligible'] == false;
}

String deriveOptimizeOutcomeCode({
  required int statusCode,
  required Map<String, dynamic> body,
  required DeckOptimizationStateResult deckState,
  ValidationReport? validationReport,
}) {
  if (statusCode >= 200 && statusCode < 300) {
    return _deriveSuccessfulOptimizeOutcome(body);
  }

  final qualityError =
      body['quality_error'] is Map
          ? (body['quality_error'] as Map).cast<String, dynamic>()
          : null;
  final qualityCode = qualityError?['code']?.toString() ?? '';
  final validation =
      qualityError?['validation'] is Map
          ? (qualityError?['validation'] as Map).cast<String, dynamic>()
          : const <String, dynamic>{};
  final healthScore =
      validationReport?.healthScore ??
      (validation['deck_health_score'] as num?)?.toInt();
  final improvementScore =
      validationReport?.improvementScore ??
      (validation['improvement_score'] as num?)?.toInt();

  switch (qualityCode) {
    case 'OPTIMIZE_NEEDS_REPAIR':
      return 'needs_repair';
    case 'OPTIMIZE_NO_SAFE_SWAPS':
    case 'OPTIMIZE_NO_ACTIONABLE_SWAPS':
      return deckState.status == 'needs_repair'
          ? 'needs_repair'
          : 'no_safe_upgrade_found';
    case 'OPTIMIZE_QUALITY_REJECTED':
    case 'OPTIMIZE_SEMANTIC_V2_REJECTED':
      if (deckState.status == 'needs_repair' ||
          (healthScore != null && healthScore < 45)) {
        return 'needs_repair';
      }
      if (healthScore != null &&
          healthScore >= 80 &&
          improvementScore != null &&
          improvementScore < 35) {
        return 'near_peak';
      }
      return 'no_safe_upgrade_found';
    case 'OPTIMIZE_EXECUTION_FAILED':
    case 'OPTIMIZE_VALIDATION_FAILED':
    case 'OPTIMIZE_POST_ANALYSIS_FAILED':
      if (deckState.status == 'needs_repair') {
        return 'needs_repair';
      }
      if (deckState.status == 'healthy') {
        return 'no_safe_upgrade_found';
      }
      return 'execution_failed';
    default:
      return statusCode >= 500 ? 'execution_failed' : 'blocked';
  }
}
