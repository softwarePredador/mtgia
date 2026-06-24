\pset pager off
-- PG register precheck for Lorehold Variant 09.
-- No writes outside TEMP tables.
DROP TABLE IF EXISTS tmp_lorehold_variant09_input;
CREATE TEMP TABLE tmp_lorehold_variant09_input(ord int, card_name text, quantity int, is_commander boolean);
INSERT INTO tmp_lorehold_variant09_input(ord, card_name, quantity, is_commander) VALUES
  (1, 'Lorehold, the Historian'::text, 1::int, true::boolean),
  (2, 'Aetherflux Reservoir'::text, 1::int, false::boolean),
  (3, 'Akroma''s Will'::text, 1::int, false::boolean),
  (4, 'Ancient Den'::text, 1::int, false::boolean),
  (5, 'Ancient Tomb'::text, 1::int, false::boolean),
  (6, 'Approach of the Second Sun'::text, 1::int, false::boolean),
  (7, 'Arcane Signet'::text, 1::int, false::boolean),
  (8, 'Arid Mesa'::text, 1::int, false::boolean),
  (9, 'Authority of the Consuls'::text, 1::int, false::boolean),
  (10, 'Bender''s Waterskin'::text, 1::int, false::boolean),
  (11, 'Big Score'::text, 1::int, false::boolean),
  (12, 'Blasphemous Act'::text, 1::int, false::boolean),
  (13, 'Bloodstained Mire'::text, 1::int, false::boolean),
  (14, 'Bolt Bend'::text, 1::int, false::boolean),
  (15, 'Boros Charm'::text, 1::int, false::boolean),
  (16, 'Brass''s Bounty'::text, 1::int, false::boolean),
  (17, 'Caldera Pyremaw'::text, 1::int, false::boolean),
  (18, 'Call Forth the Tempest'::text, 1::int, false::boolean),
  (19, 'Cavern of Souls'::text, 1::int, false::boolean),
  (20, 'Chrome Mox'::text, 1::int, false::boolean),
  (21, 'Clifftop Retreat'::text, 1::int, false::boolean),
  (22, 'Command Tower'::text, 1::int, false::boolean),
  (23, 'Conduit Pylons'::text, 1::int, false::boolean),
  (24, 'Creative Technique'::text, 1::int, false::boolean),
  (25, 'Currency Converter'::text, 1::int, false::boolean),
  (26, 'Dance with Calamity'::text, 1::int, false::boolean),
  (27, 'Deflecting Palm'::text, 1::int, false::boolean),
  (28, 'Deflecting Swat'::text, 1::int, false::boolean),
  (29, 'Desperate Ritual'::text, 1::int, false::boolean),
  (30, 'Dragon''s Rage Channeler'::text, 1::int, false::boolean),
  (31, 'Elegant Parlor'::text, 1::int, false::boolean),
  (32, 'Enlightened Tutor'::text, 1::int, false::boolean),
  (33, 'Esper Sentinel'::text, 1::int, false::boolean),
  (34, 'Fated Clash'::text, 1::int, false::boolean),
  (35, 'Flawless Maneuver'::text, 1::int, false::boolean),
  (36, 'Flooded Strand'::text, 1::int, false::boolean),
  (37, 'Galvanoth'::text, 1::int, false::boolean),
  (38, 'Gamble'::text, 1::int, false::boolean),
  (39, 'Generous Gift'::text, 1::int, false::boolean),
  (40, 'Goldspan Dragon'::text, 1::int, false::boolean),
  (41, 'Goliath Daydreamer'::text, 1::int, false::boolean),
  (42, 'Great Furnace'::text, 1::int, false::boolean),
  (43, 'Helm of Awakening'::text, 1::int, false::boolean),
  (44, 'Heroes Remembered'::text, 1::int, false::boolean),
  (45, 'Hexing Squelcher'::text, 1::int, false::boolean),
  (46, 'Insurrection'::text, 1::int, false::boolean),
  (47, 'Invincible Hymn'::text, 1::int, false::boolean),
  (48, 'Invoke Calamity'::text, 1::int, false::boolean),
  (49, 'Invoke Justice'::text, 1::int, false::boolean),
  (50, 'Jeska''s Will'::text, 1::int, false::boolean),
  (51, 'Land Tax'::text, 1::int, false::boolean),
  (52, 'Library of Leng'::text, 1::int, false::boolean),
  (53, 'Mana Geyser'::text, 1::int, false::boolean),
  (54, 'Marsh Flats'::text, 1::int, false::boolean),
  (55, 'Monument to Endurance'::text, 1::int, false::boolean),
  (56, 'Mother of Runes'::text, 1::int, false::boolean),
  (57, 'Mountain // Mountain'::text, 3::int, false::boolean),
  (58, 'Olórin''s Searing Light'::text, 1::int, false::boolean),
  (59, 'Pearl Medallion'::text, 1::int, false::boolean),
  (60, 'Penance'::text, 1::int, false::boolean),
  (61, 'Perch Protection'::text, 1::int, false::boolean),
  (62, 'Plains // Plains'::text, 8::int, false::boolean),
  (63, 'Plateau'::text, 1::int, false::boolean),
  (64, 'Prismatic Vista'::text, 1::int, false::boolean),
  (65, 'Pyretic Ritual'::text, 1::int, false::boolean),
  (66, 'Radiant Scrollwielder'::text, 1::int, false::boolean),
  (67, 'Reckless Handling'::text, 1::int, false::boolean),
  (68, 'Rise of the Eldrazi'::text, 1::int, false::boolean),
  (69, 'Ruby Medallion'::text, 1::int, false::boolean),
  (70, 'Sacred Foundry'::text, 1::int, false::boolean),
  (71, 'Scalding Tarn'::text, 1::int, false::boolean),
  (72, 'Scroll Rack'::text, 1::int, false::boolean),
  (73, 'Seething Song'::text, 1::int, false::boolean),
  (74, 'Sensei''s Divining Top'::text, 1::int, false::boolean),
  (75, 'Silence'::text, 1::int, false::boolean),
  (76, 'Smothering Tithe'::text, 1::int, false::boolean),
  (77, 'Sol Ring'::text, 1::int, false::boolean),
  (78, 'Soulfire Eruption'::text, 1::int, false::boolean),
  (79, 'Spectator Seating'::text, 1::int, false::boolean),
  (80, 'Storm Herd'::text, 1::int, false::boolean),
  (81, 'Storm-Kiln Artist'::text, 1::int, false::boolean),
  (82, 'Sunbaked Canyon'::text, 1::int, false::boolean),
  (83, 'Sunbillow Verge'::text, 1::int, false::boolean),
  (84, 'Teferi''s Protection'::text, 1::int, false::boolean),
  (85, 'Treasonous Ogre'::text, 1::int, false::boolean),
  (86, 'Trouble in Pairs'::text, 1::int, false::boolean),
  (87, 'Ultima'::text, 1::int, false::boolean),
  (88, 'Urza''s Saga'::text, 1::int, false::boolean),
  (89, 'Volcanic Vision'::text, 1::int, false::boolean),
  (90, 'Windswept Heath'::text, 1::int, false::boolean),
  (91, 'Wooded Foothills'::text, 1::int, false::boolean);

