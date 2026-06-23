\pset pager off
\set ON_ERROR_STOP on

BEGIN;

CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit;

DROP TABLE IF EXISTS manaloom_deploy_audit.pg033_land_tax_battle_rule_20260622_201417;
CREATE TABLE manaloom_deploy_audit.pg033_land_tax_battle_rule_20260622_201417 (
  section text NOT NULL,
  key text NOT NULL,
  payload jsonb NOT NULL,
  captured_at timestamptz NOT NULL DEFAULT now()
);

INSERT INTO manaloom_deploy_audit.pg033_land_tax_battle_rule_20260622_201417
  (section, key, payload)
SELECT
  'card_battle_rules',
  normalized_name || '|' || logical_rule_key,
  to_jsonb(cbr.*)
FROM card_battle_rules cbr
WHERE normalized_name = 'land tax'
   OR lower(card_name) = 'land tax';

DO $$
DECLARE
  v_card_rows int;
  v_hash_rows int;
  v_legacy_rows int;
BEGIN
  SELECT count(*) INTO v_card_rows
  FROM cards
  WHERE lower(name) = 'land tax';

  SELECT count(*) INTO v_hash_rows
  FROM cards
  WHERE lower(name) = 'land tax'
    AND md5(regexp_replace(lower(coalesce(oracle_text, '')), '\s+', ' ', 'g')) =
      '83b074e38da3e6c4eb6ec3e7568c914b';

  SELECT count(*) INTO v_legacy_rows
  FROM card_battle_rules
  WHERE normalized_name = 'land tax'
    AND logical_rule_key <> 'battle_rule_v1:e3f5f35c6a9ee4fd8c7b9972c4152bef'
    AND effect_json->>'effect' IN ('passive', 'tutor')
    AND review_status NOT IN ('rejected', 'deprecated')
    AND execution_status IN ('auto', 'executable', 'review_only');

  IF v_card_rows <> 1 THEN
    RAISE EXCEPTION 'PG033 precondition failed: Land Tax card rows=% expected 1', v_card_rows;
  END IF;
  IF v_hash_rows <> 1 THEN
    RAISE EXCEPTION 'PG033 precondition failed: Land Tax oracle hash rows=% expected 1', v_hash_rows;
  END IF;
  IF v_legacy_rows = 0 THEN
    RAISE EXCEPTION 'PG033 precondition failed: no enabled Land Tax passive/shadow row to repair';
  END IF;
END $$;

WITH target_rule AS (
  SELECT
    'land tax'::text AS normalized_name,
    'Land Tax'::text AS card_name,
    'battle_rule_v1:e3f5f35c6a9ee4fd8c7b9972c4152bef'::text AS logical_rule_key,
    '83b074e38da3e6c4eb6ec3e7568c914b'::text AS oracle_hash,
    jsonb_build_object(
      'effect', 'land_tax',
      'battle_model_scope', 'land_tax_upkeep_opponent_more_lands_basic_land_tutor_to_hand_v1',
      'trigger', 'beginning_of_your_upkeep',
      'condition', 'opponent_controls_more_lands',
      'tutor_target', 'basic_land',
      'max_count', 3,
      'destination', 'hand',
      'reveals', true,
      'shuffle_after', true
    ) AS effect_json,
    jsonb_build_object(
      'category', 'mana_development',
      'effect', 'tutor',
      'target', 'basic_land',
      'timing', 'upkeep_trigger',
      'battle_model_scope', 'land_tax_upkeep_opponent_more_lands_basic_land_tutor_to_hand_v1'
    ) AS deck_role_json,
    'PG-033: promoted Land Tax as oracle-specific upkeep basic-land tutor. Runtime models the beginning-of-upkeep trigger when any opponent controls more lands, moving up to three basic land cards from library to hand.'::text AS notes
),
resolved_card AS (
  SELECT tr.*, c.id
  FROM target_rule tr
  JOIN cards c ON lower(c.name) = tr.normalized_name
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
  normalized_name,
  logical_rule_key,
  id,
  card_name,
  effect_json,
  deck_role_json,
  'curated',
  0.930,
  'active',
  'auto',
  1,
  oracle_hash,
  notes,
  'codex_central_auditor_pg033',
  now(),
  now(),
  now(),
  now()
FROM resolved_card
ON CONFLICT (normalized_name, logical_rule_key) DO UPDATE SET
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
    ' ',
    nullif(notes, ''),
    'PG-033 disabled this broad/shadow Land Tax row after promoting oracle-specific upkeep basic-land tutor rule battle_rule_v1:e3f5f35c6a9ee4fd8c7b9972c4152bef.'
  ),
  updated_at = now(),
  last_seen_at = now()
WHERE normalized_name = 'land tax'
  AND logical_rule_key <> 'battle_rule_v1:e3f5f35c6a9ee4fd8c7b9972c4152bef'
  AND effect_json->>'effect' IN ('passive', 'tutor')
  AND review_status NOT IN ('rejected', 'deprecated')
  AND execution_status IN ('auto', 'executable', 'review_only');

SELECT
  'pg033_land_tax_apply_result' AS check_name,
  card_name,
  logical_rule_key,
  effect_json,
  source,
  confidence,
  review_status,
  execution_status,
  oracle_hash
FROM card_battle_rules
WHERE normalized_name = 'land tax'
ORDER BY source, review_status, execution_status, logical_rule_key;

COMMIT;
