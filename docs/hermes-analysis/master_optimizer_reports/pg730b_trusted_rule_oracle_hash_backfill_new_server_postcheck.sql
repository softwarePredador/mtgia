\echo 'PG730b trusted rule oracle_hash backfill postcheck'

WITH backup AS (
  SELECT normalized_name, logical_rule_key
  FROM manaloom_deploy_audit.pg730b_trusted_rule_oracle_hash_backfill_20260711
)
SELECT
  count(*) AS backfilled_rows,
  count(*) FILTER (WHERE coalesce(r.oracle_hash, '') <> '') AS rows_with_oracle_hash,
  count(*) FILTER (WHERE r.review_status IN ('verified', 'active') AND r.execution_status = 'auto') AS trusted_auto_rows,
  count(*) FILTER (
    WHERE coalesce(r.oracle_hash, '') <> ''
      AND EXISTS (
        SELECT 1
        FROM public.cards c
        WHERE (
          r.card_id = c.id
          OR r.normalized_name = lower(trim(c.name))
          OR r.normalized_name = lower(trim(split_part(c.name, ' // ', 1)))
        )
          AND coalesce(c.oracle_text, '') <> ''
          AND md5(c.oracle_text) = r.oracle_hash
      )
  ) AS rows_matching_current_oracle_hash
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
