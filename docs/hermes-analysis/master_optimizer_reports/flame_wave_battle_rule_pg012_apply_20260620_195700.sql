\pset pager off
\set ON_ERROR_STOP on

BEGIN;

CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit;

DROP TABLE IF EXISTS manaloom_deploy_audit.pg012_flame_wave_battle_rule_20260620_195700;
CREATE TABLE manaloom_deploy_audit.pg012_flame_wave_battle_rule_20260620_195700 (
  section text NOT NULL,
  key text NOT NULL,
  payload jsonb NOT NULL,
  captured_at timestamptz NOT NULL DEFAULT now()
);

INSERT INTO manaloom_deploy_audit.pg012_flame_wave_battle_rule_20260620_195700
  (section, key, payload)
SELECT
  'card_battle_rules',
  normalized_name || '|' || logical_rule_key,
  to_jsonb(cbr.*)
FROM card_battle_rules cbr
WHERE lower(card_name) = 'flame wave';

DO $$
DECLARE
  v_card_rows int;
  v_generated_rows int;
  v_oracle_hash text;
BEGIN
  SELECT count(*) INTO v_card_rows
  FROM cards
  WHERE lower(name) = 'flame wave';

  SELECT count(*) INTO v_generated_rows
  FROM cards c
  JOIN card_battle_rules cbr ON cbr.card_id = c.id
  WHERE lower(c.name) = 'flame wave'
    AND cbr.source = 'generated'
    AND cbr.review_status = 'needs_review'
    AND cbr.execution_status = 'review_only'
    AND cbr.effect_json->>'effect' = 'remove_creature';

  SELECT md5(regexp_replace(lower(coalesce(oracle_text, '')), '\s+', ' ', 'g')) INTO v_oracle_hash
  FROM cards
  WHERE lower(name) = 'flame wave'
  LIMIT 1;

  IF v_card_rows <> 1 THEN
    RAISE EXCEPTION 'PG012 precondition failed: Flame Wave card rows=% expected 1', v_card_rows;
  END IF;
  IF v_generated_rows < 1 THEN
    RAISE EXCEPTION 'PG012 precondition failed: generated review_only remove_creature rows=% expected >=1', v_generated_rows;
  END IF;
  IF v_oracle_hash <> 'db2deb4a84e2c517c85ae1d933ed708d' THEN
    RAISE EXCEPTION 'PG012 precondition failed: oracle_hash=% expected db2deb4a84e2c517c85ae1d933ed708d', v_oracle_hash;
  END IF;
END $$;

WITH flame_wave AS (
  SELECT id, name
  FROM cards
  WHERE lower(name) = 'flame wave'
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
  'flame wave',
  'battle_rule_v1:7a932c36df79f966f5f144a3b3a87d84',
  id,
  name,
  jsonb_build_object(
    'effect', 'damage_player_and_creatures',
    'amount', 4,
    'target', 'player_or_planeswalker_controller',
    'battle_model_scope', 'target_player_and_controller_creatures',
    'cmc', 7.0
  ),
  jsonb_build_object(
    'category', 'removal',
    'tags', jsonb_build_array('removal', 'damage_sweeper'),
    'battle_model_scope', 'targeted_player_creature_sweep'
  ),
  'curated',
  1.0,
  'verified',
  'auto',
  1,
  'db2deb4a84e2c517c85ae1d933ed708d',
  'PG-012: Scryfall oracle verified; Flame Wave deals 4 to target player/planeswalker and each creature that controller controls. Runtime effect damage_player_and_creatures added and tested 2026-06-20.',
  'codex_central_auditor_pg012',
  now(),
  now(),
  now(),
  now()
FROM flame_wave
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
    'PG-012 disabled stale generated remove_creature approximation after curated damage_player_and_creatures rule.'
  ),
  reviewed_by = 'codex_central_auditor_pg012',
  reviewed_at = now(),
  updated_at = now()
WHERE lower(card_name) = 'flame wave'
  AND logical_rule_key <> 'battle_rule_v1:7a932c36df79f966f5f144a3b3a87d84'
  AND source = 'generated'
  AND effect_json->>'effect' = 'remove_creature';

DO $$
DECLARE
  v_curated int;
  v_stale_enabled int;
BEGIN
  SELECT count(*) INTO v_curated
  FROM card_battle_rules
  WHERE normalized_name = 'flame wave'
    AND logical_rule_key = 'battle_rule_v1:7a932c36df79f966f5f144a3b3a87d84'
    AND effect_json->>'effect' = 'damage_player_and_creatures'
    AND review_status = 'verified'
    AND execution_status = 'auto'
    AND source = 'curated';

  SELECT count(*) INTO v_stale_enabled
  FROM card_battle_rules
  WHERE lower(card_name) = 'flame wave'
    AND logical_rule_key <> 'battle_rule_v1:7a932c36df79f966f5f144a3b3a87d84'
    AND effect_json->>'effect' = 'remove_creature'
    AND execution_status IN ('auto', 'executable', 'review_only');

  IF v_curated <> 1 THEN
    RAISE EXCEPTION 'PG012 postcondition failed: curated executable rule rows=% expected 1', v_curated;
  END IF;
  IF v_stale_enabled <> 0 THEN
    RAISE EXCEPTION 'PG012 postcondition failed: stale enabled/generated rows=% expected 0', v_stale_enabled;
  END IF;
END $$;

SELECT
  'pg012_apply_result' AS check_name,
  card_name,
  logical_rule_key,
  effect_json,
  deck_role_json,
  source,
  confidence,
  review_status,
  execution_status
FROM card_battle_rules
WHERE lower(card_name) = 'flame wave'
ORDER BY source, review_status, execution_status, logical_rule_key;

COMMIT;
