\pset pager off

SELECT
  'pg034_lightning_greaves_postcheck_counts' AS check_name,
  (
    SELECT count(*)
    FROM card_battle_rules
    WHERE normalized_name = 'lightning greaves'
      AND logical_rule_key = 'battle_rule_v1:5ea7f2a8349a93ea46e05b60ee8cdaac'
      AND effect_json->>'effect' = 'equipment_haste_shroud'
      AND effect_json->>'battle_model_scope' =
        'lightning_greaves_auto_attach_haste_shroud_equip_0_v1'
      AND effect_json->>'attach_model' = 'auto_attach_best_creature_on_resolution'
      AND effect_json->>'target' = 'creature_you_control'
      AND review_status = 'active'
      AND execution_status = 'auto'
      AND source = 'curated'
      AND oracle_hash = '4a4c71d3cc58637cf00a3d7fe2331353'
  ) AS exact_executable_rule_rows,
  (
    SELECT count(*)
    FROM card_battle_rules
    WHERE normalized_name = 'lightning greaves'
      AND logical_rule_key <> 'battle_rule_v1:5ea7f2a8349a93ea46e05b60ee8cdaac'
      AND effect_json->>'effect' IN ('equipment_haste_shroud', 'indestructible')
      AND review_status NOT IN ('rejected', 'deprecated')
      AND execution_status IN ('auto', 'executable', 'review_only')
  ) AS legacy_enabled_equipment_or_shadow_rows;

SELECT
  'pg034_lightning_greaves_rule_postcheck' AS check_name,
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
WHERE normalized_name = 'lightning greaves'
ORDER BY source, review_status, execution_status, logical_rule_key;

SELECT
  'pg034_lightning_greaves_snapshot_postcheck' AS check_name,
  name,
  function_tags,
  battle_rules
FROM card_intelligence_snapshot
WHERE lower(name) = 'lightning greaves';
