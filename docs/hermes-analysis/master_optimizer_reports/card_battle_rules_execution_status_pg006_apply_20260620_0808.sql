\echo 'PG-006 apply - normalize card_battle_rules.execution_status and record migration 029'

BEGIN;

ALTER TABLE card_battle_rules
ADD COLUMN IF NOT EXISTS execution_status TEXT;

CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit;

CREATE TABLE IF NOT EXISTS manaloom_deploy_audit.pg006_card_battle_rules_execution_status_20260620_0808 (
  normalized_name TEXT NOT NULL,
  logical_rule_key TEXT NOT NULL,
  card_id UUID,
  card_name TEXT NOT NULL,
  source TEXT NOT NULL,
  review_status TEXT NOT NULL,
  previous_execution_status TEXT,
  captured_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (normalized_name, logical_rule_key)
);

INSERT INTO manaloom_deploy_audit.pg006_card_battle_rules_execution_status_20260620_0808 (
  normalized_name,
  logical_rule_key,
  card_id,
  card_name,
  source,
  review_status,
  previous_execution_status
)
SELECT
  normalized_name,
  logical_rule_key,
  card_id,
  card_name,
  source,
  review_status,
  execution_status
FROM card_battle_rules
WHERE execution_status IS NULL
   OR execution_status = ''
   OR (
        review_status = 'needs_review'
        AND execution_status IS DISTINCT FROM 'review_only'
      )
   OR (
        review_status IN ('rejected', 'deprecated')
        AND execution_status IS DISTINCT FROM 'disabled'
      )
ON CONFLICT (normalized_name, logical_rule_key) DO NOTHING;

WITH normalized AS (
  UPDATE card_battle_rules
  SET execution_status = CASE
        WHEN review_status IN ('rejected', 'deprecated') THEN 'disabled'
        WHEN review_status = 'needs_review' THEN 'review_only'
        ELSE 'auto'
      END
  WHERE execution_status IS NULL
     OR execution_status = ''
     OR (
          review_status = 'needs_review'
          AND execution_status IS DISTINCT FROM 'review_only'
        )
     OR (
          review_status IN ('rejected', 'deprecated')
          AND execution_status IS DISTINCT FROM 'disabled'
        )
  RETURNING 1
)
SELECT 'normalized_rows' AS section, COUNT(*) AS rows
FROM normalized;

ALTER TABLE card_battle_rules
ALTER COLUMN execution_status SET DEFAULT 'auto';

ALTER TABLE card_battle_rules
ALTER COLUMN execution_status SET NOT NULL;

ALTER TABLE card_battle_rules
DROP CONSTRAINT IF EXISTS chk_card_battle_rules_execution_status;

ALTER TABLE card_battle_rules
ADD CONSTRAINT chk_card_battle_rules_execution_status CHECK (
  execution_status IN (
    'auto',
    'executable',
    'annotation_only',
    'review_only',
    'disabled'
  )
);

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
LEFT JOIN semantic_v2 sv2 ON sv2.card_id = c.id;

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
      'logical_rule_key', logical_rule_key,
      'source', source,
      'confidence', confidence,
      'review_status', review_status,
      'execution_status', execution_status,
      'rule_version', rule_version,
      'effect', effect_json,
      'deck_role', deck_role_json,
      'notes', notes,
      'updated_at', updated_at
    ) ORDER BY (review_status = 'verified') DESC, confidence DESC, source)
      AS battle_rules,
    jsonb_agg(jsonb_build_object(
      'logical_rule_key', logical_rule_key,
      'source', source,
      'confidence', confidence,
      'review_status', review_status,
      'execution_status', execution_status,
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
LEFT JOIN rulings ru ON ru.oracle_id = c.oracle_id::text;

INSERT INTO schema_migrations (version, name)
VALUES ('029', 'add_card_battle_rules_execution_status')
ON CONFLICT (version) DO NOTHING;

DO $$
DECLARE
  bad_rows INTEGER;
BEGIN
  SELECT COUNT(*)
  INTO bad_rows
  FROM card_battle_rules
  WHERE execution_status NOT IN (
    'auto',
    'executable',
    'annotation_only',
    'review_only',
    'disabled'
  );

  IF bad_rows <> 0 THEN
    RAISE EXCEPTION 'PG-006 failed: invalid execution_status rows=%', bad_rows;
  END IF;

  SELECT COUNT(*)
  INTO bad_rows
  FROM card_battle_rules
  WHERE review_status = 'needs_review'
    AND execution_status <> 'review_only';

  IF bad_rows <> 0 THEN
    RAISE EXCEPTION 'PG-006 failed: needs_review rows not review_only=%', bad_rows;
  END IF;

  SELECT COUNT(*)
  INTO bad_rows
  FROM pg_constraint
  WHERE conrelid = 'public.card_battle_rules'::regclass
    AND conname = 'chk_card_battle_rules_execution_status';

  IF bad_rows <> 1 THEN
    RAISE EXCEPTION 'PG-006 failed: execution_status constraint count=%', bad_rows;
  END IF;

  SELECT COUNT(*)
  INTO bad_rows
  FROM schema_migrations
  WHERE version = '029'
    AND name = 'add_card_battle_rules_execution_status';

  IF bad_rows <> 1 THEN
    RAISE EXCEPTION 'PG-006 failed: schema_migrations 029 count=%', bad_rows;
  END IF;

  SELECT CASE
    WHEN pg_get_viewdef('public.card_intelligence_snapshot'::regclass, true)
      ILIKE '%execution_status%'
    THEN 0
    ELSE 1
  END
  INTO bad_rows;

  IF bad_rows <> 0 THEN
    RAISE EXCEPTION 'PG-006 failed: card_intelligence_snapshot does not expose execution_status';
  END IF;
END $$;

COMMIT;
