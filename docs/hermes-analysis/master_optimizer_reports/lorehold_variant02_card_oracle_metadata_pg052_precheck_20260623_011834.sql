-- PG052 Lorehold Variant 02 card oracle metadata precheck.
\echo 'PG052 Lorehold Variant 02 card oracle metadata precheck'

WITH expected(name, oracle_id, expected_cmc) AS (
  VALUES
    ('Molecule Man', 'ba944437-0b55-47cb-92dc-2477ce6726c3'::uuid, 6::numeric),
    ('The Mind Stone', 'b175e826-09e8-4fae-9f2e-b902f95b282d'::uuid, 2::numeric),
    ('The Scarlet Witch', 'd8ae8c38-501e-44ea-9faf-cf9d11ba6616'::uuid, 3::numeric),
    ('Thor, God of Thunder', '2842217a-173e-4879-8b25-fefe2fc1123f'::uuid, 5::numeric)
)
SELECT
  'current_target_rows' AS check_name,
  count(*) AS value
FROM cards c
JOIN expected e
  ON lower(c.name) = lower(e.name)
  OR c.oracle_id = e.oracle_id
  OR c.scryfall_id = e.oracle_id;

WITH expected(name, oracle_id, expected_cmc) AS (
  VALUES
    ('Molecule Man', 'ba944437-0b55-47cb-92dc-2477ce6726c3'::uuid, 6::numeric),
    ('The Mind Stone', 'b175e826-09e8-4fae-9faf-cf9d11ba6616'::uuid, 2::numeric),
    ('The Scarlet Witch', 'd8ae8c38-501e-44ea-9faf-cf9d11ba6616'::uuid, 3::numeric),
    ('Thor, God of Thunder', '2842217a-173e-4879-8b25-fefe2fc1123f'::uuid, 5::numeric)
)
SELECT
  e.name AS expected_name,
  c.id,
  c.name AS current_name,
  c.scryfall_id,
  c.oracle_id,
  c.mana_cost,
  c.cmc AS current_cmc,
  e.expected_cmc,
  c.type_line,
  COALESCE(length(c.oracle_text), 0) AS oracle_len
FROM expected e
LEFT JOIN cards c
  ON lower(c.name) = lower(e.name)
  OR c.oracle_id = e.oracle_id
  OR c.scryfall_id = e.oracle_id
ORDER BY e.name, c.name;

WITH expected(name, oracle_id, expected_cmc) AS (
  VALUES
    ('Molecule Man', 'ba944437-0b55-47cb-92dc-2477ce6726c3'::uuid, 6::numeric),
    ('The Mind Stone', 'b175e826-09e8-4fae-9f2e-b902f95b282d'::uuid, 2::numeric),
    ('The Scarlet Witch', 'd8ae8c38-501e-44ea-9faf-cf9d11ba6616'::uuid, 3::numeric),
    ('Thor, God of Thunder', '2842217a-173e-4879-8b25-fefe2fc1123f'::uuid, 5::numeric)
)
SELECT
  'bad_or_missing_cmc_rows' AS check_name,
  count(*) AS value
FROM expected e
JOIN cards c
  ON lower(c.name) = lower(e.name)
  OR c.oracle_id = e.oracle_id
  OR c.scryfall_id = e.oracle_id
WHERE c.cmc IS DISTINCT FROM e.expected_cmc;

WITH expected(name, oracle_id) AS (
  VALUES
    ('Molecule Man', 'ba944437-0b55-47cb-92dc-2477ce6726c3'::uuid),
    ('The Mind Stone', 'b175e826-09e8-4fae-9f2e-b902f95b282d'::uuid),
    ('The Scarlet Witch', 'd8ae8c38-501e-44ea-9faf-cf9d11ba6616'::uuid),
    ('Thor, God of Thunder', '2842217a-173e-4879-8b25-fefe2fc1123f'::uuid)
)
SELECT
  'oracle_id_conflict_rows' AS check_name,
  count(*) AS value
FROM expected e
JOIN cards c
  ON c.oracle_id = e.oracle_id
  OR c.scryfall_id = e.oracle_id
WHERE lower(c.name) <> lower(e.name);
