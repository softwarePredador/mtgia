\pset pager off

SELECT
  'pg014_sphere_postcheck_counts' AS check_name,
  (SELECT count(*) FROM cards WHERE lower(name) = 'sphere of safety') AS card_rows,
  (
    SELECT count(*)
    FROM card_battle_rules
    WHERE normalized_name = 'sphere of safety'
      AND logical_rule_key = 'battle_rule_v1:a619518cf24caa68fdd86b555687f20f'
      AND effect_json->>'effect' = 'attack_tax'
      AND effect_json->>'attack_tax_per_enchantment' = '1'
      AND review_status = 'verified'
      AND execution_status = 'auto'
      AND source = 'curated'
  ) AS curated_executable_rows,
  (
    SELECT count(*)
    FROM card_battle_rules
    WHERE lower(card_name) = 'sphere of safety'
      AND logical_rule_key <> 'battle_rule_v1:a619518cf24caa68fdd86b555687f20f'
      AND effect_json->>'effect' = 'draw_engine'
      AND execution_status IN ('auto', 'executable', 'review_only')
  ) AS stale_enabled_draw_rows,
  (
    SELECT count(*)
    FROM card_function_tags
    WHERE lower(card_name) = 'sphere of safety'
      AND tag = 'protection'
      AND source = 'card_battle_rules_v1'
  ) AS protection_function_tag_rows;

SELECT
  'pg014_sphere_rule_postcheck' AS check_name,
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
WHERE lower(card_name) = 'sphere of safety'
ORDER BY source, review_status, execution_status, logical_rule_key;

SELECT
  'pg014_sphere_function_tags_postcheck' AS check_name,
  card_name,
  tag,
  source,
  confidence,
  evidence
FROM card_function_tags
WHERE lower(card_name) = 'sphere of safety'
ORDER BY tag, source;

SELECT
  'pg014_sphere_snapshot_postcheck' AS check_name,
  name,
  function_tags,
  battle_rules
FROM card_intelligence_snapshot
WHERE lower(name) = 'sphere of safety';
