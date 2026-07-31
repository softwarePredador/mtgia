import 'package:postgres/postgres.dart';

import '../basic_land_utils.dart' as basic_lands;
import 'optimize_route_request_support.dart';

const defaultOptimizeUsdToBrlRate = 5.50;

/// Mutable reservation ledger shared by every candidate source in one
/// Complete build.
///
/// Collection availability and budget are finite resources. Without a shared
/// ledger, separate AI/deterministic/fallback batches can each spend the same
/// free copy or restart the requested budget from zero. The final audit still
/// fails closed, but the user receives an avoidable error instead of the next
/// valid candidate.
class OptimizeRecommendationConstraintLedger {
  final Map<String, int> _remainingAvailableByName = <String, int>{};
  double _budgetUsedBrl = 0;

  double get budgetUsedBrl => _budgetUsedBrl;

  int remainingAvailable(String name, {required int initialAvailableQuantity}) {
    final normalized = name.trim().toLowerCase();
    if (normalized.isEmpty) return 0;
    _remainingAvailableByName.putIfAbsent(
      normalized,
      () => initialAvailableQuantity.clamp(0, 1 << 31).toInt(),
    );
    return _remainingAvailableByName[normalized] ?? 0;
  }

  void reserve({
    required String name,
    required int initialAvailableQuantity,
    required double? budgetCostBrl,
  }) {
    final normalized = name.trim().toLowerCase();
    if (normalized.isEmpty) return;
    final available = remainingAvailable(
      normalized,
      initialAvailableQuantity: initialAvailableQuantity,
    );
    if (available > 0) {
      _remainingAvailableByName[normalized] = available - 1;
      return;
    }
    if (budgetCostBrl != null && budgetCostBrl > 0) {
      _budgetUsedBrl += budgetCostBrl;
    }
  }
}

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
  OptimizeRecommendationConstraintLedger? ledger,
}) {
  final budgetIsActive = budgetLimitBrl != null && budgetLimitBrl >= 0;
  final localLedger = ledger ?? OptimizeRecommendationConstraintLedger();
  for (final entry in detailsByNameLower.entries) {
    localLedger.remainingAvailable(
      entry.key,
      initialAvailableQuantity:
          ((entry.value['available_quantity'] as num?)?.toInt() ??
                  (entry.value['owned_quantity'] as num?)?.toInt() ??
                  0)
              .clamp(0, 1 << 31)
              .toInt(),
    );
  }
  var budgetUsed = localLedger.budgetUsedBrl;
  var collectionMatchedCount = 0;
  var purchaseRequiredCount = 0;
  var missingPriceBlockedCount = 0;
  var budgetExceededBlockedCount = 0;
  final kept = <String>[];
  final blocked = <Map<String, dynamic>>[];

  for (final addition in additions) {
    final nameLower = addition.trim().toLowerCase();
    final detail = detailsByNameLower[nameLower];
    if (detail?['is_basic_land'] == true ||
        basic_lands.isBasicLandName(nameLower)) {
      kept.add(addition);
      continue;
    }
    final initialAvailable =
        ((detail?['available_quantity'] as num?)?.toInt() ??
                (detail?['owned_quantity'] as num?)?.toInt() ??
                0)
            .clamp(0, 1 << 31)
            .toInt();
    final remainingAvailable = localLedger.remainingAvailable(
      nameLower,
      initialAvailableQuantity: initialAvailable,
    );
    if (remainingAvailable > 0) {
      localLedger.reserve(
        name: nameLower,
        initialAvailableQuantity: initialAvailable,
        budgetCostBrl: null,
      );
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
        budgetUsed + budgetCost > budgetLimitBrl + 0.0001) {
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
    localLedger.reserve(
      name: nameLower,
      initialAvailableQuantity: initialAvailable,
      budgetCostBrl: budgetCost,
    );
    budgetUsed = localLedger.budgetUsedBrl;
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
  OptimizeRecommendationConstraintLedger? ledger,
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
                 FILTER (WHERE c.price_usd_foil > 0) AS price_usd_foil,
               BOOL_OR(
                 COALESCE(c.type_line, '') ~*
                 '(^|[^[:alpha:]])basic[[:space:]]+(snow[[:space:]]+)?land([^[:alpha:]]|\$)'
               ) AS is_basic_land
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
             catalog.price_usd_foil, catalog.is_basic_land,
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
    final isBasicLand = row[4] == true;
    final ownedQuantity = (row[5] as num?)?.toInt() ?? 0;
    final availableQuantity = (row[6] as num?)?.toInt() ?? 0;
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
      isBasicLand: isBasicLand,
    );
  }

  final budgetLimit = context.budgetLimitBrl?.toDouble();
  final budgetResult = applyOptimizeBudgetConstraint(
    additions: validAdditions,
    detailsByNameLower: detailsByName,
    budgetLimitBrl: budgetLimit,
    ledger: ledger,
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
  bool isBasicLand = false,
}) {
  final available = availableQuantity ?? ownedQuantity;
  if (isBasicLand) {
    return {
      'owned_quantity': ownedQuantity,
      'available_quantity': available,
      'collection_match': false,
      'purchase_required': false,
      'source': 'basic_land_zero_cost',
      'is_basic_land': true,
      'price_available': true,
      'price_status': 'not_required',
      'budget_cost_brl': 0.0,
    };
  }
  final purchaseRequired = available <= 0;
  return {
    'owned_quantity': ownedQuantity,
    'available_quantity': available,
    'collection_match': available > 0,
    'purchase_required': purchaseRequired,
    'source': available > 0 ? 'collection_free' : 'market',
    if (isBasicLand) 'is_basic_land': true,
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

List<String> expandCompleteRecommendationAdditionNames(
  Map<String, dynamic> responseBody,
) {
  final detailed = responseBody['additions_detailed'];
  if (detailed is List) {
    final expanded = <String>[];
    for (final raw in detailed.whereType<Map>()) {
      final name = raw['name']?.toString().trim() ?? '';
      if (name.isEmpty) continue;
      final quantity = switch (raw['quantity']) {
        int value => value,
        num value => value.toInt(),
        String value => int.tryParse(value.trim()) ?? 1,
        _ => 1,
      };
      for (var index = 0; index < (quantity > 0 ? quantity : 1); index++) {
        expanded.add(name);
      }
    }
    if (expanded.isNotEmpty) return expanded;
  }
  return ((responseBody['additions'] as List?) ?? const [])
      .map((name) => name.toString().trim())
      .where((name) => name.isNotEmpty)
      .toList(growable: false);
}

void applyCompleteRecommendationConstraintAuditResult({
  required Map<String, dynamic> responseBody,
  required OptimizeRecommendationConstraintResult result,
  required OptimizeRecommendationContext context,
}) {
  final inputCount = (result.diagnostics['input_count'] as num?)?.toInt() ?? 0;
  final outputCount =
      (result.diagnostics['output_count'] as num?)?.toInt() ??
      result.additions.length;
  final satisfied = outputCount == inputCount;
  responseBody['recommendation_constraints'] = {
    ...result.diagnostics,
    'enforcement': 'complete_final_fail_closed',
    'satisfied': satisfied,
  };

  final details = result.detailsByNameLower;
  final rawDetailed = responseBody['additions_detailed'];
  if (rawDetailed is List && details.isNotEmpty) {
    responseBody['additions_detailed'] =
        rawDetailed.map((raw) {
          if (raw is! Map) return raw;
          final item = raw.cast<String, dynamic>();
          final name = item['name']?.toString().trim().toLowerCase() ?? '';
          return {...item, ...?details[name]};
        }).toList();
  }

  final existingWarnings =
      ((responseBody['validation_warnings'] as List?) ?? const [])
          .map((warning) => warning.toString())
          .toList();
  responseBody['validation_warnings'] = [
    ...existingWarnings,
    ...result.validationWarnings,
  ];

  if (satisfied || context.budgetLimitBrl == null) return;
  final blockers =
      ((responseBody['apply_blockers'] as List?) ?? const [])
          .map((blocker) => blocker.toString())
          .toSet()
        ..add('complete_recommendation_constraints_unsatisfied');
  responseBody
    ..['quality_error'] = {
      'code': 'COMPLETE_RECOMMENDATION_CONSTRAINTS_UNSATISFIED',
      'message':
          'Complete bloqueado: as novas cartas não cabem no orçamento '
          'solicitado ou não possuem preço verificável.',
      'recommendation_constraints': responseBody['recommendation_constraints'],
    }
    ..['can_apply'] = false
    ..['learning_eligible'] = false
    ..['apply_blockers'] = blockers.toList();
}

Future<void> auditCompleteRecommendationConstraints({
  required Pool pool,
  required String userId,
  required Map<String, dynamic> responseBody,
  required OptimizeRecommendationContext context,
}) async {
  if (responseBody['quality_error'] is Map ||
      context.preferCollection != true && context.budgetLimitBrl == null) {
    return;
  }
  if (userId.trim().isEmpty) {
    final blockers =
        ((responseBody['apply_blockers'] as List?) ?? const [])
            .map((blocker) => blocker.toString())
            .toSet()
          ..add('complete_recommendation_context_unavailable');
    responseBody
      ..['quality_error'] = {
        'code': 'COMPLETE_RECOMMENDATION_CONTEXT_UNAVAILABLE',
        'message':
            'Complete bloqueado: não foi possível auditar coleção e '
            'orçamento para esta sessão.',
      }
      ..['can_apply'] = false
      ..['learning_eligible'] = false
      ..['apply_blockers'] = blockers.toList();
    return;
  }
  final additions = expandCompleteRecommendationAdditionNames(responseBody);
  if (additions.isEmpty) return;

  final result = await applyOptimizeRecommendationConstraints(
    pool: pool,
    userId: userId,
    validAdditions: additions,
    context: context,
  );
  applyCompleteRecommendationConstraintAuditResult(
    responseBody: responseBody,
    result: result,
    context: context,
  );
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
