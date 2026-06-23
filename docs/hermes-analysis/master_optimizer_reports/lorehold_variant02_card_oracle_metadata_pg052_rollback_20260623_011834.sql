-- PG052 Lorehold Variant 02 card oracle metadata rollback.
\echo 'PG052 Lorehold Variant 02 card oracle metadata rollback'

BEGIN;

WITH expected(name, oracle_id) AS (
  VALUES
    ('Molecule Man', 'ba944437-0b55-47cb-92dc-2477ce6726c3'::uuid),
    ('The Mind Stone', 'b175e826-09e8-4fae-9f2e-b902f95b282d'::uuid),
    ('The Scarlet Witch', 'd8ae8c38-501e-44ea-9faf-cf9d11ba6616'::uuid),
    ('Thor, God of Thunder', '2842217a-173e-4879-8b25-fefe2fc1123f'::uuid)
)
DELETE FROM cards c
USING expected e
WHERE lower(c.name) = lower(e.name)
   OR c.oracle_id = e.oracle_id
   OR c.scryfall_id = e.oracle_id;

INSERT INTO cards
SELECT *
FROM manaloom_deploy_audit.pg052_lorehold_variant02_card_oracle_metadata_20260623_011834;

COMMIT;
