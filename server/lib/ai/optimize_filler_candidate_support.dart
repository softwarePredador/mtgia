import '../color_identity.dart';
import 'commander_fallback_policy.dart';
import 'optimize_functional_role_support.dart';

List<T> dedupeCandidatesByName<T extends Map<String, Object?>>(List<T> input) {
  final seen = <String>{};
  final output = <T>[];
  for (final item in input) {
    final rawName = item['name'];
    final name = (rawName is String ? rawName : '').trim().toLowerCase();
    if (name.isEmpty || seen.contains(name)) continue;
    seen.add(name);
    output.add(item);
  }
  return output;
}

bool shouldKeepCommanderFillerCandidate({
  required Map<String, dynamic> candidate,
  required Set<String> excludeNames,
  Set<String> commanderColorIdentity = const <String>{},
  bool enforceCommanderIdentity = false,
}) {
  final rawName = candidate['name'];
  final name = (rawName is String ? rawName : '').trim().toLowerCase();
  if (name.isEmpty) return false;
  if (excludeNames.contains(name)) return false;
  if (commanderWeakFillerDenylist.contains(name)) return false;

  if (enforceCommanderIdentity || commanderColorIdentity.isNotEmpty) {
    final withinIdentity = isWithinCommanderIdentity(
      cardIdentity: resolvedCardIdentityFromParts(
        colorIdentity: (candidate['color_identity'] as List?)?.cast<String>(),
        colors:
            (candidate['colors'] as List?)?.cast<String>() ?? const <String>[],
        oracleText: candidate['oracle_text'] as String?,
        manaCost: candidate['mana_cost'] as String?,
      ),
      commanderIdentity: commanderColorIdentity,
    );
    if (!withinIdentity) return false;
  }

  return true;
}

double safeToDouble(dynamic value, [double fallback = 0.0]) {
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? fallback;
  return fallback;
}

int commanderFillerQualityScore(Map<String, dynamic> candidate) {
  final name = ((candidate['name'] as String?) ?? '').trim().toLowerCase();
  final typeLine = (candidate['type_line'] as String?) ?? '';
  final oracleText = (candidate['oracle_text'] as String?) ?? '';
  final role = inferFunctionalRole(
    name: name,
    typeLine: typeLine,
    oracleText: oracleText,
    functionalTags: candidate['functional_tags'],
    semanticTagsV2: candidate['semantic_tags_v2'],
    manaCost: candidate['mana_cost']?.toString(),
    cmc: candidate['cmc'],
  );
  final metaDeckCount = (candidate['meta_deck_count'] as num?)?.toInt() ?? 0;
  final usageCount = (candidate['usage_count'] as num?)?.toInt() ?? 0;
  final cmc = safeToDouble(candidate['cmc']);

  var score = 0;
  score += metaDeckCount * 3;
  score += usageCount ~/ 8;

  if (commanderPremiumFillerNames.contains(name)) {
    score += 160;
  }

  switch (role) {
    case 'ramp':
    case 'draw':
    case 'removal':
    case 'interaction':
    case 'wincon':
      score += 40;
    case 'engine':
      score += 15;
    case 'utility':
      score += 0;
  }

  if (cmc >= 9) {
    score -= 180;
  } else if (cmc >= 7) {
    score -= 110;
  } else if (cmc >= 6) {
    score -= 50;
  }

  if (role == 'utility' && cmc >= 6) {
    score -= 90;
  }

  final oracleLower = oracleText.toLowerCase();
  if (oracleLower.contains('each player draws')) {
    score -= 80;
  }
  if (oracleLower.contains('whenever an opponent draws')) {
    score -= 30;
  }

  return score;
}

Set<String> resolvedCardIdentity(Map<String, dynamic> card) {
  return resolvedCardIdentityFromParts(
    colorIdentity: (card['color_identity'] as List?)?.cast<String>(),
    colors: (card['colors'] as List?)?.cast<String>() ?? const <String>[],
    oracleText: card['oracle_text']?.toString(),
    manaCost: card['mana_cost']?.toString(),
  );
}

Set<String> resolvedCardIdentityFromParts({
  List<String>? colorIdentity,
  List<String> colors = const <String>[],
  String? oracleText,
  String? manaCost,
}) {
  return resolveCardColorIdentity(
    colorIdentity: colorIdentity,
    colors: colors,
    oracleText: oracleText,
    manaCost: manaCost,
  );
}

bool landProducesCommanderColors({
  required Map<String, dynamic> card,
  required Set<String> commanderColorIdentity,
}) {
  if (commanderColorIdentity.isEmpty) return false;

  final oracleText = ((card['oracle_text'] as String?) ?? '').toLowerCase();
  final colors = (card['colors'] as List?)?.cast<String>() ?? const <String>[];
  final colorIdentity =
      (card['color_identity'] as List?)?.cast<String>() ?? const <String>[];
  final detectedColors = <String>{
    ...colors.map((c) => c.toUpperCase()),
    ...colorIdentity.map((c) => c.toUpperCase()),
  };

  for (final color in commanderColorIdentity) {
    if (detectedColors.contains(color.toUpperCase())) return true;
    if (oracleText.contains('{${color.toLowerCase()}}')) return true;
  }

  if (oracleText.contains('mana of any color') ||
      oracleText.contains('mana of any type')) {
    return true;
  }

  return false;
}

bool landFixesCommanderColors({
  required Map<String, dynamic> card,
  required Set<String> commanderColorIdentity,
}) {
  if (commanderColorIdentity.isEmpty) return false;
  if (landProducesCommanderColors(
    card: card,
    commanderColorIdentity: commanderColorIdentity,
  )) {
    return true;
  }

  final oracleText = ((card['oracle_text'] as String?) ?? '').toLowerCase();
  if (oracleText.contains('search your library for a basic land') ||
      oracleText.contains('search your library for a land')) {
    return true;
  }

  const landTypesByColor = <String, String>{
    'W': 'plains',
    'U': 'island',
    'B': 'swamp',
    'R': 'mountain',
    'G': 'forest',
  };

  for (final entry in landTypesByColor.entries) {
    if (commanderColorIdentity.contains(entry.key) &&
        oracleText.contains(entry.value)) {
      return true;
    }
  }

  return false;
}
