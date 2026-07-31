import 'package:postgres/postgres.dart';

import '../ai/optimize_functional_role_support.dart';
import '../ai/optimize_swap_integrity.dart';

class OptimizationFunctionalRoleFloorViolation implements Exception {
  const OptimizationFunctionalRoleFloorViolation({
    required this.reason,
    this.assessment,
  });

  final String reason;
  final CommanderFunctionalRoleFloorAssessment? assessment;

  Map<String, dynamic> get responseBody {
    final policy = assessment?.toJson();
    return {
      'error_code': 'optimization_functional_role_floor_violation',
      'error':
          'Aplicação bloqueada: a seleção deixaria o deck abaixo das '
          'funções estruturais mínimas.',
      'quality_error': {
        'code': 'OPTIMIZATION_APPLY_FUNCTIONAL_ROLE_FLOOR',
        'message':
            'Revise a seleção e preserve o piso estrutural indicado '
            'pela análise.',
        'reason': reason,
        if (policy != null) 'functional_role_policy': policy,
      },
      if (policy != null) 'functional_role_policy': policy,
      'can_apply': false,
      'learning_eligible': false,
      'apply_blockers': const ['commander_functional_role_floor_not_met'],
    };
  }

  @override
  String toString() =>
      'OptimizationFunctionalRoleFloorViolation('
      'reason=$reason, assessment=${assessment?.toJson()})';
}

Future<CommanderFunctionalRoleFloorAssessment?>
assessOptimizationApplyCommanderFunctionalRoleFloor({
  required Session session,
  required String format,
  required Iterable<Map<String, dynamic>> cards,
  required Map<String, dynamic> mutationContext,
  OptimizeApplyAuthorizationVerification? authorizationVerification,
  String? storedArchetype,
}) async {
  if (format.trim().toLowerCase() != 'commander') return null;

  final normalizedCards = cards
      .map((card) => Map<String, dynamic>.from(card))
      .toList(growable: false);
  final cardIds = normalizedCards
      .map((card) => card['card_id']?.toString().trim() ?? '')
      .where((id) => id.isNotEmpty)
      .toSet()
      .toList(growable: false);
  final metadataById = <String, Map<String, dynamic>>{};

  if (cardIds.isNotEmpty) {
    final rows = await session.execute(
      Sql.named('''
        SELECT c.id::text, c.name, c.type_line, c.oracle_text, c.mana_cost,
               c.cmc, cis.function_tag_details, cis.semantic_tags_v2
        FROM cards c
        LEFT JOIN card_intelligence_snapshot cis ON cis.card_id = c.id
        WHERE c.id = ANY(@cardIds)
      '''),
      parameters: {'cardIds': cardIds},
    );
    for (final row in rows) {
      metadataById[row[0].toString()] = {
        'name': row[1]?.toString() ?? '',
        'type_line': row[2]?.toString() ?? '',
        'oracle_text': row[3]?.toString() ?? '',
        'mana_cost': row[4]?.toString() ?? '',
        'cmc': row[5],
        'functional_tags': row[6],
        'semantic_tags_v2': row[7],
      };
    }
  }

  return assessOptimizationApplyCommanderFunctionalRoleFloorFromCards(
    format: format,
    cards: [
      for (final card in normalizedCards)
        {
          ...card,
          ...?metadataById[card['card_id']?.toString() ?? ''],
          'quantity': card['quantity'] ?? 1,
        },
    ],
    mutationContext: mutationContext,
    authorizationVerification: authorizationVerification,
    storedArchetype: storedArchetype,
  );
}

