\pset pager off
-- PG register precheck for Lorehold Variant 05.
-- No writes outside TEMP tables.
DROP TABLE IF EXISTS tmp_lorehold_variant05_input;
CREATE TEMP TABLE tmp_lorehold_variant05_input(ord int, card_name text, quantity int, is_commander boolean);
INSERT INTO tmp_lorehold_variant05_input(ord, card_name, quantity, is_commander) VALUES
  (1, 'Lorehold, the Historian'::text, 1::int, true::boolean),
  (2, 'Adagia, Windswept Bastion'::text, 1::int, false::boolean),
  (3, 'All Is Dust'::text, 1::int, false::boolean),
  (4, 'Ancient Den'::text, 1::int, false::boolean),
  (5, 'Apex of Power'::text, 1::int, false::boolean),
  (6, 'Approach of the Second Sun'::text, 1::int, false::boolean),
  (7, 'Arcane Signet'::text, 1::int, false::boolean),
  (8, 'Artist''s Talent'::text, 1::int, false::boolean),
  (9, 'Assemble the Players'::text, 1::int, false::boolean),
  (10, 'Austere Command'::text, 1::int, false::boolean),
  (11, 'Basalt Monolith'::text, 1::int, false::boolean),
  (12, 'Battlefield Forge'::text, 1::int, false::boolean),
  (13, 'Beacon of Immortality'::text, 1::int, false::boolean),
  (14, 'Bender''s Waterskin'::text, 1::int, false::boolean),
  (15, 'Blasphemous Act'::text, 1::int, false::boolean),
  (16, 'Boros Garrison'::text, 1::int, false::boolean),
  (17, 'Brilliant Restoration'::text, 1::int, false::boolean),
  (18, 'Buried Ruin'::text, 1::int, false::boolean),
  (19, 'Call Forth the Tempest'::text, 1::int, false::boolean),
  (20, 'Clifftop Retreat'::text, 1::int, false::boolean),
  (21, 'Codex Shredder'::text, 1::int, false::boolean),
  (22, 'Command Tower'::text, 1::int, false::boolean),
  (23, 'Crawlspace'::text, 1::int, false::boolean),
  (24, 'Darksteel Citadel'::text, 1::int, false::boolean),
  (25, 'Elegant Parlor'::text, 1::int, false::boolean),
  (26, 'Ensnaring Bridge'::text, 1::int, false::boolean),
  (27, 'Fellwar Stone'::text, 1::int, false::boolean),
  (28, 'Fomori Vault'::text, 1::int, false::boolean),
  (29, 'Generous Gift'::text, 1::int, false::boolean),
  (30, 'Ghoulcaller''s Bell'::text, 1::int, false::boolean),
  (31, 'Goblin Engineer'::text, 1::int, false::boolean),
  (32, 'Great Furnace'::text, 1::int, false::boolean),
  (33, 'Helm of Awakening'::text, 1::int, false::boolean),
  (34, 'Hit the Mother Lode'::text, 1::int, false::boolean),
  (35, 'Improvisation Capstone'::text, 1::int, false::boolean),
  (36, 'Inventors'' Fair'::text, 1::int, false::boolean),
  (37, 'Invincible Hymn'::text, 1::int, false::boolean),
  (38, 'Karn''s Sylex'::text, 1::int, false::boolean),
  (39, 'Karn, the Great Creator'::text, 1::int, false::boolean),
  (40, 'Kayla''s Music Box'::text, 1::int, false::boolean),
  (41, 'Land Tax'::text, 1::int, false::boolean),
  (42, 'Lantern of Insight'::text, 1::int, false::boolean),
  (43, 'Lens of Clarity'::text, 1::int, false::boolean),
  (44, 'Leyline Dowser'::text, 1::int, false::boolean),
  (45, 'Library of Leng'::text, 1::int, false::boolean),
  (46, 'Manifold Key'::text, 1::int, false::boolean),
  (47, 'Millikin'::text, 1::int, false::boolean),
  (48, 'Mizzix''s Mastery'::text, 1::int, false::boolean),
  (49, 'Mountain // Mountain'::text, 3::int, false::boolean),
  (50, 'Mox Opal'::text, 1::int, false::boolean),
  (51, 'Mystic Forge'::text, 1::int, false::boolean),
  (52, 'Norn''s Annex'::text, 1::int, false::boolean),
  (53, 'Open the Vaults'::text, 1::int, false::boolean),
  (54, 'Orcish Spy'::text, 1::int, false::boolean),
  (55, 'Oswald Fiddlebender'::text, 1::int, false::boolean),
  (56, 'Perch Protection'::text, 1::int, false::boolean),
  (57, 'Perpetual Timepiece'::text, 1::int, false::boolean),
  (58, 'Pinnacle Monk // Mystic Peak'::text, 1::int, false::boolean),
  (59, 'Plains // Plains'::text, 4::int, false::boolean),
  (60, 'Plateau'::text, 1::int, false::boolean),
  (61, 'Primal Amulet // Primal Wellspring'::text, 1::int, false::boolean),
  (62, 'Prototype Portal'::text, 1::int, false::boolean),
  (63, 'Pyxis of Pandemonium'::text, 1::int, false::boolean),
  (64, 'Redress Fate'::text, 1::int, false::boolean),
  (65, 'Restoration Seminar'::text, 1::int, false::boolean),
  (66, 'Roar of Reclamation'::text, 1::int, false::boolean),
  (67, 'Rugged Prairie'::text, 1::int, false::boolean),
  (68, 'Rustvale Bridge'::text, 1::int, false::boolean),
  (69, 'Sacred Foundry'::text, 1::int, false::boolean),
  (70, 'Scroll Rack'::text, 1::int, false::boolean),
  (71, 'Sculpting Steel'::text, 1::int, false::boolean),
  (72, 'Sensei''s Divining Top'::text, 1::int, false::boolean),
  (73, 'Silent Arbiter'::text, 1::int, false::boolean),
  (74, 'Sol Ring'::text, 1::int, false::boolean),
  (75, 'Spectator Seating'::text, 1::int, false::boolean),
  (76, 'Spire of Industry'::text, 1::int, false::boolean),
  (77, 'Squee, Goblin Nabob'::text, 1::int, false::boolean),
  (78, 'Stroke of Midnight'::text, 1::int, false::boolean),
  (79, 'Sunbaked Canyon'::text, 1::int, false::boolean),
  (80, 'Sunbillow Verge'::text, 1::int, false::boolean),
  (81, 'Swords to Plowshares'::text, 1::int, false::boolean),
  (82, 'Tezzeret, Cruel Captain'::text, 1::int, false::boolean),
  (83, 'The Mycosynth Gardens'::text, 1::int, false::boolean),
  (84, 'The Warring Triad'::text, 1::int, false::boolean),
  (85, 'Tocasia''s Dig Site'::text, 1::int, false::boolean),
  (86, 'Triumphant Reckoning'::text, 1::int, false::boolean),
  (87, 'Unstable Glyphbridge // Sandswirl Wanderglyph'::text, 1::int, false::boolean),
  (88, 'Unwinding Clock'::text, 1::int, false::boolean),
  (89, 'Urza''s Saga'::text, 1::int, false::boolean),
  (90, 'Valakut Awakening // Valakut Stoneforge'::text, 1::int, false::boolean),
  (91, 'Vanquish the Horde'::text, 1::int, false::boolean),
  (92, 'Victory Chimes'::text, 1::int, false::boolean),
  (93, 'Voltaic Key'::text, 1::int, false::boolean),
  (94, 'Wake the Past'::text, 1::int, false::boolean),
  (95, 'Wand of Vertebrae'::text, 1::int, false::boolean);

