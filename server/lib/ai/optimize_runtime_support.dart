import 'package:postgres/postgres.dart';
import '../basic_land_utils.dart' as basic_lands;
import '../meta/meta_deck_reference_support.dart';
import '../meta/meta_deck_format_support.dart';
import 'commander_fallback_policy.dart';
import 'optimize_archetype_support.dart' as archetype_support;
import 'optimize_cache_support.dart' as optimize_cache;
export 'optimize_candidate_quality_support.dart';
export 'optimize_fallback_telemetry_support.dart';
export 'optimize_functional_role_support.dart';
import 'optimize_filler_loader_support.dart';
export 'optimize_filler_loader_support.dart';
export 'optimize_payload_support.dart';
export 'optimize_removal_candidate_support.dart';
export 'optimize_swap_candidate_support.dart';

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

String resolveOptimizeArchetype({
  required String requestedArchetype,
  required String? detectedArchetype,
}) =>
    archetype_support.resolveEffectiveOptimizeArchetype(
      requestedArchetype: requestedArchetype,
      detectedArchetype: detectedArchetype,
    );

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
