import 'package:postgres/postgres.dart';

import 'optimize_route_request_support.dart';

const defaultOptimizeUsdToBrlRate = 5.50;

class OptimizeRecommendationConstraintResult {
  const OptimizeRecommendationConstraintResult({
    required this.additions,
    required this.diagnostics,
    required this.detailsByNameLower,
    required this.validationWarnings,
  });

  final List<String> additions;
  final Map<String, dynamic> diagnostics;
  final Map<String, Map<String, dynamic>> detailsByNameLower;
  final List<String> validationWarnings;

  bool get changed => additions.length != diagnostics['input_count'];
}

class OptimizeBudgetConstraintResult {
  const OptimizeBudgetConstraintResult({
    required this.additions,
    required this.blockedAdditions,
    required this.budgetUsedBrl,
    required this.collectionMatchedCount,
    required this.purchaseRequiredCount,
    required this.missingPriceBlockedCount,
    required this.budgetExceededBlockedCount,
  });

  final List<String> additions;
  final List<Map<String, dynamic>> blockedAdditions;
  final double budgetUsedBrl;
  final int collectionMatchedCount;
  final int purchaseRequiredCount;
  final int missingPriceBlockedCount;
  final int budgetExceededBlockedCount;
}

OptimizeBudgetConstraintResult applyOptimizeBudgetConstraint({
  required List<String> additions,
  required Map<String, Map<String, dynamic>> detailsByNameLower,
  required double? budgetLimitBrl,
}) {
  final budgetIsActive = budgetLimitBrl != null && budgetLimitBrl >= 0;
  final remainingAvailableByName = <String, int>{
    for (final entry in detailsByNameLower.entries)
      entry.key: ((entry.value['available_quantity'] as num?)?.toInt() ??
              (entry.value['owned_quantity'] as num?)?.toInt() ??
              0)
          .clamp(0, 1 << 31),
  };
  var budgetUsed = 0.0;
  var collectionMatchedCount = 0;
  var purchaseRequiredCount = 0;
  var missingPriceBlockedCount = 0;
  var budgetExceededBlockedCount = 0;
  final kept = <String>[];
  final blocked = <Map<String, dynamic>>[];

  for (final addition in additions) {
    final nameLower = addition.trim().toLowerCase();
    final detail = detailsByNameLower[nameLower];
    final remainingAvailable = remainingAvailableByName[nameLower] ?? 0;
    if (remainingAvailable > 0) {
      remainingAvailableByName[nameLower] = remainingAvailable - 1;
      collectionMatchedCount += 1;
      kept.add(addition);
      continue;
    }

    final budgetCost = _detailBudgetCostBrl(detail);
    if (budgetIsActive && budgetCost == null) {
      missingPriceBlockedCount += 1;
      blocked.add({
        'name': addition,
        'reason': 'missing_price',
        'price_status': detail?['price_status'] ?? 'missing',
        'budget_used_before_brl': double.parse(budgetUsed.toStringAsFixed(2)),
      });
      continue;
    }
    if (budgetIsActive &&
        budgetCost != null &&
        budgetUsed + budgetCost > budgetLimitBrl + 0.01) {
      budgetExceededBlockedCount += 1;
      blocked.add({
        'name': addition,
        'reason': 'budget_exceeded',
        'estimated_price_brl': budgetCost,
        'budget_used_before_brl': double.parse(budgetUsed.toStringAsFixed(2)),
      });
      continue;
    }

    kept.add(addition);
    purchaseRequiredCount += 1;
    if (budgetCost != null) budgetUsed += budgetCost;
  }

  return OptimizeBudgetConstraintResult(
    additions: kept,
    blockedAdditions: blocked,
    budgetUsedBrl: double.parse(budgetUsed.toStringAsFixed(2)),
    collectionMatchedCount: collectionMatchedCount,
    purchaseRequiredCount: purchaseRequiredCount,
    missingPriceBlockedCount: missingPriceBlockedCount,
    budgetExceededBlockedCount: budgetExceededBlockedCount,
  );
}

double? _detailBudgetCostBrl(Map<String, dynamic>? detail) {
  if (detail == null) return null;
  for (final key in const ['budget_cost_brl', 'estimated_price_brl']) {
    final value = detail[key];
    final parsed = switch (value) {
      num() => value.toDouble(),
      String() => double.tryParse(value.trim()),
      _ => null,
    };
    if (parsed != null && parsed >= 0) return parsed;
  }
  return null;
}

