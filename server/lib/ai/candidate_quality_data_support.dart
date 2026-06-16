import 'commander_fallback_policy.dart';
import 'functional_card_tags.dart';
import 'optimization_functional_roles.dart';
import 'optimize_runtime_support.dart';

const candidateQualitySchemaVersion = 'aggressive_candidate_quality_v2_stage1';

const candidateQualityAllowedTags = <String>{
  'land',
  'ramp',
  'ritual',
  'draw',
  'loot',
  'removal',
  'board_wipe',
  'protection',
  'tutor',
  'wincon',
  'combo_piece',
  'mana_fixing',
  'graveyard',
  'graveyard_synergy',
  'token',
  'token_maker',
  'aristocrats',
  'aristocrat_payoff',
  'counterspell',
  'stax',
  'sacrifice',
  'sacrifice_outlet',
  'recursion',
  'lifegain',
  'drain',
  'spellslinger',
  'artifact_synergy',
  'enchantment_synergy',
  'etb',
  'blink',
  'big_spell',
  'exile_value',
  'engine',
  'payoff',
  'enabler',
};

const candidateQualitySchemaStatements = <String>[
  '''
CREATE TABLE IF NOT EXISTS card_function_tags (
  card_id UUID NOT NULL REFERENCES cards(id) ON DELETE CASCADE,
  card_name TEXT NOT NULL,
  tag TEXT NOT NULL,
  confidence NUMERIC(4,3) NOT NULL CHECK (confidence >= 0 AND confidence <= 1),
  source TEXT NOT NULL,
  evidence TEXT,
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (card_id, tag, source)
)
''',
  '''
CREATE TABLE IF NOT EXISTS card_role_scores (
  card_id UUID NOT NULL REFERENCES cards(id) ON DELETE CASCADE,
  card_name TEXT NOT NULL,
  role TEXT NOT NULL,
  score INTEGER NOT NULL CHECK (score BETWEEN 0 AND 100),
  format TEXT NOT NULL DEFAULT 'commander',
  subformat TEXT NOT NULL DEFAULT 'any',
  bracket_scope TEXT NOT NULL DEFAULT 'any',
  budget_tier TEXT NOT NULL DEFAULT 'unknown',
  source TEXT NOT NULL,
  evidence TEXT,
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (card_id, role, format, subformat, bracket_scope, source)
)
''',
  '''
CREATE TABLE IF NOT EXISTS commander_card_synergy (
  commander_name_normalized TEXT NOT NULL,
  commander_name TEXT NOT NULL,
  card_id UUID NOT NULL REFERENCES cards(id) ON DELETE CASCADE,
  card_name TEXT NOT NULL,
  role TEXT NOT NULL,
  score INTEGER NOT NULL CHECK (score BETWEEN 0 AND 100),
  source TEXT NOT NULL,
  evidence_count INTEGER NOT NULL DEFAULT 0 CHECK (evidence_count >= 0),
  evidence TEXT,
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (commander_name_normalized, card_id, role, source)
)
''',
  '''
CREATE TABLE IF NOT EXISTS optimize_rejection_penalties (
  card_name_normalized TEXT NOT NULL,
  card_name TEXT NOT NULL,
  commander_name_normalized TEXT NOT NULL DEFAULT '',
  commander_name TEXT NOT NULL DEFAULT '',
  archetype TEXT NOT NULL DEFAULT '',
  function TEXT NOT NULL DEFAULT '',
  penalty INTEGER NOT NULL CHECK (penalty BETWEEN 0 AND 1000),
  reject_count INTEGER NOT NULL DEFAULT 0 CHECK (reject_count >= 0),
  source TEXT NOT NULL,
  evidence TEXT,
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (
    card_name_normalized,
    commander_name_normalized,
    archetype,
    function,
    source
  )
)
''',
  '''
CREATE TABLE IF NOT EXISTS card_semantic_tags_v2 (
  card_id UUID NOT NULL REFERENCES cards(id) ON DELETE CASCADE,
  card_name TEXT NOT NULL,
  schema_version TEXT NOT NULL,
  speed TEXT NOT NULL DEFAULT 'unknown',
  mana_efficiency TEXT NOT NULL DEFAULT 'unknown',
  card_advantage_type TEXT NOT NULL DEFAULT 'none',
  interaction_scope TEXT NOT NULL DEFAULT 'none',
  combo_piece BOOLEAN NOT NULL DEFAULT false,
  wincon BOOLEAN NOT NULL DEFAULT false,
  engine BOOLEAN NOT NULL DEFAULT false,
  payoff BOOLEAN NOT NULL DEFAULT false,
  enabler BOOLEAN NOT NULL DEFAULT false,
  protection_type TEXT NOT NULL DEFAULT 'none',
  recursion_type TEXT NOT NULL DEFAULT 'none',
  role_confidence NUMERIC(4,3) NOT NULL CHECK (
    role_confidence >= 0 AND role_confidence <= 1
  ),
  explanation_reason TEXT NOT NULL,
  tags JSONB NOT NULL DEFAULT '[]'::jsonb,
  source TEXT NOT NULL,
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (card_id, source)
)
''',
];

