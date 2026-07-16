import '../basic_land_utils.dart' as basic_lands;

class EmptySuggestionFallbackApplication {
  final List<String> removals;
  final List<String> additions;
  final int replacementCount;
  final int pairCount;
  final bool applied;
  final String? successReason;

  const EmptySuggestionFallbackApplication({
    required this.removals,
    required this.additions,
    required this.replacementCount,
    required this.pairCount,
    required this.applied,
    required this.successReason,
  });
}

List<String> selectEmptySuggestionFallbackRemovalCandidates({
  required List<Map<String, dynamic>> allCardData,
  required Set<String> commanderLower,
  required Set<String> coreLower,
  int maxCandidates = 2,
}) {
  final candidates = <String>[];
  final seenLower = <String>{};

  void collectCandidates({required bool preferNonLand}) {
    for (final card in allCardData) {
      if (candidates.length >= maxCandidates) return;

      final name = ((card['name'] as String?) ?? '').trim();
      if (name.isEmpty) continue;

      final lower = name.toLowerCase();
      if (seenLower.contains(lower)) continue;
      if (commanderLower.contains(lower)) continue;
      if (coreLower.contains(lower)) continue;

      final typeLine = ((card['type_line'] as String?) ?? '').toLowerCase();
      final isLand = basic_lands.isLandTypeLine(typeLine);
      if (preferNonLand && isLand) continue;

      seenLower.add(lower);
      candidates.add(name);
    }
  }

  collectCandidates(preferNonLand: true);
  if (candidates.isEmpty) {
    collectCandidates(preferNonLand: false);
  }

  return candidates;
}

EmptySuggestionFallbackApplication buildEmptySuggestionFallbackApplication({
  required List<String> removalCandidates,
  required List<Map<String, dynamic>> replacements,
}) {
  final fallbackAdditions =
      replacements
          .map((replacement) => (replacement['name'] as String?)?.trim() ?? '')
          .where((name) => name.isNotEmpty)
          .toList();

  final pairCount =
      removalCandidates.length < fallbackAdditions.length
          ? removalCandidates.length
          : fallbackAdditions.length;

  if (pairCount <= 0) {
    return EmptySuggestionFallbackApplication(
      removals: const [],
      additions: const [],
      replacementCount: replacements.length,
      pairCount: 0,
      applied: false,
      successReason: null,
    );
  }

  return EmptySuggestionFallbackApplication(
    removals: removalCandidates.take(pairCount).toList(),
    additions: fallbackAdditions.take(pairCount).toList(),
    replacementCount: replacements.length,
    pairCount: pairCount,
    applied: true,
    successReason:
        'IA retornou sugestões vazias; aplicado fallback heurístico orientado a sinergia.',
  );
}

String buildEmptySuggestionFallbackFailureReason({
  required bool hasRemovalCandidates,
  required int replacementCount,
}) {
  if (!hasRemovalCandidates) {
    return 'IA retornou sugestões vazias e o deck não possui candidatas seguras para remoção.';
  }
  if (replacementCount == 0) {
    return 'IA retornou sugestões vazias e não foi possível encontrar substitutas válidas no fallback.';
  }
  return 'IA retornou sugestões vazias e não foi possível gerar fallback seguro.';
}
