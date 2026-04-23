import 'package:postgres/postgres.dart';
import '../color_identity.dart';
import '../edh_bracket_policy.dart';
import '../logger.dart';

String normalizeOptimizeReasoning(dynamic value) {
  if (value == null) return '';
  if (value is String) return value;
  return value.toString();
}

Map<String, dynamic> normalizeOptimizePayload(
  Map<String, dynamic> payload, {
  required String defaultMode,
}) {
  final normalized = Map<String, dynamic>.from(payload);
  normalized['mode'] = resolveOptimizeMode(normalized, defaultMode);
  normalized['reasoning'] = normalizeOptimizeReasoning(normalized['reasoning']);
  return normalized;
}

String resolveOptimizeMode(Map<String, dynamic> payload, String defaultMode) {
  final rawCandidates = [
    payload['mode'],
    payload['modde'],
    payload['type'],
    payload['operation_mode'],
    payload['strategy_mode'],
  ];

  for (final raw in rawCandidates) {
    if (raw is! String) continue;
    final normalized = raw.trim().toLowerCase();
    if (normalized.contains('complete')) return 'complete';
    if (normalized.contains('opt')) return 'optimize';
  }

  if (payload['additions_detailed'] is List) {
    final additionsDetailed = payload['additions_detailed'] as List;
    if (additionsDetailed.isNotEmpty) return 'complete';
  }

  return defaultMode;
}

Map<String, dynamic> parseOptimizeSuggestions(Map<String, dynamic> payload) {
  final removals = <String>[];
  final additions = <String>[];
  var recognizedFormat = false;

  final collections = [
    payload['swaps'],
    payload['swap'],
    payload['changes'],
    payload['suggestions'],
    payload['recommendations'],
    payload['replacements'],
  ];

  for (final collection in collections) {
    if (collection is! List) continue;
    recognizedFormat = true;
    for (final entry in collection) {
      if (entry is String) {
        final raw = entry.trim();
        if (raw.isEmpty) continue;
        final arrows = ['->', '=>', '→'];
        String? left;
        String? right;
        for (final arrow in arrows) {
          if (!raw.contains(arrow)) continue;
          final parts = raw.split(arrow);
          if (parts.length >= 2) {
            left = parts.first.trim();
            right = parts.sublist(1).join(arrow).trim();
          }
          break;
        }
        if ((left ?? '').isNotEmpty) removals.add(left!);
        if ((right ?? '').isNotEmpty) additions.add(right!);
        continue;
      }

      if (entry is! Map) continue;
      final map = entry.cast<dynamic, dynamic>();
      final nested = map['swap'] ?? map['change'] ?? map['suggestion'];
      final sourceMap = nested is Map ? nested.cast<dynamic, dynamic>() : map;

      final outRaw = sourceMap['out'] ??
          sourceMap['remove'] ??
          sourceMap['from'] ??
          map['out'] ??
          map['remove'] ??
          map['from'];
      final inRaw = sourceMap['in'] ??
          sourceMap['add'] ??
          sourceMap['to'] ??
          map['in'] ??
          map['add'] ??
          map['to'];

      final out = outRaw?.toString().trim() ?? '';
      final inCard = inRaw?.toString().trim() ?? '';

      if (out.isNotEmpty) removals.add(out);
      if (inCard.isNotEmpty) additions.add(inCard);
    }

    if (removals.isNotEmpty || additions.isNotEmpty) {
      return {
        'removals': removals,
        'additions': additions,
        'recognized_format': true,
      };
    }
  }

  final rawRemovals = payload['removals'];
  final rawAdditions = payload['additions'];

  if (rawRemovals is List) {
    recognizedFormat = true;
    removals.addAll(
        rawRemovals.map((e) => e.toString().trim()).where((e) => e.isNotEmpty));
  } else if (rawRemovals is String && rawRemovals.trim().isNotEmpty) {
    recognizedFormat = true;
    removals.add(rawRemovals.trim());
  } else if (payload.containsKey('removals')) {
    recognizedFormat = true;
  }

  if (rawAdditions is List) {
    recognizedFormat = true;
    additions.addAll(rawAdditions
        .map((e) => e.toString().trim())
        .where((e) => e.isNotEmpty));
  } else if (rawAdditions is String && rawAdditions.trim().isNotEmpty) {
    recognizedFormat = true;
    additions.add(rawAdditions.trim());
  } else if (payload.containsKey('additions')) {
    recognizedFormat = true;
  }

  return {
    'removals': removals,
    'additions': additions,
    'recognized_format': recognizedFormat,
  };
}

bool isBasicLandName(String name) => _isBasicLandName(name);

bool isBasicLandTypeLine(String typeLineLower) {
  return typeLineLower.contains('basic land') ||
      typeLineLower.contains('basic snow land');
}

int maxCopiesForFormat({
  required String deckFormat,
  required String typeLine,
  required String name,
}) {
  final normalizedFormat = deckFormat.toLowerCase();
  final normalizedType = typeLine.toLowerCase();
  final normalizedName = name.trim().toLowerCase();

  final isBasicLand =
      isBasicLandTypeLine(normalizedType) || _isBasicLandName(normalizedName);
  if (isBasicLand) return 999;

  if (normalizedFormat == 'commander' || normalizedFormat == 'brawl') {
    return 1;
  }

  return 4;
}

List<String> basicLandNamesForIdentity(Set<String> identity) {
  if (identity.isEmpty) return const ['Wastes'];
  final names = <String>[];
  if (identity.contains('W')) names.add('Plains');
  if (identity.contains('U')) names.add('Island');
  if (identity.contains('B')) names.add('Swamp');
  if (identity.contains('R')) names.add('Mountain');
  if (identity.contains('G')) names.add('Forest');
  return names.isEmpty ? const ['Wastes'] : names;
}

String basicLandNameForColor(String color) {
  switch (color.toUpperCase()) {
    case 'W':
      return 'Plains';
    case 'U':
      return 'Island';
    case 'B':
      return 'Swamp';
    case 'R':
      return 'Mountain';
    case 'G':
      return 'Forest';
    default:
      return 'Wastes';
  }
}

Future<Map<String, String>> loadBasicLandIds(
  Pool pool,
  List<String> names,
) async {
  if (names.isEmpty) return const {};
  final result = await pool.execute(
    Sql.named('''
      SELECT name, id::text
      FROM cards
      WHERE name = ANY(@names)
        AND (type_line LIKE 'Basic Land%' OR type_line LIKE 'Basic Snow Land%')
      ORDER BY name ASC
    '''),
    parameters: {'names': names},
  );
  final map = <String, String>{};
  for (final row in result) {
    final n = row[0] as String;
    final id = row[1] as String;
    map[n] = id;
  }
  return map;
}

Future<List<Map<String, dynamic>>> loadIdentitySafeNonBasicLandFillers({
  required Pool pool,
  required Set<String> commanderColorIdentity,
  required Set<String> excludeNames,
  required int limit,
}) async {
  if (limit <= 0) return const [];

  final identity = commanderColorIdentity.toList();
  final result = await pool.execute(
    Sql.named('''
      SELECT sub.id, sub.name, sub.type_line, sub.oracle_text, sub.colors, sub.color_identity, sub.pop_score
      FROM (
        SELECT DISTINCT ON (LOWER(c.name))
          c.id::text,
          c.name,
          c.type_line,
          COALESCE(c.oracle_text, '') AS oracle_text,
          COALESCE(c.colors, ARRAY[]::text[]) AS colors,
          COALESCE(c.color_identity, ARRAY[]::text[]) AS color_identity,
          COALESCE(cmi.usage_count, 0) AS pop_score
        FROM cards c
        LEFT JOIN card_legalities cl ON cl.card_id = c.id AND cl.format = 'commander'
        LEFT JOIN card_meta_insights cmi ON LOWER(cmi.card_name) = LOWER(c.name)
        WHERE (cl.status = 'legal' OR cl.status = 'restricted' OR cl.status IS NULL)
          AND c.type_line ILIKE '%land%'
          AND c.type_line NOT ILIKE 'Basic Land%'
          AND c.type_line NOT ILIKE 'Basic Snow Land%'
          AND LOWER(c.name) NOT IN (SELECT LOWER(unnest(@exclude::text[])))
          AND c.name NOT LIKE 'A-%'
          AND c.name NOT LIKE '\\_%' ESCAPE '\\'
          AND c.name NOT LIKE '%World Champion%'
          AND c.name NOT LIKE '%Heroes of the Realm%'
        ORDER BY LOWER(c.name), COALESCE(cmi.usage_count, 0) DESC
      ) sub
      ORDER BY sub.pop_score DESC, LOWER(sub.name) ASC
      LIMIT 600
    '''),
    parameters: {
      'exclude': excludeNames.toList(),
    },
  );

  const premiumLandNames = <String>{
    'city of brass',
    'command tower',
    'exotic orchard',
    'mana confluence',
    'path of ancestry',
    'reflecting pool',
  };

  final candidates = <Map<String, dynamic>>[];
  for (final row in result) {
    final candidate = <String, dynamic>{
      'id': row[0] as String,
      'name': row[1] as String,
      'type_line': (row[2] as String?) ?? '',
      'oracle_text': (row[3] as String?) ?? '',
      'colors': (row[4] as List?)?.cast<String>() ?? const <String>[],
      'color_identity': (row[5] as List?)?.cast<String>() ?? const <String>[],
      'pop_score': (row[6] as num?)?.toInt() ?? 0,
    };

    if (!shouldKeepCommanderFillerCandidate(
      candidate: candidate,
      excludeNames: excludeNames,
      commanderColorIdentity: commanderColorIdentity,
      enforceCommanderIdentity: true,
    )) {
      continue;
    }
    if (!landFixesCommanderColors(
      card: candidate,
      commanderColorIdentity: commanderColorIdentity,
    )) {
      continue;
    }

    final name = ((candidate['name'] as String?) ?? '').trim().toLowerCase();
    final oracle = ((candidate['oracle_text'] as String?) ?? '').toLowerCase();
    final typeLine = ((candidate['type_line'] as String?) ?? '').toLowerCase();
    final identityCount = resolvedCardIdentityFromParts(
      colorIdentity: (candidate['color_identity'] as List?)?.cast<String>() ??
          const <String>[],
      colors:
          (candidate['colors'] as List?)?.cast<String>() ?? const <String>[],
      oracleText: candidate['oracle_text'] as String?,
    ).length;

    var fixingScore = (candidate['pop_score'] as int?) ?? 0;
    if (premiumLandNames.contains(name)) fixingScore += 250;
    if (oracle.contains('add one mana of any color') ||
        oracle.contains('add one mana of any type')) {
      fixingScore += 200;
    }
    if (oracle.contains('{w}') ||
        oracle.contains('{u}') ||
        oracle.contains('{b}') ||
        oracle.contains('{r}') ||
        oracle.contains('{g}')) {
      fixingScore += 40 * identityCount;
    }
    if (oracle.contains('search your library for a basic land') ||
        oracle.contains('search your library for a land')) {
      fixingScore += 80;
    }
    if (typeLine.contains('land')) {
      fixingScore += 30;
    }
    if (oracle.contains('enters tapped')) {
      fixingScore -= 20;
    }

    candidates.add({
      ...candidate,
      'fixing_score': fixingScore,
    });
  }

  candidates.sort((a, b) {
    final byFixing = ((b['fixing_score'] as int?) ?? 0).compareTo(
      (a['fixing_score'] as int?) ?? 0,
    );
    if (byFixing != 0) return byFixing;
    final byPop = ((b['pop_score'] as int?) ?? 0).compareTo(
      (a['pop_score'] as int?) ?? 0,
    );
    if (byPop != 0) return byPop;
    return ((a['name'] as String?) ?? '')
        .compareTo((b['name'] as String?) ?? '');
  });

  return dedupeCandidatesByName(candidates).take(limit).toList();
}

int recommendedLandCountForOptimizeArchetype(String targetArchetype) {
  final archetype = targetArchetype.toLowerCase();
  if (archetype.contains('aggro')) return 34;
  if (archetype.contains('combo')) return 33;
  if (archetype.contains('control')) return 37;
  return 35;
}

Set<String> resolvedCardIdentity(Map<String, dynamic> card) {
  return resolvedCardIdentityFromParts(
    colorIdentity:
        (card['color_identity'] as List?)?.cast<String>() ?? const <String>[],
    colors: (card['colors'] as List?)?.cast<String>() ?? const <String>[],
    oracleText: card['oracle_text']?.toString(),
    manaCost: card['mana_cost']?.toString(),
  );
}

