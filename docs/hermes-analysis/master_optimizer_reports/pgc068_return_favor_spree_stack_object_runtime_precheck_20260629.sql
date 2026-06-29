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
    FROM pg_class c
    JOIN pg_namespace n ON n.oid = c.relnamespace
    WHERE n.nspname = 'manaloom_deploy_audit'
      AND c.relname = 'pgc068_return_favor_spree_stack_object_runtime_20260629'
  ) AS backup_table_exists,
  count(*) AS target_rows,
  count(*) FILTER (
    WHERE review_status IN ('active', 'verified')
      AND execution_status = 'auto'
  ) AS trusted_target_rows,
  count(*) FILTER (
    WHERE effect_json->>'battle_model_scope' = 'spree_copy_instant_or_sorcery_stack_spell_change_target_runtime_v1'
  ) AS current_partial_scope_rows,
  count(*) FILTER (
    WHERE effect_json->>'change_target_mode_status' = 'runtime_executor_v1'
  ) AS current_change_target_runtime_rows,
  count(*) FILTER (
    WHERE effect_json->>'spree_additional_cost_status' = 'annotation_only'
  ) AS current_spree_annotation_rows,
  count(*) FILTER (
    WHERE effect_json->>'copy_activated_triggered_ability_status' = 'annotation_only'
  ) AS current_copy_ability_annotation_rows,
  count(*) FILTER (
    WHERE effect_json::text LIKE '%annotation_only%'
  ) AS current_annotation_rows
FROM target_rules;
