import 'package:postgres/postgres.dart';
import '../basic_land_utils.dart' as basic_lands;
import '../color_identity.dart';
import '../logger.dart';
import 'aggressive_candidate_meta_signal_support.dart';
import 'functional_card_tags.dart';
import '../meta/meta_deck_reference_support.dart';
import '../meta/meta_deck_format_support.dart';
import 'commander_fallback_policy.dart';
import 'optimize_filler_loader_support.dart';
export 'optimize_filler_loader_support.dart';

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

class AggressiveCandidateQualitySignal {
  const AggressiveCandidateQualitySignal({
    required this.cardName,
    required this.roles,
    required this.roleScore,
    required this.functionConfidence,
    required this.synergyScore,
    required this.synergyEvidenceCount,
    required this.rejectionPenalty,
    required this.budgetTier,
    required this.bracketScope,
    required this.sources,
  });

  final String cardName;
  final Set<String> roles;
  final int roleScore;
  final double functionConfidence;
  final int synergyScore;
  final int synergyEvidenceCount;
  final int rejectionPenalty;
  final String budgetTier;
  final String bracketScope;
  final Set<String> sources;

  bool get hasSignal =>
      roleScore > 0 ||
      functionConfidence > 0 ||
      synergyScore > 0 ||
      synergyEvidenceCount > 0 ||
      sources.isNotEmpty;

  Map<String, dynamic> toJson() {
    return {
      'card_name': cardName,
      'roles': roles.toList()..sort(),
      'role_score': roleScore,
      'function_confidence': functionConfidence,
      'synergy_score': synergyScore,
      'synergy_evidence_count': synergyEvidenceCount,
      'rejection_penalty': rejectionPenalty,
      'budget_tier': budgetTier,
      'bracket_scope': bracketScope,
      'sources': sources.toList()..sort(),
    };
  }
}

String _normalizeAggressiveSignalKey(String value) {
  return value.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
}

int _aggressiveBracketScopePenalty(String bracketScope, int? bracket) {
  if (bracket == null) return 0;
  final scope = bracketScope.trim().toLowerCase();
  if (scope == 'bracket_3_4' && bracket < 3) return 140;
  if (scope == 'bracket_2_4' && bracket < 2) return 80;
  return 0;
}

int _aggressiveBudgetPenalty(String budgetTier, int? bracket) {
  if (bracket == null || bracket >= 3) return 0;
  final normalized = budgetTier.trim().toLowerCase();
  if (normalized == 'expensive') return bracket <= 1 ? 120 : 70;
  if (normalized == 'premium' && bracket <= 1) return 35;
  return 0;
}

int _scoreAggressiveCandidateQualityPair({
  required Map<String, dynamic> pair,
  required AggressiveCandidateQualitySignal? signal,
  required int? bracket,
}) {
  final removalScore = (pair['remove_score'] as num?)?.toInt() ?? 0;
  if (signal == null) return removalScore;

  final removedRole =
      (pair['remove_role']?.toString() ?? pair['role']?.toString() ?? '')
          .trim()
          .toLowerCase();
  final roleAlignmentBonus =
      removedRole.isNotEmpty && signal.roles.contains(removedRole) ? 120 : 0;
  final sourceBonus =
      signal.sources.contains(aggressiveCandidateMetaSignalSource)
          ? 45
          : signal.sources.isNotEmpty
              ? 18
              : 0;
  final evidenceBonus = (signal.synergyEvidenceCount * 4).clamp(0, 48).toInt();
  final roleScoreComponent = (signal.roleScore * 2.1).round();
  final synergyComponent = (signal.synergyScore * 2.4).round();
  final functionComponent = (signal.functionConfidence * 80).round();
  final rejectionPenalty = (signal.rejectionPenalty / 4).round();
  final bracketPenalty =
      _aggressiveBracketScopePenalty(signal.bracketScope, bracket);
  final budgetPenalty = _aggressiveBudgetPenalty(signal.budgetTier, bracket);

  return removalScore +
      roleAlignmentBonus +
      sourceBonus +
      evidenceBonus +
      roleScoreComponent +
      synergyComponent +
      functionComponent -
      rejectionPenalty -
      bracketPenalty -
      budgetPenalty;
}

