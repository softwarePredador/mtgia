import 'package:postgres/postgres.dart';
import '../basic_land_utils.dart' as basic_lands;
import '../color_identity.dart';
import '../logger.dart';
import 'functional_card_tags.dart';
import '../meta/meta_deck_reference_support.dart';
import '../meta/meta_deck_format_support.dart';
import 'commander_fallback_policy.dart';
import 'optimize_archetype_support.dart' as archetype_support;
import 'optimize_cache_support.dart' as optimize_cache;
import 'optimize_candidate_quality_support.dart';
export 'optimize_candidate_quality_support.dart';
import 'optimize_functional_role_support.dart';
export 'optimize_functional_role_support.dart';
import 'optimize_filler_loader_support.dart';
export 'optimize_filler_loader_support.dart';
import 'optimize_removal_candidate_support.dart';
export 'optimize_removal_candidate_support.dart';

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

class OptimizeIntensityConfig {
  const OptimizeIntensityConfig({
    required this.selected,
    required this.requested,
    required this.source,
    required this.targetMin,
    required this.targetMax,
    this.valid = true,
  });

  final String selected;
  final String? requested;
  final String source;
  final int targetMin;
  final int targetMax;
  final bool valid;

  bool get isRebuild => selected == 'rebuild';
  bool get wasOmitted => source == 'omitted_default';

  int clampRequestedSwapCount(int count) {
    if (targetMax <= 0) return 0;
    return count.clamp(0, targetMax);
  }

  Map<String, dynamic> toJson({
    int? candidateSwaps,
    int? returnedSwaps,
    int? qualityGateDropped,
  }) {
    final returned = returnedSwaps;
    final dropped = qualityGateDropped ?? 0;
    return {
      'selected': selected,
      'requested': requested,
      'source': source,
      'target_swaps': {
        'min': targetMin,
        'max': targetMax,
      },
      'quality_gate': {
        'can_reduce_scope': true,
        if (dropped > 0) 'dropped_swaps': dropped,
        if (returned != null && returned < targetMin && selected != 'rebuild')
          'reduced_below_target': true,
      },
      if (candidateSwaps != null) 'candidate_swaps': candidateSwaps,
      if (returned != null) 'returned_swaps': returned,
    };
  }
}

bool shouldUseAsyncOptimizeExecutor({
  required OptimizeIntensityConfig intensity,
  required String requestMode,
  required bool forceSync,
  bool? asyncRequested,
}) {
  if (forceSync) return false;
  if (requestMode != 'optimize') return false;
  if (intensity.isRebuild) return false;
  if (asyncRequested == false) return false;
  return asyncRequested == true || intensity.selected == 'aggressive';
}

