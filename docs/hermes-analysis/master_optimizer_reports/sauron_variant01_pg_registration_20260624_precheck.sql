\pset pager off
-- PG register precheck for Sauron Variant 01.
-- No writes outside TEMP tables.
DROP TABLE IF EXISTS tmp_sauron_variant01_input;
CREATE TEMP TABLE tmp_sauron_variant01_input(ord int, card_name text, quantity int, is_commander boolean);
INSERT INTO tmp_sauron_variant01_input(ord, card_name, quantity, is_commander) VALUES
  (1, 'Sauron, the Dark Lord'::text, 1::int, true::boolean),
  (2, 'Afterlife from the Loam'::text, 1::int, false::boolean),
  (3, 'An Offer You Can''t Refuse'::text, 1::int, false::boolean),
  (4, 'Ancient Tomb'::text, 1::int, false::boolean),
  (5, 'Anger'::text, 1::int, false::boolean),
  (6, 'Animate Dead'::text, 1::int, false::boolean),
  (7, 'Arcane Signet'::text, 1::int, false::boolean),
  (8, 'Archfiend of Ifnir'::text, 1::int, false::boolean),
  (9, 'Arid Mesa'::text, 1::int, false::boolean),
  (10, 'Bilbo, Retired Burglar'::text, 1::int, false::boolean),
  (11, 'Blood Crypt'::text, 1::int, false::boolean),
  (12, 'Blood for the Blood God!'::text, 1::int, false::boolean),
  (13, 'Bloodstained Mire'::text, 1::int, false::boolean),
  (14, 'Cabal Coffers'::text, 1::int, false::boolean),
  (15, 'Call of the Ring'::text, 1::int, false::boolean),
  (16, 'Cavern of Souls'::text, 1::int, false::boolean),
  (17, 'Cavern-Hoard Dragon'::text, 1::int, false::boolean),
  (18, 'City of Brass'::text, 1::int, false::boolean),
  (19, 'Command Tower'::text, 1::int, false::boolean),
  (20, 'Culling the Weak'::text, 1::int, false::boolean),
  (21, 'Cursed Mirror'::text, 1::int, false::boolean),
  (22, 'Damnation'::text, 1::int, false::boolean),
  (23, 'Dark Ritual'::text, 1::int, false::boolean),
  (24, 'Devastating Onslaught'::text, 1::int, false::boolean),
  (25, 'Diabolic Intent'::text, 1::int, false::boolean),
  (26, 'Dismember'::text, 1::int, false::boolean),
  (27, 'Displacer Kitten'::text, 1::int, false::boolean),
  (28, 'Dragonskull Summit'::text, 1::int, false::boolean),
  (29, 'Entomb'::text, 1::int, false::boolean),
  (30, 'Fellwar Stone'::text, 1::int, false::boolean),
  (31, 'Flooded Strand'::text, 1::int, false::boolean),
  (32, 'Gemstone Caverns'::text, 1::int, false::boolean),
  (33, 'Hullbreaker Horror'::text, 1::int, false::boolean),
  (34, 'Island'::text, 2::int, false::boolean),
  (35, 'Likeness Looter'::text, 1::int, false::boolean),
  (36, 'Living Death'::text, 1::int, false::boolean),
  (37, 'Luxury Suite'::text, 1::int, false::boolean),
  (38, 'Mana Drain'::text, 1::int, false::boolean),
  (39, 'Misty Rainforest'::text, 1::int, false::boolean),
  (40, 'Morphic Pool'::text, 1::int, false::boolean),
  (41, 'Mount Doom'::text, 1::int, false::boolean),
  (42, 'Mountain'::text, 2::int, false::boolean),
  (43, 'Nazgûl'::text, 9::int, false::boolean),
  (44, 'Necromancy'::text, 1::int, false::boolean),
  (45, 'Orcish Bowmasters'::text, 1::int, false::boolean),
  (46, 'Pact of Negation'::text, 1::int, false::boolean),
  (47, 'Phyrexian Tower'::text, 1::int, false::boolean),
  (48, 'Polluted Delta'::text, 1::int, false::boolean),
  (49, 'Razaketh, the Foulblooded'::text, 1::int, false::boolean),
  (50, 'Reanimate'::text, 1::int, false::boolean),
  (51, 'Reflecting Pool'::text, 1::int, false::boolean),
  (52, 'Relic of Sauron'::text, 1::int, false::boolean),
  (53, 'Rise of the Dark Realms'::text, 1::int, false::boolean),
  (54, 'Ruthless Technomancer'::text, 1::int, false::boolean),
  (55, 'Scalding Tarn'::text, 1::int, false::boolean),
  (56, 'Seething Landscape'::text, 1::int, false::boolean),
  (57, 'Shadowspear'::text, 1::int, false::boolean),
  (58, 'Sheoldred, the Apocalypse'::text, 1::int, false::boolean),
  (59, 'Sol Ring'::text, 1::int, false::boolean),
  (60, 'Soothing of Sméagol'::text, 1::int, false::boolean),
  (61, 'Spiteful Banditry'::text, 1::int, false::boolean),
  (62, 'Starwinder'::text, 1::int, false::boolean),
  (63, 'Steam Vents'::text, 1::int, false::boolean),
  (64, 'Strix Serenade'::text, 1::int, false::boolean),
  (65, 'Sulfurous Springs'::text, 1::int, false::boolean),
  (66, 'Swamp'::text, 2::int, false::boolean),
  (67, 'Swan Song'::text, 1::int, false::boolean),
  (68, 'Talisman of Creativity'::text, 1::int, false::boolean),
  (69, 'Talisman of Dominance'::text, 1::int, false::boolean),
  (70, 'Talisman of Indulgence'::text, 1::int, false::boolean),
  (71, 'Terror of the Peaks'::text, 1::int, false::boolean),
  (72, 'The Balrog of Moria'::text, 1::int, false::boolean),
  (73, 'The Black Gate'::text, 1::int, false::boolean),
  (74, 'The One Ring'::text, 1::int, false::boolean),
  (75, 'The Ozolith'::text, 1::int, false::boolean),
  (76, 'The Reaver Cleaver'::text, 1::int, false::boolean),
  (77, 'The Soul Stone'::text, 1::int, false::boolean),
  (78, 'Toxic Deluge'::text, 1::int, false::boolean),
  (79, 'Underground River'::text, 1::int, false::boolean),
  (80, 'Urborg, Tomb of Yawgmoth'::text, 1::int, false::boolean),
  (81, 'Urza''s Saga'::text, 1::int, false::boolean),
  (82, 'Verdant Catacombs'::text, 1::int, false::boolean),
  (83, 'Victimize'::text, 1::int, false::boolean),
  (84, 'Volrath''s Stronghold'::text, 1::int, false::boolean),
  (85, 'Warren Soultrader'::text, 1::int, false::boolean),
  (86, 'Watery Grave'::text, 1::int, false::boolean),
  (87, 'Windfall'::text, 1::int, false::boolean),
  (88, 'Withering Torment'::text, 1::int, false::boolean),
  (89, 'Wooded Foothills'::text, 1::int, false::boolean);