const candidateQualityIndexStatements = <String>[
  '''
CREATE INDEX IF NOT EXISTS idx_card_function_tags_tag
ON card_function_tags (tag, confidence DESC)
''',
  '''
CREATE INDEX IF NOT EXISTS idx_card_function_tags_card_name
ON card_function_tags (LOWER(card_name))
''',
  '''
CREATE INDEX IF NOT EXISTS idx_card_role_scores_lookup
ON card_role_scores (role, format, subformat, bracket_scope, score DESC)
''',
  '''
CREATE INDEX IF NOT EXISTS idx_card_role_scores_budget
ON card_role_scores (budget_tier, score DESC)
''',
  '''
CREATE INDEX IF NOT EXISTS idx_commander_card_synergy_lookup
ON commander_card_synergy (
  commander_name_normalized,
  role,
  score DESC,
  evidence_count DESC
)
''',
  '''
CREATE INDEX IF NOT EXISTS idx_optimize_rejection_penalties_lookup
ON optimize_rejection_penalties (
  commander_name_normalized,
  archetype,
  function,
  penalty DESC
)
''',
  '''
CREATE INDEX IF NOT EXISTS idx_card_semantic_tags_v2_flags
ON card_semantic_tags_v2 (
  wincon,
  combo_piece,
  engine,
  payoff,
  enabler,
  role_confidence DESC
)
''',
  '''
CREATE INDEX IF NOT EXISTS idx_card_semantic_tags_v2_card_name
ON card_semantic_tags_v2 (LOWER(card_name))
''',
];

