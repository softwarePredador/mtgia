\set ON_ERROR_STOP on

BEGIN;

DELETE FROM card_battle_rules
WHERE normalized_name = 'leyline of abundance'
  AND logical_rule_key = 'battle_rule_v1:f3c990ed2e762aaab17c617ac3a42941';

INSERT INTO card_battle_rules (
  normalized_name,
  card_id,
  card_name,
  effect_json,
  deck_role_json,
  source,
  confidence,
  review_status,
  rule_version,
  oracle_hash,
  notes,
  reviewed_by,
  reviewed_at,
  created_at,
  updated_at,
  last_seen_at,
  logical_rule_key,
  execution_status
)
SELECT
  normalized_name,
  card_id,
  card_name,
  effect_json,
  deck_role_json,
  source,
  confidence,
  review_status,
  rule_version,
  oracle_hash,
  notes,
  reviewed_by,
  reviewed_at,
  created_at,
  updated_at,
  last_seen_at,
  logical_rule_key,
  execution_status
FROM manaloom_deploy_audit.pg007_leyline_abundance_battle_rule_20260620_1018
WHERE normalized_name = 'leyline of abundance'
  AND logical_rule_key = 'battle_rule_v1:f3c990ed2e762aaab17c617ac3a42941'
ON CONFLICT (normalized_name, logical_rule_key) DO UPDATE SET
  card_id = EXCLUDED.card_id,
  card_name = EXCLUDED.card_name,
  effect_json = EXCLUDED.effect_json,
  deck_role_json = EXCLUDED.deck_role_json,
  source = EXCLUDED.source,
  confidence = EXCLUDED.confidence,
  review_status = EXCLUDED.review_status,
  rule_version = EXCLUDED.rule_version,
  oracle_hash = EXCLUDED.oracle_hash,
  notes = EXCLUDED.notes,
  reviewed_by = EXCLUDED.reviewed_by,
  reviewed_at = EXCLUDED.reviewed_at,
  created_at = EXCLUDED.created_at,
  updated_at = EXCLUDED.updated_at,
  last_seen_at = EXCLUDED.last_seen_at,
  execution_status = EXCLUDED.execution_status;

SELECT 'pg007_rollback_result' AS check_name,
       count(*) AS restored_target_rows
FROM card_battle_rules
WHERE normalized_name = 'leyline of abundance'
  AND logical_rule_key = 'battle_rule_v1:f3c990ed2e762aaab17c617ac3a42941';

COMMIT;
