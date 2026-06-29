WITH target_rules AS (
  SELECT *
  FROM public.card_battle_rules
  WHERE (
      normalized_name = 'dualcaster mage'
      AND logical_rule_key = 'battle_rule_v1:e176019b87d68d22e2388e08a4efbf55'
      AND oracle_hash = 'e26f613394b72e9724d299512983218a'
    )
    OR (
      normalized_name = 'reverberate'
      AND logical_rule_key = 'battle_rule_v1:0269136edf067f696c8576740b720e14'
      AND oracle_hash = 'cbae05dee4261e3ed5412fd5f3591c17'
    )
    OR (
      normalized_name = 'reiterate'
      AND logical_rule_key = 'battle_rule_v1:18eeabc2a2fa631d99caf65a43a8c405'
      AND oracle_hash = '996fb5f02f16605ff7f1c899f2c50f60'
    )
)
SELECT
  (
    SELECT count(*)
    FROM manaloom_deploy_audit.pgc064_copy_spell_choose_new_targets_runtime_20260629
  ) AS backup_rows,
  count(*) AS target_rows,
  count(*) FILTER (
    WHERE review_status IN ('active', 'verified')
      AND execution_status = 'auto'
      AND effect_json->>'choose_new_targets_status' = 'runtime_executor_v1'
      AND effect_json->>'copy_target_selection_status' = 'runtime_executor_v1'
      AND effect_json->>'copy_target_selection_pipeline' = 'copy_spell_runtime_choose_new_targets_v1'
  ) AS choose_new_targets_runtime_rows,
  count(*) FILTER (
    WHERE normalized_name IN ('dualcaster mage', 'reverberate')
      AND effect_json::text NOT LIKE '%annotation_only%'
  ) AS clean_promoted_rows,
  count(*) FILTER (
    WHERE normalized_name = 'reiterate'
      AND effect_json->>'buyback_status' = 'annotation_only'
      AND effect_json->>'choose_new_targets_status' = 'runtime_executor_v1'
  ) AS reiterate_runtime_choose_targets_buyback_residual_rows,
  count(*) FILTER (
    WHERE normalized_name = 'dualcaster mage'
      AND effect_json->>'battle_model_scope' = 'creature_etb_copy_stack_instant_or_sorcery_new_targets_runtime_v1'
  ) AS dualcaster_runtime_rows,
  count(*) FILTER (
    WHERE normalized_name = 'reverberate'
      AND effect_json->>'battle_model_scope' = 'copy_stack_instant_or_sorcery_new_targets_runtime_v1'
  ) AS reverberate_runtime_rows,
  count(*) FILTER (
    WHERE normalized_name = 'reiterate'
      AND effect_json->>'battle_model_scope' = 'copy_stack_instant_or_sorcery_new_targets_runtime_buyback_annotation_v1'
  ) AS reiterate_runtime_rows
FROM target_rules;
