\pset pager off
\set ON_ERROR_STOP on

BEGIN;

CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit;

DROP TABLE IF EXISTS manaloom_deploy_audit.pg034_lightning_greaves_battle_rule_20260622_202908;
CREATE TABLE manaloom_deploy_audit.pg034_lightning_greaves_battle_rule_20260622_202908 (
  section text NOT NULL,
  key text NOT NULL,
  payload jsonb NOT NULL,
  captured_at timestamptz NOT NULL DEFAULT now()
);

INSERT INTO manaloom_deploy_audit.pg034_lightning_greaves_battle_rule_20260622_202908
  (section, key, payload)
SELECT
  'card_battle_rules',
  normalized_name || '|' || logical_rule_key,
  to_jsonb(cbr.*)
FROM card_battle_rules cbr
WHERE normalized_name = 'lightning greaves'
   OR lower(card_name) = 'lightning greaves';

DO $$
DECLARE
  v_card_rows int;
  v_hash_rows int;
  v_legacy_rows int;
BEGIN
  SELECT count(*) INTO v_card_rows
  FROM cards
  WHERE lower(name) = 'lightning greaves';

  SELECT count(*) INTO v_hash_rows
  FROM cards
  WHERE lower(name) = 'lightning greaves'
    AND md5(regexp_replace(lower(coalesce(oracle_text, '')), '\s+', ' ', 'g')) =
      '4a4c71d3cc58637cf00a3d7fe2331353';

  SELECT count(*) INTO v_legacy_rows
  FROM card_battle_rules
  WHERE normalized_name = 'lightning greaves'
    AND logical_rule_key <> 'battle_rule_v1:5ea7f2a8349a93ea46e05b60ee8cdaac'
    AND effect_json->>'effect' IN ('equipment_haste_shroud', 'indestructible')
    AND review_status NOT IN ('rejected', 'deprecated')
    AND execution_status IN ('auto', 'executable', 'review_only');

  IF v_card_rows <> 1 THEN
    RAISE EXCEPTION 'PG034 precondition failed: Lightning Greaves card rows=% expected 1', v_card_rows;
  END IF;
  IF v_hash_rows <> 1 THEN
    RAISE EXCEPTION 'PG034 precondition failed: Lightning Greaves oracle hash rows=% expected 1', v_hash_rows;
  END IF;
  IF v_legacy_rows = 0 THEN
    RAISE EXCEPTION 'PG034 precondition failed: no enabled Lightning Greaves equipment/shadow row to repair';
  END IF;
END $$;

WITH target_rule AS (
  SELECT
    'lightning greaves'::text AS normalized_name,
    'Lightning Greaves'::text AS card_name,
    'battle_rule_v1:5ea7f2a8349a93ea46e05b60ee8cdaac'::text AS logical_rule_key,
    '4a4c71d3cc58637cf00a3d7fe2331353'::text AS oracle_hash,
    jsonb_build_object(
      'effect', 'equipment_haste_shroud',
      'battle_model_scope', 'lightning_greaves_auto_attach_haste_shroud_equip_0_v1',
      'attach_model', 'auto_attach_best_creature_on_resolution',
      'grants', jsonb_build_array('haste', 'shroud'),
      'equip_cost', 0,
      'target', 'creature_you_control',
      'duration', 'while_attached'
    ) AS effect_json,
    jsonb_build_object(
      'category', 'protection',
      'effect', 'equipment_haste_shroud',
      'target', 'creature_you_control',
      'timing', 'equipment_resolution_heuristic',
      'battle_model_scope', 'lightning_greaves_auto_attach_haste_shroud_equip_0_v1'
    ) AS deck_role_json,
    'PG-034: promoted Lightning Greaves as oracle-specific haste/shroud equipment rule. Runtime preserves the existing battle heuristic: cast/resolution auto-attaches to the best creature you control; full Equipment attach/retarget timing is not modeled here.'::text AS notes
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
  'codex_central_auditor_pg034',
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
    'PG-034 disabled this duplicate/shadow Lightning Greaves row after promoting oracle-specific haste/shroud equipment rule battle_rule_v1:5ea7f2a8349a93ea46e05b60ee8cdaac.'
  ),
  updated_at = now(),
  last_seen_at = now()
WHERE normalized_name = 'lightning greaves'
  AND logical_rule_key <> 'battle_rule_v1:5ea7f2a8349a93ea46e05b60ee8cdaac'
  AND effect_json->>'effect' IN ('equipment_haste_shroud', 'indestructible')
  AND review_status NOT IN ('rejected', 'deprecated')
  AND execution_status IN ('auto', 'executable', 'review_only');

SELECT
  'pg034_lightning_greaves_apply_result' AS check_name,
  card_name,
  logical_rule_key,
  effect_json,
  source,
  confidence,
  review_status,
  execution_status,
  oracle_hash
FROM card_battle_rules
WHERE normalized_name = 'lightning greaves'
ORDER BY source, review_status, execution_status, logical_rule_key;

COMMIT;
