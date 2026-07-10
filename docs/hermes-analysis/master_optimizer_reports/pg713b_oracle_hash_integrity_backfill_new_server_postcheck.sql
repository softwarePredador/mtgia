WITH backup AS (
  SELECT normalized_name, logical_rule_key
  FROM manaloom_deploy_audit.pg713b_oracle_hash_integrity_backfill_20260710
)
SELECT
  count(*) AS backfilled_rows,
  count(*) FILTER (WHERE coalesce(r.oracle_hash, '') <> '') AS rows_with_oracle_hash,
  count(*) FILTER (WHERE r.review_status IN ('verified', 'active') AND r.execution_status = 'auto') AS trusted_auto_rows
FROM backup b
JOIN public.card_battle_rules r
  ON r.normalized_name = b.normalized_name
 AND r.logical_rule_key = b.logical_rule_key;

SELECT
  count(*) AS remaining_trusted_auto_missing_hash_rows
FROM public.card_battle_rules
WHERE review_status IN ('verified', 'active')
  AND execution_status = 'auto'
  AND coalesce(oracle_hash, '') = '';
