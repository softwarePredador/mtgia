\pset pager off

SELECT
  'pg015_wrath_current_rule_state' AS check_name,
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
WHERE lower(c.name) = 'wrath of god'
ORDER BY cbr.source, cbr.review_status, cbr.execution_status, cbr.logical_rule_key;

SELECT
  'pg015_wrath_precheck_counts' AS check_name,
  (SELECT count(*) FROM cards WHERE lower(name) = 'wrath of god') AS card_rows,
  (
    SELECT count(*)
    FROM cards c
    JOIN card_battle_rules cbr ON cbr.card_id = c.id
    WHERE lower(c.name) = 'wrath of god'
      AND cbr.source = 'generated'
      AND cbr.review_status = 'needs_review'
      AND cbr.execution_status = 'review_only'
      AND cbr.effect_json->>'effect' = 'board_wipe'
  ) AS generated_wipe_review_only_rows,
  (
    SELECT count(*)
    FROM cards c
    JOIN card_battle_rules cbr ON cbr.card_id = c.id
    WHERE lower(c.name) = 'wrath of god'
      AND cbr.effect_json->>'effect' = 'board_wipe'
      AND cbr.review_status IN ('verified', 'active')
      AND cbr.execution_status IN ('auto', 'executable')
  ) AS executable_board_wipe_rows;
