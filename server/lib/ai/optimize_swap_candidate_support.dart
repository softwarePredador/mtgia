import 'package:postgres/postgres.dart';

import '../color_identity.dart';
import '../edh_bracket_policy.dart';
import '../logger.dart';
import 'optimize_candidate_quality_support.dart';
import 'optimize_filler_loader_support.dart';
import 'optimize_functional_role_support.dart';
import 'optimize_removal_candidate_support.dart';
import 'optimize_rejection_history_support.dart';
import 'optimize_route_recommendation_context_support.dart';
import 'optimization_functional_roles.dart';
import 'optimization_ramp_profile.dart';

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
  Map<String, int> preferredNameScores = const <String, int>{},
  bool preferLowCurve = false,
  String? userId,
  bool preferCollection = false,
  int? budgetLimitBrl,
  double usdToBrlRate = defaultOptimizeUsdToBrlRate,
  String deckFormat = 'commander',
  OptimizeRecommendationConstraintLedger? recommendationLedger,
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
  final normalizedPreferredNameScores = <String, int>{};
  for (final entry in preferredNameScores.entries) {
    final name = entry.key.trim().toLowerCase();
    if (name.isEmpty) continue;
    final score = entry.value.clamp(0, 400).toInt();
    final previous = normalizedPreferredNameScores[name] ?? 0;
    if (score > previous) normalizedPreferredNameScores[name] = score;
  }
  final normalizedPreferredNames =
      <String>{
            ...preferredNames,
            ...normalizedPreferredNameScores.keys,
            if (keepTheme) ...?coreCards,
          }
          .map((name) => name.trim().toLowerCase())
          .where((name) => name.isNotEmpty)
          .toSet();
  final orderedPreferredNames =
      normalizedPreferredNames.toList()..sort((a, b) {
        final byPriority = (normalizedPreferredNameScores[b] ?? 0).compareTo(
          normalizedPreferredNameScores[a] ?? 0,
        );
        return byPriority != 0 ? byPriority : a.compareTo(b);
      });
  final themeContext = buildOptimizeThemeContext(
    targetArchetype: targetArchetype,
    detectedTheme: detectedTheme,
    includeDetectedTheme: keepTheme,
  );
  final commanderName = commanders.isNotEmpty ? commanders.first.trim() : '';
  final rejectedAdditionCounts =
      commanderName.isEmpty
          ? const <String, int>{}
          : await _loadRejectedOptimizeAdditionCounts(
            pool: pool,
            commanderName: commanderName,
          );

  final candidatesResult = await pool.execute(
    Sql.named('''
      SELECT sub.id, sub.name, sub.type_line, sub.oracle_text, sub.mana_cost,
             sub.colors, sub.color_identity, sub.pop_score,
             sub.functional_tags, sub.semantic_tags_v2, sub.best_role_score,
             sub.price_usd, sub.price_usd_foil,
             sub.owned_quantity, sub.available_quantity,
             sub.best_commander_synergy_score,
             sub.minimum_bracket,
             sub.cmc
      FROM (
        SELECT DISTINCT ON (LOWER(c.name))
          c.id::text, c.name, c.type_line, c.oracle_text, c.mana_cost, c.colors, c.color_identity,
          COALESCE(cmi.usage_count, 0) AS pop_score,
          ARRAY(
            SELECT DISTINCT value
            FROM unnest(
              COALESCE(cis.function_tags, ARRAY[]::text[]) ||
              COALESCE(cis.scored_roles, ARRAY[]::text[])
            ) AS role(value)
            WHERE value IS NOT NULL AND TRIM(value) <> ''
          ) AS functional_tags,
          COALESCE(cis.semantic_tags_v2, '[]'::jsonb) AS semantic_tags_v2,
          COALESCE(cis.best_role_score, 0) AS best_role_score,
          c.price_usd,
          c.price_usd_foil,
          COALESCE(availability.owned_quantity, 0)::int AS owned_quantity,
          COALESCE(availability.free_quantity, 0)::int AS available_quantity,
          COALESCE(commander_synergy.best_score, 0)::int
            AS best_commander_synergy_score,
          COALESCE(bracket_scope.minimum_bracket, 1)::int AS minimum_bracket,
          c.cmc
        FROM cards c
        LEFT JOIN card_legalities cl
          ON cl.card_id = c.id AND cl.format = @legality_format
        LEFT JOIN card_meta_insights cmi ON LOWER(cmi.card_name) = LOWER(c.name)
        LEFT JOIN card_intelligence_snapshot cis ON cis.card_id = c.id
        LEFT JOIN LATERAL (
          SELECT MAX(ccs.score)::int AS best_score
          FROM commander_card_synergy ccs
          WHERE LOWER(ccs.card_name) = LOWER(c.name)
            AND (
              CARDINALITY(@commander_names::text[]) = 0
              OR ccs.commander_name_normalized =
                 ANY(@commander_names::text[])
            )
        ) commander_synergy ON TRUE
        LEFT JOIN LATERAL (
          SELECT MAX(
            CASE
              WHEN crs.subformat = 'competitive_commander'
                OR crs.bracket_scope = 'bracket_5' THEN 5
              WHEN crs.bracket_scope IN (
                'bracket_4_plus', 'bracket_4_5'
              ) THEN 4
              WHEN crs.bracket_scope IN (
                'bracket_3_plus', 'bracket_3_4', 'bracket_3_5'
              ) THEN 3
              WHEN crs.bracket_scope IN (
                'bracket_2_plus', 'bracket_2_4', 'bracket_2_5'
              ) THEN 2
              ELSE 1
            END
          )::int AS minimum_bracket
          FROM card_role_scores crs
          WHERE crs.card_id = c.id
            AND crs.format = 'commander'
        ) bracket_scope ON TRUE
        LEFT JOIN collection_availability_snapshot availability
          ON availability.playable_card_id = COALESCE(c.oracle_id, c.id)
         AND availability.user_id =
             CAST(NULLIF(CAST(@user_id AS text), '') AS uuid)
         AND CAST(@check_collection AS boolean) = TRUE
        WHERE (cl.status = 'legal' OR cl.status = 'restricted' OR cl.status IS NULL)
          AND LOWER(c.name) NOT IN (SELECT LOWER(unnest(@exclude::text[])))
          AND NOT (COALESCE(c.type_line, '') ~* '(^|[^a-z])land([^a-z]|\$)')
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
        ORDER BY LOWER(c.name),
                 COALESCE(availability.free_quantity, 0) DESC,
                 COALESCE(availability.owned_quantity, 0) DESC,
                 COALESCE(cmi.usage_count, 0) DESC
      ) sub
      ORDER BY CASE
                 WHEN CAST(@prefer_collection AS boolean) = TRUE
                      AND sub.available_quantity > 0 THEN 1
                 ELSE 0
               END DESC,
               CASE
                 WHEN LOWER(sub.name) = ANY(@preferred_names::text[]) THEN 1
                 ELSE 0
               END DESC,
               COALESCE(
                 array_position(@preferred_names::text[], LOWER(sub.name)),
                 2147483647
               ) ASC,
               sub.best_commander_synergy_score DESC,
               sub.pop_score DESC,
               LOWER(sub.name) ASC
      LIMIT 300
    '''),
    parameters: {
      'exclude': excludeNames.toList(),
      'identity': colorIdentityArr,
      'commander_names': commanders
          .map((name) => name.trim().toLowerCase())
          .where((name) => name.isNotEmpty)
          .toList(growable: false),
      'preferred_names': orderedPreferredNames,
      'prefer_collection': preferCollection,
      'check_collection':
          userId != null &&
          userId.trim().isNotEmpty &&
          (preferCollection || budgetLimitBrl != null),
      'user_id': userId,
      'legality_format': deckFormat.trim().toLowerCase(),
    },
  );

  final candidatePool = <Map<String, dynamic>>[];
  final effectiveBudgetLimit =
      (budgetLimitBrl != null && budgetLimitBrl >= 0) ? budgetLimitBrl : null;
  final effectiveRecommendationLedger =
      preferCollection || effectiveBudgetLimit != null
          ? recommendationLedger
          : null;
  for (final row in candidatesResult) {
    final id = row[0] as String;
    final name = row[1] as String;
    final typeLine = ((row[2] as String?) ?? '').toLowerCase();
    final oracle = ((row[3] as String?) ?? '').toLowerCase();
    final manaCost = (row[4] as String?) ?? '';
    final colors = (row[5] as List?)?.cast<String>() ?? const <String>[];
    final identity = (row[6] as List?)?.cast<String>();
    final popScore = (row[7] as num?)?.toInt() ?? 0;
    final functionalTags =
        (row[8] as List?)?.map((entry) => entry.toString()).toList() ??
        const <String>[];
    final semanticTagsV2 = row[9];
    final bestRoleScore = (row[10] as num?)?.toInt() ?? 0;
    final priceUsd = row[11];
    final priceUsdFoil = row[12];
    final ownedQuantity = (row[13] as num?)?.toInt() ?? 0;
    final availableQuantity = (row[14] as num?)?.toInt() ?? 0;
    final bestCommanderSynergyScore = (row[15] as num?)?.toInt() ?? 0;
    final minimumBracket = (row[16] as num?)?.toInt() ?? 1;
    final cmc = safeToNullableDouble(row[17]);
    final estimatedPriceBrl = estimateOptimizePriceBrl(
      priceUsd: priceUsd,
      priceUsdFoil: priceUsdFoil,
      usdToBrlRate: usdToBrlRate,
    );
    final ledgerAvailable =
        effectiveRecommendationLedger?.remainingAvailable(
          name,
          initialAvailableQuantity: availableQuantity,
        ) ??
        availableQuantity;
    if (!isOptimizeCandidateWithinBudget(
      budgetLimitBrl: effectiveBudgetLimit,
      budgetUsedBrl: effectiveRecommendationLedger?.budgetUsedBrl ?? 0,
      availableQuantity: ledgerAvailable,
      estimatedPriceBrl: estimatedPriceBrl,
    )) {
      continue;
    }

    if (!isWithinCommanderIdentity(
      cardIdentity: resolvedCardIdentityFromParts(
        colorIdentity: identity,
        colors: colors,
        oracleText: oracle,
        manaCost: manaCost,
      ),
      commanderIdentity: commanderColorIdentity,
    ))
      continue;

    candidatePool.add({
      'id': id,
      'name': name,
      'type_line': typeLine,
      'oracle_text': oracle,
      'mana_cost': manaCost,
      'colors': colors,
      'color_identity': identity,
      'pop_score': popScore,
      'functional_tags': functionalTags,
      'semantic_tags_v2': semanticTagsV2,
      'best_role_score': bestRoleScore,
      'price_usd': priceUsd,
      'price_usd_foil': priceUsdFoil,
      'estimated_price_brl': estimatedPriceBrl,
      'owned_quantity': ownedQuantity,
      'available_quantity': availableQuantity,
      'best_commander_synergy_score': bestCommanderSynergyScore,
      'minimum_bracket': minimumBracket,
      'cmc': cmc,
    });
  }

  final eligibleCandidatePool = filterCandidatesByBracketPolicy(
    candidates: candidatePool,
    bracket: bracket,
    currentDeckCards: allCardData,
  );
  final usedNames = <String>{};
  var budgetUsedBrl = 0.0;

  bool canUseCandidate(Map<String, dynamic> candidate) {
    final name = candidate['name']?.toString() ?? '';
    final initialAvailable =
        (candidate['available_quantity'] as num?)?.toInt() ?? 0;
    return isOptimizeCandidateWithinBudget(
      budgetLimitBrl: effectiveBudgetLimit,
      budgetUsedBrl:
          effectiveRecommendationLedger?.budgetUsedBrl ?? budgetUsedBrl,
      availableQuantity:
          effectiveRecommendationLedger?.remainingAvailable(
            name,
            initialAvailableQuantity: initialAvailable,
          ) ??
          initialAvailable,
      estimatedPriceBrl: (candidate['estimated_price_brl'] as num?)?.toDouble(),
    );
  }

  void consumeCandidateBudget(Map<String, dynamic> candidate) {
    final name = candidate['name']?.toString() ?? '';
    final availableQuantity =
        (candidate['available_quantity'] as num?)?.toInt() ?? 0;
    final estimatedPrice =
        (candidate['estimated_price_brl'] as num?)?.toDouble();
    if (effectiveRecommendationLedger != null) {
      effectiveRecommendationLedger.reserve(
        name: name,
        initialAvailableQuantity: availableQuantity,
        budgetCostBrl: estimatedPrice,
      );
      return;
    }
    if (effectiveBudgetLimit == null || availableQuantity > 0) return;
    if (estimatedPrice == null || estimatedPrice <= 0) return;
    budgetUsedBrl += estimatedPrice;
  }

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

    for (final candidate in eligibleCandidatePool) {
      final name = (candidate['name'] as String).toLowerCase();
      if (usedNames.contains(name)) continue;
      if (!canUseCandidate(candidate)) continue;
      final score =
          scoreOptimizeReplacementCandidate(
            functionalNeed: need,
            cardName: candidate['name'] as String? ?? '',
            typeLine: candidate['type_line'] as String? ?? '',
            oracleText: candidate['oracle_text'] as String? ?? '',
            manaCost: candidate['mana_cost'] as String? ?? '',
            popScore: (candidate['pop_score'] as int?) ?? 0,
            preferredNames: normalizedPreferredNames,
            rejectedAdditionCounts: rejectedAdditionCounts,
            preferLowCurve: preferLowCurve,
          ) +
          semanticReplacementScoreBoost(
            functionalNeed: need,
            candidate: candidate,
          ) +
          scoreOptimizeThemeAffinity(
            candidate: candidate,
            detectedTheme: themeContext,
            keepTheme: themeContext != null,
          ) +
          scoreOptimizePreferredNameAffinity(
            cardName: candidate['name'] as String? ?? '',
            preferredNameScores: normalizedPreferredNameScores,
          ) +
          scoreOptimizeBracketScopeAffinity(
            candidate: candidate,
            bracket: bracket,
          ) +
          (((candidate['best_commander_synergy_score'] as num?)?.toInt() ?? 0) *
              3) +
          ((preferCollection &&
                  ((candidate['available_quantity'] as num?)?.toInt() ?? 0) > 0)
              ? 220
              : 0);
      final matches = matchesFunctionalNeedForCandidate(
        need,
        candidate: candidate,
        enforceCommanderCriticalFloor:
            deckFormat.trim().toLowerCase() == 'commander',
      );

      if (matches && score > bestScore) {
        best = candidate;
        bestScore = score;
      }
    }

    if (best != null) {
      consumeCandidateBudget(best);
      results.add(
        buildOptimizeReplacementResult(
          best,
          functionalNeed: need,
          hasRecommendationReservation: effectiveRecommendationLedger != null,
        ),
      );
      usedNames.add((best['name'] as String).toLowerCase());
    }
  }

  if (results.length < missingCount) {
    final rankedRemaining =
        eligibleCandidatePool.where((candidate) {
            final name = (candidate['name'] as String).toLowerCase();
            return !usedNames.contains(name);
          }).toList()
          ..sort((a, b) {
            final scoreA =
                scoreOptimizeReplacementCandidate(
                  functionalNeed: 'utility',
                  cardName: a['name'] as String? ?? '',
                  typeLine: a['type_line'] as String? ?? '',
                  oracleText: a['oracle_text'] as String? ?? '',
                  manaCost: a['mana_cost'] as String? ?? '',
                  popScore: (a['pop_score'] as int?) ?? 0,
                  preferredNames: normalizedPreferredNames,
                  rejectedAdditionCounts: rejectedAdditionCounts,
                  preferLowCurve: preferLowCurve,
                ) +
                semanticReplacementScoreBoost(
                  functionalNeed: 'utility',
                  candidate: a,
                ) +
                scoreOptimizeThemeAffinity(
                  candidate: a,
                  detectedTheme: themeContext,
                  keepTheme: themeContext != null,
                ) +
                scoreOptimizePreferredNameAffinity(
                  cardName: a['name'] as String? ?? '',
                  preferredNameScores: normalizedPreferredNameScores,
                ) +
                scoreOptimizeBracketScopeAffinity(
                  candidate: a,
                  bracket: bracket,
                ) +
                (((a['best_commander_synergy_score'] as num?)?.toInt() ?? 0) *
                    3);
            final scoreB =
                scoreOptimizeReplacementCandidate(
                  functionalNeed: 'utility',
                  cardName: b['name'] as String? ?? '',
                  typeLine: b['type_line'] as String? ?? '',
                  oracleText: b['oracle_text'] as String? ?? '',
                  manaCost: b['mana_cost'] as String? ?? '',
                  popScore: (b['pop_score'] as int?) ?? 0,
                  preferredNames: normalizedPreferredNames,
                  rejectedAdditionCounts: rejectedAdditionCounts,
                  preferLowCurve: preferLowCurve,
                ) +
                semanticReplacementScoreBoost(
                  functionalNeed: 'utility',
                  candidate: b,
                ) +
                scoreOptimizeThemeAffinity(
                  candidate: b,
                  detectedTheme: themeContext,
                  keepTheme: themeContext != null,
                ) +
                scoreOptimizePreferredNameAffinity(
                  cardName: b['name'] as String? ?? '',
                  preferredNameScores: normalizedPreferredNameScores,
                ) +
                scoreOptimizeBracketScopeAffinity(
                  candidate: b,
                  bracket: bracket,
                ) +
                (((b['best_commander_synergy_score'] as num?)?.toInt() ?? 0) *
                    3);
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
      if (!canUseCandidate(candidate)) continue;

      consumeCandidateBudget(candidate);
      results.add(
        buildOptimizeReplacementResult(
          candidate,
          functionalNeed: 'utility',
          hasRecommendationReservation: effectiveRecommendationLedger != null,
        ),
      );
      usedNames.add(name);
    }
  }

  return results;
}

