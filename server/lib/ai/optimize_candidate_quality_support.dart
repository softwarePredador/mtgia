import 'package:postgres/postgres.dart';

import '../logger.dart';
import 'aggressive_candidate_meta_signal_support.dart';

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
  final minimumBracket = candidateBracketScopeMinimum(bracketScope);
  if (minimumBracket == null || bracket >= minimumBracket) return 0;
  return minimumBracket >= 3 ? 140 : 80;
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
  final bracketPenalty = _aggressiveBracketScopePenalty(
    signal.bracketScope,
    bracket,
  );
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
  final ranked =
      pairs.map((pair) {
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
    final bucket =
        normalized.contains('dados incompletos')
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
      final roles =
          ((row[1] as List?) ?? const <Object?>[])
              .map((role) => role.toString())
              .where((role) => role.trim().isNotEmpty)
              .toSet();
      final sources =
          ((row[9] as List?) ?? const <Object?>[])
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
    Log.w(
      'Aggressive candidate quality signals unavailable type=${e.runtimeType}',
    );
    return const <String, AggressiveCandidateQualitySignal>{};
  }
}
