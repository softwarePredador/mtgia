\pset pager off

SELECT
  'pg012_flame_wave_postcheck_counts' AS check_name,
  (SELECT count(*) FROM cards WHERE lower(name) = 'flame wave') AS card_rows,
  (
    SELECT count(*)
    FROM card_battle_rules
    WHERE normalized_name = 'flame wave'
      AND logical_rule_key = 'battle_rule_v1:7a932c36df79f966f5f144a3b3a87d84'
      AND effect_json->>'effect' = 'damage_player_and_creatures'
      AND effect_json->>'amount' = '4'
      AND review_status = 'verified'
      AND execution_status = 'auto'
      AND source = 'curated'
  ) AS curated_executable_rows,
  (
    SELECT count(*)
    FROM card_battle_rules
    WHERE lower(card_name) = 'flame wave'
      AND logical_rule_key <> 'battle_rule_v1:7a932c36df79f966f5f144a3b3a87d84'
      AND effect_json->>'effect' = 'remove_creature'
      AND execution_status IN ('auto', 'executable', 'review_only')
  ) AS stale_enabled_remove_rows;

SELECT
  'pg012_flame_wave_rule_postcheck' AS check_name,
  card_name,
  logical_rule_key,
  effect_json,
  deck_role_json,
  source,
  confidence,
  review_status,
  execution_status,
  reviewed_by,
  reviewed_at
FROM card_battle_rules
WHERE lower(card_name) = 'flame wave'
ORDER BY source, review_status, execution_status, logical_rule_key;

SELECT
  'pg012_flame_wave_snapshot_postcheck' AS check_name,
  name,
  function_tags,
  battle_rules
FROM card_intelligence_snapshot
WHERE lower(name) = 'flame wave';
