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
];

const optimizeCandidateQualitySummaryViewStatement = '''
CREATE OR REPLACE VIEW optimize_candidate_quality_summary AS
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
  COALESCE(
    ARRAY_REMOVE(ARRAY_AGG(DISTINCT cft.tag), NULL),
    ARRAY[]::TEXT[]
  ) AS function_tags,
  COALESCE(MAX(crs.score), 0)::int AS best_role_score,
  COALESCE(
    ARRAY_REMOVE(ARRAY_AGG(DISTINCT crs.role), NULL),
    ARRAY[]::TEXT[]
  ) AS scored_roles
FROM cards c
LEFT JOIN card_meta_insights cmi ON LOWER(cmi.card_name) = LOWER(c.name)
LEFT JOIN card_function_tags cft ON cft.card_id = c.id
LEFT JOIN card_role_scores crs ON crs.card_id = c.id
GROUP BY
  c.id,
  c.name,
  c.type_line,
  c.mana_cost,
  c.oracle_text,
  c.colors,
  c.color_identity,
  c.cmc,
  c.price_usd,
  c.price_usd_foil,
  c.set_code,
  cmi.usage_count,
  cmi.meta_deck_count
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

  if (oracle.contains('search your library') && !oracle.contains('land card')) {
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
    add('combo_piece', 0.74, 'combo_pattern_text_or_known_name');
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
  final roleBest = <String, CandidateRoleScore>{};
  for (final tag in tags) {
    final role = normalizeCandidateQualityRole(tag.tag);
    final popularityBonus =
        (metaDeckCount * 3 + metaUsageCount ~/ 12).clamp(0, 20).toInt();
    final curvePenalty = estimatedCmc >= 7
        ? 16
        : estimatedCmc >= 6
            ? 9
            : 0;
    final confidenceScore = (tag.confidence * 72).round();
    final premiumBonus =
        isPremiumCommanderCandidateName(name) || metaDeckCount >= 12 ? 8 : 0;
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
      evidence: tag.evidence,
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
  const highPowerNames = {
    'mana crypt',
    'mox diamond',
    'chrome mox',
    'force of will',
    'force of negation',
    'fierce guardianship',
    'vampiric tutor',
    'demonic tutor',
    'thassa\'s oracle',
  };

  if (highPowerNames.contains(normalizedName) ||
      budgetTier == 'expensive' ||
      role == 'combo_piece' && score >= 60) {
    return 'bracket_3_4';
  }
  if (score >= 78) return 'bracket_2_4';
  return 'any';
}

bool isPremiumCommanderCandidateName(String name) {
  const premium = {
    'arcane signet',
    'sol ring',
    'swords to plowshares',
    'path to exile',
    'cyclonic rift',
    'counterspell',
    'rhystic study',
    'lightning greaves',
    'swiftfoot boots',
    'teferi\'s protection',
    'toxic deluge',
    'blasphemous act',
    'beast within',
    'chaos warp',
  };
  return premium.contains(normalizeCandidateQualityKey(name));
}

String buildCandidateQualitySamplePoolSql() {
  return '''
SELECT
  cqs.card_id::text,
  cqs.card_name,
  cqs.function_tags,
  cqs.best_role_score,
  cqs.meta_deck_count
FROM optimize_candidate_quality_summary cqs
JOIN cards c ON c.id = cqs.card_id
LEFT JOIN card_legalities cl
  ON cl.card_id = c.id
  AND cl.format = 'commander'
WHERE (cl.status = 'legal' OR cl.status = 'restricted' OR cl.status IS NULL)
  AND c.type_line NOT ILIKE '%land%'
  AND (
    c.color_identity <@ @identity::text[]
    OR c.color_identity = '{}'
    OR (
      c.color_identity IS NULL
      AND (
        c.colors <@ @identity::text[]
        OR c.colors = '{}'
        OR c.colors IS NULL
      )
    )
  )
  AND @role = ANY(cqs.scored_roles)
ORDER BY cqs.best_role_score DESC, cqs.meta_deck_count DESC, cqs.card_name ASC
LIMIT @limit
''';
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
