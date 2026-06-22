\pset pager off

SELECT
  'pg012_flame_wave_current_rule_state' AS check_name,
  c.id::text AS card_id,
  c.name,
  c.type_line,
  md5(regexp_replace(lower(coalesce(c.oracle_text, '')), '\s+', ' ', 'g')) AS oracle_hash,
  cbr.logical_rule_key,
  cbr.effect_json,
  cbr.deck_role_json,
  cbr.source,
  cbr.confidence,
  cbr.review_status,
  cbr.execution_status
FROM cards c
LEFT JOIN card_battle_rules cbr ON cbr.card_id = c.id
WHERE lower(c.name) = 'flame wave'
ORDER BY cbr.source, cbr.review_status, cbr.execution_status, cbr.logical_rule_key;

SELECT
  'pg012_flame_wave_precheck_counts' AS check_name,
  (SELECT count(*) FROM cards WHERE lower(name) = 'flame wave') AS card_rows,
  (
    SELECT count(*)
    FROM cards c
    JOIN card_battle_rules cbr ON cbr.card_id = c.id
    WHERE lower(c.name) = 'flame wave'
      AND cbr.source = 'generated'
      AND cbr.review_status = 'needs_review'
      AND cbr.execution_status = 'review_only'
      AND cbr.effect_json->>'effect' = 'remove_creature'
  ) AS generated_remove_review_only_rows,
  (
    SELECT count(*)
    FROM cards c
    JOIN card_battle_rules cbr ON cbr.card_id = c.id
    WHERE lower(c.name) = 'flame wave'
      AND cbr.logical_rule_key = 'battle_rule_v1:7a932c36df79f966f5f144a3b3a87d84'
  ) AS curated_rule_key_rows,
  (
    SELECT count(*)
    FROM cards c
    JOIN card_battle_rules cbr ON cbr.card_id = c.id
    WHERE lower(c.name) = 'flame wave'
      AND cbr.effect_json->>'effect' = 'damage_player_and_creatures'
      AND cbr.review_status IN ('verified', 'active')
      AND cbr.execution_status IN ('auto', 'executable')
  ) AS executable_damage_player_creatures_rows;

SELECT
  'pg012_flame_wave_function_tags_reference' AS check_name,
  c.name,
  cft.tag,
  cft.source,
  cft.confidence,
  cft.evidence
FROM cards c
LEFT JOIN card_function_tags cft ON cft.card_id = c.id
WHERE lower(c.name) = 'flame wave'
ORDER BY cft.tag, cft.source;
