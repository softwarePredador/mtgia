\pset pager off
-- PG register precheck for Lorehold Variant 11.
-- No writes outside TEMP tables.
DROP TABLE IF EXISTS tmp_lorehold_variant11_input;
CREATE TEMP TABLE tmp_lorehold_variant11_input(ord int, card_name text, quantity int, is_commander boolean);
INSERT INTO tmp_lorehold_variant11_input(ord, card_name, quantity, is_commander) VALUES
  (1, 'Lorehold, the Historian'::text, 1::int, true::boolean),
  (2, 'Abrade'::text, 1::int, false::boolean),
  (3, 'Ancient Copper Dragon'::text, 1::int, false::boolean),
  (4, 'Apex of Power'::text, 1::int, false::boolean),
  (5, 'Arcane Signet'::text, 1::int, false::boolean),
  (6, 'Authority of the Consuls'::text, 1::int, false::boolean),
  (7, 'Balefire Liege'::text, 1::int, false::boolean),
  (8, 'Bedlam Reveler'::text, 1::int, false::boolean),
  (9, 'Blasphemous Act'::text, 1::int, false::boolean),
  (10, 'Blaze Commando'::text, 1::int, false::boolean),
  (11, 'Blood Moon'::text, 1::int, false::boolean),
  (12, 'Boltwave'::text, 1::int, false::boolean),
  (13, 'Boros Garrison'::text, 1::int, false::boolean),
  (14, 'Boros Reckoner'::text, 1::int, false::boolean),
  (15, 'Boseiju, Who Shelters All'::text, 1::int, false::boolean),
  (16, 'Chaos Wand'::text, 1::int, false::boolean),
  (17, 'Chaos Warp'::text, 1::int, false::boolean),
  (18, 'Clifftop Retreat'::text, 1::int, false::boolean),
  (19, 'Command Tower'::text, 1::int, false::boolean),
  (20, 'Coruscation Mage'::text, 1::int, false::boolean),
  (21, 'Dawn''s Truce'::text, 1::int, false::boolean),
  (22, 'Deathbellow War Cry'::text, 1::int, false::boolean),
  (23, 'Deflecting Palm'::text, 1::int, false::boolean),
  (24, 'Deflecting Swat'::text, 1::int, false::boolean),
  (25, 'Eight-and-a-Half-Tails'::text, 1::int, false::boolean),
  (26, 'Explosive Singularity'::text, 1::int, false::boolean),
  (27, 'Firesong and Sunspeaker'::text, 1::int, false::boolean),
  (28, 'Generous Gift'::text, 1::int, false::boolean),
  (29, 'Ghostly Prison'::text, 1::int, false::boolean),
  (30, 'Gods Willing'::text, 1::int, false::boolean),
  (31, 'Grand Abolisher'::text, 1::int, false::boolean),
  (32, 'Guttersnipe'::text, 1::int, false::boolean),
  (33, 'Hexing Squelcher'::text, 1::int, false::boolean),
  (34, 'Invoke Calamity'::text, 1::int, false::boolean),
  (35, 'Jeska''s Will'::text, 1::int, false::boolean),
  (36, 'Lightning Bolt'::text, 1::int, false::boolean),
  (37, 'Lightning Helix'::text, 1::int, false::boolean),
  (38, 'Lindblum, Industrial Regency // Mage Siege'::text, 1::int, false::boolean),
  (39, 'Magus of the Wheel'::text, 1::int, false::boolean),
  (40, 'Mizzix''s Mastery'::text, 1::int, false::boolean),
  (41, 'Monastery Mentor'::text, 1::int, false::boolean),
  (42, 'Mountain // Mountain'::text, 10::int, false::boolean),
  (43, 'Myriad Landscape'::text, 1::int, false::boolean),
  (44, 'Neheb, the Eternal'::text, 1::int, false::boolean),
  (45, 'Path to Exile'::text, 1::int, false::boolean),
  (46, 'Plains // Plains'::text, 8::int, false::boolean),
  (47, 'Plateau'::text, 1::int, false::boolean),
  (48, 'Possibility Storm'::text, 1::int, false::boolean),
  (49, 'Radiant Performer'::text, 1::int, false::boolean),
  (50, 'Reckless Endeavor'::text, 1::int, false::boolean),
  (51, 'Reforge the Soul'::text, 1::int, false::boolean),
  (52, 'Reliquary Tower'::text, 1::int, false::boolean),
  (53, 'Rise of the Eldrazi'::text, 1::int, false::boolean),
  (54, 'Rugged Prairie'::text, 1::int, false::boolean),
  (55, 'Rune-Tail, Kitsune Ascendant // Rune-Tail''s Essence'::text, 1::int, false::boolean),
  (56, 'Sacred Foundry'::text, 1::int, false::boolean),
  (57, 'Sawhorn Nemesis'::text, 1::int, false::boolean),
  (58, 'Screaming Nemesis'::text, 1::int, false::boolean),
  (59, 'Scroll Rack'::text, 1::int, false::boolean),
  (60, 'Semblance Anvil'::text, 1::int, false::boolean),
  (61, 'Sensei''s Divining Top'::text, 1::int, false::boolean),
  (62, 'Serra Ascendant'::text, 1::int, false::boolean),
  (63, 'Silence'::text, 1::int, false::boolean),
  (64, 'Slickshot Show-Off'::text, 1::int, false::boolean),
  (65, 'Smothering Tithe'::text, 1::int, false::boolean),
  (66, 'Sol Ring'::text, 1::int, false::boolean),
  (67, 'Soul Immolation'::text, 1::int, false::boolean),
  (68, 'Soulfire Eruption'::text, 1::int, false::boolean),
  (69, 'Star of Extinction'::text, 1::int, false::boolean),
  (70, 'Storm Herd'::text, 1::int, false::boolean),
  (71, 'Stroke of Midnight'::text, 1::int, false::boolean),
  (72, 'Stuffy Doll'::text, 1::int, false::boolean),
  (73, 'Swiftfoot Boots'::text, 1::int, false::boolean),
  (74, 'Teferi''s Protection'::text, 1::int, false::boolean),
  (75, 'Thawing Glaciers'::text, 1::int, false::boolean),
  (76, 'The Walls of Ba Sing Se'::text, 1::int, false::boolean),
  (77, 'Untimely Malfunction'::text, 1::int, false::boolean),
  (78, 'Utvara Hellkite'::text, 1::int, false::boolean),
  (79, 'Wear // Tear'::text, 1::int, false::boolean),
  (80, 'Wheel of Fate'::text, 1::int, false::boolean),
  (81, 'Wheel of Fortune'::text, 1::int, false::boolean),
  (82, 'Whispersilk Cloak'::text, 1::int, false::boolean),
  (83, 'Worldfire'::text, 1::int, false::boolean),
  (84, 'Young Pyromancer'::text, 1::int, false::boolean);

