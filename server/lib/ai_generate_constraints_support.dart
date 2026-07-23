import 'dart:convert';

import 'package:postgres/postgres.dart';

import 'ai_generate_performance_support.dart';
import 'basic_land_utils.dart';

const aiGenerateUsdToBrlRate = 5.50;

class AiGenerateConstraintGuidance {
  const AiGenerateConstraintGuidance({
    required this.prompt,
    required this.diagnostics,
  });

  const AiGenerateConstraintGuidance.empty()
    : prompt = '',
      diagnostics = const <String, dynamic>{};

  final String prompt;
  final Map<String, dynamic> diagnostics;
}

Future<AiGenerateConstraintGuidance> loadAiGenerateConstraintGuidance({
  required Pool pool,
  required String userId,
  required AiGenerateConstraints constraints,
  int maxOwnedCandidates = 400,
}) async {
  if (!constraints.isRequested) {
    return const AiGenerateConstraintGuidance.empty();
  }

  final ownedCandidates = <Map<String, dynamic>>[];
  var totalOwnedNames = 0;
  if (constraints.preferCollection || constraints.collectionOnly) {
    final rows = await pool.execute(
      Sql.named('''
        WITH available AS (
          SELECT LOWER(canonical_name) AS name_lower,
                 MIN(canonical_name) AS name,
                 SUM(free_quantity)::int AS available_quantity
          FROM collection_availability_snapshot
          WHERE user_id = CAST(@user_id AS uuid)
            AND free_quantity > 0
          GROUP BY LOWER(canonical_name)
        )
        SELECT name, available_quantity, COUNT(*) OVER()::int AS total_names
        FROM available
        ORDER BY available_quantity DESC, name ASC
        LIMIT @limit
      '''),
      parameters: {
        'user_id': userId,
        'limit': maxOwnedCandidates.clamp(1, 1000),
      },
    );
    for (final row in rows) {
      totalOwnedNames = (row[2] as num?)?.toInt() ?? totalOwnedNames;
      ownedCandidates.add({
        'name': row[0]?.toString() ?? '',
        'available_quantity': (row[1] as num?)?.toInt() ?? 0,
      });
    }
  }

  final lines = <String>[
    'Generation constraints selected by the player:',
    if (constraints.preferCollection)
      '- Prefer cards from the owned-candidate list when legal and strategically coherent.',
    if (constraints.collectionOnly)
      '- HARD: use only cards available in the player collection, except basic lands. The server will reject any shortage.',
    if (constraints.budgetLimitBrl != null)
      '- HARD: total purchases must not exceed BRL ${constraints.budgetLimitBrl}. Missing prices are not free and will be rejected.',
    if (ownedCandidates.isNotEmpty)
      '- Owned candidates (exact names and available quantities): ${jsonEncode(ownedCandidates)}',
    '- Preserve the exact deck size and format legality. Never remove cards merely to fit a constraint.',
  ];
  return AiGenerateConstraintGuidance(
    prompt: lines.join('\n'),
    diagnostics: {
      'schema_version': 'ai_generate_constraint_guidance_v1_2026-07-22',
      'source': 'postgres_collection_availability_snapshot',
      'owned_candidate_count': ownedCandidates.length,
      'owned_total_name_count': totalOwnedNames,
      'owned_candidates_truncated': totalOwnedNames > ownedCandidates.length,
      'cache_policy': 'global_response_cache_bypassed',
    },
  );
}

class AiGenerateCardMarketState {
  const AiGenerateCardMarketState({
    required this.availableQuantity,
    required this.estimatedUnitPriceBrl,
  });

  final int availableQuantity;
  final double? estimatedUnitPriceBrl;
}

class AiGenerateConstraintAudit {
  const AiGenerateConstraintAudit({
    required this.canSave,
    required this.blockers,
    required this.cardDetails,
    required this.requiredQuantity,
    required this.collectionMatchedQuantity,
    required this.purchaseRequiredQuantity,
    required this.missingPriceQuantity,
    required this.estimatedPurchaseTotalBrl,
  });

  final bool canSave;
  final List<Map<String, dynamic>> blockers;
  final List<Map<String, dynamic>> cardDetails;
  final int requiredQuantity;
  final int collectionMatchedQuantity;
  final int purchaseRequiredQuantity;
  final int missingPriceQuantity;
  final double estimatedPurchaseTotalBrl;

  Map<String, dynamic> toJson(AiGenerateConstraints constraints) => {
    'schema_version': 'ai_generate_constraints_v1_2026-07-22',
    'source': 'postgres_cards_and_collection_availability_snapshot',
    'requested': constraints.toJson(),
    'can_save': canSave,
    'blockers': blockers,
    'summary': {
      'required_quantity': requiredQuantity,
      'collection_matched_quantity': collectionMatchedQuantity,
      'purchase_required_quantity': purchaseRequiredQuantity,
      'missing_price_quantity': missingPriceQuantity,
      'estimated_purchase_total_brl': estimatedPurchaseTotalBrl,
      if (constraints.budgetLimitBrl != null)
        'budget_limit_brl': constraints.budgetLimitBrl,
      'basic_land_policy': 'assumed_available_zero_cost',
      'price_source': 'cards.price_usd_estimated_brl',
      'usd_to_brl_rate': aiGenerateUsdToBrlRate,
    },
    'cards': cardDetails,
  };
}

