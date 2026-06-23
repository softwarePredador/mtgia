\pset pager off

SELECT
  count(*) AS target_rows,
  count(*) FILTER (WHERE oracle_hash = 'ccd492289c6f1c14c8fb7a248d7bbf32') AS hash_match_rows,
  count(*) FILTER (WHERE effect_json->>'battle_model_scope' = 'single_shot_red_ritual_v1') AS expected_scope_rows,
  count(*) FILTER (WHERE effect_json->>'mana_color_status' = 'abstracted_to_generic_pool_runtime') AS expected_mana_color_status_rows,
  count(*) FILTER (WHERE effect_json->>'oracle_runtime_scope' = 'single_shot_red_ritual_runtime_generic_pool_color_annotation') AS expected_runtime_scope_rows,
  count(*) FILTER (WHERE effect_json->>'pg058_l3b_simple_red_ritual_family' = 'deck6_simple_red_rituals') AS expected_family_rows,
  count(*) FILTER (WHERE review_status = 'verified' AND execution_status = 'auto') AS trusted_auto_rows,
  (SELECT count(*) FROM manaloom_deploy_audit.pg100_seething_song_runtime_metadata_restore_20260623_093907) AS backup_rows
FROM card_battle_rules
WHERE normalized_name = 'seething song'
  AND logical_rule_key = 'battle_rule_v1:3eb15dc581c6b913158f9b63c023f3d7';

SELECT
  card_name,
  logical_rule_key,
  oracle_hash,
  effect_json->>'effect' AS effect,
  effect_json->>'battle_model_scope' AS battle_model_scope,
  effect_json->>'mana_color_status' AS mana_color_status,
  effect_json->>'oracle_runtime_scope' AS oracle_runtime_scope,
  effect_json->>'pg058_l3b_simple_red_ritual_family' AS pg058_family,
  rule_version,
  review_status,
  execution_status
FROM card_battle_rules
WHERE normalized_name = 'seething song'
  AND logical_rule_key = 'battle_rule_v1:3eb15dc581c6b913158f9b63c023f3d7';