CommanderFunctionalRoleFloorAssessment?
assessOptimizationApplyCommanderFunctionalRoleFloorFromCards({
  required String format,
  required Iterable<Map<String, dynamic>> cards,
  required Map<String, dynamic> mutationContext,
  OptimizeApplyAuthorizationVerification? authorizationVerification,
  String? storedArchetype,
}) {
  if (format.trim().toLowerCase() != 'commander') return null;

  final payload = authorizationVerification?.payload;
  final rawSignedPolicy =
      payload?['functional_role_policy'] is Map
          ? (payload!['functional_role_policy'] as Map).cast<String, dynamic>()
          : null;
  final authorizedMode =
      payload?['mode']?.toString().trim().toLowerCase() ?? '';
  final hasAuthorizedRemovals =
      payload?['removals'] is Map && (payload!['removals'] as Map).isNotEmpty;
  final requiresSignedPolicy =
      authorizationVerification != null &&
      (authorizedMode == 'optimize' || hasAuthorizedRemovals);
  final authorizedBracket = _readInt(payload?['bracket']);

  if (requiresSignedPolicy &&
      !_isValidSatisfiedSignedPolicy(
        rawSignedPolicy,
        expectedBracket: authorizedBracket,
      )) {
    throw const OptimizationFunctionalRoleFloorViolation(
      reason: 'functional_role_policy_binding_missing',
    );
  }

  final materialized = cards.toList(growable: false);
  final signedMinimumCounts = _readRoleCountMap(
    rawSignedPolicy?['minimum_counts'],
  );
  final fallbackArchetype =
      (storedArchetype?.trim().isNotEmpty == true
              ? storedArchetype!
              : mutationContext['archetype']?.toString() ?? 'midrange')
          .trim()
          .toLowerCase();
  final archetype =
      rawSignedPolicy?['archetype']?.toString().trim().toLowerCase() ??
      fallbackArchetype;
  final bracket = _readInt(
    rawSignedPolicy?['bracket'] ?? mutationContext['bracket'],
  );
  final minimumCounts =
      signedMinimumCounts.isNotEmpty
          ? signedMinimumCounts
          : commanderFunctionalRoleMinimumCounts(
            targetArchetype: archetype.isEmpty ? 'midrange' : archetype,
            bracket: bracket,
          );
  final totalCards = materialized.fold<int>(
    0,
    (sum, card) => sum + _positiveQuantity(card['quantity']),
  );
  final actualCounts = <String, int>{
    for (final role in minimumCounts.keys)
      role: countOptimizationFunctionalRole(materialized, role: role),
  };

  return CommanderFunctionalRoleFloorAssessment(
    archetype: archetype.isEmpty ? 'midrange' : archetype,
    bracket: bracket,
    totalCards: totalCards,
    minimumCounts: minimumCounts,
    actualCounts: actualCounts,
  );
}

bool _isValidSatisfiedSignedPolicy(
  Map<String, dynamic>? policy, {
  required int? expectedBracket,
}) {
  final policyBracket = _readInt(policy?['bracket']);
  final archetype = policy?['archetype']?.toString().trim().toLowerCase() ?? '';
  if (policy == null ||
      policy['policy'] != commanderFunctionalRoleFloorPolicyVersion ||
      archetype.isEmpty ||
      expectedBracket == null ||
      policyBracket != expectedBracket ||
      policy['applies'] != true ||
      policy['satisfied'] != true ||
      (_readInt(policy['total_cards']) ?? 0) < 90) {
    return false;
  }
  final minimumCounts = _readRoleCountMap(policy['minimum_counts']);
  final actualCounts = _readRoleCountMap(policy['actual_counts']);
  final deficits = _readRoleCountMap(policy['deficits']);
  if (!hasCanonicalCommanderFunctionalRoleMinimumCounts(
        counts: minimumCounts,
        targetArchetype: archetype,
        bracket: expectedBracket,
      ) ||
      deficits.isNotEmpty) {
    return false;
  }
  for (final entry in minimumCounts.entries) {
    if ((actualCounts[entry.key] ?? -1) < entry.value) return false;
  }
  return true;
}

Map<String, int> _readRoleCountMap(Object? raw) {
  if (raw is! Map) return const <String, int>{};
  final result = <String, int>{};
  for (final entry in raw.entries) {
    final role = entry.key.toString().trim().toLowerCase();
    final count = _readInt(entry.value);
    if (role.isNotEmpty && count != null && count >= 0) {
      result[role] = count;
    }
  }
  return result;
}

int _positiveQuantity(Object? raw) {
  final quantity = _readInt(raw) ?? 1;
  return quantity > 0 ? quantity : 0;
}

int? _readInt(Object? raw) => switch (raw) {
  int value => value,
  num value => value.toInt(),
  String value => int.tryParse(value.trim()),
  _ => null,
};
