-- PG052 Lorehold Variant 02 card oracle metadata postcheck.
\echo 'PG052 Lorehold Variant 02 card oracle metadata postcheck'

WITH expected(name, oracle_id, expected_cmc) AS (
  VALUES
    ('Molecule Man', 'ba944437-0b55-47cb-92dc-2477ce6726c3'::uuid, 6::numeric),
    ('The Mind Stone', 'b175e826-09e8-4fae-9f2e-b902f95b282d'::uuid, 2::numeric),
    ('The Scarlet Witch', 'd8ae8c38-501e-44ea-9faf-cf9d11ba6616'::uuid, 3::numeric),
    ('Thor, God of Thunder', '2842217a-173e-4879-8b25-fefe2fc1123f'::uuid, 5::numeric)
)
SELECT
  e.name AS expected_name,
  c.id,
  c.name,
  c.mana_cost,
  c.cmc,
  e.expected_cmc,
  c.type_line,
  c.colors,
  c.color_identity,
  c.power,
  c.toughness,
  c.keywords,
  c.set_code,
  c.rarity,
  c.collector_number,
  c.layout,
  COALESCE(length(c.oracle_text), 0) AS oracle_len
FROM expected e
JOIN cards c
  ON lower(c.name) = lower(e.name)
  OR c.oracle_id = e.oracle_id
  OR c.scryfall_id = e.oracle_id
ORDER BY e.name;

WITH expected(name, oracle_id, expected_cmc) AS (
  VALUES
    ('Molecule Man', 'ba944437-0b55-47cb-92dc-2477ce6726c3'::uuid, 6::numeric),
    ('The Mind Stone', 'b175e826-09e8-4fae-9f2e-b902f95b282d'::uuid, 2::numeric),
    ('The Scarlet Witch', 'd8ae8c38-501e-44ea-9faf-cf9d11ba6616'::uuid, 3::numeric),
    ('Thor, God of Thunder', '2842217a-173e-4879-8b25-fefe2fc1123f'::uuid, 5::numeric)
)
SELECT
  'target_rows' AS check_name,
  count(*) AS value
FROM expected e
JOIN cards c
  ON lower(c.name) = lower(e.name)
  OR c.oracle_id = e.oracle_id
  OR c.scryfall_id = e.oracle_id
UNION ALL
SELECT
  'bad_cmc_rows' AS check_name,
  count(*) AS value
FROM expected e
JOIN cards c
  ON lower(c.name) = lower(e.name)
  OR c.oracle_id = e.oracle_id
  OR c.scryfall_id = e.oracle_id
WHERE c.cmc IS DISTINCT FROM e.expected_cmc
UNION ALL
SELECT
  'missing_oracle_rows' AS check_name,
  count(*) AS value
FROM expected e
JOIN cards c
  ON lower(c.name) = lower(e.name)
  OR c.oracle_id = e.oracle_id
  OR c.scryfall_id = e.oracle_id
WHERE COALESCE(c.oracle_text, '') = ''
UNION ALL
SELECT
  'off_lorehold_color_identity_rows' AS check_name,
  count(*) AS value
FROM expected e
JOIN cards c
  ON lower(c.name) = lower(e.name)
  OR c.oracle_id = e.oracle_id
  OR c.scryfall_id = e.oracle_id
WHERE NOT (COALESCE(c.color_identity, ARRAY[]::text[]) <@ ARRAY['R','W']::text[])
UNION ALL
SELECT
  'backup_rows' AS check_name,
  count(*) AS value
FROM manaloom_deploy_audit.pg052_lorehold_variant02_card_oracle_metadata_20260623_011834;
