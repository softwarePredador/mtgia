\pset pager off
-- PG register precheck for Lorehold Variant 08.
-- No writes outside TEMP tables.
DROP TABLE IF EXISTS tmp_lorehold_variant08_input;
CREATE TEMP TABLE tmp_lorehold_variant08_input(ord int, card_name text, quantity int, is_commander boolean);
INSERT INTO tmp_lorehold_variant08_input(ord, card_name, quantity, is_commander) VALUES
  (1, 'Lorehold, the Historian'::text, 1::int, true::boolean),
  (2, 'Ancient Tomb'::text, 1::int, false::boolean),
  (3, 'Apex of Power'::text, 1::int, false::boolean),
  (4, 'Approach of the Second Sun'::text, 1::int, false::boolean),
  (5, 'Arcane Signet'::text, 1::int, false::boolean),
  (6, 'Armageddon'::text, 1::int, false::boolean),
  (7, 'Bender''s Waterskin'::text, 1::int, false::boolean),
  (8, 'Big Score'::text, 1::int, false::boolean),
  (9, 'Bloodstained Mire'::text, 1::int, false::boolean),
  (10, 'Boros Charm'::text, 1::int, false::boolean),
  (11, 'Boseiju, Who Shelters All'::text, 1::int, false::boolean),
  (12, 'Brass''s Bounty'::text, 1::int, false::boolean),
  (13, 'Call Forth the Tempest'::text, 1::int, false::boolean),
  (14, 'Chandra''s Ignition'::text, 1::int, false::boolean),
  (15, 'Chrome Mox'::text, 1::int, false::boolean),
  (16, 'City of Brass'::text, 1::int, false::boolean),
  (17, 'Command Tower'::text, 1::int, false::boolean),
  (18, 'Cool but Rude'::text, 1::int, false::boolean),
  (19, 'Dance with Calamity'::text, 1::int, false::boolean),
  (20, 'Dawn''s Truce'::text, 1::int, false::boolean),
  (21, 'Deflecting Swat'::text, 1::int, false::boolean),
  (22, 'Double Vision'::text, 1::int, false::boolean),
  (23, 'Dragon''s Rage Channeler'::text, 1::int, false::boolean),
  (24, 'Dualcaster Mage'::text, 1::int, false::boolean),
  (25, 'Elegant Parlor'::text, 1::int, false::boolean),
  (26, 'Enlightened Tutor'::text, 1::int, false::boolean),
  (27, 'Esper Sentinel'::text, 1::int, false::boolean),
  (28, 'Farewell'::text, 1::int, false::boolean),
  (29, 'Galvanoth'::text, 1::int, false::boolean),
  (30, 'Gamble'::text, 1::int, false::boolean),
  (31, 'Gemstone Caverns'::text, 1::int, false::boolean),
  (32, 'Ghostly Prison'::text, 1::int, false::boolean),
  (33, 'Glint-Horn Buccaneer'::text, 1::int, false::boolean),
  (34, 'Goliath Daydreamer'::text, 1::int, false::boolean),
  (35, 'Grand Abolisher'::text, 1::int, false::boolean),
  (36, 'Hexing Squelcher'::text, 1::int, false::boolean),
  (37, 'Hit the Mother Lode'::text, 1::int, false::boolean),
  (38, 'Improvisation Capstone'::text, 1::int, false::boolean),
  (39, 'Jeska''s Will'::text, 1::int, false::boolean),
  (40, 'Land Tax'::text, 1::int, false::boolean),
  (41, 'Library of Leng'::text, 1::int, false::boolean),
  (42, 'Longshot, Rebel Bowman'::text, 1::int, false::boolean),
  (43, 'Lotus Petal'::text, 1::int, false::boolean),
  (44, 'Mana Vault'::text, 1::int, false::boolean),
  (45, 'Marsh Flats'::text, 1::int, false::boolean),
  (46, 'Mizzix''s Mastery'::text, 1::int, false::boolean),
  (47, 'Monument to Endurance'::text, 1::int, false::boolean),
  (48, 'Mountain // Mountain'::text, 6::int, false::boolean),
  (49, 'Olórin''s Searing Light'::text, 1::int, false::boolean),
  (50, 'Path to Exile'::text, 1::int, false::boolean),
  (51, 'Penance'::text, 1::int, false::boolean),
  (52, 'Perch Protection'::text, 1::int, false::boolean),
  (53, 'Plains // Plains'::text, 5::int, false::boolean),
  (54, 'Planetarium of Wan Shi Tong'::text, 1::int, false::boolean),
  (55, 'Plateau'::text, 1::int, false::boolean),
  (56, 'Red Elemental Blast'::text, 1::int, false::boolean),
  (57, 'Redirect Lightning'::text, 1::int, false::boolean),
  (58, 'Reforge the Soul'::text, 1::int, false::boolean),
  (59, 'Reliquary Tower'::text, 1::int, false::boolean),
  (60, 'Reprieve'::text, 1::int, false::boolean),
  (61, 'Reverberate'::text, 1::int, false::boolean),
  (62, 'Rise of the Eldrazi'::text, 1::int, false::boolean),
  (63, 'Sacred Foundry'::text, 1::int, false::boolean),
  (64, 'Scroll Rack'::text, 1::int, false::boolean),
  (65, 'Sensei''s Divining Top'::text, 1::int, false::boolean),
  (66, 'Shinka, the Bloodsoaked Keep'::text, 1::int, false::boolean),
  (67, 'Silence'::text, 1::int, false::boolean),
  (68, 'Smothering Tithe'::text, 1::int, false::boolean),
  (69, 'Sol Ring'::text, 1::int, false::boolean),
  (70, 'Soulfire Eruption'::text, 1::int, false::boolean),
  (71, 'Spectator Seating'::text, 1::int, false::boolean),
  (72, 'Starting Town'::text, 1::int, false::boolean),
  (73, 'Storm Herd'::text, 1::int, false::boolean),
  (74, 'Storm-Kiln Artist'::text, 1::int, false::boolean),
  (75, 'Sunbillow Verge'::text, 1::int, false::boolean),
  (76, 'Sundown Pass'::text, 1::int, false::boolean),
  (77, 'Teferi''s Protection'::text, 1::int, false::boolean),
  (78, 'Temple of Triumph'::text, 1::int, false::boolean),
  (79, 'Tezzeret, Cruel Captain'::text, 1::int, false::boolean),
  (80, 'The Biblioplex'::text, 1::int, false::boolean),
  (81, 'The One Ring'::text, 1::int, false::boolean),
  (82, 'Twinflame'::text, 1::int, false::boolean),
  (83, 'Unexpected Windfall'::text, 1::int, false::boolean),
  (84, 'Unwinding Clock'::text, 1::int, false::boolean),
  (85, 'Urza''s Saga'::text, 1::int, false::boolean),
  (86, 'Vedalken Orrery'::text, 1::int, false::boolean),
  (87, 'Verge Rangers'::text, 1::int, false::boolean),
  (88, 'Victory Chimes'::text, 1::int, false::boolean),
  (89, 'Volcanic Vision'::text, 1::int, false::boolean),
  (90, 'Windswept Heath'::text, 1::int, false::boolean),
  (91, 'Zhalfirin Void'::text, 1::int, false::boolean);

