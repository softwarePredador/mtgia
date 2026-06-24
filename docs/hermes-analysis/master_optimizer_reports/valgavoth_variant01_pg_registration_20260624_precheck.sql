\pset pager off
-- PG register precheck for Valgavoth Variant 01.
-- No writes outside TEMP tables.
DROP TABLE IF EXISTS tmp_valgavoth_variant01_input;
CREATE TEMP TABLE tmp_valgavoth_variant01_input(ord int, card_name text, quantity int, is_commander boolean);
INSERT INTO tmp_valgavoth_variant01_input(ord, card_name, quantity, is_commander) VALUES
  (1, 'Valgavoth, Harrower of Souls'::text, 1::int, true::boolean),
  (2, 'Arcane Signet'::text, 1::int, false::boolean),
  (3, 'Arena of Glory'::text, 1::int, false::boolean),
  (4, 'Arid Mesa'::text, 1::int, false::boolean),
  (5, 'Ash Barrens'::text, 1::int, false::boolean),
  (6, 'Badlands'::text, 1::int, false::boolean),
  (7, 'Basilisk Collar'::text, 1::int, false::boolean),
  (8, 'Bedevil'::text, 1::int, false::boolean),
  (9, 'Blasphemous Act'::text, 1::int, false::boolean),
  (10, 'Blood Artist'::text, 1::int, false::boolean),
  (11, 'Blood Crypt'::text, 1::int, false::boolean),
  (12, 'Blood Seeker'::text, 1::int, false::boolean),
  (13, 'Bloodchief Ascension'::text, 1::int, false::boolean),
  (14, 'Bloodstained Mire'::text, 1::int, false::boolean),
  (15, 'Brash Taunter'::text, 1::int, false::boolean),
  (16, 'Castle Locthwain'::text, 1::int, false::boolean),
  (17, 'Cemetery Gatekeeper'::text, 1::int, false::boolean),
  (18, 'Chaos Warp'::text, 1::int, false::boolean),
  (19, 'City of Brass'::text, 1::int, false::boolean),
  (20, 'Command Tower'::text, 1::int, false::boolean),
  (21, 'Decree of Pain'::text, 1::int, false::boolean),
  (22, 'Deflecting Swat'::text, 1::int, false::boolean),
  (23, 'Dragonskull Summit'::text, 1::int, false::boolean),
  (24, 'Exotic Orchard'::text, 1::int, false::boolean),
  (25, 'Falkenrath Noble'::text, 1::int, false::boolean),
  (26, 'Fate Unraveler'::text, 1::int, false::boolean),
  (27, 'Feed the Swarm'::text, 1::int, false::boolean),
  (28, 'Fellwar Stone'::text, 1::int, false::boolean),
  (29, 'Fiery Inscription'::text, 1::int, false::boolean),
  (30, 'Gleeful Arsonist'::text, 1::int, false::boolean),
  (31, 'Graven Cairns'::text, 1::int, false::boolean),
  (32, 'Gray Merchant of Asphodel'::text, 1::int, false::boolean),
  (33, 'Harsh Mentor'::text, 1::int, false::boolean),
  (34, 'Hexing Squelcher'::text, 1::int, false::boolean),
  (35, 'Infernal Grasp'::text, 1::int, false::boolean),
  (36, 'Kaervek the Merciless'::text, 1::int, false::boolean),
  (37, 'Kardur, Doomscourge'::text, 1::int, false::boolean),
  (38, 'Kederekt Parasite'::text, 1::int, false::boolean),
  (39, 'Light Up the Stage'::text, 1::int, false::boolean),
  (40, 'Lightning Greaves'::text, 1::int, false::boolean),
  (41, 'Mai, Scornful Striker'::text, 1::int, false::boolean),
  (42, 'Malakir Rebirth'::text, 1::int, false::boolean),
  (43, 'Marsh Flats'::text, 1::int, false::boolean),
  (44, 'Massacre Girl'::text, 1::int, false::boolean),
  (45, 'Massacre Wurm'::text, 1::int, false::boolean),
  (46, 'Mayhem Devil'::text, 1::int, false::boolean),
  (47, 'Mind Stone'::text, 1::int, false::boolean),
  (48, 'Mogis, God of Slaughter'::text, 1::int, false::boolean),
  (49, 'Morbid Opportunist'::text, 1::int, false::boolean),
  (50, 'Mountain'::text, 7::int, false::boolean),
  (51, 'Nightshade Harvester'::text, 1::int, false::boolean),
  (52, 'Persistent Constrictor'::text, 1::int, false::boolean),
  (53, 'Phyrexian Tower'::text, 1::int, false::boolean),
  (54, 'Ragavan, Nimble Pilferer'::text, 1::int, false::boolean),
  (55, 'Rakdos Charm'::text, 1::int, false::boolean),
  (56, 'Rakdos Signet'::text, 1::int, false::boolean),
  (57, 'Rampaging Ferocidon'::text, 1::int, false::boolean),
  (58, 'Raucous Theater'::text, 1::int, false::boolean),
  (59, 'Redirect Lightning'::text, 1::int, false::boolean),
  (60, 'Sadistic Shell Game'::text, 1::int, false::boolean),
  (61, 'Scalding Tarn'::text, 1::int, false::boolean),
  (62, 'Scrawling Crawler'::text, 1::int, false::boolean),
  (63, 'Shadowblood Ridge'::text, 1::int, false::boolean),
  (64, 'Sheoldred, the Apocalypse'::text, 1::int, false::boolean),
  (65, 'Shivan Gorge'::text, 1::int, false::boolean),
  (66, 'Sol Ring'::text, 1::int, false::boolean),
  (67, 'Solemn Simulacrum'::text, 1::int, false::boolean),
  (68, 'Spiked Corridor // Torture Pit'::text, 1::int, false::boolean),
  (69, 'Spiteful Visions'::text, 1::int, false::boolean),
  (70, 'Star Athlete'::text, 1::int, false::boolean),
  (71, 'Sulfurous Springs'::text, 1::int, false::boolean),
  (72, 'Suspended Sentence'::text, 1::int, false::boolean),
  (73, 'Swamp'::text, 8::int, false::boolean),
  (74, 'Syr Konrad, the Grim'::text, 1::int, false::boolean),
  (75, 'Séance Board'::text, 1::int, false::boolean),
  (76, 'Tainted Peak'::text, 1::int, false::boolean),
  (77, 'Talisman of Indulgence'::text, 1::int, false::boolean),
  (78, 'The Lord of Pain'::text, 1::int, false::boolean),
  (79, 'The Meathook Massacre'::text, 1::int, false::boolean),
  (80, 'The Soul Stone'::text, 1::int, false::boolean),
  (81, 'Tibalt''s Trickery'::text, 1::int, false::boolean),
  (82, 'Uncivil Unrest'::text, 1::int, false::boolean),
  (83, 'Untimely Malfunction'::text, 1::int, false::boolean),
  (84, 'Vandalblast'::text, 1::int, false::boolean),
  (85, 'Verdant Catacombs'::text, 1::int, false::boolean),
  (86, 'Vial Smasher the Fierce'::text, 1::int, false::boolean),
  (87, 'Witch''s Clinic'::text, 1::int, false::boolean);

