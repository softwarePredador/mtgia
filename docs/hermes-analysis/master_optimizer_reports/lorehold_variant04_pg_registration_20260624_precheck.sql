\pset pager off
-- PG register precheck for Lorehold Variant 04.
-- No writes outside TEMP tables.
DROP TABLE IF EXISTS tmp_lorehold_variant04_input;
CREATE TEMP TABLE tmp_lorehold_variant04_input(ord int, card_name text, quantity int, is_commander boolean);
INSERT INTO tmp_lorehold_variant04_input(ord, card_name, quantity, is_commander) VALUES
  (1, 'Lorehold, the Historian'::text, 1::int, true::boolean),
  (2, 'Apex of Power'::text, 1::int, false::boolean),
  (3, 'Approach of the Second Sun'::text, 1::int, false::boolean),
  (4, 'Arcane Signet'::text, 1::int, false::boolean),
  (5, 'Archaeomancer''s Map'::text, 1::int, false::boolean),
  (6, 'Archivist of Oghma'::text, 1::int, false::boolean),
  (7, 'Arid Archway'::text, 1::int, false::boolean),
  (8, 'Arid Mesa'::text, 1::int, false::boolean),
  (9, 'Ash Barrens'::text, 1::int, false::boolean),
  (10, 'Austere Command'::text, 1::int, false::boolean),
  (11, 'Battlefield Forge'::text, 1::int, false::boolean),
  (12, 'Bender''s Waterskin'::text, 1::int, false::boolean),
  (13, 'Big Score'::text, 1::int, false::boolean),
  (14, 'Blasphemous Act'::text, 1::int, false::boolean),
  (15, 'Blood Sun'::text, 1::int, false::boolean),
  (16, 'Bolt Bend'::text, 1::int, false::boolean),
  (17, 'Boros Charm'::text, 1::int, false::boolean),
  (18, 'Boros Garrison'::text, 1::int, false::boolean),
  (19, 'Boros Signet'::text, 1::int, false::boolean),
  (20, 'Brass''s Bounty'::text, 1::int, false::boolean),
  (21, 'Call Forth the Tempest'::text, 1::int, false::boolean),
  (22, 'Clever Concealment'::text, 1::int, false::boolean),
  (23, 'Clifftop Retreat'::text, 1::int, false::boolean),
  (24, 'Command Tower'::text, 1::int, false::boolean),
  (25, 'Dance with Calamity'::text, 1::int, false::boolean),
  (26, 'Deflecting Swat'::text, 1::int, false::boolean),
  (27, 'Demolition Field'::text, 1::int, false::boolean),
  (28, 'Dragon''s Rage Channeler'::text, 1::int, false::boolean),
  (29, 'Emeria''s Call // Emeria, Shattered Skyclave'::text, 1::int, false::boolean),
  (30, 'Esper Sentinel'::text, 1::int, false::boolean),
  (31, 'Fellwar Stone'::text, 1::int, false::boolean),
  (32, 'Gamble'::text, 1::int, false::boolean),
  (33, 'Giver of Runes'::text, 1::int, false::boolean),
  (34, 'Glittering Massif'::text, 1::int, false::boolean),
  (35, 'Guildless Commons'::text, 1::int, false::boolean),
  (36, 'Hexing Squelcher'::text, 1::int, false::boolean),
  (37, 'Hit the Mother Lode'::text, 1::int, false::boolean),
  (38, 'Improvisation Capstone'::text, 1::int, false::boolean),
  (39, 'Insurrection'::text, 1::int, false::boolean),
  (40, 'Invoke Calamity'::text, 1::int, false::boolean),
  (41, 'Knight of the White Orchid'::text, 1::int, false::boolean),
  (42, 'Land Tax'::text, 1::int, false::boolean),
  (43, 'Library of Leng'::text, 1::int, false::boolean),
  (44, 'Lotus Field'::text, 1::int, false::boolean),
  (45, 'Lotus Vale'::text, 1::int, false::boolean),
  (46, 'Loyal Warhound'::text, 1::int, false::boolean),
  (47, 'Mizzix''s Mastery'::text, 1::int, false::boolean),
  (48, 'Monument to Endurance'::text, 1::int, false::boolean),
  (49, 'Mother of Runes'::text, 1::int, false::boolean),
  (50, 'Mountain // Mountain'::text, 5::int, false::boolean),
  (51, 'Needleverge Pathway // Pillarverge Pathway'::text, 1::int, false::boolean),
  (52, 'Olórin''s Searing Light'::text, 1::int, false::boolean),
  (53, 'Path to Exile'::text, 1::int, false::boolean),
  (54, 'Penance'::text, 1::int, false::boolean),
  (55, 'Perch Protection'::text, 1::int, false::boolean),
  (56, 'Pinnacle Monk // Mystic Peak'::text, 1::int, false::boolean),
  (57, 'Plains // Plains'::text, 5::int, false::boolean),
  (58, 'Radiant Summit'::text, 1::int, false::boolean),
  (59, 'Reforge the Soul'::text, 1::int, false::boolean),
  (60, 'Restoration Seminar'::text, 1::int, false::boolean),
  (61, 'Rise of the Eldrazi'::text, 1::int, false::boolean),
  (62, 'Rugged Prairie'::text, 1::int, false::boolean),
  (63, 'Sacred Foundry'::text, 1::int, false::boolean),
  (64, 'Sand Scout'::text, 1::int, false::boolean),
  (65, 'Scavenger Grounds'::text, 1::int, false::boolean),
  (66, 'Scholar of New Horizons'::text, 1::int, false::boolean),
  (67, 'Scroll Rack'::text, 1::int, false::boolean),
  (68, 'Sejiri Shelter // Sejiri Glacier'::text, 1::int, false::boolean),
  (69, 'Sensei''s Divining Top'::text, 1::int, false::boolean),
  (70, 'Sol Ring'::text, 1::int, false::boolean),
  (71, 'Soul-Guide Lantern'::text, 1::int, false::boolean),
  (72, 'Squee, Goblin Nabob'::text, 1::int, false::boolean),
  (73, 'Starfield Shepherd'::text, 1::int, false::boolean),
  (74, 'Storm Herd'::text, 1::int, false::boolean),
  (75, 'Sunbillow Verge'::text, 1::int, false::boolean),
  (76, 'Sundering Eruption // Volcanic Fissure'::text, 1::int, false::boolean),
  (77, 'Sundown Pass'::text, 1::int, false::boolean),
  (78, 'Swords to Plowshares'::text, 1::int, false::boolean),
  (79, 'Talisman of Conviction'::text, 1::int, false::boolean),
  (80, 'Tibalt''s Trickery'::text, 1::int, false::boolean),
  (81, 'Unexpected Windfall'::text, 1::int, false::boolean),
  (82, 'Urza''s Saga'::text, 1::int, false::boolean),
  (83, 'Valakut Awakening // Valakut Stoneforge'::text, 1::int, false::boolean),
  (84, 'Vandalblast'::text, 1::int, false::boolean),
  (85, 'Verge Rangers'::text, 1::int, false::boolean),
  (86, 'Victory Chimes'::text, 1::int, false::boolean),
  (87, 'Volcanic Vision'::text, 1::int, false::boolean),
  (88, 'Wear // Tear'::text, 1::int, false::boolean),
  (89, 'Weathered Wayfarer'::text, 1::int, false::boolean),
  (90, 'Wheel of Fortune'::text, 1::int, false::boolean),
  (91, 'Wheel of Misfortune'::text, 1::int, false::boolean),
  (92, 'Witch Enchanter // Witch-Blessed Meadow'::text, 1::int, false::boolean);