Map<String, dynamic> buildOptimizeReplacementResult(
  Map<String, dynamic> candidate, {
  required String functionalNeed,
  bool hasRecommendationReservation = false,
}) {
  final ownedQuantity = (candidate['owned_quantity'] as num?)?.toInt() ?? 0;
  final availableQuantity =
      (candidate['available_quantity'] as num?)?.toInt() ?? 0;
  final estimatedPrice = (candidate['estimated_price_brl'] as num?)?.toDouble();
  return {
    'id': candidate['id'],
    'name': candidate['name'],
    'type_line': candidate['type_line'] ?? '',
    'oracle_text': candidate['oracle_text'] ?? '',
    'mana_cost': candidate['mana_cost'] ?? '',
    'cmc': candidate['cmc'],
    'colors': candidate['colors'] ?? const <String>[],
    'color_identity': candidate['color_identity'] ?? const <String>[],
    'functional_tags': candidate['functional_tags'] ?? const <String>[],
    'semantic_tags_v2':
        candidate['semantic_tags_v2'] ?? const <Map<String, dynamic>>[],
    'functional_need': _normalizeReplacementNeed(functionalNeed),
    'owned_quantity': ownedQuantity,
    'available_quantity': availableQuantity,
    'collection_match': availableQuantity > 0,
    'purchase_required': availableQuantity <= 0,
    if (hasRecommendationReservation)
      optimizeRecommendationReservationMarker: true,
    if (estimatedPrice != null)
      'estimated_price_brl': double.parse(estimatedPrice.toStringAsFixed(2)),
  };
}

