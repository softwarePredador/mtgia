\pset pager off

SELECT
  count(*) AS silence_rule_rows,
  count(*) FILTER (
    WHERE logical_rule_key = 'battle_rule_v1:74b210b77b004a677906e0216d44e445'
      AND oracle_hash = 'a0ca3c09a7db091c435ab31adb9c1780'
      AND review_status = 'verified'
      AND execution_status = 'auto'
  ) AS expected_runtime_rows,
  count(*) FILTER (
    WHERE logical_rule_key = 'battle_rule_v1:74b210b77b004a677906e0216d44e445'
      AND oracle_hash IS NULL
  ) AS target_missing_hash_rows,
  (
    SELECT count(*)
    FROM manaloom_deploy_audit.pg077_silence_hash_restore_20260623_061815
  ) AS backup_rows
FROM card_battle_rules
WHERE normalized_name = 'silence';

SELECT
  normalized_name,
  logical_rule_key,
  source,
  review_status,
  execution_status,
  confidence,
  rule_version,
  oracle_hash,
  effect_json,
  notes
FROM card_battle_rules
WHERE normalized_name = 'silence'
ORDER BY review_status, execution_status, logical_rule_key;
