\pset pager off
BEGIN;
-- PG register apply for Lorehold Variant 10.
-- Scope: insert/update one decks row, replace its deck_cards rows, upsert one inactive commander_learned_decks row.
DROP TABLE IF EXISTS tmp_lorehold_variant10_input;
CREATE TEMP TABLE tmp_lorehold_variant10_input(ord int, card_name text, quantity int, is_commander boolean);
INSERT INTO tmp_lorehold_variant10_input(ord, card_name, quantity, is_commander) VALUES
  (1, 'Lorehold, the Historian'::text, 1::int, true::boolean),
  (2, 'Ancient Tomb'::text, 1::int, false::boolean),
  (3, 'Apex of Power'::text, 1::int, false::boolean),
  (4, 'Approach of the Second Sun'::text, 1::int, false::boolean),
  (5, 'Arcane Signet'::text, 1::int, false::boolean),
  (6, 'Arid Mesa'::text, 1::int, false::boolean),
  (7, 'Beacon of Immortality'::text, 1::int, false::boolean),
  (8, 'Big Score'::text, 1::int, false::boolean),
  (9, 'Birgi, God of Storytelling // Harnfel, Horn of Bounty'::text, 1::int, false::boolean),
  (10, 'Boros Charm'::text, 1::int, false::boolean),
  (11, 'Boseiju, Who Shelters All'::text, 1::int, false::boolean),
  (12, 'Brass''s Bounty'::text, 1::int, false::boolean),
  (13, 'Call Forth the Tempest'::text, 1::int, false::boolean),
  (14, 'Cavern of Souls'::text, 1::int, false::boolean),
  (15, 'Chaos Warp'::text, 1::int, false::boolean),
  (16, 'Clifftop Retreat'::text, 1::int, false::boolean),
  (17, 'Command Beacon'::text, 1::int, false::boolean),
  (18, 'Command Tower'::text, 1::int, false::boolean),
  (19, 'Deflecting Palm'::text, 1::int, false::boolean),
  (20, 'Deflecting Swat'::text, 1::int, false::boolean),
  (21, 'Double Vision'::text, 1::int, false::boolean),
  (22, 'Enlightened Tutor'::text, 1::int, false::boolean),
  (23, 'Erode'::text, 1::int, false::boolean),
  (24, 'Esper Sentinel'::text, 1::int, false::boolean),
  (25, 'Faithless Looting'::text, 1::int, false::boolean),
  (26, 'Farewell'::text, 1::int, false::boolean),
  (27, 'Flare of Duplication'::text, 1::int, false::boolean),
  (28, 'Flashback'::text, 1::int, false::boolean),
  (29, 'Galvanoth'::text, 1::int, false::boolean),
  (30, 'Gamble'::text, 1::int, false::boolean),
  (31, 'Goldspan Dragon'::text, 1::int, false::boolean),
  (32, 'Goliath Daydreamer'::text, 1::int, false::boolean),
  (33, 'Grand Abolisher'::text, 1::int, false::boolean),
  (34, 'Guttersnipe'::text, 1::int, false::boolean),
  (35, 'Heroes Remembered'::text, 1::int, false::boolean),
  (36, 'Hexing Squelcher'::text, 1::int, false::boolean),
  (37, 'Insurrection'::text, 1::int, false::boolean),
  (38, 'Invoke Calamity'::text, 1::int, false::boolean),
  (39, 'Jeska''s Will'::text, 1::int, false::boolean),
  (40, 'Land Tax'::text, 1::int, false::boolean),
  (41, 'Library of Leng'::text, 1::int, false::boolean),
  (42, 'Lightning Bolt'::text, 1::int, false::boolean),
  (43, 'Lightning Greaves'::text, 1::int, false::boolean),
  (44, 'Longshot, Rebel Bowman'::text, 1::int, false::boolean),
  (45, 'Mana Vault'::text, 1::int, false::boolean),
  (46, 'Mithril Coat'::text, 1::int, false::boolean),
  (47, 'Mizzix''s Mastery'::text, 1::int, false::boolean),
  (48, 'Monument to Endurance'::text, 1::int, false::boolean),
  (49, 'Mountain // Mountain'::text, 10::int, false::boolean),
  (50, 'Myriad Landscape'::text, 1::int, false::boolean),
  (51, 'Olórin''s Searing Light'::text, 1::int, false::boolean),
  (52, 'Perch Protection'::text, 1::int, false::boolean),
  (53, 'Plains // Plains'::text, 8::int, false::boolean),
  (54, 'Plateau'::text, 1::int, false::boolean),
  (55, 'Primal Amulet // Primal Wellspring'::text, 1::int, false::boolean),
  (56, 'Radiant Summit'::text, 1::int, false::boolean),
  (57, 'Red Elemental Blast'::text, 1::int, false::boolean),
  (58, 'Reforge the Soul'::text, 1::int, false::boolean),
  (59, 'Reiterate'::text, 1::int, false::boolean),
  (60, 'Reliquary Tower'::text, 1::int, false::boolean),
  (61, 'Reprieve'::text, 1::int, false::boolean),
  (62, 'Rise of the Eldrazi'::text, 1::int, false::boolean),
  (63, 'Rite of the Dragoncaller'::text, 1::int, false::boolean),
  (64, 'Sacred Foundry'::text, 1::int, false::boolean),
  (65, 'Seething Song'::text, 1::int, false::boolean),
  (66, 'Sensei''s Divining Top'::text, 1::int, false::boolean),
  (67, 'Silence'::text, 1::int, false::boolean),
  (68, 'Single Combat'::text, 1::int, false::boolean),
  (69, 'Smothering Tithe'::text, 1::int, false::boolean),
  (70, 'Sol Ring'::text, 1::int, false::boolean),
  (71, 'Spectator Seating'::text, 1::int, false::boolean),
  (72, 'Starfall Invocation'::text, 1::int, false::boolean),
  (73, 'Sunbillow Verge'::text, 1::int, false::boolean),
  (74, 'Sundown Pass'::text, 1::int, false::boolean),
  (75, 'Swords to Plowshares'::text, 1::int, false::boolean),
  (76, 'Taunt from the Rampart'::text, 1::int, false::boolean),
  (77, 'Teferi''s Protection'::text, 1::int, false::boolean),
  (78, 'The One Ring'::text, 1::int, false::boolean),
  (79, 'Twinflame Tyrant'::text, 1::int, false::boolean),
  (80, 'Underworld Breach'::text, 1::int, false::boolean),
  (81, 'Unexpected Windfall'::text, 1::int, false::boolean),
  (82, 'Urza''s Saga'::text, 1::int, false::boolean),
  (83, 'Vandalblast'::text, 1::int, false::boolean),
  (84, 'Velomachus Lorehold'::text, 1::int, false::boolean);

