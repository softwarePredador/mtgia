-- PG054 Lorehold Variant 03 card metadata rollback.
\echo 'PG054 Lorehold Variant 03 card metadata rollback'

BEGIN;

DELETE FROM cards
WHERE lower(name) IN (
  lower('Naktamun Lorespinner // Wheel of Fortune'),
  lower('Tablet of Discovery')
)
OR lower(split_part(name, ' // ', 1)) = lower('Naktamun Lorespinner')
OR oracle_id IN (
  'c78783e5-868d-4a8b-a4f8-95a92853cf0a'::uuid,
  '19cf5798-4600-4a66-b1c7-de77bde157d0'::uuid
)
OR scryfall_id IN (
  'c78783e5-868d-4a8b-a4f8-95a92853cf0a'::uuid,
  '19cf5798-4600-4a66-b1c7-de77bde157d0'::uuid
);

INSERT INTO cards
SELECT *
FROM manaloom_deploy_audit.pg054_lorehold_variant03_card_metadata_20260623_013138;

COMMIT;
