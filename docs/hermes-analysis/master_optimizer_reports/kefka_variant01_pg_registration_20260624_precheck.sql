\pset pager off
-- PG register precheck for Kefka Variant 01.
-- No writes outside TEMP tables.
DROP TABLE IF EXISTS tmp_kefka_variant01_input;
CREATE TEMP TABLE tmp_kefka_variant01_input(ord int, card_name text, quantity int, is_commander boolean);
INSERT INTO tmp_kefka_variant01_input(ord, card_name, quantity, is_commander) VALUES
  (1, 'Kefka, Court Mage'::text, 1::int, true::boolean),
  (2, 'Aclazotz, Deepest Betrayal'::text, 1::int, false::boolean),
  (3, 'Arcane Denial'::text, 1::int, false::boolean),
  (4, 'Arcane Signet'::text, 1::int, false::boolean),
  (5, 'Archfiend of Ifnir'::text, 1::int, false::boolean),
  (6, 'Black Market Connections'::text, 1::int, false::boolean),
  (7, 'Blazemire Verge'::text, 1::int, false::boolean),
  (8, 'Blood Crypt'::text, 1::int, false::boolean),
  (9, 'Bloodchief Ascension'::text, 1::int, false::boolean),
  (10, 'Bloodletter of Aclazotz'::text, 1::int, false::boolean),
  (11, 'Bloodthirsty Conqueror'::text, 1::int, false::boolean),
  (12, 'Bojuka Bog'::text, 1::int, false::boolean),
  (13, 'Bone Miser'::text, 1::int, false::boolean),
  (14, 'Brallin, Skyshark Rider'::text, 1::int, false::boolean),
  (15, 'Cathartic Reunion'::text, 1::int, false::boolean),
  (16, 'Chaos Warp'::text, 1::int, false::boolean),
  (17, 'Command Tower'::text, 1::int, false::boolean),
  (18, 'Containment Construct'::text, 1::int, false::boolean),
  (19, 'Court of Ambition'::text, 1::int, false::boolean),
  (20, 'Crumbling Necropolis'::text, 1::int, false::boolean),
  (21, 'Dark Deal'::text, 1::int, false::boolean),
  (22, 'Davros, Dalek Creator'::text, 1::int, false::boolean),
  (23, 'Deflecting Swat'::text, 1::int, false::boolean),
  (24, 'Demolition Field'::text, 1::int, false::boolean),
  (25, 'Dragonskull Summit'::text, 1::int, false::boolean),
  (26, 'Drossforge Bridge'::text, 1::int, false::boolean),
  (27, 'Drowned Catacomb'::text, 1::int, false::boolean),
  (28, 'Entropic Battlecruiser'::text, 1::int, false::boolean),
  (29, 'Exotic Orchard'::text, 1::int, false::boolean),
  (30, 'Exquisite Blood'::text, 1::int, false::boolean),
  (31, 'Faithless Looting'::text, 1::int, false::boolean),
  (32, 'Feast of Sanity'::text, 1::int, false::boolean),
  (33, 'Fell Specter'::text, 1::int, false::boolean),
  (34, 'Geth''s Grimoire'::text, 1::int, false::boolean),
  (35, 'Glint-Horn Buccaneer'::text, 1::int, false::boolean),
  (36, 'Gloomlake Verge'::text, 1::int, false::boolean),
  (37, 'Green Goblin, Nemesis'::text, 1::int, false::boolean),
  (38, 'Harmonic Prodigy'::text, 1::int, false::boolean),
  (39, 'Haunted Ridge'::text, 1::int, false::boolean),
  (40, 'Island'::text, 2::int, false::boolean),
  (41, 'Kaya''s Ghostform'::text, 1::int, false::boolean),
  (42, 'Liliana''s Caress'::text, 1::int, false::boolean),
  (43, 'Luxury Suite'::text, 1::int, false::boolean),
  (44, 'Magmakin Artillerist'::text, 1::int, false::boolean),
  (45, 'Mana Drain'::text, 1::int, false::boolean),
  (46, 'Megrim'::text, 1::int, false::boolean),
  (47, 'Mistvault Bridge'::text, 1::int, false::boolean),
  (48, 'Monument to Endurance'::text, 1::int, false::boolean),
  (49, 'Morphic Pool'::text, 1::int, false::boolean),
  (50, 'Mountain'::text, 2::int, false::boolean),
  (51, 'Necrogoyf'::text, 1::int, false::boolean),
  (52, 'Niv-Mizzet, Parun'::text, 1::int, false::boolean),
  (53, 'Oppression'::text, 1::int, false::boolean),
  (54, 'Painful Quandary'::text, 1::int, false::boolean),
  (55, 'Phyrexian Arena'::text, 1::int, false::boolean),
  (56, 'Psychic Frog'::text, 1::int, false::boolean),
  (57, 'Psychosis Crawler'::text, 1::int, false::boolean),
  (58, 'Raiders'' Wake'::text, 1::int, false::boolean),
  (59, 'Raucous Theater'::text, 1::int, false::boolean),
  (60, 'Riverpyre Verge'::text, 1::int, false::boolean),
  (61, 'Rogue''s Passage'::text, 1::int, false::boolean),
  (62, 'Sangromancer'::text, 1::int, false::boolean),
  (63, 'Scalding Tarn'::text, 1::int, false::boolean),
  (64, 'Scavenger Grounds'::text, 1::int, false::boolean),
  (65, 'Sheoldred'::text, 1::int, false::boolean),
  (66, 'Sheoldred, the Apocalypse'::text, 1::int, false::boolean),
  (67, 'Shipwreck Marsh'::text, 1::int, false::boolean),
  (68, 'Silverbluff Bridge'::text, 1::int, false::boolean),
  (69, 'Sol Ring'::text, 1::int, false::boolean),
  (70, 'Solphim, Mayhem Dominus'::text, 1::int, false::boolean),
  (71, 'Steam Vents'::text, 1::int, false::boolean),
  (72, 'Stormcarved Coast'::text, 1::int, false::boolean),
  (73, 'Sulfur Falls'::text, 1::int, false::boolean),
  (74, 'Surly Badgersaur'::text, 1::int, false::boolean),
  (75, 'Swamp'::text, 2::int, false::boolean),
  (76, 'Swan Song'::text, 1::int, false::boolean),
  (77, 'Swiftfoot Boots'::text, 1::int, false::boolean),
  (78, 'Syr Konrad, the Grim'::text, 1::int, false::boolean),
  (79, 'Teferi''s Time Twist'::text, 1::int, false::boolean),
  (80, 'The Haunt of Hightower'::text, 1::int, false::boolean),
  (81, 'The Locust God'::text, 1::int, false::boolean),
  (82, 'Thundering Falls'::text, 1::int, false::boolean),
  (83, 'Tinybones, Bauble Burglar'::text, 1::int, false::boolean),
  (84, 'Tinybones, Trinket Thief'::text, 1::int, false::boolean),
  (85, 'Toxic Deluge'::text, 1::int, false::boolean),
  (86, 'Training Center'::text, 1::int, false::boolean),
  (87, 'Underworld Dreams'::text, 1::int, false::boolean),
  (88, 'Urborg, Tomb of Yawgmoth'::text, 1::int, false::boolean),
  (89, 'Vandalblast'::text, 1::int, false::boolean),
  (90, 'Vivi Ornitier'::text, 1::int, false::boolean),
  (91, 'Waste Not'::text, 1::int, false::boolean),
  (92, 'Watery Grave'::text, 1::int, false::boolean),
  (93, 'Whip of Erebos'::text, 1::int, false::boolean),
  (94, 'Withering Torment'::text, 1::int, false::boolean),
  (95, 'Words of Waste'::text, 1::int, false::boolean),
  (96, 'Wound Reflection'::text, 1::int, false::boolean),
  (97, 'Xander''s Lounge'::text, 1::int, false::boolean);