bool matchesFunctionalNeedForCandidate(
  String need, {
  required Map<String, dynamic> candidate,
  bool enforceCommanderCriticalFloor = false,
}) {
  final normalizedNeed = _normalizeReplacementNeed(need);
  final commanderCriticalRole =
      normalizedNeed == 'removal' ? 'interaction' : normalizedNeed;
  if (enforceCommanderCriticalFloor &&
      commanderCriticalFunctionalRoleNames.contains(commanderCriticalRole)) {
    return countsTowardCommanderCriticalRoleFloor(
      candidate,
      role: commanderCriticalRole,
    );
  }
  if (normalizedNeed == 'ramp' &&
      !optimizationRampProfileForCard(candidate).countsTowardGenericFloor) {
    return false;
  }
  final roles = optimizationFunctionalRolesForCard(candidate);
  if (normalizedNeed == 'utility') return true;
  if (roles.map(_normalizeReplacementNeed).contains(normalizedNeed)) {
    return true;
  }
  return matchesFunctionalNeed(
    need,
    name: candidate['name'] as String? ?? '',
    oracleText: candidate['oracle_text'] as String? ?? '',
    typeLine: candidate['type_line'] as String? ?? '',
    manaCost: candidate['mana_cost']?.toString(),
    cmc: candidate['cmc'],
  );
}

