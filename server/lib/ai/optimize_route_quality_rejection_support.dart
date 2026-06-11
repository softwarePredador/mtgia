Map<String, dynamic> buildNoSafeSwapsRejectedBody({
  required Map<String, dynamic> optimizeIntensity,
  required List<String> droppedSwaps,
  required List<String> removals,
  required List<String> additions,
}) {
  return {
    'error':
        'Nenhuma troca segura restou apos o gate de qualidade da otimizacao.',
    'quality_error': {
      'code': 'OPTIMIZE_NO_SAFE_SWAPS',
      'message':
          'As trocas sugeridas pioravam funcao, curva ou consistencia do deck.',
      'dropped_swaps': droppedSwaps,
    },
    'mode': 'optimize',
    'optimize_intensity': optimizeIntensity,
    'removals': removals,
    'additions': additions,
  };
}

Map<String, dynamic> buildQualityRejectedBody({
  required List<String> reasons,
  required Map<String, dynamic> validation,
  required List<String> removals,
  required List<String> additions,
  required Map<String, dynamic> deckAnalysis,
  required Map<String, dynamic>? postAnalysis,
  required List<String> validationWarnings,
}) {
  return {
    'error': 'A otimizacao sugerida nao passou no gate final de qualidade.',
    'quality_error': {
      'code': 'OPTIMIZE_QUALITY_REJECTED',
      'message':
          'As trocas foram recusadas porque degradam funcoes criticas ou nao atingem qualidade minima.',
      'reasons': reasons,
      'validation': validation,
    },
    'mode': 'optimize',
    'removals': removals,
    'additions': additions,
    'deck_analysis': deckAnalysis,
    'post_analysis': postAnalysis,
    'validation_warnings': validationWarnings,
  };
}
