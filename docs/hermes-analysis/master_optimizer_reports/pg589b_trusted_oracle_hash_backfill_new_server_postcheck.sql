WITH residual AS (
  SELECT count(*) AS missing_hash_rows
  FROM card_battle_rules
  WHERE source IN ('curated', 'manual')
    AND review_status IN ('verified', 'active')
    AND execution_status IN ('auto', 'executable')
    AND coalesce(oracle_hash, '') = ''
),
backup AS (
  SELECT count(*) AS backup_rows
  FROM manaloom_deploy_audit.pg589b_trusted_oracle_hash_backfill_backup
),
verified AS (
  SELECT count(*) AS verified_rows
  FROM card_battle_rules r
  JOIN manaloom_deploy_audit.pg589b_trusted_oracle_hash_backfill_backup b
    ON b.card_id = r.card_id
   AND b.logical_rule_key = r.logical_rule_key
  WHERE r.oracle_hash = b.new_oracle_hash
)
SELECT
  residual.missing_hash_rows,
  backup.backup_rows,
  verified.verified_rows
FROM residual, backup, verified;

SELECT
  r.card_name,
  r.normalized_name,
  r.logical_rule_key,
  r.review_status,
  r.execution_status,
  r.rule_version,
  r.oracle_hash
FROM card_battle_rules r
JOIN manaloom_deploy_audit.pg589b_trusted_oracle_hash_backfill_backup b
  ON b.card_id = r.card_id
 AND b.logical_rule_key = r.logical_rule_key
ORDER BY r.normalized_name, r.logical_rule_key
LIMIT 60;
