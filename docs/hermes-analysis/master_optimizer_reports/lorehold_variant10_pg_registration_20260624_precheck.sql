\pset pager off
-- PG register precheck for Lorehold Variant 10.
-- No writes outside TEMP tables.
DROP TABLE IF EXISTS tmp_lorehold_variant10_input;
CREATE TEMP TABLE tmp_lorehold_variant10_input(ord int, card_name text, quantity int, is_commander boolean);
INSERT INTO tmp_lorehold_variant10_input(ord, card_name, quantity, is_commander) VALUES
  (1, 'Lorehold, the Historian'::text, 1::int, true::boolean),
  (2, 'Ancient Tomb'::text, 1::int, false::boolean),
  (3, 'Apex of Power'::text, 1::int, false::boolean),
  (4, 'Approach of the Second Sun'::text, 1::int, false::boolean),
  (5, 'Arcane Signet'::text, 1::int, false::boolean),
  (6, 'Arid Mesa'::text, 1::int, false::boolean),
  (7, 'Beacon of Immortality'::text, 1::int, false::boolean),
  (8, 'Big Score'::text, 1::int, false::boolean),
  (9, 'Birgi, God of Storytelling // Harnfel, Horn of Bounty'::text, 1::int, false::boolean),
  (10, 'Boros Charm'::text, 1::int, false::boolean),
  (11, 'Boseiju, Who Shelters All'::text, 1::int, false::boolean),
  (12, 'Brass''s Bounty'::text, 1::int, false::boolean),
  (13, 'Call Forth the Tempest'::text, 1::int, false::boolean),
  (14, 'Cavern of Souls'::text, 1::int, false::boolean),
  (15, 'Chaos Warp'::text, 1::int, false::boolean),
  (16, 'Clifftop Retreat'::text, 1::int, false::boolean),
  (17, 'Command Beacon'::text, 1::int, false::boolean),
  (18, 'Command Tower'::text, 1::int, false::boolean),
  (19, 'Deflecting Palm'::text, 1::int, false::boolean),
  (20, 'Deflecting Swat'::text, 1::int, false::boolean),
  (21, 'Double Vision'::text, 1::int, false::boolean),
  (22, 'Enlightened Tutor'::text, 1::int, false::boolean),
  (23, 'Erode'::text, 1::int, false::boolean),
  (24, 'Esper Sentinel'::text, 1::int, false::boolean),
  (25, 'Faithless Looting'::text, 1::int, false::boolean),
  (26, 'Farewell'::text, 1::int, false::boolean),
  (27, 'Flare of Duplication'::text, 1::int, false::boolean),
  (28, 'Flashback'::text, 1::int, false::boolean),
  (29, 'Galvanoth'::text, 1::int, false::boolean),
  (30, 'Gamble'::text, 1::int, false::boolean),
  (31, 'Goldspan Dragon'::text, 1::int, false::boolean),
  (32, 'Goliath Daydreamer'::text, 1::int, false::boolean),
  (33, 'Grand Abolisher'::text, 1::int, false::boolean),
  (34, 'Guttersnipe'::text, 1::int, false::boolean),
  (35, 'Heroes Remembered'::text, 1::int, false::boolean),
  (36, 'Hexing Squelcher'::text, 1::int, false::boolean),
  (37, 'Insurrection'::text, 1::int, false::boolean),
  (38, 'Invoke Calamity'::text, 1::int, false::boolean),
  (39, 'Jeska''s Will'::text, 1::int, false::boolean),
  (40, 'Land Tax'::text, 1::int, false::boolean),
  (41, 'Library of Leng'::text, 1::int, false::boolean),
  (42, 'Lightning Bolt'::text, 1::int, false::boolean),
  (43, 'Lightning Greaves'::text, 1::int, false::boolean),
  (44, 'Longshot, Rebel Bowman'::text, 1::int, false::boolean),
  (45, 'Mana Vault'::text, 1::int, false::boolean),
  (46, 'Mithril Coat'::text, 1::int, false::boolean),
  (47, 'Mizzix''s Mastery'::text, 1::int, false::boolean),
  (48, 'Monument to Endurance'::text, 1::int, false::boolean),
  (49, 'Mountain // Mountain'::text, 10::int, false::boolean),
  (50, 'Myriad Landscape'::text, 1::int, false::boolean),
  (51, 'Olórin''s Searing Light'::text, 1::int, false::boolean),
  (52, 'Perch Protection'::text, 1::int, false::boolean),
  (53, 'Plains // Plains'::text, 8::int, false::boolean),
  (54, 'Plateau'::text, 1::int, false::boolean),
  (55, 'Primal Amulet // Primal Wellspring'::text, 1::int, false::boolean),
  (56, 'Radiant Summit'::text, 1::int, false::boolean),
  (57, 'Red Elemental Blast'::text, 1::int, false::boolean),
  (58, 'Reforge the Soul'::text, 1::int, false::boolean),
  (59, 'Reiterate'::text, 1::int, false::boolean),
  (60, 'Reliquary Tower'::text, 1::int, false::boolean),
  (61, 'Reprieve'::text, 1::int, false::boolean),
  (62, 'Rise of the Eldrazi'::text, 1::int, false::boolean),
  (63, 'Rite of the Dragoncaller'::text, 1::int, false::boolean),
  (64, 'Sacred Foundry'::text, 1::int, false::boolean),
  (65, 'Seething Song'::text, 1::int, false::boolean),
  (66, 'Sensei''s Divining Top'::text, 1::int, false::boolean),
  (67, 'Silence'::text, 1::int, false::boolean),
  (68, 'Single Combat'::text, 1::int, false::boolean),
  (69, 'Smothering Tithe'::text, 1::int, false::boolean),
  (70, 'Sol Ring'::text, 1::int, false::boolean),
  (71, 'Spectator Seating'::text, 1::int, false::boolean),
  (72, 'Starfall Invocation'::text, 1::int, false::boolean),
  (73, 'Sunbillow Verge'::text, 1::int, false::boolean),
  (74, 'Sundown Pass'::text, 1::int, false::boolean),
  (75, 'Swords to Plowshares'::text, 1::int, false::boolean),
  (76, 'Taunt from the Rampart'::text, 1::int, false::boolean),
  (77, 'Teferi''s Protection'::text, 1::int, false::boolean),
  (78, 'The One Ring'::text, 1::int, false::boolean),
  (79, 'Twinflame Tyrant'::text, 1::int, false::boolean),
  (80, 'Underworld Breach'::text, 1::int, false::boolean),
  (81, 'Unexpected Windfall'::text, 1::int, false::boolean),
  (82, 'Urza''s Saga'::text, 1::int, false::boolean),
  (83, 'Vandalblast'::text, 1::int, false::boolean),
  (84, 'Velomachus Lorehold'::text, 1::int, false::boolean);

