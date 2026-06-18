const commanderLearningSnapshotViewStatement = '''
CREATE OR REPLACE VIEW commander_learning_snapshot AS
WITH active_learned_decks AS (
  SELECT
    commander_name_normalized,
    MAX(commander_name) AS commander_name,
    COUNT(*)::int AS active_learned_deck_count,
    MAX(score) AS best_learned_score,
    MAX(promoted_at) AS latest_promoted_at,
    MAX(updated_at) AS latest_learned_updated_at,
    ARRAY_REMOVE(ARRAY_AGG(DISTINCT legal_status ORDER BY legal_status), NULL)
      AS learned_legal_statuses,
    ARRAY_REMOVE(ARRAY_AGG(DISTINCT archetype ORDER BY archetype), NULL)
      AS learned_archetypes,
    jsonb_agg(jsonb_build_object(
      'deck_name', deck_name,
      'archetype', archetype,
      'card_count', card_count,
      'score', score,
      'legal_status', legal_status,
      'wincon_primary', wincon_primary,
      'wincon_backup', wincon_backup,
      'promoted_at', promoted_at,
      'updated_at', updated_at
    ) ORDER BY score DESC NULLS LAST, promoted_at DESC NULLS LAST, updated_at DESC)
      AS active_learned_decks
  FROM commander_learned_decks
  WHERE is_active = TRUE
  GROUP BY commander_name_normalized
),
bridge_names AS (
  SELECT DISTINCT ON (normalized_lookup_name)
    normalized_lookup_name,
    canonical_name
  FROM card_identity_bridge
  WHERE normalized_lookup_name IS NOT NULL
    AND normalized_lookup_name <> ''
  ORDER BY normalized_lookup_name, (source = 'cards') DESC, match_priority ASC,
    canonical_name ASC
),
usage_ranked AS (
  SELECT
    ccu.commander_name_normalized,
    ccu.card_name_normalized,
    COALESCE(bn.canonical_name, ccu.card_name_normalized)
      AS canonical_card_name,
    ccu.usage_count,
    ccu.last_used_at,
    ROW_NUMBER() OVER (
      PARTITION BY ccu.commander_name_normalized
      ORDER BY ccu.usage_count DESC, ccu.last_used_at DESC, ccu.card_name_normalized
    ) AS rn
  FROM commander_card_usage ccu
  LEFT JOIN bridge_names bn
    ON bn.normalized_lookup_name = ccu.card_name_normalized
),
usage_summary AS (
  SELECT
    commander_name_normalized,
    COUNT(*)::int AS usage_card_rows,
    COALESCE(SUM(usage_count), 0)::int AS total_usage_count,
    jsonb_agg(jsonb_build_object(
      'card_name_normalized', card_name_normalized,
      'canonical_card_name', canonical_card_name,
      'usage_count', usage_count,
      'last_used_at', last_used_at
    ) ORDER BY usage_count DESC, last_used_at DESC, card_name_normalized)
      FILTER (WHERE rn <= 50) AS top_usage_cards
  FROM usage_ranked
  GROUP BY commander_name_normalized
),
synergy_ranked AS (
  SELECT
    ccs.commander_name_normalized,
    ccs.commander_name,
    ccs.card_id,
    ccs.card_name,
    ccs.role,
    ccs.score,
    ccs.source,
    ccs.evidence_count,
    ccs.updated_at,
    ROW_NUMBER() OVER (
      PARTITION BY ccs.commander_name_normalized
      ORDER BY ccs.score DESC, ccs.evidence_count DESC, ccs.card_name, ccs.role
    ) AS rn
  FROM commander_card_synergy ccs
),
synergy_summary AS (
  SELECT
    commander_name_normalized,
    MAX(commander_name) AS commander_name,
    COUNT(*)::int AS synergy_rows,
    MAX(score)::int AS best_synergy_score,
    jsonb_agg(jsonb_build_object(
      'card_id', card_id,
      'card_name', card_name,
      'role', role,
      'score', score,
      'source', source,
      'evidence_count', evidence_count,
      'updated_at', updated_at
    ) ORDER BY score DESC, evidence_count DESC, card_name, role)
      FILTER (WHERE rn <= 50) AS top_synergy_cards
  FROM synergy_ranked
  GROUP BY commander_name_normalized
),
all_commanders AS (
  SELECT commander_name_normalized FROM active_learned_decks
  UNION
  SELECT commander_name_normalized FROM usage_summary
  UNION
  SELECT commander_name_normalized FROM synergy_summary
)
SELECT
  ac.commander_name_normalized,
  COALESCE(ld.commander_name, ss.commander_name, ac.commander_name_normalized)
    AS commander_name,
  COALESCE(ld.active_learned_deck_count, 0) AS active_learned_deck_count,
  ld.best_learned_score,
  ld.latest_promoted_at,
  ld.latest_learned_updated_at,
  COALESCE(ld.learned_legal_statuses, ARRAY[]::TEXT[])
    AS learned_legal_statuses,
  COALESCE(ld.learned_archetypes, ARRAY[]::TEXT[]) AS learned_archetypes,
  COALESCE(ld.active_learned_decks, '[]'::jsonb) AS active_learned_decks,
  COALESCE(us.usage_card_rows, 0) AS usage_card_rows,
  COALESCE(us.total_usage_count, 0) AS total_usage_count,
  COALESCE(us.top_usage_cards, '[]'::jsonb) AS top_usage_cards,
  COALESCE(ss.synergy_rows, 0) AS synergy_rows,
  COALESCE(ss.best_synergy_score, 0) AS best_synergy_score,
  COALESCE(ss.top_synergy_cards, '[]'::jsonb) AS top_synergy_cards,
  jsonb_build_object(
    'has_active_learned_deck', COALESCE(ld.active_learned_deck_count, 0) > 0,
    'has_usage', COALESCE(us.usage_card_rows, 0) > 0,
    'has_synergy', COALESCE(ss.synergy_rows, 0) > 0,
    'metadata_hidden', TRUE
  ) AS source_coverage
FROM all_commanders ac
LEFT JOIN active_learned_decks ld
  ON ld.commander_name_normalized = ac.commander_name_normalized
LEFT JOIN usage_summary us
  ON us.commander_name_normalized = ac.commander_name_normalized
LEFT JOIN synergy_summary ss
  ON ss.commander_name_normalized = ac.commander_name_normalized
''';
