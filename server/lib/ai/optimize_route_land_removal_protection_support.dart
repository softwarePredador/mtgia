class OptimizeLandRemovalProtectionResult {
  final List<String> removals;
  final List<String> additions;
  final int currentLandCount;
  final int projectedLandCount;
  final int blockedCount;
  final int minSafeLands;
  final bool floorSatisfied;
  final bool protectionApplied;

  const OptimizeLandRemovalProtectionResult({
    required this.removals,
    required this.additions,
    required this.currentLandCount,
    required this.projectedLandCount,
    required this.blockedCount,
    required this.minSafeLands,
    required this.floorSatisfied,
    required this.protectionApplied,
  });
}

OptimizeLandRemovalProtectionResult applyOptimizeLandRemovalProtection({
  required List<String> removals,
  required List<Map<String, dynamic>> allCardData,
  List<String> additions = const <String>[],
  List<Map<String, dynamic>> additionsCardData = const <Map<String, dynamic>>[],
  Map<String, dynamic>? profileRoleTargets,
  int commanderMinLands = 34,
}) {
  final currentLandCount = allCardData.fold<int>(0, (sum, card) {
    final type = (card['type_line']?.toString() ?? '').toLowerCase();
    if (!type.contains('land')) return sum;
    final quantity = card['quantity'];
    if (quantity is int) return sum + quantity;
    return sum + (int.tryParse(quantity?.toString() ?? '') ?? 1);
  });

  final minSafeLands = resolveOptimizeMinimumLandFloor(
    commanderMinLands: commanderMinLands,
    profileRoleTargets: profileRoleTargets,
  );
  final landNamesInDeck = _landNames(allCardData);
  final landAdditionNames = _landNames(additionsCardData);
  final requestedLandRemovals =
      removals
          .where((name) => landNamesInDeck.contains(_normalizeName(name)))
          .length;
  final requestedLandAdditions =
      additions
          .where((name) => landAdditionNames.contains(_normalizeName(name)))
          .length;
  final requestedProjectedLandCount =
      currentLandCount - requestedLandRemovals + requestedLandAdditions;

  if (requestedProjectedLandCount >= minSafeLands) {
    return OptimizeLandRemovalProtectionResult(
      removals: List<String>.of(removals),
      additions: List<String>.of(additions),
      currentLandCount: currentLandCount,
      projectedLandCount: requestedProjectedLandCount,
      blockedCount: 0,
      minSafeLands: minSafeLands,
      floorSatisfied: true,
      protectionApplied: false,
    );
  }

  var landRemovalsToBlock =
      (minSafeLands - requestedProjectedLandCount)
          .clamp(0, requestedLandRemovals)
          .toInt();
  final blockedIndexes = <int>{};
  for (
    var index = removals.length - 1;
    index >= 0 && landRemovalsToBlock > 0;
    index--
  ) {
    final removesLand = landNamesInDeck.contains(
      _normalizeName(removals[index]),
    );
    final pairedAdditionIsLand =
        index < additions.length &&
        landAdditionNames.contains(_normalizeName(additions[index]));
    if (!removesLand || pairedAdditionIsLand) continue;
    blockedIndexes.add(index);
    landRemovalsToBlock--;
  }
  final filteredRemovals = <String>[
    for (var index = 0; index < removals.length; index++)
      if (!blockedIndexes.contains(index)) removals[index],
  ];
  final filteredAdditions = <String>[
    for (var index = 0; index < additions.length; index++)
      if (!blockedIndexes.contains(index)) additions[index],
  ];
  final blockedCount = blockedIndexes.length;
  final projectedLandCount = requestedProjectedLandCount + blockedCount;
  final floorSatisfied = projectedLandCount >= minSafeLands;

  if (!floorSatisfied) {
    return OptimizeLandRemovalProtectionResult(
      removals: const <String>[],
      additions: const <String>[],
      currentLandCount: currentLandCount,
      projectedLandCount: currentLandCount,
      blockedCount: blockedCount,
      minSafeLands: minSafeLands,
      floorSatisfied: false,
      protectionApplied: removals.isNotEmpty || additions.isNotEmpty,
    );
  }

  return OptimizeLandRemovalProtectionResult(
    removals: filteredRemovals,
    additions: filteredAdditions,
    currentLandCount: currentLandCount,
    projectedLandCount: projectedLandCount,
    blockedCount: blockedCount,
    minSafeLands: minSafeLands,
    floorSatisfied: true,
    protectionApplied: blockedCount > 0,
  );
}

int resolveOptimizeMinimumLandFloor({
  Map<String, dynamic>? profileRoleTargets,
  int commanderMinLands = 34,
}) {
  var floor = commanderMinLands < 34 ? 34 : commanderMinLands;
  if (profileRoleTargets == null) return floor;

  for (final entry in profileRoleTargets.entries) {
    final key = entry.key.trim().toLowerCase().replaceAll(
      RegExp(r'[^a-z0-9]+'),
      '_',
    );
    if (key != 'land' && key != 'lands') continue;
    final value = entry.value;
    int? profileFloor;
    if (value is num) {
      profileFloor = value.round();
    } else if (value is String) {
      profileFloor = int.tryParse(value.trim());
    } else if (value is Map) {
      final rawMin = value['min'] ?? value['MIN'];
      if (rawMin is num) {
        profileFloor = rawMin.round();
      } else if (rawMin is String) {
        profileFloor = int.tryParse(rawMin.trim());
      }
    }
    if (profileFloor != null && profileFloor > floor) floor = profileFloor;
  }
  return floor;
}

Set<String> _landNames(List<Map<String, dynamic>> cards) =>
    cards
        .where(
          (card) => (card['type_line']?.toString() ?? '')
              .toLowerCase()
              .contains('land'),
        )
        .map((card) => _normalizeName(card['name']?.toString() ?? ''))
        .where((name) => name.isNotEmpty)
        .toSet();

String _normalizeName(String value) => value.trim().toLowerCase();