const optimizeCandidateQualitySummaryViewStatement = '''
CREATE OR REPLACE VIEW optimize_candidate_quality_summary AS
WITH meta_insights AS (
  SELECT
    LOWER(card_name) AS normalized_card_name,
    MAX(usage_count)::int AS usage_count,
    MAX(meta_deck_count)::int AS meta_deck_count
  FROM card_meta_insights
  GROUP BY LOWER(card_name)
),
function_tags AS (
  SELECT
    card_id,
    ARRAY_REMOVE(ARRAY_AGG(DISTINCT tag ORDER BY tag), NULL)
      AS function_tags
  FROM card_function_tags
  GROUP BY card_id
),
role_scores AS (
  SELECT
    card_id,
    MAX(score)::int AS best_role_score,
    ARRAY_REMOVE(ARRAY_AGG(DISTINCT role ORDER BY role), NULL)
      AS scored_roles
  FROM card_role_scores
  GROUP BY card_id
),
semantic_v2 AS (
  SELECT
    card_id,
    jsonb_agg(jsonb_build_object(
      'schema_version', schema_version,
      'source', source,
      'speed', speed,
      'mana_efficiency', mana_efficiency,
      'card_advantage_type', card_advantage_type,
      'interaction_scope', interaction_scope,
      'combo_piece', combo_piece,
      'wincon', wincon,
      'engine', engine,
      'payoff', payoff,
      'enabler', enabler,
      'protection_type', protection_type,
      'recursion_type', recursion_type,
      'role_confidence', role_confidence,
      'explanation_reason', explanation_reason,
      'tags', tags
    ) ORDER BY role_confidence DESC, source) AS semantic_tags_v2
  FROM card_semantic_tags_v2
  GROUP BY card_id
)
SELECT
  c.id AS card_id,
  c.name AS card_name,
  c.type_line,
  c.mana_cost,
  c.oracle_text,
  c.colors,
  c.color_identity,
  c.cmc,
  c.price_usd,
  c.price_usd_foil,
  c.set_code,
  COALESCE(cmi.usage_count, 0) AS meta_usage_count,
  COALESCE(cmi.meta_deck_count, 0) AS meta_deck_count,
  COALESCE(ft.function_tags, ARRAY[]::TEXT[]) AS function_tags,
  COALESCE(rs.best_role_score, 0)::int AS best_role_score,
  COALESCE(rs.scored_roles, ARRAY[]::TEXT[]) AS scored_roles,
  COALESCE(sv2.semantic_tags_v2, '[]'::jsonb) AS semantic_tags_v2
FROM cards c
LEFT JOIN meta_insights cmi ON cmi.normalized_card_name = LOWER(c.name)
LEFT JOIN function_tags ft ON ft.card_id = c.id
LEFT JOIN role_scores rs ON rs.card_id = c.id
LEFT JOIN semantic_v2 sv2 ON sv2.card_id = c.id
''';