DROP TABLE IF EXISTS tmp_lorehold_variant08_picked;
CREATE TEMP TABLE tmp_lorehold_variant08_picked AS
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
  FROM tmp_lorehold_variant08_input i
  LEFT JOIN cards c
    ON lower(c.name) = lower(i.card_name)
    OR lower(split_part(c.name, ' // ', 1)) = lower(split_part(i.card_name, ' // ', 1))
)
SELECT * FROM candidates WHERE rn = 1 OR card_id IS NULL;


SELECT
  'pg_lorehold_variant08_precheck_coverage' AS check_name,
  COUNT(*) AS input_rows,
  COALESCE(SUM(quantity),0)::int AS input_qty,
  COALESCE(SUM(CASE WHEN is_commander THEN quantity ELSE 0 END),0)::int AS commander_qty,
  COUNT(card_id) AS resolved_rows,
  COUNT(*) FILTER (WHERE card_id IS NULL) AS missing_rows
FROM tmp_lorehold_variant08_picked;

SELECT 'pg_lorehold_variant08_missing_card' AS check_name, ord, card_name, quantity, is_commander
FROM tmp_lorehold_variant08_picked
WHERE card_id IS NULL
ORDER BY ord;

SELECT
  'pg_lorehold_variant08_existing_target' AS check_name,
  (SELECT COUNT(*) FROM decks WHERE id = '6df74eb3-c4a7-5398-bcf5-febb38d80d7a'::uuid) AS deck_rows,
  (SELECT COALESCE(SUM(quantity),0)::int FROM deck_cards WHERE deck_id = '6df74eb3-c4a7-5398-bcf5-febb38d80d7a'::uuid) AS deck_qty,
  (SELECT COUNT(*) FROM commander_learned_decks WHERE source_system = 'manual_user_deck_registration' AND source_ref = 'lorehold_variant08_20260624_1a76c69c236f') AS learned_rows;
