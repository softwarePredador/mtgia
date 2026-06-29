SELECT
  count(*) AS target_rows,
  count(*) FILTER (
    WHERE effect_json ->> 'cycling_status' = 'runtime_executor_v1'
      AND effect_json ->> 'cycling_cost' = '{2}'
      AND effect_json ->> 'cycling_draw_count' = '1'
      AND effect_json ->> 'cycling_discard_self_status' = 'runtime_executor_v1'
  ) AS cycling_runtime_rows,
  count(*) FILTER (
    WHERE effect_json ->> 'battle_model_scope' = 'land_enters_tapped_mana_source_with_cycling_runtime_v1'
      AND effect_json ->> 'oracle_runtime_scope' = 'mountain_plains_enters_tapped_red_white_mana_and_cycling_two_runtime_v1'
  ) AS scope_rows,
  count(*) FILTER (
    WHERE rule_version >= 2
      AND reviewed_by = 'codex-pgc057'
  ) AS reviewed_version_rows,
  (
    SELECT count(*)
    FROM manaloom_deploy_audit.pgc057_glittering_massif_cycling_runtime_20260629
  ) AS backup_rows
FROM public.card_battle_rules
WHERE normalized_name = 'glittering massif'
  AND logical_rule_key = 'battle_rule_v1:603c776839827f2f21cef8b62e22a1be';
