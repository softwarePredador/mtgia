\set ON_ERROR_STOP on

BEGIN READ ONLY;

SELECT 'pg007_target_rule' AS check_name,
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
WHERE normalized_name = 'leyline of abundance'
  AND logical_rule_key = 'battle_rule_v1:f3c990ed2e762aaab17c617ac3a42941';

SELECT 'pg007_target_rule_count' AS check_name, count(*) AS row_count
FROM card_battle_rules
WHERE normalized_name = 'leyline of abundance'
  AND logical_rule_key = 'battle_rule_v1:f3c990ed2e762aaab17c617ac3a42941'
  AND card_id = 'd524183f-6430-411b-8a9b-48eda6cb0f7d'::uuid
  AND source = 'curated'
  AND review_status = 'active'
  AND execution_status = 'auto'
  AND effect_json->>'effect' = 'ramp_permanent'
  AND effect_json->>'battle_model_scope' = 'leyline_of_abundance_static_mana_bonus_partial_v1';

SELECT 'pg007_snapshot_after' AS check_name,
       id,
       card_id,
       name,
       battle_rules::text AS battle_rules,
       function_tags::text AS function_tags
FROM card_intelligence_snapshot
WHERE card_id = 'd524183f-6430-411b-8a9b-48eda6cb0f7d'::uuid
   OR lower(name) = 'leyline of abundance'
ORDER BY name, card_id;

SELECT 'pg007_backup_rows' AS check_name, count(*) AS row_count
FROM manaloom_deploy_audit.pg007_leyline_abundance_battle_rule_20260620_1018;

ROLLBACK;