OptimizeIntensityConfig resolveOptimizeIntensity(dynamic raw) {
  if (raw == null || raw.toString().trim().isEmpty) {
    return const OptimizeIntensityConfig(
      selected: 'focused',
      requested: null,
      source: 'omitted_default',
      targetMin: 6,
      targetMax: 10,
    );
  }

  final requested = raw.toString().trim().toLowerCase();
  final normalized = switch (requested) {
    'conservative' || 'safe' || 'leve' => 'light',
    'default' || 'balanced' || 'balanceado' => 'focused',
    'strong' || 'hard' || 'alta' => 'aggressive',
    'reconstruct' || 'reconstruction' || 'full_rebuild' => 'rebuild',
    _ => requested,
  };

  switch (normalized) {
    case 'light':
      return OptimizeIntensityConfig(
        selected: 'light',
        requested: requested,
        source: 'explicit',
        targetMin: 3,
        targetMax: 5,
      );
    case 'focused':
      return OptimizeIntensityConfig(
        selected: 'focused',
        requested: requested,
        source: 'explicit',
        targetMin: 6,
        targetMax: 10,
      );
    case 'aggressive':
      return OptimizeIntensityConfig(
        selected: 'aggressive',
        requested: requested,
        source: 'explicit',
        targetMin: 10,
        targetMax: 20,
      );
    case 'rebuild':
      return OptimizeIntensityConfig(
        selected: 'rebuild',
        requested: requested,
        source: 'explicit',
        targetMin: 0,
        targetMax: 0,
      );
    default:
      return OptimizeIntensityConfig(
        selected: 'focused',
        requested: requested,
        source: 'invalid',
        targetMin: 6,
        targetMax: 10,
        valid: false,
      );
  }
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

bool isBasicLandName(String name) => basic_lands.isBasicLandName(name);

bool isBasicLandTypeLine(String typeLineLower) {
  return basic_lands.isBasicLandTypeLine(typeLineLower);
}

int maxCopiesForFormat({
  required String deckFormat,
  required String typeLine,
  required String name,
}) {
  final normalizedFormat = deckFormat.toLowerCase();
  final normalizedType = typeLine.toLowerCase();

  final isBasicLand =
      isBasicLandTypeLine(normalizedType) || basic_lands.isBasicLandName(name);
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
  int swapLimit = 6,
  String intensity = 'focused',
  Map<String, dynamic>? diagnosticsOut,
}) async {
  if (allCardData.isEmpty) return const [];
  final effectiveSwapLimit = swapLimit.clamp(1, 20).toInt();
  final isAggressive = intensity.trim().toLowerCase() == 'aggressive';
  final candidateSearchLimit = isAggressive
      ? (effectiveSwapLimit * 3).clamp(effectiveSwapLimit, 60).toInt()
      : effectiveSwapLimit;

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
    swapLimit: candidateSearchLimit,
  );
  final removalList = removalCandidates
      .map((candidate) => candidate['name'] as String)
      .toList();
  if (removalList.isEmpty) {
    if (isAggressive && diagnosticsOut != null) {
      diagnosticsOut
        ..['requested_target_swaps'] = effectiveSwapLimit
        ..['removal_candidates'] = 0
        ..['replacement_candidates'] = 0
        ..['pairs_generated'] = 0
        ..['candidate_sources'] = const <String>[]
        ..['low_candidate_coverage'] = true;
    }
    return const [];
  }
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
      'remove_score': removalMeta['score'],
      'reason':
          'swap deterministico priorizando funcao ${removalMeta['role'] ?? 'utility'} e pool competitivo do comandante',
    });
  }

  if (isAggressive && pairs.isNotEmpty) {
    final signals = await loadAggressiveCandidateQualitySignals(
      pool: pool,
      candidateNames: pairs.map((pair) => '${pair['add']}').toList(),
      commanders: commanders,
      targetArchetype: targetArchetype,
      bracket: bracket,
    );
    final ranked = rankAggressiveCandidateQualityPairs(
      pairs: pairs,
      signalsByName: signals,
      bracket: bracket,
    );
    pairs
      ..clear()
      ..addAll(ranked);
    if (diagnosticsOut != null) {
      final candidateSources = signals.values
          .expand((signal) => signal.sources)
          .toSet()
          .toList()
        ..sort();
      diagnosticsOut
        ..['requested_target_swaps'] = effectiveSwapLimit
        ..['removal_candidates'] = removalCandidates.length
        ..['replacement_candidates'] = replacements.length
        ..['pairs_generated'] = pairs.length
        ..['candidate_sources'] = candidateSources
        ..['low_candidate_coverage'] = pairs.length < effectiveSwapLimit
        ..['ranked_before_quality_gate'] = true;
    }
  } else if (isAggressive && diagnosticsOut != null) {
    diagnosticsOut
      ..['requested_target_swaps'] = effectiveSwapLimit
      ..['removal_candidates'] = removalCandidates.length
      ..['replacement_candidates'] = replacements.length
      ..['pairs_generated'] = pairs.length
      ..['candidate_sources'] = const <String>[]
      ..['low_candidate_coverage'] = pairs.length < effectiveSwapLimit
      ..['ranked_before_quality_gate'] = true;
  }

  // Em decks jÃ¡ saudÃ¡veis, reduzir o nÃºmero de swaps diminui risco de regressÃ£o.
  final maxPairs = structuralRecoveryScenario
      ? computeOptimizeStructuralRecoverySwapTarget(
          allCardData: allCardData,
          commanderColorIdentity: commanderColorIdentity,
          targetArchetype: targetArchetype,
        ).clamp(1, effectiveSwapLimit).toInt()
      : effectiveSwapLimit;

  final responsePairLimit =
      isAggressive ? (maxPairs * 2).clamp(maxPairs, 40).toInt() : maxPairs;
  return pairs.take(responsePairLimit).toList();
}