AiGenerateConstraintAudit evaluateAiGenerateConstraints({
  required Map<String, dynamic> generatedDeck,
  required AiGenerateConstraints constraints,
  required Map<String, AiGenerateCardMarketState> marketByNameLower,
}) {
  final requiredByName = <String, ({String name, int quantity})>{};

  void addCard(Object? rawName, Object? rawQuantity) {
    final name = rawName?.toString().trim() ?? '';
    if (name.isEmpty) return;
    final quantity = switch (rawQuantity) {
      int() => rawQuantity,
      num() => rawQuantity.toInt(),
      _ => int.tryParse(rawQuantity?.toString() ?? '') ?? 1,
    };
    if (quantity <= 0) return;
    final key = name.toLowerCase();
    final current = requiredByName[key];
    requiredByName[key] = (
      name: current?.name ?? name,
      quantity: (current?.quantity ?? 0) + quantity,
    );
  }

  final commander = generatedDeck['commander'];
  if (commander is Map) addCard(commander['name'], 1);
  final cards = generatedDeck['cards'];
  if (cards is Iterable) {
    for (final card in cards.whereType<Map>()) {
      addCard(card['name'], card['quantity']);
    }
  }

  var requiredQuantity = 0;
  var collectionMatchedQuantity = 0;
  var purchaseRequiredQuantity = 0;
  var missingPriceQuantity = 0;
  var estimatedPurchaseTotalBrl = 0.0;
  final collectionOnlyCards = <Map<String, dynamic>>[];
  final missingPriceCards = <Map<String, dynamic>>[];
  final details = <Map<String, dynamic>>[];

  final sortedEntries =
      requiredByName.entries.toList()
        ..sort((a, b) => a.value.name.compareTo(b.value.name));
  for (final entry in sortedEntries) {
    final name = entry.value.name;
    final quantity = entry.value.quantity;
    requiredQuantity += quantity;

    if (isBasicLandName(name)) {
      collectionMatchedQuantity += quantity;
      details.add({
        'name': name,
        'required_quantity': quantity,
        'collection_matched_quantity': quantity,
        'purchase_required_quantity': 0,
        'price_available': true,
        'price_status': 'basic_land_zero_cost',
        'estimated_purchase_cost_brl': 0.0,
      });
      continue;
    }

    final market = marketByNameLower[entry.key];
    final availableQuantity = (market?.availableQuantity ?? 0).clamp(
      0,
      quantity,
    );
    final purchaseQuantity = quantity - availableQuantity;
    final unitPrice = market?.estimatedUnitPriceBrl;
    final purchaseCost =
        unitPrice == null ? null : _money(unitPrice * purchaseQuantity);
    collectionMatchedQuantity += availableQuantity;
    purchaseRequiredQuantity += purchaseQuantity;
    if (purchaseQuantity > 0 && unitPrice == null) {
      missingPriceQuantity += purchaseQuantity;
      missingPriceCards.add({'name': name, 'quantity': purchaseQuantity});
    }
    if (purchaseCost != null) estimatedPurchaseTotalBrl += purchaseCost;
    if (constraints.collectionOnly && purchaseQuantity > 0) {
      collectionOnlyCards.add({'name': name, 'quantity': purchaseQuantity});
    }

    details.add({
      'name': name,
      'required_quantity': quantity,
      'available_quantity': market?.availableQuantity ?? 0,
      'collection_matched_quantity': availableQuantity,
      'purchase_required_quantity': purchaseQuantity,
      'price_available': unitPrice != null,
      'price_status': unitPrice == null ? 'missing' : 'estimated',
      if (unitPrice != null) 'estimated_unit_price_brl': _money(unitPrice),
      if (purchaseCost != null) 'estimated_purchase_cost_brl': purchaseCost,
    });
  }
  estimatedPurchaseTotalBrl = _money(estimatedPurchaseTotalBrl);

  final blockers = <Map<String, dynamic>>[];
  if (collectionOnlyCards.isNotEmpty) {
    blockers.add({
      'code': 'collection_only_unavailable',
      'message': 'A lista exige cartas que não estão disponíveis na coleção.',
      'card_count': collectionOnlyCards.length,
      'quantity': collectionOnlyCards.fold<int>(
        0,
        (sum, card) => sum + (card['quantity'] as int),
      ),
      'cards': collectionOnlyCards.take(20).toList(growable: false),
    });
  }
  if (constraints.budgetLimitBrl != null && missingPriceCards.isNotEmpty) {
    blockers.add({
      'code': 'missing_price',
      'message':
          'O orçamento não pode ser confirmado porque há compras sem preço.',
      'card_count': missingPriceCards.length,
      'quantity': missingPriceQuantity,
      'cards': missingPriceCards.take(20).toList(growable: false),
    });
  }
  final budgetLimit = constraints.budgetLimitBrl;
  if (budgetLimit != null && estimatedPurchaseTotalBrl > budgetLimit + 0.01) {
    blockers.add({
      'code': 'budget_exceeded',
      'message': 'O custo estimado das compras excede o orçamento informado.',
      'budget_limit_brl': budgetLimit,
      'estimated_purchase_total_brl': estimatedPurchaseTotalBrl,
    });
  }

  return AiGenerateConstraintAudit(
    canSave: blockers.isEmpty,
    blockers: blockers,
    cardDetails: details,
    requiredQuantity: requiredQuantity,
    collectionMatchedQuantity: collectionMatchedQuantity,
    purchaseRequiredQuantity: purchaseRequiredQuantity,
    missingPriceQuantity: missingPriceQuantity,
    estimatedPurchaseTotalBrl: estimatedPurchaseTotalBrl,
  );
}