const cardIntelligenceSnapshotViewStatement = '''
CREATE OR REPLACE VIEW card_intelligence_snapshot AS
WITH function_tags AS (
  SELECT
    card_id,
    ARRAY_REMOVE(ARRAY_AGG(DISTINCT tag ORDER BY tag), NULL) AS function_tags,
    jsonb_agg(jsonb_build_object(
      'tag', tag,
      'confidence', confidence,
      'source', source,
      'evidence', evidence,
      'updated_at', updated_at
    ) ORDER BY confidence DESC, tag, source) AS function_tag_details,
    MAX(confidence) AS max_function_tag_confidence
  FROM card_function_tags
  GROUP BY card_id
),
role_scores AS (
  SELECT
    card_id,
    MAX(score)::int AS best_role_score,
    ARRAY_REMOVE(ARRAY_AGG(DISTINCT role ORDER BY role), NULL) AS scored_roles,
    jsonb_agg(jsonb_build_object(
      'role', role,
      'score', score,
      'format', format,
      'subformat', subformat,
      'bracket_scope', bracket_scope,
      'budget_tier', budget_tier,
      'source', source,
      'evidence', evidence,
      'updated_at', updated_at
    ) ORDER BY score DESC, role, source) AS role_score_details
  FROM card_role_scores
  GROUP BY card_id
),
commander_synergy AS (
  SELECT
    card_id,
    COUNT(*)::int AS commander_synergy_rows,
    MAX(score)::int AS best_commander_synergy_score,
    jsonb_agg(jsonb_build_object(
      'commander_name', commander_name,
      'commander_name_normalized', commander_name_normalized,
      'role', role,
      'score', score,
      'source', source,
      'evidence_count', evidence_count,
      'evidence', evidence,
      'updated_at', updated_at
    ) ORDER BY score DESC, evidence_count DESC, commander_name_normalized, role)
      AS commander_synergy_details
  FROM commander_card_synergy
  GROUP BY card_id
),
semantic_v2 AS (
  SELECT
    card_id,
    jsonb_agg(jsonb_build_object(
      'schema_version', schema_version,
      'source', source,
      'speed', speed,
      'mana_efficiency', mana_efficiency,
      'card_advantage_type', card_advantage_type,
      'interaction_scope', interaction_scope,
      'combo_piece', combo_piece,
      'wincon', wincon,
      'engine', engine,
      'payoff', payoff,
      'enabler', enabler,
      'protection_type', protection_type,
      'recursion_type', recursion_type,
      'role_confidence', role_confidence,
      'explanation_reason', explanation_reason,
      'tags', tags,
      'updated_at', updated_at
    ) ORDER BY role_confidence DESC, source) AS semantic_tags_v2,
    MAX(role_confidence) AS max_semantic_confidence
  FROM card_semantic_tags_v2
  GROUP BY card_id
),
battle_rules AS (
  SELECT
    card_id,
    COUNT(*)::int AS battle_rule_count,
    (COUNT(*) FILTER (WHERE review_status = 'verified'))::int
      AS verified_battle_rule_count,
    jsonb_agg(jsonb_build_object(
      'source', source,
      'confidence', confidence,
      'review_status', review_status,
      'rule_version', rule_version,
      'effect', effect_json,
      'deck_role', deck_role_json,
      'notes', notes,
      'updated_at', updated_at
    ) ORDER BY (review_status = 'verified') DESC, confidence DESC, source)
      AS battle_rules,
    jsonb_agg(jsonb_build_object(
      'source', source,
      'confidence', confidence,
      'review_status', review_status,
      'rule_version', rule_version,
      'effect', effect_json,
      'deck_role', deck_role_json,
      'notes', notes,
      'updated_at', updated_at
    ) ORDER BY confidence DESC, source)
      FILTER (WHERE review_status = 'verified') AS verified_battle_rules
  FROM card_battle_rules
  WHERE card_id IS NOT NULL
  GROUP BY card_id
),
legalities AS (
  SELECT
    card_id,
    jsonb_object_agg(format, status ORDER BY format) AS legalities
  FROM card_legalities
  GROUP BY card_id
),
rulings AS (
  SELECT
    oracle_id,
    COUNT(*)::int AS ruling_count,
    MAX(published_at) AS latest_ruling_at
  FROM card_rulings
  GROUP BY oracle_id
)
SELECT
  c.id AS id,
  c.id AS card_id,
  c.oracle_id,
  c.scryfall_id,
  c.name AS name,
  c.name AS card_name,
  LOWER(TRIM(c.name)) AS normalized_card_name,
  c.mana_cost,
  c.type_line,
  c.oracle_text,
  c.colors,
  c.color_identity,
  c.cmc,
  c.image_url,
  c.price_usd,
  c.price_usd_foil,
  c.set_code,
  c.collector_number,
  c.rarity,
  c.keywords,
  COALESCE(l.legalities, '{}'::jsonb) AS legalities,
  COALESCE(ft.function_tags, ARRAY[]::TEXT[]) AS function_tags,
  COALESCE(ft.function_tag_details, '[]'::jsonb) AS function_tag_details,
  ft.max_function_tag_confidence,
  COALESCE(rs.best_role_score, 0) AS best_role_score,
  COALESCE(rs.scored_roles, ARRAY[]::TEXT[]) AS scored_roles,
  COALESCE(rs.role_score_details, '[]'::jsonb) AS role_score_details,
  COALESCE(cs.commander_synergy_rows, 0) AS commander_synergy_rows,
  COALESCE(cs.best_commander_synergy_score, 0)
    AS best_commander_synergy_score,
  COALESCE(cs.commander_synergy_details, '[]'::jsonb)
    AS commander_synergy_details,
  COALESCE(sv2.semantic_tags_v2, '[]'::jsonb) AS semantic_tags_v2,
  sv2.max_semantic_confidence,
  COALESCE(br.battle_rules, '[]'::jsonb) AS battle_rules,
  COALESCE(br.verified_battle_rules, '[]'::jsonb) AS verified_battle_rules,
  COALESCE(br.battle_rule_count, 0) AS battle_rule_count,
  COALESCE(br.verified_battle_rule_count, 0) AS verified_battle_rule_count,
  COALESCE(ru.ruling_count, 0) AS ruling_count,
  ru.latest_ruling_at,
  jsonb_build_object(
    'has_legalities', l.card_id IS NOT NULL,
    'has_function_tags', ft.card_id IS NOT NULL,
    'has_role_scores', rs.card_id IS NOT NULL,
    'has_commander_synergy', cs.card_id IS NOT NULL,
    'has_semantic_v2', sv2.card_id IS NOT NULL,
    'has_verified_battle_rules',
      COALESCE(br.verified_battle_rule_count, 0) > 0,
    'has_any_battle_rules', COALESCE(br.battle_rule_count, 0) > 0,
    'has_rulings', COALESCE(ru.ruling_count, 0) > 0
  ) AS source_coverage
FROM cards c
LEFT JOIN legalities l ON l.card_id = c.id
LEFT JOIN function_tags ft ON ft.card_id = c.id
LEFT JOIN role_scores rs ON rs.card_id = c.id
LEFT JOIN commander_synergy cs ON cs.card_id = c.id
LEFT JOIN semantic_v2 sv2 ON sv2.card_id = c.id
LEFT JOIN battle_rules br ON br.card_id = c.id
LEFT JOIN rulings ru ON ru.oracle_id = c.oracle_id::text
''';

