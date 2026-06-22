\pset pager off

WITH wanted(card_name, expected_oracle_hash, logical_rule_key, expected_effect) AS (
  VALUES
    ('Norn''s Annex', 'c24fdd009dc36172162fa5f1c581b2da', 'battle_rule_v1:0b3adc33c3be375c3d4005b0082ff5c2', 'attack_tax'),
    ('Windborn Muse', '370b18223df70f111f8673fd6b4acb7f', 'battle_rule_v1:6932f0223ca41f0eedf724d55a9a858b', 'attack_tax'),
    ('Silent Arbiter', '77d31b859247e6129c25b4fa47be336e', 'battle_rule_v1:6f6089b73fb8f7f9aee20cacb64fffc7', 'attack_limit'),
    ('Ensnaring Bridge', 'f5f24e3b4b9f6a52fb0afa1cef9ae3d3', 'battle_rule_v1:1ea5840419f4343c05a661e79d6829d5', 'attack_limit'),
    ('Magus of the Moat', 'da1c62032e405fc6fc6151ccdf6df879', 'battle_rule_v1:439de5be33887bbce5dde1cfb367774a', 'attack_limit')
)
SELECT
  'pg016_anti_combat_precheck_cards' AS check_name,
  w.card_name AS wanted_card_name,
  c.id AS card_id,
  c.name AS pg_card_name,
  c.mana_cost,
  c.cmc,
  c.type_line,
  c.color_identity,
  cl.status AS commander_status,
  md5(regexp_replace(lower(coalesce(c.oracle_text, '')), '\s+', ' ', 'g')) AS oracle_hash,
  w.expected_oracle_hash,
  w.logical_rule_key,
  w.expected_effect
FROM wanted w
LEFT JOIN cards c ON lower(c.name) = lower(w.card_name)
LEFT JOIN card_legalities cl ON cl.card_id = c.id AND cl.format = 'commander'
ORDER BY w.card_name;

WITH wanted(card_name) AS (
  VALUES
    ('Norn''s Annex'),
    ('Windborn Muse'),
    ('Silent Arbiter'),
    ('Ensnaring Bridge'),
    ('Magus of the Moat')
)
SELECT
  'pg016_anti_combat_precheck_existing_rules' AS check_name,
  w.card_name AS wanted_card_name,
  cbr.card_name,
  cbr.logical_rule_key,
  cbr.effect_json,
  cbr.deck_role_json,
  cbr.source,
  cbr.confidence,
  cbr.review_status,
  cbr.execution_status
FROM wanted w
LEFT JOIN card_battle_rules cbr ON lower(cbr.card_name) = lower(w.card_name)
ORDER BY w.card_name, cbr.source, cbr.review_status, cbr.execution_status, cbr.logical_rule_key;

WITH wanted(card_name) AS (
  VALUES
    ('Norn''s Annex'),
    ('Windborn Muse'),
    ('Silent Arbiter'),
    ('Ensnaring Bridge'),
    ('Magus of the Moat')
)
SELECT
  'pg016_anti_combat_precheck_function_tags' AS check_name,
  w.card_name AS wanted_card_name,
  cft.card_name,
  cft.tag,
  cft.source,
  cft.confidence,
  cft.evidence
FROM wanted w
LEFT JOIN card_function_tags cft ON lower(cft.card_name) = lower(w.card_name)
ORDER BY w.card_name, cft.tag, cft.source;
