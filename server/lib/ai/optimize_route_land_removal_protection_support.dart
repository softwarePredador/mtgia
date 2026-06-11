class OptimizeLandRemovalProtectionResult {
  final List<String> removals;
  final int currentLandCount;
  final int blockedCount;
  final int minSafeLands;
  final bool protectionApplied;

  const OptimizeLandRemovalProtectionResult({
    required this.removals,
    required this.currentLandCount,
    required this.blockedCount,
    required this.minSafeLands,
    required this.protectionApplied,
  });
}

OptimizeLandRemovalProtectionResult applyOptimizeLandRemovalProtection({
  required List<String> removals,
  required List<Map<String, dynamic>> allCardData,
  int minSafeLands = 28,
  int safeLandBuffer = 3,
}) {
  final currentLandCount = allCardData.fold<int>(0, (sum, card) {
    final type = (card['type_line']?.toString() ?? '').toLowerCase();
    if (!type.contains('land')) return sum;
    final quantity = card['quantity'];
    if (quantity is int) return sum + quantity;
    return sum + (int.tryParse(quantity?.toString() ?? '') ?? 1);
  });

  if (currentLandCount > minSafeLands + safeLandBuffer) {
    return OptimizeLandRemovalProtectionResult(
      removals: List<String>.of(removals),
      currentLandCount: currentLandCount,
      blockedCount: 0,
      minSafeLands: minSafeLands,
      protectionApplied: false,
    );
  }

  final landNamesInDeck = <String>{};
  for (final card in allCardData) {
    final type = (card['type_line']?.toString() ?? '').toLowerCase();
    if (!type.contains('land')) continue;
    final name = card['name']?.toString().toLowerCase();
    if (name != null && name.isNotEmpty) {
      landNamesInDeck.add(name);
    }
  }

  final filteredRemovals = removals.where((name) {
    return !landNamesInDeck.contains(name.toLowerCase());
  }).toList();

  return OptimizeLandRemovalProtectionResult(
    removals: filteredRemovals,
    currentLandCount: currentLandCount,
    blockedCount: removals.length - filteredRemovals.length,
    minSafeLands: minSafeLands,
    protectionApplied: true,
  );
}