class CandidateFunctionTag {
  const CandidateFunctionTag({
    required this.tag,
    required this.confidence,
    required this.evidence,
  });

  final String tag;
  final double confidence;
  final String evidence;
}

class CandidateRoleScore {
  const CandidateRoleScore({
    required this.role,
    required this.score,
    required this.bracketScope,
    required this.budgetTier,
    required this.evidence,
  });

  final String role;
  final int score;
  final String bracketScope;
  final String budgetTier;
  final String evidence;
}

String normalizeCandidateQualityKey(String value) {
  return value.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
}

String normalizeCandidateQualityRole(String tag) {
  return switch (tag) {
    'board_wipe' => 'wipe',
    'counterspell' => 'removal',
    'mana_fixing' => 'ramp',
    'ritual' => 'ramp',
    'combo_piece' => 'combo_piece',
    'token_maker' => 'token',
    'aristocrat_payoff' => 'aristocrats',
    'sacrifice_outlet' => 'sacrifice',
    'graveyard_synergy' => 'graveyard',
    'blink' => 'protection',
    'exile_value' => 'draw',
    'drain' => 'wincon',
    'lifegain' => 'protection',
    'engine' => 'engine',
    'payoff' => 'payoff',
    'enabler' => 'enabler',
    _ => tag,
  };
}

