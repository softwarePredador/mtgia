WITH missing AS (
  SELECT b.normalized_name, b.card_name, b.logical_rule_key
  FROM card_battle_rules b
  WHERE b.execution_status IN ('auto', 'executable')
    AND b.review_status IN ('verified', 'active')
    AND coalesce(b.oracle_hash, '') = ''
),
backup AS (
  SELECT count(*) AS backup_rows
  FROM manaloom_deploy_audit.pg693_trusted_rule_oracle_hash_backfill_backup
)
SELECT
  (SELECT count(*) FROM missing) AS trusted_executable_rules_missing_oracle_hash,
  (SELECT backup_rows FROM backup) AS backup_rows;

SELECT
  b.normalized_name,
  b.card_name,
  b.logical_rule_key,
  b.oracle_hash,
  md5(coalesce(c.oracle_text, '')) AS expected_oracle_hash
FROM card_battle_rules b
JOIN cards c ON c.id = b.card_id
JOIN manaloom_deploy_audit.pg693_trusted_rule_oracle_hash_backfill_backup backup
  ON backup.normalized_name = b.normalized_name
 AND backup.logical_rule_key = b.logical_rule_key
ORDER BY b.normalized_name, b.logical_rule_key;
