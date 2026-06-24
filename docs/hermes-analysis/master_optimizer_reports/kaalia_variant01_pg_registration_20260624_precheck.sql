\pset pager off
-- PG register precheck for Kaalia Variant 01.
-- No writes outside TEMP tables.
DROP TABLE IF EXISTS tmp_kaalia_variant01_input;
CREATE TEMP TABLE tmp_kaalia_variant01_input(ord int, card_name text, quantity int, is_commander boolean);
INSERT INTO tmp_kaalia_variant01_input(ord, card_name, quantity, is_commander) VALUES
  (1, 'Kaalia of the Vast'::text, 1::int, true::boolean),
  (2, 'Alicia Masters, Skilled Sculptor'::text, 1::int, false::boolean),
  (3, 'Ancient Tomb'::text, 1::int, false::boolean),
  (4, 'Arcane Signet'::text, 1::int, false::boolean),
  (5, 'Archaeomancer''s Map'::text, 1::int, false::boolean),
  (6, 'Ardenn, Intrepid Archaeologist'::text, 1::int, false::boolean),
  (7, 'Arid Mesa'::text, 1::int, false::boolean),
  (8, 'Basalt Monolith'::text, 1::int, false::boolean),
  (9, 'Biotransference'::text, 1::int, false::boolean),
  (10, 'Birgi, God of Storytelling'::text, 1::int, false::boolean),
  (11, 'Blightsteel Colossus'::text, 1::int, false::boolean),
  (12, 'Blood Crypt'::text, 1::int, false::boolean),
  (13, 'Bloodstained Mire'::text, 1::int, false::boolean),
  (14, 'Bloodthirster'::text, 1::int, false::boolean),
  (15, 'Burnt Offering'::text, 1::int, false::boolean),
  (16, 'Cabal Ritual'::text, 1::int, false::boolean),
  (17, 'City of Traitors'::text, 1::int, false::boolean),
  (18, 'Clifftop Retreat'::text, 1::int, false::boolean),
  (19, 'Command Tower'::text, 1::int, false::boolean),
  (20, 'Culling the Weak'::text, 1::int, false::boolean),
  (21, 'Dark Ritual'::text, 1::int, false::boolean),
  (22, 'Delney, Streetwise Lookout'::text, 1::int, false::boolean),
  (23, 'Demonic Tutor'::text, 1::int, false::boolean),
  (24, 'Desperate Ritual'::text, 1::int, false::boolean),
  (25, 'Diabolic Intent'::text, 1::int, false::boolean),
  (26, 'Dragonskull Summit'::text, 1::int, false::boolean),
  (27, 'Elegant Parlor'::text, 1::int, false::boolean),
  (28, 'Enlightened Tutor'::text, 1::int, false::boolean),
  (29, 'Esper Sentinel'::text, 1::int, false::boolean),
  (30, 'Fable of the Mirror-Breaker'::text, 1::int, false::boolean),
  (31, 'Fabled Passage'::text, 1::int, false::boolean),
  (32, 'Forge Anew'::text, 1::int, false::boolean),
  (33, 'Genji Glove'::text, 1::int, false::boolean),
  (34, 'Godless Shrine'::text, 1::int, false::boolean),
  (35, 'Grand Abolisher'::text, 1::int, false::boolean),
  (36, 'Grim Monolith'::text, 1::int, false::boolean),
  (37, 'Grim Tutor'::text, 1::int, false::boolean),
  (38, 'Hammer of Nazahn'::text, 1::int, false::boolean),
  (39, 'Haunted Ridge'::text, 1::int, false::boolean),
  (40, 'Imperial Seal'::text, 1::int, false::boolean),
  (41, 'Infernal Plunge'::text, 1::int, false::boolean),
  (42, 'Isolated Chapel'::text, 1::int, false::boolean),
  (43, 'Jeska''s Will'::text, 1::int, false::boolean),
  (44, 'Karlach, Fury of Avernus'::text, 1::int, false::boolean),
  (45, 'Lightning Greaves'::text, 1::int, false::boolean),
  (46, 'Lightning, Army of One'::text, 1::int, false::boolean),
  (47, 'Mana Vault'::text, 1::int, false::boolean),
  (48, 'Marsh Flats'::text, 1::int, false::boolean),
  (49, 'Maskwood Nexus'::text, 1::int, false::boolean),
  (50, 'Master of Cruelties'::text, 1::int, false::boolean),
  (51, 'Mjölnir, Hammer of Thor'::text, 1::int, false::boolean),
  (52, 'Monologue Tax'::text, 1::int, false::boolean),
  (53, 'Mountain'::text, 2::int, false::boolean),
  (54, 'Necrodominance'::text, 1::int, false::boolean),
  (55, 'Necropotence'::text, 1::int, false::boolean),
  (56, 'Ornithopter of Paradise'::text, 1::int, false::boolean),
  (57, 'Oswald Fiddlebender'::text, 1::int, false::boolean),
  (58, 'Plains'::text, 9::int, false::boolean),
  (59, 'Professional Face-Breaker'::text, 1::int, false::boolean),
  (60, 'Puresteel Paladin'::text, 1::int, false::boolean),
  (61, 'Pyretic Ritual'::text, 1::int, false::boolean),
  (62, 'Ragavan, Nimble Pilferer'::text, 1::int, false::boolean),
  (63, 'Ranger-Captain of Eos'::text, 1::int, false::boolean),
  (64, 'Raucous Theater'::text, 1::int, false::boolean),
  (65, 'Razaketh, the Foulblooded'::text, 1::int, false::boolean),
  (66, 'Rune-Scarred Demon'::text, 1::int, false::boolean),
  (67, 'Sacred Foundry'::text, 1::int, false::boolean),
  (68, 'Savai Triome'::text, 1::int, false::boolean),
  (69, 'Shadowy Backstreet'::text, 1::int, false::boolean),
  (70, 'Shattered Sanctum'::text, 1::int, false::boolean),
  (71, 'Sigarda''s Aid'::text, 1::int, false::boolean),
  (72, 'Silence'::text, 1::int, false::boolean),
  (73, 'Smothering Tithe'::text, 1::int, false::boolean),
  (74, 'Smuggler''s Share'::text, 1::int, false::boolean),
  (75, 'Sol Ring'::text, 1::int, false::boolean),
  (76, 'Sram, Senior Edificer'::text, 1::int, false::boolean),
  (77, 'Steelshaper''s Gift'::text, 1::int, false::boolean),
  (78, 'Stoneforge Mystic'::text, 1::int, false::boolean),
  (79, 'Strike It Rich'::text, 1::int, false::boolean),
  (80, 'Sundown Pass'::text, 1::int, false::boolean),
  (81, 'Sunforger'::text, 1::int, false::boolean),
  (82, 'Swamp'::text, 3::int, false::boolean),
  (83, 'The One Ring'::text, 1::int, false::boolean),
  (84, 'The Seriema'::text, 1::int, false::boolean),
  (85, 'Trouble in Pairs'::text, 1::int, false::boolean),
  (86, 'Vampiric Tutor'::text, 1::int, false::boolean),
  (87, 'Voice of Victory'::text, 1::int, false::boolean),
  (88, 'Vorpal Sword'::text, 1::int, false::boolean),
  (89, 'Wishclaw Talisman'::text, 1::int, false::boolean);

