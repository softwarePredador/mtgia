\pset pager off

WITH wanted(card_name, expected_oracle_hash) AS (
  VALUES
    ('Jin-Gitaxias, Core Augur', '6cbe9a3e4c114022f6a3e1b855bdc392'),
    ('Chandra, Flameshaper', 'd41ef10198ca5cefdfa1c4d2687f0e3b')
)
SELECT
  'pg018_opponent_forensic_precheck_cards' AS check_name,
  c.id AS card_id,
  c.name,
  c.mana_cost,
  c.cmc,
  c.type_line,
  c.color_identity,
  cl.status AS commander_status,
  md5(regexp_replace(lower(coalesce(c.oracle_text, '')), '\s+', ' ', 'g')) AS oracle_hash,
  wanted.expected_oracle_hash
FROM wanted
LEFT JOIN cards c ON lower(c.name) = lower(wanted.card_name)
LEFT JOIN card_legalities cl ON cl.card_id = c.id AND cl.format = 'commander'
ORDER BY wanted.card_name;

WITH wanted(card_name) AS (
  VALUES
    ('Jin-Gitaxias, Core Augur'),
    ('Chandra, Flameshaper')
)
SELECT
  'pg018_opponent_forensic_precheck_rules' AS check_name,
  cbr.card_name,
  cbr.logical_rule_key,
  cbr.effect_json,
  cbr.deck_role_json,
  cbr.source,
  cbr.confidence,
  cbr.review_status,
  cbr.execution_status
FROM wanted
LEFT JOIN card_battle_rules cbr ON lower(cbr.card_name) = lower(wanted.card_name)
ORDER BY wanted.card_name, cbr.source, cbr.review_status, cbr.execution_status, cbr.logical_rule_key;
