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
      SELECT DISTINCT ON (LOWER(c.name))
             LOWER(c.name) AS name_lower,
             c.name,
             c.price_usd,
             c.price_usd_foil,
             COALESCE(owned.owned_quantity, 0)::int AS owned_quantity
      FROM cards c
      LEFT JOIN LATERAL (
        SELECT COALESCE(SUM(bi.quantity), 0)::int AS owned_quantity
        FROM user_binder_items bi
        WHERE bi.card_id = c.id
          AND bi.user_id = CAST(@user_id AS uuid)
          AND COALESCE(bi.list_type, 'have') = 'have'
      ) owned ON TRUE
      WHERE LOWER(c.name) = ANY(@names)
      ORDER BY LOWER(c.name),
               COALESCE(owned.owned_quantity, 0) DESC,
               c.price_usd NULLS LAST,
               c.name ASC
    '''),
    parameters: {
      'user_id': userId,
      'names': normalizedNames,
    },
  );

  final detailsByName = <String, Map<String, dynamic>>{};
  for (final row in rows) {
    final nameLower = (row[0] as String?) ?? '';
    if (nameLower.isEmpty) continue;
    final ownedQuantity = (row[4] as num?)?.toInt() ?? 0;
    final estimatedPrice = estimateOptimizePriceBrl(
      priceUsd: row[2],
      priceUsdFoil: row[3],
      usdToBrlRate: usdToBrlRate,
    );
    detailsByName[nameLower] = buildOptimizeRecommendationMarketDetail(
      ownedQuantity: ownedQuantity,
      estimatedPriceBrl: estimatedPrice,
      usdToBrlRate: usdToBrlRate,
    );
  }

  final budgetLimit = context.budgetLimitBrl;
  var budgetUsed = 0.0;
  final kept = <String>[];
  final blocked = <Map<String, dynamic>>[];
  for (final addition in validAdditions) {
    final nameLower = addition.trim().toLowerCase();
    final detail = detailsByName[nameLower];
    final ownedQuantity = (detail?['owned_quantity'] as num?)?.toInt() ?? 0;
    final purchaseRequired = ownedQuantity <= 0;
    final budgetCost = purchaseRequired
        ? (detail?['budget_cost_brl'] as num?)?.toDouble()
        : 0.0;

    if (budgetLimit != null &&
        budgetLimit > 0 &&
        purchaseRequired &&
        budgetCost != null &&
        budgetUsed + budgetCost > budgetLimit + 0.01) {
      blocked.add({
        'name': addition,
        'estimated_price_brl': budgetCost,
        'budget_used_before_brl': double.parse(budgetUsed.toStringAsFixed(2)),
      });
      continue;
    }

    kept.add(addition);
    if (budgetCost != null) budgetUsed += budgetCost;
  }

  final collectionMatches = kept.where((name) {
    final detail = detailsByName[name.trim().toLowerCase()];
    return ((detail?['owned_quantity'] as num?)?.toInt() ?? 0) > 0;
  }).length;
  final purchaseRequiredCount = kept.length - collectionMatches;
  final diagnostics = <String, dynamic>{
    'input_count': validAdditions.length,
    'output_count': kept.length,
    'prefer_collection': context.preferCollection == true,
    'collection_matched_count': collectionMatches,
    'purchase_required_count': purchaseRequiredCount,
    if (budgetLimit != null) 'budget_limit_brl': budgetLimit,
    if (budgetLimit != null)
      'budget_used_brl': double.parse(budgetUsed.toStringAsFixed(2)),
    if (blocked.isNotEmpty) 'budget_blocked_count': blocked.length,
    if (blocked.isNotEmpty) 'budget_blocked_additions': blocked,
    'price_source': 'cards.price_usd_estimated_brl',
    'usd_to_brl_rate': usdToBrlRate,
  };

  final warnings = <String>[];
  if (blocked.isNotEmpty) {
    warnings.add(
      'Orcamento aplicado: ${blocked.length} adicao(oes) acima do limite de R\$ $budgetLimit foram removidas da sugestao.',
    );
  }
  if (context.preferCollection == true && collectionMatches == 0) {
    warnings.add(
      'A preferencia por colecao foi considerada, mas nenhuma adicao final foi encontrada no fichario do usuario.',
    );
  }

  return OptimizeRecommendationConstraintResult(
    additions: kept,
    diagnostics: diagnostics,
    detailsByNameLower: detailsByName,
    validationWarnings: warnings,
  );
}

Map<String, dynamic> buildOptimizeRecommendationMarketDetail({
  required int ownedQuantity,
  required double? estimatedPriceBrl,
  required double usdToBrlRate,
}) {
  final purchaseRequired = ownedQuantity <= 0;
  return {
    'owned_quantity': ownedQuantity,
    'collection_match': ownedQuantity > 0,
    'purchase_required': purchaseRequired,
    'source': ownedQuantity > 0 ? 'collection' : 'market',
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
