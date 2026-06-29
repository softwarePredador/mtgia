WITH target_rules AS (
  SELECT *
  FROM public.card_battle_rules
  WHERE normalized_name = 'reiterate'
    AND logical_rule_key = 'battle_rule_v1:18eeabc2a2fa631d99caf65a43a8c405'
    AND oracle_hash = '996fb5f02f16605ff7f1c899f2c50f60'
)
SELECT
  (
    SELECT count(*)
    FROM pg_class c
    JOIN pg_namespace n ON n.oid = c.relnamespace
    WHERE n.nspname = 'manaloom_deploy_audit'
      AND c.relname = 'pgc067_buyback_runtime_20260629'
  ) AS backup_table_exists,
  count(*) AS target_rows,
  count(*) FILTER (
    WHERE review_status IN ('active', 'verified')
      AND execution_status = 'auto'
  ) AS trusted_target_rows,
  count(*) FILTER (
    WHERE effect_json->>'buyback_status' = 'annotation_only'
  ) AS current_buyback_annotation_rows,
  count(*) FILTER (
    WHERE effect_json->>'buyback_status' = 'runtime_executor_v1'
  ) AS current_buyback_runtime_rows,
  count(*) FILTER (
    WHERE effect_json::text LIKE '%annotation_only%'
  ) AS current_annotation_rows
FROM target_rules;
