import 'package:postgres/postgres.dart';

import '../basic_land_utils.dart' as basic_lands;
import '../color_identity.dart';
import '../edh_bracket_policy.dart';
import '../logger.dart';
import 'commander_fallback_policy.dart';
import 'optimize_filler_candidate_support.dart';
import 'optimize_functional_role_support.dart';
import 'optimization_ramp_profile.dart';

export 'optimize_filler_candidate_support.dart';

Future<Map<String, String>> loadBasicLandIds(
  Pool pool,
  List<String> names,
) async {
  if (names.isEmpty) return const {};
  final result = await pool.execute(
    Sql.named('''
      WITH input_names AS (
        SELECT DISTINCT
          TRIM(value) AS input_name,
          LOWER(TRIM(value)) AS normalized_input_name
        FROM unnest(@names::text[]) AS value
        WHERE TRIM(value) <> ''
      ),
      ranked AS (
        SELECT
          input_names.input_name,
          cib.card_id::text AS card_id,
          ROW_NUMBER() OVER (
            PARTITION BY input_names.input_name
            ORDER BY
              CASE
                WHEN cib.normalized_lookup_name =
                     input_names.normalized_input_name THEN 0
                WHEN cib.normalized_canonical_name =
                     input_names.normalized_input_name THEN 1
                WHEN cib.normalized_canonical_name LIKE
                     input_names.normalized_input_name || ' // %' THEN 2
                ELSE 3
              END,
              COALESCE(cib.match_priority, 999),
              cib.card_id::text
          ) AS resolution_rank
        FROM input_names
        JOIN card_identity_bridge cib
          ON cib.normalized_lookup_name =
               input_names.normalized_input_name
          OR cib.normalized_canonical_name =
               input_names.normalized_input_name
          OR cib.normalized_canonical_name LIKE
               input_names.normalized_input_name || ' // %'
        WHERE COALESCE(cib.type_line, '') ~*
          '(^|[^[:alpha:]])basic[[:space:]]+(snow[[:space:]]+)?land([^[:alpha:]]|\$)'
      )
      SELECT input_name, card_id
      FROM ranked
      WHERE resolution_rank = 1
      ORDER BY input_name ASC
    '''),
    parameters: {'names': TypedValue(Type.textArray, names)},
  );
  final map = <String, String>{};
  for (final row in result) {
    final n = row[0].toString();
    final id = row[1].toString();
    map[n] = id;
  }
  return map;
}

Future<List<Map<String, dynamic>>> loadIdentitySafeNonBasicLandFillers({
  required Pool pool,
  required Set<String> commanderColorIdentity,
  required Set<String> excludeNames,
  List<Map<String, dynamic>> currentDeckCards = const <Map<String, dynamic>>[],
  int? bracket,
  required int limit,
  String deckFormat = 'commander',
}) async {
  if (limit <= 0) return const [];

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
          c.color_identity AS color_identity,
          COALESCE(cmi.usage_count, 0) AS pop_score
        FROM cards c
        LEFT JOIN card_legalities cl
          ON cl.card_id = c.id AND cl.format = @legality_format
        LEFT JOIN card_meta_insights cmi ON LOWER(cmi.card_name) = LOWER(c.name)
        WHERE (cl.status = 'legal' OR cl.status = 'restricted' OR cl.status IS NULL)
          AND COALESCE(c.type_line, '') ~* '(^|[^a-z])land([^a-z]|\$)'
          AND NOT (COALESCE(c.type_line, '') ~* '(^|[^[:alpha:]])basic[[:space:]]+(snow[[:space:]]+)?land([^[:alpha:]]|\$)')
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
      'legality_format': deckFormat.trim().toLowerCase(),
    },
  );

  final candidates = <Map<String, dynamic>>[];
  for (final row in result) {
    final candidate = <String, dynamic>{
      'id': row[0] as String,
      'name': row[1] as String,
      'type_line': (row[2] as String?) ?? '',
      'oracle_text': (row[3] as String?) ?? '',
      'colors': (row[4] as List?)?.cast<String>() ?? const <String>[],
      'color_identity': (row[5] as List?)?.cast<String>(),
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
    final identityCount =
        resolvedCardIdentityFromParts(
          colorIdentity: (candidate['color_identity'] as List?)?.cast<String>(),
          colors:
              (candidate['colors'] as List?)?.cast<String>() ??
              const <String>[],
          oracleText: candidate['oracle_text'] as String?,
        ).length;

    var fixingScore = (candidate['pop_score'] as int?) ?? 0;
    if (commanderPremiumFixingLandNames.contains(name)) fixingScore += 250;
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
    if (basic_lands.isLandTypeLine(typeLine)) {
      fixingScore += 30;
    }
    if (oracle.contains('enters tapped')) {
      fixingScore -= 20;
    }

    candidates.add({...candidate, 'fixing_score': fixingScore});
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
    return ((a['name'] as String?) ?? '').compareTo(
      (b['name'] as String?) ?? '',
    );
  });

  return filterCandidatesByBracketPolicy(
    candidates: dedupeCandidatesByName(candidates),
    bracket: bracket,
    currentDeckCards: currentDeckCards,
  ).take(limit).toList();
}