DROP TABLE IF EXISTS tmp_lorehold_variant04_picked;
CREATE TEMP TABLE tmp_lorehold_variant04_picked AS
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
  FROM tmp_lorehold_variant04_input i
  LEFT JOIN cards c
    ON lower(c.name) = lower(i.card_name)
    OR lower(split_part(c.name, ' // ', 1)) = lower(split_part(i.card_name, ' // ', 1))
)
SELECT * FROM candidates WHERE rn = 1 OR card_id IS NULL;


SELECT
  'pg_lorehold_variant04_precheck_coverage' AS check_name,
  COUNT(*) AS input_rows,
  COALESCE(SUM(quantity),0)::int AS input_qty,
  COALESCE(SUM(CASE WHEN is_commander THEN quantity ELSE 0 END),0)::int AS commander_qty,
  COUNT(card_id) AS resolved_rows,
  COUNT(*) FILTER (WHERE card_id IS NULL) AS missing_rows
FROM tmp_lorehold_variant04_picked;

SELECT 'pg_lorehold_variant04_missing_card' AS check_name, ord, card_name, quantity, is_commander
FROM tmp_lorehold_variant04_picked
WHERE card_id IS NULL
ORDER BY ord;

SELECT
  'pg_lorehold_variant04_existing_target' AS check_name,
  (SELECT COUNT(*) FROM decks WHERE id = '917674eb-6a3d-58de-acce-5a2a3ac9e497'::uuid) AS deck_rows,
  (SELECT COALESCE(SUM(quantity),0)::int FROM deck_cards WHERE deck_id = '917674eb-6a3d-58de-acce-5a2a3ac9e497'::uuid) AS deck_qty,
  (SELECT COUNT(*) FROM commander_learned_decks WHERE source_system = 'manual_user_deck_registration' AND source_ref = 'lorehold_variant04_20260624_ba7d06f86f23') AS learned_rows;
