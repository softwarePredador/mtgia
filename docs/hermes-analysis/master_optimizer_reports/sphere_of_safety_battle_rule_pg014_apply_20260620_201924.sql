\pset pager off
\set ON_ERROR_STOP on

BEGIN;

CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit;

DROP TABLE IF EXISTS manaloom_deploy_audit.pg014_sphere_of_safety_20260620_201924;
CREATE TABLE manaloom_deploy_audit.pg014_sphere_of_safety_20260620_201924 (
  section text NOT NULL,
  key text NOT NULL,
  payload jsonb NOT NULL,
  captured_at timestamptz NOT NULL DEFAULT now()
);

INSERT INTO manaloom_deploy_audit.pg014_sphere_of_safety_20260620_201924
  (section, key, payload)
SELECT
  'card_battle_rules',
  normalized_name || '|' || logical_rule_key,
  to_jsonb(cbr.*)
FROM card_battle_rules cbr
WHERE lower(card_name) = 'sphere of safety';

INSERT INTO manaloom_deploy_audit.pg014_sphere_of_safety_20260620_201924
  (section, key, payload)
SELECT
  'card_function_tags',
  card_id::text || '|' || tag || '|' || source,
  to_jsonb(cft.*)
FROM card_function_tags cft
WHERE lower(card_name) = 'sphere of safety';

DO $$
DECLARE
  v_card_rows int;
  v_generated_rows int;
  v_curated_rows int;
  v_oracle_hash text;
BEGIN
  SELECT count(*) INTO v_card_rows
  FROM cards
  WHERE lower(name) = 'sphere of safety';

  SELECT count(*) INTO v_generated_rows
  FROM cards c
  JOIN card_battle_rules cbr ON cbr.card_id = c.id
  WHERE lower(c.name) = 'sphere of safety'
    AND cbr.source = 'generated'
    AND cbr.review_status = 'needs_review'
    AND cbr.execution_status = 'review_only'
    AND cbr.effect_json->>'effect' = 'draw_engine';

  SELECT count(*) INTO v_curated_rows
  FROM card_battle_rules
  WHERE normalized_name = 'sphere of safety'
    AND logical_rule_key = 'battle_rule_v1:a619518cf24caa68fdd86b555687f20f';

  SELECT md5(regexp_replace(lower(coalesce(oracle_text, '')), '\s+', ' ', 'g')) INTO v_oracle_hash
  FROM cards
  WHERE lower(name) = 'sphere of safety'
  LIMIT 1;

  IF v_card_rows <> 1 THEN
    RAISE EXCEPTION 'PG014 precondition failed: Sphere of Safety card rows=% expected 1', v_card_rows;
  END IF;
  IF v_generated_rows < 1 AND v_curated_rows = 0 THEN
    RAISE EXCEPTION 'PG014 precondition failed: generated review_only draw_engine rows=% expected >=1 before first curated apply', v_generated_rows;
  END IF;
  IF v_oracle_hash <> '8cccdd6f8ac9a1391ed6e7b17c9e2a00' THEN
    RAISE EXCEPTION 'PG014 precondition failed: oracle_hash=% expected 8cccdd6f8ac9a1391ed6e7b17c9e2a00', v_oracle_hash;
  END IF;
END $$;

WITH sphere AS (
  SELECT id, name
  FROM cards
  WHERE lower(name) = 'sphere of safety'
)
INSERT INTO card_battle_rules (
  normalized_name,
  logical_rule_key,
  card_id,
  card_name,
  effect_json,
  deck_role_json,
  source,
  confidence,
  review_status,
  execution_status,
  rule_version,
  oracle_hash,
  notes,
  reviewed_by,
  reviewed_at,
  created_at,
  updated_at,
  last_seen_at
)
SELECT
  'sphere of safety',
  'battle_rule_v1:a619518cf24caa68fdd86b555687f20f',
  id,
  name,
  jsonb_build_object(
    'effect', 'attack_tax',
    'attack_tax_per_enchantment', 1,
    'minimum_attack_tax_per_creature', 1,
    'battle_model_scope', 'sphere_of_safety_enchantment_scaled_attack_tax',
    'cmc', 5.0
  ),
  jsonb_build_object(
    'category', 'protection',
    'effect', 'attack_tax',
    'subtype', 'enchantment_scaled_pillowfort'
  ),
  'curated',
  1.0,
  'verified',
  'auto',
  1,
  '8cccdd6f8ac9a1391ed6e7b17c9e2a00',
  'PG-014: oracle-verified attack tax. Creatures cannot attack controller unless their controller pays X per creature, where X is the number of enchantments controlled. Runtime supports attack_tax_per_enchantment.',
  'codex_central_auditor_pg014',
  now(),
  now(),
  now(),
  now()
