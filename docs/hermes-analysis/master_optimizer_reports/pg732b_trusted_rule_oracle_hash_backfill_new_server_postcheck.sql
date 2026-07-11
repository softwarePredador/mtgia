SELECT
  COUNT(*) AS trusted_executable_rules_missing_oracle_hash
FROM card_battle_rules br
JOIN cards c ON c.id = br.card_id
WHERE br.execution_status = 'auto'
  AND br.review_status IN ('verified', 'active')
  AND COALESCE(br.oracle_hash, '') = ''
  AND COALESCE(BTRIM(c.oracle_text), '') <> '';

SELECT
  COUNT(*) AS backup_rows
FROM manaloom_deploy_audit.pg732b_trusted_rule_oracle_hash_backfill_new_server_20260711;

SELECT
  COUNT(*) AS backfilled_rows_matching_card_oracle_hash
FROM manaloom_deploy_audit.pg732b_trusted_rule_oracle_hash_backfill_new_server_20260711 backup
JOIN card_battle_rules br
  ON br.normalized_name = backup.normalized_name
 AND br.logical_rule_key = backup.logical_rule_key
JOIN cards c ON c.id = br.card_id
WHERE br.oracle_hash = md5(c.oracle_text);
