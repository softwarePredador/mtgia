class OptimizeCompleteTopUpSeed {
  final Map<String, int> countsByName;
  final int missing;
  final List<String> basicNames;

  const OptimizeCompleteTopUpSeed({
    required this.countsByName,
    required this.missing,
    required this.basicNames,
  });
}

class OptimizeCompleteTopUpResult {
  final List<String> additions;
  final List<Map<String, dynamic>> additionsDetailed;

  const OptimizeCompleteTopUpResult({
    required this.additions,
    required this.additionsDetailed,
  });
}

OptimizeCompleteTopUpSeed buildOptimizeCompleteTopUpSeed({
  required List<String> validAdditions,
  required int desired,
  required List<String> basicNames,
  required String deckFormat,
}) {
  final countsByName = <String, int>{};
  final basicNamesLower = basicNames.map((e) => e.toLowerCase()).toSet();
  final normalizedFormat = deckFormat.toLowerCase();
  final isSingletonFormat =
      normalizedFormat == 'commander' || normalizedFormat == 'brawl';

  for (final name in validAdditions) {
    final lower = name.toLowerCase();
    final current = countsByName[name] ?? 0;
    final isBasic = basicNamesLower.contains(lower) || lower == 'wastes';
    if (!isBasic && isSingletonFormat && current >= 1) {
      continue;
    }
    countsByName[name] = current + 1;
  }

  final currentTotal = countsByName.values.fold<int>(0, (a, b) => a + b);
  final missing = desired - currentTotal;

  return OptimizeCompleteTopUpSeed(
    countsByName: countsByName,
    missing: missing > 0 ? missing : 0,
    basicNames: basicNames,
  );
}

OptimizeCompleteTopUpResult buildOptimizeCompleteTopUpResult({
  required OptimizeCompleteTopUpSeed seed,
  required Map<String, String> basicIdsByName,
  required Map<String, Map<String, dynamic>> validByNameLower,
}) {
  final countsByName = Map<String, int>.of(seed.countsByName);
  var missing = seed.missing;

  if (missing > 0 && basicIdsByName.isNotEmpty) {
    final names = basicIdsByName.keys.toList();
    var index = 0;
    while (missing > 0) {
      final name = names[index % names.length];
      countsByName[name] = (countsByName[name] ?? 0) + 1;
      missing--;
      index++;
    }
  }

  final additionsDetailed = <Map<String, dynamic>>[];
  for (final entry in countsByName.entries) {
    final valid = validByNameLower[entry.key.toLowerCase()];
    final id = valid?['id']?.toString() ?? basicIdsByName[entry.key];
    final name = valid?['name']?.toString() ?? entry.key;
    if (id == null || id.isEmpty) continue;
    additionsDetailed.add({
      'name': name,
      'card_id': id,
      'quantity': entry.value,
    });
  }

  return OptimizeCompleteTopUpResult(
    additions: additionsDetailed.map((e) => e['name'] as String).toList(),
    additionsDetailed: additionsDetailed,
  );
}
