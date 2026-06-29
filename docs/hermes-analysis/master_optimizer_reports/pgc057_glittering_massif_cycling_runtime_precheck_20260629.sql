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
  WHERE normalized_name = 'glittering massif'
    AND logical_rule_key = 'battle_rule_v1:603c776839827f2f21cef8b62e22a1be'
)
SELECT
  count(*) AS target_rows,
  count(*) FILTER (
    WHERE review_status = 'verified'
      AND execution_status = 'auto'
      AND oracle_hash = '71d8d9152563d51114543ed1a9289903'
  ) AS trusted_target_rows,
  count(*) FILTER (
    WHERE effect_json ->> 'cycling_status' = 'annotation_only'
  ) AS current_annotation_rows,
  count(*) FILTER (
    WHERE effect_json ->> 'cycling_cost' = '{2}'
  ) AS current_cycling_cost_rows,
  CASE
    WHEN to_regclass('manaloom_deploy_audit.pgc057_glittering_massif_cycling_runtime_20260629') IS NULL
      THEN 0
    ELSE 1
  END AS backup_table_exists
FROM target;