DROP TABLE IF EXISTS tmp_lorehold_variant11_picked;
CREATE TEMP TABLE tmp_lorehold_variant11_picked AS
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
  FROM tmp_lorehold_variant11_input i
  LEFT JOIN cards c
    ON lower(c.name) = lower(i.card_name)
    OR lower(split_part(c.name, ' // ', 1)) = lower(split_part(i.card_name, ' // ', 1))
)
SELECT * FROM candidates WHERE rn = 1 OR card_id IS NULL;


SELECT
  'pg_lorehold_variant11_precheck_coverage' AS check_name,
  COUNT(*) AS input_rows,
  COALESCE(SUM(quantity),0)::int AS input_qty,
  COALESCE(SUM(CASE WHEN is_commander THEN quantity ELSE 0 END),0)::int AS commander_qty,
  COUNT(card_id) AS resolved_rows,
  COUNT(*) FILTER (WHERE card_id IS NULL) AS missing_rows
FROM tmp_lorehold_variant11_picked;

SELECT 'pg_lorehold_variant11_missing_card' AS check_name, ord, card_name, quantity, is_commander
FROM tmp_lorehold_variant11_picked
WHERE card_id IS NULL
ORDER BY ord;

SELECT
  'pg_lorehold_variant11_existing_target' AS check_name,
  (SELECT COUNT(*) FROM decks WHERE id = '9df6ac2e-6620-5265-8008-1f57c8963d66'::uuid) AS deck_rows,
  (SELECT COALESCE(SUM(quantity),0)::int FROM deck_cards WHERE deck_id = '9df6ac2e-6620-5265-8008-1f57c8963d66'::uuid) AS deck_qty,
  (SELECT COUNT(*) FROM commander_learned_decks WHERE source_system = 'manual_user_deck_registration' AND source_ref = 'lorehold_variant11_20260624_4f48eee5a34d') AS learned_rows;