int recommendedLandCountForOptimizeArchetype(String targetArchetype) {
  final archetype = targetArchetype.toLowerCase();
  if (archetype.contains('aggro')) return 34;
  if (archetype.contains('combo')) return 33;
  if (archetype.contains('control')) return 37;
  return 35;
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

    if (basic_lands.isLandTypeLine(typeLine)) {
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
    if (basic_lands.isLandTypeLine(typeLine)) {
      landCount += qty;
    } else {
      nonLandCount += qty;
    }
  }

  final recommendedLandCount = recommendedLandCountForOptimizeArchetype(
    targetArchetype,
  );
  final excessLands = (landCount - recommendedLandCount).clamp(0, 99);
  final missingNonLands = (58 - nonLandCount).clamp(0, 99);

  return [
    12,
    excessLands,
    missingNonLands,
  ].reduce((a, b) => a < b ? a : b).clamp(6, 12);
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
      'wipe': 2,
      'protection': 6,
      'utility': 18,
    },
    'aggro' => const <String, int>{
      'creature': 18,
      'ramp': 8,
      'draw': 8,
      'removal': 8,
      'wipe': 1,
      'protection': 4,
      'utility': 14,
    },
    _ => const <String, int>{
      'draw': 12,
      'ramp': 10,
      'removal': 8,
      'wipe': 2,
      'creature': 8,
      'protection': 4,
      'utility': 16,
    },
  };

  final currentCounts = <String, int>{};
  for (final card in allCardData) {
    final qty = (card['quantity'] as int?) ?? 1;
    final typeLine = ((card['type_line'] as String?) ?? '').toLowerCase();
    if (basic_lands.isLandTypeLine(typeLine)) continue;

    final role = inferOptimizeFunctionalNeed(
      name: (card['name'] as String?) ?? '',
      typeLine: (card['type_line'] as String?) ?? '',
      oracleText: (card['oracle_text'] as String?) ?? '',
    );
    if (role == 'ramp' &&
        !optimizationRampProfileForCard(card).countsTowardGenericFloor) {
      continue;
    }
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
    'wipe': minimumCommanderWipeCountForArchetype(targetArchetype),
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
    'wipe': 0,
    'interaction': 0,
    'engine': 0,
    'wincon': 0,
    'utility': 0,
  };

  var nonLandTotal = 0;
  for (final c in currentDeckCards) {
    final typeLine = ((c['type_line'] as String?) ?? '').toLowerCase();
    if (basic_lands.isLandTypeLine(typeLine)) continue;

    final qty = (c['quantity'] as int?) ?? 1;
    final role = inferFunctionalRoleForCard(c);
    if (role == 'ramp' &&
        !optimizationRampProfileForCard(c).countsTowardGenericFloor) {
      nonLandTotal += qty;
      continue;
    }
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
    final coveredByRoleDeficits = needs.values.fold<int>(
      0,
      (sum, value) => sum + value,
    );
    final uncoveredSlots = (missingNonLand - coveredByRoleDeficits).clamp(
      0,
      58,
    );
    needs['utility'] = (needs['utility'] ?? 0) + uncoveredSlots;
  }

  return needs;
}

