\pset pager off
\set ON_ERROR_STOP on

BEGIN;

CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit;

DROP TABLE IF EXISTS manaloom_deploy_audit.pg024_mental_misstep_target_rule_20260622_130251;
CREATE TABLE manaloom_deploy_audit.pg024_mental_misstep_target_rule_20260622_130251 (
  section text NOT NULL,
  key text NOT NULL,
  payload jsonb NOT NULL,
  captured_at timestamptz NOT NULL DEFAULT now()
);

INSERT INTO manaloom_deploy_audit.pg024_mental_misstep_target_rule_20260622_130251
  (section, key, payload)
SELECT
  'card_battle_rules',
  normalized_name || '|' || logical_rule_key,
  to_jsonb(cbr.*)
FROM card_battle_rules cbr
WHERE lower(card_name) = 'mental misstep'
   OR normalized_name = 'mental misstep';

DO $$
DECLARE
  v_card_rows int;
  v_oracle_hash_rows int;
  v_exact_rows int;
  v_broad_enabled_rows int;
BEGIN
  SELECT count(*) INTO v_card_rows
  FROM cards
  WHERE lower(name) = 'mental misstep';

  SELECT count(*) INTO v_oracle_hash_rows
  FROM cards
  WHERE lower(name) = 'mental misstep'
    AND md5(regexp_replace(lower(coalesce(oracle_text, '')), '\s+', ' ', 'g')) =
      '3952e627ac586fb842eae00bd3c91786';

  SELECT count(*) INTO v_exact_rows
  FROM card_battle_rules
  WHERE normalized_name = 'mental misstep'
    AND logical_rule_key = 'battle_rule_v1:da6a568dbdfeda5d4009574d953db55e'
    AND effect_json->>'effect' = 'counter'
    AND effect_json->>'counter_target_cmc' = '1'
    AND review_status IN ('verified', 'active')
    AND execution_status IN ('auto', 'executable');

  SELECT count(*) INTO v_broad_enabled_rows
  FROM card_battle_rules
  WHERE lower(card_name) = 'mental misstep'
    AND logical_rule_key <> 'battle_rule_v1:da6a568dbdfeda5d4009574d953db55e'
    AND effect_json->>'effect' = 'counter'
    AND NOT (effect_json ? 'counter_target_cmc')
    AND NOT (effect_json ? 'counter_target_mana_value')
    AND NOT (effect_json ? 'target_cmc')
    AND NOT (effect_json ? 'target_mana_value')
    AND execution_status IN ('auto', 'executable', 'review_only');

  IF v_card_rows <> 1 THEN
    RAISE EXCEPTION 'PG024 precondition failed: Mental Misstep card rows=% expected 1', v_card_rows;
  END IF;
  IF v_oracle_hash_rows <> 1 THEN
    RAISE EXCEPTION 'PG024 precondition failed: Mental Misstep oracle hash rows=% expected 1', v_oracle_hash_rows;
  END IF;
  IF v_exact_rows = 0 AND v_broad_enabled_rows = 0 THEN
    RAISE EXCEPTION 'PG024 precondition failed: no exact rule and no broad enabled counter rows to repair';
  END IF;
END $$;

WITH mental_misstep AS (
  SELECT id, name
  FROM cards
  WHERE lower(name) = 'mental misstep'
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
  'mental misstep',
  'battle_rule_v1:da6a568dbdfeda5d4009574d953db55e',
  id,
  name,
  jsonb_build_object(
    'effect', 'counter',
    'instant', true,
    'counter_target_cmc', 1,
    'battle_model_scope', 'mental_misstep_mana_value_one_counter_v1'
  ),
  jsonb_build_object(
    'category', 'protection',
    'effect', 'counter',
    'timing', 'instant'
  ),
  'curated',
  1.000,
  'verified',
  'auto',
  1,
  '3952e627ac586fb842eae00bd3c91786',
  'PG-024: promoted Mental Misstep target legality. Oracle text counters only target spell with mana value 1; broad counter rows could illegally counter higher-mana-value spells such as Windborn Muse.',
  'codex_central_auditor_pg024',
  now(),
  now(),
  now(),
  now()
FROM mental_misstep
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
    'PG-024 disabled broad Mental Misstep counter approximation after promoting target mana-value-one rule.'
  ),
  reviewed_by = 'codex_central_auditor_pg024',
  reviewed_at = now(),
  updated_at = now()
WHERE lower(card_name) = 'mental misstep'
  AND logical_rule_key <> 'battle_rule_v1:da6a568dbdfeda5d4009574d953db55e'
  AND effect_json->>'effect' = 'counter'
  AND NOT (effect_json ? 'counter_target_cmc')
  AND NOT (effect_json ? 'counter_target_mana_value')
  AND NOT (effect_json ? 'target_cmc')
  AND NOT (effect_json ? 'target_mana_value');

DO $$
DECLARE
  v_exact_rows int;
  v_broad_enabled_rows int;
BEGIN
  SELECT count(*) INTO v_exact_rows
  FROM card_battle_rules
  WHERE normalized_name = 'mental misstep'
    AND logical_rule_key = 'battle_rule_v1:da6a568dbdfeda5d4009574d953db55e'
    AND effect_json->>'effect' = 'counter'
    AND effect_json->>'counter_target_cmc' = '1'
    AND review_status = 'verified'
    AND execution_status = 'auto'
    AND source = 'curated';

  SELECT count(*) INTO v_broad_enabled_rows
  FROM card_battle_rules
  WHERE lower(card_name) = 'mental misstep'
    AND logical_rule_key <> 'battle_rule_v1:da6a568dbdfeda5d4009574d953db55e'
    AND effect_json->>'effect' = 'counter'
    AND NOT (effect_json ? 'counter_target_cmc')
    AND NOT (effect_json ? 'counter_target_mana_value')
    AND NOT (effect_json ? 'target_cmc')
    AND NOT (effect_json ? 'target_mana_value')
    AND execution_status IN ('auto', 'executable', 'review_only');

  IF v_exact_rows <> 1 THEN
    RAISE EXCEPTION 'PG024 postcondition failed: exact executable rule rows=% expected 1', v_exact_rows;
  END IF;
  IF v_broad_enabled_rows <> 0 THEN
    RAISE EXCEPTION 'PG024 postcondition failed: broad enabled counter rows=% expected 0', v_broad_enabled_rows;
  END IF;
END $$;

SELECT
  'pg024_apply_result' AS check_name,
  card_name,
  logical_rule_key,
  effect_json,
  deck_role_json,
  source,
  confidence,
  review_status,
  execution_status,
  reviewed_by,
  reviewed_at
FROM card_battle_rules
WHERE lower(card_name) = 'mental misstep'
ORDER BY source, review_status, execution_status, logical_rule_key;

COMMIT;
