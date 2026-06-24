\pset pager off
-- PG register precheck for Lorehold Variant 07.
-- No writes outside TEMP tables.
DROP TABLE IF EXISTS tmp_lorehold_variant07_input;
CREATE TEMP TABLE tmp_lorehold_variant07_input(ord int, card_name text, quantity int, is_commander boolean);
INSERT INTO tmp_lorehold_variant07_input(ord, card_name, quantity, is_commander) VALUES
  (1, 'Lorehold, the Historian'::text, 1::int, true::boolean),
  (2, 'Agate Instigator'::text, 1::int, false::boolean),
  (3, 'Ancient Gold Dragon'::text, 1::int, false::boolean),
  (4, 'Ancient Tomb'::text, 1::int, false::boolean),
  (5, 'Approach of the Second Sun'::text, 1::int, false::boolean),
  (6, 'Arcane Signet'::text, 1::int, false::boolean),
  (7, 'Arena of Glory'::text, 1::int, false::boolean),
  (8, 'Arid Mesa'::text, 1::int, false::boolean),
  (9, 'Artist''s Talent'::text, 1::int, false::boolean),
  (10, 'Austere Command'::text, 1::int, false::boolean),
  (11, 'Barbarian Ring'::text, 1::int, false::boolean),
  (12, 'Basalt Monolith'::text, 1::int, false::boolean),
  (13, 'Birgi, God of Storytelling // Harnfel, Horn of Bounty'::text, 1::int, false::boolean),
  (14, 'Blasphemous Act'::text, 1::int, false::boolean),
  (15, 'Bloodstained Mire'::text, 1::int, false::boolean),
  (16, 'Boros Charm'::text, 1::int, false::boolean),
  (17, 'Boros Reckoner'::text, 1::int, false::boolean),
  (18, 'Boseiju, Who Shelters All'::text, 1::int, false::boolean),
  (19, 'Brass''s Bounty'::text, 1::int, false::boolean),
  (20, 'Call Forth the Tempest'::text, 1::int, false::boolean),
  (21, 'Cavern of Souls'::text, 1::int, false::boolean),
  (22, 'Charmbreaker Devils'::text, 1::int, false::boolean),
  (23, 'City of Brass'::text, 1::int, false::boolean),
  (24, 'City of Traitors'::text, 1::int, false::boolean),
  (25, 'Cloud Key'::text, 1::int, false::boolean),
  (26, 'Command Tower'::text, 1::int, false::boolean),
  (27, 'Crystal Vein'::text, 1::int, false::boolean),
  (28, 'Dualcaster Mage'::text, 1::int, false::boolean),
  (29, 'Eiganjo, Seat of the Empire'::text, 1::int, false::boolean),
  (30, 'Elegant Parlor'::text, 1::int, false::boolean),
  (31, 'Enlightened Tutor'::text, 1::int, false::boolean),
  (32, 'Ephemerate'::text, 1::int, false::boolean),
  (33, 'Flare of Duplication'::text, 1::int, false::boolean),
  (34, 'Flooded Strand'::text, 1::int, false::boolean),
  (35, 'Forbidden Orchard'::text, 1::int, false::boolean),
  (36, 'Fury Storm'::text, 1::int, false::boolean),
  (37, 'Gamble'::text, 1::int, false::boolean),
  (38, 'Gemstone Caverns'::text, 1::int, false::boolean),
  (39, 'Gisela, Blade of Goldnight'::text, 1::int, false::boolean),
  (40, 'Grinding Station'::text, 1::int, false::boolean),
  (41, 'Heat Shimmer'::text, 1::int, false::boolean),
  (42, 'Helm of Awakening'::text, 1::int, false::boolean),
  (43, 'Impact Tremors'::text, 1::int, false::boolean),
  (44, 'Increasing Vengeance'::text, 1::int, false::boolean),
  (45, 'Jeska''s Will'::text, 1::int, false::boolean),
  (46, 'Library of Leng'::text, 1::int, false::boolean),
  (47, 'Lion''s Eye Diamond'::text, 1::int, false::boolean),
  (48, 'Longshot, Rebel Bowman'::text, 1::int, false::boolean),
  (49, 'Mana Confluence'::text, 1::int, false::boolean),
  (50, 'Mana Geyser'::text, 1::int, false::boolean),
  (51, 'Mana Vault'::text, 1::int, false::boolean),
  (52, 'Marsh Flats'::text, 1::int, false::boolean),
  (53, 'Mizzix''s Mastery'::text, 1::int, false::boolean),
  (54, 'Molten Duplication'::text, 1::int, false::boolean),
  (55, 'Molten Gatekeeper'::text, 1::int, false::boolean),
  (56, 'Monologue Tax'::text, 1::int, false::boolean),
  (57, 'Past in Flames'::text, 1::int, false::boolean),
  (58, 'Pearl Medallion'::text, 1::int, false::boolean),
  (59, 'Plains // Plains'::text, 1::int, false::boolean),
  (60, 'Plateau'::text, 1::int, false::boolean),
  (61, 'Purphoros, God of the Forge'::text, 1::int, false::boolean),
  (62, 'Pyromancer''s Goggles'::text, 1::int, false::boolean),
  (63, 'Red Elemental Blast'::text, 1::int, false::boolean),
  (64, 'Reforge the Soul'::text, 1::int, false::boolean),
  (65, 'Reiterate'::text, 1::int, false::boolean),
  (66, 'Rem Karolus, Stalwart Slayer'::text, 1::int, false::boolean),
  (67, 'Repercussion'::text, 1::int, false::boolean),
  (68, 'Reprieve'::text, 1::int, false::boolean),
  (69, 'Restoration Seminar'::text, 1::int, false::boolean),
  (70, 'Return the Favor'::text, 1::int, false::boolean),
  (71, 'Reverberate'::text, 1::int, false::boolean),
  (72, 'Ruby Medallion'::text, 1::int, false::boolean),
  (73, 'Sacred Foundry'::text, 1::int, false::boolean),
  (74, 'Scalding Tarn'::text, 1::int, false::boolean),
  (75, 'Scroll Rack'::text, 1::int, false::boolean),
  (76, 'Seething Song'::text, 1::int, false::boolean),
  (77, 'Semblance Anvil'::text, 1::int, false::boolean),
  (78, 'Sensei''s Divining Top'::text, 1::int, false::boolean),
  (79, 'Shivan Gorge'::text, 1::int, false::boolean),
  (80, 'Silence'::text, 1::int, false::boolean),
  (81, 'Smothering Tithe'::text, 1::int, false::boolean),
  (82, 'Sokenzan, Crucible of Defiance'::text, 1::int, false::boolean),
  (83, 'Sol Ring'::text, 1::int, false::boolean),
  (84, 'Starfall Invocation'::text, 1::int, false::boolean),
  (85, 'Storm-Kiln Artist'::text, 1::int, false::boolean),
  (86, 'Taii Wakeen, Perfect Shot'::text, 1::int, false::boolean),
  (87, 'Teferi''s Protection'::text, 1::int, false::boolean),
  (88, 'Terror of the Peaks'::text, 1::int, false::boolean),
  (89, 'Toralf, God of Fury // Toralf''s Hammer'::text, 1::int, false::boolean),
  (90, 'Twinflame'::text, 1::int, false::boolean),
  (91, 'Ultima'::text, 1::int, false::boolean),
  (92, 'Underworld Breach'::text, 1::int, false::boolean),
  (93, 'Urza''s Saga'::text, 1::int, false::boolean),
  (94, 'Warleader''s Call'::text, 1::int, false::boolean),
  (95, 'Wheel of Fortune'::text, 1::int, false::boolean),
  (96, 'Wild Ricochet'::text, 1::int, false::boolean),
  (97, 'Windswept Heath'::text, 1::int, false::boolean),
  (98, 'Wooded Foothills'::text, 1::int, false::boolean),
  (99, 'Young Pyromancer'::text, 1::int, false::boolean),
  (100, 'Zirda, the Dawnwaker'::text, 1::int, false::boolean);