DROP TABLE IF EXISTS tmp_sauron_variant01_picked;
CREATE TEMP TABLE tmp_sauron_variant01_picked AS
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
  FROM tmp_sauron_variant01_input i
  LEFT JOIN cards c
    ON lower(c.name) = lower(i.card_name)
    OR lower(split_part(c.name, ' // ', 1)) = lower(split_part(i.card_name, ' // ', 1))
)
SELECT * FROM candidates WHERE rn = 1 OR card_id IS NULL;


SELECT
  'pg_sauron_variant01_precheck_coverage' AS check_name,
  COUNT(*) AS input_rows,
  COALESCE(SUM(quantity),0)::int AS input_qty,
  COALESCE(SUM(CASE WHEN is_commander THEN quantity ELSE 0 END),0)::int AS commander_qty,
  COUNT(card_id) AS resolved_rows,
  COUNT(*) FILTER (WHERE card_id IS NULL) AS missing_rows
FROM tmp_sauron_variant01_picked;

SELECT 'pg_sauron_variant01_missing_card' AS check_name, ord, card_name, quantity, is_commander
FROM tmp_sauron_variant01_picked
WHERE card_id IS NULL
ORDER BY ord;

SELECT
  'pg_sauron_variant01_existing_target' AS check_name,
  (SELECT COUNT(*) FROM decks WHERE id = 'c2230827-7963-52e4-a6ba-298d7be3478a'::uuid) AS deck_rows,
  (SELECT COALESCE(SUM(quantity),0)::int FROM deck_cards WHERE deck_id = 'c2230827-7963-52e4-a6ba-298d7be3478a'::uuid) AS deck_qty,
  (SELECT COUNT(*) FROM commander_learned_decks WHERE source_system = 'manual_user_deck_registration' AND source_ref = 'sauron_variant01_20260624_6aa4f012e11d') AS learned_rows;
