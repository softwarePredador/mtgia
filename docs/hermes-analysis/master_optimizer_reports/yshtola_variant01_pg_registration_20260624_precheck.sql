\pset pager off
-- PG register precheck for Y'shtola Variant 01.
-- No writes outside TEMP tables.
DROP TABLE IF EXISTS tmp_yshtola_variant01_input;
CREATE TEMP TABLE tmp_yshtola_variant01_input(ord int, card_name text, quantity int, is_commander boolean);
INSERT INTO tmp_yshtola_variant01_input(ord, card_name, quantity, is_commander) VALUES
  (1, 'Y''shtola, Night''s Blessed'::text, 1::int, true::boolean),
  (2, 'Adarkar Wastes'::text, 1::int, false::boolean),
  (3, 'An Offer You Can''t Refuse'::text, 1::int, false::boolean),
  (4, 'Ancient Tomb'::text, 1::int, false::boolean),
  (5, 'Arcane Signet'::text, 1::int, false::boolean),
  (6, 'Authority of the Consuls'::text, 1::int, false::boolean),
  (7, 'Blood Pact'::text, 1::int, false::boolean),
  (8, 'Bloodthirsty Conqueror'::text, 1::int, false::boolean),
  (9, 'Brainstorm'::text, 1::int, false::boolean),
  (10, 'Brainsurge'::text, 1::int, false::boolean),
  (11, 'Caves of Koilos'::text, 1::int, false::boolean),
  (12, 'Command Tower'::text, 1::int, false::boolean),
  (13, 'Commander''s Sphere'::text, 1::int, false::boolean),
  (14, 'Crawlspace'::text, 1::int, false::boolean),
  (15, 'Curiosity'::text, 1::int, false::boolean),
  (16, 'Cyclonic Rift'::text, 1::int, false::boolean),
  (17, 'Dark Ritual'::text, 1::int, false::boolean),
  (18, 'Deadly Rollick'::text, 1::int, false::boolean),
  (19, 'Delney, Streetwise Lookout'::text, 1::int, false::boolean),
  (20, 'Dimir Signet'::text, 1::int, false::boolean),
  (21, 'Enduring Tenacity'::text, 1::int, false::boolean),
  (22, 'Enlightened Tutor'::text, 1::int, false::boolean),
  (23, 'Esper Sentinel'::text, 1::int, false::boolean),
  (24, 'Exotic Orchard'::text, 1::int, false::boolean),
  (25, 'Exquisite Blood'::text, 1::int, false::boolean),
  (26, 'Exsanguinate'::text, 1::int, false::boolean),
  (27, 'Fabled Passage'::text, 1::int, false::boolean),
  (28, 'Farewell'::text, 1::int, false::boolean),
  (29, 'Fierce Guardianship'::text, 1::int, false::boolean),
  (30, 'Flare of Denial'::text, 1::int, false::boolean),
  (31, 'Flawless Maneuver'::text, 1::int, false::boolean),
  (32, 'Flooded Strand'::text, 1::int, false::boolean),
  (33, 'Ghostly Prison'::text, 1::int, false::boolean),
  (34, 'Gloomlake Verge'::text, 1::int, false::boolean),
  (35, 'Godless Shrine'::text, 1::int, false::boolean),
  (36, 'Grand Abolisher'::text, 1::int, false::boolean),
  (37, 'Grim Tutor'::text, 1::int, false::boolean),
  (38, 'Hallowed Fountain'::text, 1::int, false::boolean),
  (39, 'High Fae Trickster'::text, 1::int, false::boolean),
  (40, 'Idyllic Tutor'::text, 1::int, false::boolean),
  (41, 'Island'::text, 3::int, false::boolean),
  (42, 'Kambal, Consul of Allocation'::text, 1::int, false::boolean),
  (43, 'Kira, Great Glass-Spinner'::text, 1::int, false::boolean),
  (44, 'Lightning Greaves'::text, 1::int, false::boolean),
  (45, 'Malakir Rebirth'::text, 1::int, false::boolean),
  (46, 'Mana Vault'::text, 1::int, false::boolean),
  (47, 'Marauding Blight-Priest'::text, 1::int, false::boolean),
  (48, 'Marsh Flats'::text, 1::int, false::boolean),
  (49, 'Misleading Signpost'::text, 1::int, false::boolean),
  (50, 'Mox Amber'::text, 1::int, false::boolean),
  (51, 'Mystic Remora'::text, 1::int, false::boolean),
  (52, 'Mystical Tutor'::text, 1::int, false::boolean),
  (53, 'Ophidian Eye'::text, 1::int, false::boolean),
  (54, 'Orzhov Signet'::text, 1::int, false::boolean),
  (55, 'Otawara, Soaring City'::text, 1::int, false::boolean),
  (56, 'Plains'::text, 3::int, false::boolean),
  (57, 'Polluted Delta'::text, 1::int, false::boolean),
  (58, 'Ponder'::text, 1::int, false::boolean),
  (59, 'Prismatic Vista'::text, 1::int, false::boolean),
  (60, 'Propaganda'::text, 1::int, false::boolean),
  (61, 'Reflecting Pool'::text, 1::int, false::boolean),
  (62, 'Reliquary Tower'::text, 1::int, false::boolean),
  (63, 'Rhystic Study'::text, 1::int, false::boolean),
  (64, 'Sanguine Bond'::text, 1::int, false::boolean),
  (65, 'Scrubland'::text, 1::int, false::boolean),
  (66, 'Sejiri Shelter'::text, 1::int, false::boolean),
  (67, 'Shattered Sanctum'::text, 1::int, false::boolean),
  (68, 'Sheoldred, the Apocalypse'::text, 1::int, false::boolean),
  (69, 'Sigil of Sleep'::text, 1::int, false::boolean),
  (70, 'Sink into Stupor'::text, 1::int, false::boolean),
  (71, 'Smothering Tithe'::text, 1::int, false::boolean),
  (72, 'Sol Ring'::text, 1::int, false::boolean),
  (73, 'Spirit Link'::text, 1::int, false::boolean),
  (74, 'Starfall Invocation'::text, 1::int, false::boolean),
  (75, 'Starting Town'::text, 1::int, false::boolean),
  (76, 'Sudden Spoiling'::text, 1::int, false::boolean),
  (77, 'Sunken Ruins'::text, 1::int, false::boolean),
  (78, 'Swamp'::text, 4::int, false::boolean),
  (79, 'Swiftfoot Boots'::text, 1::int, false::boolean),
  (80, 'Talisman of Dominance'::text, 1::int, false::boolean),
  (81, 'Talisman of Hierarchy'::text, 1::int, false::boolean),
  (82, 'Talisman of Progress'::text, 1::int, false::boolean),
  (83, 'Teferi''s Protection'::text, 1::int, false::boolean),
  (84, 'Teferi, Time Raveler'::text, 1::int, false::boolean),
  (85, 'The Darkness Crystal'::text, 1::int, false::boolean),
  (86, 'The Meathook Massacre'::text, 1::int, false::boolean),
  (87, 'The One Ring'::text, 1::int, false::boolean),
  (88, 'The Wind Crystal'::text, 1::int, false::boolean),
  (89, 'Think Twice'::text, 1::int, false::boolean),
  (90, 'Underground River'::text, 1::int, false::boolean),
  (91, 'Vito, Thorn of the Dusk Rose'::text, 1::int, false::boolean),
  (92, 'Watery Grave'::text, 1::int, false::boolean),
  (93, 'Witch Enchanter'::text, 1::int, false::boolean);