List<Map<String, dynamic>> rankAggressiveCandidateQualityPairs({
  required List<Map<String, dynamic>> pairs,
  required Map<String, AggressiveCandidateQualitySignal> signalsByName,
  required int? bracket,
}) {
  final ranked = pairs.map((pair) {
    final addName = pair['add']?.toString() ?? '';
    final signal = signalsByName[_normalizeAggressiveSignalKey(addName)];
    final score = _scoreAggressiveCandidateQualityPair(
      pair: pair,
      signal: signal,
      bracket: bracket,
    );
    return {
      ...pair,
      'candidate_quality_score': score,
      if (signal != null) 'candidate_quality_signal': signal.toJson(),
      if (signal != null && signal.roles.isNotEmpty)
        'add_role': signal.roles.first,
      if (signal != null && signal.sources.isNotEmpty)
        'candidate_quality_sources': signal.sources.toList()..sort(),
    };
  }).toList();

  ranked.sort((a, b) {
    final byScore = ((b['candidate_quality_score'] as num?) ?? 0).compareTo(
      (a['candidate_quality_score'] as num?) ?? 0,
    );
    if (byScore != 0) return byScore;
    final byRemoveScore = ((b['remove_score'] as num?) ?? 0).compareTo(
      (a['remove_score'] as num?) ?? 0,
    );
    if (byRemoveScore != 0) return byRemoveScore;
    return (a['add']?.toString() ?? '').compareTo(b['add']?.toString() ?? '');
  });

  return ranked;
}

Map<String, int> bucketOptimizeQualityGateDroppedReasons(
  Iterable<String> droppedReasons,
) {
  final buckets = <String, int>{};
  for (final reason in droppedReasons) {
    final normalized = reason.toLowerCase();
    final bucket = normalized.contains('dados incompletos')
        ? 'incomplete_card_data'
        : normalized.contains('delta cmc') || normalized.contains('cmc')
            ? 'curve_or_role_mismatch'
            : normalized.contains('papel')
                ? 'role_mismatch'
                : normalized.contains('mana') || normalized.contains('land')
                    ? 'mana_or_land_safety'
                    : 'quality_gate_rejected';
    buckets[bucket] = (buckets[bucket] ?? 0) + 1;
  }
  return buckets;
}

