Map<String, dynamic> buildOptimizeWarnings({
  required List<String> invalidCards,
  required Map<String, List<String>> suggestions,
  required List<String> filteredByColorIdentity,
  required Set<String> commanderColorIdentity,
  required List<Map<String, dynamic>> blockedByBracket,
  required int? bracket,
  required List<String> blockedByTheme,
  required bool keepTheme,
  required String? emptySuggestionFallbackReason,
  required bool recognizedSuggestionFormat,
  required bool emptySuggestionFallbackApplied,
}) {
  final warnings = <String, dynamic>{};

  if (invalidCards.isNotEmpty) {
    warnings.addAll({
      'invalid_cards': invalidCards,
      'message':
          'Algumas cartas sugeridas pela IA não foram encontradas e foram removidas',
      'suggestions': suggestions,
    });
  }

  if (filteredByColorIdentity.isNotEmpty) {
    warnings['filtered_by_color_identity'] = {
      'commander_identity': commanderColorIdentity.toList(),
      'removed_additions': filteredByColorIdentity,
      'message':
          'Algumas adições sugeridas pela IA foram removidas por estarem fora da identidade de cor do comandante.',
    };
  }

  if (blockedByBracket.isNotEmpty) {
    warnings['blocked_by_bracket'] = {
      'bracket': bracket,
      'blocked_additions': blockedByBracket,
      'message':
          'Algumas adições sugeridas foram bloqueadas por exceder limites do bracket.',
    };
  }

  if (blockedByTheme.isNotEmpty) {
    warnings['blocked_by_theme'] = {
      'keep_theme': keepTheme,
      'blocked_removals': blockedByTheme,
      'message':
          'Algumas remoções sugeridas foram bloqueadas para preservar o tema do deck.',
    };
  }

  if (emptySuggestionFallbackReason != null) {
    warnings['empty_suggestions_handling'] = {
      'recognized_format': recognizedSuggestionFormat,
      'fallback_applied': emptySuggestionFallbackApplied,
      'message': emptySuggestionFallbackReason,
    };
  }

  return warnings;
}
