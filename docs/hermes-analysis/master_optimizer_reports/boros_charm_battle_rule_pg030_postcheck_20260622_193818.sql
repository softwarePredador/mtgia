\pset pager off

SELECT
  'pg030_boros_charm_postcheck_counts' AS check_name,
  (
    SELECT count(*)
    FROM card_battle_rules
    WHERE normalized_name = 'boros charm'
      AND logical_rule_key = 'battle_rule_v1:32605a838d7a519f44eaa0899d2c40bf'
      AND effect_json->>'effect' = 'modal_boros_charm'
      AND effect_json->>'battle_model_scope' =
        'boros_charm_choose_one_damage_indestructible_double_strike_v1'
      AND effect_json->'modes' @>
        '[{"mode":"permanents_you_control_gain_indestructible_until_eot"}]'::jsonb
      AND effect_json->'modes' @>
        '[{"mode":"target_creature_gains_double_strike_until_eot"}]'::jsonb
      AND effect_json->'modes' @>
        '[{"mode":"damage_player_or_planeswalker","mode_status":"annotation_only"}]'::jsonb
      AND review_status = 'active'
      AND execution_status = 'auto'
      AND source = 'curated'
      AND oracle_hash = '98a7be829075118b499a7c283a23501f'
  ) AS exact_executable_rule_rows,
  (
    SELECT count(*)
    FROM card_battle_rules
    WHERE normalized_name = 'boros charm'
      AND logical_rule_key <> 'battle_rule_v1:32605a838d7a519f44eaa0899d2c40bf'
      AND effect_json->>'effect' IN ('modal_boros_charm', 'indestructible')
      AND review_status NOT IN ('rejected', 'deprecated')
      AND execution_status IN ('auto', 'executable', 'review_only')
  ) AS legacy_enabled_modal_or_shadow_rows;

SELECT
  'pg030_boros_charm_rule_postcheck' AS check_name,
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
WHERE normalized_name = 'boros charm'
ORDER BY source, review_status, execution_status, logical_rule_key;

SELECT
  'pg030_boros_charm_snapshot_postcheck' AS check_name,
  name,
  function_tags,
  battle_rules
FROM card_intelligence_snapshot
WHERE lower(name) = 'boros charm';
