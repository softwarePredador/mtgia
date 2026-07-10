SELECT
  count(*) AS trusted_executable_rules_missing_oracle_hash
FROM public.card_battle_rules
WHERE review_status IN ('verified', 'active')
  AND execution_status = 'auto'
  AND coalesce(btrim(oracle_hash), '') = '';

SELECT
  count(*) AS backup_rows
FROM manaloom_deploy_audit.pg724b_trusted_oracle_hash_backfill_new_server_20260710;

WITH backup AS (
  SELECT normalized_name, logical_rule_key
  FROM manaloom_deploy_audit.pg724b_trusted_oracle_hash_backfill_new_server_20260710
),
updated AS (
  SELECT br.normalized_name, br.logical_rule_key, br.oracle_hash
  FROM public.card_battle_rules br
  JOIN backup b
    ON b.normalized_name = br.normalized_name
   AND b.logical_rule_key = br.logical_rule_key
)
SELECT
  count(*) AS updated_rows_from_backup_set,
  count(*) FILTER (WHERE coalesce(btrim(oracle_hash), '') <> '') AS updated_rows_with_oracle_hash
FROM updated;
