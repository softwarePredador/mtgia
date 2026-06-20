import '../color_identity.dart';

class OptimizeColorIdentityFilterResult {
  final List<String> additions;
  final List<String> filteredByColorIdentity;
  final List<String> filteredByMissingIdentity;

  const OptimizeColorIdentityFilterResult({
    required this.additions,
    required this.filteredByColorIdentity,
    this.filteredByMissingIdentity = const <String>[],
  });
}

OptimizeColorIdentityFilterResult filterOptimizeAdditionsByCommanderIdentity({
  required List<String> validAdditions,
  required Map<String, List<String>> identityByName,
  required Set<String> commanderColorIdentity,
}) {
  final allowed = <String>[];
  final filtered = <String>[];
  final missingIdentity = <String>[];

  for (final name in validAdditions) {
    final normalizedName = name.toLowerCase();
    if (!identityByName.containsKey(normalizedName)) {
      missingIdentity.add(name);
      continue;
    }

    final identity = identityByName[normalizedName] ?? const <String>[];
    final ok = isWithinCommanderIdentity(
      cardIdentity: identity,
      commanderIdentity: commanderColorIdentity,
    );
    if (ok) {
      allowed.add(name);
    } else {
      filtered.add(name);
    }
  }

  return OptimizeColorIdentityFilterResult(
    additions: allowed,
    filteredByColorIdentity: filtered,
    filteredByMissingIdentity: missingIdentity,
  );
}