List<Map<String, dynamic>> selectDeterministicSlotCandidates({
  required List<Map<String, dynamic>> candidates,
  required Map<String, int> slotNeeds,
  required int limit,
  int? bracket,
  Set<String> preferredNames = const <String>{},
}) {
  if (limit <= 0 || candidates.isEmpty) return const [];

  final normalizedPreferred =
      preferredNames
          .map((name) => name.trim().toLowerCase())
          .where((name) => name.isNotEmpty)
          .toSet();
  final enriched = <Map<String, dynamic>>[];
  for (var index = 0; index < candidates.length; index++) {
    final candidate = candidates[index];
    final role = inferFunctionalRoleForCard(candidate);
    final countsTowardRole =
        role != 'ramp' ||
        optimizationRampProfileForCard(candidate).countsTowardGenericFloor;
    enriched.add({
      ...candidate,
      '_slot_role': countsTowardRole ? role : 'utility',
      '_slot_order': index,
      '_slot_preferred': normalizedPreferred.contains(
        candidate['name']?.toString().trim().toLowerCase() ?? '',
      ),
      '_slot_intent_penalty': commanderBracketIntentPenalty(
        candidate,
        bracket: bracket,
      ),
    });
  }

  int compareCandidates(Map<String, dynamic> a, Map<String, dynamic> b) {
    final penaltyA = (a['_slot_intent_penalty'] as int?) ?? 0;
    final penaltyB = (b['_slot_intent_penalty'] as int?) ?? 0;
    final byPenalty = penaltyA.compareTo(penaltyB);
    if (byPenalty != 0) return byPenalty;

    final preferredA = a['_slot_preferred'] == true ? 1 : 0;
    final preferredB = b['_slot_preferred'] == true ? 1 : 0;
    final byPreferred = preferredB.compareTo(preferredA);
    if (byPreferred != 0) return byPreferred;

    final orderA = (a['_slot_order'] as int?) ?? 0;
    final orderB = (b['_slot_order'] as int?) ?? 0;
    final byOrder = orderA.compareTo(orderB);
    if (byOrder != 0) return byOrder;
    return (a['name']?.toString() ?? '').compareTo(b['name']?.toString() ?? '');
  }

  final byRole = <String, List<Map<String, dynamic>>>{};
  for (final candidate in enriched) {
    final role = candidate['_slot_role'] as String? ?? 'utility';
    byRole.putIfAbsent(role, () => <Map<String, dynamic>>[]).add(candidate);
  }
  for (final roleCandidates in byRole.values) {
    roleCandidates.sort(compareCandidates);
  }

  final remainingNeeds = <String, int>{
    for (final entry in slotNeeds.entries)
      if (entry.value > 0) entry.key: entry.value,
  };
  final roleOrder =
      remainingNeeds.keys.toList()..sort((a, b) {
        final byNeed = (remainingNeeds[b] ?? 0).compareTo(
          remainingNeeds[a] ?? 0,
        );
        if (byNeed != 0) return byNeed;
        return a.compareTo(b);
      });
  final selected = <Map<String, dynamic>>[];
  final selectedNames = <String>{};

  while (selected.length < limit) {
    var addedInRound = false;
    for (final role in roleOrder) {
      if (selected.length >= limit) break;
      final remaining = remainingNeeds[role] ?? 0;
      if (remaining <= 0) continue;
      final pool = byRole[role];
      if (pool == null || pool.isEmpty) continue;

      Map<String, dynamic>? next;
      while (pool.isNotEmpty && next == null) {
        final candidate = pool.removeAt(0);
        final name = candidate['name']?.toString().trim().toLowerCase() ?? '';
        if (name.isEmpty || selectedNames.contains(name)) continue;
        next = candidate;
      }
      if (next == null) continue;

      selected.add(next);
      selectedNames.add(next['name']?.toString().trim().toLowerCase() ?? '');
      remainingNeeds[role] = remaining - 1;
      addedInRound = true;
    }
    if (!addedInRound) break;
  }

  if (selected.length < limit) {
    final remaining =
        enriched.where((candidate) {
            final name =
                candidate['name']?.toString().trim().toLowerCase() ?? '';
            return name.isNotEmpty && !selectedNames.contains(name);
          }).toList()
          ..sort(compareCandidates);
    for (final candidate in remaining) {
      if (selected.length >= limit) break;
      final name = candidate['name']?.toString().trim().toLowerCase() ?? '';
      if (!selectedNames.add(name)) continue;
      selected.add(candidate);
    }
  }

  return selected
      .take(limit)
      .map((candidate) {
        final result =
            Map<String, dynamic>.from(candidate)
              ..remove('_slot_role')
              ..remove('_slot_order')
              ..remove('_slot_preferred')
              ..remove('_slot_intent_penalty');
        return result;
      })
      .toList(growable: false);
}