Future<OptimizeRecommendationConstraintResult>
applyOptimizeRecommendationConstraints({
  required Pool pool,
  required String userId,
  required List<String> validAdditions,
  required OptimizeRecommendationContext context,
  double usdToBrlRate = defaultOptimizeUsdToBrlRate,
}) async {
  if (validAdditions.isEmpty ||
      context.preferCollection != true && context.budgetLimitBrl == null) {
    return OptimizeRecommendationConstraintResult(
      additions: validAdditions,
      diagnostics: const <String, dynamic>{},
      detailsByNameLower: const <String, Map<String, dynamic>>{},
      validationWarnings: const <String>[],
    );
  }

  final normalizedNames = validAdditions
      .map((name) => name.trim().toLowerCase())
      .where((name) => name.isNotEmpty)
      .toSet()
      .toList(growable: false);
  if (normalizedNames.isEmpty) {
    return OptimizeRecommendationConstraintResult(
      additions: validAdditions,
      diagnostics: const <String, dynamic>{},
      detailsByNameLower: const <String, Map<String, dynamic>>{},
      validationWarnings: const <String>[],
    );
  }

  final rows = await pool.execute(
    Sql.named('''
      WITH catalog AS (
        SELECT LOWER(c.name) AS name_lower,
               MIN(c.name) AS name,
               MIN(c.price_usd) FILTER (WHERE c.price_usd > 0) AS price_usd,
               MIN(c.price_usd_foil)
                 FILTER (WHERE c.price_usd_foil > 0) AS price_usd_foil
        FROM cards c
        WHERE LOWER(c.name) = ANY(@names)
        GROUP BY LOWER(c.name)
      ), playable AS (
        SELECT DISTINCT LOWER(c.name) AS name_lower,
               COALESCE(c.oracle_id, c.id) AS playable_card_id
        FROM cards c
        WHERE LOWER(c.name) = ANY(@names)
      ), availability AS (
        SELECT playable.name_lower,
               COALESCE(SUM(snapshot.owned_quantity), 0)::int
                 AS owned_quantity,
               COALESCE(SUM(snapshot.free_quantity), 0)::int
                 AS available_quantity
        FROM playable
        LEFT JOIN collection_availability_snapshot snapshot
          ON snapshot.playable_card_id = playable.playable_card_id
         AND snapshot.user_id = CAST(@user_id AS uuid)
        GROUP BY playable.name_lower
      )
      SELECT catalog.name_lower, catalog.name, catalog.price_usd,
             catalog.price_usd_foil,
             COALESCE(availability.owned_quantity, 0)::int,
             COALESCE(availability.available_quantity, 0)::int
      FROM catalog
      LEFT JOIN availability USING (name_lower)
      ORDER BY catalog.name_lower
    '''),
    parameters: {'user_id': userId, 'names': normalizedNames},
  );

  final detailsByName = <String, Map<String, dynamic>>{};
  for (final row in rows) {
    final nameLower = (row[0] as String?) ?? '';
    if (nameLower.isEmpty) continue;
    final ownedQuantity = (row[4] as num?)?.toInt() ?? 0;
    final availableQuantity = (row[5] as num?)?.toInt() ?? 0;
    final estimatedPrice = estimateOptimizePriceBrl(
      priceUsd: row[2],
      priceUsdFoil: row[3],
      usdToBrlRate: usdToBrlRate,
    );
    detailsByName[nameLower] = buildOptimizeRecommendationMarketDetail(
      ownedQuantity: ownedQuantity,
      availableQuantity: availableQuantity,
      estimatedPriceBrl: estimatedPrice,
      usdToBrlRate: usdToBrlRate,
    );
  }

  final budgetLimit = context.budgetLimitBrl?.toDouble();
  final budgetResult = applyOptimizeBudgetConstraint(
    additions: validAdditions,
    detailsByNameLower: detailsByName,
    budgetLimitBrl: budgetLimit,
  );
  final diagnostics = <String, dynamic>{
    'input_count': validAdditions.length,
    'output_count': budgetResult.additions.length,
    'prefer_collection': context.preferCollection == true,
    'collection_matched_count': budgetResult.collectionMatchedCount,
    'purchase_required_count': budgetResult.purchaseRequiredCount,
    if (budgetLimit != null) 'budget_limit_brl': budgetLimit,
    if (budgetLimit != null) 'budget_used_brl': budgetResult.budgetUsedBrl,
    if (budgetResult.blockedAdditions.isNotEmpty)
      'budget_blocked_count': budgetResult.blockedAdditions.length,
    if (budgetResult.missingPriceBlockedCount > 0)
      'missing_price_blocked_count': budgetResult.missingPriceBlockedCount,
    if (budgetResult.budgetExceededBlockedCount > 0)
      'budget_exceeded_blocked_count': budgetResult.budgetExceededBlockedCount,
    if (budgetResult.blockedAdditions.isNotEmpty)
      'budget_blocked_additions': budgetResult.blockedAdditions,
    'price_source': 'cards.price_usd_estimated_brl',
    'usd_to_brl_rate': usdToBrlRate,
  };

  final warnings = <String>[];
  if (budgetResult.missingPriceBlockedCount > 0) {
    warnings.add(
      'Orcamento aplicado: ${budgetResult.missingPriceBlockedCount} adicao(oes) sem preco verificavel foram bloqueadas.',
    );
  }
  if (budgetResult.budgetExceededBlockedCount > 0) {
    warnings.add(
      'Orcamento aplicado: ${budgetResult.budgetExceededBlockedCount} adicao(oes) acima do limite de R\$ $budgetLimit foram removidas da sugestao.',
    );
  }
  if (context.preferCollection == true &&
      budgetResult.collectionMatchedCount == 0) {
    warnings.add(
      'A preferencia por colecao foi considerada, mas nenhuma adicao final foi encontrada no fichario do usuario.',
    );
  }

  return OptimizeRecommendationConstraintResult(
    additions: budgetResult.additions,
    diagnostics: diagnostics,
    detailsByNameLower: detailsByName,
    validationWarnings: warnings,
  );
}

