\pset pager off
-- PG register precheck for Lorehold Variant 06.
-- No writes outside TEMP tables.
DROP TABLE IF EXISTS tmp_lorehold_variant06_input;
CREATE TEMP TABLE tmp_lorehold_variant06_input(ord int, card_name text, quantity int, is_commander boolean);
INSERT INTO tmp_lorehold_variant06_input(ord, card_name, quantity, is_commander) VALUES
  (1, 'Lorehold, the Historian'::text, 1::int, true::boolean),
  (2, 'Alhammarret''s Archive'::text, 1::int, false::boolean),
  (3, 'Apex of Power'::text, 1::int, false::boolean),
  (4, 'Arcane Bombardment'::text, 1::int, false::boolean),
  (5, 'Arcane Signet'::text, 1::int, false::boolean),
  (6, 'Arid Mesa'::text, 1::int, false::boolean),
  (7, 'Ashling, Flame Dancer'::text, 1::int, false::boolean),
  (8, 'Austere Command'::text, 1::int, false::boolean),
  (9, 'Battlefield Forge'::text, 1::int, false::boolean),
  (10, 'Bender''s Waterskin'::text, 1::int, false::boolean),
  (11, 'Big Score'::text, 1::int, false::boolean),
  (12, 'Bloodstained Mire'::text, 1::int, false::boolean),
  (13, 'Boros Signet'::text, 1::int, false::boolean),
  (14, 'Brass''s Bounty'::text, 1::int, false::boolean),
  (15, 'Call Forth the Tempest'::text, 1::int, false::boolean),
  (16, 'Chaos Warp'::text, 1::int, false::boolean),
  (17, 'Clifftop Retreat'::text, 1::int, false::boolean),
  (18, 'Command Tower'::text, 1::int, false::boolean),
  (19, 'Crackle with Power'::text, 1::int, false::boolean),
  (20, 'Dance with Calamity'::text, 1::int, false::boolean),
  (21, 'Deflecting Swat'::text, 1::int, false::boolean),
  (22, 'Dualcaster Mage'::text, 1::int, false::boolean),
  (23, 'Electro, Assaulting Battery'::text, 1::int, false::boolean),
  (24, 'Elegant Parlor'::text, 1::int, false::boolean),
  (25, 'Enlightened Tutor'::text, 1::int, false::boolean),
  (26, 'Esper Sentinel'::text, 1::int, false::boolean),
  (27, 'Faithless Looting'::text, 1::int, false::boolean),
  (28, 'Fellwar Stone'::text, 1::int, false::boolean),
  (29, 'Fire Nation Palace'::text, 1::int, false::boolean),
  (30, 'Flooded Strand'::text, 1::int, false::boolean),
  (31, 'Galvanoth'::text, 1::int, false::boolean),
  (32, 'Goblin Engineer'::text, 1::int, false::boolean),
  (33, 'Goldspan Dragon'::text, 1::int, false::boolean),
  (34, 'Hit the Mother Lode'::text, 1::int, false::boolean),
  (35, 'Improvisation Capstone'::text, 1::int, false::boolean),
  (36, 'Insurrection'::text, 1::int, false::boolean),
  (37, 'Land Tax'::text, 1::int, false::boolean),
  (38, 'Library of Leng'::text, 1::int, false::boolean),
  (39, 'Longshot, Rebel Bowman'::text, 1::int, false::boolean),
  (40, 'Mizzix''s Mastery'::text, 1::int, false::boolean),
  (41, 'Monument to Endurance'::text, 1::int, false::boolean),
  (42, 'Mountain // Mountain'::text, 7::int, false::boolean),
  (43, 'Multiversal Passage'::text, 1::int, false::boolean),
  (44, 'Needleverge Pathway // Pillarverge Pathway'::text, 1::int, false::boolean),
  (45, 'Palantír of Orthanc'::text, 1::int, false::boolean),
  (46, 'Penance'::text, 1::int, false::boolean),
  (47, 'Perch Protection'::text, 1::int, false::boolean),
  (48, 'Pinnacle Monk // Mystic Peak'::text, 1::int, false::boolean),
  (49, 'Plains // Plains'::text, 5::int, false::boolean),
  (50, 'Planetarium of Wan Shi Tong'::text, 1::int, false::boolean),
  (51, 'Plateau'::text, 1::int, false::boolean),
  (52, 'Prismatic Vista'::text, 1::int, false::boolean),
  (53, 'Profound Journey'::text, 1::int, false::boolean),
  (54, 'Promise of Loyalty'::text, 1::int, false::boolean),
  (55, 'Radiant Summit'::text, 1::int, false::boolean),
  (56, 'Reckless Endeavor'::text, 1::int, false::boolean),
  (57, 'Reckless Handling'::text, 1::int, false::boolean),
  (58, 'Redirect Lightning'::text, 1::int, false::boolean),
  (59, 'Reforge the Soul'::text, 1::int, false::boolean),
  (60, 'Restoration Seminar'::text, 1::int, false::boolean),
  (61, 'Rise of the Eldrazi'::text, 1::int, false::boolean),
  (62, 'Ruby Medallion'::text, 1::int, false::boolean),
  (63, 'Rugged Prairie'::text, 1::int, false::boolean),
  (64, 'Sacred Foundry'::text, 1::int, false::boolean),
  (65, 'Scroll Rack'::text, 1::int, false::boolean),
  (66, 'Sensei''s Divining Top'::text, 1::int, false::boolean),
  (67, 'Smothering Tithe'::text, 1::int, false::boolean),
  (68, 'Sol Ring'::text, 1::int, false::boolean),
  (69, 'Spectator Seating'::text, 1::int, false::boolean),
  (70, 'Storm Herd'::text, 1::int, false::boolean),
  (71, 'Storm-Kiln Artist'::text, 1::int, false::boolean),
  (72, 'Sun Titan'::text, 1::int, false::boolean),
  (73, 'Sunbillow Verge'::text, 1::int, false::boolean),
  (74, 'Sundown Pass'::text, 1::int, false::boolean),
  (75, 'Talisman of Conviction'::text, 1::int, false::boolean),
  (76, 'Taunt from the Rampart'::text, 1::int, false::boolean),
  (77, 'Teferi''s Protection'::text, 1::int, false::boolean),
  (78, 'Temple of Triumph'::text, 1::int, false::boolean),
  (79, 'Turbulent Steppe'::text, 1::int, false::boolean),
  (80, 'Twinflame'::text, 1::int, false::boolean),
  (81, 'Twinflame Tyrant'::text, 1::int, false::boolean),
  (82, 'Unexpected Windfall'::text, 1::int, false::boolean),
  (83, 'Urza''s Saga'::text, 1::int, false::boolean),
  (84, 'Valakut Awakening // Valakut Stoneforge'::text, 1::int, false::boolean),
  (85, 'Velomachus Lorehold'::text, 1::int, false::boolean),
  (86, 'Verge Rangers'::text, 1::int, false::boolean),
  (87, 'Victory Chimes'::text, 1::int, false::boolean),
  (88, 'Volcanic Vision'::text, 1::int, false::boolean),
  (89, 'Wheel of Fate'::text, 1::int, false::boolean),
  (90, 'Wooded Foothills'::text, 1::int, false::boolean);