DROP TABLE IF EXISTS tmp_valgavoth_variant01_picked;
CREATE TEMP TABLE tmp_valgavoth_variant01_picked AS
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
  FROM tmp_valgavoth_variant01_input i
  LEFT JOIN cards c
    ON lower(c.name) = lower(i.card_name)
    OR lower(split_part(c.name, ' // ', 1)) = lower(split_part(i.card_name, ' // ', 1))
)
SELECT * FROM candidates WHERE rn = 1 OR card_id IS NULL;


SELECT
  'pg_valgavoth_variant01_precheck_coverage' AS check_name,
  COUNT(*) AS input_rows,
  COALESCE(SUM(quantity),0)::int AS input_qty,
  COALESCE(SUM(CASE WHEN is_commander THEN quantity ELSE 0 END),0)::int AS commander_qty,
  COUNT(card_id) AS resolved_rows,
  COUNT(*) FILTER (WHERE card_id IS NULL) AS missing_rows
FROM tmp_valgavoth_variant01_picked;

SELECT 'pg_valgavoth_variant01_missing_card' AS check_name, ord, card_name, quantity, is_commander
FROM tmp_valgavoth_variant01_picked
WHERE card_id IS NULL
ORDER BY ord;

SELECT
  'pg_valgavoth_variant01_existing_target' AS check_name,
  (SELECT COUNT(*) FROM decks WHERE id = 'c77cb83c-dd28-5d66-a0d8-799079a848bb'::uuid) AS deck_rows,
  (SELECT COALESCE(SUM(quantity),0)::int FROM deck_cards WHERE deck_id = 'c77cb83c-dd28-5d66-a0d8-799079a848bb'::uuid) AS deck_qty,
  (SELECT COUNT(*) FROM commander_learned_decks WHERE source_system = 'manual_user_deck_registration' AND source_ref = 'valgavoth_variant01_20260624_b037751a69fa') AS learned_rows;
