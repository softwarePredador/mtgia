\pset pager off
BEGIN;
-- PG register apply for Lorehold Variant 04.
-- Scope: insert/update one decks row, replace its deck_cards rows, upsert one inactive commander_learned_decks row.
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


DO $$
DECLARE
  missing_count int;
  total_qty int;
  commander_qty int;
BEGIN
  SELECT COUNT(*) INTO missing_count FROM tmp_lorehold_variant04_picked WHERE card_id IS NULL;
  IF missing_count <> 0 THEN
    RAISE EXCEPTION 'Refusing Lorehold Variant 04 PG registration: % cards missing from cards catalog', missing_count;
  END IF;
  SELECT COALESCE(SUM(quantity),0)::int INTO total_qty FROM tmp_lorehold_variant04_picked;
  SELECT COALESCE(SUM(CASE WHEN is_commander THEN quantity ELSE 0 END),0)::int INTO commander_qty FROM tmp_lorehold_variant04_picked;
  IF total_qty <> 100 THEN
    RAISE EXCEPTION 'Refusing Lorehold Variant 04 PG registration: expected qty 100, got %', total_qty;
  END IF;
  IF commander_qty <> 1 THEN
    RAISE EXCEPTION 'Refusing Lorehold Variant 04 PG registration: expected commander qty 1, got %', commander_qty;
  END IF;
END $$;

INSERT INTO decks (
  id, user_id, name, format, description, is_public, synergy_score,
  strengths, weaknesses, archetype, bracket
) VALUES (
  '917674eb-6a3d-58de-acce-5a2a3ac9e497'::uuid,
  NULL,
  'PG REGISTERED Lorehold Variant 04 - Rafael Paste 2026-06-24',
  'commander',
  'Manual Lorehold deck registration for card validation. deck_hash=ba7d06f86f2381388259c4926e684407284f70e313e83f80df922827a67d8f68; source=docs/hermes-analysis/manaloom-knowledge/decks/lorehold-the-historian/2026-06-24-variant-04-user-decklist.md',
  false,
  0,
  'Pending validation: user-pasted Lorehold deck registered for card logic review.',
  'Pending card-rule validation; not promoted as definitive deck.',
  'battle-variant',
  NULL
)
ON CONFLICT (id) DO UPDATE SET
  name = EXCLUDED.name,
  format = EXCLUDED.format,
  description = EXCLUDED.description,
  is_public = EXCLUDED.is_public,
  strengths = EXCLUDED.strengths,
  weaknesses = EXCLUDED.weaknesses,
  archetype = EXCLUDED.archetype,
  bracket = EXCLUDED.bracket;

DELETE FROM deck_cards WHERE deck_id = '917674eb-6a3d-58de-acce-5a2a3ac9e497'::uuid;

INSERT INTO deck_cards (deck_id, card_id, quantity, is_commander, condition)
SELECT
  '917674eb-6a3d-58de-acce-5a2a3ac9e497'::uuid,
  card_id,
  quantity,
  is_commander,
  'NM'
FROM tmp_lorehold_variant04_picked
ORDER BY ord;