Map<String, dynamic> buildDeterministicOptimizeResponse({
  required List<Map<String, dynamic>> deterministicSwapCandidates,
  required String targetArchetype,
  OptimizeIntensityConfig? intensity,
}) {
  final swaps = deterministicSwapCandidates
      .where((candidate) =>
          (candidate['remove']?.toString().trim().isNotEmpty ?? false) &&
          (candidate['add']?.toString().trim().isNotEmpty ?? false))
      .map((candidate) {
    final sources = candidate['candidate_quality_sources'] is List
        ? (candidate['candidate_quality_sources'] as List)
            .map((source) => source.toString())
            .toSet()
        : const <String>{};
    final semanticNote = sources.contains(semanticLayerV2Source)
        ? ' Sinal semÃ¢ntico v2 em shadow mode ajudou o ranking; gates legados continuam valendo.'
        : '';
    return {
      'out': candidate['remove'],
      'in': candidate['add'],
      'reason':
          '${candidate['reason'] ?? 'swap deterministico por funcao'}$semanticNote',
      'role': candidate['remove_role'] ?? candidate['role'] ?? 'utility',
      'function': candidate['remove_role'] ?? candidate['role'] ?? 'utility',
      'priority': intensity?.selected == 'light' ? 'Medium' : 'High',
      'impact': intensity?.selected == 'aggressive'
          ? 'maior escopo de melhoria preservando gates'
          : 'melhoria segura de consistencia',
      'risk': intensity?.selected == 'aggressive' ? 'medium' : 'low',
      if (candidate['candidate_quality_score'] != null)
        'candidate_quality_score': candidate['candidate_quality_score'],
      if (candidate['candidate_quality_signal'] != null)
        'candidate_quality_signal': candidate['candidate_quality_signal'],
      if (candidate['candidate_quality_sources'] != null)
        'candidate_quality_sources': candidate['candidate_quality_sources'],
    };
  }).toList();

  return {
    'mode': 'optimize',
    'strategy_source': 'deterministic_first',
    if (intensity != null) 'intensity': intensity.selected,
    if (intensity != null)
      'optimize_intensity': intensity.toJson(
        candidateSwaps: deterministicSwapCandidates.length,
        returnedSwaps: swaps.length,
      ),
    'reasoning':
        'O backend priorizou swaps determinÃ­sticos para $targetArchetype antes da IA, usando funÃ§Ã£o das cartas, prioridade competitiva do comandante e histÃ³rico de rejeiÃ§Ã£o.',
    'swaps': swaps,
  };
}

Map<String, dynamic> buildAggressiveOptimizeUtilitySignal({
  required int requestedSwaps,
  required int returnedSwaps,
  required Map<String, int> rejectionBuckets,
  required bool lowCandidateCoverage,
}) {
  final safeRequested = requestedSwaps <= 0 ? 1 : requestedSwaps;
  final returnedRatio = returnedSwaps / safeRequested;

  String status;
  String userMessageKey;
  if (returnedSwaps > 0) {
    status = returnedRatio >= 0.5 ? 'actionable' : 'partial_actionable';
    userMessageKey = 'aggressive_swaps_available';
  } else if (lowCandidateCoverage) {
    status = 'low_coverage';
    userMessageKey = 'aggressive_low_candidate_coverage';
  } else if (rejectionBuckets.isNotEmpty) {
    status = 'quality_rejected';
    userMessageKey = 'aggressive_quality_gate_blocked';
  } else {
    status = 'no_safe_swaps';
    userMessageKey = 'aggressive_no_safe_swaps';
  }

  return {
    'status': status,
    'requested_swaps': safeRequested,
    'returned_swaps': returnedSwaps,
    'returned_ratio': double.parse(returnedRatio.toStringAsFixed(3)),
    'has_actionable_swaps': returnedSwaps > 0,
    'needs_product_explanation': returnedSwaps == 0,
    'user_message_key': userMessageKey,
  };
}