Future<Map<String, AggressiveCandidateQualitySignal>>
    loadAggressiveCandidateQualitySignals({
  required Pool pool,
  required List<String> candidateNames,
  required List<String> commanders,
  required String targetArchetype,
  required int? bracket,
}) async {
  final normalizedNames = candidateNames
      .map(_normalizeAggressiveSignalKey)
      .where((name) => name.isNotEmpty)
      .toSet()
      .toList(growable: false);
  if (normalizedNames.isEmpty) {
    return const <String, AggressiveCandidateQualitySignal>{};
  }

  final normalizedCommanders = commanders
      .map(_normalizeAggressiveSignalKey)
      .where((name) => name.isNotEmpty)
      .toSet()
      .toList(growable: false);
  final roles = aggressiveCandidateTrackedRoles.toList(growable: false);
  final tags = roles
      .map((role) => role == 'wipe' ? 'board_wipe' : role)
      .toSet()
      .toList(growable: false);

  try {
    final result = await pool.execute(
      Sql.named('''
WITH requested(name_lower) AS (
  SELECT UNNEST(@names::text[])
),
role_rows AS (
  SELECT
    LOWER(crs.card_name) AS name_lower,
    ARRAY_REMOVE(ARRAY_AGG(DISTINCT crs.role), NULL) AS roles,
    MAX(crs.score)::int AS role_score,
    MAX(crs.budget_tier) AS budget_tier,
    MAX(crs.bracket_scope) AS bracket_scope,
    ARRAY_REMOVE(ARRAY_AGG(DISTINCT crs.source), NULL) AS role_sources
  FROM card_role_scores crs
  JOIN requested r ON LOWER(crs.card_name) = r.name_lower
  WHERE crs.format = 'commander'
    AND crs.role = ANY(@roles::text[])
    AND crs.source IN ('deterministic_heuristic_v1', @meta_source)
  GROUP BY LOWER(crs.card_name)
),
tag_rows AS (
  SELECT
    LOWER(cft.card_name) AS name_lower,
    MAX(cft.confidence)::float AS function_confidence,
    ARRAY_REMOVE(ARRAY_AGG(DISTINCT cft.source), NULL) AS tag_sources
  FROM card_function_tags cft
  JOIN requested r ON LOWER(cft.card_name) = r.name_lower
  WHERE cft.tag = ANY(@tags::text[])
  GROUP BY LOWER(cft.card_name)
),
synergy_rows AS (
  SELECT
    LOWER(ccs.card_name) AS name_lower,
    ARRAY_REMOVE(ARRAY_AGG(DISTINCT ccs.role), NULL) AS synergy_roles,
    MAX(ccs.score)::int AS synergy_score,
    MAX(ccs.evidence_count)::int AS synergy_evidence_count,
    ARRAY_REMOVE(ARRAY_AGG(DISTINCT ccs.source), NULL) AS synergy_sources
  FROM commander_card_synergy ccs
  JOIN requested r ON LOWER(ccs.card_name) = r.name_lower
  WHERE ccs.source = @meta_source
    AND ccs.role = ANY(@roles::text[])
    AND (
      CARDINALITY(@commanders::text[]) = 0
      OR ccs.commander_name_normalized = ANY(@commanders::text[])
    )
  GROUP BY LOWER(ccs.card_name)
),
penalty_rows AS (
  SELECT
    orp.card_name_normalized AS name_lower,
    MAX(orp.penalty)::int AS rejection_penalty
  FROM optimize_rejection_penalties orp
  JOIN requested r ON orp.card_name_normalized = r.name_lower
  WHERE (
      CARDINALITY(@commanders::text[]) = 0
      OR orp.commander_name_normalized = ''
      OR orp.commander_name_normalized = ANY(@commanders::text[])
    )
    AND (
      orp.archetype = ''
      OR LOWER(orp.archetype) = LOWER(@archetype)
    )
  GROUP BY orp.card_name_normalized
)
SELECT
  r.name_lower,
  COALESCE(rr.roles, ARRAY[]::text[]) || COALESCE(sr.synergy_roles, ARRAY[]::text[]) AS roles,
  COALESCE(rr.role_score, 0) AS role_score,
  COALESCE(tr.function_confidence, 0)::float AS function_confidence,
  COALESCE(sr.synergy_score, 0) AS synergy_score,
  COALESCE(sr.synergy_evidence_count, 0) AS synergy_evidence_count,
  COALESCE(pr.rejection_penalty, 0) AS rejection_penalty,
  COALESCE(rr.budget_tier, 'unknown') AS budget_tier,
  COALESCE(rr.bracket_scope, 'any') AS bracket_scope,
  COALESCE(rr.role_sources, ARRAY[]::text[]) ||
    COALESCE(tr.tag_sources, ARRAY[]::text[]) ||
    COALESCE(sr.synergy_sources, ARRAY[]::text[]) AS sources
FROM requested r
LEFT JOIN role_rows rr ON rr.name_lower = r.name_lower
LEFT JOIN tag_rows tr ON tr.name_lower = r.name_lower
LEFT JOIN synergy_rows sr ON sr.name_lower = r.name_lower
LEFT JOIN penalty_rows pr ON pr.name_lower = r.name_lower
      '''),
      parameters: {
        'names': normalizedNames,
        'commanders': normalizedCommanders,
        'roles': roles,
        'tags': tags,
        'archetype': targetArchetype,
        'meta_source': aggressiveCandidateMetaSignalSource,
      },
    );

    final signals = <String, AggressiveCandidateQualitySignal>{};
    for (final row in result) {
      final nameLower = row[0] as String? ?? '';
      if (nameLower.isEmpty) continue;
      final roles = ((row[1] as List?) ?? const <Object?>[])
          .map((role) => role.toString())
          .where((role) => role.trim().isNotEmpty)
          .toSet();
      final sources = ((row[9] as List?) ?? const <Object?>[])
          .map((source) => source.toString())
          .where((source) => source.trim().isNotEmpty)
          .toSet();
      signals[nameLower] = AggressiveCandidateQualitySignal(
        cardName: nameLower,
        roles: roles,
        roleScore: (row[2] as num?)?.toInt() ?? 0,
        functionConfidence: (row[3] as num?)?.toDouble() ?? 0,
        synergyScore: (row[4] as num?)?.toInt() ?? 0,
        synergyEvidenceCount: (row[5] as num?)?.toInt() ?? 0,
        rejectionPenalty: (row[6] as num?)?.toInt() ?? 0,
        budgetTier: row[7] as String? ?? 'unknown',
        bracketScope: row[8] as String? ?? 'any',
        sources: sources,
      );
    }

    return signals..removeWhere((_, signal) => !signal.hasSignal);
  } catch (e) {
    Log.w('Aggressive candidate quality signals unavailable: $e');
    return const <String, AggressiveCandidateQualitySignal>{};
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
  int swapLimit = 6,
}) {
  final effectiveSwapLimit = swapLimit.clamp(1, 60).toInt();

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

    // Evitar cortar terrenos sÃ³ porque estÃ¡ 1-3 acima do recomendado.
    // Em decks saudÃ¡veis (especialmente control), isso frequentemente aumenta screw.
    // Mantemos o corte de lands apenas quando hÃ¡ excesso material.
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
            structuralRecoveryScenario
                ? structuralRecoverySwapTarget
                : effectiveSwapLimit,
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

    // Se o deck estÃ¡ "saudÃ¡vel" (sem excesso claro de papÃ©is) o algoritmo por surplus
    // pode ficar sem alvos e acabar forÃ§ando cortes de terrenos (que frequentemente
    // pioram mana screw). Neste caso, preferimos sugerir 1-2 cortes de topo de curva
    // fora de papÃ©is crÃ­ticos para abrir espaÃ§o a upgrades mais baratos.
    final nonLandRemovalCount =
        removalCandidates.where((c) => (c['role'] as String?) != 'land').length;
    if (!structuralRecoveryScenario &&
        nonLandRemovalCount < effectiveSwapLimit) {
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
            effectiveSwapLimit) {
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

    final takeLimit = structuralRecoveryScenario
        ? (structuralRecoverySwapTarget < effectiveSwapLimit
            ? structuralRecoverySwapTarget
            : effectiveSwapLimit)
        : effectiveSwapLimit;
    return removalCandidates
        .where((candidate) => (candidate['score'] as int) > 0)
        .take(takeLimit)
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
    if (merged.length >= effectiveSwapLimit) break;
  }

  final structuralRecoveryScenario = isOptimizeStructuralRecoveryScenario(
    allCardData: allCardData,
    commanderColorIdentity: commanderColorIdentity,
  );
  final structuralTakeCount = structuralRecoveryScenario
      ? computeOptimizeStructuralRecoverySwapTarget(
          allCardData: allCardData,
          commanderColorIdentity: commanderColorIdentity,
          targetArchetype: targetArchetype,
        )
      : effectiveSwapLimit;
  final takeCount = structuralTakeCount < effectiveSwapLimit
      ? structuralTakeCount
      : effectiveSwapLimit;
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
  String intensity = 'focused',
}) {
  final base = [
    'optimize',
    mode.toLowerCase().trim(),
    intensity.toLowerCase().trim(),
    deckId,
    archetype.toLowerCase().trim(),
    '${bracket ?? 'none'}',
    keepTheme ? 'keep' : 'free',
    deckSignature,
  ].join('::');
  return 'v7:${_stableHash(base)}';
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
