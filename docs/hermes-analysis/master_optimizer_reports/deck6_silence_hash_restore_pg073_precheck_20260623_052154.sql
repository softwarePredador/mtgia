\pset pager off

SELECT
  count(*) FILTER (
    WHERE c.name = 'Silence'
      AND md5(coalesce(c.oracle_text, '')) = 'a0ca3c09a7db091c435ab31adb9c1780'
  ) AS silence_card_with_expected_oracle_hash,
  count(*) FILTER (
    WHERE r.normalized_name = 'silence'
      AND r.logical_rule_key = 'battle_rule_v1:74b210b77b004a677906e0216d44e445'
  ) AS target_rule_rows,
  count(*) FILTER (
    WHERE r.normalized_name = 'silence'
      AND r.logical_rule_key = 'battle_rule_v1:74b210b77b004a677906e0216d44e445'
      AND r.oracle_hash IS NULL
  ) AS target_missing_hash_rows,
  to_regclass('manaloom_deploy_audit.pg073_silence_hash_restore_20260623_052154') IS NOT NULL AS backup_table_already_exists
FROM cards c
LEFT JOIN card_battle_rules r ON r.card_id = c.id OR r.normalized_name = lower(c.name)
WHERE c.name = 'Silence';

SELECT
  c.name,
  md5(coalesce(c.oracle_text, '')) AS card_oracle_hash,
  r.normalized_name,
  r.logical_rule_key,
  r.source,
  r.review_status,
  r.execution_status,
  r.oracle_hash,
  r.effect_json,
  r.notes
FROM cards c
JOIN card_battle_rules r ON r.card_id = c.id OR r.normalized_name = lower(c.name)
WHERE c.name = 'Silence'
ORDER BY r.review_status, r.execution_status, r.logical_rule_key;
