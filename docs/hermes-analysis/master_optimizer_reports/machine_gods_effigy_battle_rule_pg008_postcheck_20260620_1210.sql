\set ON_ERROR_STOP on

BEGIN READ ONLY;

SELECT 'pg008_target_rule' AS check_name,
       normalized_name,
       logical_rule_key,
       card_id,
       card_name,
       source,
       review_status,
       execution_status,
       confidence,
       effect_json::text AS effect_json,
       deck_role_json::text AS deck_role_json,
       notes
FROM card_battle_rules
WHERE normalized_name = 'machine god''s effigy'
  AND logical_rule_key = 'battle_rule_v1:c07949dca69471872a2d2b70c527b5f8';

SELECT 'pg008_target_rule_count' AS check_name, count(*) AS row_count
FROM card_battle_rules
WHERE normalized_name = 'machine god''s effigy'
  AND logical_rule_key = 'battle_rule_v1:c07949dca69471872a2d2b70c527b5f8'
  AND card_id = '1f48fdfb-983c-429b-a777-df0ce2b1d8f0'::uuid
  AND source = 'curated'
  AND review_status = 'active'
  AND execution_status = 'auto'
  AND effect_json->>'effect' = 'ramp_permanent'
  AND effect_json->>'battle_model_scope' = 'copy_artifact_mana_rock_partial_v1'
  AND effect_json->>'produces' = 'U';

SELECT 'pg008_snapshot_after' AS check_name,
       id,
       card_id,
       name,
       battle_rule_count,
       verified_battle_rule_count,
       battle_rules::text AS battle_rules,
       verified_battle_rules::text AS verified_battle_rules,
       function_tags::text AS function_tags,
       source_coverage::text AS source_coverage
FROM card_intelligence_snapshot
WHERE card_id = '1f48fdfb-983c-429b-a777-df0ce2b1d8f0'::uuid
   OR lower(name) = 'machine god''s effigy'
ORDER BY name, card_id;

SELECT 'pg008_backup_rows' AS check_name, count(*) AS row_count
FROM manaloom_deploy_audit.pg008_machine_gods_effigy_battle_rule_20260620_1210;

ROLLBACK;
