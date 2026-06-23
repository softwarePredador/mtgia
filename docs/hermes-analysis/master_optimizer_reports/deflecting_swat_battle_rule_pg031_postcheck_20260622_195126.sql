\pset pager off

SELECT
  'pg031_deflecting_swat_postcheck_counts' AS check_name,
  (
    SELECT count(*)
    FROM card_battle_rules
    WHERE normalized_name = 'deflecting swat'
      AND logical_rule_key = 'battle_rule_v1:bac48343654a53205d790a8268bd2631'
      AND effect_json->>'effect' = 'redirect_removal'
      AND effect_json->>'battle_model_scope' =
        'deflecting_swat_control_commander_free_redirect_target_spell_or_ability_v1'
      AND effect_json->>'free_if_control_commander' = 'true'
      AND effect_json->>'alternative_cost' = '{0}'
      AND effect_json->>'alternative_cost_condition' = 'control_commander'
      AND effect_json->>'runtime_scope' = 'single_target_targeted_removal_spell'
      AND effect_json->>'ability_targets_runtime' = 'annotation_only'
      AND review_status = 'active'
      AND execution_status = 'auto'
      AND source = 'curated'
      AND oracle_hash = 'a34c89817f87f32bedfb3d66a5bdc672'
  ) AS exact_executable_rule_rows,
  (
    SELECT count(*)
    FROM card_battle_rules
    WHERE normalized_name = 'deflecting swat'
      AND logical_rule_key <> 'battle_rule_v1:bac48343654a53205d790a8268bd2631'
      AND effect_json->>'effect' IN ('redirect_removal', 'draw_cards')
      AND review_status NOT IN ('rejected', 'deprecated')
      AND execution_status IN ('auto', 'executable', 'review_only')
  ) AS legacy_enabled_redirect_or_shadow_rows;

SELECT
  'pg031_deflecting_swat_rule_postcheck' AS check_name,
  card_name,
  logical_rule_key,
  effect_json,
  deck_role_json,
  source,
  confidence,
  review_status,
  execution_status,
  oracle_hash,
  reviewed_by,
  reviewed_at
FROM card_battle_rules
WHERE normalized_name = 'deflecting swat'
ORDER BY source, review_status, execution_status, logical_rule_key;

SELECT
  'pg031_deflecting_swat_snapshot_postcheck' AS check_name,
  name,
  function_tags,
  battle_rules
FROM card_intelligence_snapshot
WHERE lower(name) = 'deflecting swat';
