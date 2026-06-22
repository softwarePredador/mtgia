\pset pager off

SELECT
  'pg013_brainstone_current_rule_state' AS check_name,
  c.id::text AS card_id,
  c.name,
  c.type_line,
  c.oracle_text,
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
WHERE lower(c.name) = 'brainstone'
ORDER BY cbr.source, cbr.review_status, cbr.execution_status, cbr.logical_rule_key;

SELECT
  'pg013_brainstone_precheck_counts' AS check_name,
  (SELECT count(*) FROM cards WHERE lower(name) = 'brainstone') AS card_rows,
  (
    SELECT count(*)
    FROM cards c
    JOIN card_battle_rules cbr ON cbr.card_id = c.id
    WHERE lower(c.name) = 'brainstone'
      AND cbr.source = 'generated'
      AND cbr.review_status = 'needs_review'
      AND cbr.execution_status = 'review_only'
      AND cbr.effect_json->>'effect' = 'draw_cards'
  ) AS generated_draw_review_only_rows,
  (
    SELECT count(*)
    FROM cards c
    JOIN card_battle_rules cbr ON cbr.card_id = c.id
    WHERE lower(c.name) = 'brainstone'
      AND cbr.logical_rule_key = 'battle_rule_v1:03bed5506a427743723cd7676c6a67d9'
  ) AS curated_rule_key_rows,
  (
    SELECT count(*)
    FROM cards c
    JOIN card_battle_rules cbr ON cbr.card_id = c.id
    WHERE lower(c.name) = 'brainstone'
      AND cbr.effect_json->>'effect' = 'topdeck_manipulation'
      AND cbr.review_status IN ('verified', 'active')
      AND cbr.execution_status IN ('auto', 'executable')
  ) AS executable_topdeck_rows;

SELECT
  'pg013_brainstone_snapshot_precheck' AS check_name,
  name,
  function_tags,
  battle_rules
FROM card_intelligence_snapshot
WHERE lower(name) = 'brainstone';
