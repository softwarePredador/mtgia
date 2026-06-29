WITH target_rules AS (
  SELECT *
  FROM public.card_battle_rules
  WHERE (
      normalized_name = 'return the favor'
      AND logical_rule_key = 'battle_rule_v1:fb3ee27205e34477fa9753b38433e9a2'
      AND oracle_hash = 'a24911b7ea2027ebba59bb6792eee776'
    )
    OR (
      normalized_name = 'untimely malfunction'
      AND logical_rule_key = 'battle_rule_v1:667ba8e5e69696402f9cd213886e57a8'
      AND oracle_hash = '877f2d75c90c7886ca9536135829bb90'
    )
)
SELECT
  (
    SELECT count(*)
    FROM manaloom_deploy_audit.pgc065_modal_target_change_runtime_20260629
  ) AS backup_rows,
  count(*) AS target_rows,
  count(*) FILTER (
    WHERE normalized_name = 'return the favor'
      AND effect_json->>'change_target_mode_status' = 'runtime_executor_v1'
      AND effect_json->>'target_change_pipeline' = 'single_target_stack_object_redirect_runtime_v1'
  ) AS return_change_target_runtime_rows,
  count(*) FILTER (
    WHERE normalized_name = 'untimely malfunction'
      AND effect_json->>'redirect_target_mode_status' = 'runtime_executor_v1'
      AND effect_json->>'target_change_pipeline' = 'single_target_stack_object_redirect_runtime_v1'
  ) AS untimely_redirect_runtime_rows,
  count(*) FILTER (
    WHERE normalized_name = 'return the favor'
      AND effect_json->>'spree_additional_cost_status' = 'annotation_only'
      AND effect_json->>'copy_activated_triggered_ability_status' = 'annotation_only'
  ) AS return_expected_residual_rows,
  count(*) FILTER (
    WHERE normalized_name = 'untimely malfunction'
      AND effect_json->>'cant_block_mode_status' = 'annotation_only'
  ) AS untimely_expected_residual_rows
FROM target_rules;
