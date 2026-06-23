\pset pager off

SELECT
  'pg033_land_tax_postcheck_counts' AS check_name,
  (
    SELECT count(*)
    FROM card_battle_rules
    WHERE normalized_name = 'land tax'
      AND logical_rule_key = 'battle_rule_v1:e3f5f35c6a9ee4fd8c7b9972c4152bef'
      AND effect_json->>'effect' = 'land_tax'
      AND effect_json->>'battle_model_scope' =
        'land_tax_upkeep_opponent_more_lands_basic_land_tutor_to_hand_v1'
      AND effect_json->>'trigger' = 'beginning_of_your_upkeep'
      AND effect_json->>'condition' = 'opponent_controls_more_lands'
      AND effect_json->>'tutor_target' = 'basic_land'
      AND effect_json->>'destination' = 'hand'
      AND review_status = 'active'
      AND execution_status = 'auto'
      AND source = 'curated'
      AND oracle_hash = '83b074e38da3e6c4eb6ec3e7568c914b'
  ) AS exact_executable_rule_rows,
  (
    SELECT count(*)
    FROM card_battle_rules
    WHERE normalized_name = 'land tax'
      AND logical_rule_key <> 'battle_rule_v1:e3f5f35c6a9ee4fd8c7b9972c4152bef'
      AND effect_json->>'effect' IN ('passive', 'tutor')
      AND review_status NOT IN ('rejected', 'deprecated')
      AND execution_status IN ('auto', 'executable', 'review_only')
  ) AS legacy_enabled_passive_or_shadow_rows;

SELECT
  'pg033_land_tax_rule_postcheck' AS check_name,
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
WHERE normalized_name = 'land tax'
ORDER BY source, review_status, execution_status, logical_rule_key;

SELECT
  'pg033_land_tax_snapshot_postcheck' AS check_name,
  name,
  function_tags,
  battle_rules
FROM card_intelligence_snapshot
WHERE lower(name) = 'land tax';
