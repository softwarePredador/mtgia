WITH target_rules AS (
  SELECT *
  FROM public.card_battle_rules
  WHERE normalized_name = 'return the favor'
    AND logical_rule_key = 'battle_rule_v1:fb3ee27205e34477fa9753b38433e9a2'
    AND oracle_hash = 'a24911b7ea2027ebba59bb6792eee776'
)
SELECT
  (
    SELECT count(*)
    FROM manaloom_deploy_audit.pgc068_return_favor_spree_stack_object_runtime_20260629
  ) AS backup_rows,
  count(*) AS target_rows,
  count(*) FILTER (
    WHERE effect_json->>'battle_model_scope' = 'spree_copy_stack_object_change_target_selected_mode_runtime_v1'
      AND effect_json->>'target' = 'stack_object'
      AND effect_json->>'spree_additional_cost_status' = 'runtime_executor_v1'
      AND effect_json->>'spree_selected_mode_cost_status' = 'runtime_executor_v1'
      AND effect_json->'spree_mode_costs'->>'copy_instant_or_sorcery_spell' = '{1}'
      AND effect_json->'spree_mode_costs'->>'change_single_target' = '{1}'
      AND effect_json->>'copy_activated_triggered_ability_status' = 'runtime_executor_v1'
      AND effect_json->>'change_target_mode_status' = 'runtime_executor_v1'
      AND effect_json->>'target_change_pipeline' = 'single_target_stack_object_redirect_runtime_v1'
  ) AS return_favor_runtime_rows,
  count(*) FILTER (
    WHERE effect_json::text LIKE '%annotation_only%'
  ) AS remaining_annotation_rows
FROM target_rules;
