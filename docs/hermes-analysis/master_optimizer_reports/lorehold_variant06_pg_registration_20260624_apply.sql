\pset pager off
BEGIN;
-- PG register apply for Lorehold Variant 06.
-- Scope: insert/update one decks row, replace its deck_cards rows, upsert one inactive commander_learned_decks row.
DROP TABLE IF EXISTS tmp_lorehold_variant06_input;
CREATE TEMP TABLE tmp_lorehold_variant06_input(ord int, card_name text, quantity int, is_commander boolean);
INSERT INTO tmp_lorehold_variant06_input(ord, card_name, quantity, is_commander) VALUES
  (1, 'Lorehold, the Historian'::text, 1::int, true::boolean),
  (2, 'Alhammarret''s Archive'::text, 1::int, false::boolean),
  (3, 'Apex of Power'::text, 1::int, false::boolean),
  (4, 'Arcane Bombardment'::text, 1::int, false::boolean),
  (5, 'Arcane Signet'::text, 1::int, false::boolean),
  (6, 'Arid Mesa'::text, 1::int, false::boolean),
  (7, 'Ashling, Flame Dancer'::text, 1::int, false::boolean),
  (8, 'Austere Command'::text, 1::int, false::boolean),
  (9, 'Battlefield Forge'::text, 1::int, false::boolean),
  (10, 'Bender''s Waterskin'::text, 1::int, false::boolean),
  (11, 'Big Score'::text, 1::int, false::boolean),
  (12, 'Bloodstained Mire'::text, 1::int, false::boolean),
  (13, 'Boros Signet'::text, 1::int, false::boolean),
  (14, 'Brass''s Bounty'::text, 1::int, false::boolean),
  (15, 'Call Forth the Tempest'::text, 1::int, false::boolean),
  (16, 'Chaos Warp'::text, 1::int, false::boolean),
  (17, 'Clifftop Retreat'::text, 1::int, false::boolean),
  (18, 'Command Tower'::text, 1::int, false::boolean),
  (19, 'Crackle with Power'::text, 1::int, false::boolean),
  (20, 'Dance with Calamity'::text, 1::int, false::boolean),
  (21, 'Deflecting Swat'::text, 1::int, false::boolean),
  (22, 'Dualcaster Mage'::text, 1::int, false::boolean),
  (23, 'Electro, Assaulting Battery'::text, 1::int, false::boolean),
  (24, 'Elegant Parlor'::text, 1::int, false::boolean),
  (25, 'Enlightened Tutor'::text, 1::int, false::boolean),
  (26, 'Esper Sentinel'::text, 1::int, false::boolean),
  (27, 'Faithless Looting'::text, 1::int, false::boolean),
  (28, 'Fellwar Stone'::text, 1::int, false::boolean),
  (29, 'Fire Nation Palace'::text, 1::int, false::boolean),
  (30, 'Flooded Strand'::text, 1::int, false::boolean),
  (31, 'Galvanoth'::text, 1::int, false::boolean),
  (32, 'Goblin Engineer'::text, 1::int, false::boolean),
  (33, 'Goldspan Dragon'::text, 1::int, false::boolean),
  (34, 'Hit the Mother Lode'::text, 1::int, false::boolean),
  (35, 'Improvisation Capstone'::text, 1::int, false::boolean),
  (36, 'Insurrection'::text, 1::int, false::boolean),
  (37, 'Land Tax'::text, 1::int, false::boolean),
  (38, 'Library of Leng'::text, 1::int, false::boolean),
  (39, 'Longshot, Rebel Bowman'::text, 1::int, false::boolean),
  (40, 'Mizzix''s Mastery'::text, 1::int, false::boolean),
  (41, 'Monument to Endurance'::text, 1::int, false::boolean),
  (42, 'Mountain // Mountain'::text, 7::int, false::boolean),
  (43, 'Multiversal Passage'::text, 1::int, false::boolean),
  (44, 'Needleverge Pathway // Pillarverge Pathway'::text, 1::int, false::boolean),
  (45, 'Palantír of Orthanc'::text, 1::int, false::boolean),
  (46, 'Penance'::text, 1::int, false::boolean),
  (47, 'Perch Protection'::text, 1::int, false::boolean),
  (48, 'Pinnacle Monk // Mystic Peak'::text, 1::int, false::boolean),
  (49, 'Plains // Plains'::text, 5::int, false::boolean),
  (50, 'Planetarium of Wan Shi Tong'::text, 1::int, false::boolean),
  (51, 'Plateau'::text, 1::int, false::boolean),
  (52, 'Prismatic Vista'::text, 1::int, false::boolean),
  (53, 'Profound Journey'::text, 1::int, false::boolean),
  (54, 'Promise of Loyalty'::text, 1::int, false::boolean),
  (55, 'Radiant Summit'::text, 1::int, false::boolean),
  (56, 'Reckless Endeavor'::text, 1::int, false::boolean),
  (57, 'Reckless Handling'::text, 1::int, false::boolean),
  (58, 'Redirect Lightning'::text, 1::int, false::boolean),
  (59, 'Reforge the Soul'::text, 1::int, false::boolean),
  (60, 'Restoration Seminar'::text, 1::int, false::boolean),
  (61, 'Rise of the Eldrazi'::text, 1::int, false::boolean),
  (62, 'Ruby Medallion'::text, 1::int, false::boolean),
  (63, 'Rugged Prairie'::text, 1::int, false::boolean),
  (64, 'Sacred Foundry'::text, 1::int, false::boolean),
  (65, 'Scroll Rack'::text, 1::int, false::boolean),
  (66, 'Sensei''s Divining Top'::text, 1::int, false::boolean),
  (67, 'Smothering Tithe'::text, 1::int, false::boolean),
  (68, 'Sol Ring'::text, 1::int, false::boolean),
  (69, 'Spectator Seating'::text, 1::int, false::boolean),
  (70, 'Storm Herd'::text, 1::int, false::boolean),
  (71, 'Storm-Kiln Artist'::text, 1::int, false::boolean),
  (72, 'Sun Titan'::text, 1::int, false::boolean),
  (73, 'Sunbillow Verge'::text, 1::int, false::boolean),
  (74, 'Sundown Pass'::text, 1::int, false::boolean),
  (75, 'Talisman of Conviction'::text, 1::int, false::boolean),
  (76, 'Taunt from the Rampart'::text, 1::int, false::boolean),
  (77, 'Teferi''s Protection'::text, 1::int, false::boolean),
  (78, 'Temple of Triumph'::text, 1::int, false::boolean),
  (79, 'Turbulent Steppe'::text, 1::int, false::boolean),
  (80, 'Twinflame'::text, 1::int, false::boolean),
  (81, 'Twinflame Tyrant'::text, 1::int, false::boolean),
  (82, 'Unexpected Windfall'::text, 1::int, false::boolean),
  (83, 'Urza''s Saga'::text, 1::int, false::boolean),
  (84, 'Valakut Awakening // Valakut Stoneforge'::text, 1::int, false::boolean),
  (85, 'Velomachus Lorehold'::text, 1::int, false::boolean),
  (86, 'Verge Rangers'::text, 1::int, false::boolean),
  (87, 'Victory Chimes'::text, 1::int, false::boolean),
  (88, 'Volcanic Vision'::text, 1::int, false::boolean),
  (89, 'Wheel of Fate'::text, 1::int, false::boolean),
  (90, 'Wooded Foothills'::text, 1::int, false::boolean);

