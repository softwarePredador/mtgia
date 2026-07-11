\echo 'PG744B trusted rule oracle_hash backfill postcheck'

SELECT
  COUNT(*) AS trusted_executable_rules_missing_oracle_hash
FROM card_battle_rules
WHERE source IN ('curated', 'manual')
  AND review_status IN ('verified', 'active')
  AND execution_status IN ('auto', 'executable')
  AND COALESCE(oracle_hash, '') = '';

SELECT
  COUNT(*) AS backup_rows
FROM manaloom_deploy_audit.pg744b_trusted_rule_oracle_hash_backfill_new_server_20260711;

SELECT
  COUNT(*) AS backfilled_rows_matching_card_oracle_hash
FROM manaloom_deploy_audit.pg744b_trusted_rule_oracle_hash_backfill_new_server_20260711 backup
JOIN card_battle_rules br
  ON br.card_id = backup.card_id
 AND br.normalized_name = backup.normalized_name
 AND br.logical_rule_key = backup.logical_rule_key
 AND br.source = backup.source
JOIN cards c ON c.id = br.card_id
WHERE br.oracle_hash = md5(c.oracle_text);
