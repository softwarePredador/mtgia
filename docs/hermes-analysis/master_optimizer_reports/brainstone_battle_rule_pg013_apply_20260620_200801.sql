\pset pager off
\set ON_ERROR_STOP on

BEGIN;

CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit;

DROP TABLE IF EXISTS manaloom_deploy_audit.pg013_brainstone_battle_rule_20260620_200801;
CREATE TABLE manaloom_deploy_audit.pg013_brainstone_battle_rule_20260620_200801 (
  section text NOT NULL,
  key text NOT NULL,
  payload jsonb NOT NULL,
  captured_at timestamptz NOT NULL DEFAULT now()
);

INSERT INTO manaloom_deploy_audit.pg013_brainstone_battle_rule_20260620_200801
  (section, key, payload)
SELECT
  'card_battle_rules',
  normalized_name || '|' || logical_rule_key,
  to_jsonb(cbr.*)
FROM card_battle_rules cbr
WHERE lower(card_name) = 'brainstone';

DO $$
DECLARE
  v_card_rows int;
  v_generated_rows int;
  v_curated_rows int;
  v_oracle_hash text;
BEGIN
  SELECT count(*) INTO v_card_rows
  FROM cards
  WHERE lower(name) = 'brainstone';

  SELECT count(*) INTO v_generated_rows
  FROM cards c
  JOIN card_battle_rules cbr ON cbr.card_id = c.id
  WHERE lower(c.name) = 'brainstone'
    AND cbr.source = 'generated'
    AND cbr.review_status = 'needs_review'
    AND cbr.execution_status = 'review_only'
    AND cbr.effect_json->>'effect' = 'draw_cards';

  SELECT count(*) INTO v_curated_rows
  FROM card_battle_rules
  WHERE normalized_name = 'brainstone'
    AND logical_rule_key = 'battle_rule_v1:03bed5506a427743723cd7676c6a67d9';

  SELECT md5(regexp_replace(lower(coalesce(oracle_text, '')), '\s+', ' ', 'g')) INTO v_oracle_hash
  FROM cards
  WHERE lower(name) = 'brainstone'
  LIMIT 1;

  IF v_card_rows <> 1 THEN
    RAISE EXCEPTION 'PG013 precondition failed: Brainstone card rows=% expected 1', v_card_rows;
  END IF;
  IF v_generated_rows < 1 AND v_curated_rows = 0 THEN
    RAISE EXCEPTION 'PG013 precondition failed: generated review_only draw_cards rows=% expected >=1 before first curated apply', v_generated_rows;
  END IF;
  IF v_oracle_hash <> '58ead991d38c00ac4b790f7e3aa09578' THEN
    RAISE EXCEPTION 'PG013 precondition failed: oracle_hash=% expected 58ead991d38c00ac4b790f7e3aa09578', v_oracle_hash;
  END IF;
END $$;

WITH brainstone AS (
  SELECT id, name
  FROM cards
  WHERE lower(name) = 'brainstone'
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
  'brainstone',
  'battle_rule_v1:03bed5506a427743723cd7676c6a67d9',
  id,
  name,
  jsonb_build_object(
    'effect', 'topdeck_manipulation',
    'activation_cost_generic', 2,
    'requires_sacrifice_artifact', true,
    'draw_count', 3,
    'put_from_hand_on_top_count', 2,
    'hand_to_top_exchange', true,
    'battle_model_scope', 'brainstone_draw_three_put_two_back_unexecuted_v1',
    'cmc', 1.0
  ),
  jsonb_build_object(
    'category', 'draw',
    'effect', 'topdeck_manipulation',
    'subtype', 'activated_draw_topdeck_filter'
  ),
  'curated',
  0.88,
  'active',
  'auto',
  1,
  '58ead991d38c00ac4b790f7e3aa09578',
  'PG-013: promoted reviewed Brainstone rule from reviewed_battle_card_rules.json. Oracle text is activated {2}, tap, sacrifice: draw three, then put two cards from hand on top; runtime must treat this as topdeck manipulation/filter, not free draw on spell resolution.',
  'codex_central_auditor_pg013',
  now(),
  now(),
  now(),
  now()
FROM brainstone
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
    'PG-013 disabled stale generated draw_cards approximation after curated activated topdeck_manipulation rule.'
  ),
  reviewed_by = 'codex_central_auditor_pg013',
  reviewed_at = now(),
  updated_at = now()
WHERE lower(card_name) = 'brainstone'
  AND logical_rule_key <> 'battle_rule_v1:03bed5506a427743723cd7676c6a67d9'
  AND source = 'generated'
  AND effect_json->>'effect' = 'draw_cards';

DO $$
DECLARE
  v_curated int;
  v_stale_enabled int;
BEGIN
  SELECT count(*) INTO v_curated
  FROM card_battle_rules
  WHERE normalized_name = 'brainstone'
    AND logical_rule_key = 'battle_rule_v1:03bed5506a427743723cd7676c6a67d9'
    AND effect_json->>'effect' = 'topdeck_manipulation'
    AND effect_json->>'activation_cost_generic' = '2'
    AND effect_json->>'draw_count' = '3'
    AND effect_json->>'put_from_hand_on_top_count' = '2'
    AND review_status = 'active'
    AND execution_status = 'auto'
    AND source = 'curated';

  SELECT count(*) INTO v_stale_enabled
  FROM card_battle_rules
  WHERE lower(card_name) = 'brainstone'
    AND logical_rule_key <> 'battle_rule_v1:03bed5506a427743723cd7676c6a67d9'
    AND effect_json->>'effect' = 'draw_cards'
    AND execution_status IN ('auto', 'executable', 'review_only');

  IF v_curated <> 1 THEN
    RAISE EXCEPTION 'PG013 postcondition failed: curated executable rule rows=% expected 1', v_curated;
  END IF;
  IF v_stale_enabled <> 0 THEN
    RAISE EXCEPTION 'PG013 postcondition failed: stale enabled/generated rows=% expected 0', v_stale_enabled;
  END IF;
END $$;

SELECT
  'pg013_apply_result' AS check_name,
  card_name,
  logical_rule_key,
  effect_json,
  deck_role_json,
  source,
  confidence,
  review_status,
  execution_status
FROM card_battle_rules
WHERE lower(card_name) = 'brainstone'
ORDER BY source, review_status, execution_status, logical_rule_key;

COMMIT;
