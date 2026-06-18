import 'optimization_validator.dart';
import 'optimize_state_support.dart';

String deriveOptimizeOutcomeCode({
  required int statusCode,
  required Map<String, dynamic> body,
  required DeckOptimizationStateResult deckState,
  ValidationReport? validationReport,
}) {
  if (statusCode >= 200 && statusCode < 300) {
    final mode = body['mode']?.toString() ?? 'optimize';
    if (mode == 'rebuild_guided') return 'rebuild_guided';
    return mode == 'complete' ? 'deck_completed' : 'optimized';
  }

  final qualityError = body['quality_error'] is Map
      ? (body['quality_error'] as Map).cast<String, dynamic>()
      : null;
  final qualityCode = qualityError?['code']?.toString() ?? '';
  final validation = qualityError?['validation'] is Map
      ? (qualityError?['validation'] as Map).cast<String, dynamic>()
      : const <String, dynamic>{};
  final healthScore = validationReport?.healthScore ??
      (validation['deck_health_score'] as num?)?.toInt();
  final improvementScore = validationReport?.improvementScore ??
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
