\pset pager off
BEGIN;
-- PG register apply for Lorehold Variant 08.
-- Scope: insert/update one decks row, replace its deck_cards rows, upsert one inactive commander_learned_decks row.
DROP TABLE IF EXISTS tmp_lorehold_variant08_input;
CREATE TEMP TABLE tmp_lorehold_variant08_input(ord int, card_name text, quantity int, is_commander boolean);
INSERT INTO tmp_lorehold_variant08_input(ord, card_name, quantity, is_commander) VALUES
  (1, 'Lorehold, the Historian'::text, 1::int, true::boolean),
  (2, 'Ancient Tomb'::text, 1::int, false::boolean),
  (3, 'Apex of Power'::text, 1::int, false::boolean),
  (4, 'Approach of the Second Sun'::text, 1::int, false::boolean),
  (5, 'Arcane Signet'::text, 1::int, false::boolean),
  (6, 'Armageddon'::text, 1::int, false::boolean),
  (7, 'Bender''s Waterskin'::text, 1::int, false::boolean),
  (8, 'Big Score'::text, 1::int, false::boolean),
  (9, 'Bloodstained Mire'::text, 1::int, false::boolean),
  (10, 'Boros Charm'::text, 1::int, false::boolean),
  (11, 'Boseiju, Who Shelters All'::text, 1::int, false::boolean),
  (12, 'Brass''s Bounty'::text, 1::int, false::boolean),
  (13, 'Call Forth the Tempest'::text, 1::int, false::boolean),
  (14, 'Chandra''s Ignition'::text, 1::int, false::boolean),
  (15, 'Chrome Mox'::text, 1::int, false::boolean),
  (16, 'City of Brass'::text, 1::int, false::boolean),
  (17, 'Command Tower'::text, 1::int, false::boolean),
  (18, 'Cool but Rude'::text, 1::int, false::boolean),
  (19, 'Dance with Calamity'::text, 1::int, false::boolean),
  (20, 'Dawn''s Truce'::text, 1::int, false::boolean),
  (21, 'Deflecting Swat'::text, 1::int, false::boolean),
  (22, 'Double Vision'::text, 1::int, false::boolean),
  (23, 'Dragon''s Rage Channeler'::text, 1::int, false::boolean),
  (24, 'Dualcaster Mage'::text, 1::int, false::boolean),
  (25, 'Elegant Parlor'::text, 1::int, false::boolean),
  (26, 'Enlightened Tutor'::text, 1::int, false::boolean),
  (27, 'Esper Sentinel'::text, 1::int, false::boolean),
  (28, 'Farewell'::text, 1::int, false::boolean),
  (29, 'Galvanoth'::text, 1::int, false::boolean),
  (30, 'Gamble'::text, 1::int, false::boolean),
  (31, 'Gemstone Caverns'::text, 1::int, false::boolean),
  (32, 'Ghostly Prison'::text, 1::int, false::boolean),
  (33, 'Glint-Horn Buccaneer'::text, 1::int, false::boolean),
  (34, 'Goliath Daydreamer'::text, 1::int, false::boolean),
  (35, 'Grand Abolisher'::text, 1::int, false::boolean),
  (36, 'Hexing Squelcher'::text, 1::int, false::boolean),
  (37, 'Hit the Mother Lode'::text, 1::int, false::boolean),
  (38, 'Improvisation Capstone'::text, 1::int, false::boolean),
  (39, 'Jeska''s Will'::text, 1::int, false::boolean),
  (40, 'Land Tax'::text, 1::int, false::boolean),
  (41, 'Library of Leng'::text, 1::int, false::boolean),
  (42, 'Longshot, Rebel Bowman'::text, 1::int, false::boolean),
  (43, 'Lotus Petal'::text, 1::int, false::boolean),
  (44, 'Mana Vault'::text, 1::int, false::boolean),
  (45, 'Marsh Flats'::text, 1::int, false::boolean),
  (46, 'Mizzix''s Mastery'::text, 1::int, false::boolean),
  (47, 'Monument to Endurance'::text, 1::int, false::boolean),
  (48, 'Mountain // Mountain'::text, 6::int, false::boolean),
  (49, 'Olórin''s Searing Light'::text, 1::int, false::boolean),
  (50, 'Path to Exile'::text, 1::int, false::boolean),
  (51, 'Penance'::text, 1::int, false::boolean),
  (52, 'Perch Protection'::text, 1::int, false::boolean),
  (53, 'Plains // Plains'::text, 5::int, false::boolean),
  (54, 'Planetarium of Wan Shi Tong'::text, 1::int, false::boolean),
  (55, 'Plateau'::text, 1::int, false::boolean),
  (56, 'Red Elemental Blast'::text, 1::int, false::boolean),
  (57, 'Redirect Lightning'::text, 1::int, false::boolean),
  (58, 'Reforge the Soul'::text, 1::int, false::boolean),
  (59, 'Reliquary Tower'::text, 1::int, false::boolean),
  (60, 'Reprieve'::text, 1::int, false::boolean),
  (61, 'Reverberate'::text, 1::int, false::boolean),
  (62, 'Rise of the Eldrazi'::text, 1::int, false::boolean),
  (63, 'Sacred Foundry'::text, 1::int, false::boolean),
  (64, 'Scroll Rack'::text, 1::int, false::boolean),
  (65, 'Sensei''s Divining Top'::text, 1::int, false::boolean),
  (66, 'Shinka, the Bloodsoaked Keep'::text, 1::int, false::boolean),
  (67, 'Silence'::text, 1::int, false::boolean),
  (68, 'Smothering Tithe'::text, 1::int, false::boolean),
  (69, 'Sol Ring'::text, 1::int, false::boolean),
  (70, 'Soulfire Eruption'::text, 1::int, false::boolean),
  (71, 'Spectator Seating'::text, 1::int, false::boolean),
  (72, 'Starting Town'::text, 1::int, false::boolean),
  (73, 'Storm Herd'::text, 1::int, false::boolean),
  (74, 'Storm-Kiln Artist'::text, 1::int, false::boolean),
  (75, 'Sunbillow Verge'::text, 1::int, false::boolean),
  (76, 'Sundown Pass'::text, 1::int, false::boolean),
  (77, 'Teferi''s Protection'::text, 1::int, false::boolean),
  (78, 'Temple of Triumph'::text, 1::int, false::boolean),
  (79, 'Tezzeret, Cruel Captain'::text, 1::int, false::boolean),
  (80, 'The Biblioplex'::text, 1::int, false::boolean),
  (81, 'The One Ring'::text, 1::int, false::boolean),
  (82, 'Twinflame'::text, 1::int, false::boolean),
  (83, 'Unexpected Windfall'::text, 1::int, false::boolean),
  (84, 'Unwinding Clock'::text, 1::int, false::boolean),
  (85, 'Urza''s Saga'::text, 1::int, false::boolean),
  (86, 'Vedalken Orrery'::text, 1::int, false::boolean),
  (87, 'Verge Rangers'::text, 1::int, false::boolean),
  (88, 'Victory Chimes'::text, 1::int, false::boolean),
  (89, 'Volcanic Vision'::text, 1::int, false::boolean),
  (90, 'Windswept Heath'::text, 1::int, false::boolean),
  (91, 'Zhalfirin Void'::text, 1::int, false::boolean);

