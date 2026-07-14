import 'package:postgres/postgres.dart';

import '../color_identity.dart';
import '../logger.dart';
import 'optimize_candidate_quality_support.dart';
import 'optimize_filler_loader_support.dart';
import 'optimize_functional_role_support.dart';
import 'optimize_removal_candidate_support.dart';
import 'optimize_route_recommendation_context_support.dart';
import 'optimization_functional_roles.dart';

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
  String? userId,
  bool preferCollection = false,
  int? budgetLimitBrl,
  double usdToBrlRate = defaultOptimizeUsdToBrlRate,
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
      SELECT sub.id, sub.name, sub.type_line, sub.oracle_text, sub.mana_cost,
             sub.colors, sub.color_identity, sub.pop_score,
             sub.functional_tags, sub.semantic_tags_v2, sub.best_role_score,
             sub.price_usd, sub.price_usd_foil, sub.owned_quantity
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
          COALESCE(owned.owned_quantity, 0)::int AS owned_quantity
        FROM cards c
        LEFT JOIN card_legalities cl ON cl.card_id = c.id AND cl.format = 'commander'
        LEFT JOIN card_meta_insights cmi ON LOWER(cmi.card_name) = LOWER(c.name)
        LEFT JOIN card_intelligence_snapshot cis ON cis.card_id = c.id
        LEFT JOIN LATERAL (
          SELECT COALESCE(SUM(bi.quantity), 0)::int AS owned_quantity
          FROM user_binder_items bi
          WHERE bi.card_id = c.id
            AND CAST(@prefer_collection AS boolean) = TRUE
            AND NULLIF(CAST(@user_id AS text), '') IS NOT NULL
            AND bi.user_id = CAST(NULLIF(CAST(@user_id AS text), '') AS uuid)
            AND COALESCE(bi.list_type, 'have') = 'have'
        ) owned ON TRUE
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
        ORDER BY LOWER(c.name),
                 COALESCE(owned.owned_quantity, 0) DESC,
                 COALESCE(cmi.usage_count, 0) DESC
      ) sub
      ORDER BY CASE WHEN sub.owned_quantity > 0 THEN 1 ELSE 0 END DESC,
               sub.pop_score DESC,
               LOWER(sub.name) ASC
      LIMIT 300
    '''),
    parameters: {
      'exclude': excludeNames.toList(),
      'identity': colorIdentityArr,
      'prefer_collection': preferCollection,
      'user_id': userId,
    },
  );

  final candidatePool = <Map<String, dynamic>>[];
  final effectiveBudgetLimit =
      (budgetLimitBrl != null && budgetLimitBrl > 0) ? budgetLimitBrl : null;
  for (final row in candidatesResult) {
    final id = row[0] as String;
    final name = row[1] as String;
    final typeLine = ((row[2] as String?) ?? '').toLowerCase();
    final oracle = ((row[3] as String?) ?? '').toLowerCase();
    final manaCost = (row[4] as String?) ?? '';
    final colors = (row[5] as List?)?.cast<String>() ?? const <String>[];
    final identity = (row[6] as List?)?.cast<String>() ?? const <String>[];
    final popScore = (row[7] as num?)?.toInt() ?? 0;
    final functionalTags =
        (row[8] as List?)?.map((entry) => entry.toString()).toList() ??
            const <String>[];
    final semanticTagsV2 = row[9];
    final bestRoleScore = (row[10] as num?)?.toInt() ?? 0;
    final priceUsd = row[11];
    final priceUsdFoil = row[12];
    final ownedQuantity = (row[13] as num?)?.toInt() ?? 0;
    final estimatedPriceBrl = estimateOptimizePriceBrl(
      priceUsd: priceUsd,
      priceUsdFoil: priceUsdFoil,
      usdToBrlRate: usdToBrlRate,
    );
    if (effectiveBudgetLimit != null &&
        ownedQuantity <= 0 &&
        estimatedPriceBrl != null &&
        estimatedPriceBrl > effectiveBudgetLimit) {
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
      'functional_tags': functionalTags,
      'semantic_tags_v2': semanticTagsV2,
      'best_role_score': bestRoleScore,
      'price_usd': priceUsd,
      'price_usd_foil': priceUsdFoil,
      'estimated_price_brl': estimatedPriceBrl,
      'owned_quantity': ownedQuantity,
    });
  }

  final usedNames = <String>{};
  var budgetUsedBrl = 0.0;

  bool canUseCandidate(Map<String, dynamic> candidate) {
    if (effectiveBudgetLimit == null) return true;
    final ownedQuantity = (candidate['owned_quantity'] as num?)?.toInt() ?? 0;
    if (ownedQuantity > 0) return true;
    final estimatedPrice =
        (candidate['estimated_price_brl'] as num?)?.toDouble();
    if (estimatedPrice == null || estimatedPrice <= 0) return true;
    return budgetUsedBrl + estimatedPrice <= effectiveBudgetLimit + 0.01;
  }

  void consumeCandidateBudget(Map<String, dynamic> candidate) {
    if (effectiveBudgetLimit == null) return;
    final ownedQuantity = (candidate['owned_quantity'] as num?)?.toInt() ?? 0;
    if (ownedQuantity > 0) return;
    final estimatedPrice =
        (candidate['estimated_price_brl'] as num?)?.toDouble();
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

    for (final candidate in candidatePool) {
      final name = (candidate['name'] as String).toLowerCase();
      if (usedNames.contains(name)) continue;
      if (!canUseCandidate(candidate)) continue;
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
          ) +
          semanticReplacementScoreBoost(
            functionalNeed: need,
            candidate: candidate,
          ) +
          ((preferCollection &&
                  ((candidate['owned_quantity'] as num?)?.toInt() ?? 0) > 0)
              ? 220
              : 0);
      final matches = matchesFunctionalNeedForCandidate(
        need,
        candidate: candidate,
      );

      if (matches && score > bestScore) {
        best = candidate;
        bestScore = score;
      }
    }

    if (best != null) {
      results.add(_buildReplacementResult(best));
      usedNames.add((best['name'] as String).toLowerCase());
      consumeCandidateBudget(best);
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
            ) +
            semanticReplacementScoreBoost(
                functionalNeed: 'utility', candidate: a);
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
            ) +
            semanticReplacementScoreBoost(
                functionalNeed: 'utility', candidate: b);
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

      results.add(_buildReplacementResult(candidate));
      usedNames.add(name);
      consumeCandidateBudget(candidate);
    }
  }

  return results;
}

Map<String, dynamic> _buildReplacementResult(Map<String, dynamic> candidate) {
  final ownedQuantity = (candidate['owned_quantity'] as num?)?.toInt() ?? 0;
  final estimatedPrice = (candidate['estimated_price_brl'] as num?)?.toDouble();
  return {
    'id': candidate['id'],
    'name': candidate['name'],
    'owned_quantity': ownedQuantity,
    'collection_match': ownedQuantity > 0,
    'purchase_required': ownedQuantity <= 0,
    if (estimatedPrice != null)
      'estimated_price_brl': double.parse(estimatedPrice.toStringAsFixed(2)),
  };
}

bool matchesFunctionalNeedForCandidate(
  String need, {
  required Map<String, dynamic> candidate,
}) {
  final normalizedNeed = _normalizeReplacementNeed(need);
  final roles = optimizationFunctionalRolesForCard(candidate);
  if (normalizedNeed == 'utility') return true;
  if (roles.map(_normalizeReplacementNeed).contains(normalizedNeed)) {
    return true;
  }
  return matchesFunctionalNeed(
    need,
    oracleText: candidate['oracle_text'] as String? ?? '',
    typeLine: candidate['type_line'] as String? ?? '',
  );
}

int semanticReplacementScoreBoost({
  required String functionalNeed,
  required Map<String, dynamic> candidate,
}) {
  final normalizedNeed = _normalizeReplacementNeed(functionalNeed);
  final roles = optimizationFunctionalRolesForCard(candidate)
      .map(_normalizeReplacementNeed)
      .toSet();
  final roleScore = ((candidate['best_role_score'] as num?)?.toInt() ?? 0)
      .clamp(0, 100)
      .toInt();
  if (normalizedNeed == 'utility') {
    return roleScore ~/ 4;
  }
  if (!roles.contains(normalizedNeed)) return 0;
  return 90 + (roleScore ~/ 3);
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
    userId: userId,
    preferCollection: preferCollection,
    budgetLimitBrl: budgetLimitBrl,
    usdToBrlRate: usdToBrlRate,
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
        'owned_quantity': 0,
        'collection_match': false,
        'purchase_required': true,
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
      'owned_quantity': replacement['owned_quantity'],
      'collection_match': replacement['collection_match'] == true,
      'purchase_required': replacement['purchase_required'] != false,
      if (replacement['estimated_price_brl'] != null)
        'estimated_price_brl': replacement['estimated_price_brl'],
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

  // Em decks ja saudaveis, reduzir o numero de swaps diminui risco de regressao.
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