int semanticReplacementScoreBoost({
  required String functionalNeed,
  required Map<String, dynamic> candidate,
}) {
  final normalizedNeed = _normalizeReplacementNeed(functionalNeed);
  if (normalizedNeed == 'ramp' &&
      !optimizationRampProfileForCard(candidate).countsTowardGenericFloor) {
    return 0;
  }
  final roles =
      optimizationFunctionalRolesForCard(
        candidate,
      ).map(_normalizeReplacementNeed).toSet();
  final roleScore =
      ((candidate['best_role_score'] as num?)?.toInt() ?? 0)
          .clamp(0, 100)
          .toInt();
  if (normalizedNeed == 'utility') {
    return roleScore ~/ 4;
  }
  if (!roles.contains(normalizedNeed)) return 0;
  return 90 + (roleScore ~/ 3);
}

int scoreOptimizeThemeAffinity({
  required Map<String, dynamic> candidate,
  required String? detectedTheme,
  required bool keepTheme,
}) {
  if (!keepTheme) return 0;
  final theme = (detectedTheme ?? '').trim().toLowerCase();
  if (theme.isEmpty || theme == 'unknown') return 0;

  final name = candidate['name']?.toString().toLowerCase() ?? '';
  final typeLine = candidate['type_line']?.toString().toLowerCase() ?? '';
  final oracle = candidate['oracle_text']?.toString().toLowerCase() ?? '';
  final roles =
      optimizationFunctionalRolesForCard(
        candidate,
      ).map((role) => role.trim().toLowerCase()).toSet();
  var score = 0;

  bool hasAnyRole(Iterable<String> expected) =>
      roles.intersection(expected.toSet()).isNotEmpty;

  final isMiracleBigSpells =
      theme.contains('miracle') ||
      theme.contains('big spell') ||
      theme.contains('spellslinger');
  if (isMiracleBigSpells) {
    final isSpell =
        typeLine.contains('instant') || typeLine.contains('sorcery');
    final supportsTopDeck =
        oracle.contains('miracle') ||
        oracle.contains('top of your library') ||
        oracle.contains('top card of your library') ||
        oracle.contains('scry') ||
        oracle.contains('surveil');
    final supportsHandTiming =
        oracle.contains('draw') &&
        (oracle.contains('discard') || oracle.contains('first card'));
    final supportsBigSpellPlan = hasAnyRole(const [
      'big_spell',
      'spellslinger',
      'exile_value',
      'loot',
    ]);

    if (isSpell) score += 110;
    if (supportsTopDeck) score += 170;
    if (supportsHandTiming) score += 80;
    if (supportsBigSpellPlan) score += 120;
    if (oracle.contains('miracle')) score += 180;

    final isUnalignedPermanent =
        !isSpell &&
        !supportsTopDeck &&
        !supportsHandTiming &&
        !supportsBigSpellPlan &&
        (typeLine.contains('equipment') ||
            typeLine.contains('creature') ||
            typeLine.contains('artifact'));
    if (isUnalignedPermanent) score -= 100;
  }

  if (theme.contains('artifact')) {
    if (typeLine.contains('artifact') ||
        hasAnyRole(const ['artifact_synergy'])) {
      score += 120;
    }
  }
  if (theme.contains('token')) {
    if (oracle.contains('token') ||
        hasAnyRole(const ['token_maker', 'token'])) {
      score += 120;
    }
  }
  if (theme.contains('graveyard') ||
      theme.contains('reanimator') ||
      theme.contains('recursion')) {
    if (hasAnyRole(const ['graveyard_synergy', 'recursion']) ||
        oracle.contains('graveyard')) {
      score += 120;
    }
  }
  if (theme.contains('voltron') || theme.contains('equipment')) {
    if (typeLine.contains('equipment') ||
        hasAnyRole(const ['protection', 'equipment'])) {
      score += 120;
    }
  }
  if (theme.contains('counter') || theme.contains('proliferate')) {
    if (oracle.contains('counter') || oracle.contains('proliferate')) {
      score += 110;
    }
  }

  final normalizedThemeTokens =
      theme
          .split(RegExp(r'[^a-z0-9]+'))
          .where(
            (token) =>
                token.length >= 5 &&
                !const {
                  'spells',
                  'cards',
                  'commander',
                  'midrange',
                  'control',
                }.contains(token),
          )
          .toSet();
  final searchable = '$name $typeLine $oracle ${roles.join(' ')}';
  for (final token in normalizedThemeTokens) {
    if (searchable.contains(token)) score += 30;
  }

  return score.clamp(-200, 600).toInt();
}

