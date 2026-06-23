\pset pager off
\set ON_ERROR_STOP on

WITH exact_rule AS (
  SELECT *
  FROM card_battle_rules
  WHERE normalized_name = 'swords to plowshares'
    AND logical_rule_key = 'battle_rule_v1:379008f3f03f94258292123453e3041c'
    AND effect_json->>'effect' = 'remove_creature'
    AND effect_json->>'destination' = 'exile'
    AND effect_json->>'exile_target' = 'true'
    AND effect_json->>'target_controller_life_gain_equal_target_power' = 'true'
    AND effect_json->>'battle_model_scope' =
      'swords_to_plowshares_creature_exile_life_equal_power_v1'
    AND review_status = 'active'
    AND execution_status = 'auto'
    AND oracle_hash = '702f566e95dd477f5cf5a551e41e9df8'
),
legacy_rows AS (
  SELECT *
  FROM card_battle_rules
  WHERE normalized_name = 'swords to plowshares'
    AND logical_rule_key <> 'battle_rule_v1:379008f3f03f94258292123453e3041c'
    AND effect_json->>'effect' = 'remove_creature'
    AND review_status NOT IN ('rejected', 'deprecated')
    AND execution_status IN ('auto', 'executable', 'review_only')
),
trusted_without_hash AS (
  SELECT *
  FROM card_battle_rules
  WHERE normalized_name = 'swords to plowshares'
    AND source IN ('manual', 'curated')
    AND review_status IN ('verified', 'active')
    AND execution_status IN ('auto', 'executable')
    AND coalesce(oracle_hash, '') = ''
)
SELECT 'exact_executable_rule_rows' AS check_name, count(*)::text AS value FROM exact_rule
UNION ALL
SELECT 'legacy_enabled_removal_rows', count(*)::text FROM legacy_rows
UNION ALL
SELECT 'trusted_executable_without_oracle_hash_rows', count(*)::text FROM trusted_without_hash
UNION ALL
SELECT 'active_rule_snapshot', jsonb_pretty(to_jsonb(exact_rule.*)) FROM exact_rule;