DROP TABLE IF EXISTS tmp_lorehold_variant08_picked;
CREATE TEMP TABLE tmp_lorehold_variant08_picked AS
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
  FROM tmp_lorehold_variant08_input i
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
  SELECT COUNT(*) INTO missing_count FROM tmp_lorehold_variant08_picked WHERE card_id IS NULL;
  IF missing_count <> 0 THEN
    RAISE EXCEPTION 'Refusing Lorehold Variant 08 PG registration: % cards missing from cards catalog', missing_count;
  END IF;
  SELECT COALESCE(SUM(quantity),0)::int INTO total_qty FROM tmp_lorehold_variant08_picked;
  SELECT COALESCE(SUM(CASE WHEN is_commander THEN quantity ELSE 0 END),0)::int INTO commander_qty FROM tmp_lorehold_variant08_picked;
  IF total_qty <> 100 THEN
    RAISE EXCEPTION 'Refusing Lorehold Variant 08 PG registration: expected qty 100, got %', total_qty;
  END IF;
  IF commander_qty <> 1 THEN
    RAISE EXCEPTION 'Refusing Lorehold Variant 08 PG registration: expected commander qty 1, got %', commander_qty;
  END IF;
END $$;

INSERT INTO decks (
  id, user_id, name, format, description, is_public, synergy_score,
  strengths, weaknesses, archetype, bracket
) VALUES (
  '6df74eb3-c4a7-5398-bcf5-febb38d80d7a'::uuid,
  NULL,
  'PG REGISTERED Lorehold Variant 08 - Rafael Paste 2026-06-24',
  'commander',
  'Manual Lorehold deck registration for card validation. deck_hash=1a76c69c236f182671a7d2069ecb48d9003261d1dd23ac144ae55c2c0a904367; source=docs/hermes-analysis/manaloom-knowledge/decks/lorehold-the-historian/2026-06-24-variant-08-user-decklist.md',
  false,
  0,
  'Pending validation: user-pasted Lorehold spell-copy control deck registered for card logic review.',
  'Pending card-rule validation; not promoted as definitive deck.',
  'spell-copy-control-variant',
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

DELETE FROM deck_cards WHERE deck_id = '6df74eb3-c4a7-5398-bcf5-febb38d80d7a'::uuid;

INSERT INTO deck_cards (deck_id, card_id, quantity, is_commander, condition)
SELECT
  '6df74eb3-c4a7-5398-bcf5-febb38d80d7a'::uuid,
  card_id,
  quantity,
  is_commander,
  'NM'
FROM tmp_lorehold_variant08_picked
ORDER BY ord;

INSERT INTO commander_learned_decks (
  id, commander_name, commander_name_normalized, deck_name,
  source_system, source_ref, source_url, archetype, card_list, card_count,
  score, wincon_primary, wincon_backup, legal_status, notes, metadata,
  is_active, promoted_at, updated_at
) VALUES (
  'fe7dc94a-b360-5108-a004-ee75bb11e76c'::uuid,
  'Lorehold, the Historian',
  'lorehold, the historian',
  'Lorehold Variant 08 - Rafael Paste 2026-06-24',
  'manual_user_deck_registration',
  'lorehold_variant08_20260624_1a76c69c236f',
  'docs/hermes-analysis/manaloom-knowledge/decks/lorehold-the-historian/2026-06-24-variant-08-user-decklist.md',
  'spell-copy-control-variant',
  '1 Lorehold, the Historian
1 Ancient Tomb
1 Apex of Power
1 Approach of the Second Sun
1 Arcane Signet
1 Armageddon
1 Bender''s Waterskin
1 Big Score
1 Bloodstained Mire
1 Boros Charm
1 Boseiju, Who Shelters All
1 Brass''s Bounty
1 Call Forth the Tempest
1 Chandra''s Ignition
1 Chrome Mox
1 City of Brass
1 Command Tower
1 Cool but Rude
1 Dance with Calamity
1 Dawn''s Truce
1 Deflecting Swat
1 Double Vision
1 Dragon''s Rage Channeler
1 Dualcaster Mage
1 Elegant Parlor
1 Enlightened Tutor
1 Esper Sentinel
1 Farewell
1 Galvanoth
1 Gamble
1 Gemstone Caverns
1 Ghostly Prison
1 Glint-Horn Buccaneer
1 Goliath Daydreamer
1 Grand Abolisher
1 Hexing Squelcher
1 Hit the Mother Lode
1 Improvisation Capstone
1 Jeska''s Will
1 Land Tax
1 Library of Leng
1 Longshot, Rebel Bowman
1 Lotus Petal
1 Mana Vault
1 Marsh Flats
1 Mizzix''s Mastery
1 Monument to Endurance
6 Mountain // Mountain
1 Olórin''s Searing Light
1 Path to Exile
1 Penance
1 Perch Protection
5 Plains // Plains
1 Planetarium of Wan Shi Tong
1 Plateau
1 Red Elemental Blast
1 Redirect Lightning
1 Reforge the Soul
1 Reliquary Tower
1 Reprieve
1 Reverberate
1 Rise of the Eldrazi
1 Sacred Foundry
1 Scroll Rack
1 Sensei''s Divining Top
1 Shinka, the Bloodsoaked Keep
1 Silence
1 Smothering Tithe
1 Sol Ring
1 Soulfire Eruption
1 Spectator Seating
1 Starting Town
1 Storm Herd
1 Storm-Kiln Artist
1 Sunbillow Verge
1 Sundown Pass
1 Teferi''s Protection
1 Temple of Triumph
1 Tezzeret, Cruel Captain
1 The Biblioplex
1 The One Ring
1 Twinflame
1 Unexpected Windfall
1 Unwinding Clock
1 Urza''s Saga
1 Vedalken Orrery
1 Verge Rangers
1 Victory Chimes
1 Volcanic Vision
1 Windswept Heath
1 Zhalfirin Void',
  100,
  0,
  'pending_validation',
  'pending_validation',
  'registered_pending_card_rule_validation',
  'Manual user-pasted Lorehold spell-copy control deck registered for downstream card validation; not promoted active.',
  '{"deck_hash": "1a76c69c236f182671a7d2069ecb48d9003261d1dd23ac144ae55c2c0a904367", "hermes_deck_id": 613, "notes": "Registered from user-pasted Lorehold spell-copy control list. Not promoted as active learned deck.", "oracle_missing_after_registration": 0, "pg_deck_id": "6df74eb3-c4a7-5398-bcf5-febb38d80d7a", "registration_scope": "deck_intake_for_card_validation", "source_decklist": "docs/hermes-analysis/manaloom-knowledge/decks/lorehold-the-historian/2026-06-24-variant-08-user-decklist.md", "staging_report": "docs/hermes-analysis/master_optimizer_reports/lorehold_variant_staging_20260624_123450.json", "staging_warning_count": 11, "validation_status": "registered_pending_card_rule_validation"}'::jsonb,
  false,
  NULL,
  now()
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
  updated_at = now();

COMMIT;
