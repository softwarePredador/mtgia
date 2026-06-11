class OptimizeRebalancePlan {
  final bool needsRebalance;
  final bool needsReplacements;
  final int missingCount;
  final Set<String> excludeNames;
  final List<String> removedButUnmatched;

  const OptimizeRebalancePlan({
    required this.needsRebalance,
    required this.needsReplacements,
    required this.missingCount,
    required this.excludeNames,
    required this.removedButUnmatched,
  });
}

class OptimizeRebalanceReplacementApplication {
  final List<String> additions;
  final Map<String, Map<String, dynamic>> validByNameLowerUpdates;
  final int addedCount;

  const OptimizeRebalanceReplacementApplication({
    required this.additions,
    required this.validByNameLowerUpdates,
    required this.addedCount,
  });
}

class OptimizeRebalanceTrimResult {
  final List<String> removals;
  final List<String> additions;
  final int truncatedRemovalsCount;
  final int truncatedAdditionsCount;

  const OptimizeRebalanceTrimResult({
    required this.removals,
    required this.additions,
    required this.truncatedRemovalsCount,
    required this.truncatedAdditionsCount,
  });
}

OptimizeRebalancePlan buildOptimizeRebalancePlan({
  required List<String> removals,
  required List<String> additions,
  required Set<String> deckNamesLower,
  required List<String> filteredByColorIdentity,
}) {
  final needsRebalance = removals.length != additions.length;
  final needsReplacements = additions.length < removals.length;
  final missingCount =
      needsReplacements ? removals.length - additions.length : 0;

  return OptimizeRebalancePlan(
    needsRebalance: needsRebalance,
    needsReplacements: needsReplacements,
    missingCount: missingCount,
    excludeNames: needsReplacements
        ? <String>{
            ...deckNamesLower,
            ...additions.map((name) => name.toLowerCase()),
            ...filteredByColorIdentity.map((name) => name.toLowerCase()),
          }
        : const <String>{},
    removedButUnmatched: needsReplacements
        ? removals.sublist(additions.length)
        : const <String>[],
  );
}

OptimizeRebalanceReplacementApplication applyOptimizeRebalanceReplacements({
  required List<String> additions,
  required List<Map<String, dynamic>> replacements,
}) {
  final nextAdditions = List<String>.of(additions);
  final updates = <String, Map<String, dynamic>>{};

  for (final replacement in replacements) {
    final name = replacement['name']?.toString();
    final id = replacement['id']?.toString();
    if (name == null || name.isEmpty || id == null || id.isEmpty) {
      continue;
    }
    nextAdditions.add(name);
    updates[name.toLowerCase()] = {
      'id': id,
      'name': name,
    };
  }

  return OptimizeRebalanceReplacementApplication(
    additions: nextAdditions,
    validByNameLowerUpdates: updates,
    addedCount: updates.length,
  );
}

OptimizeRebalanceTrimResult trimOptimizeRebalanceToPairs({
  required List<String> removals,
  required List<String> additions,
}) {
  if (additions.length < removals.length) {
    final trimmedRemovals = removals.take(additions.length).toList();
    return OptimizeRebalanceTrimResult(
      removals: trimmedRemovals,
      additions: List<String>.of(additions),
      truncatedRemovalsCount: removals.length - trimmedRemovals.length,
      truncatedAdditionsCount: 0,
    );
  }

  if (additions.length > removals.length) {
    final trimmedAdditions = additions.take(removals.length).toList();
    return OptimizeRebalanceTrimResult(
      removals: List<String>.of(removals),
      additions: trimmedAdditions,
      truncatedRemovalsCount: 0,
      truncatedAdditionsCount: additions.length - trimmedAdditions.length,
    );
  }

  return OptimizeRebalanceTrimResult(
    removals: List<String>.of(removals),
    additions: List<String>.of(additions),
    truncatedRemovalsCount: 0,
    truncatedAdditionsCount: 0,
  );
}
