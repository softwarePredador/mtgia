\pset pager off

SELECT
  count(*) FILTER (
    WHERE c.name = 'Silence'
      AND md5(coalesce(c.oracle_text, '')) = 'a0ca3c09a7db091c435ab31adb9c1780'
  ) AS target_cards_with_expected_oracle_hash,
  count(*) FILTER (
    WHERE cbr.normalized_name = 'silence'
      AND cbr.logical_rule_key = 'battle_rule_v1:74b210b77b004a677906e0216d44e445'
  ) AS target_rule_rows,
  count(*) FILTER (
    WHERE cbr.normalized_name = 'silence'
      AND cbr.logical_rule_key = 'battle_rule_v1:74b210b77b004a677906e0216d44e445'
      AND cbr.oracle_hash IS NULL
  ) AS target_missing_hash_rows,
  to_regclass('manaloom_deploy_audit.pg077_silence_hash_restore_20260623_061815') IS NOT NULL AS backup_table_already_exists
FROM cards c
JOIN card_battle_rules cbr ON cbr.card_id = c.id
WHERE c.name = 'Silence';

SELECT
  c.name,
  md5(coalesce(c.oracle_text, '')) AS current_oracle_hash,
  c.oracle_text,
  cbr.normalized_name,
  cbr.logical_rule_key,
  cbr.review_status,
  cbr.execution_status,
  cbr.rule_version,
  cbr.oracle_hash,
  cbr.effect_json
FROM cards c
JOIN card_battle_rules cbr ON cbr.card_id = c.id
WHERE c.name = 'Silence'
ORDER BY cbr.logical_rule_key;