int scoreOptimizePreferredNameAffinity({
  required String cardName,
  required Map<String, int> preferredNameScores,
}) {
  final name = cardName.trim().toLowerCase();
  if (name.isEmpty) return 0;
  return (preferredNameScores[name] ?? 0).clamp(0, 400).toInt();
}

String? buildOptimizeThemeContext({
  required String targetArchetype,
  required String? detectedTheme,
  bool includeDetectedTheme = true,
}) {
  final parts = <String>[];
  final archetype = targetArchetype.trim();
  final detected = detectedTheme?.trim() ?? '';
  if (archetype.isNotEmpty) parts.add(archetype);
  if (includeDetectedTheme &&
      detected.isNotEmpty &&
      detected.toLowerCase() != archetype.toLowerCase()) {
    parts.add(detected);
  }
  return parts.isEmpty ? null : parts.join(' / ');
}

int scoreOptimizeBracketScopeAffinity({
  required Map<String, dynamic> candidate,
  required int? bracket,
}) {
  if (bracket == null) return 0;
  final minimumBracket = switch (candidate['minimum_bracket']) {
    int value => value,
    num value => value.toInt(),
    String value => int.tryParse(value.trim()) ?? 1,
    _ => 1,
  };
  if (minimumBracket <= bracket) return 0;
  final distance = minimumBracket - bracket;
  return -(distance * 220).clamp(0, 660).toInt();
}

String _normalizeReplacementNeed(String value) {
  return switch (value.trim().toLowerCase()) {
    'board_wipe' || 'wipe' => 'wipe',
    'counterspell' || 'interaction' => 'removal',
    'ritual' || 'mana_fixing' => 'ramp',
    'exile_value' || 'loot' => 'draw',
    'token' || 'token_maker' => 'creature',
    'sacrifice_outlet' => 'engine',
    'combo_piece' => 'combo_piece',
    _ => value.trim().toLowerCase(),
  };
}

