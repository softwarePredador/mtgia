-- PG625 postcheck: expected values after apply + migration 032:
-- requested_cards_verified_and_tagged = 24/24
-- trusted_executable_missing_oracle_hash = 0
-- schema migration 032 = present

WITH requested_cards(name) AS (
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
  'requested_cards_verified_and_tagged' AS check_name,
  COUNT(*)::text || '/' || (SELECT COUNT(*) FROM requested_cards)::text AS value
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
  AND COALESCE(oracle_hash, '') = ''

UNION ALL

SELECT
  'schema_migration_032',
  COUNT(*)::text
FROM schema_migrations
WHERE version = '032'
  AND name = 'refresh_card_intelligence_snapshot_rule_identity_fallback';
