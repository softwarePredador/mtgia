\pset pager off

SELECT
  'pg014_sphere_current_rule_state' AS check_name,
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
WHERE lower(c.name) = 'sphere of safety'
ORDER BY cbr.source, cbr.review_status, cbr.execution_status, cbr.logical_rule_key;

SELECT
  'pg014_sphere_precheck_counts' AS check_name,
  (SELECT count(*) FROM cards WHERE lower(name) = 'sphere of safety') AS card_rows,
  (
    SELECT count(*)
    FROM cards c
    JOIN card_battle_rules cbr ON cbr.card_id = c.id
    WHERE lower(c.name) = 'sphere of safety'
      AND cbr.source = 'generated'
      AND cbr.review_status = 'needs_review'
      AND cbr.execution_status = 'review_only'
      AND cbr.effect_json->>'effect' = 'draw_engine'
  ) AS generated_draw_review_only_rows,
  (
    SELECT count(*)
    FROM cards c
    JOIN card_battle_rules cbr ON cbr.card_id = c.id
    WHERE lower(c.name) = 'sphere of safety'
      AND cbr.logical_rule_key = 'battle_rule_v1:a619518cf24caa68fdd86b555687f20f'
  ) AS curated_rule_key_rows,
  (
    SELECT count(*)
    FROM cards c
    JOIN card_battle_rules cbr ON cbr.card_id = c.id
    WHERE lower(c.name) = 'sphere of safety'
      AND cbr.effect_json->>'effect' = 'attack_tax'
      AND cbr.review_status IN ('verified', 'active')
      AND cbr.execution_status IN ('auto', 'executable')
  ) AS executable_attack_tax_rows;

SELECT
  'pg014_sphere_function_tags_precheck' AS check_name,
  c.name,
  cft.tag,
  cft.source,
  cft.confidence,
  cft.evidence
FROM cards c
LEFT JOIN card_function_tags cft ON cft.card_id = c.id
WHERE lower(c.name) = 'sphere of safety'
ORDER BY cft.tag, cft.source;