bool isOptimizeCandidateWithinBudget({
  required int? budgetLimitBrl,
  required double budgetUsedBrl,
  required int availableQuantity,
  required double? estimatedPriceBrl,
}) {
  if (budgetLimitBrl == null) return true;
  if (availableQuantity > 0) return true;
  if (estimatedPriceBrl == null || estimatedPriceBrl <= 0) return false;
  return budgetUsedBrl + estimatedPriceBrl <= budgetLimitBrl + 0.0001;
}

int _positiveOptimizeQuantity(Object? raw) => switch (raw) {
  int value when value > 0 => value,
  num value when value > 0 => value.toInt(),
  String value => int.tryParse(value.trim()) ?? 1,
  _ => 1,
};

Map<String, int> _criticalRoleContributionsForRemoval(
  Map<String, dynamic> removal,
) {
  final persisted = removal['critical_role_contributions'];
  if (persisted is Map) {
    return {
      for (final role in commanderCriticalFunctionalRoleNames)
        role: switch (persisted[role]) {
          int value => value,
          num value => value.toInt(),
          String value => int.tryParse(value.trim()) ?? 0,
          _ => 0,
        },
    };
  }
  return {
    for (final role in commanderCriticalFunctionalRoleNames)
      role: countOptimizationFunctionalRole([
        {...removal, 'quantity': 1},
      ], role: role),
  };
}

List<String> _criticalRoleNeedsAfterOptimizeRemovals({
  required CommanderFunctionalRoleFloorAssessment assessment,
  required List<Map<String, dynamic>> removals,
}) {
  if (!assessment.applies) return const [];
  final counts = Map<String, int>.from(assessment.actualCounts);
  for (final removal in removals) {
    final contributions = _criticalRoleContributionsForRemoval(removal);
    for (final entry in contributions.entries) {
      counts[entry.key] = (counts[entry.key] ?? 0) - entry.value;
    }
  }

  final needs = <String>[];
  for (final role in const ['ramp', 'draw', 'interaction', 'wipe']) {
    final deficit = ((assessment.minimumCounts[role] ?? 0) -
            (counts[role] ?? 0))
        .clamp(0, 99);
    needs.addAll(List<String>.filled(deficit, role));
  }
  return needs;
}

List<Map<String, dynamic>> _buildProjectedDeckFromOptimizePairs({
  required List<Map<String, dynamic>> allCardData,
  required List<Map<String, dynamic>> pairs,
  required List<Map<String, dynamic>> replacements,
}) {
  final projected = allCardData
      .map((card) => Map<String, dynamic>.from(card))
      .toList(growable: true);
  final replacementByName = <String, Map<String, dynamic>>{
    for (final replacement in replacements)
      if (replacement['name']?.toString().trim().isNotEmpty == true)
        replacement['name'].toString().trim().toLowerCase(): replacement,
  };

  for (final pair in pairs) {
    final removalName = pair['remove']?.toString().trim().toLowerCase() ?? '';
    final removalIndex = projected.indexWhere(
      (card) => card['name']?.toString().trim().toLowerCase() == removalName,
    );
    if (removalIndex >= 0) {
      final quantity = _positiveOptimizeQuantity(
        projected[removalIndex]['quantity'],
      );
      if (quantity > 1) {
        projected[removalIndex]['quantity'] = quantity - 1;
      } else {
        projected.removeAt(removalIndex);
      }
    }

    final additionName = pair['add']?.toString().trim().toLowerCase() ?? '';
    final replacement = replacementByName[additionName];
    if (replacement != null) {
      projected.add({...replacement, 'quantity': 1});
    }
  }
  return projected;
}