DROP TABLE IF EXISTS tmp_lorehold_variant06_picked;
CREATE TEMP TABLE tmp_lorehold_variant06_picked AS
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
  FROM tmp_lorehold_variant06_input i
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
  SELECT COUNT(*) INTO missing_count FROM tmp_lorehold_variant06_picked WHERE card_id IS NULL;
  IF missing_count <> 0 THEN
    RAISE EXCEPTION 'Refusing Lorehold Variant 06 PG registration: % cards missing from cards catalog', missing_count;
  END IF;
  SELECT COALESCE(SUM(quantity),0)::int INTO total_qty FROM tmp_lorehold_variant06_picked;
  SELECT COALESCE(SUM(CASE WHEN is_commander THEN quantity ELSE 0 END),0)::int INTO commander_qty FROM tmp_lorehold_variant06_picked;
  IF total_qty <> 100 THEN
    RAISE EXCEPTION 'Refusing Lorehold Variant 06 PG registration: expected qty 100, got %', total_qty;
  END IF;
  IF commander_qty <> 1 THEN
    RAISE EXCEPTION 'Refusing Lorehold Variant 06 PG registration: expected commander qty 1, got %', commander_qty;
  END IF;
END $$;

INSERT INTO decks (
  id, user_id, name, format, description, is_public, synergy_score,
  strengths, weaknesses, archetype, bracket
) VALUES (
  '0936dae3-32c4-5fb8-9c6f-d986670de794'::uuid,
  NULL,
  'PG REGISTERED Lorehold Variant 06 - Rafael Paste 2026-06-24',
  'commander',
  'Manual Lorehold deck registration for card validation. deck_hash=a073b0fdc0db03c432651caa8f41d275faa6d67e5efb3865daee7ff4ca543298; source=docs/hermes-analysis/manaloom-knowledge/decks/lorehold-the-historian/2026-06-24-variant-06-user-decklist.md',
  false,
  0,
  'Pending validation: user-pasted Lorehold big-spells deck registered for card logic review.',
  'Pending card-rule validation; not promoted as definitive deck.',
  'big-spells-variant',
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

DELETE FROM deck_cards WHERE deck_id = '0936dae3-32c4-5fb8-9c6f-d986670de794'::uuid;

INSERT INTO deck_cards (deck_id, card_id, quantity, is_commander, condition)
SELECT
  '0936dae3-32c4-5fb8-9c6f-d986670de794'::uuid,
  card_id,
  quantity,
  is_commander,
  'NM'
FROM tmp_lorehold_variant06_picked
ORDER BY ord;

INSERT INTO commander_learned_decks (
  id, commander_name, commander_name_normalized, deck_name,
  source_system, source_ref, source_url, archetype, card_list, card_count,
  score, wincon_primary, wincon_backup, legal_status, notes, metadata,
  is_active, promoted_at, updated_at
) VALUES (
  '90b0fbe9-683b-53cf-9fc1-75699196f4aa'::uuid,
  'Lorehold, the Historian',
  'lorehold, the historian',
  'Lorehold Variant 06 - Rafael Paste 2026-06-24',
  'manual_user_deck_registration',
  'lorehold_variant06_20260624_a073b0fdc0db',
  'docs/hermes-analysis/manaloom-knowledge/decks/lorehold-the-historian/2026-06-24-variant-06-user-decklist.md',
  'big-spells-variant',
  '1 Lorehold, the Historian
1 Alhammarret''s Archive
1 Apex of Power
1 Arcane Bombardment
1 Arcane Signet
1 Arid Mesa
1 Ashling, Flame Dancer
1 Austere Command
1 Battlefield Forge
1 Bender''s Waterskin
1 Big Score
1 Bloodstained Mire
1 Boros Signet
1 Brass''s Bounty
1 Call Forth the Tempest
1 Chaos Warp
1 Clifftop Retreat
1 Command Tower
1 Crackle with Power
1 Dance with Calamity
1 Deflecting Swat
1 Dualcaster Mage
1 Electro, Assaulting Battery
1 Elegant Parlor
1 Enlightened Tutor
1 Esper Sentinel
1 Faithless Looting
1 Fellwar Stone
1 Fire Nation Palace
1 Flooded Strand
1 Galvanoth
1 Goblin Engineer
1 Goldspan Dragon
1 Hit the Mother Lode
1 Improvisation Capstone
1 Insurrection
1 Land Tax
1 Library of Leng
1 Longshot, Rebel Bowman
1 Mizzix''s Mastery
1 Monument to Endurance
7 Mountain // Mountain
1 Multiversal Passage
1 Needleverge Pathway // Pillarverge Pathway
1 Palantír of Orthanc
1 Penance
1 Perch Protection
1 Pinnacle Monk // Mystic Peak
5 Plains // Plains
1 Planetarium of Wan Shi Tong
1 Plateau
1 Prismatic Vista
1 Profound Journey
1 Promise of Loyalty
1 Radiant Summit
1 Reckless Endeavor
1 Reckless Handling
1 Redirect Lightning
1 Reforge the Soul
1 Restoration Seminar
1 Rise of the Eldrazi
1 Ruby Medallion
1 Rugged Prairie
1 Sacred Foundry
1 Scroll Rack
1 Sensei''s Divining Top
1 Smothering Tithe
1 Sol Ring
1 Spectator Seating
1 Storm Herd
1 Storm-Kiln Artist
1 Sun Titan
1 Sunbillow Verge
1 Sundown Pass
1 Talisman of Conviction
1 Taunt from the Rampart
1 Teferi''s Protection
1 Temple of Triumph
1 Turbulent Steppe
1 Twinflame
1 Twinflame Tyrant
1 Unexpected Windfall
1 Urza''s Saga
1 Valakut Awakening // Valakut Stoneforge
1 Velomachus Lorehold
1 Verge Rangers
1 Victory Chimes
1 Volcanic Vision
1 Wheel of Fate
1 Wooded Foothills',
  100,
  NULL,
  'Mizzix''s Mastery',
  'Rise of the Eldrazi / Storm Herd / Crackle with Power',
  'registered_pending_card_rule_validation',
  'Manual user-pasted Lorehold big-spells deck registered for downstream card validation; not promoted active.',
  '{"deck_hash": "a073b0fdc0db03c432651caa8f41d275faa6d67e5efb3865daee7ff4ca543298", "hermes_deck_id": 611, "notes": "Registered from user-pasted Lorehold big-spells list. Not promoted as active learned deck.", "oracle_missing_after_registration": 0, "pg_deck_id": "0936dae3-32c4-5fb8-9c6f-d986670de794", "registration_scope": "deck_intake_for_card_validation", "source_decklist": "docs/hermes-analysis/manaloom-knowledge/decks/lorehold-the-historian/2026-06-24-variant-06-user-decklist.md", "staging_report": "docs/hermes-analysis/master_optimizer_reports/lorehold_variant_staging_20260624_122012.json", "staging_warning_count": 14, "validation_status": "registered_pending_card_rule_validation"}'::jsonb,
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
