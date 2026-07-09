WITH missing AS (
  SELECT 1
  FROM public.card_battle_rules
  WHERE source = 'curated'
    AND review_status IN ('active', 'verified')
    AND execution_status = 'auto'
    AND coalesce(oracle_hash, '') = ''
),
backup AS (
  SELECT *
  FROM manaloom_deploy_audit.pg679b_trusted_oracle_hash_backfill_backup
),
updated AS (
  SELECT r.card_id, r.logical_rule_key, r.oracle_hash
  FROM public.card_battle_rules r
  JOIN backup b
    ON b.card_id = r.card_id
   AND b.logical_rule_key = r.logical_rule_key
  WHERE r.oracle_hash = b.new_oracle_hash
)
SELECT
  (SELECT count(*) FROM missing) AS trusted_executable_rules_missing_oracle_hash,
  (SELECT count(*) FROM backup) AS backup_rows,
  (SELECT count(*) FROM updated) AS updated_rows;

SELECT
  r.card_name,
  r.normalized_name,
  r.logical_rule_key,
  r.oracle_hash
FROM public.card_battle_rules r
JOIN manaloom_deploy_audit.pg679b_trusted_oracle_hash_backfill_backup b
  ON b.card_id = r.card_id
 AND b.logical_rule_key = r.logical_rule_key
ORDER BY r.card_name, r.logical_rule_key;
