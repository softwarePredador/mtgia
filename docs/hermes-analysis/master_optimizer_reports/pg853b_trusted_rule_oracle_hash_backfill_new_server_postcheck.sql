\echo 'PG853B trusted rule oracle_hash backfill postcheck'

WITH remaining AS (
  SELECT count(*) AS rows
  FROM card_battle_rules br
  JOIN cards c ON c.id = br.card_id
  WHERE br.source IN ('curated', 'manual')
    AND br.review_status IN ('verified', 'active')
    AND br.execution_status IN ('auto', 'executable')
    AND COALESCE(br.oracle_hash, '') = ''
),
backup AS (
  SELECT count(*) AS rows
  FROM manaloom_deploy_audit.pg853b_trusted_rule_oracle_hash_backfill_new_server_20260712
),
updated AS (
  SELECT count(*) AS rows
  FROM card_battle_rules br
  JOIN manaloom_deploy_audit.pg853b_trusted_rule_oracle_hash_backfill_new_server_20260712 b
    ON b.card_id = br.card_id
   AND b.normalized_name = br.normalized_name
   AND b.logical_rule_key = br.logical_rule_key
   AND b.source = br.source
  WHERE br.oracle_hash = b.new_oracle_hash
)
SELECT
  (SELECT rows FROM remaining) AS trusted_executable_rules_missing_oracle_hash,
  (SELECT rows FROM backup) AS backup_rows,
  (SELECT rows FROM updated) AS updated_rows_with_current_oracle_hash;
