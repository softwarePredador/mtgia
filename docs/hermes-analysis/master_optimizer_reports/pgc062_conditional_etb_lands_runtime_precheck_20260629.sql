WITH target AS (
  SELECT
    normalized_name,
    logical_rule_key,
    oracle_hash,
    rule_version,
    review_status,
    execution_status,
    effect_json
  FROM public.card_battle_rules
  WHERE logical_rule_key = 'battle_rule_v1:603c776839827f2f21cef8b62e22a1be'
    AND normalized_name IN ('clifftop retreat', 'inspiring vantage', 'sundown pass')
)
SELECT
  count(*) AS target_rows,
  count(*) FILTER (
    WHERE review_status = 'verified'
      AND execution_status = 'auto'
      AND (
        (normalized_name = 'clifftop retreat'
          AND oracle_hash = '48ea345a9823024a12c03d458106af4e')
        OR
        (normalized_name = 'inspiring vantage'
          AND oracle_hash = 'eb2813246000c2c0bfe218cb61fed144')
        OR
        (normalized_name = 'sundown pass'
          AND oracle_hash = '2f86ee5bc9a587b6a45b4eddf98e663c')
      )
  ) AS trusted_target_rows,
  count(*) FILTER (
    WHERE effect_json ->> 'conditional_enters_tapped_status' = 'annotation_only'
  ) AS current_conditional_etb_annotation_rows,
  CASE
    WHEN to_regclass('manaloom_deploy_audit.pgc062_conditional_etb_lands_runtime_20260629') IS NULL
      THEN 0
    ELSE 1
  END AS backup_table_exists
FROM target;
