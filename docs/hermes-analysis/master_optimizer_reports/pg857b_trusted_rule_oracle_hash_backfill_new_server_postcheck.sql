\echo 'PG857B trusted rule oracle_hash backfill postcheck'

WITH remaining AS (
  SELECT COUNT(*) AS rows
  FROM public.card_battle_rules br
  WHERE br.source IN ('curated', 'manual')
    AND br.review_status = 'verified'
    AND br.execution_status IN ('auto', 'executable')
    AND COALESCE(br.oracle_hash, '') = ''
),
backfilled AS (
  SELECT COUNT(*) AS rows
  FROM public.card_battle_rules br
  JOIN manaloom_deploy_audit.pg857b_trusted_rule_oracle_hash_backfill_new_server_20260713 b
    ON br.card_id = b.card_id
   AND br.normalized_name = b.normalized_name
   AND br.logical_rule_key = b.logical_rule_key
   AND br.source = b.source
   AND br.oracle_hash = b.pg857b_new_oracle_hash
),
backup AS (
  SELECT COUNT(*) AS rows
  FROM manaloom_deploy_audit.pg857b_trusted_rule_oracle_hash_backfill_new_server_20260713
)
SELECT
  (SELECT rows FROM backup) AS backup_rows,
  (SELECT rows FROM backfilled) AS rows_backfilled,
  (SELECT rows FROM remaining) AS trusted_executable_rules_missing_oracle_hash;

SELECT
  b.card_name,
  b.normalized_name,
  b.logical_rule_key,
  b.pg857b_new_oracle_hash AS applied_oracle_hash
FROM manaloom_deploy_audit.pg857b_trusted_rule_oracle_hash_backfill_new_server_20260713 b
ORDER BY b.card_name, b.logical_rule_key;
