-- PG052 Lorehold Variant 02 card oracle metadata apply.
\echo 'PG052 Lorehold Variant 02 card oracle metadata apply'

BEGIN;

CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit;

DROP TABLE IF EXISTS manaloom_deploy_audit.pg052_lorehold_variant02_card_oracle_metadata_20260623_011834;

CREATE TABLE manaloom_deploy_audit.pg052_lorehold_variant02_card_oracle_metadata_20260623_011834 AS
WITH expected(name, oracle_id) AS (
  VALUES
    ('Molecule Man', 'ba944437-0b55-47cb-92dc-2477ce6726c3'::uuid),
    ('The Mind Stone', 'b175e826-09e8-4fae-9f2e-b902f95b282d'::uuid),
    ('The Scarlet Witch', 'd8ae8c38-501e-44ea-9faf-cf9d11ba6616'::uuid),
    ('Thor, God of Thunder', '2842217a-173e-4879-8b25-fefe2fc1123f'::uuid)
)
SELECT c.*
FROM cards c
JOIN expected e
  ON lower(c.name) = lower(e.name)
  OR c.oracle_id = e.oracle_id
  OR c.scryfall_id = e.oracle_id;

DO $$
DECLARE
  v_existing_core integer;
  v_conflicts integer;
BEGIN
  SELECT count(*) INTO v_existing_core
  FROM cards
  WHERE lower(name) IN ('the mind stone', 'the scarlet witch', 'thor, god of thunder');

  IF v_existing_core <> 3 THEN
    RAISE EXCEPTION 'PG052 precondition failed: existing Marvel core rows=% expected 3', v_existing_core;
  END IF;

  WITH expected(name, oracle_id) AS (
    VALUES
      ('Molecule Man', 'ba944437-0b55-47cb-92dc-2477ce6726c3'::uuid),
      ('The Mind Stone', 'b175e826-09e8-4fae-9f2e-b902f95b282d'::uuid),
      ('The Scarlet Witch', 'd8ae8c38-501e-44ea-9faf-cf9d11ba6616'::uuid),
      ('Thor, God of Thunder', '2842217a-173e-4879-8b25-fefe2fc1123f'::uuid)
  )
  SELECT count(*) INTO v_conflicts
  FROM expected e
  JOIN cards c
    ON c.oracle_id = e.oracle_id
    OR c.scryfall_id = e.oracle_id
  WHERE lower(c.name) <> lower(e.name);

  IF v_conflicts <> 0 THEN
    RAISE EXCEPTION 'PG052 precondition failed: oracle_id conflict rows=%', v_conflicts;
  END IF;
END $$;

WITH source_cards(
  name, oracle_id, mana_cost, type_line, oracle_text, colors, color_identity,
  cmc, power, toughness, keywords, set_code, rarity, collector_number, layout,
  image_url, is_reserved
) AS (
  VALUES
    (
      'Molecule Man',
      'ba944437-0b55-47cb-92dc-2477ce6726c3'::uuid,
      '{6}',
      'Legendary Creature — Human Villain',
      'Nonland cards in your hand have miracle {0}. (You may cast a card for its miracle cost when you draw it if it''s the first card you drew this turn.)',
      ARRAY[]::text[],
      ARRAY[]::text[],
      6::numeric,
      '5',
      '5',
      ARRAY[]::text[],
      'msc',
      'rare',
      '9',
      'normal',
      'https://cards.scryfall.io/normal/front/e/e/ee64d0dd-e3d8-4abc-b9d6-b19c505fbfa1.jpg?1781099776',
      false
    ),
    (
      'The Mind Stone',
      'b175e826-09e8-4fae-9f2e-b902f95b282d'::uuid,
      '{1}{W}',
      'Legendary Artifact — Infinity Stone',
      'Indestructible
{T}: Add {W}.
{5}{W}, {T}: Harness The Mind Stone. (Once harnessed, its ∞ ability is active.)
∞ — At the beginning of your end step, exile up to one other target nonland permanent you control, then return that card to the battlefield under its owner''s control.',
      ARRAY['W']::text[],
      ARRAY['W']::text[],
      2::numeric,
      NULL,
      NULL,
      ARRAY[]::text[],
      'msh',
      'mythic',
      '21',
      'normal',
      'https://cards.scryfall.io/normal/front/8/7/87f1e69a-6d74-4982-afda-82613637799a.jpg?1780414743',
      false
    ),
    (
      'The Scarlet Witch',
      'd8ae8c38-501e-44ea-9faf-cf9d11ba6616'::uuid,
      '{2}{R}',
      'Legendary Creature — Mutant Warlock Hero',
      'Instant and sorcery spells you cast with mana value 4 or greater cost {X} less to cast, where X is The Scarlet Witch''s power.',
      ARRAY['R']::text[],
      ARRAY['R']::text[],
      3::numeric,
      '2',
      '3',
      ARRAY[]::text[],
      'msh',
      'rare',
      '151',
      'normal',
      'https://cards.scryfall.io/normal/front/4/0/407e8993-e56d-477d-ab85-d10a2522eab3.jpg?1780413670',
      false
    ),
    (
      'Thor, God of Thunder',
      '2842217a-173e-4879-8b25-fefe2fc1123f'::uuid,
      '{3}{R}{R}',
      'Legendary Creature — God Warrior Hero',
      'Flying
When Thor enters, exile target Equipment, instant, or sorcery card from your graveyard. Until the end of your next turn, you may play that card.
Whenever you cast a noncreature spell, Thor deals damage equal to that spell''s mana value to any target.',
      ARRAY['R']::text[],
      ARRAY['R']::text[],
      5::numeric,
      '5',
      '5',
      ARRAY['Flying']::text[],
      'msh',
      'mythic',
      '156',
      'normal',
      'https://cards.scryfall.io/normal/front/c/d/cddd314c-c271-475a-b076-01a8599c8015.jpg?1780413681',
      false
    )
)
UPDATE cards c
SET
  mana_cost = s.mana_cost,
  type_line = s.type_line,
  oracle_text = s.oracle_text,
  colors = s.colors,
  color_identity = s.color_identity,
  cmc = s.cmc,
  power = s.power,
  toughness = s.toughness,
  keywords = s.keywords,
  set_code = s.set_code,
  rarity = s.rarity,
  collector_number = s.collector_number,
  layout = s.layout,
  image_url = s.image_url,
  is_reserved = s.is_reserved,
  oracle_id = s.oracle_id
