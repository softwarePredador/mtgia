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
    FROM pg_class c
    JOIN pg_namespace n ON n.oid = c.relnamespace
    WHERE n.nspname = 'manaloom_deploy_audit'
      AND c.relname = 'pgc064_copy_spell_choose_new_targets_runtime_20260629'
  ) AS backup_table_exists,
  count(*) AS target_rows,
  count(*) FILTER (
    WHERE review_status IN ('active', 'verified')
      AND execution_status = 'auto'
  ) AS trusted_target_rows,
  count(*) FILTER (
    WHERE effect_json->>'effect' = 'copy_spell'
      AND effect_json->>'target' = 'instant_or_sorcery_on_stack'
  ) AS copy_spell_stack_target_rows,
  count(*) FILTER (
    WHERE effect_json->>'may_choose_new_targets' = 'true'
      AND effect_json->>'choose_new_targets_status' = 'annotation_only'
  ) AS choose_new_targets_annotation_rows,
  count(*) FILTER (
    WHERE normalized_name = 'reiterate'
      AND effect_json->>'buyback_status' = 'annotation_only'
  ) AS expected_reiterate_buyback_annotation_rows,
  count(*) FILTER (
    WHERE effect_json::text LIKE '%annotation_only%'
  ) AS current_annotation_rows
FROM target_rules;
