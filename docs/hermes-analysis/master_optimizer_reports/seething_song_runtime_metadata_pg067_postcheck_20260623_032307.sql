\pset pager off

SELECT
  count(*) AS target_rows,
  count(*) FILTER (
    WHERE oracle_hash = 'ccd492289c6f1c14c8fb7a248d7bbf32'
      AND review_status IN ('verified', 'active')
      AND execution_status IN ('auto', 'executable')
      AND effect_json->>'effect' = 'ramp_ritual'
      AND effect_json->>'battle_model_scope' = 'single_shot_red_ritual_v1'
      AND effect_json->>'mana_color_status' = 'abstracted_to_generic_pool_runtime'
  ) AS expected_runtime_rows,
  (
    SELECT count(*)
    FROM manaloom_deploy_audit.pg067_seething_song_runtime_metadata_20260623_032307
  ) AS backup_rows,
  jsonb_pretty(jsonb_agg(to_jsonb(card_battle_rules))) AS target_rules
FROM card_battle_rules
WHERE normalized_name = 'seething song'
  AND logical_rule_key = 'battle_rule_v1:3eb15dc581c6b913158f9b63c023f3d7';