Map<String, dynamic> buildOptimizeRecommendationMarketDetail({
  required int ownedQuantity,
  int? availableQuantity,
  required double? estimatedPriceBrl,
  required double usdToBrlRate,
}) {
  final available = availableQuantity ?? ownedQuantity;
  final purchaseRequired = available <= 0;
  return {
    'owned_quantity': ownedQuantity,
    'available_quantity': available,
    'collection_match': available > 0,
    'purchase_required': purchaseRequired,
    'source': available > 0 ? 'collection_free' : 'market',
    'price_available': estimatedPriceBrl != null,
    'price_status': estimatedPriceBrl == null ? 'missing' : 'estimated',
    if (estimatedPriceBrl != null)
      'estimated_price_brl': estimatedPriceBrl.toStringAsFixed(2),
    if (estimatedPriceBrl != null)
      'price_brl': 'R\$ ${estimatedPriceBrl.toStringAsFixed(2)}',
    if (purchaseRequired && estimatedPriceBrl != null)
      'budget_cost_brl': estimatedPriceBrl,
    if (purchaseRequired && estimatedPriceBrl != null)
      'price_source': 'cards.price_usd_estimated_brl',
    if (purchaseRequired && estimatedPriceBrl != null)
      'usd_to_brl_rate': usdToBrlRate,
  };
}

double? estimateOptimizePriceBrl({
  required Object? priceUsd,
  required Object? priceUsdFoil,
  double usdToBrlRate = defaultOptimizeUsdToBrlRate,
}) {
  final candidates = <double?>[
    _safePositiveDouble(priceUsd),
    _safePositiveDouble(priceUsdFoil),
  ].whereType<double>().toList(growable: false);
  if (candidates.isEmpty || usdToBrlRate <= 0) return null;
  final minUsd = candidates.reduce((a, b) => a < b ? a : b);
  return double.parse((minUsd * usdToBrlRate).toStringAsFixed(2));
}

double? _safePositiveDouble(Object? value) {
  final parsed = switch (value) {
    num() => value.toDouble(),
    String() => double.tryParse(value.trim()),
    _ => null,
  };
  if (parsed == null || parsed <= 0) return null;
  return parsed;
}
