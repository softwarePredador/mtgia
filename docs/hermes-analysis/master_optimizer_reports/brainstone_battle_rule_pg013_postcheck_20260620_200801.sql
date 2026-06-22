\pset pager off

SELECT
  'pg013_brainstone_postcheck_counts' AS check_name,
  (SELECT count(*) FROM cards WHERE lower(name) = 'brainstone') AS card_rows,
  (
    SELECT count(*)
    FROM card_battle_rules
    WHERE normalized_name = 'brainstone'
      AND logical_rule_key = 'battle_rule_v1:03bed5506a427743723cd7676c6a67d9'
      AND effect_json->>'effect' = 'topdeck_manipulation'
      AND effect_json->>'activation_cost_generic' = '2'
      AND effect_json->>'draw_count' = '3'
      AND effect_json->>'put_from_hand_on_top_count' = '2'
      AND review_status = 'active'
      AND execution_status = 'auto'
      AND source = 'curated'
  ) AS curated_executable_rows,
  (
    SELECT count(*)
    FROM card_battle_rules
    WHERE lower(card_name) = 'brainstone'
      AND logical_rule_key <> 'battle_rule_v1:03bed5506a427743723cd7676c6a67d9'
      AND effect_json->>'effect' = 'draw_cards'
      AND execution_status IN ('auto', 'executable', 'review_only')
  ) AS stale_enabled_draw_rows;

SELECT
  'pg013_brainstone_rule_postcheck' AS check_name,
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
WHERE lower(card_name) = 'brainstone'
ORDER BY source, review_status, execution_status, logical_rule_key;

SELECT
  'pg013_brainstone_snapshot_postcheck' AS check_name,
  name,
  function_tags,
  battle_rules
FROM card_intelligence_snapshot
WHERE lower(name) = 'brainstone';
