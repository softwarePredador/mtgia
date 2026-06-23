\pset pager off

SELECT
  count(*) FILTER (
    WHERE normalized_name = 'seething song'
      AND logical_rule_key = 'battle_rule_v1:3eb15dc581c6b913158f9b63c023f3d7'
      AND oracle_hash = 'ccd492289c6f1c14c8fb7a248d7bbf32'
      AND effect_json->>'battle_model_scope' = 'single_shot_red_ritual_v1'
      AND effect_json->>'mana_color_status' = 'abstracted_to_generic_pool_runtime'
      AND effect_json->>'oracle_runtime_scope' = 'single_shot_red_ritual_runtime_generic_pool_color_annotation'
      AND effect_json->>'pg058_l3b_simple_red_ritual_family' = 'deck6_simple_red_rituals'
  ) AS seething_metadata_restored_rows,
  count(*) FILTER (
    WHERE normalized_name = 'seething song'
      AND review_status = 'needs_review'
      AND execution_status <> 'disabled'
  ) AS active_needs_review_shadow_rows,
  (SELECT count(*) FROM manaloom_deploy_audit.pg070_deck6_l2_hash_only_runtime_rules_20260623_011859) AS backup_rows
FROM card_battle_rules
WHERE normalized_name = 'seething song';

SELECT
  card_name,
  normalized_name,
  logical_rule_key,
  oracle_hash,
  effect_json,
  notes
FROM card_battle_rules
WHERE normalized_name = 'seething song'
ORDER BY logical_rule_key;
