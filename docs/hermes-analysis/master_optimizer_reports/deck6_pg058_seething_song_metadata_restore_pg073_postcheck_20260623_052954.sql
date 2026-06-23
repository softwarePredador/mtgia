\pset pager off

SELECT
  count(*) AS target_rule_rows,
  count(*) FILTER (
    WHERE oracle_hash = 'ccd492289c6f1c14c8fb7a248d7bbf32'
      AND effect_json->>'mana_color_status' = 'abstracted_to_generic_pool_runtime'
      AND effect_json->>'oracle_runtime_scope' = 'single_shot_red_ritual_runtime_generic_pool_color_annotation'
      AND effect_json->>'pg058_l3b_simple_red_ritual_family' = 'deck6_simple_red_rituals'
      AND execution_status = 'auto'
  ) AS expected_runtime_rows,
  count(*) FILTER (
    WHERE effect_json->>'mana_color_status' IS DISTINCT FROM 'abstracted_to_generic_pool_runtime'
      OR effect_json->>'oracle_runtime_scope' IS DISTINCT FROM 'single_shot_red_ritual_runtime_generic_pool_color_annotation'
      OR effect_json->>'pg058_l3b_simple_red_ritual_family' IS DISTINCT FROM 'deck6_simple_red_rituals'
  ) AS target_missing_runtime_metadata_rows,
  (
    SELECT count(*)
    FROM manaloom_deploy_audit.pg073_pg058_seething_song_metadata_restore_20260623_052954
  ) AS backup_rows
FROM card_battle_rules
WHERE normalized_name = 'seething song'
  AND logical_rule_key = 'battle_rule_v1:3eb15dc581c6b913158f9b63c023f3d7';

SELECT
  normalized_name,
  logical_rule_key,
  source,
  review_status,
  execution_status,
  confidence,
  oracle_hash,
  effect_json,
  notes
FROM card_battle_rules
WHERE normalized_name = 'seething song'
  AND logical_rule_key = 'battle_rule_v1:3eb15dc581c6b913158f9b63c023f3d7'
ORDER BY logical_rule_key;