DROP TABLE IF EXISTS tmp_lorehold_variant05_picked;
CREATE TEMP TABLE tmp_lorehold_variant05_picked AS
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
  FROM tmp_lorehold_variant05_input i
  LEFT JOIN cards c
    ON lower(c.name) = lower(i.card_name)
    OR lower(split_part(c.name, ' // ', 1)) = lower(split_part(i.card_name, ' // ', 1))
)
SELECT * FROM candidates WHERE rn = 1 OR card_id IS NULL;


SELECT
  'pg_lorehold_variant05_precheck_coverage' AS check_name,
  COUNT(*) AS input_rows,
  COALESCE(SUM(quantity),0)::int AS input_qty,
  COALESCE(SUM(CASE WHEN is_commander THEN quantity ELSE 0 END),0)::int AS commander_qty,
  COUNT(card_id) AS resolved_rows,
  COUNT(*) FILTER (WHERE card_id IS NULL) AS missing_rows
FROM tmp_lorehold_variant05_picked;

SELECT 'pg_lorehold_variant05_missing_card' AS check_name, ord, card_name, quantity, is_commander
FROM tmp_lorehold_variant05_picked
WHERE card_id IS NULL
ORDER BY ord;

SELECT
  'pg_lorehold_variant05_existing_target' AS check_name,
  (SELECT COUNT(*) FROM decks WHERE id = '8aa57962-3a3e-5351-89fd-e4651456a3bd'::uuid) AS deck_rows,
  (SELECT COALESCE(SUM(quantity),0)::int FROM deck_cards WHERE deck_id = '8aa57962-3a3e-5351-89fd-e4651456a3bd'::uuid) AS deck_qty,
  (SELECT COUNT(*) FROM commander_learned_decks WHERE source_system = 'manual_user_deck_registration' AND source_ref = 'lorehold_variant05_20260624_5154c88a8b0b') AS learned_rows;
