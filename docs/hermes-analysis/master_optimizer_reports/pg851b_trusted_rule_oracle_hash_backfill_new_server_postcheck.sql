\echo 'PG851B trusted rule oracle_hash backfill postcheck'

WITH backup AS (
  SELECT *
  FROM manaloom_deploy_audit.pg851b_trusted_rule_oracle_hash_backfill_new_server_20260712
),
remaining AS (
  SELECT COUNT(*) AS rows
  FROM public.card_battle_rules br
  WHERE br.source IN ('curated', 'manual')
    AND br.review_status = 'verified'
    AND br.execution_status IN ('auto', 'executable')
    AND COALESCE(br.oracle_hash, '') = ''
),
updated AS (
  SELECT COUNT(*) AS rows
  FROM public.card_battle_rules br
  JOIN backup b
    ON b.card_id = br.card_id
   AND b.normalized_name = br.normalized_name
   AND b.logical_rule_key = br.logical_rule_key
   AND b.source = br.source
  WHERE br.oracle_hash = b.pg851b_new_oracle_hash
)
SELECT
  (SELECT rows FROM remaining) AS verified_executable_rules_missing_oracle_hash,
  (SELECT COUNT(*) FROM backup) AS backup_rows,
  (SELECT rows FROM updated) AS updated_rows_with_current_oracle_hash;

SELECT
  br.card_name,
  br.normalized_name,
  br.source,
  br.review_status,
  br.execution_status,
  br.logical_rule_key
FROM public.card_battle_rules br
WHERE br.source IN ('curated', 'manual')
  AND br.review_status = 'verified'
  AND br.execution_status IN ('auto', 'executable')
  AND COALESCE(br.oracle_hash, '') = ''
ORDER BY br.card_name, br.logical_rule_key
LIMIT 80;