List<CandidateFunctionTag> inferCandidateFunctionTags({
  required String name,
  required String typeLine,
  required String oracleText,
  String? manaCost,
}) {
  final normalizedName = normalizeCandidateQualityKey(name);
  final type = typeLine.toLowerCase();
  final oracle = oracleText.toLowerCase();
  final tags = <String, CandidateFunctionTag>{};

  void add(String tag, double confidence, String evidence) {
    if (!candidateQualityAllowedTags.contains(tag)) return;
    final current = tags[tag];
    if (current == null || confidence > current.confidence) {
      tags[tag] = CandidateFunctionTag(
        tag: tag,
        confidence: confidence.clamp(0, 1).toDouble(),
        evidence: evidence,
      );
    }
  }

  for (final inferred in inferFunctionalCardTags(
    name: name,
    typeLine: typeLine,
    oracleText: oracleText,
    manaCost: manaCost,
  )) {
    add(inferred.tag, inferred.confidence, inferred.evidence);
    switch (inferred.tag) {
      case 'token_maker':
        add('token', inferred.confidence, '${inferred.evidence};alias=v1');
        break;
      case 'aristocrat_payoff':
        add('aristocrats', inferred.confidence,
            '${inferred.evidence};alias=v1');
        break;
      case 'graveyard_synergy':
        add('graveyard', inferred.confidence, '${inferred.evidence};alias=v1');
        break;
      case 'sacrifice_outlet':
        add('sacrifice', inferred.confidence, '${inferred.evidence};alias=v1');
        break;
      case 'ritual':
        add('ramp', 0.72, '${inferred.evidence};alias=v1');
        break;
      case 'blink':
        add('protection', 0.68, '${inferred.evidence};alias=v1');
        break;
      case 'exile_value':
        add('draw', 0.64, '${inferred.evidence};alias=v1');
        break;
    }
  }

  if (type.contains('land') &&
      (oracle.contains('add ') ||
          oracle.contains('any color') ||
          oracle.contains('mana'))) {
    add('mana_fixing', 0.82, 'land_mana_text');
  }

  if (looksLikeOptimizationRampText(oracleText) ||
      normalizedName.contains('signet') ||
      normalizedName.contains('talisman') ||
      normalizedName == 'sol ring') {
    add('ramp', 0.86, 'mana_or_land_ramp_text');
  }

  if (oracle.contains('add one mana of any color') ||
      oracle.contains('add one mana of any type') ||
      oracle.contains('mana of any color') ||
      oracle.contains('commander\'s color identity') ||
      (oracle.contains('commander') && oracle.contains('color identity'))) {
    add('mana_fixing', 0.9, 'any_color_or_commander_identity_mana');
  }

  if (oracle.contains('draw a card') ||
      oracle.contains('draw two cards') ||
      oracle.contains('draw three cards') ||
      oracle.contains('draw cards') ||
      oracle.contains('draw x cards')) {
    add('draw', 0.84, 'draw_text');
  }

  if (oracle.contains('destroy target') ||
      oracle.contains('exile target') ||
      oracle.contains('return target') && oracle.contains('to its owner') ||
      oracle.contains('deals') &&
          oracle.contains('damage') &&
          oracle.contains('target')) {
    add('removal', 0.82, 'targeted_interaction_text');
  }

  if (oracle.contains('counter target')) {
    add('counterspell', 0.9, 'counter_target_text');
    add('removal', 0.72, 'counterspell_is_interaction');
  }

  if (looksLikeOptimizationBoardWipeText(oracleText)) {
    add('board_wipe', 0.9, 'mass_removal_text');
  }

  if (oracle.contains('search your library') &&
      !looksLikeOptimizationLandSearchText(oracle)) {
    add('tutor', 0.86, 'non_land_library_search');
  }

  if (oracle.contains('hexproof') ||
      oracle.contains('indestructible') ||
      oracle.contains('shroud') ||
      oracle.contains('ward') ||
      oracle.contains('phase out') ||
      normalizedName.contains('greaves') ||
      normalizedName.contains('boots')) {
    add('protection', 0.82, 'protection_keyword_or_equipment');
  }

  if (oracle.contains('you win the game') ||
      oracle.contains('each opponent loses') ||
      oracle.contains('loses the game') ||
      oracle.contains('deal damage equal to') ||
      oracle.contains('double your life total')) {
    add('wincon', 0.76, 'explicit_win_or_finisher_text');
  }

  if (oracle.contains('infinite') ||
      oracle.contains('untap') && oracle.contains('add ') ||
      oracle.contains('copy target activated or triggered ability') ||
      normalizedName.contains('thassa') && normalizedName.contains('oracle') ||
      normalizedName.contains('dramatic reversal') ||
      normalizedName.contains('isochron scepter')) {
    // Baixa confiança: a fonte real de combo_piece é card_function_tags
    // persistida pelo sync do Commander Spellbook.
    add('combo_piece', 0.60, 'combo_pattern_text_or_known_name');
  }

  if (oracle.contains('graveyard') ||
      oracle.contains('from your graveyard') ||
      oracle.contains('return target creature card') ||
      oracle.contains('mill')) {
    add('graveyard', 0.72, 'graveyard_text');
  }

  if (oracle.contains('return') &&
      oracle.contains('from your graveyard') &&
      (oracle.contains('to your hand') || oracle.contains('battlefield'))) {
    add('recursion', 0.86, 'graveyard_return_text');
  }

  if (oracle.contains('create') && oracle.contains('token') ||
      oracle.contains('populate')) {
    add('token', 0.82, 'token_creation_text');
  }

  if (oracle.contains('sacrifice') ||
      oracle.contains('dies') ||
      oracle.contains('whenever another creature dies')) {
    add('sacrifice', 0.72, 'sacrifice_or_death_trigger_text');
  }

  if (oracle.contains('whenever') &&
          oracle.contains('creature') &&
          oracle.contains('dies') ||
      normalizedName.contains('blood artist') ||
      normalizedName.contains('zulaport cutthroat') ||
      oracle.contains('each opponent loses') && oracle.contains('gain')) {
    add('aristocrats', 0.8, 'aristocrats_death_drain_text');
  }

  if (oracle.contains('players can\'t') ||
      oracle.contains('opponents can\'t') ||
      oracle.contains('spells cost') && oracle.contains('more to cast')) {
    add('stax', 0.74, 'restriction_or_tax_text');
  }

  final ordered = tags.values.toList()
    ..sort((a, b) {
      final byConfidence = b.confidence.compareTo(a.confidence);
      if (byConfidence != 0) return byConfidence;
      return a.tag.compareTo(b.tag);
    });
  return ordered;
}