DROP TABLE IF EXISTS tmp_kefka_variant01_picked;
CREATE TEMP TABLE tmp_kefka_variant01_picked AS
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
  FROM tmp_kefka_variant01_input i
  LEFT JOIN cards c
    ON lower(c.name) = lower(i.card_name)
    OR lower(split_part(c.name, ' // ', 1)) = lower(split_part(i.card_name, ' // ', 1))
)
SELECT * FROM candidates WHERE rn = 1 OR card_id IS NULL;


SELECT
  'pg_kefka_variant01_precheck_coverage' AS check_name,
  COUNT(*) AS input_rows,
  COALESCE(SUM(quantity),0)::int AS input_qty,
  COALESCE(SUM(CASE WHEN is_commander THEN quantity ELSE 0 END),0)::int AS commander_qty,
  COUNT(card_id) AS resolved_rows,
  COUNT(*) FILTER (WHERE card_id IS NULL) AS missing_rows
FROM tmp_kefka_variant01_picked;

SELECT 'pg_kefka_variant01_missing_card' AS check_name, ord, card_name, quantity, is_commander
FROM tmp_kefka_variant01_picked
WHERE card_id IS NULL
ORDER BY ord;

SELECT
  'pg_kefka_variant01_existing_target' AS check_name,
  (SELECT COUNT(*) FROM decks WHERE id = '34508aae-e393-577a-97d8-6259353664af'::uuid) AS deck_rows,
  (SELECT COALESCE(SUM(quantity),0)::int FROM deck_cards WHERE deck_id = '34508aae-e393-577a-97d8-6259353664af'::uuid) AS deck_qty,
  (SELECT COUNT(*) FROM commander_learned_decks WHERE source_system = 'manual_user_deck_registration' AND source_ref = 'kefka_variant01_20260624_ec4ca73a3063') AS learned_rows;