Future<AiGenerateConstraintAudit> loadAndEvaluateAiGenerateConstraints({
  required Pool pool,
  required String userId,
  required Map<String, dynamic> generatedDeck,
  required AiGenerateConstraints constraints,
}) async {
  final names = <String>{};
  final commander = generatedDeck['commander'];
  if (commander is Map) {
    final name = commander['name']?.toString().trim().toLowerCase() ?? '';
    if (name.isNotEmpty && !isBasicLandName(name)) names.add(name);
  }
  final cards = generatedDeck['cards'];
  if (cards is Iterable) {
    for (final card in cards.whereType<Map>()) {
      final name = card['name']?.toString().trim().toLowerCase() ?? '';
      if (name.isNotEmpty && !isBasicLandName(name)) names.add(name);
    }
  }

  final marketByName = <String, AiGenerateCardMarketState>{};
  if (names.isNotEmpty) {
    final rows = await pool.execute(
      Sql.named('''
        WITH catalog AS (
          SELECT LOWER(c.name) AS name_lower,
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
        ), available AS (
          SELECT playable.name_lower,
                 COALESCE(SUM(snapshot.free_quantity), 0)::int
                   AS available_quantity
          FROM playable
          LEFT JOIN collection_availability_snapshot snapshot
            ON snapshot.playable_card_id = playable.playable_card_id
           AND snapshot.user_id = CAST(@user_id AS uuid)
          GROUP BY playable.name_lower
        )
        SELECT catalog.name_lower, catalog.price_usd, catalog.price_usd_foil,
               COALESCE(available.available_quantity, 0)::int
        FROM catalog
        LEFT JOIN available USING (name_lower)
      '''),
      parameters: {'user_id': userId, 'names': names.toList(growable: false)},
    );
    for (final row in rows) {
      final key = row[0]?.toString() ?? '';
      if (key.isEmpty) continue;
      marketByName[key] = AiGenerateCardMarketState(
        availableQuantity: (row[3] as num?)?.toInt() ?? 0,
        estimatedUnitPriceBrl: _estimateBrl(row[1], row[2]),
      );
    }
  }

  return evaluateAiGenerateConstraints(
    generatedDeck: generatedDeck,
    constraints: constraints,
    marketByNameLower: marketByName,
  );
}

Future<Map<String, dynamic>> enforceAiGenerateConstraints({
  required Pool pool,
  required String userId,
  required Map<String, dynamic> responseBody,
  required AiGenerateConstraints constraints,
}) async {
  if (!constraints.isRequested) return responseBody;
  final generatedDeck = responseBody['generated_deck'];
  if (generatedDeck is! Map) {
    return {
      ...responseBody,
      'can_save': false,
      'generation_constraints': {
        'schema_version': 'ai_generate_constraints_v1_2026-07-22',
        'requested': constraints.toJson(),
        'can_save': false,
        'blockers': const [
          {
            'code': 'generated_deck_missing',
            'message': 'A lista gerada não está disponível para auditoria.',
          },
        ],
      },
      'learning_eligible': false,
      'learning_exclusion_reason': 'generation_constraints_not_verified',
    };
  }
  final audit = await loadAndEvaluateAiGenerateConstraints(
    pool: pool,
    userId: userId,
    generatedDeck: generatedDeck.cast<String, dynamic>(),
    constraints: constraints,
  );
  return {
    ...responseBody,
    'can_save': audit.canSave,
    'generation_constraints': audit.toJson(constraints),
    if (!audit.canSave) ...{
      'learning_eligible': false,
      'learning_exclusion_reason': 'generation_constraints_blocked',
    },
  };
}

double? _estimateBrl(Object? priceUsd, Object? priceUsdFoil) {
  final prices = [priceUsd, priceUsdFoil]
      .map(
        (value) => switch (value) {
          num() => value.toDouble(),
          String() => double.tryParse(value.trim()),
          _ => null,
        },
      )
      .whereType<double>()
      .where((value) => value > 0)
      .toList(growable: false);
  if (prices.isEmpty) return null;
  return _money(
    prices.reduce((a, b) => a < b ? a : b) * aiGenerateUsdToBrlRate,
  );
}

double _money(double value) => double.parse(value.toStringAsFixed(2));