Map<String, dynamic> summarizeAggressiveOptimizeUtilitySamples({
  required List<Map<String, dynamic>> samples,
  int minApplicableRatePercent = 70,
}) {
  final eligible = samples
      .where((sample) => sample['eligible'] != false)
      .toList(growable: false);
  final total = eligible.length;
  final applicable = eligible.where((sample) {
    final swaps = sample['returned_swaps'];
    if (swaps is int) return swaps > 0;
    final diagnostics = sample['aggressive_candidate_quality'];
    if (diagnostics is Map) {
      final returned = diagnostics['returned_swaps'];
      return returned is int && returned > 0;
    }
    final rawSwaps = sample['swaps'];
    return rawSwaps is List && rawSwaps.isNotEmpty;
  }).length;
  final noOp = total - applicable;
  final rate = total == 0 ? 0 : ((applicable * 100) / total).round();

  final latencies = eligible
      .map((sample) => sample['latency_ms'])
      .whereType<int>()
      .toList()
    ..sort();
  final p95 = latencies.isEmpty
      ? null
      : latencies[((latencies.length * 0.95).ceil() - 1)
          .clamp(0, latencies.length - 1)];

  return {
    'eligible_samples': total,
    'applicable_samples': applicable,
    'no_op_samples': noOp,
    'applicable_rate_percent': rate,
    'min_applicable_rate_percent': minApplicableRatePercent,
    'passes_utility_gate': total > 0 && rate >= minApplicableRatePercent,
    if (p95 != null) 'p95_ms': p95,
  };
}

String resolveOptimizeArchetype({
  required String requestedArchetype,
  required String? detectedArchetype,
}) =>
    archetype_support.resolveEffectiveOptimizeArchetype(
      requestedArchetype: requestedArchetype,
      detectedArchetype: detectedArchetype,
    );

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
  return optimize_cache.buildOptimizeDeckSignature(cardsResult);
}

String buildOptimizeCacheKey({
  required String deckId,
  required String archetype,
  required String mode,
  required int? bracket,
  required bool keepTheme,
  required String deckSignature,
  String intensity = 'focused',
}) {
  return optimize_cache.buildOptimizeCacheKey(
    deckId: deckId,
    archetype: archetype,
    mode: mode,
    bracket: bracket,
    keepTheme: keepTheme,
    deckSignature: deckSignature,
    intensity: intensity,
  );
}

Future<Map<String, dynamic>?> loadOptimizeCache({
  required Pool pool,
  required String cacheKey,
}) async {
  return optimize_cache.loadOptimizeCache(
    pool: pool,
    cacheKey: cacheKey,
  );
}