FROM source_cards s
WHERE lower(c.name) = lower(s.name)
   OR c.oracle_id = s.oracle_id
   OR c.scryfall_id = s.oracle_id;

INSERT INTO cards (
  id, scryfall_id, name, mana_cost, type_line, oracle_text, colors,
  image_url, set_code, rarity, created_at, price, ai_description,
  color_identity, price_updated_at, price_usd, price_usd_foil, cmc,
  collector_number, foil, edhrec_rank, is_reserved, power, toughness,
  keywords, oracle_id, layout, card_faces_json
)
SELECT
  'ee64d0dd-e3d8-4abc-b9d6-b19c505fbfa1'::uuid,
  s.oracle_id,
  s.name,
  s.mana_cost,
  s.type_line,
  s.oracle_text,
  s.colors,
  s.image_url,
  s.set_code,
  s.rarity,
  now(),
  NULL::numeric,
  NULL::text,
  s.color_identity,
  NULL::timestamptz,
  NULL::numeric,
  NULL::numeric,
  s.cmc,
  s.collector_number,
  false,
  NULL::integer,
  s.is_reserved,
  s.power,
  s.toughness,
  s.keywords,
  s.oracle_id,
  s.layout,
  NULL::jsonb
FROM (
  SELECT
    'Molecule Man'::text AS name,
    'ba944437-0b55-47cb-92dc-2477ce6726c3'::uuid AS oracle_id,
    '{6}'::text AS mana_cost,
    'Legendary Creature — Human Villain'::text AS type_line,
    'Nonland cards in your hand have miracle {0}. (You may cast a card for its miracle cost when you draw it if it''s the first card you drew this turn.)'::text AS oracle_text,
    ARRAY[]::text[] AS colors,
    ARRAY[]::text[] AS color_identity,
    6::numeric AS cmc,
    '5'::text AS power,
    '5'::text AS toughness,
    ARRAY[]::text[] AS keywords,
    'msc'::text AS set_code,
    'rare'::text AS rarity,
    '9'::text AS collector_number,
    'normal'::text AS layout,
    'https://cards.scryfall.io/normal/front/e/e/ee64d0dd-e3d8-4abc-b9d6-b19c505fbfa1.jpg?1781099776'::text AS image_url,
    false AS is_reserved
) s
WHERE NOT EXISTS (
  SELECT 1 FROM cards c
  WHERE lower(c.name) = lower(s.name)
     OR c.oracle_id = s.oracle_id
     OR c.scryfall_id = s.oracle_id
);

DO $$
DECLARE
  v_rows integer;
  v_bad_cmc integer;
  v_missing_oracle integer;
BEGIN
  WITH expected(name, oracle_id, expected_cmc) AS (
    VALUES
      ('Molecule Man', 'ba944437-0b55-47cb-92dc-2477ce6726c3'::uuid, 6::numeric),
      ('The Mind Stone', 'b175e826-09e8-4fae-9f2e-b902f95b282d'::uuid, 2::numeric),
      ('The Scarlet Witch', 'd8ae8c38-501e-44ea-9faf-cf9d11ba6616'::uuid, 3::numeric),
      ('Thor, God of Thunder', '2842217a-173e-4879-8b25-fefe2fc1123f'::uuid, 5::numeric)
  )
  SELECT count(*) INTO v_rows
  FROM expected e
  JOIN cards c
    ON lower(c.name) = lower(e.name)
    OR c.oracle_id = e.oracle_id
    OR c.scryfall_id = e.oracle_id;

  WITH expected(name, oracle_id, expected_cmc) AS (
    VALUES
      ('Molecule Man', 'ba944437-0b55-47cb-92dc-2477ce6726c3'::uuid, 6::numeric),
      ('The Mind Stone', 'b175e826-09e8-4fae-9f2e-b902f95b282d'::uuid, 2::numeric),
      ('The Scarlet Witch', 'd8ae8c38-501e-44ea-9faf-cf9d11ba6616'::uuid, 3::numeric),
      ('Thor, God of Thunder', '2842217a-173e-4879-8b25-fefe2fc1123f'::uuid, 5::numeric)
  )
  SELECT count(*) INTO v_bad_cmc
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
  SELECT count(*) INTO v_missing_oracle
  FROM expected e
  JOIN cards c
    ON lower(c.name) = lower(e.name)
    OR c.oracle_id = e.oracle_id
    OR c.scryfall_id = e.oracle_id
  WHERE COALESCE(c.oracle_text, '') = '';

  IF v_rows <> 4 OR v_bad_cmc <> 0 OR v_missing_oracle <> 0 THEN
    RAISE EXCEPTION 'PG052 postcondition failed: rows=%, bad_cmc=%, missing_oracle=%',
      v_rows, v_bad_cmc, v_missing_oracle;
  END IF;
END $$;

COMMIT;
