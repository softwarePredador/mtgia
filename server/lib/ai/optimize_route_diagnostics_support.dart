Map<String, dynamic> buildEmptySuggestionFallbackDiagnostics({
  required bool triggered,
  required bool applied,
  required int candidateCount,
  required int replacementCount,
  required int pairCount,
  required Map<String, dynamic> aggregate,
  Map<String, dynamic>? persistedAggregate,
}) {
  return {
    'empty_suggestions_fallback': {
      'triggered': triggered,
      'applied': applied,
      'candidate_count': candidateCount,
      'replacement_count': replacementCount,
      'pair_count': pairCount,
    },
    'empty_suggestions_fallback_aggregate': aggregate,
    if (persistedAggregate != null)
      'empty_suggestions_fallback_aggregate_persisted': persistedAggregate,
  };
}

void attachOptimizeDiagnostic(
  Map<String, dynamic> responseBody, {
  required String key,
  required Object? value,
}) {
  final existingDiagnostics = responseBody['optimize_diagnostics'] is Map
      ? (responseBody['optimize_diagnostics'] as Map).cast<String, dynamic>()
      : <String, dynamic>{};

  responseBody['optimize_diagnostics'] = {
    ...existingDiagnostics,
    key: value,
  };
}
