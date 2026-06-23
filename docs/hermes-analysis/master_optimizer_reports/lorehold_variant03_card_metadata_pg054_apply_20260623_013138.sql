-- PG054 Lorehold Variant 03 card metadata apply.
\echo 'PG054 Lorehold Variant 03 card metadata apply'

BEGIN;

CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit;

DROP TABLE IF EXISTS manaloom_deploy_audit.pg054_lorehold_variant03_card_metadata_20260623_013138;

CREATE TABLE manaloom_deploy_audit.pg054_lorehold_variant03_card_metadata_20260623_013138 AS
SELECT *
FROM cards
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

DO $$
DECLARE
  v_rows integer;
BEGIN
  SELECT count(*) INTO v_rows
  FROM manaloom_deploy_audit.pg054_lorehold_variant03_card_metadata_20260623_013138;

  IF v_rows <> 2 THEN
    RAISE EXCEPTION 'PG054 precondition failed: backup rows=% expected 2', v_rows;
  END IF;
END $$;

UPDATE cards
SET
  cmc = 3,
  rarity = 'rare',
  collector_number = '33',
  layout = 'prepare',
  card_faces_json = '[
    {
      "object": "card_face",
      "name": "Naktamun Lorespinner",
      "mana_cost": "{2}{R}",
      "type_line": "Creature — Jackal Wizard",
      "oracle_text": "At the beginning of your upkeep, if a player has one or fewer cards in hand, this creature becomes prepared. (While it''s prepared, you may cast a copy of its spell. Doing so unprepares it.)",
      "power": "3",
      "toughness": "3"
    },
    {
      "object": "card_face",
      "name": "Wheel of Fortune",
      "mana_cost": "{2}{R}",
      "type_line": "Sorcery",
      "oracle_text": "Each player discards their hand, then draws seven cards."
    }
  ]'::jsonb
WHERE lower(name) = lower('Naktamun Lorespinner // Wheel of Fortune')
   OR lower(split_part(name, ' // ', 1)) = lower('Naktamun Lorespinner')
   OR oracle_id = 'c78783e5-868d-4a8b-a4f8-95a92853cf0a'::uuid
   OR scryfall_id = 'c78783e5-868d-4a8b-a4f8-95a92853cf0a'::uuid;

UPDATE cards
SET
  cmc = 3,
  rarity = 'uncommon',
  collector_number = '132',
  layout = 'normal'
WHERE lower(name) = lower('Tablet of Discovery')
   OR oracle_id = '19cf5798-4600-4a66-b1c7-de77bde157d0'::uuid
   OR scryfall_id = '19cf5798-4600-4a66-b1c7-de77bde157d0'::uuid;

DO $$
DECLARE
  v_bad_cmc integer;
  v_missing_faces integer;
BEGIN
  WITH expected(name, oracle_id, expected_cmc) AS (
    VALUES
      ('Naktamun Lorespinner // Wheel of Fortune', 'c78783e5-868d-4a8b-a4f8-95a92853cf0a'::uuid, 3::numeric),
      ('Tablet of Discovery', '19cf5798-4600-4a66-b1c7-de77bde157d0'::uuid, 3::numeric)
  )
  SELECT count(*) INTO v_bad_cmc
  FROM expected e
  JOIN cards c
    ON lower(c.name) = lower(e.name)
    OR lower(split_part(c.name, ' // ', 1)) = lower(split_part(e.name, ' // ', 1))
    OR c.oracle_id = e.oracle_id
    OR c.scryfall_id = e.oracle_id
  WHERE c.cmc IS DISTINCT FROM e.expected_cmc;

  SELECT count(*) INTO v_missing_faces
  FROM cards c
  WHERE (lower(c.name) = lower('Naktamun Lorespinner // Wheel of Fortune')
     OR c.oracle_id = 'c78783e5-868d-4a8b-a4f8-95a92853cf0a'::uuid)
    AND c.card_faces_json IS NULL;

  IF v_bad_cmc <> 0 OR v_missing_faces <> 0 THEN
    RAISE EXCEPTION 'PG054 postcondition failed: bad_cmc=%, missing_faces=%',
      v_bad_cmc, v_missing_faces;
  END IF;
END $$;

COMMIT;