DROP TABLE IF EXISTS tmp_lorehold_variant09_picked;
CREATE TEMP TABLE tmp_lorehold_variant09_picked AS
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
  FROM tmp_lorehold_variant09_input i
  LEFT JOIN cards c
    ON lower(c.name) = lower(i.card_name)
    OR lower(split_part(c.name, ' // ', 1)) = lower(split_part(i.card_name, ' // ', 1))
)
SELECT * FROM candidates WHERE rn = 1 OR card_id IS NULL;


SELECT
  'pg_lorehold_variant09_precheck_coverage' AS check_name,
  COUNT(*) AS input_rows,
  COALESCE(SUM(quantity),0)::int AS input_qty,
  COALESCE(SUM(CASE WHEN is_commander THEN quantity ELSE 0 END),0)::int AS commander_qty,
  COUNT(card_id) AS resolved_rows,
  COUNT(*) FILTER (WHERE card_id IS NULL) AS missing_rows
FROM tmp_lorehold_variant09_picked;

SELECT 'pg_lorehold_variant09_missing_card' AS check_name, ord, card_name, quantity, is_commander
FROM tmp_lorehold_variant09_picked
WHERE card_id IS NULL
ORDER BY ord;

SELECT
  'pg_lorehold_variant09_existing_target' AS check_name,
  (SELECT COUNT(*) FROM decks WHERE id = 'b51c8f24-fa8b-50ee-8200-d78fe9908ffa'::uuid) AS deck_rows,
  (SELECT COALESCE(SUM(quantity),0)::int FROM deck_cards WHERE deck_id = 'b51c8f24-fa8b-50ee-8200-d78fe9908ffa'::uuid) AS deck_qty,
  (SELECT COUNT(*) FROM commander_learned_decks WHERE source_system = 'manual_user_deck_registration' AND source_ref = 'lorehold_variant09_20260624_9370b6170e00') AS learned_rows;