List<Map<String, dynamic>> buildSameLaneOptimizeSwapPairs({
  required List<Map<String, dynamic>> removalCandidates,
  required List<Map<String, dynamic>> replacements,
}) {
  final pairs = <Map<String, dynamic>>[];
  final usedReplacementIndexes = <int>{};
  for (final removal in removalCandidates) {
    final removalName = removal['name']?.toString().trim() ?? '';
    final removalRole = _normalizeReplacementNeed(
      removal['role']?.toString() ?? '',
    );
    if (removalName.isEmpty || removalRole.isEmpty) continue;

    int? replacementIndex;
    for (var index = 0; index < replacements.length; index++) {
      if (usedReplacementIndexes.contains(index)) continue;
      final replacement = replacements[index];
      final additionName = replacement['name']?.toString().trim() ?? '';
      final additionRole = _normalizeReplacementNeed(
        replacement['functional_need']?.toString() ?? '',
      );
      if (additionName.isNotEmpty && additionRole == removalRole) {
        replacementIndex = index;
        break;
      }
    }
    final bracketRepair = removal['bracket_violation'] == true;
    final functionalRoleRepair = removal['functional_role_repair'] == true;
    if (replacementIndex == null && (bracketRepair || functionalRoleRepair)) {
      for (var index = 0; index < replacements.length; index++) {
        if (usedReplacementIndexes.contains(index)) continue;
        final additionName =
            replacements[index]['name']?.toString().trim() ?? '';
        if (additionName.isEmpty) continue;
        replacementIndex = index;
        break;
      }
    }
    if (replacementIndex == null) continue;

    usedReplacementIndexes.add(replacementIndex);
    final replacement = replacements[replacementIndex];
    final additionName = replacement['name']?.toString().trim() ?? '';
    final additionRole = _normalizeReplacementNeed(
      replacement['functional_need']?.toString() ?? removalRole,
    );
    final sameLane = additionRole == removalRole;
    final protectedAnchor = removal['protected_anchor'] == true;
    final anchorReasons =
        (removal['anchor_reasons'] as List?)
            ?.map((value) => value.toString())
            .where((value) => value.isNotEmpty)
            .toList(growable: false) ??
        const <String>[];

    pairs.add({
      'remove': removalName,
      'add': additionName,
      'remove_role': removalRole,
      'add_role': additionRole,
      'same_lane': sameLane,
      'bracket_repair': bracketRepair,
      'functional_role_repair': functionalRoleRepair,
      if (functionalRoleRepair)
        'functional_role_repair_target':
            removal['functional_role_repair_target'],
      'protected_anchor': protectedAnchor,
      'anchor_reasons': anchorReasons,
      'anchor_policy': 'same_lane_replacement_or_battle_gate',
      'anchor_policy_satisfied':
          bracketRepair || functionalRoleRepair || !protectedAnchor || sameLane,
      'same_lane_hypothesis':
          sameLane
              ? 'Substituir uma carta de $removalRole por outra da mesma função antes do battle gate independente.'
              : bracketRepair
              ? 'Remover uma violação objetiva de bracket e realocar a vaga '
                  'para $additionRole antes do battle gate independente.'
              : 'Reparar o piso funcional de $additionRole sem remover '
                  'terreno ou outra função crítica antes do battle gate.',
      'remove_score': removal['score'],
      'owned_quantity': replacement['owned_quantity'],
      'available_quantity': replacement['available_quantity'],
      'collection_match': replacement['collection_match'] == true,
      'purchase_required': replacement['purchase_required'] != false,
      if (replacement['estimated_price_brl'] != null)
        'estimated_price_brl': replacement['estimated_price_brl'],
      'reason':
          bracketRepair
              ? 'Swap determinístico obrigatório para adequar o bracket; a '
                  'vaga foi direcionada à necessidade $additionRole.'
              : functionalRoleRepair
              ? 'Swap determinístico para reparar o piso funcional de '
                  '$additionRole; a validação final confirma a lista projetada.'
              : 'Swap determinístico na mesma função $removalRole; '
                  'superioridade ainda depende de evidência natural e battle '
                  'gate independente.',
    });
  }
  return pairs;
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
  String? userId,
  bool preferCollection = false,
  int? budgetLimitBrl,
  double usdToBrlRate = defaultOptimizeUsdToBrlRate,
  String deckFormat = 'commander',
}) async {
  if (allCardData.isEmpty) return const [];
  final requestedSwapLimit = swapLimit.clamp(1, 20).toInt();
  final roleFloorAssessment =
      deckFormat.trim().toLowerCase() == 'commander'
          ? assessCommanderFunctionalRoleFloors(
            cards: allCardData,
            targetArchetype: targetArchetype,
            bracket: bracket,
          )
          : null;
  final criticalRoleFloorNeeds =
      roleFloorAssessment?.applies == true
          ? buildCommanderCriticalRoleFloorNeeds(
            cards: allCardData,
            targetArchetype: targetArchetype,
            limit: 20,
            bracket: bracket,
          )
          : const <String>[];
  final bracketRepairSwapCount =
      bracket == null
          ? 0
          : (() {
            final assessment = assessDeckAgainstBracketPolicy(
              bracket: bracket,
              cards: allCardData,
            );
            final count = assessment.counts[BracketCategory.gameChanger] ?? 0;
            final cap =
                assessment.policy.maxCounts[BracketCategory.gameChanger] ?? 0;
            return (count - cap).clamp(0, 20).toInt();
          })();
  final repairMode =
      bracketRepairSwapCount > 0 || criticalRoleFloorNeeds.isNotEmpty;
  final requiredRepairSlots =
      (bracketRepairSwapCount + criticalRoleFloorNeeds.length)
          .clamp(1, 20)
          .toInt();
  final effectiveSwapLimit =
      repairMode ? requiredRepairSlots : requestedSwapLimit;
  final isAggressive = intensity.trim().toLowerCase() == 'aggressive';
  final candidateSearchLimit =
      repairMode
          ? 20
          : isAggressive
          ? (effectiveSwapLimit * 3).clamp(effectiveSwapLimit, 60).toInt()
          : effectiveSwapLimit;

  final preferredNames =
      commanderPriorityNames.map((name) => name.toLowerCase()).toSet();
  final structuralRecoveryScenario = isOptimizeStructuralRecoveryScenario(
    allCardData: allCardData,
    commanderColorIdentity: commanderColorIdentity,
  );
  final rawRemovalCandidates = buildDeterministicOptimizeRemovalCandidates(
    allCardData: allCardData,
    commanders: commanders,
    commanderColorIdentity: commanderColorIdentity,
    targetArchetype: targetArchetype,
    keepTheme: keepTheme,
    coreCards: coreCards,
    commanderPriorityNames: commanderPriorityNames,
    bracket: bracket,
    swapLimit: candidateSearchLimit,
  );
  final selectedRawRemovals = <Map<String, dynamic>>[];
  if (repairMode) {
    selectedRawRemovals.addAll(
      rawRemovalCandidates.where(
        (candidate) => candidate['bracket_violation'] == true,
      ),
    );
    final initialNeeds =
        roleFloorAssessment == null
            ? const <String>[]
            : _criticalRoleNeedsAfterOptimizeRemovals(
              assessment: roleFloorAssessment,
              removals: selectedRawRemovals,
            );
    final requiredCount =
        [
          selectedRawRemovals.length,
          initialNeeds.length,
        ].reduce((a, b) => a > b ? a : b).clamp(1, 20).toInt();
    for (final candidate in rawRemovalCandidates) {
      if (selectedRawRemovals.length >= requiredCount) break;
      if (candidate['bracket_violation'] == true) continue;
      selectedRawRemovals.add(candidate);
    }
    if (selectedRawRemovals.length < requiredCount) return const [];
  } else {
    selectedRawRemovals.addAll(rawRemovalCandidates.take(effectiveSwapLimit));
  }

  final pendingRoleNeeds =
      roleFloorAssessment == null
          ? <String>[]
          : _criticalRoleNeedsAfterOptimizeRemovals(
            assessment: roleFloorAssessment,
            removals: selectedRawRemovals,
          );
  if (pendingRoleNeeds.length > selectedRawRemovals.length) return const [];

  final removalCandidates = <Map<String, dynamic>>[];
  for (final rawCandidate in selectedRawRemovals) {
    final candidate = Map<String, dynamic>.from(rawCandidate);
    if (pendingRoleNeeds.isNotEmpty) {
      candidate
        ..['functional_role_repair'] = true
        ..['functional_role_repair_target'] = pendingRoleNeeds.removeAt(0);
    }
    removalCandidates.add(candidate);
  }
  final removalList =
      removalCandidates
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
  final bracketViolationCount =
      removalCandidates
          .where((candidate) => candidate['bracket_violation'] == true)
          .length;
  final functionalRoleRepairCount =
      removalCandidates
          .where((candidate) => candidate['functional_role_repair'] == true)
          .length;
  List<String>? functionalNeedsOverride;
  if (structuralRecoveryScenario ||
      bracketViolationCount > 0 ||
      functionalRoleRepairCount > 0) {
    final structuralNeeds = buildStructuralRecoveryFunctionalNeeds(
      allCardData: allCardData,
      targetArchetype: targetArchetype,
      limit: removalList.length,
    );
    if (bracketViolationCount > 0 || functionalRoleRepairCount > 0) {
      var bracketNeedIndex = 0;
      functionalNeedsOverride = [
        for (final removal in removalCandidates)
          if (removal['functional_role_repair'] == true)
            removal['functional_role_repair_target']?.toString() ?? 'wipe'
          else if (removal['bracket_violation'] == true)
            structuralNeeds.isEmpty
                ? 'utility'
                : structuralNeeds[(bracketNeedIndex++)
                    .clamp(0, structuralNeeds.length - 1)
                    .toInt()]
          else
            removal['role']?.toString() ?? 'utility',
      ];
    } else {
      functionalNeedsOverride = structuralNeeds;
    }
  }

  final deckNamesLower =
      allCardData
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
    userId: userId,
    preferCollection: preferCollection,
    budgetLimitBrl: budgetLimitBrl,
    usdToBrlRate: usdToBrlRate,
    deckFormat: deckFormat,
  );
  final pairs = buildSameLaneOptimizeSwapPairs(
    removalCandidates: removalCandidates,
    replacements: replacements,
  );
  if (repairMode && pairs.length != removalCandidates.length) {
    return const [];
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
      final candidateSources =
          signals.values.expand((signal) => signal.sources).toSet().toList()
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

  // Em decks ja saudaveis, reduzir o numero de swaps diminui risco de regressao.
  final structuralPairLimit =
      structuralRecoveryScenario
          ? computeOptimizeStructuralRecoverySwapTarget(
            allCardData: allCardData,
            commanderColorIdentity: commanderColorIdentity,
            targetArchetype: targetArchetype,
          ).clamp(1, effectiveSwapLimit).toInt()
          : effectiveSwapLimit;
  final maxPairs =
      repairMode
          ? removalCandidates.length
          : bracketRepairSwapCount > structuralPairLimit
          ? bracketRepairSwapCount.clamp(1, effectiveSwapLimit).toInt()
          : structuralPairLimit;

  final responsePairLimit =
      isAggressive ? (maxPairs * 2).clamp(maxPairs, 40).toInt() : maxPairs;
  final selectedPairs = pairs.take(responsePairLimit).toList(growable: false);
  if (repairMode && deckFormat.trim().toLowerCase() == 'commander') {
    final projected = _buildProjectedDeckFromOptimizePairs(
      allCardData: allCardData,
      pairs: selectedPairs,
      replacements: replacements,
    );
    final projectedRoleFloors = assessCommanderFunctionalRoleFloors(
      cards: projected,
      targetArchetype: targetArchetype,
      bracket: bracket,
    );
    final projectedBracket =
        bracket == null
            ? null
            : assessDeckAgainstBracketPolicy(
              bracket: bracket,
              cards: projected,
            );
    if (!projectedRoleFloors.satisfied ||
        projectedBracket?.hardCompliant == false) {
      return const [];
    }
  }
  return selectedPairs;
}

Future<Map<String, int>> _loadRejectedOptimizeAdditionCounts({
  required Pool pool,
  required String commanderName,
}) async {
  if (commanderName.trim().isEmpty) return const <String, int>{};

  final explicitRejectionPredicate = explicitOptimizeQualityRejectionSql('oal');
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
          AND $explicitRejectionPredicate
          AND oal.created_at > NOW() - INTERVAL '180 days'
        GROUP BY LOWER(value)
        ORDER BY reject_count DESC, card_name ASC
        LIMIT 200
      '''),
      parameters: {'commander_name': commanderName},
    );

    return {
      for (final row in result)
        (row[0] as String?) ?? '': (row[1] as int?) ?? 0,
    }..removeWhere((key, value) => key.trim().isEmpty || value <= 0);
  } catch (e) {
    Log.w(
      'Falha ao carregar penalidades historicas de optimize '
      'type=${e.runtimeType}',
    );
    return const <String, int>{};
  }
}
