import '../card_validation_service.dart';

class OptimizeInitialSuggestionFilterResult {
  final List<String> removals;
  final List<String> additions;
  final List<String> blockedByTheme;

  const OptimizeInitialSuggestionFilterResult({
    required this.removals,
    required this.additions,
    required this.blockedByTheme,
  });
}

OptimizeInitialSuggestionFilterResult buildInitialOptimizeSuggestionFilters({
  required List<String> removals,
  required List<String> additions,
  required Set<String> deckNamesLower,
  required Set<String> commanderLower,
  required Set<String> coreLower,
  required bool keepTheme,
  required bool isComplete,
}) {
  var filteredRemovals = List<String>.of(removals);
  var filteredAdditions = List<String>.of(additions);

  if (!isComplete) {
    final minCount = filteredRemovals.length < filteredAdditions.length
        ? filteredRemovals.length
        : filteredAdditions.length;
    filteredRemovals = filteredRemovals.take(minCount).toList();
    filteredAdditions = filteredAdditions.take(minCount).toList();
  }

  filteredRemovals =
      filteredRemovals.map(CardValidationService.sanitizeCardName).toList();
  filteredAdditions =
      filteredAdditions.map(CardValidationService.sanitizeCardName).toList();

  filteredRemovals = filteredRemovals
      .where((name) => deckNamesLower.contains(name.toLowerCase()))
      .toList();

  filteredRemovals = filteredRemovals
      .where((name) => !commanderLower.contains(name.toLowerCase()))
      .toList();

  final blockedByTheme = <String>[];
  if (keepTheme) {
    filteredRemovals = filteredRemovals.where((name) {
      final isCore = coreLower.contains(name.toLowerCase());
      if (isCore) blockedByTheme.add(name);
      return !isCore;
    }).toList();
  }

  if (!isComplete) {
    filteredAdditions = filteredAdditions
        .where((name) => !deckNamesLower.contains(name.toLowerCase()))
        .toList();
  }

  if (!isComplete) {
    final minCount = filteredRemovals.length < filteredAdditions.length
        ? filteredRemovals.length
        : filteredAdditions.length;
    filteredRemovals = filteredRemovals.take(minCount).toList();
    filteredAdditions = filteredAdditions.take(minCount).toList();
  }

  return OptimizeInitialSuggestionFilterResult(
    removals: filteredRemovals,
    additions: filteredAdditions,
    blockedByTheme: blockedByTheme,
  );
}