INSERT INTO commander_learned_decks (
  id, commander_name, commander_name_normalized, deck_name,
  source_system, source_ref, source_url, archetype, card_list, card_count,
  score, wincon_primary, wincon_backup, legal_status, notes, metadata,
  is_active, promoted_at, updated_at
) VALUES (
  'a4767730-e826-5c14-b716-c6906f3d44c3'::uuid,
  'Lorehold, the Historian',
  'lorehold, the historian',
  'Lorehold Variant 04 - Rafael Paste 2026-06-24',
  'manual_user_deck_registration',
  'lorehold_variant04_20260624_ba7d06f86f23',
  'docs/hermes-analysis/manaloom-knowledge/decks/lorehold-the-historian/2026-06-24-variant-04-user-decklist.md',
  'battle-variant',
  '1 Lorehold, the Historian
1 Apex of Power
1 Approach of the Second Sun
1 Arcane Signet
1 Archaeomancer''s Map
1 Archivist of Oghma
1 Arid Archway
1 Arid Mesa
1 Ash Barrens
1 Austere Command
1 Battlefield Forge
1 Bender''s Waterskin
1 Big Score
1 Blasphemous Act
1 Blood Sun
1 Bolt Bend
1 Boros Charm
1 Boros Garrison
1 Boros Signet
1 Brass''s Bounty
1 Call Forth the Tempest
1 Clever Concealment
1 Clifftop Retreat
1 Command Tower
1 Dance with Calamity
1 Deflecting Swat
1 Demolition Field
1 Dragon''s Rage Channeler
1 Emeria''s Call // Emeria, Shattered Skyclave
1 Esper Sentinel
1 Fellwar Stone
1 Gamble
1 Giver of Runes
1 Glittering Massif
1 Guildless Commons
1 Hexing Squelcher
1 Hit the Mother Lode
1 Improvisation Capstone
1 Insurrection
1 Invoke Calamity
1 Knight of the White Orchid
1 Land Tax
1 Library of Leng
1 Lotus Field
1 Lotus Vale
1 Loyal Warhound
1 Mizzix''s Mastery
1 Monument to Endurance
1 Mother of Runes
5 Mountain // Mountain
1 Needleverge Pathway // Pillarverge Pathway
1 Olórin''s Searing Light
1 Path to Exile
1 Penance
1 Perch Protection
1 Pinnacle Monk // Mystic Peak
5 Plains // Plains
1 Radiant Summit
1 Reforge the Soul
1 Restoration Seminar
1 Rise of the Eldrazi
1 Rugged Prairie
1 Sacred Foundry
1 Sand Scout
1 Scavenger Grounds
1 Scholar of New Horizons
1 Scroll Rack
1 Sejiri Shelter // Sejiri Glacier
1 Sensei''s Divining Top
1 Sol Ring
1 Soul-Guide Lantern
1 Squee, Goblin Nabob
1 Starfield Shepherd
1 Storm Herd
1 Sunbillow Verge
1 Sundering Eruption // Volcanic Fissure
1 Sundown Pass
1 Swords to Plowshares
1 Talisman of Conviction
1 Tibalt''s Trickery
1 Unexpected Windfall
1 Urza''s Saga
1 Valakut Awakening // Valakut Stoneforge
1 Vandalblast
1 Verge Rangers
1 Victory Chimes
1 Volcanic Vision
1 Wear // Tear
1 Weathered Wayfarer
1 Wheel of Fortune
1 Wheel of Misfortune
1 Witch Enchanter // Witch-Blessed Meadow',
  100,
  NULL,
  'Approach of the Second Sun',
  'Rise of the Eldrazi / Storm Herd / Mizzix''s Mastery',
  'registered_pending_card_rule_validation',
  'Manual user-pasted Lorehold deck registered for downstream card validation; not promoted active.',
  '{"deck_hash": "ba7d06f86f2381388259c4926e684407284f70e313e83f80df922827a67d8f68", "hermes_deck_id": 609, "notes": "Registered from user-pasted Lorehold list. Not promoted as active learned deck.", "oracle_missing_after_registration": 0, "pg_deck_id": "917674eb-6a3d-58de-acce-5a2a3ac9e497", "registration_scope": "deck_intake_for_card_validation", "source_decklist": "docs/hermes-analysis/manaloom-knowledge/decks/lorehold-the-historian/2026-06-24-variant-04-user-decklist.md", "staging_report": "docs/hermes-analysis/master_optimizer_reports/lorehold_variant_staging_20260624_120107.json", "staging_warning_count": 14, "validation_status": "registered_pending_card_rule_validation"}'::jsonb,
  false,
  NULL,
  NOW()
)
ON CONFLICT (source_system, source_ref) DO UPDATE SET
  commander_name = EXCLUDED.commander_name,
  commander_name_normalized = EXCLUDED.commander_name_normalized,
  deck_name = EXCLUDED.deck_name,
  source_url = EXCLUDED.source_url,
  archetype = EXCLUDED.archetype,
  card_list = EXCLUDED.card_list,
  card_count = EXCLUDED.card_count,
  score = EXCLUDED.score,
  wincon_primary = EXCLUDED.wincon_primary,
  wincon_backup = EXCLUDED.wincon_backup,
  legal_status = EXCLUDED.legal_status,
  notes = EXCLUDED.notes,
  metadata = EXCLUDED.metadata,
  is_active = false,
  promoted_at = NULL,
  updated_at = NOW();

COMMIT;