int commanderBracketIntentPenalty(
  Map<String, dynamic> candidate, {
  required int? bracket,
}) {
  if (bracket == null || bracket >= 4) return 0;
  final tags =
      tagCardForBracket(
        name: candidate['name']?.toString() ?? '',
        typeLine: candidate['type_line']?.toString() ?? '',
        oracleText: candidate['oracle_text']?.toString() ?? '',
      ).categories;
  final multiplier = bracket == 1 ? 2 : 1;
  var penalty = 0;
  if (tags.contains(BracketCategory.gameChanger)) penalty += 10000;
  if (tags.contains(BracketCategory.infiniteCombo)) penalty += 160 * multiplier;
  if (tags.contains(BracketCategory.extraTurns)) penalty += 220 * multiplier;
  if (tags.contains(BracketCategory.freeInteraction)) {
    penalty += 80 * multiplier;
  }
  if (tags.contains(BracketCategory.stax)) penalty += 70 * multiplier;
  if (tags.contains(BracketCategory.fastMana)) penalty += 50 * multiplier;
  return penalty;
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
  String deckFormat = 'commander',
}) async {
  if (limit <= 0) return const [];

  final slotNeeds = buildSlotNeedsForDeck(
    currentDeckCards: currentDeckCards,
    targetArchetype: targetArchetype,
  );

  final candidates = await loadCompetitiveNonLandFillers(
    pool: pool,
    currentDeckCards: currentDeckCards,
    commanderColorIdentity: commanderColorIdentity,
    bracket: bracket,
    excludeNames: excludeNames,
    limit: limit < 80 ? 240 : (limit * 4),
    deckFormat: deckFormat,
  );

  if (candidates.isEmpty) return const [];

  final selected = selectDeterministicSlotCandidates(
    candidates: candidates,
    slotNeeds: slotNeeds,
    limit: limit,
    bracket: bracket,
    preferredNames: preferredNames ?? const <String>{},
  );

  return selected.map((e) {
    return {
      'id': e['id'],
      'name': e['name'],
      'type_line': e['type_line'],
      'oracle_text': e['oracle_text'],
      'mana_cost': e['mana_cost'],
      'cmc': e['cmc'],
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
  String deckFormat = 'commander',
}) async {
  if (limit <= 0) return const [];

  final identity = commanderColorIdentity.toList();
  final result = await pool.execute(
    Sql.named('''
      SELECT c.id::text, c.name, c.type_line, c.oracle_text, c.mana_cost, c.colors, c.color_identity, c.cmc,
             mi.meta_deck_count, mi.usage_count
      FROM card_meta_insights mi
      JOIN cards c ON LOWER(c.name) = LOWER(mi.card_name)
      LEFT JOIN card_legalities cl
        ON cl.card_id = c.id AND cl.format = @legality_format
      WHERE (cl.status = 'legal' OR cl.status = 'restricted' OR cl.status IS NULL)
        AND NOT (COALESCE(c.type_line, '') ~* '(^|[^a-z])land([^a-z]|\$)')
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
      'legality_format': deckFormat.trim().toLowerCase(),
    },
  );

  final mapped =
      result
          .map(
            (row) => {
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
            },
          )
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
    final byQuality = commanderFillerQualityScore(
      b,
    ).compareTo(commanderFillerQualityScore(a));
    if (byQuality != 0) return byQuality;
    return ((a['name'] as String?) ?? '').compareTo(
      (b['name'] as String?) ?? '',
    );
  });
  return deduped.take(limit).toList();
}

Future<List<Map<String, dynamic>>> loadBroadCommanderNonLandFillers({
  required Pool pool,
  required List<Map<String, dynamic>> currentDeckCards,
  required Set<String> commanderColorIdentity,
  required Set<String> excludeNames,
  required int? bracket,
  required int limit,
  String deckFormat = 'commander',
}) async {
  if (limit <= 0) return const [];

  final identity = commanderColorIdentity.toList();
  Log.d(
    '  [broad] start limit=$limit identity=${identity.join(',')} exclude=${excludeNames.length}',
  );
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
      LEFT JOIN card_legalities cl
        ON cl.card_id = c.id AND cl.format = @legality_format
      LEFT JOIN card_meta_insights cmi ON LOWER(cmi.card_name) = LOWER(c.name)
      WHERE (cl.status = 'legal' OR cl.status = 'restricted' OR cl.status IS NULL)
        AND NOT (COALESCE(c.type_line, '') ~* '(^|[^a-z])land([^a-z]|\$)')
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
      'legality_format': deckFormat.trim().toLowerCase(),
    },
  );

  Log.d('  [broad] sql rows=${result.length}');

  var candidates =
      result
          .map(
            (row) => {
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
            },
          )
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
    final byQuality = commanderFillerQualityScore(
      b,
    ).compareTo(commanderFillerQualityScore(a));
    if (byQuality != 0) return byQuality;
    return ((a['name'] as String?) ?? '').compareTo(
      (b['name'] as String?) ?? '',
    );
  });
  Log.d('  [broad] dedup rows=${candidates.length}');

  if (bracket != null && candidates.isNotEmpty) {
    final decision = applyBracketPolicyToAdditions(
      bracket: bracket,
      currentDeckCards: currentDeckCards,
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
    final filtered =
        candidates
            .where(
              (c) => allowedSet.contains((c['name'] as String).toLowerCase()),
            )
            .toList();
    Log.d(
      '  [broad] bracket=$bracket allowed=${allowedSet.length} filtered=${filtered.length}',
    );
    candidates = filtered;
  }

  Log.d('  [broad] final rows=${candidates.length}');
  return dedupeCandidatesByName(candidates).take(limit).toList();
}

List<Map<String, dynamic>> selectCommanderWipeFloorCandidates({
  required List<Map<String, dynamic>> candidates,
  required List<Map<String, dynamic>> currentDeckCards,
  required int? bracket,
  required int limit,
}) {
  if (limit <= 0 || candidates.isEmpty) return const [];

  final exactWipes = dedupeCandidatesByName(
    candidates
        .where(
          (candidate) =>
              countOptimizationFunctionalRole([candidate], role: 'wipe') > 0,
        )
        .toList(growable: false),
  ).toList(growable: true);
  final bracketSafe = filterCandidatesByBracketPolicy(
    candidates: exactWipes,
    bracket: bracket,
    currentDeckCards: currentDeckCards,
  );

  bracketSafe.sort((a, b) {
    final byIntent = commanderBracketIntentPenalty(
      a,
      bracket: bracket,
    ).compareTo(commanderBracketIntentPenalty(b, bracket: bracket));
    if (byIntent != 0) return byIntent;

    final byRoleScore = ((b['best_role_score'] as num?)?.toDouble() ?? 0)
        .compareTo((a['best_role_score'] as num?)?.toDouble() ?? 0);
    if (byRoleScore != 0) return byRoleScore;

    final byQuality = commanderFillerQualityScore(
      b,
    ).compareTo(commanderFillerQualityScore(a));
    if (byQuality != 0) return byQuality;

    return (a['name']?.toString() ?? '').compareTo(b['name']?.toString() ?? '');
  });

  return bracketSafe.take(limit).toList(growable: false);
}

Future<List<Map<String, dynamic>>> loadCommanderWipeFloorCandidates({
  required Pool pool,
  required List<Map<String, dynamic>> currentDeckCards,
  required Set<String> commanderColorIdentity,
  required Set<String> excludeNames,
  required int? bracket,
  required int limit,
  String deckFormat = 'commander',
}) async {
  if (limit <= 0) return const [];

  final result = await pool.execute(
    Sql.named('''
      SELECT
        ranked.id,
        ranked.name,
        ranked.type_line,
        ranked.oracle_text,
        ranked.mana_cost,
        ranked.colors,
        ranked.color_identity,
        ranked.cmc,
        ranked.meta_deck_count,
        ranked.usage_count,
        ranked.functional_tags,
        ranked.semantic_tags_v2,
        ranked.best_role_score
      FROM (
        SELECT DISTINCT ON (LOWER(c.name))
          c.id::text AS id,
          c.name,
          c.type_line,
          c.oracle_text,
          c.mana_cost,
          c.colors,
          c.color_identity,
          c.cmc,
          COALESCE(cmi.meta_deck_count, 0) AS meta_deck_count,
          COALESCE(cmi.usage_count, 0) AS usage_count,
          ARRAY(
            SELECT DISTINCT value
            FROM unnest(
              COALESCE(cis.function_tags, ARRAY[]::text[]) ||
              COALESCE(cis.scored_roles, ARRAY[]::text[])
            ) AS role(value)
            WHERE value IS NOT NULL AND TRIM(value) <> ''
          ) AS functional_tags,
          COALESCE(cis.semantic_tags_v2, '[]'::jsonb) AS semantic_tags_v2,
          COALESCE(cis.best_role_score, 0) AS best_role_score
        FROM cards c
        LEFT JOIN card_legalities cl
          ON cl.card_id = c.id AND cl.format = @legality_format
        LEFT JOIN card_meta_insights cmi
          ON LOWER(cmi.card_name) = LOWER(c.name)
        LEFT JOIN card_intelligence_snapshot cis ON cis.card_id = c.id
        WHERE
          (cl.status = 'legal' OR cl.status = 'restricted' OR cl.status IS NULL)
          AND LOWER(c.name) NOT IN (
            SELECT LOWER(unnest(@exclude::text[]))
          )
          AND NOT (
            COALESCE(c.type_line, '') ~*
              '(^|[^a-z])land([^a-z]|\$)'
          )
          AND c.name NOT LIKE 'A-%'
          AND c.name NOT LIKE '\\_%' ESCAPE '\\'
          AND c.name NOT LIKE '%World Champion%'
          AND c.name NOT LIKE '%Heroes of the Realm%'
          AND c.oracle_text IS NOT NULL
          AND LENGTH(TRIM(c.oracle_text)) > 0
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
          AND (
            COALESCE(cis.function_tags, ARRAY[]::text[]) &&
              ARRAY['wipe', 'board_wipe']::text[]
            OR COALESCE(cis.scored_roles, ARRAY[]::text[]) &&
              ARRAY['wipe', 'board_wipe']::text[]
            OR COALESCE(c.oracle_text, '') ~*
              '(destroy|exile)[[:space:]]+all'
            OR LOWER(COALESCE(c.oracle_text, '')) LIKE
              '%return all nonland permanents%'
            OR LOWER(COALESCE(c.oracle_text, '')) LIKE
              '%return all creatures%'
            OR (
              LOWER(COALESCE(c.oracle_text, '')) LIKE
                '%return to their owners'' hands all%'
              AND (
                LOWER(COALESCE(c.oracle_text, '')) LIKE '%creatures%'
                OR LOWER(COALESCE(c.oracle_text, '')) LIKE
                  '%nonland permanents%'
              )
            )
            OR LOWER(COALESCE(c.oracle_text, '')) LIKE
              '%all creatures get -%'
            OR LOWER(COALESCE(c.oracle_text, '')) LIKE
              '%each creature gets -%'
            OR LOWER(COALESCE(c.oracle_text, '')) LIKE
              '%all colored permanents%'
            OR LOWER(COALESCE(c.oracle_text, '')) LIKE
              '%each player sacrifices all%'
            OR LOWER(COALESCE(c.oracle_text, '')) LIKE
              '%each opponent sacrifices all%'
            OR LOWER(COALESCE(c.oracle_text, '')) LIKE
              '%damage to each creature%'
            OR (
              LOWER(COALESCE(c.oracle_text, '')) LIKE '%deals%'
              AND LOWER(COALESCE(c.oracle_text, '')) LIKE '%damage%'
              AND LOWER(COALESCE(c.oracle_text, '')) LIKE
                '%to each creature%'
            )
          )
        ORDER BY
          LOWER(c.name),
          COALESCE(cmi.usage_count, 0) DESC,
          c.id
      ) ranked
      ORDER BY
        ranked.best_role_score DESC,
        ranked.meta_deck_count DESC,
        ranked.usage_count DESC,
        ranked.cmc ASC NULLS LAST,
        LOWER(ranked.name) ASC
      LIMIT 600
    '''),
    parameters: {
      'exclude': excludeNames.toList(growable: false),
      'identity': commanderColorIdentity.toList(growable: false),
      'legality_format': deckFormat.trim().toLowerCase(),
    },
  );

  final candidates = result
      .map(
        (row) => <String, dynamic>{
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
          'functional_tags':
              (row[10] as List?)
                  ?.map((entry) => entry.toString())
                  .toList(growable: false) ??
              const <String>[],
          'semantic_tags_v2': row[11],
          'best_role_score': (row[12] as num?)?.toDouble() ?? 0,
        },
      )
      .where(
        (candidate) => shouldKeepCommanderFillerCandidate(
          candidate: candidate,
          excludeNames: excludeNames,
          commanderColorIdentity: commanderColorIdentity,
          enforceCommanderIdentity: true,
        ),
      )
      .toList(growable: false);

  return selectCommanderWipeFloorCandidates(
    candidates: candidates,
    currentDeckCards: currentDeckCards,
    bracket: bracket,
    limit: limit,
  );
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
  String deckFormat = 'commander',
}) async {
  if (limit <= 0) return const [];

  final aggregated = <Map<String, dynamic>>[];
  final seen = <String>{};
  List<Map<String, dynamic>> bracketSnapshot() => [
    ...currentDeckCards,
    ...aggregated,
  ];

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
    deckFormat: deckFormat,
  );
  addUnique(withBracket);

  if (aggregated.length < limit && bracket == null) {
    final noBracket = await loadDeterministicSlotFillers(
      pool: pool,
      currentDeckCards: bracketSnapshot(),
      targetArchetype: targetArchetype,
      commanderColorIdentity: commanderColorIdentity,
      bracket: null,
      excludeNames: excludeNames.union(seen),
      preferredNames: preferredNames,
      limit: limit - aggregated.length,
      deckFormat: deckFormat,
    );
    addUnique(noBracket);
  }

  if (aggregated.length < limit) {
    final metaFillers = await loadMetaInsightFillers(
      pool: pool,
      commanderColorIdentity: commanderColorIdentity,
      excludeNames: excludeNames.union(seen),
      limit: limit - aggregated.length,
      deckFormat: deckFormat,
    );
    addUnique(
      filterCandidatesByBracketPolicy(
        candidates: metaFillers,
        bracket: bracket,
        currentDeckCards: bracketSnapshot(),
      ),
    );
  }

  if (aggregated.length < limit) {
    final broadWithBracket = await loadBroadCommanderNonLandFillers(
      pool: pool,
      currentDeckCards: bracketSnapshot(),
      commanderColorIdentity: commanderColorIdentity,
      excludeNames: excludeNames.union(seen),
      bracket: bracket,
      limit: limit - aggregated.length,
      deckFormat: deckFormat,
    );
    addUnique(broadWithBracket);
  }

  if (aggregated.length < limit && bracket == null) {
    final broadNoBracket = await loadBroadCommanderNonLandFillers(
      pool: pool,
      currentDeckCards: bracketSnapshot(),
      commanderColorIdentity: commanderColorIdentity,
      excludeNames: excludeNames.union(seen),
      bracket: null,
      limit: limit - aggregated.length,
      deckFormat: deckFormat,
    );
    addUnique(broadNoBracket);
  }

  return aggregated.take(limit).toList();
}

Future<List<Map<String, dynamic>>> loadCompetitiveNonLandFillers({
  required Pool pool,
  required List<Map<String, dynamic>> currentDeckCards,
  required Set<String> commanderColorIdentity,
  required int? bracket,
  required Set<String> excludeNames,
  required int limit,
  String deckFormat = 'commander',
}) async {
  if (limit <= 0) return const [];

  final identity = commanderColorIdentity.toList();
  final result = await pool.execute(
    Sql.named('''
      SELECT sub.id, sub.name, sub.type_line, sub.oracle_text, sub.mana_cost,
             sub.colors, sub.color_identity, sub.cmc
      FROM (
        SELECT DISTINCT ON (LOWER(c.name))
          c.id::text, c.name, c.type_line, c.oracle_text, c.mana_cost,
          c.colors, c.color_identity, c.cmc,
          COALESCE(cmi.usage_count, 0) AS pop_score
        FROM cards c
        LEFT JOIN card_legalities cl
          ON cl.card_id = c.id AND cl.format = @legality_format
        LEFT JOIN card_meta_insights cmi ON LOWER(cmi.card_name) = LOWER(c.name)
        WHERE (cl.status = 'legal' OR cl.status = 'restricted' OR cl.status IS NULL)
          AND NOT (COALESCE(c.type_line, '') ~* '(^|[^a-z])land([^a-z]|\$)')
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
      'legality_format': deckFormat.trim().toLowerCase(),
    },
  );

  var candidates =
      result
          .map(
            (row) => {
              'id': row[0] as String,
              'name': row[1] as String,
              'type_line': (row[2] as String?) ?? '',
              'oracle_text': (row[3] as String?) ?? '',
              'mana_cost': (row[4] as String?) ?? '',
              'colors': (row[5] as List?)?.cast<String>() ?? const <String>[],
              'color_identity':
                  (row[6] as List?)?.cast<String>() ?? const <String>[],
              'cmc': safeToDouble(row[7]),
            },
          )
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
    final stapleResult = await pool.execute(
      Sql.named('''
        SELECT DISTINCT ON (LOWER(c.name))
               c.id::text, c.name, c.type_line, c.oracle_text, c.mana_cost,
               c.colors, c.color_identity, c.cmc
        FROM cards c
        LEFT JOIN card_legalities cl
          ON cl.card_id = c.id AND cl.format = @legality_format
        WHERE (cl.status = 'legal' OR cl.status = 'restricted' OR cl.status IS NULL)
          AND LOWER(c.name) IN (SELECT LOWER(unnest(@names::text[])))
          AND (
            c.color_identity <@ @identity::text[]
            OR c.color_identity = '{}'
          )
        ORDER BY LOWER(c.name), c.id
      '''),
      parameters: {
        'names': commanderCompletionStapleNames,
        'identity': identity,
        'legality_format': deckFormat.trim().toLowerCase(),
      },
    );
    final stapleCandidates =
        stapleResult
            .map(
              (row) => {
                'id': row[0] as String,
                'name': row[1] as String,
                'type_line': (row[2] as String?) ?? '',
                'oracle_text': (row[3] as String?) ?? '',
                'mana_cost': (row[4] as String?) ?? '',
                'colors': (row[5] as List?)?.cast<String>() ?? const <String>[],
                'color_identity':
                    (row[6] as List?)?.cast<String>() ?? const <String>[],
                'cmc': safeToDouble(row[7]),
              },
            )
            .where(
              (c) =>
                  !excludeNames.contains((c['name'] as String).toLowerCase()),
            )
            .toList();
    candidates.addAll(stapleCandidates);
    candidates = dedupeCandidatesByName(candidates);
    if (candidates.isEmpty) {
      print('[COMPLETE FILLER] Pool vazio, fallback para staples universais.');
    } else if (stapleCandidates.isNotEmpty) {
      print(
        '[COMPLETE FILLER] Pool expandido com staples universais: ${stapleCandidates.length}',
      );
    }
  }

  if (bracket != null && candidates.isNotEmpty) {
    final decision = applyBracketPolicyToAdditions(
      bracket: bracket,
      currentDeckCards: currentDeckCards,
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
    final filtered =
        candidates
            .where(
              (c) => allowedSet.contains((c['name'] as String).toLowerCase()),
            )
            .toList();

    candidates = filtered;
  }

  return dedupeCandidatesByName(candidates).take(limit).toList();
}

Future<List<Map<String, dynamic>>> loadEmergencyNonBasicFillers({
  required Pool pool,
  required List<Map<String, dynamic>> currentDeckCards,
  required Set<String> commanderColorIdentity,
  required Set<String> excludeNames,
  required int? bracket,
  required int limit,
  String deckFormat = 'commander',
}) async {
  if (limit <= 0) return const [];

  final result = await pool.execute(
    Sql.named('''
      SELECT sub.id, sub.name, sub.type_line, sub.oracle_text, sub.mana_cost,
             sub.colors, sub.color_identity, sub.cmc
      FROM (
        SELECT DISTINCT ON (LOWER(c.name))
          c.id::text, c.name, c.type_line, c.oracle_text, c.mana_cost,
          c.colors, c.color_identity, c.cmc,
          COALESCE(cmi.usage_count, 0) AS pop_score
        FROM cards c
        LEFT JOIN card_legalities cl
          ON cl.card_id = c.id AND cl.format = @legality_format
        LEFT JOIN card_meta_insights cmi ON LOWER(cmi.card_name) = LOWER(c.name)
        WHERE (cl.status = 'legal' OR cl.status = 'restricted' OR cl.status IS NULL)
          AND NOT (COALESCE(c.type_line, '') ~* '(^|[^a-z])land([^a-z]|\$)')
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
      'legality_format': deckFormat.trim().toLowerCase(),
    },
  );

  var candidates =
      result
          .map(
            (row) => {
              'id': row[0] as String,
              'name': row[1] as String,
              'type_line': (row[2] as String?) ?? '',
              'oracle_text': (row[3] as String?) ?? '',
              'mana_cost': (row[4] as String?) ?? '',
              'colors': (row[5] as List?)?.cast<String>() ?? const <String>[],
              'color_identity':
                  (row[6] as List?)?.cast<String>() ?? const <String>[],
              'cmc': safeToDouble(row[7]),
            },
          )
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

  if (bracket != null && candidates.isNotEmpty) {
    final decision = applyBracketPolicyToAdditions(
      bracket: bracket,
      currentDeckCards: currentDeckCards,
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
    final filtered =
        candidates
            .where(
              (c) => allowedSet.contains((c['name'] as String).toLowerCase()),
            )
            .toList();
    candidates = filtered;
  }

  return dedupeCandidatesByName(candidates).take(limit).toList();
}

List<Map<String, dynamic>> filterCandidatesByBracketPolicy({
  required List<Map<String, dynamic>> candidates,
  required int? bracket,
  required List<Map<String, dynamic>> currentDeckCards,
}) {
  if (bracket == null || candidates.isEmpty) return candidates;

  final decision = applyBracketPolicyToAdditions(
    bracket: bracket,
    currentDeckCards: currentDeckCards,
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
  return candidates
      .where((c) => allowedSet.contains((c['name'] as String).toLowerCase()))
      .toList();
}

Future<List<Map<String, dynamic>>> loadIdentitySafeNonLandFillers({
  required Pool pool,
  required Set<String> commanderColorIdentity,
  required Set<String> excludeNames,
  List<Map<String, dynamic>> currentDeckCards = const <Map<String, dynamic>>[],
  int? bracket,
  required int limit,
  String deckFormat = 'commander',
}) async {
  if (limit <= 0) return const [];

  Log.d(
    '  [identity-safe] start limit=$limit identity=${commanderColorIdentity.join(',')} exclude=${excludeNames.length}',
  );

  final result = await pool.execute(
    Sql.named('''
      SELECT sub.id, sub.name, sub.type_line, sub.oracle_text, sub.mana_cost,
             sub.colors, sub.color_identity, sub.cmc
      FROM (
        SELECT DISTINCT ON (LOWER(c.name))
          c.id::text, c.name, c.type_line, c.oracle_text, c.mana_cost,
          c.colors, c.color_identity, c.cmc,
          COALESCE(cmi.usage_count, 0) AS pop_score
        FROM cards c
        LEFT JOIN card_legalities cl
          ON cl.card_id = c.id AND cl.format = @legality_format
        LEFT JOIN card_meta_insights cmi ON LOWER(cmi.card_name) = LOWER(c.name)
        WHERE (cl.status = 'legal' OR cl.status = 'restricted' OR cl.status IS NULL)
          AND NOT (COALESCE(c.type_line, '') ~* '(^|[^a-z])land([^a-z]|\$)')
          AND c.name NOT LIKE 'A-%'
          AND c.name NOT LIKE '\\_%' ESCAPE '\\'
          AND c.name NOT LIKE '%World Champion%'
          AND c.name NOT LIKE '%Heroes of the Realm%'
        ORDER BY LOWER(c.name), COALESCE(cmi.usage_count, 0) DESC
      ) sub
      ORDER BY sub.pop_score DESC, RANDOM()
      LIMIT 4000
    '''),
    parameters: {'legality_format': deckFormat.trim().toLowerCase()},
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
    final colorIdentity = (row[6] as List?)?.cast<String>();
    final cmc = safeToDouble(row[7]);

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
      'cmc': cmc,
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

  return filterCandidatesByBracketPolicy(
    candidates: dedupeCandidatesByName(filtered),
    bracket: bracket,
    currentDeckCards: currentDeckCards,
  ).take(limit).toList();
}

Future<List<Map<String, dynamic>>> loadPreferredNameFillers({
  required Pool pool,
  required Set<String> preferredNames,
  required Set<String> commanderColorIdentity,
  required Set<String> excludeNames,
  List<Map<String, dynamic>> currentDeckCards = const <Map<String, dynamic>>[],
  int? bracket,
  required int limit,
  String deckFormat = 'commander',
}) async {
  if (limit <= 0 || preferredNames.isEmpty) return const [];

  final normalizedPreferred =
      preferredNames
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
      LEFT JOIN card_legalities cl
        ON cl.card_id = c.id AND cl.format = @legality_format
      WHERE LOWER(name) = ANY(@preferred::text[])
        AND (cl.status = 'legal' OR cl.status = 'restricted' OR cl.status IS NULL)
        AND NOT (COALESCE(type_line, '') ~* '(^|[^a-z])land([^a-z]|\$)')
      ORDER BY COALESCE(cmi.meta_deck_count, 0) DESC,
               COALESCE(cmi.usage_count, 0) DESC,
               c.name ASC
    '''),
    parameters: {
      'preferred': normalizedPreferred.toList(),
      'legality_format': deckFormat.trim().toLowerCase(),
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
    final colorIdentity = (row[6] as List?)?.cast<String>();

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
    final byQuality = commanderFillerQualityScore(
      b,
    ).compareTo(commanderFillerQualityScore(a));
    if (byQuality != 0) return byQuality;
    return ((a['name'] as String?) ?? '').compareTo(
      (b['name'] as String?) ?? '',
    );
  });

  final floor = filtered.length > limit ? 25 : -999;
  final qualityFiltered =
      filtered
          .where((candidate) => commanderFillerQualityScore(candidate) >= floor)
          .toList();
  final source = qualityFiltered.isNotEmpty ? qualityFiltered : filtered;

  return filterCandidatesByBracketPolicy(
    candidates: dedupeCandidatesByName(source),
    bracket: bracket,
    currentDeckCards: currentDeckCards,
  ).take(limit).toList();
}
