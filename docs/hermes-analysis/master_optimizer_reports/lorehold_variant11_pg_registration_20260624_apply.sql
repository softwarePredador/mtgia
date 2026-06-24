\pset pager off
BEGIN;
-- PG register apply for Lorehold Variant 11.
-- Scope: insert/update one decks row, replace its deck_cards rows, upsert one inactive commander_learned_decks row.
DROP TABLE IF EXISTS tmp_lorehold_variant11_input;
CREATE TEMP TABLE tmp_lorehold_variant11_input(ord int, card_name text, quantity int, is_commander boolean);
INSERT INTO tmp_lorehold_variant11_input(ord, card_name, quantity, is_commander) VALUES
  (1, 'Lorehold, the Historian'::text, 1::int, true::boolean),
  (2, 'Abrade'::text, 1::int, false::boolean),
  (3, 'Ancient Copper Dragon'::text, 1::int, false::boolean),
  (4, 'Apex of Power'::text, 1::int, false::boolean),
  (5, 'Arcane Signet'::text, 1::int, false::boolean),
  (6, 'Authority of the Consuls'::text, 1::int, false::boolean),
  (7, 'Balefire Liege'::text, 1::int, false::boolean),
  (8, 'Bedlam Reveler'::text, 1::int, false::boolean),
  (9, 'Blasphemous Act'::text, 1::int, false::boolean),
  (10, 'Blaze Commando'::text, 1::int, false::boolean),
  (11, 'Blood Moon'::text, 1::int, false::boolean),
  (12, 'Boltwave'::text, 1::int, false::boolean),
  (13, 'Boros Garrison'::text, 1::int, false::boolean),
  (14, 'Boros Reckoner'::text, 1::int, false::boolean),
  (15, 'Boseiju, Who Shelters All'::text, 1::int, false::boolean),
  (16, 'Chaos Wand'::text, 1::int, false::boolean),
  (17, 'Chaos Warp'::text, 1::int, false::boolean),
  (18, 'Clifftop Retreat'::text, 1::int, false::boolean),
  (19, 'Command Tower'::text, 1::int, false::boolean),
  (20, 'Coruscation Mage'::text, 1::int, false::boolean),
  (21, 'Dawn''s Truce'::text, 1::int, false::boolean),
  (22, 'Deathbellow War Cry'::text, 1::int, false::boolean),
  (23, 'Deflecting Palm'::text, 1::int, false::boolean),
  (24, 'Deflecting Swat'::text, 1::int, false::boolean),
  (25, 'Eight-and-a-Half-Tails'::text, 1::int, false::boolean),
  (26, 'Explosive Singularity'::text, 1::int, false::boolean),
  (27, 'Firesong and Sunspeaker'::text, 1::int, false::boolean),
  (28, 'Generous Gift'::text, 1::int, false::boolean),
  (29, 'Ghostly Prison'::text, 1::int, false::boolean),
  (30, 'Gods Willing'::text, 1::int, false::boolean),
  (31, 'Grand Abolisher'::text, 1::int, false::boolean),
  (32, 'Guttersnipe'::text, 1::int, false::boolean),
  (33, 'Hexing Squelcher'::text, 1::int, false::boolean),
  (34, 'Invoke Calamity'::text, 1::int, false::boolean),
  (35, 'Jeska''s Will'::text, 1::int, false::boolean),
  (36, 'Lightning Bolt'::text, 1::int, false::boolean),
  (37, 'Lightning Helix'::text, 1::int, false::boolean),
  (38, 'Lindblum, Industrial Regency // Mage Siege'::text, 1::int, false::boolean),
  (39, 'Magus of the Wheel'::text, 1::int, false::boolean),
  (40, 'Mizzix''s Mastery'::text, 1::int, false::boolean),
  (41, 'Monastery Mentor'::text, 1::int, false::boolean),
  (42, 'Mountain // Mountain'::text, 10::int, false::boolean),
  (43, 'Myriad Landscape'::text, 1::int, false::boolean),
  (44, 'Neheb, the Eternal'::text, 1::int, false::boolean),
  (45, 'Path to Exile'::text, 1::int, false::boolean),
  (46, 'Plains // Plains'::text, 8::int, false::boolean),
  (47, 'Plateau'::text, 1::int, false::boolean),
  (48, 'Possibility Storm'::text, 1::int, false::boolean),
  (49, 'Radiant Performer'::text, 1::int, false::boolean),
  (50, 'Reckless Endeavor'::text, 1::int, false::boolean),
  (51, 'Reforge the Soul'::text, 1::int, false::boolean),
  (52, 'Reliquary Tower'::text, 1::int, false::boolean),
  (53, 'Rise of the Eldrazi'::text, 1::int, false::boolean),
  (54, 'Rugged Prairie'::text, 1::int, false::boolean),
  (55, 'Rune-Tail, Kitsune Ascendant // Rune-Tail''s Essence'::text, 1::int, false::boolean),
  (56, 'Sacred Foundry'::text, 1::int, false::boolean),
  (57, 'Sawhorn Nemesis'::text, 1::int, false::boolean),
  (58, 'Screaming Nemesis'::text, 1::int, false::boolean),
  (59, 'Scroll Rack'::text, 1::int, false::boolean),
  (60, 'Semblance Anvil'::text, 1::int, false::boolean),
  (61, 'Sensei''s Divining Top'::text, 1::int, false::boolean),
  (62, 'Serra Ascendant'::text, 1::int, false::boolean),
  (63, 'Silence'::text, 1::int, false::boolean),
  (64, 'Slickshot Show-Off'::text, 1::int, false::boolean),
  (65, 'Smothering Tithe'::text, 1::int, false::boolean),
  (66, 'Sol Ring'::text, 1::int, false::boolean),
  (67, 'Soul Immolation'::text, 1::int, false::boolean),
  (68, 'Soulfire Eruption'::text, 1::int, false::boolean),
  (69, 'Star of Extinction'::text, 1::int, false::boolean),
  (70, 'Storm Herd'::text, 1::int, false::boolean),
  (71, 'Stroke of Midnight'::text, 1::int, false::boolean),
  (72, 'Stuffy Doll'::text, 1::int, false::boolean),
  (73, 'Swiftfoot Boots'::text, 1::int, false::boolean),
  (74, 'Teferi''s Protection'::text, 1::int, false::boolean),
  (75, 'Thawing Glaciers'::text, 1::int, false::boolean),
  (76, 'The Walls of Ba Sing Se'::text, 1::int, false::boolean),
  (77, 'Untimely Malfunction'::text, 1::int, false::boolean),
  (78, 'Utvara Hellkite'::text, 1::int, false::boolean),
  (79, 'Wear // Tear'::text, 1::int, false::boolean),
  (80, 'Wheel of Fate'::text, 1::int, false::boolean),
  (81, 'Wheel of Fortune'::text, 1::int, false::boolean),
  (82, 'Whispersilk Cloak'::text, 1::int, false::boolean),
  (83, 'Worldfire'::text, 1::int, false::boolean),
  (84, 'Young Pyromancer'::text, 1::int, false::boolean);

