\pset pager off
BEGIN;
-- PG register apply for Lorehold Variant 09.
-- Scope: insert/update one decks row, replace its deck_cards rows, upsert one inactive commander_learned_decks row.
DROP TABLE IF EXISTS tmp_lorehold_variant09_input;
CREATE TEMP TABLE tmp_lorehold_variant09_input(ord int, card_name text, quantity int, is_commander boolean);
INSERT INTO tmp_lorehold_variant09_input(ord, card_name, quantity, is_commander) VALUES
  (1, 'Lorehold, the Historian'::text, 1::int, true::boolean),
  (2, 'Aetherflux Reservoir'::text, 1::int, false::boolean),
  (3, 'Akroma''s Will'::text, 1::int, false::boolean),
  (4, 'Ancient Den'::text, 1::int, false::boolean),
  (5, 'Ancient Tomb'::text, 1::int, false::boolean),
  (6, 'Approach of the Second Sun'::text, 1::int, false::boolean),
  (7, 'Arcane Signet'::text, 1::int, false::boolean),
  (8, 'Arid Mesa'::text, 1::int, false::boolean),
  (9, 'Authority of the Consuls'::text, 1::int, false::boolean),
  (10, 'Bender''s Waterskin'::text, 1::int, false::boolean),
  (11, 'Big Score'::text, 1::int, false::boolean),
  (12, 'Blasphemous Act'::text, 1::int, false::boolean),
  (13, 'Bloodstained Mire'::text, 1::int, false::boolean),
  (14, 'Bolt Bend'::text, 1::int, false::boolean),
  (15, 'Boros Charm'::text, 1::int, false::boolean),
  (16, 'Brass''s Bounty'::text, 1::int, false::boolean),
  (17, 'Caldera Pyremaw'::text, 1::int, false::boolean),
  (18, 'Call Forth the Tempest'::text, 1::int, false::boolean),
  (19, 'Cavern of Souls'::text, 1::int, false::boolean),
  (20, 'Chrome Mox'::text, 1::int, false::boolean),
  (21, 'Clifftop Retreat'::text, 1::int, false::boolean),
  (22, 'Command Tower'::text, 1::int, false::boolean),
  (23, 'Conduit Pylons'::text, 1::int, false::boolean),
  (24, 'Creative Technique'::text, 1::int, false::boolean),
  (25, 'Currency Converter'::text, 1::int, false::boolean),
  (26, 'Dance with Calamity'::text, 1::int, false::boolean),
  (27, 'Deflecting Palm'::text, 1::int, false::boolean),
  (28, 'Deflecting Swat'::text, 1::int, false::boolean),
  (29, 'Desperate Ritual'::text, 1::int, false::boolean),
  (30, 'Dragon''s Rage Channeler'::text, 1::int, false::boolean),
  (31, 'Elegant Parlor'::text, 1::int, false::boolean),
  (32, 'Enlightened Tutor'::text, 1::int, false::boolean),
  (33, 'Esper Sentinel'::text, 1::int, false::boolean),
  (34, 'Fated Clash'::text, 1::int, false::boolean),
  (35, 'Flawless Maneuver'::text, 1::int, false::boolean),
  (36, 'Flooded Strand'::text, 1::int, false::boolean),
  (37, 'Galvanoth'::text, 1::int, false::boolean),
  (38, 'Gamble'::text, 1::int, false::boolean),
  (39, 'Generous Gift'::text, 1::int, false::boolean),
  (40, 'Goldspan Dragon'::text, 1::int, false::boolean),
  (41, 'Goliath Daydreamer'::text, 1::int, false::boolean),
  (42, 'Great Furnace'::text, 1::int, false::boolean),
  (43, 'Helm of Awakening'::text, 1::int, false::boolean),
  (44, 'Heroes Remembered'::text, 1::int, false::boolean),
  (45, 'Hexing Squelcher'::text, 1::int, false::boolean),
  (46, 'Insurrection'::text, 1::int, false::boolean),
  (47, 'Invincible Hymn'::text, 1::int, false::boolean),
  (48, 'Invoke Calamity'::text, 1::int, false::boolean),
  (49, 'Invoke Justice'::text, 1::int, false::boolean),
  (50, 'Jeska''s Will'::text, 1::int, false::boolean),
  (51, 'Land Tax'::text, 1::int, false::boolean),
  (52, 'Library of Leng'::text, 1::int, false::boolean),
  (53, 'Mana Geyser'::text, 1::int, false::boolean),
  (54, 'Marsh Flats'::text, 1::int, false::boolean),
  (55, 'Monument to Endurance'::text, 1::int, false::boolean),
  (56, 'Mother of Runes'::text, 1::int, false::boolean),
  (57, 'Mountain // Mountain'::text, 3::int, false::boolean),
  (58, 'Olórin''s Searing Light'::text, 1::int, false::boolean),
  (59, 'Pearl Medallion'::text, 1::int, false::boolean),
  (60, 'Penance'::text, 1::int, false::boolean),
  (61, 'Perch Protection'::text, 1::int, false::boolean),
  (62, 'Plains // Plains'::text, 8::int, false::boolean),
  (63, 'Plateau'::text, 1::int, false::boolean),
  (64, 'Prismatic Vista'::text, 1::int, false::boolean),
  (65, 'Pyretic Ritual'::text, 1::int, false::boolean),
  (66, 'Radiant Scrollwielder'::text, 1::int, false::boolean),
  (67, 'Reckless Handling'::text, 1::int, false::boolean),
  (68, 'Rise of the Eldrazi'::text, 1::int, false::boolean),
  (69, 'Ruby Medallion'::text, 1::int, false::boolean),
  (70, 'Sacred Foundry'::text, 1::int, false::boolean),
  (71, 'Scalding Tarn'::text, 1::int, false::boolean),
  (72, 'Scroll Rack'::text, 1::int, false::boolean),
  (73, 'Seething Song'::text, 1::int, false::boolean),
  (74, 'Sensei''s Divining Top'::text, 1::int, false::boolean),
  (75, 'Silence'::text, 1::int, false::boolean),
  (76, 'Smothering Tithe'::text, 1::int, false::boolean),
  (77, 'Sol Ring'::text, 1::int, false::boolean),
  (78, 'Soulfire Eruption'::text, 1::int, false::boolean),
  (79, 'Spectator Seating'::text, 1::int, false::boolean),
  (80, 'Storm Herd'::text, 1::int, false::boolean),
  (81, 'Storm-Kiln Artist'::text, 1::int, false::boolean),
  (82, 'Sunbaked Canyon'::text, 1::int, false::boolean),
  (83, 'Sunbillow Verge'::text, 1::int, false::boolean),
  (84, 'Teferi''s Protection'::text, 1::int, false::boolean),
  (85, 'Treasonous Ogre'::text, 1::int, false::boolean),
  (86, 'Trouble in Pairs'::text, 1::int, false::boolean),
  (87, 'Ultima'::text, 1::int, false::boolean),
  (88, 'Urza''s Saga'::text, 1::int, false::boolean),
  (89, 'Volcanic Vision'::text, 1::int, false::boolean),
  (90, 'Windswept Heath'::text, 1::int, false::boolean),
  (91, 'Wooded Foothills'::text, 1::int, false::boolean);