DROP TABLE IF EXISTS tmp_lorehold_variant06_picked;
CREATE TEMP TABLE tmp_lorehold_variant06_picked AS
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
  FROM tmp_lorehold_variant06_input i
  LEFT JOIN cards c
    ON lower(c.name) = lower(i.card_name)
    OR lower(split_part(c.name, ' // ', 1)) = lower(split_part(i.card_name, ' // ', 1))
)
SELECT * FROM candidates WHERE rn = 1 OR card_id IS NULL;


SELECT
  'pg_lorehold_variant06_precheck_coverage' AS check_name,
  COUNT(*) AS input_rows,
  COALESCE(SUM(quantity),0)::int AS input_qty,
  COALESCE(SUM(CASE WHEN is_commander THEN quantity ELSE 0 END),0)::int AS commander_qty,
  COUNT(card_id) AS resolved_rows,
  COUNT(*) FILTER (WHERE card_id IS NULL) AS missing_rows
FROM tmp_lorehold_variant06_picked;

SELECT 'pg_lorehold_variant06_missing_card' AS check_name, ord, card_name, quantity, is_commander
FROM tmp_lorehold_variant06_picked
WHERE card_id IS NULL
ORDER BY ord;

SELECT
  'pg_lorehold_variant06_existing_target' AS check_name,
  (SELECT COUNT(*) FROM decks WHERE id = '0936dae3-32c4-5fb8-9c6f-d986670de794'::uuid) AS deck_rows,
  (SELECT COALESCE(SUM(quantity),0)::int FROM deck_cards WHERE deck_id = '0936dae3-32c4-5fb8-9c6f-d986670de794'::uuid) AS deck_qty,
  (SELECT COUNT(*) FROM commander_learned_decks WHERE source_system = 'manual_user_deck_registration' AND source_ref = 'lorehold_variant06_20260624_a073b0fdc0db') AS learned_rows;