DROP TABLE IF EXISTS tmp_yshtola_variant01_picked;
CREATE TEMP TABLE tmp_yshtola_variant01_picked AS
WITH candidates AS (
  SELECT
    i.*,
    c.id AS card_id,
    c.name AS pg_name,
    c.set_code,
    c.collector_number,
    c.cmc,
    c.type_line,
    c.oracle_text,
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
  FROM tmp_yshtola_variant01_input i
  LEFT JOIN cards c
    ON lower(c.name) = lower(i.card_name)
    OR lower(split_part(c.name, ' // ', 1)) = lower(split_part(i.card_name, ' // ', 1))
)
SELECT * FROM candidates WHERE rn = 1 OR card_id IS NULL;


SELECT
  'pg_yshtola_variant01_precheck_coverage' AS check_name,
  COUNT(*) AS input_rows,
  COALESCE(SUM(quantity),0)::int AS input_qty,
  COALESCE(SUM(CASE WHEN is_commander THEN quantity ELSE 0 END),0)::int AS commander_qty,
  COUNT(card_id) AS resolved_rows,
  COUNT(*) FILTER (WHERE card_id IS NULL) AS missing_rows
FROM tmp_yshtola_variant01_picked;

SELECT 'pg_yshtola_variant01_missing_card' AS check_name, ord, card_name, quantity, is_commander
FROM tmp_yshtola_variant01_picked
WHERE card_id IS NULL
ORDER BY ord;

SELECT
  'pg_yshtola_variant01_existing_target' AS check_name,
  (SELECT COUNT(*) FROM decks WHERE id = '982cf6a6-c84a-5c3e-b9fc-e79127598b89'::uuid) AS deck_rows,
  (SELECT COALESCE(SUM(quantity),0)::int FROM deck_cards WHERE deck_id = '982cf6a6-c84a-5c3e-b9fc-e79127598b89'::uuid) AS deck_qty,
  (SELECT COUNT(*) FROM commander_learned_decks WHERE source_system = 'manual_user_deck_registration' AND source_ref = 'yshtola_variant01_20260624_2165c4d41e85') AS learned_rows;