List<CandidateRoleScore> buildCandidateRoleScores({
  required String name,
  required String typeLine,
  required String oracleText,
  String? manaCost,
  Object? priceUsd,
  Object? priceUsdFoil,
  Object? cmc,
  int metaUsageCount = 0,
  int metaDeckCount = 0,
  double edhrecInclusionRate = 0,
  int edhrecSampleDecks = 0,
}) {
  final tags = inferCandidateFunctionTags(
    name: name,
    typeLine: typeLine,
    oracleText: oracleText,
    manaCost: manaCost,
  );
  if (tags.isEmpty) return const <CandidateRoleScore>[];

  final budgetTier = inferCandidateBudgetTier(
    priceUsd: priceUsd,
    priceUsdFoil: priceUsdFoil,
  );
  final estimatedCmc = safeToDouble(cmc, _estimateManaCostCmc(manaCost ?? ''));
  final normalizedEdhrecRate =
      _normalizeEdhrecInclusionRate(edhrecInclusionRate);
  final edhrecInclusionBonus =
      (normalizedEdhrecRate * 18).round().clamp(0, 18).toInt();
  final edhrecSampleBonus = _edhrecSampleBonus(edhrecSampleDecks);
  final roleBest = <String, CandidateRoleScore>{};
  for (final tag in tags) {
    final role = normalizeCandidateQualityRole(tag.tag);
    final popularityBonus = (metaDeckCount * 3 +
            metaUsageCount ~/ 12 +
            edhrecInclusionBonus +
            edhrecSampleBonus)
        .clamp(0, 30)
        .toInt();
    final curvePenalty = estimatedCmc >= 7
        ? 16
        : estimatedCmc >= 6
            ? 9
            : 0;
    final confidenceScore = (tag.confidence * 72).round();
    final premiumBonus = isPremiumCommanderCandidateName(name) ||
            metaDeckCount >= 12 ||
            (normalizedEdhrecRate >= 0.35 && edhrecSampleDecks >= 1000)
        ? 8
        : 0;
    final score =
        (confidenceScore + popularityBonus + premiumBonus - curvePenalty)
            .clamp(1, 100)
            .toInt();
    final bracketScope = inferCandidateBracketScope(
      name: name,
      role: role,
      score: score,
      budgetTier: budgetTier,
    );
    final candidate = CandidateRoleScore(
      role: role,
      score: score,
      bracketScope: bracketScope,
      budgetTier: budgetTier,
      evidence: _withEdhrecEvidence(
        baseEvidence: tag.evidence,
        inclusionRate: normalizedEdhrecRate,
        sampleDecks: edhrecSampleDecks,
      ),
    );
    final current = roleBest[role];
    if (current == null || candidate.score > current.score) {
      roleBest[role] = candidate;
    }
  }

  final output = roleBest.values.toList()
    ..sort((a, b) {
      final byScore = b.score.compareTo(a.score);
      if (byScore != 0) return byScore;
      return a.role.compareTo(b.role);
    });
  return output;
}

