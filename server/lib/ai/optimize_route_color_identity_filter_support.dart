import '../color_identity.dart';

class OptimizeColorIdentityFilterResult {
  final List<String> additions;
  final List<String> filteredByColorIdentity;

  const OptimizeColorIdentityFilterResult({
    required this.additions,
    required this.filteredByColorIdentity,
  });
}

OptimizeColorIdentityFilterResult filterOptimizeAdditionsByCommanderIdentity({
  required List<String> validAdditions,
  required Map<String, List<String>> identityByName,
  required Set<String> commanderColorIdentity,
}) {
  final allowed = <String>[];
  final filtered = <String>[];

  for (final name in validAdditions) {
    final identity = identityByName[name.toLowerCase()] ?? const <String>[];
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
  );
}