DROP TABLE IF EXISTS tmp_lorehold_variant11_picked;
CREATE TEMP TABLE tmp_lorehold_variant11_picked AS
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
  FROM tmp_lorehold_variant11_input i
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
  SELECT COUNT(*) INTO missing_count FROM tmp_lorehold_variant11_picked WHERE card_id IS NULL;
  IF missing_count <> 0 THEN
    RAISE EXCEPTION 'Refusing Lorehold Variant 11 PG registration: % cards missing from cards catalog', missing_count;
  END IF;
  SELECT COALESCE(SUM(quantity),0)::int INTO total_qty FROM tmp_lorehold_variant11_picked;
  SELECT COALESCE(SUM(CASE WHEN is_commander THEN quantity ELSE 0 END),0)::int INTO commander_qty FROM tmp_lorehold_variant11_picked;
  IF total_qty <> 100 THEN
    RAISE EXCEPTION 'Refusing Lorehold Variant 11 PG registration: expected qty 100, got %', total_qty;
  END IF;
  IF commander_qty <> 1 THEN
    RAISE EXCEPTION 'Refusing Lorehold Variant 11 PG registration: expected commander qty 1, got %', commander_qty;
  END IF;
END $$;

INSERT INTO decks (
  id, user_id, name, format, description, is_public, synergy_score,
  strengths, weaknesses, archetype, bracket
) VALUES (
  '9df6ac2e-6620-5265-8008-1f57c8963d66'::uuid,
  NULL,
  'PG REGISTERED Lorehold Variant 11 - Rafael Paste 2026-06-24',
  'commander',
  'Manual Lorehold deck registration for card validation. deck_hash=4f48eee5a34dcf561e4d45f88ced34b9052ccb4f13697d69ce69f06aa2dbb99b; source=docs/hermes-analysis/manaloom-knowledge/decks/lorehold-the-historian/2026-06-24-variant-11-user-decklist.md',
  false,
  0,
  'Pending validation: user-pasted Lorehold burn dragon control deck registered for card logic review.',
  'Pending card-rule validation; not promoted as definitive deck.',
  'burn-dragon-control-variant',
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

DELETE FROM deck_cards WHERE deck_id = '9df6ac2e-6620-5265-8008-1f57c8963d66'::uuid;

INSERT INTO deck_cards (deck_id, card_id, quantity, is_commander, condition)
SELECT
  '9df6ac2e-6620-5265-8008-1f57c8963d66'::uuid,
  card_id,
  quantity,
  is_commander,
  'NM'
FROM tmp_lorehold_variant11_picked
ORDER BY ord;

INSERT INTO commander_learned_decks (
  id, commander_name, commander_name_normalized, deck_name,
  source_system, source_ref, source_url, archetype, card_list, card_count,
  score, wincon_primary, wincon_backup, legal_status, notes, metadata,
  is_active, promoted_at, updated_at
) VALUES (
  '5f0082b0-00bb-5b6d-9518-839401e4225e'::uuid,
  'Lorehold, the Historian',
  'lorehold, the historian',
  'Lorehold Variant 11 - Rafael Paste 2026-06-24',
  'manual_user_deck_registration',
  'lorehold_variant11_20260624_4f48eee5a34d',
  'docs/hermes-analysis/manaloom-knowledge/decks/lorehold-the-historian/2026-06-24-variant-11-user-decklist.md',
  'burn-dragon-control-variant',
  '1 Lorehold, the Historian
1 Abrade
1 Ancient Copper Dragon
1 Apex of Power
1 Arcane Signet
1 Authority of the Consuls
1 Balefire Liege
1 Bedlam Reveler
1 Blasphemous Act
1 Blaze Commando
1 Blood Moon
1 Boltwave
1 Boros Garrison
1 Boros Reckoner
1 Boseiju, Who Shelters All
1 Chaos Wand
1 Chaos Warp
1 Clifftop Retreat
1 Command Tower
1 Coruscation Mage
1 Dawn''s Truce
1 Deathbellow War Cry
1 Deflecting Palm
1 Deflecting Swat
1 Eight-and-a-Half-Tails
1 Explosive Singularity
1 Firesong and Sunspeaker
1 Generous Gift
1 Ghostly Prison
1 Gods Willing
1 Grand Abolisher
1 Guttersnipe
1 Hexing Squelcher
1 Invoke Calamity
1 Jeska''s Will
1 Lightning Bolt
1 Lightning Helix
1 Lindblum, Industrial Regency // Mage Siege
1 Magus of the Wheel
1 Mizzix''s Mastery
1 Monastery Mentor
10 Mountain // Mountain
1 Myriad Landscape
1 Neheb, the Eternal
1 Path to Exile
8 Plains // Plains
1 Plateau
1 Possibility Storm
1 Radiant Performer
1 Reckless Endeavor
1 Reforge the Soul
1 Reliquary Tower
1 Rise of the Eldrazi
1 Rugged Prairie
1 Rune-Tail, Kitsune Ascendant // Rune-Tail''s Essence
1 Sacred Foundry
1 Sawhorn Nemesis
1 Screaming Nemesis
1 Scroll Rack
1 Semblance Anvil
1 Sensei''s Divining Top
1 Serra Ascendant
1 Silence
1 Slickshot Show-Off
1 Smothering Tithe
1 Sol Ring
1 Soul Immolation
1 Soulfire Eruption
1 Star of Extinction
1 Storm Herd
1 Stroke of Midnight
1 Stuffy Doll
1 Swiftfoot Boots
1 Teferi''s Protection
1 Thawing Glaciers
1 The Walls of Ba Sing Se
1 Untimely Malfunction
1 Utvara Hellkite
1 Wear // Tear
1 Wheel of Fate
1 Wheel of Fortune
1 Whispersilk Cloak
1 Worldfire
1 Young Pyromancer',
  100,
  0,
  'pending_validation',
  'pending_validation',
  'registered_pending_card_rule_validation',
  'Manual user-pasted Lorehold burn dragon control deck registered for downstream card validation; not promoted active.',
  '{"deck_hash": "4f48eee5a34dcf561e4d45f88ced34b9052ccb4f13697d69ce69f06aa2dbb99b", "hermes_deck_id": 616, "notes": "Registered from user-pasted Lorehold burn dragon control list. Not promoted as active learned deck.", "oracle_missing_after_registration": 0, "pg_deck_id": "9df6ac2e-6620-5265-8008-1f57c8963d66", "registration_scope": "deck_intake_for_card_validation", "source_decklist": "docs/hermes-analysis/manaloom-knowledge/decks/lorehold-the-historian/2026-06-24-variant-11-user-decklist.md", "staging_report": "docs/hermes-analysis/master_optimizer_reports/lorehold_variant_staging_20260624_124701.json", "staging_warning_count": 36, "validation_status": "registered_pending_card_rule_validation"}'::jsonb,
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
