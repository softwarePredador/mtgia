WITH missing AS (
  SELECT COUNT(*) AS missing_hash_rules
  FROM public.card_battle_rules
  WHERE source IN ('curated', 'manual')
    AND review_status IN ('verified', 'active')
    AND execution_status IN ('auto', 'executable')
    AND COALESCE(oracle_hash, '') = ''
),
backup AS (
  SELECT COUNT(*) AS backup_rows
  FROM manaloom_deploy_audit.pg604b_trusted_rule_oracle_hash_backfill_new_server_backup
),
sample AS (
  SELECT
    r.card_name,
    r.normalized_name,
    r.logical_rule_key,
    r.oracle_hash
  FROM public.card_battle_rules r
  JOIN manaloom_deploy_audit.pg604b_trusted_rule_oracle_hash_backfill_new_server_backup b
    ON b.card_id = r.card_id
   AND b.logical_rule_key = r.logical_rule_key
  ORDER BY r.normalized_name, r.logical_rule_key
  LIMIT 50
)
SELECT
  (SELECT missing_hash_rules FROM missing) AS trusted_executable_rules_missing_oracle_hash,
  (SELECT backup_rows FROM backup) AS backup_rows,
  COUNT(*) AS checked_sample_rows,
  COUNT(*) FILTER (WHERE COALESCE(oracle_hash, '') <> '') AS checked_sample_rows_with_hash
FROM sample;
