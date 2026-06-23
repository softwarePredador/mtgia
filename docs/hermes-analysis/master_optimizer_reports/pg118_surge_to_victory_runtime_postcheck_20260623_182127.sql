SELECT
  count(*) FILTER (
    WHERE logical_rule_key = 'battle_rule_v1:44a0c5f4d0c51f52db6a36d12f9db98e'
      AND review_status IN ('verified', 'active')
      AND execution_status IN ('auto', 'executable')
      AND oracle_hash = '5381f78ff0798b9afad371e0fa495831'
  ) AS promoted_rule_rows,
  count(*) FILTER (
    WHERE logical_rule_key = 'battle_rule_v1:44a0c5f4d0c51f52db6a36d12f9db98e'
      AND review_status = 'verified'
      AND execution_status = 'auto'
      AND effect_json ->> 'battle_model_scope' = 'graveyard_spell_exile_team_pump_combat_damage_copy_cast_until_eot_v1'
  ) AS promoted_verified_auto_rows,
  count(*) FILTER (
    WHERE logical_rule_key IN (
      'battle_rule_v1:4ea05a4d2ce8454073d85afff5e3f790',
      'battle_rule_v1:cc95729e96832afbdb1eb194ec6212d4'
    )
      AND review_status = 'deprecated'
      AND execution_status = 'disabled'
  ) AS deprecated_legacy_rows
FROM public.card_battle_rules
WHERE normalized_name = 'surge to victory';

SELECT count(*) AS backup_rows
FROM manaloom_deploy_audit.pg118_surge_to_victory_runtime_20260623_182127;

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
WHERE r.normalized_name = 'surge to victory'
ORDER BY r.review_status, r.execution_status, r.logical_rule_key;
