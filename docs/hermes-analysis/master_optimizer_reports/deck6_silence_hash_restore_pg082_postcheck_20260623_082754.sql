\pset pager off

SELECT
  count(*) AS target_rows,
  count(*) FILTER (WHERE cbr.oracle_hash = 'a0ca3c09a7db091c435ab31adb9c1780') AS target_hash_match_rows,
  count(*) FILTER (WHERE cbr.oracle_hash IS NULL OR cbr.oracle_hash = '') AS missing_hash_rows,
  count(*) FILTER (WHERE cbr.effect_json->>'battle_model_scope' = 'silence_until_eot_v1') AS expected_scope_rows,
  count(*) FILTER (WHERE cbr.effect_json->>'oracle_runtime_scope' = 'opponent_spell_cast_lock_until_eot_runtime') AS expected_runtime_scope_rows,
  count(*) FILTER (WHERE cbr.review_status = 'verified' AND cbr.execution_status = 'auto') AS trusted_auto_rows,
  count(*) FILTER (WHERE cbr.rule_version >= 2) AS rule_version_at_least_2_rows,
  (SELECT count(*) FROM manaloom_deploy_audit.pg082_deck6_silence_hash_restore_20260623_082754) AS backup_rows
FROM card_battle_rules cbr
WHERE cbr.normalized_name = 'silence'
  AND cbr.logical_rule_key = 'battle_rule_v1:74b210b77b004a677906e0216d44e445';

SELECT
  c.name,
  cbr.logical_rule_key,
  cbr.oracle_hash,
  cbr.effect_json->>'effect' AS effect,
  cbr.effect_json->>'battle_model_scope' AS battle_model_scope,
  cbr.effect_json->>'oracle_runtime_scope' AS oracle_runtime_scope,
  cbr.rule_version,
  cbr.review_status,
  cbr.execution_status
FROM cards c
JOIN card_battle_rules cbr
  ON cbr.card_id = c.id
WHERE c.name = 'Silence'
  AND cbr.logical_rule_key = 'battle_rule_v1:74b210b77b004a677906e0216d44e445';