FROM sphere
ON CONFLICT (normalized_name, logical_rule_key)
DO UPDATE SET
  card_id = EXCLUDED.card_id,
  card_name = EXCLUDED.card_name,
  effect_json = EXCLUDED.effect_json,
  deck_role_json = EXCLUDED.deck_role_json,
  source = EXCLUDED.source,
  confidence = EXCLUDED.confidence,
  review_status = EXCLUDED.review_status,
  execution_status = EXCLUDED.execution_status,
  rule_version = EXCLUDED.rule_version,
  oracle_hash = EXCLUDED.oracle_hash,
  notes = EXCLUDED.notes,
  reviewed_by = EXCLUDED.reviewed_by,
  reviewed_at = EXCLUDED.reviewed_at,
  updated_at = now(),
  last_seen_at = now();

UPDATE card_battle_rules
SET
  review_status = 'deprecated',
  execution_status = 'disabled',
  notes = concat_ws(
    E'\n',
    NULLIF(notes, ''),
    'PG-014 disabled stale generated draw_engine approximation after curated attack_tax rule.'
  ),
  reviewed_by = 'codex_central_auditor_pg014',
  reviewed_at = now(),
  updated_at = now()
WHERE lower(card_name) = 'sphere of safety'
  AND logical_rule_key <> 'battle_rule_v1:a619518cf24caa68fdd86b555687f20f'
  AND source = 'generated'
  AND effect_json->>'effect' = 'draw_engine';

WITH sphere AS (
  SELECT id, name
  FROM cards
  WHERE lower(name) = 'sphere of safety'
)
INSERT INTO card_function_tags (
  card_id,
  card_name,
  tag,
  confidence,
  source,
  evidence,
  updated_at
)
SELECT
  id,
  name,
  'protection',
  1.0,
  'card_battle_rules_v1',
  'PG-014 curated attack_tax battle rule battle_rule_v1:a619518cf24caa68fdd86b555687f20f',
  now()
FROM sphere
ON CONFLICT (card_id, tag, source)
DO UPDATE SET
  card_name = EXCLUDED.card_name,
  confidence = EXCLUDED.confidence,
  evidence = EXCLUDED.evidence,
  updated_at = now();

DO $$
DECLARE
  v_curated int;
  v_stale_enabled int;
  v_function_tag int;
BEGIN
  SELECT count(*) INTO v_curated
  FROM card_battle_rules
  WHERE normalized_name = 'sphere of safety'
    AND logical_rule_key = 'battle_rule_v1:a619518cf24caa68fdd86b555687f20f'
    AND effect_json->>'effect' = 'attack_tax'
    AND effect_json->>'attack_tax_per_enchantment' = '1'
    AND review_status = 'verified'
    AND execution_status = 'auto'
    AND source = 'curated';

  SELECT count(*) INTO v_stale_enabled
  FROM card_battle_rules
  WHERE lower(card_name) = 'sphere of safety'
    AND logical_rule_key <> 'battle_rule_v1:a619518cf24caa68fdd86b555687f20f'
    AND effect_json->>'effect' = 'draw_engine'
    AND execution_status IN ('auto', 'executable', 'review_only');

  SELECT count(*) INTO v_function_tag
  FROM card_function_tags
  WHERE lower(card_name) = 'sphere of safety'
    AND tag = 'protection'
    AND source = 'card_battle_rules_v1'
    AND confidence >= 1.0;

  IF v_curated <> 1 THEN
    RAISE EXCEPTION 'PG014 postcondition failed: curated executable rule rows=% expected 1', v_curated;
  END IF;
  IF v_stale_enabled <> 0 THEN
    RAISE EXCEPTION 'PG014 postcondition failed: stale enabled/generated rows=% expected 0', v_stale_enabled;
  END IF;
  IF v_function_tag <> 1 THEN
    RAISE EXCEPTION 'PG014 postcondition failed: protection function tag rows=% expected 1', v_function_tag;
  END IF;
END $$;

SELECT
  'pg014_apply_rule_result' AS check_name,
  card_name,
  logical_rule_key,
  effect_json,
  deck_role_json,
  source,
  confidence,
  review_status,
  execution_status
FROM card_battle_rules
WHERE lower(card_name) = 'sphere of safety'
ORDER BY source, review_status, execution_status, logical_rule_key;

SELECT
  'pg014_apply_tag_result' AS check_name,
  card_name,
  tag,
  source,
  confidence,
  evidence
FROM card_function_tags
WHERE lower(card_name) = 'sphere of safety'
ORDER BY tag, source;

COMMIT;
