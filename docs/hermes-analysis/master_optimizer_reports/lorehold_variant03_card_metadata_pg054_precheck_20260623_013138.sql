-- PG054 Lorehold Variant 03 card metadata precheck.
\echo 'PG054 Lorehold Variant 03 card metadata precheck'

WITH expected(name, oracle_id, expected_cmc) AS (
  VALUES
    ('Naktamun Lorespinner // Wheel of Fortune', 'c78783e5-868d-4a8b-a4f8-95a92853cf0a'::uuid, 3::numeric),
    ('Tablet of Discovery', '19cf5798-4600-4a66-b1c7-de77bde157d0'::uuid, 3::numeric)
)
SELECT
  e.name AS expected_name,
  c.id,
  c.name,
  c.scryfall_id,
  c.oracle_id,
  c.mana_cost,
  c.cmc AS current_cmc,
  e.expected_cmc,
  c.type_line,
  c.rarity,
  c.collector_number,
  c.layout,
  c.card_faces_json IS NOT NULL AS has_faces,
  COALESCE(length(c.oracle_text), 0) AS oracle_len
FROM expected e
LEFT JOIN cards c
  ON lower(c.name) = lower(e.name)
  OR lower(split_part(c.name, ' // ', 1)) = lower(split_part(e.name, ' // ', 1))
  OR c.oracle_id = e.oracle_id
  OR c.scryfall_id = e.oracle_id
ORDER BY e.name;

WITH expected(name, oracle_id, expected_cmc) AS (
  VALUES
    ('Naktamun Lorespinner // Wheel of Fortune', 'c78783e5-868d-4a8b-a4f8-95a92853cf0a'::uuid, 3::numeric),
    ('Tablet of Discovery', '19cf5798-4600-4a66-b1c7-de77bde157d0'::uuid, 3::numeric)
)
SELECT
  'target_rows' AS check_name,
  count(*) AS value
FROM expected e
JOIN cards c
  ON lower(c.name) = lower(e.name)
  OR lower(split_part(c.name, ' // ', 1)) = lower(split_part(e.name, ' // ', 1))
  OR c.oracle_id = e.oracle_id
  OR c.scryfall_id = e.oracle_id
UNION ALL
SELECT
  'bad_cmc_rows' AS check_name,
  count(*) AS value
FROM expected e
JOIN cards c
  ON lower(c.name) = lower(e.name)
  OR lower(split_part(c.name, ' // ', 1)) = lower(split_part(e.name, ' // ', 1))
  OR c.oracle_id = e.oracle_id
  OR c.scryfall_id = e.oracle_id
WHERE c.cmc IS DISTINCT FROM e.expected_cmc
UNION ALL
SELECT
  'naktamun_missing_faces_rows' AS check_name,
  count(*) AS value
FROM cards c
WHERE (lower(c.name) = lower('Naktamun Lorespinner // Wheel of Fortune')
   OR c.oracle_id = 'c78783e5-868d-4a8b-a4f8-95a92853cf0a'::uuid)
  AND c.card_faces_json IS NULL;