double _normalizeEdhrecInclusionRate(double value) {
  if (!value.isFinite || value <= 0) return 0;
  if (value <= 1) return value;
  if (value <= 100) return value / 100;
  return 1;
}

int _edhrecSampleBonus(int sampleDecks) {
  if (sampleDecks >= 5000) return 6;
  if (sampleDecks >= 1000) return 4;
  if (sampleDecks >= 250) return 2;
  if (sampleDecks > 0) return 1;
  return 0;
}

String _withEdhrecEvidence({
  required String baseEvidence,
  required double inclusionRate,
  required int sampleDecks,
}) {
  if (inclusionRate <= 0 && sampleDecks <= 0) return baseEvidence;
  return [
    baseEvidence,
    'edhrec_inclusion_rate=${inclusionRate.toStringAsFixed(3)}',
    'edhrec_sample_decks=$sampleDecks',
  ].join(';');
}

String inferCandidateBudgetTier({
  required Object? priceUsd,
  required Object? priceUsdFoil,
}) {
  final regular = safeToDouble(priceUsd, -1);
  final foil = safeToDouble(priceUsdFoil, -1);
  final knownPrices = [
    if (regular >= 0) regular,
    if (foil >= 0) foil,
  ];
  if (knownPrices.isEmpty) return 'unknown';
  final price = knownPrices.reduce((a, b) => a < b ? a : b);
  if (price <= 1) return 'budget';
  if (price <= 10) return 'accessible';
  if (price <= 50) return 'premium';
  return 'expensive';
}

String inferCandidateBracketScope({
  required String name,
  required String role,
  required int score,
  required String budgetTier,
}) {
  final normalizedName = normalizeCandidateQualityKey(name);

  if (candidateQualityHighPowerNames.contains(normalizedName) ||
      budgetTier == 'expensive' ||
      role == 'combo_piece' && score >= 60) {
    return 'bracket_3_4';
  }
  if (score >= 78) return 'bracket_2_4';
  return 'any';
}

bool isPremiumCommanderCandidateName(String name) {
  return candidateQualityPremiumNames
      .contains(normalizeCandidateQualityKey(name));
}

double _estimateManaCostCmc(String manaCost) {
  if (manaCost.trim().isEmpty) return 0;
  var total = 0.0;
  for (final match in RegExp(r'\{([^}]+)\}').allMatches(manaCost)) {
    final symbol = (match.group(1) ?? '').trim().toUpperCase();
    if (symbol.isEmpty || symbol == 'X') continue;
    final numeric = int.tryParse(symbol);
    total += numeric ?? 1;
  }
  return total;
}

Set<String> resolveCandidateQualityIdentity({
  required Object? colorIdentity,
  required Object? colors,
  required String oracleText,
  required String manaCost,
}) {
  return resolvedCardIdentityFromParts(
    colorIdentity: colorIdentity is List
        ? colorIdentity.map((e) => e.toString()).toList(growable: false)
        : const <String>[],
    colors: colors is List
        ? colors.map((e) => e.toString()).toList(growable: false)
        : const <String>[],
    oracleText: oracleText,
    manaCost: manaCost,
  );
}
