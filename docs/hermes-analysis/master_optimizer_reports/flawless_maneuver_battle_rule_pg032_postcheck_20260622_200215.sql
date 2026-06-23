\pset pager off

SELECT
  'pg032_flawless_maneuver_postcheck_counts' AS check_name,
  (
    SELECT count(*)
    FROM card_battle_rules
    WHERE normalized_name = 'flawless maneuver'
      AND logical_rule_key = 'battle_rule_v1:73622071c1ad89267708f914a0729bf2'
      AND effect_json->>'effect' = 'indestructible'
      AND effect_json->>'battle_model_scope' =
        'flawless_maneuver_control_commander_free_creatures_indestructible_until_eot_v1'
      AND effect_json->>'target_scope' = 'creatures_you_control'
      AND effect_json->>'duration' = 'until_end_of_turn'
      AND effect_json->>'free_if_control_commander' = 'true'
      AND effect_json->>'alternative_cost' = '{0}'
      AND effect_json->>'alternative_cost_condition' = 'control_commander'
      AND review_status = 'active'
      AND execution_status = 'auto'
      AND source = 'curated'
      AND oracle_hash = 'fa955216fa827bf75c5b79dcbdb4b97e'
  ) AS exact_executable_rule_rows,
  (
    SELECT count(*)
    FROM card_battle_rules
    WHERE normalized_name = 'flawless maneuver'
      AND logical_rule_key <> 'battle_rule_v1:73622071c1ad89267708f914a0729bf2'
      AND effect_json->>'effect' = 'indestructible'
      AND review_status NOT IN ('rejected', 'deprecated')
      AND execution_status IN ('auto', 'executable', 'review_only')
  ) AS legacy_enabled_indestructible_or_shadow_rows;

SELECT
  'pg032_flawless_maneuver_rule_postcheck' AS check_name,
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
WHERE normalized_name = 'flawless maneuver'
ORDER BY source, review_status, execution_status, logical_rule_key;

SELECT
  'pg032_flawless_maneuver_snapshot_postcheck' AS check_name,
  name,
  function_tags,
  battle_rules
FROM card_intelligence_snapshot
WHERE lower(name) = 'flawless maneuver';
