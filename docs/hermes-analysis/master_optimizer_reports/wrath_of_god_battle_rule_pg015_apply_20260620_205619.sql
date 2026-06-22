\pset pager off
\set ON_ERROR_STOP on

BEGIN;

CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit;

DROP TABLE IF EXISTS manaloom_deploy_audit.pg015_wrath_of_god_20260620_205619;
CREATE TABLE manaloom_deploy_audit.pg015_wrath_of_god_20260620_205619 (
  section text NOT NULL,
  key text NOT NULL,
  payload jsonb NOT NULL,
  captured_at timestamptz NOT NULL DEFAULT now()
);

INSERT INTO manaloom_deploy_audit.pg015_wrath_of_god_20260620_205619
  (section, key, payload)
SELECT
  'card_battle_rules',
  normalized_name || '|' || logical_rule_key,
  to_jsonb(cbr.*)
FROM card_battle_rules cbr
WHERE lower(card_name) = 'wrath of god';

DO $$
DECLARE
  v_card_rows int;
  v_generated_rows int;
  v_oracle_hash text;
BEGIN
  SELECT count(*) INTO v_card_rows
  FROM cards
  WHERE lower(name) = 'wrath of god';

  SELECT count(*) INTO v_generated_rows
  FROM cards c
  JOIN card_battle_rules cbr ON cbr.card_id = c.id
  WHERE lower(c.name) = 'wrath of god'
    AND cbr.source = 'generated'
    AND cbr.review_status = 'needs_review'
    AND cbr.execution_status = 'review_only'
    AND cbr.effect_json->>'effect' = 'board_wipe';

  SELECT md5(regexp_replace(lower(coalesce(oracle_text, '')), '\s+', ' ', 'g')) INTO v_oracle_hash
  FROM cards
  WHERE lower(name) = 'wrath of god'
  LIMIT 1;

  IF v_card_rows <> 1 THEN
    RAISE EXCEPTION 'PG015 precondition failed: Wrath of God card rows=% expected 1', v_card_rows;
  END IF;
  IF v_generated_rows < 1 THEN
    RAISE EXCEPTION 'PG015 precondition failed: generated review_only board_wipe rows=% expected >=1', v_generated_rows;
  END IF;
  IF v_oracle_hash <> 'a8f68dacac72b1857d01e598fd79edbe' THEN
    RAISE EXCEPTION 'PG015 precondition failed: oracle_hash=% expected a8f68dacac72b1857d01e598fd79edbe', v_oracle_hash;
  END IF;
END $$;

WITH wrath AS (
  SELECT id, name
  FROM cards
  WHERE lower(name) = 'wrath of god'
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
  'wrath of god',
  'battle_rule_v1:3c8d1d97cf71a2cb4fef4cb0439f474e',
  id,
  name,
  jsonb_build_object(
    'effect', 'board_wipe',
    'cmc', 4.0
  ),
  jsonb_build_object(
    'category', 'wipe',
    'effect', 'board_wipe'
  ),
  'curated',
  1.0,
  'verified',
  'auto',
  1,
  'a8f68dacac72b1857d01e598fd79edbe',
  'PG-015: oracle-verified destroy all creatures board wipe. Promoted for Lorehold survival variant testing.',
  'codex_central_auditor_pg015',
  now(),
  now(),
  now(),
  now()
FROM wrath
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
    'PG-015 disabled duplicate generated board_wipe approximation after curated Wrath of God rule.'
  ),
  reviewed_by = 'codex_central_auditor_pg015',
  reviewed_at = now(),
  updated_at = now()
WHERE lower(card_name) = 'wrath of god'
  AND logical_rule_key <> 'battle_rule_v1:3c8d1d97cf71a2cb4fef4cb0439f474e'
  AND source = 'generated'
  AND effect_json->>'effect' = 'board_wipe';

DO $$
DECLARE
  v_curated int;
  v_stale_enabled int;
BEGIN
  SELECT count(*) INTO v_curated
  FROM card_battle_rules
  WHERE normalized_name = 'wrath of god'
    AND logical_rule_key = 'battle_rule_v1:3c8d1d97cf71a2cb4fef4cb0439f474e'
    AND effect_json->>'effect' = 'board_wipe'
    AND review_status = 'verified'
    AND execution_status = 'auto'
    AND source = 'curated';

  SELECT count(*) INTO v_stale_enabled
  FROM card_battle_rules
  WHERE lower(card_name) = 'wrath of god'
    AND logical_rule_key <> 'battle_rule_v1:3c8d1d97cf71a2cb4fef4cb0439f474e'
    AND effect_json->>'effect' = 'board_wipe'
    AND execution_status IN ('auto', 'executable', 'review_only');

  IF v_curated <> 1 THEN
    RAISE EXCEPTION 'PG015 postcondition failed: curated executable rule rows=% expected 1', v_curated;
  END IF;
  IF v_stale_enabled <> 0 THEN
    RAISE EXCEPTION 'PG015 postcondition failed: stale enabled/generated rows=% expected 0', v_stale_enabled;
  END IF;
END $$;

SELECT
  'pg015_apply_result' AS check_name,
  card_name,
  logical_rule_key,
  effect_json,
  deck_role_json,
  source,
  confidence,
  review_status,
  execution_status
FROM card_battle_rules
WHERE lower(card_name) = 'wrath of god'
ORDER BY source, review_status, execution_status, logical_rule_key;

COMMIT;