DROP TABLE IF EXISTS tmp_lorehold_variant07_picked;
CREATE TEMP TABLE tmp_lorehold_variant07_picked AS
WITH candidates AS (
  SELECT
    i.*,
    c.id AS card_id,
    c.name AS pg_name,
    c.set_code,
    c.collector_number,
    ROW_NUMBER() OVER (
      PARTITION BY i.ord
      ORDER BY
        CASE
          WHEN lower(c.name) = lower(i.card_name) THEN 0
          WHEN lower(split_part(c.name, ' // ', 1)) = lower(split_part(i.card_name, ' // ', 1)) THEN 1
          ELSE 2
        END,
        c.oracle_id NULLS LAST,
        c.set_code NULLS LAST,
        c.collector_number NULLS LAST,
        c.id
    ) AS rn
  FROM tmp_lorehold_variant07_input i
  LEFT JOIN cards c
    ON lower(c.name) = lower(i.card_name)
    OR lower(split_part(c.name, ' // ', 1)) = lower(split_part(i.card_name, ' // ', 1))
)
SELECT * FROM candidates WHERE rn = 1 OR card_id IS NULL;


SELECT
  'pg_lorehold_variant07_precheck_coverage' AS check_name,
  COUNT(*) AS input_rows,
  COALESCE(SUM(quantity),0)::int AS input_qty,
  COALESCE(SUM(CASE WHEN is_commander THEN quantity ELSE 0 END),0)::int AS commander_qty,
  COUNT(card_id) AS resolved_rows,
  COUNT(*) FILTER (WHERE card_id IS NULL) AS missing_rows
FROM tmp_lorehold_variant07_picked;

SELECT 'pg_lorehold_variant07_missing_card' AS check_name, ord, card_name, quantity, is_commander
FROM tmp_lorehold_variant07_picked
WHERE card_id IS NULL
ORDER BY ord;

SELECT
  'pg_lorehold_variant07_existing_target' AS check_name,
  (SELECT COUNT(*) FROM decks WHERE id = '231281c3-e6a2-579b-93fe-21ddfdd13bda'::uuid) AS deck_rows,
  (SELECT COALESCE(SUM(quantity),0)::int FROM deck_cards WHERE deck_id = '231281c3-e6a2-579b-93fe-21ddfdd13bda'::uuid) AS deck_qty,
  (SELECT COUNT(*) FROM commander_learned_decks WHERE source_system = 'manual_user_deck_registration' AND source_ref = 'lorehold_variant07_20260624_5570c465c492') AS learned_rows;
