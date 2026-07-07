-- PG625 precheck: priority Lorehold rule/snapshot validation.
-- Run via: ./server/bin/with_new_server_pg.sh psql -X -v ON_ERROR_STOP=1 -f <this file>

WITH target_rules(normalized_name, logical_rule_key) AS (
  VALUES
    ('fellwar stone', 'battle_rule_v1:3906ffa3cbf7d3437d68e44e13e10bba'),
    ('library of leng', 'battle_rule_v1:b6491cf6f7d7df9a3fb0d91abd3d31c3'),
    ('scroll rack', 'battle_rule_v1:3b58ff16a7eb52fb05c1bd8517225cd2'),
    ('talisman of conviction', 'battle_rule_v1:02133e513da5ea98ac74d32d39b16470')
),
requested_cards(name) AS (
  VALUES
    ('Lorehold, the Historian'),
    ('Farewell'),
    ('Fellwar Stone'),
    ('Flawless Maneuver'),
    ('Hit the Mother Lode'),
    ('Improvisation Capstone'),
    ('Land Tax'),
    ('Library of Leng'),
    ('Scroll Rack'),
    ('Swords to Plowshares'),
    ('Talisman of Conviction'),
    ('Teferi''s Protection'),
    ('Tibalt''s Trickery'),
    ('Command Tower'),
    ('Sol Ring'),
    ('Thor, God of Thunder'),
    ('Furygale Flocking'),
    ('Molecule Man'),
    ('Pearl Medallion'),
    ('Prismari Pianist'),
    ('Redirect Lightning'),
    ('The Mind Stone'),
    ('The Scarlet Witch'),
    ('Turbulent Steppe')
),
card_pick AS (
  SELECT DISTINCT ON (r.name)
    r.name AS requested_name,
    c.id AS card_id
  FROM requested_cards r
  JOIN cards c ON lower(c.name) = lower(r.name)
  ORDER BY r.name, c.created_at DESC NULLS LAST, c.id
),
snapshot_status AS (
  SELECT
    p.requested_name,
    COALESCE(s.verified_battle_rule_count, 0) AS verified_rule_count,
    COALESCE(array_length(s.function_tags, 1), 0) AS function_tag_count
  FROM card_pick p
  LEFT JOIN card_intelligence_snapshot s ON s.card_id = p.card_id
)
SELECT
  'target_active_auto_rows' AS check_name,
  COUNT(*)::text AS value
FROM card_battle_rules cbr
JOIN target_rules t USING (normalized_name, logical_rule_key)
WHERE cbr.review_status = 'active'
  AND cbr.execution_status = 'auto'

UNION ALL

SELECT
  'requested_cards_verified_and_tagged',
  COUNT(*)::text || '/' || (SELECT COUNT(*) FROM requested_cards)::text
FROM snapshot_status
WHERE verified_rule_count > 0
  AND function_tag_count > 0

UNION ALL

SELECT
  'trusted_executable_missing_oracle_hash',
  COUNT(*)::text
FROM card_battle_rules
WHERE source IN ('curated', 'manual')
  AND review_status IN ('verified', 'active')
  AND execution_status IN ('auto', 'executable')
  AND COALESCE(oracle_hash, '') = '';