DROP TABLE IF EXISTS tmp_kaalia_variant01_picked;
CREATE TEMP TABLE tmp_kaalia_variant01_picked AS
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
  FROM tmp_kaalia_variant01_input i
  LEFT JOIN cards c
    ON lower(c.name) = lower(i.card_name)
    OR lower(split_part(c.name, ' // ', 1)) = lower(split_part(i.card_name, ' // ', 1))
)
SELECT * FROM candidates WHERE rn = 1 OR card_id IS NULL;


SELECT
  'pg_kaalia_variant01_precheck_coverage' AS check_name,
  COUNT(*) AS input_rows,
  COALESCE(SUM(quantity),0)::int AS input_qty,
  COALESCE(SUM(CASE WHEN is_commander THEN quantity ELSE 0 END),0)::int AS commander_qty,
  COUNT(card_id) AS resolved_rows,
  COUNT(*) FILTER (WHERE card_id IS NULL) AS missing_rows
FROM tmp_kaalia_variant01_picked;

SELECT 'pg_kaalia_variant01_missing_card' AS check_name, ord, card_name, quantity, is_commander
FROM tmp_kaalia_variant01_picked
WHERE card_id IS NULL
ORDER BY ord;

SELECT
  'pg_kaalia_variant01_existing_target' AS check_name,
  (SELECT COUNT(*) FROM decks WHERE id = 'b629f227-b2b2-5e71-9854-99d345a8e01c'::uuid) AS deck_rows,
  (SELECT COALESCE(SUM(quantity),0)::int FROM deck_cards WHERE deck_id = 'b629f227-b2b2-5e71-9854-99d345a8e01c'::uuid) AS deck_qty,
  (SELECT COUNT(*) FROM commander_learned_decks WHERE source_system = 'manual_user_deck_registration' AND source_ref = 'kaalia_variant01_20260624_b895928feb6f') AS learned_rows;