Future<List<Map<String, dynamic>>> loadUniversalCommanderFallbacks({
  required Pool pool,
  required Set<String> excludeNames,
  Set<String> commanderColorIdentity = const <String>{},
  required int limit,
}) async {
  if (limit <= 0) return const [];

  final filteredPreferred = universalCommanderFallbackNames
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

  final names = commanderFoundationNamesFor(
    commanderColorIdentity: commanderColorIdentity,
    targetArchetype: targetArchetype,
    detectedTheme: detectedTheme,
  );

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
  String metaScope = 'competitive_commander',
  List<String> commanderNames = const <String>[],
  bool preferExternalCompetitive = true,
}) async {
  if (commanderName.trim().isEmpty || limit <= 0) return const [];
  final normalizedCommanderNames = <String>{
    commanderName.trim(),
    ...commanderNames
        .map((name) => name.trim())
        .where((name) => name.isNotEmpty),
  }.toList(growable: false);

  final referenceSelection = await loadCommanderMetaReferenceSelection(
    pool: pool,
    commanderNames: normalizedCommanderNames,
    limitDecks: 6,
    priorityCardLimit: limit,
    metaScope: metaScope,
    preferExternalCompetitive: preferExternalCompetitive,
  );
  if (referenceSelection.priorityCardNames.isNotEmpty) {
    return referenceSelection.priorityCardNames
        .take(limit)
        .toList(growable: false);
  }

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

Future<MetaDeckReferenceSelectionResult> loadCommanderMetaReferenceSelection({
  required Pool pool,
  required List<String> commanderNames,
  required int limitDecks,
  required int priorityCardLimit,
  String metaScope = 'competitive_commander',
  bool preferExternalCompetitive = true,
}) async {
  final normalizedCommanderNames = commanderNames
      .map((name) => name.trim())
      .where((name) => name.isNotEmpty)
      .toSet()
      .toList(growable: false);
  if (normalizedCommanderNames.isEmpty ||
      limitDecks <= 0 ||
      priorityCardLimit <= 0) {
    return MetaDeckReferenceSelectionResult(
      commanderScope: metaScope,
      selectionReason: 'no_match',
      references: const <MetaDeckReferenceCandidate>[],
      priorityCardNames: const <String>[],
      sourceBreakdown: const <String, int>{},
    );
  }

  final candidates = await queryMetaDeckReferenceCandidates(
    pool: pool,
    formatCodes: metaDeckFormatCodesForCommanderScope(metaScope),
    commanderNames: normalizedCommanderNames,
    keywordPatterns: _buildCommanderSearchKeywords(normalizedCommanderNames),
    limit: 240,
  );

  return selectMetaDeckReferenceCandidates(
    candidates: candidates,
    commanderNames: normalizedCommanderNames,
    keywordPatterns: _buildCommanderSearchKeywords(normalizedCommanderNames),
    commanderScope: metaScope,
    deckLimit: limitDecks,
    priorityCardLimit: priorityCardLimit,
    preferExternalCompetitive: preferExternalCompetitive,
  );
}

MetaDeckReferenceSelectionResult emptyCommanderMetaReferenceSelection({
  String? commanderScope,
}) {
  return MetaDeckReferenceSelectionResult(
    commanderScope: commanderScope,
    selectionReason: 'no_match',
    references: const <MetaDeckReferenceCandidate>[],
    priorityCardNames: const <String>[],
    sourceBreakdown: const <String, int>{},
  );
}

String? resolveCommanderOptimizeMetaScope({
  required String deckFormat,
  int? bracket,
}) {
  if (deckFormat.trim().toLowerCase() != 'commander') {
    return null;
  }
  if ((bracket ?? 0) >= 3) {
    return 'competitive_commander';
  }
  return null;
}

List<String> _buildCommanderSearchKeywords(List<String> commanderNames) {
  final keywords = <String>{};
  for (final rawCommander in commanderNames) {
    final trimmed = rawCommander.trim();
    if (trimmed.isEmpty) continue;
    keywords.add(trimmed);
    final token = trimmed.split(',').first.trim();
    if (token.isNotEmpty) keywords.add(token);
  }
  return keywords.toList(growable: false);
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
  return optimize_cache.saveOptimizeCache(
    pool: pool,
    cacheKey: cacheKey,
    userId: userId,
    deckId: deckId,
    deckSignature: deckSignature,
    payload: payload,
  );
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
  String? functionalRole,
  String? priority,
  String? risk,
}) {
  final confidenceScore = _confidenceScoreFromLevel(confidenceLevel);
  final action = type == 'add' ? 'entrada' : 'saÃ­da';
  final curveDelta = (cmcAfter - cmcBefore).toStringAsFixed(2);
  final isBasicLand = basic_lands.isBasicLandName(name);
  final resolvedRole = (functionalRole == null || functionalRole.trim().isEmpty)
      ? 'utility'
      : functionalRole.trim();

  return {
    'type': type,
    'name': name,
    'card_id': cardId,
    'quantity': quantity,
    'is_basic_land': isBasicLand,
    'role': resolvedRole,
    'function': resolvedRole,
    'priority': priority ?? (type == 'add' ? 'High' : 'Medium'),
    'risk': risk ?? (keepTheme ? 'low' : 'medium'),
    'reason':
        'SugestÃ£o de $action para alinhar o deck ao plano ${targetArchetype.toLowerCase()} e melhorar consistÃªncia geral.',
    'confidence': {
      'level': confidenceLevel,
      'score': confidenceScore,
    },
    'impact_estimate': {
      'curve': 'Î”CMC $curveDelta',
      'consistency': keepTheme ? 'alta' : 'mÃ©dia',
      'synergy': type == 'add' ? 'melhora' : 'ajuste',
      'legality': 'mantida',
      'risk': risk ?? (keepTheme ? 'low' : 'medium'),
    },
  };
}

double _confidenceScoreFromLevel(String level) {
  switch (level.toLowerCase()) {
    case 'alta':
    case 'high':
      return 0.9;
    case 'mÃ©dia':
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