DROP TABLE IF EXISTS tmp_lorehold_variant09_picked;
CREATE TEMP TABLE tmp_lorehold_variant09_picked AS
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
  FROM tmp_lorehold_variant09_input i
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
  SELECT COUNT(*) INTO missing_count FROM tmp_lorehold_variant09_picked WHERE card_id IS NULL;
  IF missing_count <> 0 THEN
    RAISE EXCEPTION 'Refusing Lorehold Variant 09 PG registration: % cards missing from cards catalog', missing_count;
  END IF;
  SELECT COALESCE(SUM(quantity),0)::int INTO total_qty FROM tmp_lorehold_variant09_picked;
  SELECT COALESCE(SUM(CASE WHEN is_commander THEN quantity ELSE 0 END),0)::int INTO commander_qty FROM tmp_lorehold_variant09_picked;
  IF total_qty <> 100 THEN
    RAISE EXCEPTION 'Refusing Lorehold Variant 09 PG registration: expected qty 100, got %', total_qty;
  END IF;
  IF commander_qty <> 1 THEN
    RAISE EXCEPTION 'Refusing Lorehold Variant 09 PG registration: expected commander qty 1, got %', commander_qty;
  END IF;
END $$;

INSERT INTO decks (
  id, user_id, name, format, description, is_public, synergy_score,
  strengths, weaknesses, archetype, bracket
) VALUES (
  'b51c8f24-fa8b-50ee-8200-d78fe9908ffa'::uuid,
  NULL,
  'PG REGISTERED Lorehold Variant 09 - Rafael Paste 2026-06-24',
  'commander',
  'Manual Lorehold deck registration for card validation. deck_hash=9370b6170e00bc9fdcb33358ed7653f0c06a2d454871361dbef4fdc75560e6ee; source=docs/hermes-analysis/manaloom-knowledge/decks/lorehold-the-historian/2026-06-24-variant-09-user-decklist.md',
  false,
  0,
  'Pending validation: user-pasted Lorehold lifegain storm deck registered for card logic review.',
  'Pending card-rule validation; not promoted as definitive deck.',
  'lifegain-storm-variant',
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

DELETE FROM deck_cards WHERE deck_id = 'b51c8f24-fa8b-50ee-8200-d78fe9908ffa'::uuid;

INSERT INTO deck_cards (deck_id, card_id, quantity, is_commander, condition)
SELECT
  'b51c8f24-fa8b-50ee-8200-d78fe9908ffa'::uuid,
  card_id,
  quantity,
  is_commander,
  'NM'
FROM tmp_lorehold_variant09_picked
ORDER BY ord;

INSERT INTO commander_learned_decks (
  id, commander_name, commander_name_normalized, deck_name,
  source_system, source_ref, source_url, archetype, card_list, card_count,
  score, wincon_primary, wincon_backup, legal_status, notes, metadata,
  is_active, promoted_at, updated_at
) VALUES (
  '806238bd-c707-5a9f-befc-56e00e93bb9c'::uuid,
  'Lorehold, the Historian',
  'lorehold, the historian',
  'Lorehold Variant 09 - Rafael Paste 2026-06-24',
  'manual_user_deck_registration',
  'lorehold_variant09_20260624_9370b6170e00',
  'docs/hermes-analysis/manaloom-knowledge/decks/lorehold-the-historian/2026-06-24-variant-09-user-decklist.md',
  'lifegain-storm-variant',
  '1 Lorehold, the Historian
1 Aetherflux Reservoir
1 Akroma''s Will
1 Ancient Den
1 Ancient Tomb
1 Approach of the Second Sun
1 Arcane Signet
1 Arid Mesa
1 Authority of the Consuls
1 Bender''s Waterskin
1 Big Score
1 Blasphemous Act
1 Bloodstained Mire
1 Bolt Bend
1 Boros Charm
1 Brass''s Bounty
1 Caldera Pyremaw
1 Call Forth the Tempest
1 Cavern of Souls
1 Chrome Mox
1 Clifftop Retreat
1 Command Tower
1 Conduit Pylons
1 Creative Technique
1 Currency Converter
1 Dance with Calamity
1 Deflecting Palm
1 Deflecting Swat
1 Desperate Ritual
1 Dragon''s Rage Channeler
1 Elegant Parlor
1 Enlightened Tutor
1 Esper Sentinel
1 Fated Clash
1 Flawless Maneuver
1 Flooded Strand
1 Galvanoth
1 Gamble
1 Generous Gift
1 Goldspan Dragon
1 Goliath Daydreamer
1 Great Furnace
1 Helm of Awakening
1 Heroes Remembered
1 Hexing Squelcher
1 Insurrection
1 Invincible Hymn
1 Invoke Calamity
1 Invoke Justice
1 Jeska''s Will
1 Land Tax
1 Library of Leng
1 Mana Geyser
1 Marsh Flats
1 Monument to Endurance
1 Mother of Runes
3 Mountain // Mountain
1 Olórin''s Searing Light
1 Pearl Medallion
1 Penance
1 Perch Protection
8 Plains // Plains
1 Plateau
1 Prismatic Vista
1 Pyretic Ritual
1 Radiant Scrollwielder
1 Reckless Handling
1 Rise of the Eldrazi
1 Ruby Medallion
1 Sacred Foundry
1 Scalding Tarn
1 Scroll Rack
1 Seething Song
1 Sensei''s Divining Top
1 Silence
1 Smothering Tithe
1 Sol Ring
1 Soulfire Eruption
1 Spectator Seating
1 Storm Herd
1 Storm-Kiln Artist
1 Sunbaked Canyon
1 Sunbillow Verge
1 Teferi''s Protection
1 Treasonous Ogre
1 Trouble in Pairs
1 Ultima
1 Urza''s Saga
1 Volcanic Vision
1 Windswept Heath
1 Wooded Foothills',
  100,
  0,
  'pending_validation',
  'pending_validation',
  'registered_pending_card_rule_validation',
  'Manual user-pasted Lorehold lifegain storm deck registered for downstream card validation; not promoted active.',
  '{"deck_hash": "9370b6170e00bc9fdcb33358ed7653f0c06a2d454871361dbef4fdc75560e6ee", "hermes_deck_id": 614, "notes": "Registered from user-pasted Lorehold lifegain storm list. Not promoted as active learned deck.", "oracle_missing_after_registration": 0, "pg_deck_id": "b51c8f24-fa8b-50ee-8200-d78fe9908ffa", "registration_scope": "deck_intake_for_card_validation", "source_decklist": "docs/hermes-analysis/manaloom-knowledge/decks/lorehold-the-historian/2026-06-24-variant-09-user-decklist.md", "staging_report": "docs/hermes-analysis/master_optimizer_reports/lorehold_variant_staging_20260624_123839.json", "staging_warning_count": 17, "validation_status": "registered_pending_card_rule_validation"}'::jsonb,
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