DROP TABLE IF EXISTS tmp_lorehold_variant10_picked;
CREATE TEMP TABLE tmp_lorehold_variant10_picked AS
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
  FROM tmp_lorehold_variant10_input i
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
  SELECT COUNT(*) INTO missing_count FROM tmp_lorehold_variant10_picked WHERE card_id IS NULL;
  IF missing_count <> 0 THEN
    RAISE EXCEPTION 'Refusing Lorehold Variant 10 PG registration: % cards missing from cards catalog', missing_count;
  END IF;
  SELECT COALESCE(SUM(quantity),0)::int INTO total_qty FROM tmp_lorehold_variant10_picked;
  SELECT COALESCE(SUM(CASE WHEN is_commander THEN quantity ELSE 0 END),0)::int INTO commander_qty FROM tmp_lorehold_variant10_picked;
  IF total_qty <> 100 THEN
    RAISE EXCEPTION 'Refusing Lorehold Variant 10 PG registration: expected qty 100, got %', total_qty;
  END IF;
  IF commander_qty <> 1 THEN
    RAISE EXCEPTION 'Refusing Lorehold Variant 10 PG registration: expected commander qty 1, got %', commander_qty;
  END IF;
END $$;

INSERT INTO decks (
  id, user_id, name, format, description, is_public, synergy_score,
  strengths, weaknesses, archetype, bracket
) VALUES (
  '43c026ae-2d92-5049-90fc-1fdad4b04298'::uuid,
  NULL,
  'PG REGISTERED Lorehold Variant 10 - Rafael Paste 2026-06-24',
  'commander',
  'Manual Lorehold deck registration for card validation. deck_hash=69fc2e8dfcb40e24137a92b8823677e26538768b21602671f46158f3c303a42c; source=docs/hermes-analysis/manaloom-knowledge/decks/lorehold-the-historian/2026-06-24-variant-10-user-decklist.md',
  false,
  0,
  'Pending validation: user-pasted Lorehold spell-copy big-spells deck registered for card logic review.',
  'Pending card-rule validation; not promoted as definitive deck.',
  'spell-copy-big-spells-variant',
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

DELETE FROM deck_cards WHERE deck_id = '43c026ae-2d92-5049-90fc-1fdad4b04298'::uuid;

INSERT INTO deck_cards (deck_id, card_id, quantity, is_commander, condition)
SELECT
  '43c026ae-2d92-5049-90fc-1fdad4b04298'::uuid,
  card_id,
  quantity,
  is_commander,
  'NM'
FROM tmp_lorehold_variant10_picked
ORDER BY ord;

INSERT INTO commander_learned_decks (
  id, commander_name, commander_name_normalized, deck_name,
  source_system, source_ref, source_url, archetype, card_list, card_count,
  score, wincon_primary, wincon_backup, legal_status, notes, metadata,
  is_active, promoted_at, updated_at
) VALUES (
  'a77eb26f-4cae-595c-bfd0-55be138a141b'::uuid,
  'Lorehold, the Historian',
  'lorehold, the historian',
  'Lorehold Variant 10 - Rafael Paste 2026-06-24',
  'manual_user_deck_registration',
  'lorehold_variant10_20260624_69fc2e8dfcb4',
  'docs/hermes-analysis/manaloom-knowledge/decks/lorehold-the-historian/2026-06-24-variant-10-user-decklist.md',
  'spell-copy-big-spells-variant',
  '1 Lorehold, the Historian
1 Ancient Tomb
1 Apex of Power
1 Approach of the Second Sun
1 Arcane Signet
1 Arid Mesa
1 Beacon of Immortality
1 Big Score
1 Birgi, God of Storytelling // Harnfel, Horn of Bounty
1 Boros Charm
1 Boseiju, Who Shelters All
1 Brass''s Bounty
1 Call Forth the Tempest
1 Cavern of Souls
1 Chaos Warp
1 Clifftop Retreat
1 Command Beacon
1 Command Tower
1 Deflecting Palm
1 Deflecting Swat
1 Double Vision
1 Enlightened Tutor
1 Erode
1 Esper Sentinel
1 Faithless Looting
1 Farewell
1 Flare of Duplication
1 Flashback
1 Galvanoth
1 Gamble
1 Goldspan Dragon
1 Goliath Daydreamer
1 Grand Abolisher
1 Guttersnipe
1 Heroes Remembered
1 Hexing Squelcher
1 Insurrection
1 Invoke Calamity
1 Jeska''s Will
1 Land Tax
1 Library of Leng
1 Lightning Bolt
1 Lightning Greaves
1 Longshot, Rebel Bowman
1 Mana Vault
1 Mithril Coat
1 Mizzix''s Mastery
1 Monument to Endurance
10 Mountain // Mountain
1 Myriad Landscape
1 Olórin''s Searing Light
1 Perch Protection
8 Plains // Plains
1 Plateau
1 Primal Amulet // Primal Wellspring
1 Radiant Summit
1 Red Elemental Blast
1 Reforge the Soul
1 Reiterate
1 Reliquary Tower
1 Reprieve
1 Rise of the Eldrazi
1 Rite of the Dragoncaller
1 Sacred Foundry
1 Seething Song
1 Sensei''s Divining Top
1 Silence
1 Single Combat
1 Smothering Tithe
1 Sol Ring
1 Spectator Seating
1 Starfall Invocation
1 Sunbillow Verge
1 Sundown Pass
1 Swords to Plowshares
1 Taunt from the Rampart
1 Teferi''s Protection
1 The One Ring
1 Twinflame Tyrant
1 Underworld Breach
1 Unexpected Windfall
1 Urza''s Saga
1 Vandalblast
1 Velomachus Lorehold',
  100,
  0,
  'pending_validation',
  'pending_validation',
  'registered_pending_card_rule_validation',
  'Manual user-pasted Lorehold spell-copy big-spells deck registered for downstream card validation; not promoted active.',
  '{"deck_hash": "69fc2e8dfcb40e24137a92b8823677e26538768b21602671f46158f3c303a42c", "hermes_deck_id": 615, "notes": "Registered from user-pasted Lorehold spell-copy big-spells list. Not promoted as active learned deck.", "oracle_missing_after_registration": 0, "pg_deck_id": "43c026ae-2d92-5049-90fc-1fdad4b04298", "registration_scope": "deck_intake_for_card_validation", "source_decklist": "docs/hermes-analysis/manaloom-knowledge/decks/lorehold-the-historian/2026-06-24-variant-10-user-decklist.md", "staging_report": "docs/hermes-analysis/master_optimizer_reports/lorehold_variant_staging_20260624_124206.json", "staging_warning_count": 14, "validation_status": "registered_pending_card_rule_validation"}'::jsonb,
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
