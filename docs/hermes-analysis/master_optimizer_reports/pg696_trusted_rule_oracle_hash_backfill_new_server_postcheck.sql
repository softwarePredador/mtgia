\echo 'PG696 trusted rule oracle_hash backfill postcheck'

SELECT
  count(*) AS remaining_trusted_executable_missing_hash_rows
FROM public.card_battle_rules b
WHERE b.execution_status IN ('auto', 'executable')
  AND b.review_status IN ('verified', 'active')
  AND coalesce(b.oracle_hash, '') = '';

SELECT
  count(*) AS backup_rows,
  count(*) FILTER (WHERE b.oracle_hash = backup.new_oracle_hash) AS backfilled_rows_with_expected_hash
FROM manaloom_deploy_audit.pg696_trusted_rule_oracle_hash_backfill_new_server_20260709 backup
JOIN public.card_battle_rules b
  ON b.normalized_name = backup.normalized_name
 AND b.logical_rule_key = backup.logical_rule_key;

SELECT
  b.card_name,
  b.normalized_name,
  b.logical_rule_key,
  b.oracle_hash,
  backup.new_oracle_hash AS expected_oracle_hash
FROM manaloom_deploy_audit.pg696_trusted_rule_oracle_hash_backfill_new_server_20260709 backup
JOIN public.card_battle_rules b
  ON b.normalized_name = backup.normalized_name
 AND b.logical_rule_key = backup.logical_rule_key
ORDER BY b.normalized_name, b.logical_rule_key;