DROP TABLE IF EXISTS tmp_lorehold_variant10_picked;
CREATE TEMP TABLE tmp_lorehold_variant10_picked AS
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
  FROM tmp_lorehold_variant10_input i
  LEFT JOIN cards c
    ON lower(c.name) = lower(i.card_name)
    OR lower(split_part(c.name, ' // ', 1)) = lower(split_part(i.card_name, ' // ', 1))
)
SELECT * FROM candidates WHERE rn = 1 OR card_id IS NULL;


SELECT
  'pg_lorehold_variant10_precheck_coverage' AS check_name,
  COUNT(*) AS input_rows,
  COALESCE(SUM(quantity),0)::int AS input_qty,
  COALESCE(SUM(CASE WHEN is_commander THEN quantity ELSE 0 END),0)::int AS commander_qty,
  COUNT(card_id) AS resolved_rows,
  COUNT(*) FILTER (WHERE card_id IS NULL) AS missing_rows
FROM tmp_lorehold_variant10_picked;

SELECT 'pg_lorehold_variant10_missing_card' AS check_name, ord, card_name, quantity, is_commander
FROM tmp_lorehold_variant10_picked
WHERE card_id IS NULL
ORDER BY ord;

SELECT
  'pg_lorehold_variant10_existing_target' AS check_name,
  (SELECT COUNT(*) FROM decks WHERE id = '43c026ae-2d92-5049-90fc-1fdad4b04298'::uuid) AS deck_rows,
  (SELECT COALESCE(SUM(quantity),0)::int FROM deck_cards WHERE deck_id = '43c026ae-2d92-5049-90fc-1fdad4b04298'::uuid) AS deck_qty,
  (SELECT COUNT(*) FROM commander_learned_decks WHERE source_system = 'manual_user_deck_registration' AND source_ref = 'lorehold_variant10_20260624_69fc2e8dfcb4') AS learned_rows;
