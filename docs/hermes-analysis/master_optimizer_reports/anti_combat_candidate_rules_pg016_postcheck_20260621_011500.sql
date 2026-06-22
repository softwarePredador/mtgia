\pset pager off

WITH wanted(card_name, logical_rule_key, expected_effect) AS (
  VALUES
    ('Norn''s Annex', 'battle_rule_v1:0b3adc33c3be375c3d4005b0082ff5c2', 'attack_tax'),
    ('Windborn Muse', 'battle_rule_v1:6932f0223ca41f0eedf724d55a9a858b', 'attack_tax'),
    ('Silent Arbiter', 'battle_rule_v1:6f6089b73fb8f7f9aee20cacb64fffc7', 'attack_limit'),
    ('Ensnaring Bridge', 'battle_rule_v1:1ea5840419f4343c05a661e79d6829d5', 'attack_limit'),
    ('Magus of the Moat', 'battle_rule_v1:439de5be33887bbce5dde1cfb367774a', 'attack_limit')
)
SELECT
  'pg016_anti_combat_postcheck_counts' AS check_name,
  (SELECT count(*) FROM cards c JOIN wanted w ON lower(c.name) = lower(w.card_name)) AS card_rows,
  (
    SELECT count(*)
    FROM wanted w
    JOIN card_legalities cl ON cl.format = 'commander' AND cl.status = 'legal'
    JOIN cards c ON c.id = cl.card_id AND lower(c.name) = lower(w.card_name)
  ) AS commander_legal_rows,
  (
    SELECT count(*)
    FROM wanted w
    JOIN card_battle_rules cbr
      ON lower(cbr.card_name) = lower(w.card_name)
     AND cbr.logical_rule_key = w.logical_rule_key
     AND cbr.effect_json->>'effect' = w.expected_effect
     AND cbr.review_status = 'verified'
     AND cbr.execution_status = 'auto'
     AND cbr.source = 'curated'
  ) AS curated_executable_rows,
  (
    SELECT count(*)
    FROM wanted w
    JOIN card_battle_rules cbr ON lower(cbr.card_name) = lower(w.card_name)
    WHERE cbr.logical_rule_key <> w.logical_rule_key
      AND cbr.source = 'generated'
      AND cbr.execution_status IN ('auto', 'executable', 'review_only')
  ) AS stale_enabled_generated_rows,
  (
    SELECT count(*)
    FROM wanted w
    JOIN card_function_tags cft ON lower(cft.card_name) = lower(w.card_name)
    WHERE cft.tag = 'protection'
      AND cft.source = 'card_battle_rules_v1'
  ) AS protection_function_tag_rows;

WITH wanted(card_name) AS (
  VALUES
    ('Norn''s Annex'),
    ('Windborn Muse'),
    ('Silent Arbiter'),
    ('Ensnaring Bridge'),
    ('Magus of the Moat')
)
SELECT
  'pg016_anti_combat_rule_postcheck' AS check_name,
  cbr.card_name,
  cbr.logical_rule_key,
  cbr.effect_json,
  cbr.deck_role_json,
  cbr.source,
  cbr.confidence,
  cbr.review_status,
  cbr.execution_status,
  cbr.reviewed_by,
  cbr.reviewed_at
FROM wanted w
JOIN card_battle_rules cbr ON lower(cbr.card_name) = lower(w.card_name)
ORDER BY cbr.card_name, cbr.source, cbr.review_status, cbr.execution_status, cbr.logical_rule_key;

WITH wanted(card_name) AS (
  VALUES
    ('Norn''s Annex'),
    ('Windborn Muse'),
    ('Silent Arbiter'),
    ('Ensnaring Bridge'),
    ('Magus of the Moat')
)
SELECT
  'pg016_anti_combat_function_tags_postcheck' AS check_name,
  cft.card_name,
  cft.tag,
  cft.source,
  cft.confidence,
  cft.evidence
FROM wanted w
JOIN card_function_tags cft ON lower(cft.card_name) = lower(w.card_name)
ORDER BY cft.card_name, cft.tag, cft.source;

WITH wanted(card_name) AS (
  VALUES
    ('Norn''s Annex'),
    ('Windborn Muse'),
    ('Silent Arbiter'),
    ('Ensnaring Bridge'),
    ('Magus of the Moat')
)
SELECT
  'pg016_anti_combat_snapshot_postcheck' AS check_name,
  cis.name,
  cis.function_tags,
  cis.battle_rules
FROM wanted w
LEFT JOIN card_intelligence_snapshot cis ON lower(cis.name) = lower(w.card_name)
ORDER BY w.card_name;
