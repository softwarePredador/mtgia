\pset pager off

SELECT
  'pg017_arcane_epiphany_postcheck_counts' AS check_name,
  (SELECT count(*) FROM cards WHERE lower(name) = 'arcane epiphany') AS card_rows,
  (
    SELECT count(*)
    FROM card_battle_rules
    WHERE normalized_name = 'arcane epiphany'
      AND logical_rule_key = 'battle_rule_v1:3e12c38dd6d41a47079fbdefee08b3bd'
      AND effect_json->>'effect' = 'draw_cards'
      AND effect_json->>'draw_count' = '3'
      AND review_status = 'verified'
      AND execution_status = 'auto'
      AND source = 'curated'
  ) AS curated_executable_rows,
  (
    SELECT count(*)
    FROM card_function_tags
    WHERE lower(card_name) = 'arcane epiphany'
      AND tag = 'draw'
      AND source = 'card_battle_rules_v1'
  ) AS draw_function_tag_rows;

SELECT
  'pg017_arcane_epiphany_rule_postcheck' AS check_name,
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
WHERE lower(card_name) = 'arcane epiphany'
ORDER BY source, review_status, execution_status, logical_rule_key;

SELECT
  'pg017_arcane_epiphany_snapshot_postcheck' AS check_name,
  name,
  function_tags,
  battle_rules
FROM card_intelligence_snapshot
WHERE lower(name) = 'arcane epiphany';