Set<String> resolvedCardIdentityFromParts({
  List<String> colorIdentity = const <String>[],
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

bool isOptimizeStructuralRecoveryScenario({
  required List<Map<String, dynamic>> allCardData,
  required Set<String> commanderColorIdentity,
}) {
  var totalCards = 0;
  var landCount = 0;
  var nonLandCount = 0;
  var colorProducingLandCount = 0;

  for (final card in allCardData) {
    final qty = (card['quantity'] as int?) ?? 1;
    final typeLine = ((card['type_line'] as String?) ?? '').toLowerCase();
    totalCards += qty;

    if (typeLine.contains('land')) {
      landCount += qty;
      if (landProducesCommanderColors(
        card: card,
        commanderColorIdentity: commanderColorIdentity,
      )) {
        colorProducingLandCount += qty;
      }
    } else {
      nonLandCount += qty;
    }
  }

  if (totalCards == 0) return false;

  final landRatio = landCount / totalCards;
  return landRatio >= 0.65 ||
      landCount >= 50 ||
      nonLandCount <= 20 ||
      (landCount >= 40 && colorProducingLandCount <= 8);
}

int computeOptimizeStructuralRecoverySwapTarget({
  required List<Map<String, dynamic>> allCardData,
  required Set<String> commanderColorIdentity,
  required String targetArchetype,
}) {
  if (!isOptimizeStructuralRecoveryScenario(
    allCardData: allCardData,
    commanderColorIdentity: commanderColorIdentity,
  )) {
    return 6;
  }

  var landCount = 0;
  var nonLandCount = 0;
  for (final card in allCardData) {
    final qty = (card['quantity'] as int?) ?? 1;
    final typeLine = ((card['type_line'] as String?) ?? '').toLowerCase();
    if (typeLine.contains('land')) {
      landCount += qty;
    } else {
      nonLandCount += qty;
    }
  }

  final recommendedLandCount =
      recommendedLandCountForOptimizeArchetype(targetArchetype);
  final excessLands = (landCount - recommendedLandCount).clamp(0, 99);
  final missingNonLands = (58 - nonLandCount).clamp(0, 99);

  return [12, excessLands, missingNonLands]
      .reduce((a, b) => a < b ? a : b)
      .clamp(6, 12);
}

List<String> buildStructuralRecoveryFunctionalNeeds({
  required List<Map<String, dynamic>> allCardData,
  required String targetArchetype,
  required int limit,
}) {
  if (limit <= 0) return const [];

  final archetype = targetArchetype.trim().toLowerCase();
  final targetProfile = switch (archetype) {
    'control' => const <String, int>{
        'draw': 14,
        'ramp': 12,
        'removal': 10,
        'wipe': 4,
        'protection': 4,
        'utility': 14,
      },
    'combo' => const <String, int>{
        'draw': 14,
        'ramp': 12,
        'tutor': 8,
        'protection': 6,
        'utility': 18,
      },
    'aggro' => const <String, int>{
        'creature': 18,
        'ramp': 8,
        'draw': 8,
        'removal': 8,
        'protection': 4,
        'utility': 14,
      },
    _ => const <String, int>{
        'draw': 12,
        'ramp': 10,
        'removal': 8,
        'creature': 8,
        'protection': 4,
        'utility': 16,
      },
  };

  final currentCounts = <String, int>{};
  for (final card in allCardData) {
    final qty = (card['quantity'] as int?) ?? 1;
    final typeLine = ((card['type_line'] as String?) ?? '').toLowerCase();
    if (typeLine.contains('land')) continue;

    final role = inferOptimizeFunctionalNeed(
      name: (card['name'] as String?) ?? '',
      typeLine: (card['type_line'] as String?) ?? '',
      oracleText: (card['oracle_text'] as String?) ?? '',
    );
    currentCounts[role] = (currentCounts[role] ?? 0) + qty;
  }

  final deficits = <MapEntry<String, int>>[];
  for (final entry in targetProfile.entries) {
    final deficit = entry.value - (currentCounts[entry.key] ?? 0);
    if (deficit > 0) {
      deficits.add(MapEntry(entry.key, deficit));
    }
  }

  deficits.sort((a, b) {
    final byDeficit = b.value.compareTo(a.value);
    if (byDeficit != 0) return byDeficit;
    return a.key.compareTo(b.key);
  });

  final sequence = <String>[];
  while (sequence.length < limit && deficits.isNotEmpty) {
    var addedInRound = false;
    for (var i = 0; i < deficits.length && sequence.length < limit; i++) {
      final entry = deficits[i];
      if (entry.value <= 0) continue;
      sequence.add(entry.key);
      deficits[i] = MapEntry(entry.key, entry.value - 1);
      addedInRound = true;
    }
    if (!addedInRound) break;
  }

  if (sequence.length < limit) {
    final fallbackNeed = switch (archetype) {
      'control' => 'draw',
      'combo' => 'draw',
      'aggro' => 'creature',
      _ => 'utility',
    };
    while (sequence.length < limit) {
      sequence.add(fallbackNeed);
    }
  }

  return sequence;
}

Map<String, int> buildRoleTargetProfile(String targetArchetype) {
  final archetype = targetArchetype.toLowerCase();
  final baseTargets = <String, int>{
    'ramp': 10,
    'draw': 10,
    'removal': 8,
    'interaction': 6,
    'engine': 8,
    'wincon': 4,
    'utility': 8,
  };

  if (archetype.contains('control')) {
    baseTargets['draw'] = 12;
    baseTargets['removal'] = 10;
    baseTargets['interaction'] = 8;
    baseTargets['wincon'] = 3;
  } else if (archetype.contains('aggro')) {
    baseTargets['ramp'] = 8;
    baseTargets['draw'] = 8;
    baseTargets['engine'] = 10;
    baseTargets['wincon'] = 6;
  } else if (archetype.contains('combo')) {
    baseTargets['ramp'] = 11;
    baseTargets['draw'] = 12;
    baseTargets['interaction'] = 8;
    baseTargets['wincon'] = 5;
  }

  return baseTargets;
}

Map<String, int> buildSlotNeedsForDeck({
  required List<Map<String, dynamic>> currentDeckCards,
  required String targetArchetype,
}) {
  final baseTargets = buildRoleTargetProfile(targetArchetype);

  final current = <String, int>{
    'ramp': 0,
    'draw': 0,
    'removal': 0,
    'interaction': 0,
    'engine': 0,
    'wincon': 0,
    'utility': 0,
  };

  var nonLandTotal = 0;
  for (final c in currentDeckCards) {
    final typeLine = ((c['type_line'] as String?) ?? '').toLowerCase();
    if (typeLine.contains('land')) continue;

    final qty = (c['quantity'] as int?) ?? 1;
    final role = inferFunctionalRole(
      name: (c['name'] as String?) ?? '',
      typeLine: (c['type_line'] as String?) ?? '',
      oracleText: (c['oracle_text'] as String?) ?? '',
    );
    current[role] = (current[role] ?? 0) + qty;
    nonLandTotal += qty;
  }

  final needs = <String, int>{};
  for (final entry in baseTargets.entries) {
    final deficit = entry.value - (current[entry.key] ?? 0);
    needs[entry.key] = deficit > 0 ? deficit : 0;
  }

  if (nonLandTotal < 58) {
    final missingNonLand = 58 - nonLandTotal;
    needs['utility'] = (needs['utility'] ?? 0) + missingNonLand;
  }

  return needs;
}

Future<List<Map<String, dynamic>>> loadDeterministicSlotFillers({
  required Pool pool,
  required List<Map<String, dynamic>> currentDeckCards,
  required String targetArchetype,
  required Set<String> commanderColorIdentity,
  required int? bracket,
  required Set<String> excludeNames,
  Set<String>? preferredNames,
  required int limit,
}) async {
  if (limit <= 0) return const [];

  final slotNeeds = buildSlotNeedsForDeck(
    currentDeckCards: currentDeckCards,
    targetArchetype: targetArchetype,
  );

  final candidates = await loadCompetitiveNonLandFillers(
    pool: pool,
    commanderColorIdentity: commanderColorIdentity,
    bracket: bracket,
    excludeNames: excludeNames,
    limit: limit < 80 ? 240 : (limit * 4),
  );

  if (candidates.isEmpty) return const [];

  final scored = candidates.map((c) {
    final name = (c['name'] as String?) ?? '';
    final typeLine = (c['type_line'] as String?) ?? '';
    final oracle = (c['oracle_text'] as String?) ?? '';
    final role = inferFunctionalRole(
      name: name,
      typeLine: typeLine,
      oracleText: oracle,
    );

    final primaryNeed = slotNeeds[role] ?? 0;
    final utilityNeed = slotNeeds['utility'] ?? 0;
    final fromAiSuggestion =
        (preferredNames ?? const <String>{}).contains(name.toLowerCase());
    final aiBoost = fromAiSuggestion ? 35 : 0;
    final score = primaryNeed * 100 +
        (role == 'utility' ? utilityNeed * 10 : 0) +
        aiBoost;

    return {
      ...c,
      '_role': role,
      '_score': score,
    };
  }).toList();

  scored.sort((a, b) {
    final scoreA = (a['_score'] as int?) ?? 0;
    final scoreB = (b['_score'] as int?) ?? 0;
    final byScore = scoreB.compareTo(scoreA);
    if (byScore != 0) return byScore;
    final nameA = (a['name'] as String?) ?? '';
    final nameB = (b['name'] as String?) ?? '';
    return nameA.compareTo(nameB);
  });

  return scored.take(limit).map((e) {
    return {
      'id': e['id'],
      'name': e['name'],
      'type_line': e['type_line'],
      'oracle_text': e['oracle_text'],
      'mana_cost': e['mana_cost'],
      'colors': e['colors'],
      'color_identity': e['color_identity'],
    };
  }).toList();
}

Future<List<Map<String, dynamic>>> loadMetaInsightFillers({
  required Pool pool,
  required Set<String> commanderColorIdentity,
  required Set<String> excludeNames,
  required int limit,
}) async {
  if (limit <= 0) return const [];

  final identity = commanderColorIdentity.toList();
  final result = await pool.execute(
    Sql.named('''
      SELECT c.id::text, c.name, c.type_line, c.oracle_text, c.mana_cost, c.colors, c.color_identity, c.cmc,
             mi.meta_deck_count, mi.usage_count
      FROM card_meta_insights mi
      JOIN cards c ON LOWER(c.name) = LOWER(mi.card_name)
      LEFT JOIN card_legalities cl ON cl.card_id = c.id AND cl.format = 'commander'
      WHERE (cl.status = 'legal' OR cl.status = 'restricted' OR cl.status IS NULL)
        AND c.type_line NOT ILIKE '%land%'
        AND c.name NOT LIKE 'A-%'
        AND c.name NOT LIKE '\\_%' ESCAPE '\\'
        AND c.name NOT LIKE '%World Champion%'
        AND c.name NOT LIKE '%Heroes of the Realm%'
        AND (
          (
            c.color_identity IS NOT NULL
            AND (
              (
                c.color_identity IS NOT NULL
                AND (
                  c.color_identity <@ @identity::text[]
                  OR c.color_identity = '{}'
                )
              )
              OR (
                c.color_identity IS NULL
                AND (
                  c.colors <@ @identity::text[]
                  OR c.colors = '{}'
                  OR c.colors IS NULL
                )
              )
            )
          )
          OR (
            c.color_identity IS NULL
            AND (
              c.colors <@ @identity::text[]
              OR c.colors = '{}'
              OR c.colors IS NULL
            )
          )
        )
      ORDER BY mi.meta_deck_count DESC, mi.usage_count DESC, c.name ASC
      LIMIT @limit
    '''),
    parameters: {
      'identity': identity,
      'limit': limit,
    },
  );

  final mapped = result
      .map((row) => {
            'id': row[0] as String,
            'name': row[1] as String,
            'type_line': (row[2] as String?) ?? '',
            'oracle_text': (row[3] as String?) ?? '',
            'mana_cost': (row[4] as String?) ?? '',
            'colors': (row[5] as List?)?.cast<String>() ?? const <String>[],
            'color_identity':
                (row[6] as List?)?.cast<String>() ?? const <String>[],
            'cmc': safeToDouble(row[7]),
            'meta_deck_count': (row[8] as num?)?.toInt() ?? 0,
            'usage_count': (row[9] as num?)?.toInt() ?? 0,
          })
      .where(
        (candidate) => shouldKeepCommanderFillerCandidate(
          candidate: candidate,
          excludeNames: excludeNames,
          commanderColorIdentity: commanderColorIdentity,
          enforceCommanderIdentity: true,
        ),
      )
      .toList();

  final deduped = dedupeCandidatesByName(mapped);
  deduped.sort((a, b) {
    final byQuality = commanderFillerQualityScore(b)
        .compareTo(commanderFillerQualityScore(a));
    if (byQuality != 0) return byQuality;
    return ((a['name'] as String?) ?? '')
        .compareTo((b['name'] as String?) ?? '');
  });
  return deduped.take(limit).toList();
}

Future<List<Map<String, dynamic>>> loadBroadCommanderNonLandFillers({
  required Pool pool,
  required Set<String> commanderColorIdentity,
  required Set<String> excludeNames,
  required int? bracket,
  required int limit,
}) async {
  if (limit <= 0) return const [];

  final identity = commanderColorIdentity.toList();
  Log.d(
      '  [broad] start limit=$limit identity=${identity.join(',')} exclude=${excludeNames.length}');
  final result = await pool.execute(
    Sql.named('''
      SELECT sub.id, sub.name, sub.type_line, sub.oracle_text, sub.mana_cost, sub.colors, sub.color_identity, sub.cmc, sub.meta_deck_count, sub.usage_count
      FROM (
        SELECT DISTINCT ON (LOWER(c.name))
          c.id::text, c.name, c.type_line, c.oracle_text, c.mana_cost, c.colors, c.color_identity, c.cmc,
          COALESCE(cmi.meta_deck_count, 0) AS meta_deck_count,
          COALESCE(cmi.usage_count, 0) AS usage_count,
          COALESCE(cmi.usage_count, 0) AS pop_score
        FROM cards c
      LEFT JOIN card_legalities cl ON cl.card_id = c.id AND cl.format = 'commander'
      LEFT JOIN card_meta_insights cmi ON LOWER(cmi.card_name) = LOWER(c.name)
      WHERE (cl.status = 'legal' OR cl.status = 'restricted' OR cl.status IS NULL)
        AND c.type_line NOT ILIKE '%land%'
        AND c.name NOT LIKE 'A-%'
        AND c.name NOT LIKE '\\_%' ESCAPE '\\'
        AND c.name NOT LIKE '%World Champion%'
          AND c.name NOT LIKE '%Heroes of the Realm%'
          AND c.oracle_text IS NOT NULL
          AND (
            (
              c.color_identity IS NOT NULL
              AND (
                c.color_identity <@ @identity::text[]
                OR c.color_identity = '{}'
              )
            )
            OR (
              c.color_identity IS NULL
              AND (
                c.colors <@ @identity::text[]
                OR c.colors = '{}'
                OR c.colors IS NULL
              )
            )
          )
        ORDER BY LOWER(c.name), COALESCE(cmi.usage_count, 0) DESC
      ) sub
      ORDER BY sub.pop_score DESC, RANDOM()
      LIMIT @limit
    '''),
    parameters: {
      'identity': identity,
      'limit': limit,
    },
  );

  Log.d('  [broad] sql rows=${result.length}');

  var candidates = result
      .map((row) => {
            'id': row[0] as String,
            'name': row[1] as String,
            'type_line': (row[2] as String?) ?? '',
            'oracle_text': (row[3] as String?) ?? '',
            'mana_cost': (row[4] as String?) ?? '',
            'colors': (row[5] as List?)?.cast<String>() ?? const <String>[],
            'color_identity':
                (row[6] as List?)?.cast<String>() ?? const <String>[],
            'cmc': safeToDouble(row[7]),
            'meta_deck_count': (row[8] as num?)?.toInt() ?? 0,
            'usage_count': (row[9] as num?)?.toInt() ?? 0,
          })
      .where(
        (candidate) => shouldKeepCommanderFillerCandidate(
          candidate: candidate,
          excludeNames: excludeNames,
          commanderColorIdentity: commanderColorIdentity,
          enforceCommanderIdentity: true,
        ),
      )
      .toList();
  candidates = dedupeCandidatesByName(candidates);
  candidates.sort((a, b) {
    final byQuality = commanderFillerQualityScore(b)
        .compareTo(commanderFillerQualityScore(a));
    if (byQuality != 0) return byQuality;
    return ((a['name'] as String?) ?? '')
        .compareTo((b['name'] as String?) ?? '');
  });
  Log.d('  [broad] dedup rows=${candidates.length}');

  if (bracket != null && candidates.isNotEmpty) {
    final decision = applyBracketPolicyToAdditions(
      bracket: bracket,
      currentDeckCards: const [],
      additionsCardsData: candidates.map((c) {
        return {
          'name': c['name'],
          'type_line': c['type_line'],
          'oracle_text': c['oracle_text'],
          'quantity': 1,
        };
      }),
    );
    final allowedSet = decision.allowed.map((e) => e.toLowerCase()).toSet();
    final filtered = candidates
        .where((c) => allowedSet.contains((c['name'] as String).toLowerCase()))
        .toList();
    Log.d(
        '  [broad] bracket=$bracket allowed=${allowedSet.length} filtered=${filtered.length}');
    if (filtered.isNotEmpty) {
      candidates = filtered;
    }
  }

  Log.d('  [broad] final rows=${candidates.length}');
  return dedupeCandidatesByName(candidates).take(limit).toList();
}

Future<List<Map<String, dynamic>>> loadGuaranteedNonBasicFillers({
  required Pool pool,
  required List<Map<String, dynamic>> currentDeckCards,
  required String targetArchetype,
  required Set<String> commanderColorIdentity,
  required int? bracket,
  required Set<String> excludeNames,
  required Set<String> preferredNames,
  required int limit,
}) async {
  if (limit <= 0) return const [];

  final aggregated = <Map<String, dynamic>>[];
  final seen = <String>{};

  void addUnique(Iterable<Map<String, dynamic>> items) {
    for (final item in items) {
      final name = ((item['name'] as String?) ?? '').trim().toLowerCase();
      if (name.isEmpty || seen.contains(name)) continue;
      seen.add(name);
      aggregated.add(item);
      if (aggregated.length >= limit) return;
    }
  }

  final withBracket = await loadDeterministicSlotFillers(
    pool: pool,
    currentDeckCards: currentDeckCards,
    targetArchetype: targetArchetype,
    commanderColorIdentity: commanderColorIdentity,
    bracket: bracket,
    excludeNames: excludeNames,
    preferredNames: preferredNames,
    limit: limit,
  );
  addUnique(withBracket);

  if (aggregated.length < limit) {
    final noBracket = await loadDeterministicSlotFillers(
      pool: pool,
      currentDeckCards: currentDeckCards,
      targetArchetype: targetArchetype,
      commanderColorIdentity: commanderColorIdentity,
      bracket: null,
      excludeNames: excludeNames.union(seen),
      preferredNames: preferredNames,
      limit: limit - aggregated.length,
    );
    addUnique(noBracket);
  }

  if (aggregated.length < limit) {
    final metaFillers = await loadMetaInsightFillers(
      pool: pool,
      commanderColorIdentity: commanderColorIdentity,
      excludeNames: excludeNames.union(seen),
      limit: limit - aggregated.length,
    );
    addUnique(metaFillers);
  }

  if (aggregated.length < limit) {
    final broadWithBracket = await loadBroadCommanderNonLandFillers(
      pool: pool,
      commanderColorIdentity: commanderColorIdentity,
      excludeNames: excludeNames.union(seen),
      bracket: bracket,
      limit: limit - aggregated.length,
    );
    addUnique(broadWithBracket);
  }

  if (aggregated.length < limit) {
    final broadNoBracket = await loadBroadCommanderNonLandFillers(
      pool: pool,
      commanderColorIdentity: commanderColorIdentity,
      excludeNames: excludeNames.union(seen),
      bracket: null,
      limit: limit - aggregated.length,
    );
    addUnique(broadNoBracket);
  }

  return aggregated.take(limit).toList();
}

Future<List<Map<String, dynamic>>> loadCompetitiveNonLandFillers({
  required Pool pool,
  required Set<String> commanderColorIdentity,
  required int? bracket,
  required Set<String> excludeNames,
  required int limit,
}) async {
  if (limit <= 0) return const [];

  final identity = commanderColorIdentity.toList();
  final result = await pool.execute(
    Sql.named('''
      SELECT sub.id, sub.name, sub.type_line, sub.oracle_text, sub.mana_cost, sub.colors, sub.color_identity
      FROM (
        SELECT DISTINCT ON (LOWER(c.name))
          c.id::text, c.name, c.type_line, c.oracle_text, c.mana_cost, c.colors, c.color_identity,
          COALESCE(cmi.usage_count, 0) AS pop_score
        FROM cards c
        LEFT JOIN card_legalities cl ON cl.card_id = c.id AND cl.format = 'commander'
        LEFT JOIN card_meta_insights cmi ON LOWER(cmi.card_name) = LOWER(c.name)
        WHERE (cl.status = 'legal' OR cl.status = 'restricted' OR cl.status IS NULL)
          AND c.type_line NOT ILIKE '%land%'
          AND c.name NOT LIKE 'A-%'
          AND c.name NOT LIKE '\\_%' ESCAPE '\\'
          AND c.name NOT LIKE '%World Champion%'
          AND c.name NOT LIKE '%Heroes of the Realm%'
          AND c.oracle_text IS NOT NULL
          AND (
            (
              c.color_identity IS NOT NULL
              AND (
                c.color_identity <@ @identity::text[]
                OR c.color_identity = '{}'
              )
            )
            OR (
              c.color_identity IS NULL
              AND (
                c.colors <@ @identity::text[]
                OR c.colors = '{}'
                OR c.colors IS NULL
              )
            )
          )
        ORDER BY LOWER(c.name), COALESCE(cmi.usage_count, 0) DESC
      ) sub
      ORDER BY sub.pop_score DESC, RANDOM()
      LIMIT 600
    '''),
    parameters: {
      'identity': identity,
    },
  );

  var candidates = result
      .map((row) => {
            'id': row[0] as String,
            'name': row[1] as String,
            'type_line': (row[2] as String?) ?? '',
            'oracle_text': (row[3] as String?) ?? '',
            'mana_cost': (row[4] as String?) ?? '',
            'colors': (row[5] as List?)?.cast<String>() ?? const <String>[],
            'color_identity':
                (row[6] as List?)?.cast<String>() ?? const <String>[],
          })
      .where(
        (candidate) => shouldKeepCommanderFillerCandidate(
          candidate: candidate,
          excludeNames: excludeNames,
          commanderColorIdentity: commanderColorIdentity,
          enforceCommanderIdentity: true,
        ),
      )
      .toList();
  candidates = dedupeCandidatesByName(candidates);

  if (candidates.length < limit) {
    final stapleNames = [
      'Sol Ring',
      'Arcane Signet',
      'Mind Stone',
      'Fellwar Stone',
      'Swiftfoot Boots',
      'Lightning Greaves',
      'Command Tower',
      'Demonic Tutor',
      'Vampiric Tutor',
      'Rhystic Study',
      'Necropotence',
      'Cyclonic Rift',
      'Swords to Plowshares',
      'Anguished Unmaking',
      'Beast Within',
      'Nature' 's Claim',
      'Counterspell',
      'Mana Drain',
      'Fact or Fiction',
      'Ponder',
      'Preordain',
      'Brainstorm',
      'Signet',
      'Talisman',
      'Dark Ritual',
      'Reanimate',
      'Animate Dead',
      'Eternal Witness',
      'Regrowth',
      'Hero' 's Downfall',
      'Mortify',
      'Path to Exile',
      'Generous Gift',
      'Chaos Warp',
      'Krosan Grip',
      'Disenchant',
      'Return to Nature',
      'Mana Leak',
      'Force of Will',
      'Force of Negation',
      'Teferi' 's Protection',
      'Toxic Deluge',
      'Blasphemous Act',
      'Boardwipe',
      'Draw',
      'Ramp',
      'Removal'
    ];
    final stapleResult = await pool.execute(
      Sql.named('''
        SELECT c.id::text, c.name, c.type_line, c.oracle_text, c.colors, c.color_identity
        FROM cards c
        LEFT JOIN card_legalities cl ON cl.card_id = c.id AND cl.format = 'commander'
        WHERE (cl.status = 'legal' OR cl.status = 'restricted' OR cl.status IS NULL)
          AND LOWER(c.name) IN (SELECT LOWER(unnest(@names::text[])))
          AND (
            c.color_identity <@ @identity::text[]
            OR c.color_identity = '{}'
          )
      '''),
      parameters: {
        'names': stapleNames,
        'identity': identity,
      },
    );
    final stapleCandidates = stapleResult
        .map((row) => {
              'id': row[0] as String,
              'name': row[1] as String,
              'type_line': (row[2] as String?) ?? '',
              'oracle_text': (row[3] as String?) ?? '',
              'colors': (row[4] as List?)?.cast<String>() ?? const <String>[],
              'color_identity':
                  (row[5] as List?)?.cast<String>() ?? const <String>[],
            })
        .where(
            (c) => !excludeNames.contains((c['name'] as String).toLowerCase()))
        .toList();
    candidates.addAll(stapleCandidates);
    candidates = dedupeCandidatesByName(candidates);
    if (candidates.isEmpty) {
      print('[COMPLETE FILLER] Pool vazio, fallback para staples universais.');
    } else if (stapleCandidates.isNotEmpty) {
      print(
          '[COMPLETE FILLER] Pool expandido com staples universais: ${stapleCandidates.length}');
    }
  }

  if (bracket != null && candidates.isNotEmpty) {
    final decision = applyBracketPolicyToAdditions(
      bracket: bracket,
      currentDeckCards: const [],
      additionsCardsData: candidates.map((c) {
        return {
          'name': c['name'],
          'type_line': c['type_line'],
          'oracle_text': c['oracle_text'],
          'quantity': 1,
        };
      }),
    );
    final allowedSet = decision.allowed.map((e) => e.toLowerCase()).toSet();
    final filtered = candidates
        .where((c) => allowedSet.contains((c['name'] as String).toLowerCase()))
        .toList();

    if (filtered.isNotEmpty) {
      candidates = filtered;
    }
  }

  return dedupeCandidatesByName(candidates).take(limit).toList();
}

Future<List<Map<String, dynamic>>> loadEmergencyNonBasicFillers({
  required Pool pool,
  required Set<String> excludeNames,
  required int? bracket,
  required int limit,
}) async {
  if (limit <= 0) return const [];

  final result = await pool.execute(
    Sql.named('''
      SELECT sub.id, sub.name, sub.type_line, sub.oracle_text, sub.mana_cost, sub.colors, sub.color_identity
      FROM (
        SELECT DISTINCT ON (LOWER(c.name))
          c.id::text, c.name, c.type_line, c.oracle_text, c.mana_cost, c.colors, c.color_identity,
          COALESCE(cmi.usage_count, 0) AS pop_score
        FROM cards c
        LEFT JOIN card_legalities cl ON cl.card_id = c.id AND cl.format = 'commander'
        LEFT JOIN card_meta_insights cmi ON LOWER(cmi.card_name) = LOWER(c.name)
        WHERE (cl.status = 'legal' OR cl.status = 'restricted' OR cl.status IS NULL)
          AND c.type_line NOT ILIKE '%land%'
          AND c.name NOT LIKE 'A-%'
          AND c.name NOT LIKE '\\_%' ESCAPE '\\'
          AND c.name NOT LIKE '%World Champion%'
          AND c.name NOT LIKE '%Heroes of the Realm%'
        ORDER BY LOWER(c.name), COALESCE(cmi.usage_count, 0) DESC
      ) sub
      ORDER BY sub.pop_score DESC, RANDOM()
      LIMIT @limit
    '''),
    parameters: {
      'limit': limit * 3,
    },
  );

  var candidates = result
      .map((row) => {
            'id': row[0] as String,
            'name': row[1] as String,
            'type_line': (row[2] as String?) ?? '',
            'oracle_text': (row[3] as String?) ?? '',
            'colors': (row[4] as List?)?.cast<String>() ?? const <String>[],
            'color_identity':
                (row[5] as List?)?.cast<String>() ?? const <String>[],
          })
      .where(
        (candidate) => shouldKeepCommanderFillerCandidate(
          candidate: candidate,
          excludeNames: excludeNames,
        ),
      )
      .toList();
  candidates = dedupeCandidatesByName(candidates);

  if (bracket != null && candidates.isNotEmpty) {
    final decision = applyBracketPolicyToAdditions(
      bracket: bracket,
      currentDeckCards: const [],
      additionsCardsData: candidates.map((c) {
        return {
          'name': c['name'],
          'type_line': c['type_line'],
          'oracle_text': c['oracle_text'],
          'quantity': 1,
        };
      }),
    );
    final allowedSet = decision.allowed.map((e) => e.toLowerCase()).toSet();
    final filtered = candidates
        .where((c) => allowedSet.contains((c['name'] as String).toLowerCase()))
        .toList();
    if (filtered.isNotEmpty) {
      candidates = filtered;
    }
  }

  return dedupeCandidatesByName(candidates).take(limit).toList();
}

Future<List<Map<String, dynamic>>> loadIdentitySafeNonLandFillers({
  required Pool pool,
  required Set<String> commanderColorIdentity,
  required Set<String> excludeNames,
  required int limit,
}) async {
  if (limit <= 0) return const [];

  Log.d(
      '  [identity-safe] start limit=$limit identity=${commanderColorIdentity.join(',')} exclude=${excludeNames.length}');

  final result = await pool.execute(
    Sql.named('''
      SELECT sub.id, sub.name, sub.type_line, sub.oracle_text, sub.mana_cost, sub.colors, sub.color_identity
      FROM (
        SELECT DISTINCT ON (LOWER(c.name))
          c.id::text, c.name, c.type_line, c.oracle_text, c.mana_cost, c.colors, c.color_identity,
          COALESCE(cmi.usage_count, 0) AS pop_score
        FROM cards c
        LEFT JOIN card_legalities cl ON cl.card_id = c.id AND cl.format = 'commander'
        LEFT JOIN card_meta_insights cmi ON LOWER(cmi.card_name) = LOWER(c.name)
        WHERE (cl.status = 'legal' OR cl.status = 'restricted' OR cl.status IS NULL)
          AND c.type_line NOT ILIKE '%land%'
          AND c.name NOT LIKE 'A-%'
          AND c.name NOT LIKE '\\_%' ESCAPE '\\'
          AND c.name NOT LIKE '%World Champion%'
          AND c.name NOT LIKE '%Heroes of the Realm%'
        ORDER BY LOWER(c.name), COALESCE(cmi.usage_count, 0) DESC
      ) sub
      ORDER BY sub.pop_score DESC, RANDOM()
      LIMIT 4000
    '''),
  );

  Log.d('  [identity-safe] sql rows=${result.length}');

  final filtered = <Map<String, dynamic>>[];
  for (final row in result) {
    final id = row[0] as String;
    final name = row[1] as String;
    final lowerName = name.toLowerCase();
    if (excludeNames.contains(lowerName)) continue;

    final typeLine = (row[2] as String?) ?? '';
    final oracleText = (row[3] as String?) ?? '';
    final manaCost = (row[4] as String?) ?? '';
    final colors = (row[5] as List?)?.cast<String>() ?? const <String>[];
    final colorIdentity = (row[6] as List?)?.cast<String>() ?? const <String>[];

    final withinIdentity = isWithinCommanderIdentity(
      cardIdentity: resolvedCardIdentityFromParts(
        colorIdentity: colorIdentity,
        colors: colors,
        oracleText: oracleText,
        manaCost: manaCost,
      ),
      commanderIdentity: commanderColorIdentity,
    );
    if (!withinIdentity) continue;
    final candidate = {
      'id': id,
      'name': name,
      'type_line': typeLine,
      'oracle_text': oracleText,
      'mana_cost': manaCost,
      'colors': colors,
      'color_identity': colorIdentity,
    };
    if (!shouldKeepCommanderFillerCandidate(
      candidate: candidate,
      excludeNames: excludeNames,
      commanderColorIdentity: commanderColorIdentity,
      enforceCommanderIdentity: true,
    )) {
      continue;
    }

    filtered.add(candidate);
  }

  Log.d('  [identity-safe] filtered rows=${filtered.length}');

  return dedupeCandidatesByName(filtered).take(limit).toList();
}

Future<List<Map<String, dynamic>>> loadPreferredNameFillers({
  required Pool pool,
  required Set<String> preferredNames,
  required Set<String> commanderColorIdentity,
  required Set<String> excludeNames,
  required int limit,
}) async {
  if (limit <= 0 || preferredNames.isEmpty) return const [];

  final normalizedPreferred = preferredNames
      .map((name) => name.trim().toLowerCase())
      .where((name) => name.isNotEmpty)
      .toSet();
  if (normalizedPreferred.isEmpty) return const [];

  final result = await pool.execute(
    Sql.named('''
      SELECT
        c.id::text,
        c.name,
        c.type_line,
        c.oracle_text,
        c.mana_cost,
        c.colors,
        c.color_identity,
        c.cmc,
        COALESCE(cmi.meta_deck_count, 0) AS meta_deck_count,
        COALESCE(cmi.usage_count, 0) AS usage_count
      FROM cards c
      LEFT JOIN card_meta_insights cmi ON LOWER(cmi.card_name) = LOWER(c.name)
      WHERE LOWER(name) = ANY(@preferred::text[])
        AND type_line NOT ILIKE '%land%'
      ORDER BY COALESCE(cmi.meta_deck_count, 0) DESC,
               COALESCE(cmi.usage_count, 0) DESC,
               c.name ASC
    '''),
    parameters: {
      'preferred': normalizedPreferred.toList(),
    },
  );

  final filtered = <Map<String, dynamic>>[];
  for (final row in result) {
    final id = row[0] as String;
    final name = row[1] as String;
    final lowerName = name.toLowerCase();
    if (excludeNames.contains(lowerName)) continue;

    final typeLine = (row[2] as String?) ?? '';
    final oracleText = (row[3] as String?) ?? '';
    final manaCost = (row[4] as String?) ?? '';
    final colors = (row[5] as List?)?.cast<String>() ?? const <String>[];
    final colorIdentity = (row[6] as List?)?.cast<String>() ?? const <String>[];

    final withinIdentity = isWithinCommanderIdentity(
      cardIdentity: resolvedCardIdentityFromParts(
        colorIdentity: colorIdentity,
        colors: colors,
        oracleText: oracleText,
        manaCost: manaCost,
      ),
      commanderIdentity: commanderColorIdentity,
    );
    if (!withinIdentity) continue;
    final candidate = {
      'id': id,
      'name': name,
      'type_line': typeLine,
      'oracle_text': oracleText,
      'mana_cost': manaCost,
      'colors': colors,
      'color_identity': colorIdentity,
      'cmc': safeToDouble(row[7]),
      'meta_deck_count': (row[8] as num?)?.toInt() ?? 0,
      'usage_count': (row[9] as num?)?.toInt() ?? 0,
    };
    if (!shouldKeepCommanderFillerCandidate(
      candidate: candidate,
      excludeNames: excludeNames,
      commanderColorIdentity: commanderColorIdentity,
      enforceCommanderIdentity: true,
    )) {
      continue;
    }

    filtered.add(candidate);
  }

  filtered.sort((a, b) {
    final byQuality = commanderFillerQualityScore(b)
        .compareTo(commanderFillerQualityScore(a));
    if (byQuality != 0) return byQuality;
    return ((a['name'] as String?) ?? '')
        .compareTo((b['name'] as String?) ?? '');
  });

  final floor = filtered.length > limit ? 25 : -999;
  final qualityFiltered = filtered
      .where((candidate) => commanderFillerQualityScore(candidate) >= floor)
      .toList();
  final source = qualityFiltered.isNotEmpty ? qualityFiltered : filtered;

  return dedupeCandidatesByName(source).take(limit).toList();
}

Future<List<Map<String, dynamic>>> findSynergyReplacements({
  required Pool pool,
  required List<String> commanders,
  required Set<String> commanderColorIdentity,
  required String targetArchetype,
  required int? bracket,
  required bool keepTheme,
  required String? detectedTheme,
  required List<String>? coreCards,
  required int missingCount,
  required List<String> removedCards,
  List<String>? functionalNeedsOverride,
  required Set<String> excludeNames,
  required List<Map<String, dynamic>> allCardData,
  Set<String> preferredNames = const <String>{},
  bool preferLowCurve = false,
}) async {
  final results = <Map<String, dynamic>>[];

  List<String> defaultNeedsForArchetype(String archetype) {
    final normalized = archetype.toLowerCase();
    if (normalized.contains('control')) {
      return const ['removal', 'draw', 'ramp', 'protection', 'utility'];
    }
    if (normalized.contains('aggro')) {
      return const ['creature', 'ramp', 'draw', 'removal', 'utility'];
    }
    if (normalized.contains('combo')) {
      return const ['draw', 'tutor', 'ramp', 'protection', 'utility'];
    }
    if (normalized.contains('stax')) {
      return const ['ramp', 'removal', 'protection', 'utility'];
    }
    if (normalized.contains('tribal')) {
      return const ['creature', 'draw', 'ramp', 'removal', 'utility'];
    }
    return const ['ramp', 'draw', 'removal', 'creature', 'utility'];
  }

  final functionalNeeds = <String>[];
  if (removedCards.isNotEmpty) {
    final removedTypesResult = await pool.execute(
      Sql.named('''
      SELECT name, type_line, oracle_text, color_identity
      FROM cards
      WHERE name = ANY(@names)
    '''),
      parameters: {'names': removedCards},
    );

    final removedByName = <String, Map<String, dynamic>>{};
    for (final row in removedTypesResult) {
      final name = ((row[0] as String?) ?? '').trim().toLowerCase();
      if (name.isEmpty) continue;
      removedByName[name] = {
        'name': (row[0] as String?) ?? '',
        'type_line': (row[1] as String?) ?? '',
        'oracle_text': (row[2] as String?) ?? '',
      };
    }

    for (final removedName in removedCards) {
      final removed = removedByName[removedName.trim().toLowerCase()];
      if (removed == null) {
        functionalNeeds.add('utility');
        continue;
      }

      functionalNeeds.add(
        inferOptimizeFunctionalNeed(
          name: removed['name'] as String? ?? '',
          typeLine: removed['type_line'] as String? ?? '',
          oracleText: removed['oracle_text'] as String? ?? '',
        ),
      );
    }
  }

  final colorIdentityArr = commanderColorIdentity.toList();
  final normalizedPreferredNames = preferredNames
      .map((name) => name.trim().toLowerCase())
      .where((name) => name.isNotEmpty)
      .toSet();
  final commanderName = commanders.isNotEmpty ? commanders.first.trim() : '';
  final rejectedAdditionCounts = commanderName.isEmpty
      ? const <String, int>{}
      : await _loadRejectedOptimizeAdditionCounts(
          pool: pool,
          commanderName: commanderName,
        );

  final candidatesResult = await pool.execute(
    Sql.named('''
      SELECT sub.id, sub.name, sub.type_line, sub.oracle_text, sub.mana_cost, sub.colors, sub.color_identity, sub.pop_score
      FROM (
        SELECT DISTINCT ON (LOWER(c.name))
          c.id::text, c.name, c.type_line, c.oracle_text, c.mana_cost, c.colors, c.color_identity,
          COALESCE(cmi.usage_count, 0) AS pop_score
        FROM cards c
        LEFT JOIN card_legalities cl ON cl.card_id = c.id AND cl.format = 'commander'
        LEFT JOIN card_meta_insights cmi ON LOWER(cmi.card_name) = LOWER(c.name)
        WHERE (cl.status = 'legal' OR cl.status = 'restricted' OR cl.status IS NULL)
          AND LOWER(c.name) NOT IN (SELECT LOWER(unnest(@exclude::text[])))
          AND c.type_line NOT ILIKE '%land%'
          AND c.name NOT LIKE 'A-%'
          AND c.name NOT LIKE '\\_%' ESCAPE '\\'
          AND c.name NOT LIKE '%World Champion%'
          AND c.name NOT LIKE '%Heroes of the Realm%'
          AND c.oracle_text IS NOT NULL
          AND LENGTH(TRIM(c.oracle_text)) > 0
          AND (
            c.color_identity <@ @identity::text[]
            OR c.color_identity = '{}'
            OR c.color_identity IS NULL
          )
        ORDER BY LOWER(c.name), COALESCE(cmi.usage_count, 0) DESC
      ) sub
      ORDER BY sub.pop_score DESC, LOWER(sub.name) ASC
      LIMIT 300
    '''),
    parameters: {
      'exclude': excludeNames.toList(),
      'identity': colorIdentityArr,
    },
  );

  final candidatePool = <Map<String, dynamic>>[];
  for (final row in candidatesResult) {
    final id = row[0] as String;
    final name = row[1] as String;
    final typeLine = ((row[2] as String?) ?? '').toLowerCase();
    final oracle = ((row[3] as String?) ?? '').toLowerCase();
    final manaCost = (row[4] as String?) ?? '';
    final colors = (row[5] as List?)?.cast<String>() ?? const <String>[];
    final identity = (row[6] as List?)?.cast<String>() ?? const <String>[];
    final popScore = (row[7] as num?)?.toInt() ?? 0;

    if (!isWithinCommanderIdentity(
      cardIdentity: resolvedCardIdentityFromParts(
        colorIdentity: identity,
        colors: colors,
        oracleText: oracle,
        manaCost: manaCost,
      ),
      commanderIdentity: commanderColorIdentity,
    )) continue;

    candidatePool.add({
      'id': id,
      'name': name,
      'type_line': typeLine,
      'oracle_text': oracle,
      'mana_cost': manaCost,
      'colors': colors,
      'color_identity': identity,
      'pop_score': popScore,
    });
  }

  final usedNames = <String>{};

  final needs =
      (functionalNeedsOverride != null && functionalNeedsOverride.isNotEmpty)
          ? functionalNeedsOverride
          : functionalNeeds.isNotEmpty
              ? functionalNeeds
              : defaultNeedsForArchetype(targetArchetype);

  for (var i = 0; i < missingCount && i < needs.length; i++) {
    final need = needs[i];
    Map<String, dynamic>? best;
    var bestScore = -0x7fffffff;

    for (final candidate in candidatePool) {
      final name = (candidate['name'] as String).toLowerCase();
      if (usedNames.contains(name)) continue;
      final score = scoreOptimizeReplacementCandidate(
        functionalNeed: need,
        cardName: candidate['name'] as String? ?? '',
        typeLine: candidate['type_line'] as String? ?? '',
        oracleText: candidate['oracle_text'] as String? ?? '',
        manaCost: candidate['mana_cost'] as String? ?? '',
        popScore: (candidate['pop_score'] as int?) ?? 0,
        preferredNames: normalizedPreferredNames,
        rejectedAdditionCounts: rejectedAdditionCounts,
        preferLowCurve: preferLowCurve,
      );
      final matches = matchesFunctionalNeed(
        need,
        oracleText: candidate['oracle_text'] as String? ?? '',
        typeLine: candidate['type_line'] as String? ?? '',
      );

      if (matches && score > bestScore) {
        best = candidate;
        bestScore = score;
      }
    }

    if (best != null) {
      results.add({'id': best['id'], 'name': best['name']});
      usedNames.add((best['name'] as String).toLowerCase());
    }
  }

  if (results.length < missingCount) {
    final rankedRemaining = candidatePool.where((candidate) {
      final name = (candidate['name'] as String).toLowerCase();
      return !usedNames.contains(name);
    }).toList()
      ..sort((a, b) {
        final scoreA = scoreOptimizeReplacementCandidate(
          functionalNeed: 'utility',
          cardName: a['name'] as String? ?? '',
          typeLine: a['type_line'] as String? ?? '',
          oracleText: a['oracle_text'] as String? ?? '',
          manaCost: a['mana_cost'] as String? ?? '',
          popScore: (a['pop_score'] as int?) ?? 0,
          preferredNames: normalizedPreferredNames,
          rejectedAdditionCounts: rejectedAdditionCounts,
          preferLowCurve: preferLowCurve,
        );
        final scoreB = scoreOptimizeReplacementCandidate(
          functionalNeed: 'utility',
          cardName: b['name'] as String? ?? '',
          typeLine: b['type_line'] as String? ?? '',
          oracleText: b['oracle_text'] as String? ?? '',
          manaCost: b['mana_cost'] as String? ?? '',
          popScore: (b['pop_score'] as int?) ?? 0,
          preferredNames: normalizedPreferredNames,
          rejectedAdditionCounts: rejectedAdditionCounts,
          preferLowCurve: preferLowCurve,
        );
        final byScore = scoreB.compareTo(scoreA);
        if (byScore != 0) return byScore;
        final nameA = (a['name'] as String? ?? '').toLowerCase();
        final nameB = (b['name'] as String? ?? '').toLowerCase();
        return nameA.compareTo(nameB);
      });

    for (final candidate in rankedRemaining) {
      if (results.length >= missingCount) break;
      final name = (candidate['name'] as String).toLowerCase();
      if (usedNames.contains(name)) continue;

      results.add({'id': candidate['id'], 'name': candidate['name']});
      usedNames.add(name);
    }
  }

  return results;
}

List<T> dedupeCandidatesByName<T extends Map<String, Object?>>(
  List<T> input,
) {
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

const _weakCommanderFillerDenylist = <String>{
  'ancestral reminiscence',
  'bane\'s contingency',
  'body of knowledge',
  'cancel',
  'diviner\'s portent',
  'didn\'t say please',
  'dream fracture',
  'dreamstone hedron',
  'forced fruition',
  'palladium myr',
  'prismatic lens',
  'sisay\'s ring',
  'silver myr',
  'stonespeaker crystal',
  'ur-golem\'s eye',
};

const _premiumCommanderFillerNames = <String>{
  'arcane denial',
  'arcane signet',
  'brainstorm',
  'chrome mox',
  'counterspell',
  'cyclonic rift',
  'fact or fiction',
  'fierce guardianship',
  'force of negation',
  'force of will',
  'grim monolith',
  'lightning greaves',
  'mana drain',
  'mana vault',
  'mental misstep',
  'mind stone',
  'mox diamond',
  'mystical tutor',
  'negate',
  'pact of negation',
  'ponder',
  'preordain',
  'rhystic study',
  'sol ring',
  'swan song',
  'swiftfoot boots',
  'thassa\'s oracle',
  'thought vessel',
};

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
  if (_weakCommanderFillerDenylist.contains(name)) return false;

  if (enforceCommanderIdentity || commanderColorIdentity.isNotEmpty) {
    final withinIdentity = isWithinCommanderIdentity(
      cardIdentity: resolvedCardIdentityFromParts(
        colorIdentity: (candidate['color_identity'] as List?)?.cast<String>() ??
            const <String>[],
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
  );
  final metaDeckCount = (candidate['meta_deck_count'] as num?)?.toInt() ?? 0;
  final usageCount = (candidate['usage_count'] as num?)?.toInt() ?? 0;
  final cmc = safeToDouble(candidate['cmc']);

  var score = 0;
  score += metaDeckCount * 3;
  score += usageCount ~/ 8;

  if (_premiumCommanderFillerNames.contains(name)) {
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

int? extractRecommendedLandsFromProfile(Map<String, dynamic>? profile) {
  if (profile == null) return null;
  final structure = profile['recommended_structure'];
  if (structure is! Map) return null;
  final landsRaw = structure['lands'];
  if (landsRaw is int) return landsRaw;
  if (landsRaw is num) return landsRaw.toInt();
  if (landsRaw is String) return int.tryParse(landsRaw);
  return null;
}

List<String> extractTopCardNamesFromProfile(
  Map<String, dynamic>? profile, {
  required int limit,
}) {
  if (profile == null || limit <= 0) return const [];
  final topCardsRaw = profile['top_cards'];
  if (topCardsRaw is! List) return const [];

  return topCardsRaw
      .whereType<Map>()
      .map((entry) => (entry['name'] as String?)?.trim() ?? '')
      .where((name) => name.isNotEmpty)
      .take(limit)
      .toList();
}

List<String> extractAverageDeckSeedNamesFromProfile(
  Map<String, dynamic>? profile, {
  required int limit,
}) {
  if (profile == null || limit <= 0) return const [];
  final raw = profile['average_deck_seed'];
  if (raw is! List) return const [];

  return raw
      .whereType<Map>()
      .map((entry) => (entry['name'] as String?)?.trim() ?? '')
      .where((name) => name.isNotEmpty)
      .take(limit)
      .toList();
}

String inferFunctionalRole({
  required String name,
  required String typeLine,
  required String oracleText,
}) {
  final n = name.toLowerCase();
  final t = typeLine.toLowerCase();
  final o = oracleText.toLowerCase();

  final isRampByText = o.contains('add {') ||
      o.contains('add one mana') ||
      o.contains('search your library for a basic land') ||
      o.contains('search your library for a land');
  final isRampByName =
      n.contains('signet') || n.contains('talisman') || n.contains('sol ring');
  if (isRampByText || isRampByName) return 'ramp';

  if (o.contains('draw a card') ||
      o.contains('draw two cards') ||
      o.contains('draw three cards')) {
    return 'draw';
  }

  if ((o.contains('destroy target') || o.contains('exile target')) &&
      (o.contains('creature') ||
          o.contains('artifact') ||
          o.contains('enchantment') ||
          o.contains('permanent'))) {
    return 'removal';
  }

  if (o.contains('counter target') || o.contains('counterspell')) {
    return 'interaction';
  }

  if (o.contains('you win the game') || o.contains('each opponent loses')) {
    return 'wincon';
  }

  if (o.contains('whenever') ||
      o.contains('at the beginning of') ||
      o.contains('sacrifice')) {
    return 'engine';
  }

  if (t.contains('creature')) return 'engine';
  return 'utility';
}

bool looksLikeBoardWipe(String oracleText) {
  final oracle = oracleText.toLowerCase();
  return oracle.contains('destroy all') ||
      oracle.contains('exile all') ||
      oracle.contains('each creature') ||
      oracle.contains('each player sacrifices') ||
      oracle.contains('all colored permanents') ||
      oracle.contains('all creatures get');
}

bool looksLikeProtectionEffect({
  required String name,
  required String typeLine,
  required String oracleText,
}) {
  final normalizedName = name.toLowerCase();
  final normalizedType = typeLine.toLowerCase();
  final oracle = oracleText.toLowerCase();

  return normalizedName.contains('greaves') ||
      normalizedName.contains('boots') ||
      oracle.contains('hexproof') ||
      oracle.contains('indestructible') ||
      oracle.contains('ward') ||
      oracle.contains('phase out') ||
      oracle.contains('phases out') ||
      oracle.contains('gains shroud') ||
      (normalizedType.contains('equipment') &&
          (oracle.contains('equipped creature has') ||
              oracle.contains('equip')));
}

bool looksLikeTemporaryManaBurst({
  required String name,
  required String typeLine,
  required String oracleText,
}) {
  final normalizedName = name.toLowerCase();
  final normalizedType = typeLine.toLowerCase();
  final oracle = oracleText.toLowerCase();
  final generatesMana =
      oracle.contains('add {') || oracle.contains('add one mana');

  if (!generatesMana) return false;
  if (!(normalizedType.contains('instant') ||
      normalizedType.contains('sorcery'))) {
    return false;
  }

  return normalizedName.contains('ritual') ||
      oracle.contains('until end of turn') ||
      oracle.contains('for each');
}

String inferOptimizeFunctionalNeed({
  required String name,
  required String typeLine,
  required String oracleText,
}) {
  final normalizedType = typeLine.toLowerCase();
  final oracle = oracleText.toLowerCase();

  if (looksLikeProtectionEffect(
    name: name,
    typeLine: typeLine,
    oracleText: oracleText,
  )) {
    return 'protection';
  }

  if (looksLikeBoardWipe(oracleText)) {
    return 'wipe';
  }

  if (oracle.contains('destroy target') ||
      oracle.contains('exile target') ||
      oracle.contains('counter target')) {
    return 'removal';
  }

  if (oracle.contains('draw') || oracle.contains('cards')) {
    return 'draw';
  }

  if (oracle.contains('search your library') &&
      !normalizedType.contains('land')) {
    return oracle.contains('land') ? 'ramp' : 'tutor';
  }

  if ((looksLikeTemporaryManaBurst(
            name: name,
            typeLine: typeLine,
            oracleText: oracleText,
          ) ||
          oracle.contains('add {') ||
          oracle.contains('add one mana')) &&
      !normalizedType.contains('land')) {
    return 'ramp';
  }

  if (normalizedType.contains('artifact')) return 'artifact';
  if (normalizedType.contains('creature')) return 'creature';

  return 'utility';
}

bool matchesFunctionalNeed(
  String need, {
  required String oracleText,
  required String typeLine,
}) {
  final oracle = oracleText.toLowerCase();
  final type = typeLine.toLowerCase();

  return switch (need) {
    'draw' => oracle.contains('draw') || oracle.contains('cards'),
    'removal' => oracle.contains('destroy') ||
        oracle.contains('exile') ||
        oracle.contains('counter'),
    'wipe' => looksLikeBoardWipe(oracleText),
    'ramp' => (oracle.contains('add') && oracle.contains('mana')) ||
        oracle.contains('search your library for a land'),
    'tutor' =>
      oracle.contains('search your library') && !oracle.contains('land'),
    'protection' => oracle.contains('hexproof') ||
        oracle.contains('indestructible') ||
        oracle.contains('ward') ||
        oracle.contains('phase out') ||
        oracle.contains('phases out'),
    'creature' => type.contains('creature'),
    'artifact' => type.contains('artifact'),
    _ => true,
  };
}

int scoreOptimizeReplacementCandidate({
  required String functionalNeed,
  required String cardName,
  required String typeLine,
  required String oracleText,
  required String manaCost,
  required int popScore,
  required Set<String> preferredNames,
  required Map<String, int> rejectedAdditionCounts,
  bool preferLowCurve = false,
}) {
  final normalizedName = cardName.trim().toLowerCase();
  final normalizedType = typeLine.toLowerCase();
  final normalizedOracle = oracleText.toLowerCase();
  final estimatedCmc = _estimateManaCostCmc(manaCost);
  final matchesNeed = matchesFunctionalNeed(
    functionalNeed,
    oracleText: oracleText,
    typeLine: typeLine,
  );
  final needScore = matchesNeed ? 160 : (functionalNeed == 'utility' ? 40 : 0);
  final preferredScore = preferredNames.contains(normalizedName) ? 120 : 0;
  final popularityScore = (popScore ~/ 10).clamp(0, 90);
  final rejectionPenalty =
      ((rejectedAdditionCounts[normalizedName] ?? 0) * 35).clamp(0, 175);
  final protectionBonus =
      functionalNeed == 'protection' && normalizedOracle.contains('free')
          ? 15
          : 0;
  final offNeedPenalty = !matchesNeed && functionalNeed != 'utility' ? 90 : 0;
  final landPenalty = normalizedType.contains('land') ? 220 : 0;
  final temporaryManaPenalty = looksLikeTemporaryManaBurst(
    name: cardName,
    typeLine: typeLine,
    oracleText: oracleText,
  )
      ? (functionalNeed == 'ramp' ? 70 : 160)
      : 0;
  final lowCurveBonus = preferLowCurve
      ? ((4 - estimatedCmc).clamp(0, 4) * 18).round()
      : ((3 - estimatedCmc).clamp(0, 3) * 6).round();
  final expensiveSpellPenalty = preferLowCurve && estimatedCmc > 4
      ? ((estimatedCmc - 4) * 20).round()
      : 0;

  return needScore +
      preferredScore +
      popularityScore +
      protectionBonus +
      lowCurveBonus -
      rejectionPenalty -
      offNeedPenalty -
      landPenalty -
      temporaryManaPenalty -
      expensiveSpellPenalty;
}

double _estimateManaCostCmc(String manaCost) {
  if (manaCost.trim().isEmpty) return 0;

  final matches = RegExp(r'\{([^}]+)\}').allMatches(manaCost);
  var total = 0.0;

  for (final match in matches) {
    final symbol = (match.group(1) ?? '').trim().toUpperCase();
    if (symbol.isEmpty || symbol == 'X') continue;
    final numeric = int.tryParse(symbol);
    if (numeric != null) {
      total += numeric;
      continue;
    }
    total += 1;
  }

  return total;
}

Future<Map<String, int>> _loadRejectedOptimizeAdditionCounts({
  required Pool pool,
  required String commanderName,
}) async {
  if (commanderName.trim().isEmpty) return const <String, int>{};

  try {
    final result = await pool.execute(
      Sql.named('''
        SELECT
          LOWER(value) AS card_name,
          COUNT(*)::int AS reject_count
        FROM optimization_analysis_logs oal
        CROSS JOIN LATERAL jsonb_array_elements_text(
          COALESCE(oal.additions_list, '[]'::jsonb)
        ) AS value
        WHERE oal.operation_mode = 'optimize'
          AND LOWER(oal.commander_name) = LOWER(@commander_name)
          AND COALESCE(oal.decisions_reasoning->>'status_code', '0') <> '200'
          AND oal.created_at > NOW() - INTERVAL '180 days'
        GROUP BY LOWER(value)
        ORDER BY reject_count DESC, card_name ASC
        LIMIT 200
      '''),
      parameters: {
        'commander_name': commanderName,
      },
    );

    return {
      for (final row in result)
        (row[0] as String?) ?? '': (row[1] as int?) ?? 0,
    }..removeWhere((key, value) => key.trim().isEmpty || value <= 0);
  } catch (e) {
    Log.w('Falha ao carregar penalidades historicas de optimize: $e');
    return const <String, int>{};
  }
}

List<Map<String, dynamic>> buildDeterministicOptimizeRemovalCandidates({
  required List<Map<String, dynamic>> allCardData,
  required List<String> commanders,
  required Set<String> commanderColorIdentity,
  required String targetArchetype,
  required bool keepTheme,
  required List<String>? coreCards,
  required List<String> commanderPriorityNames,
}) {
  List<Map<String, dynamic>> buildCandidates({
    required bool allowCoreTradeoffs,
  }) {
    if (allCardData.isEmpty) return const [];

    final commanderLower =
        commanders.map((name) => name.trim().toLowerCase()).toSet();
    final coreLower = (coreCards ?? const <String>[])
        .map((name) => name.trim().toLowerCase())
        .toSet();
    final preferredNames =
        commanderPriorityNames.map((name) => name.toLowerCase()).toSet();
    final currentRoleCounts = <String, int>{};
    final roleTargets = buildRoleTargetProfile(targetArchetype);
    final structuralRecoveryScenario = isOptimizeStructuralRecoveryScenario(
      allCardData: allCardData,
      commanderColorIdentity: commanderColorIdentity,
    );
    final structuralRecoverySwapTarget =
        computeOptimizeStructuralRecoverySwapTarget(
      allCardData: allCardData,
      commanderColorIdentity: commanderColorIdentity,
      targetArchetype: targetArchetype,
    );
    var landCount = 0;

    for (final card in allCardData) {
      final qty = (card['quantity'] as int?) ?? 1;
      final typeLine = ((card['type_line'] as String?) ?? '').toLowerCase();
      if (typeLine.contains('land')) {
        landCount += qty;
        continue;
      }

      final role = inferFunctionalRole(
        name: (card['name'] as String?) ?? '',
        typeLine: (card['type_line'] as String?) ?? '',
        oracleText: (card['oracle_text'] as String?) ?? '',
      );
      currentRoleCounts[role] = (currentRoleCounts[role] ?? 0) + qty;
    }

    final removalCandidates = <Map<String, dynamic>>[];
    for (final card in allCardData) {
      final name = ((card['name'] as String?) ?? '').trim();
      if (name.isEmpty) continue;
      final lower = name.toLowerCase();
      if (commanderLower.contains(lower)) continue;

      final isCore = keepTheme && coreLower.contains(lower);
      if (isCore && !allowCoreTradeoffs) continue;

      final typeLine = (card['type_line'] as String?) ?? '';
      final isLand = typeLine.toLowerCase().contains('land');
      if (isLand) continue;

      final role = inferFunctionalRole(
        name: name,
        typeLine: typeLine,
        oracleText: (card['oracle_text'] as String?) ?? '',
      );
      final currentRole = currentRoleCounts[role] ?? 0;
      final targetRole = roleTargets[role] ?? 0;
      final surplus = (currentRole - targetRole).clamp(0, 99);
      if (surplus <= 0) continue;
      final cmc = (card['cmc'] as num?)?.toDouble() ?? 0.0;
      final preferredPenalty = preferredNames.contains(lower) ? 220 : 0;
      final corePenalty = isCore ? 240 : 0;
      final score =
          surplus * 100 + (cmc * 12).round() - preferredPenalty - corePenalty;
      if (score <= 0) continue;

      removalCandidates.add({
        'name': name,
        'role': role,
        'cmc': cmc,
        'score': score,
        'type_line': typeLine,
        'oracle_text': (card['oracle_text'] as String?) ?? '',
      });
    }

    final recommendedLandCount =
        recommendedLandCountForOptimizeArchetype(targetArchetype);
    final excessLands = landCount - recommendedLandCount;

    // Evitar cortar terrenos só porque está 1-3 acima do recomendado.
    // Em decks saudáveis (especialmente control), isso frequentemente aumenta screw.
    // Mantemos o corte de lands apenas quando há excesso material.
    if (excessLands >= 4) {
      for (final card in allCardData) {
        final name = ((card['name'] as String?) ?? '').trim();
        if (name.isEmpty) continue;

        final typeLine = ((card['type_line'] as String?) ?? '').toLowerCase();
        if (!typeLine.contains('land')) continue;

        final lower = name.toLowerCase();
        final isBasic = isBasicLandName(lower);
        final supportsColors = landProducesCommanderColors(
          card: card,
          commanderColorIdentity: commanderColorIdentity,
        );
        final tappedPenalty = (((card['oracle_text'] as String?) ?? '')
                .toLowerCase()
                .contains('enters the battlefield tapped'))
            ? 20
            : 0;
        final colorlessPenalty =
            supportsColors ? 0 : (commanderColorIdentity.isEmpty ? 0 : 70);
        final basicPenalty = isBasic ? 30 : 0;
        final score =
            excessLands * 100 + colorlessPenalty + basicPenalty + tappedPenalty;
        final copies = ((card['quantity'] as int?) ?? 1).clamp(
          1,
          excessLands.clamp(
            1,
            structuralRecoveryScenario ? structuralRecoverySwapTarget : 6,
          ),
        );

        for (var i = 0; i < copies; i++) {
          removalCandidates.add({
            'name': name,
            'role': 'land',
            'cmc': 0.0,
            'score': score - i,
            'type_line': card['type_line'],
            'oracle_text': (card['oracle_text'] as String?) ?? '',
          });
        }
      }
    }

    // Se o deck está "saudável" (sem excesso claro de papéis) o algoritmo por surplus
    // pode ficar sem alvos e acabar forçando cortes de terrenos (que frequentemente
    // pioram mana screw). Neste caso, preferimos sugerir 1-2 cortes de topo de curva
    // fora de papéis críticos para abrir espaço a upgrades mais baratos.
    final nonLandRemovalCount =
        removalCandidates.where((c) => (c['role'] as String?) != 'land').length;
    if (!structuralRecoveryScenario && nonLandRemovalCount < 2) {
      final criticalRoles = switch (targetArchetype.trim().toLowerCase()) {
        'aggro' => {'creature', 'ramp', 'removal', 'protection'},
        'control' => {'removal', 'draw', 'wipe', 'ramp', 'protection'},
        'midrange' => {'removal', 'ramp', 'draw'},
        _ => {'removal', 'ramp'},
      };

      final existing = removalCandidates
          .map((c) => ((c['name'] as String?) ?? '').trim().toLowerCase())
          .where((n) => n.isNotEmpty)
          .toSet();

      final extra = <Map<String, dynamic>>[];
      for (final card in allCardData) {
        final name = ((card['name'] as String?) ?? '').trim();
        if (name.isEmpty) continue;
        final lower = name.toLowerCase();
        if (existing.contains(lower)) continue;
        if (commanderLower.contains(lower)) continue;

        final isCore = keepTheme && coreLower.contains(lower);
        if (isCore && !allowCoreTradeoffs) continue;

        final typeLine = (card['type_line'] as String?) ?? '';
        if (typeLine.toLowerCase().contains('land')) continue;

        final cmc = (card['cmc'] as num?)?.toDouble() ?? 0.0;
        if (cmc < 6) continue;

        final role = inferFunctionalRole(
          name: name,
          typeLine: typeLine,
          oracleText: (card['oracle_text'] as String?) ?? '',
        );
        if (criticalRoles.contains(role)) continue;

        final preferredPenalty = preferredNames.contains(lower) ? 220 : 0;
        final corePenalty = isCore ? 240 : 0;
        final score = (cmc * 30).round() - preferredPenalty - corePenalty;
        if (score <= 0) continue;

        extra.add({
          'name': name,
          'role': role,
          'cmc': cmc,
          'score': score,
          'type_line': typeLine,
          'oracle_text': (card['oracle_text'] as String?) ?? '',
        });
      }

      extra.sort((a, b) {
        final byScore = (b['score'] as int).compareTo(a['score'] as int);
        if (byScore != 0) return byScore;
        return ((a['name'] as String)).compareTo(b['name'] as String);
      });

      for (final candidate in extra) {
        if (removalCandidates
                .where((c) => (c['role'] as String?) != 'land')
                .length >=
            2) {
          break;
        }
        final lower =
            ((candidate['name'] as String?) ?? '').trim().toLowerCase();
        if (lower.isEmpty || existing.contains(lower)) continue;
        removalCandidates.add(candidate);
        existing.add(lower);
      }
    }

    removalCandidates.sort((a, b) {
      final byScore = (b['score'] as int).compareTo(a['score'] as int);
      if (byScore != 0) return byScore;
      return ((a['name'] as String)).compareTo(b['name'] as String);
    });

    return removalCandidates
        .where((candidate) => (candidate['score'] as int) > 0)
        .take(structuralRecoveryScenario ? structuralRecoverySwapTarget : 6)
        .toList();
  }

  if (allCardData.isEmpty) return const [];
  final strictCandidates = buildCandidates(allowCoreTradeoffs: false);
  if (!keepTheme || strictCandidates.length >= 3) {
    return strictCandidates;
  }

  final merged = <Map<String, dynamic>>[...strictCandidates];
  final relaxedCandidates = buildCandidates(allowCoreTradeoffs: true);
  final seenNonLandNames = strictCandidates
      .where((candidate) => candidate['role'] != 'land')
      .map((candidate) => ((candidate['name'] as String?) ?? '').toLowerCase())
      .where((name) => name.isNotEmpty)
      .toSet();

  for (final candidate in relaxedCandidates) {
    final role = (candidate['role'] as String?) ?? 'utility';
    final lowerName = ((candidate['name'] as String?) ?? '').toLowerCase();
    final isLand = role == 'land';
    if (!isLand && seenNonLandNames.contains(lowerName)) continue;

    merged.add(candidate);
    if (!isLand && lowerName.isNotEmpty) {
      seenNonLandNames.add(lowerName);
    }
    if (merged.length >= 6) break;
  }

  final structuralRecoveryScenario = isOptimizeStructuralRecoveryScenario(
    allCardData: allCardData,
    commanderColorIdentity: commanderColorIdentity,
  );
  final takeCount = structuralRecoveryScenario
      ? computeOptimizeStructuralRecoverySwapTarget(
          allCardData: allCardData,
          commanderColorIdentity: commanderColorIdentity,
          targetArchetype: targetArchetype,
        )
      : 6;
  return merged.take(takeCount).toList();
}

Future<List<Map<String, dynamic>>> buildDeterministicOptimizeSwapCandidates({
  required Pool pool,
  required List<Map<String, dynamic>> allCardData,
  required List<String> commanders,
  required Set<String> commanderColorIdentity,
  required String targetArchetype,
  required int? bracket,
  required bool keepTheme,
  required String? detectedTheme,
  required List<String>? coreCards,
  required List<String> commanderPriorityNames,
}) async {
  if (allCardData.isEmpty) return const [];

  final preferredNames =
      commanderPriorityNames.map((name) => name.toLowerCase()).toSet();
  final structuralRecoveryScenario = isOptimizeStructuralRecoveryScenario(
    allCardData: allCardData,
    commanderColorIdentity: commanderColorIdentity,
  );
  final removalCandidates = buildDeterministicOptimizeRemovalCandidates(
    allCardData: allCardData,
    commanders: commanders,
    commanderColorIdentity: commanderColorIdentity,
    targetArchetype: targetArchetype,
    keepTheme: keepTheme,
    coreCards: coreCards,
    commanderPriorityNames: commanderPriorityNames,
  );
  final removalList = removalCandidates
      .map((candidate) => candidate['name'] as String)
      .toList();
  if (removalList.isEmpty) return const [];
  final functionalNeedsOverride = structuralRecoveryScenario
      ? buildStructuralRecoveryFunctionalNeeds(
          allCardData: allCardData,
          targetArchetype: targetArchetype,
          limit: removalList.length,
        )
      : null;

  final deckNamesLower = allCardData
      .map((c) => ((c['name'] as String?) ?? '').toLowerCase())
      .where((n) => n.isNotEmpty)
      .toSet();
  final replacements = await findSynergyReplacements(
    pool: pool,
    commanders: commanders,
    commanderColorIdentity: commanderColorIdentity,
    targetArchetype: targetArchetype,
    bracket: bracket,
    keepTheme: keepTheme,
    detectedTheme: detectedTheme,
    coreCards: coreCards,
    missingCount: removalList.length,
    removedCards: removalList,
    functionalNeedsOverride: functionalNeedsOverride,
    excludeNames: deckNamesLower,
    allCardData: allCardData,
    preferredNames: preferredNames,
    preferLowCurve: structuralRecoveryScenario,
  );
  if (replacements.length < removalList.length) {
    final usedReplacementNames = replacements
        .map((replacement) =>
            ((replacement['name'] as String?) ?? '').trim().toLowerCase())
        .where((name) => name.isNotEmpty)
        .toSet();
    final fillerPool = await loadDeterministicSlotFillers(
      pool: pool,
      currentDeckCards: allCardData,
      targetArchetype: targetArchetype,
      commanderColorIdentity: commanderColorIdentity,
      bracket: bracket,
      excludeNames: deckNamesLower.union(usedReplacementNames),
      preferredNames: preferredNames,
      limit: removalList.length - replacements.length,
    );
    for (final filler in fillerPool) {
      if (replacements.length >= removalList.length) break;
      final lowerName =
          ((filler['name'] as String?) ?? '').trim().toLowerCase();
      if (lowerName.isEmpty || usedReplacementNames.contains(lowerName)) {
        continue;
      }
      replacements.add({
        'id': filler['id'],
        'name': filler['name'],
      });
      usedReplacementNames.add(lowerName);
    }
  }

  final pairCount = removalList.length < replacements.length
      ? removalList.length
      : replacements.length;
  final pairs = <Map<String, dynamic>>[];
  for (var i = 0; i < pairCount; i++) {
    final removalName = removalList[i];
    final replacement = replacements[i];
    final removalMeta = removalCandidates.firstWhere(
      (candidate) => candidate['name'] == removalName,
      orElse: () => const <String, dynamic>{},
    );

    pairs.add({
      'remove': removalName,
      'add': replacement['name'],
      'remove_role': removalMeta['role'],
      'reason':
          'swap deterministico priorizando funcao ${removalMeta['role'] ?? 'utility'} e pool competitivo do comandante',
    });
  }

  // Em decks já saudáveis, reduzir o número de swaps diminui risco de regressão.
  final maxPairs = structuralRecoveryScenario
      ? computeOptimizeStructuralRecoverySwapTarget(
          allCardData: allCardData,
          commanderColorIdentity: commanderColorIdentity,
          targetArchetype: targetArchetype,
        )
      : 2;

  return pairs.take(maxPairs).toList();
}

Map<String, dynamic> buildDeterministicOptimizeResponse({
  required List<Map<String, dynamic>> deterministicSwapCandidates,
  required String targetArchetype,
}) {
  final swaps = deterministicSwapCandidates
      .where((candidate) =>
          (candidate['remove']?.toString().trim().isNotEmpty ?? false) &&
          (candidate['add']?.toString().trim().isNotEmpty ?? false))
      .map((candidate) => {
            'out': candidate['remove'],
            'in': candidate['add'],
            if (candidate['reason'] != null) 'reason': candidate['reason'],
            'priority': 'High',
          })
      .toList();

  return {
    'mode': 'optimize',
    'strategy_source': 'deterministic_first',
    'reasoning':
        'O backend priorizou swaps determinísticos para $targetArchetype antes da IA, usando função das cartas, prioridade competitiva do comandante e histórico de rejeição.',
    'swaps': swaps,
  };
}

String resolveOptimizeArchetype({
  required String requestedArchetype,
  required String? detectedArchetype,
}) {
  final requested = requestedArchetype.trim().toLowerCase();
  final detected = detectedArchetype?.trim().toLowerCase() ?? '';

  if (requested.isEmpty) return detected.isNotEmpty ? detected : 'midrange';
  if (detected.isEmpty || detected == 'unknown') return requested;
  if (requested == detected) return requested;

  const genericRequested = {'midrange', 'value', 'goodstuff'};
  const specificDetected = {'aggro', 'control', 'combo', 'stax', 'tribal'};

  if (genericRequested.contains(requested) &&
      specificDetected.contains(detected)) {
    return detected;
  }

  return requested;
}

bool shouldRetryOptimizeWithAiFallback({
  required bool deterministicFirstEnabled,
  required bool fallbackAlreadyAttempted,
  required String? strategySource,
  required String? qualityErrorCode,
  required bool isComplete,
}) {
  if (!deterministicFirstEnabled || fallbackAlreadyAttempted || isComplete) {
    return false;
  }

  if (strategySource != 'deterministic_first') return false;

  return qualityErrorCode == 'OPTIMIZE_NO_SAFE_SWAPS' ||
      qualityErrorCode == 'OPTIMIZE_QUALITY_REJECTED';
}

String buildOptimizeDeckSignature(List<ResultRow> cardsResult) {
  final entries = <String>[];
  for (final row in cardsResult) {
    final cardId = row[9].toString();
    final quantity = (row[2] as int?) ?? 1;
    entries.add('$cardId:$quantity');
  }
  entries.sort();
  return entries.join('|');
}

String buildOptimizeCacheKey({
  required String deckId,
  required String archetype,
  required String mode,
  required int? bracket,
  required bool keepTheme,
  required String deckSignature,
}) {
  final base = [
    'optimize',
    mode.toLowerCase().trim(),
    deckId,
    archetype.toLowerCase().trim(),
    '${bracket ?? 'none'}',
    keepTheme ? 'keep' : 'free',
    deckSignature,
  ].join('::');
  return 'v6:${_stableHash(base)}';
}

String _stableHash(String value) {
  var hash = 2166136261;
  for (final code in value.codeUnits) {
    hash ^= code;
    hash = (hash * 16777619) & 0xFFFFFFFF;
  }
  return hash.toRadixString(16);
}

Future<Map<String, dynamic>?> loadOptimizeCache({
  required Pool pool,
  required String cacheKey,
}) async {
  final result = await pool.execute(
    Sql.named('''
      SELECT payload
      FROM ai_optimize_cache
      WHERE cache_key = @cache_key
        AND expires_at > NOW()
      ORDER BY created_at DESC
      LIMIT 1
    '''),
    parameters: {
      'cache_key': cacheKey,
    },
  );

  if (result.isEmpty) return null;
  final payload = result.first[0];
  if (payload is Map<String, dynamic>)
    return Map<String, dynamic>.from(payload);
  if (payload is Map) return payload.cast<String, dynamic>();
  return null;
}

Future<List<Map<String, dynamic>>> loadUniversalCommanderFallbacks({
  required Pool pool,
  required Set<String> excludeNames,
  Set<String> commanderColorIdentity = const <String>{},
  required int limit,
}) async {
  if (limit <= 0) return const [];

  const preferred = <String>[
    'Sol Ring',
    'Arcane Signet',
    'Command Tower',
    'Mind Stone',
    'Wayfarer\'s Bauble',
    'Swiftfoot Boots',
    'Lightning Greaves',
    'Swords to Plowshares',
    'Path to Exile',
    'Beast Within',
    'Generous Gift',
    'Counterspell',
    'Negate',
    'Arcane Denial',
    'Brainstorm',
    'Swan Song',
    'Mystical Tutor',
    'Cyclonic Rift',
    'Rhystic Study',
    'Ponder',
    'Preordain',
    'Fact or Fiction',
    'Read the Bones',
    'Cultivate',
    'Kodama\'s Reach',
    'Farseek',
    'Nature\'s Lore',
    'Three Visits',
  ];

  final filteredPreferred = preferred
      .where((name) => !excludeNames.contains(name.toLowerCase()))
      .toList();
  if (filteredPreferred.isEmpty) return const [];

  final result = await pool.execute(
    Sql.named('''
      SELECT id::text, name, type_line, oracle_text, mana_cost, colors, color_identity
      FROM cards
      WHERE name = ANY(@names)
      ORDER BY name ASC
      LIMIT @limit
    '''),
    parameters: {
      'names': filteredPreferred,
      'limit': limit,
    },
  );

  final mapped = result
      .map((row) => {
            'id': row[0] as String,
            'name': row[1] as String,
            'type_line': (row[2] as String?) ?? '',
            'oracle_text': (row[3] as String?) ?? '',
            'mana_cost': (row[4] as String?) ?? '',
            'colors': (row[5] as List?)?.cast<String>() ?? const <String>[],
            'color_identity':
                (row[6] as List?)?.cast<String>() ?? const <String>[],
          })
      .where(
        (candidate) => shouldKeepCommanderFillerCandidate(
          candidate: candidate,
          excludeNames: excludeNames,
          commanderColorIdentity: commanderColorIdentity,
          enforceCommanderIdentity: true,
        ),
      )
      .toList();

  return dedupeCandidatesByName(mapped).take(limit).toList();
}

Future<List<Map<String, dynamic>>> loadArchetypeCommanderFoundationFillers({
  required Pool pool,
  required Set<String> commanderColorIdentity,
  required String targetArchetype,
  required String? detectedTheme,
  required Set<String> excludeNames,
  required int limit,
}) async {
  if (limit <= 0) return const [];

  final identity = commanderColorIdentity.map((e) => e.toUpperCase()).toSet();
  final archetype = targetArchetype.toLowerCase();
  final theme = (detectedTheme ?? '').toLowerCase();
  final names = <String>{
    'The One Ring',
    'Fellwar Stone',
    'Swiftfoot Boots',
    'Mystic Remora',
    'Swan Song',
    'An Offer You Can\'t Refuse',
  };

  if (identity.length == 1 && identity.contains('U')) {
    names.addAll(const {
      'Fabricate',
      'Merchant Scroll',
      'Muddle the Mixture',
      'Pongify',
      'Rapid Hybridization',
      'Reality Shift',
      'Resculpt',
      'Spell Pierce',
      'Solve the Equation',
      'Windfall',
      'Whir of Invention',
    });

    if (archetype.contains('combo') || archetype.contains('control')) {
      names.addAll(const {
        'High Tide',
        'Jace, Wielder of Mysteries',
        'Long-Term Plans',
        'Personal Tutor',
        'Transmute Artifact',
        'Tezzeret the Seeker',
      });
    }

    if (theme.contains('proliferate') || theme.contains('phyrexian')) {
      names.addAll(const {
        'Contentious Plan',
        'Experimental Augury',
        'Inexorable Tide',
        'Prologue to Phyresis',
        'Tekuthal, Inquiry Dominus',
        'Tezzeret\'s Gambit',
        'Thrummingbird',
      });
    }
  }

  final filteredNames = names
      .where((name) => !excludeNames.contains(name.toLowerCase()))
      .toList();
  if (filteredNames.isEmpty) return const [];

  final result = await pool.execute(
    Sql.named('''
      SELECT c.id::text, c.name, c.type_line, c.oracle_text, c.mana_cost, c.colors, c.color_identity, c.cmc,
             COALESCE(cmi.meta_deck_count, 0) AS meta_deck_count,
             COALESCE(cmi.usage_count, 0) AS usage_count
      FROM cards c
      LEFT JOIN card_meta_insights cmi ON LOWER(cmi.card_name) = LOWER(c.name)
      LEFT JOIN card_legalities cl ON cl.card_id = c.id AND cl.format = 'commander'
      WHERE (cl.status = 'legal' OR cl.status = 'restricted' OR cl.status IS NULL)
        AND LOWER(c.name) IN (SELECT LOWER(unnest(@names::text[])))
        AND c.type_line NOT ILIKE '%land%'
      ORDER BY COALESCE(cmi.meta_deck_count, 0) DESC,
               COALESCE(cmi.usage_count, 0) DESC,
               c.name ASC
      LIMIT @limit
    '''),
    parameters: {
      'names': filteredNames,
      'limit': limit * 2,
    },
  );

  final mapped = result
      .map((row) => {
            'id': row[0] as String,
            'name': row[1] as String,
            'type_line': (row[2] as String?) ?? '',
            'oracle_text': (row[3] as String?) ?? '',
            'mana_cost': (row[4] as String?) ?? '',
            'colors': (row[5] as List?)?.cast<String>() ?? const <String>[],
            'color_identity':
                (row[6] as List?)?.cast<String>() ?? const <String>[],
            'cmc': safeToDouble(row[7]),
            'meta_deck_count': (row[8] as num?)?.toInt() ?? 0,
            'usage_count': (row[9] as num?)?.toInt() ?? 0,
          })
      .where(
        (candidate) => shouldKeepCommanderFillerCandidate(
          candidate: candidate,
          excludeNames: excludeNames,
          commanderColorIdentity: commanderColorIdentity,
          enforceCommanderIdentity: true,
        ),
      )
      .toList();

  final deduped = dedupeCandidatesByName(mapped);
  deduped.sort((a, b) {
    final byQuality = commanderFillerQualityScore(b)
        .compareTo(commanderFillerQualityScore(a));
    if (byQuality != 0) return byQuality;
    return ((a['name'] as String?) ?? '')
        .compareTo((b['name'] as String?) ?? '');
  });
  return deduped.take(limit).toList();
}

Future<List<String>> loadCommanderCompetitivePriorities({
  required Pool pool,
  required String commanderName,
  required int limit,
}) async {
  if (commanderName.trim().isEmpty || limit <= 0) return const [];

  var result = await pool.execute(
    Sql.named('''
      SELECT card_list
      FROM meta_decks
      WHERE format IN ('EDH', 'cEDH')
        AND card_list ILIKE @commanderPattern
      ORDER BY created_at DESC
      LIMIT 200
    '''),
    parameters: {
      'commanderPattern': '%${commanderName.replaceAll('%', '')}%',
    },
  );

  if (result.isEmpty) {
    final commanderToken = commanderName.split(',').first.trim();
    if (commanderToken.isNotEmpty) {
      result = await pool.execute(
        Sql.named('''
          SELECT card_list
          FROM meta_decks
          WHERE format IN ('EDH', 'cEDH')
            AND archetype ILIKE @archetypePattern
          ORDER BY created_at DESC
          LIMIT 200
        '''),
        parameters: {
          'archetypePattern': '%${commanderToken.replaceAll('%', '')}%',
        },
      );
    }
  }

  if (result.isEmpty) {
    List<dynamic> fallback = const [];
    try {
      fallback = await pool.execute(
        Sql.named('''
          SELECT card_name, usage_count, meta_deck_count
          FROM card_meta_insights
          WHERE @commander = ANY(common_commanders)
          ORDER BY meta_deck_count DESC, usage_count DESC, card_name ASC
          LIMIT @limit
        '''),
        parameters: {
          'commander': commanderName,
          'limit': limit,
        },
      );
    } catch (_) {
      fallback = const [];
    }

    if (fallback.isEmpty) return const [];

    return fallback
        .map((row) => (row[0] as String?) ?? '')
        .where((name) => name.trim().isNotEmpty)
        .take(limit)
        .toList();
  }

  final commanderLower = commanderName.trim().toLowerCase();
  final counts = <String, int>{};

  for (final row in result) {
    final raw = (row[0] as String?) ?? '';
    if (raw.trim().isEmpty) continue;

    var inSideboard = false;
    final lines = raw.split('\n');
    for (final lineRaw in lines) {
      final line = lineRaw.trim();
      if (line.isEmpty) continue;
      if (line.toLowerCase().contains('sideboard')) {
        inSideboard = true;
        continue;
      }
      if (inSideboard) continue;

      final match = RegExp(r'^(\d+)x?\s+(.+)$').firstMatch(line);
      if (match == null) continue;

      final quantity = int.tryParse(match.group(1) ?? '1') ?? 1;
      var cardName = (match.group(2) ?? '').trim();
      if (cardName.isEmpty) continue;

      cardName = cardName.replaceAll(RegExp(r'\s*\([^)]+\)\s*$'), '').trim();
      if (cardName.isEmpty) continue;

      final lower = cardName.toLowerCase();
      if (lower == commanderLower || _isBasicLandName(lower)) continue;

      counts[cardName] = (counts[cardName] ?? 0) + quantity;
    }
  }

  final sorted = counts.entries.toList()
    ..sort((a, b) {
      final byCount = b.value.compareTo(a.value);
      if (byCount != 0) return byCount;
      return a.key.compareTo(b.key);
    });

  return sorted.take(limit).map((e) => e.key).toList();
}

Future<Map<String, dynamic>?> loadCommanderReferenceProfileFromCache({
  required Pool pool,
  required String commanderName,
}) async {
  if (commanderName.trim().isEmpty) return null;

  try {
    final result = await pool.execute(
      Sql.named('''
        SELECT profile_json
        FROM commander_reference_profiles
        WHERE LOWER(commander_name) = LOWER(@commander)
        LIMIT 1
      '''),
      parameters: {'commander': commanderName},
    );

    if (result.isEmpty) return null;
    final payload = result.first[0];
    if (payload is Map<String, dynamic>)
      return Map<String, dynamic>.from(payload);
    if (payload is Map) return payload.cast<String, dynamic>();
    return null;
  } catch (_) {
    return null;
  }
}

Future<void> saveOptimizeCache({
  required Pool pool,
  required String cacheKey,
  required String? userId,
  required String deckId,
  required String deckSignature,
  required Map<String, dynamic> payload,
}) async {
  await pool.execute(
    Sql.named('''
      INSERT INTO ai_optimize_cache (
        cache_key,
        user_id,
        deck_id,
        deck_signature,
        payload,
        expires_at
      ) VALUES (
        @cache_key,
        CAST(@user_id AS uuid),
        CAST(@deck_id AS uuid),
        @deck_signature,
        @payload,
        NOW() + INTERVAL '6 hours'
      )
      ON CONFLICT (cache_key)
      DO UPDATE SET
        user_id = EXCLUDED.user_id,
        deck_id = EXCLUDED.deck_id,
        deck_signature = EXCLUDED.deck_signature,
        payload = EXCLUDED.payload,
        expires_at = EXCLUDED.expires_at,
        created_at = NOW()
    '''),
    parameters: {
      'cache_key': cacheKey,
      'user_id': userId,
      'deck_id': deckId,
      'deck_signature': deckSignature,
      'payload': payload,
    },
  );

  await pool.execute('''
    DELETE FROM ai_optimize_cache
    WHERE expires_at <= NOW()
  ''');
}

Future<Map<String, dynamic>> loadUserAiPreferences({
  required Pool pool,
  required String? userId,
}) async {
  if (userId == null || userId.isEmpty) {
    return const {
      'preferred_bracket': null,
      'keep_theme_default': true,
    };
  }

  final result = await pool.execute(
    Sql.named('''
      SELECT preferred_archetype, preferred_bracket, keep_theme_default
      FROM ai_user_preferences
      WHERE user_id = CAST(@user_id AS uuid)
      LIMIT 1
    '''),
    parameters: {
      'user_id': userId,
    },
  );

  if (result.isEmpty) {
    return const {
      'preferred_bracket': null,
      'keep_theme_default': true,
    };
  }

  final row = result.first;
  return {
    'preferred_archetype': row[0] as String?,
    'preferred_bracket': row[1] as int?,
    'keep_theme_default': row[2] as bool? ?? true,
  };
}

Future<void> saveUserAiPreferences({
  required Pool pool,
  required String? userId,
  required String preferredArchetype,
  required int? preferredBracket,
  required bool keepThemeDefault,
  required List<String> preferredColors,
}) async {
  if (userId == null || userId.isEmpty) return;

  await pool.execute(
    Sql.named('''
      INSERT INTO ai_user_preferences (
        user_id,
        preferred_archetype,
        preferred_bracket,
        keep_theme_default,
        preferred_colors,
        updated_at
      ) VALUES (
        CAST(@user_id AS uuid),
        @preferred_archetype,
        @preferred_bracket,
        @keep_theme_default,
        @preferred_colors,
        NOW()
      )
      ON CONFLICT (user_id)
      DO UPDATE SET
        preferred_archetype = EXCLUDED.preferred_archetype,
        preferred_bracket = EXCLUDED.preferred_bracket,
        keep_theme_default = EXCLUDED.keep_theme_default,
        preferred_colors = EXCLUDED.preferred_colors,
        updated_at = NOW()
    '''),
    parameters: {
      'user_id': userId,
      'preferred_archetype': preferredArchetype,
      'preferred_bracket': preferredBracket,
      'keep_theme_default': keepThemeDefault,
      'preferred_colors': preferredColors,
    },
  );
}

Map<String, dynamic> buildOptimizeRecommendationDetail({
  required String type,
  required String name,
  required String cardId,
  required int quantity,
  required String targetArchetype,
  required String confidenceLevel,
  required double cmcBefore,
  required double cmcAfter,
  required bool keepTheme,
}) {
  final confidenceScore = _confidenceScoreFromLevel(confidenceLevel);
  final action = type == 'add' ? 'entrada' : 'saída';
  final curveDelta = (cmcAfter - cmcBefore).toStringAsFixed(2);
  final isBasicLand = _isBasicLandName(name);

  return {
    'type': type,
    'name': name,
    'card_id': cardId,
    'quantity': quantity,
    'is_basic_land': isBasicLand,
    'reason':
        'Sugestão de $action para alinhar o deck ao plano ${targetArchetype.toLowerCase()} e melhorar consistência geral.',
    'confidence': {
      'level': confidenceLevel,
      'score': confidenceScore,
    },
    'impact_estimate': {
      'curve': 'ΔCMC $curveDelta',
      'consistency': keepTheme ? 'alta' : 'média',
      'synergy': type == 'add' ? 'melhora' : 'ajuste',
      'legality': 'mantida',
    },
  };
}

double _confidenceScoreFromLevel(String level) {
  switch (level.toLowerCase()) {
    case 'alta':
    case 'high':
      return 0.9;
    case 'média':
    case 'media':
    case 'medium':
      return 0.7;
    default:
      return 0.5;
  }
}

Future<void> recordOptimizeFallbackTelemetry({
  required Pool pool,
  required String? userId,
  required String? deckId,
  required String mode,
  required bool recognizedFormat,
  required bool triggered,
  required bool applied,
  required bool noCandidate,
  required bool noReplacement,
  required int candidateCount,
  required int replacementCount,
  required int pairCount,
}) async {
  await pool.execute(
    Sql.named('''
      INSERT INTO ai_optimize_fallback_telemetry (
        user_id,
        deck_id,
        mode,
        recognized_format,
        triggered,
        applied,
        no_candidate,
        no_replacement,
        candidate_count,
        replacement_count,
        pair_count
      ) VALUES (
        CAST(@user_id AS uuid),
        CAST(@deck_id AS uuid),
        @mode,
        @recognized_format,
        @triggered,
        @applied,
        @no_candidate,
        @no_replacement,
        @candidate_count,
        @replacement_count,
        @pair_count
      )
    '''),
    parameters: {
      'user_id': userId,
      'deck_id': deckId,
      'mode': mode,
      'recognized_format': recognizedFormat,
      'triggered': triggered,
      'applied': applied,
      'no_candidate': noCandidate,
      'no_replacement': noReplacement,
      'candidate_count': candidateCount,
      'replacement_count': replacementCount,
      'pair_count': pairCount,
    },
  );
}

Future<Map<String, dynamic>> loadPersistedEmptyFallbackAggregate(
  Pool pool,
) async {
  final result = await pool.execute('''
    SELECT
      COUNT(*)::int AS total_requests,
      SUM(CASE WHEN triggered THEN 1 ELSE 0 END)::int AS triggered_count,
      SUM(CASE WHEN applied THEN 1 ELSE 0 END)::int AS applied_count,
      SUM(CASE WHEN no_candidate THEN 1 ELSE 0 END)::int AS no_candidate_count,
      SUM(CASE WHEN no_replacement THEN 1 ELSE 0 END)::int AS no_replacement_count,
      COUNT(*) FILTER (WHERE created_at >= NOW() - INTERVAL '24 hours')::int AS total_requests_24h,
      SUM(CASE WHEN triggered AND created_at >= NOW() - INTERVAL '24 hours' THEN 1 ELSE 0 END)::int AS triggered_count_24h,
      SUM(CASE WHEN applied AND created_at >= NOW() - INTERVAL '24 hours' THEN 1 ELSE 0 END)::int AS applied_count_24h,
      SUM(CASE WHEN no_candidate AND created_at >= NOW() - INTERVAL '24 hours' THEN 1 ELSE 0 END)::int AS no_candidate_count_24h,
      SUM(CASE WHEN no_replacement AND created_at >= NOW() - INTERVAL '24 hours' THEN 1 ELSE 0 END)::int AS no_replacement_count_24h
    FROM ai_optimize_fallback_telemetry
  ''');

  if (result.isEmpty) {
    return {
      'all_time': {
        'request_count': 0,
        'triggered_count': 0,
        'applied_count': 0,
        'no_candidate_count': 0,
        'no_replacement_count': 0,
        'trigger_rate': 0.0,
        'apply_rate': 0.0,
      },
      'last_24h': {
        'request_count': 0,
        'triggered_count': 0,
        'applied_count': 0,
        'no_candidate_count': 0,
        'no_replacement_count': 0,
        'trigger_rate': 0.0,
        'apply_rate': 0.0,
      },
    };
  }

  final row = result.first.toColumnMap();

  final allRequests = _toInt(row['total_requests']);
  final allTriggered = _toInt(row['triggered_count']);
  final allApplied = _toInt(row['applied_count']);
  final allNoCandidate = _toInt(row['no_candidate_count']);
  final allNoReplacement = _toInt(row['no_replacement_count']);

  final requests24h = _toInt(row['total_requests_24h']);
  final triggered24h = _toInt(row['triggered_count_24h']);
  final applied24h = _toInt(row['applied_count_24h']);
  final noCandidate24h = _toInt(row['no_candidate_count_24h']);
  final noReplacement24h = _toInt(row['no_replacement_count_24h']);

  return {
    'all_time': {
      'request_count': allRequests,
      'triggered_count': allTriggered,
      'applied_count': allApplied,
      'no_candidate_count': allNoCandidate,
      'no_replacement_count': allNoReplacement,
      'trigger_rate': allRequests > 0 ? allTriggered / allRequests : 0.0,
      'apply_rate': allTriggered > 0 ? allApplied / allTriggered : 0.0,
    },
    'last_24h': {
      'request_count': requests24h,
      'triggered_count': triggered24h,
      'applied_count': applied24h,
      'no_candidate_count': noCandidate24h,
      'no_replacement_count': noReplacement24h,
      'trigger_rate': requests24h > 0 ? triggered24h / requests24h : 0.0,
      'apply_rate': triggered24h > 0 ? applied24h / triggered24h : 0.0,
    },
  };
}

int _toInt(dynamic value) {
  if (value == null) return 0;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString()) ?? 0;
}

bool _isBasicLandName(String name) {
  final normalized = name.trim().toLowerCase();
  return normalized == 'plains' ||
      normalized == 'island' ||
      normalized == 'swamp' ||
      normalized == 'mountain' ||
      normalized == 'forest' ||
      normalized == 'wastes' ||
      normalized == 'snow-covered plains' ||
      normalized == 'snow-covered island' ||
      normalized == 'snow-covered swamp' ||
      normalized == 'snow-covered mountain' ||
      normalized == 'snow-covered forest';
}
