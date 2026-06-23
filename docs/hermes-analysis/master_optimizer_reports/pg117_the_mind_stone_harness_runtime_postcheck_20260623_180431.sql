SELECT
  count(*) FILTER (
    WHERE logical_rule_key = 'battle_rule_v1:57bb1f91d9eea2ad14a8e8d24d2f8d53'
      AND review_status IN ('verified', 'active')
      AND execution_status IN ('auto', 'executable')
      AND oracle_hash = '17bda9d167ae2799376387d03be5681f'
  ) AS promoted_rule_rows,
  count(*) FILTER (
    WHERE logical_rule_key = 'battle_rule_v1:57bb1f91d9eea2ad14a8e8d24d2f8d53'
      AND review_status = 'verified'
      AND execution_status = 'auto'
      AND effect_json ->> 'battle_model_scope' = 'legendary_artifact_mana_harness_and_end_step_blink_other_nonland_permanent_v1'
  ) AS promoted_verified_auto_rows
FROM public.card_battle_rules
WHERE normalized_name = 'the mind stone';

SELECT count(*) AS backup_rows
FROM manaloom_deploy_audit.pg117_the_mind_stone_harness_runtime_20260623_180431;

SELECT
  r.normalized_name,
  r.logical_rule_key,
  r.review_status,
  r.execution_status,
  r.rule_version,
  r.oracle_hash,
  r.effect_json,
  r.deck_role_json
FROM public.card_battle_rules r
WHERE r.normalized_name = 'the mind stone'
ORDER BY r.review_status, r.execution_status, r.logical_rule_key;
