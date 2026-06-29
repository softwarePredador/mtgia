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
    FROM manaloom_deploy_audit.pgc067_buyback_runtime_20260629
  ) AS backup_rows,
  count(*) AS target_rows,
  count(*) FILTER (
    WHERE effect_json->>'battle_model_scope' = 'copy_stack_instant_or_sorcery_new_targets_runtime_buyback_runtime_v1'
      AND effect_json->>'buyback_status' = 'runtime_executor_v1'
      AND effect_json->>'buyback_cost' = '{3}'
      AND effect_json->>'choose_new_targets_status' = 'runtime_executor_v1'
      AND effect_json->>'copy_target_selection_status' = 'runtime_executor_v1'
  ) AS reiterate_buyback_runtime_rows,
  count(*) FILTER (
    WHERE effect_json::text LIKE '%annotation_only%'
  ) AS remaining_annotation_rows
FROM target_rules;
