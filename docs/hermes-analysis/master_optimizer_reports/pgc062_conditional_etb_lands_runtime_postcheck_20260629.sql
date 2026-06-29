SELECT
  count(*) AS target_rows,
  count(*) FILTER (
    WHERE normalized_name = 'clifftop retreat'
      AND effect_json ->> 'conditional_enters_tapped_status' = 'runtime_executor_v1'
      AND effect_json ->> 'conditional_enters_tapped_profile' = 'checkland'
      AND effect_json ->> 'battle_model_scope' = 'check_land_dual_source_etb_runtime_v1'
      AND rule_version >= 2
      AND reviewed_by = 'codex-pgc062'
  ) AS clifftop_runtime_rows,
  count(*) FILTER (
    WHERE normalized_name = 'inspiring vantage'
      AND effect_json ->> 'conditional_enters_tapped_status' = 'runtime_executor_v1'
      AND effect_json ->> 'conditional_enters_tapped_profile' = 'fastland'
      AND effect_json ->> 'battle_model_scope' = 'fastland_dual_source_etb_runtime_v1'
      AND (effect_json ->> 'enters_tapped_if_control_lands_min')::integer = 3
      AND rule_version >= 2
      AND reviewed_by = 'codex-pgc062'
  ) AS inspiring_runtime_rows,
  count(*) FILTER (
    WHERE normalized_name = 'sundown pass'
      AND effect_json ->> 'conditional_enters_tapped_status' = 'runtime_executor_v1'
      AND effect_json ->> 'conditional_enters_tapped_profile' = 'slowland'
      AND effect_json ->> 'battle_model_scope' = 'slowland_dual_source_etb_runtime_v1'
      AND (effect_json ->> 'enters_tapped_unless_control_lands_min')::integer = 2
      AND rule_version >= 2
      AND reviewed_by = 'codex-pgc062'
  ) AS sundown_runtime_rows,
  (
    SELECT count(*)
    FROM manaloom_deploy_audit.pgc062_conditional_etb_lands_runtime_20260629
  ) AS backup_rows
FROM public.card_battle_rules
WHERE logical_rule_key = 'battle_rule_v1:603c776839827f2f21cef8b62e22a1be'
  AND normalized_name IN ('clifftop retreat', 'inspiring vantage', 'sundown pass');
