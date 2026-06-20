\set ON_ERROR_STOP on

BEGIN;

CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit;

CREATE TABLE IF NOT EXISTS manaloom_deploy_audit.pg008_machine_gods_effigy_battle_rule_20260620_1210 AS
SELECT now() AS backed_up_at, *
FROM card_battle_rules
WHERE normalized_name = 'machine god''s effigy'
  AND logical_rule_key = 'battle_rule_v1:c07949dca69471872a2d2b70c527b5f8'
WITH NO DATA;

INSERT INTO manaloom_deploy_audit.pg008_machine_gods_effigy_battle_rule_20260620_1210
SELECT now() AS backed_up_at, cbr.*
FROM card_battle_rules cbr
WHERE cbr.normalized_name = 'machine god''s effigy'
  AND cbr.logical_rule_key = 'battle_rule_v1:c07949dca69471872a2d2b70c527b5f8'
ON CONFLICT DO NOTHING;

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
) VALUES (
  'machine god''s effigy',
  'battle_rule_v1:c07949dca69471872a2d2b70c527b5f8',
  '1f48fdfb-983c-429b-a777-df0ce2b1d8f0'::uuid,
  'Machine God''s Effigy',
  '{"cmc":4.0,"effect":"ramp_permanent","produces":"U","mana_produced":1,"battle_model_scope":"copy_artifact_mana_rock_partial_v1","may_enter_as_creature_copy":true,"copy_target_selection_not_modeled":true,"not_a_creature_after_copy":true}'::jsonb,
  '{"category":"ramp","effect":"ramp_permanent","subtype":"copy_artifact_mana_rock"}'::jsonb,
  'curated',
  0.820,
  'active',
  'auto',
  1,
  (SELECT md5(coalesce(oracle_text, ''))
   FROM cards
   WHERE id = '1f48fdfb-983c-429b-a777-df0ce2b1d8f0'::uuid),
  'PG-008: trace Machine God''s Effigy spell-cast ramp_permanent fallback seen in battle latest 20260620_150241 seed_63211509. Runtime behavior remains the existing ramp_permanent approximation as a 4-mana artifact that can produce blue; copy/ETB target selection and copied text remain partial, so review_status stays active rather than verified.',
  'auditor_central',
  CURRENT_TIMESTAMP,
  CURRENT_TIMESTAMP,
  CURRENT_TIMESTAMP,
  CURRENT_TIMESTAMP
)
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
  updated_at = CURRENT_TIMESTAMP,
  last_seen_at = CURRENT_TIMESTAMP;

SELECT 'pg008_apply_result' AS check_name,
       normalized_name,
       logical_rule_key,
       card_id,
       card_name,
       source,
       review_status,
       execution_status,
       confidence,
       effect_json::text AS effect_json,
       deck_role_json::text AS deck_role_json
FROM card_battle_rules
WHERE normalized_name = 'machine god''s effigy'
  AND logical_rule_key = 'battle_rule_v1:c07949dca69471872a2d2b70c527b5f8';

COMMIT;
