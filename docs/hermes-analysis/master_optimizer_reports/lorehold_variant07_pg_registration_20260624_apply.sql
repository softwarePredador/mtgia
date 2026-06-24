\pset pager off
BEGIN;
-- PG register apply for Lorehold Variant 07.
-- Scope: insert/update one decks row, replace its deck_cards rows, upsert one inactive commander_learned_decks row.
DROP TABLE IF EXISTS tmp_lorehold_variant07_input;
CREATE TEMP TABLE tmp_lorehold_variant07_input(ord int, card_name text, quantity int, is_commander boolean);
INSERT INTO tmp_lorehold_variant07_input(ord, card_name, quantity, is_commander) VALUES
  (1, 'Lorehold, the Historian'::text, 1::int, true::boolean),
  (2, 'Agate Instigator'::text, 1::int, false::boolean),
  (3, 'Ancient Gold Dragon'::text, 1::int, false::boolean),
  (4, 'Ancient Tomb'::text, 1::int, false::boolean),
  (5, 'Approach of the Second Sun'::text, 1::int, false::boolean),
  (6, 'Arcane Signet'::text, 1::int, false::boolean),
  (7, 'Arena of Glory'::text, 1::int, false::boolean),
  (8, 'Arid Mesa'::text, 1::int, false::boolean),
  (9, 'Artist''s Talent'::text, 1::int, false::boolean),
  (10, 'Austere Command'::text, 1::int, false::boolean),
  (11, 'Barbarian Ring'::text, 1::int, false::boolean),
  (12, 'Basalt Monolith'::text, 1::int, false::boolean),
  (13, 'Birgi, God of Storytelling // Harnfel, Horn of Bounty'::text, 1::int, false::boolean),
  (14, 'Blasphemous Act'::text, 1::int, false::boolean),
  (15, 'Bloodstained Mire'::text, 1::int, false::boolean),
  (16, 'Boros Charm'::text, 1::int, false::boolean),
  (17, 'Boros Reckoner'::text, 1::int, false::boolean),
  (18, 'Boseiju, Who Shelters All'::text, 1::int, false::boolean),
  (19, 'Brass''s Bounty'::text, 1::int, false::boolean),
  (20, 'Call Forth the Tempest'::text, 1::int, false::boolean),
  (21, 'Cavern of Souls'::text, 1::int, false::boolean),
  (22, 'Charmbreaker Devils'::text, 1::int, false::boolean),
  (23, 'City of Brass'::text, 1::int, false::boolean),
  (24, 'City of Traitors'::text, 1::int, false::boolean),
  (25, 'Cloud Key'::text, 1::int, false::boolean),
  (26, 'Command Tower'::text, 1::int, false::boolean),
  (27, 'Crystal Vein'::text, 1::int, false::boolean),
  (28, 'Dualcaster Mage'::text, 1::int, false::boolean),
  (29, 'Eiganjo, Seat of the Empire'::text, 1::int, false::boolean),
  (30, 'Elegant Parlor'::text, 1::int, false::boolean),
  (31, 'Enlightened Tutor'::text, 1::int, false::boolean),
  (32, 'Ephemerate'::text, 1::int, false::boolean),
  (33, 'Flare of Duplication'::text, 1::int, false::boolean),
  (34, 'Flooded Strand'::text, 1::int, false::boolean),
  (35, 'Forbidden Orchard'::text, 1::int, false::boolean),
  (36, 'Fury Storm'::text, 1::int, false::boolean),
  (37, 'Gamble'::text, 1::int, false::boolean),
  (38, 'Gemstone Caverns'::text, 1::int, false::boolean),
  (39, 'Gisela, Blade of Goldnight'::text, 1::int, false::boolean),
  (40, 'Grinding Station'::text, 1::int, false::boolean),
  (41, 'Heat Shimmer'::text, 1::int, false::boolean),
  (42, 'Helm of Awakening'::text, 1::int, false::boolean),
  (43, 'Impact Tremors'::text, 1::int, false::boolean),
  (44, 'Increasing Vengeance'::text, 1::int, false::boolean),
  (45, 'Jeska''s Will'::text, 1::int, false::boolean),
  (46, 'Library of Leng'::text, 1::int, false::boolean),
  (47, 'Lion''s Eye Diamond'::text, 1::int, false::boolean),
  (48, 'Longshot, Rebel Bowman'::text, 1::int, false::boolean),
  (49, 'Mana Confluence'::text, 1::int, false::boolean),
  (50, 'Mana Geyser'::text, 1::int, false::boolean),
  (51, 'Mana Vault'::text, 1::int, false::boolean),
  (52, 'Marsh Flats'::text, 1::int, false::boolean),
  (53, 'Mizzix''s Mastery'::text, 1::int, false::boolean),
  (54, 'Molten Duplication'::text, 1::int, false::boolean),
  (55, 'Molten Gatekeeper'::text, 1::int, false::boolean),
  (56, 'Monologue Tax'::text, 1::int, false::boolean),
  (57, 'Past in Flames'::text, 1::int, false::boolean),
  (58, 'Pearl Medallion'::text, 1::int, false::boolean),
  (59, 'Plains // Plains'::text, 1::int, false::boolean),
  (60, 'Plateau'::text, 1::int, false::boolean),
  (61, 'Purphoros, God of the Forge'::text, 1::int, false::boolean),
  (62, 'Pyromancer''s Goggles'::text, 1::int, false::boolean),
  (63, 'Red Elemental Blast'::text, 1::int, false::boolean),
  (64, 'Reforge the Soul'::text, 1::int, false::boolean),
  (65, 'Reiterate'::text, 1::int, false::boolean),
  (66, 'Rem Karolus, Stalwart Slayer'::text, 1::int, false::boolean),
  (67, 'Repercussion'::text, 1::int, false::boolean),
  (68, 'Reprieve'::text, 1::int, false::boolean),
  (69, 'Restoration Seminar'::text, 1::int, false::boolean),
  (70, 'Return the Favor'::text, 1::int, false::boolean),
  (71, 'Reverberate'::text, 1::int, false::boolean),
  (72, 'Ruby Medallion'::text, 1::int, false::boolean),
  (73, 'Sacred Foundry'::text, 1::int, false::boolean),
  (74, 'Scalding Tarn'::text, 1::int, false::boolean),
  (75, 'Scroll Rack'::text, 1::int, false::boolean),
  (76, 'Seething Song'::text, 1::int, false::boolean),
  (77, 'Semblance Anvil'::text, 1::int, false::boolean),
  (78, 'Sensei''s Divining Top'::text, 1::int, false::boolean),
  (79, 'Shivan Gorge'::text, 1::int, false::boolean),
  (80, 'Silence'::text, 1::int, false::boolean),
  (81, 'Smothering Tithe'::text, 1::int, false::boolean),
  (82, 'Sokenzan, Crucible of Defiance'::text, 1::int, false::boolean),
  (83, 'Sol Ring'::text, 1::int, false::boolean),
  (84, 'Starfall Invocation'::text, 1::int, false::boolean),
  (85, 'Storm-Kiln Artist'::text, 1::int, false::boolean),
  (86, 'Taii Wakeen, Perfect Shot'::text, 1::int, false::boolean),
  (87, 'Teferi''s Protection'::text, 1::int, false::boolean),
  (88, 'Terror of the Peaks'::text, 1::int, false::boolean),
  (89, 'Toralf, God of Fury // Toralf''s Hammer'::text, 1::int, false::boolean),
  (90, 'Twinflame'::text, 1::int, false::boolean),
  (91, 'Ultima'::text, 1::int, false::boolean),
  (92, 'Underworld Breach'::text, 1::int, false::boolean),
  (93, 'Urza''s Saga'::text, 1::int, false::boolean),
  (94, 'Warleader''s Call'::text, 1::int, false::boolean),
  (95, 'Wheel of Fortune'::text, 1::int, false::boolean),
  (96, 'Wild Ricochet'::text, 1::int, false::boolean),
  (97, 'Windswept Heath'::text, 1::int, false::boolean),
  (98, 'Wooded Foothills'::text, 1::int, false::boolean),
  (99, 'Young Pyromancer'::text, 1::int, false::boolean),
  (100, 'Zirda, the Dawnwaker'::text, 1::int, false::boolean);

DROP TABLE IF EXISTS tmp_lorehold_variant07_picked;
CREATE TEMP TABLE tmp_lorehold_variant07_picked AS
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
  FROM tmp_lorehold_variant07_input i
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
  SELECT COUNT(*) INTO missing_count FROM tmp_lorehold_variant07_picked WHERE card_id IS NULL;
  IF missing_count <> 0 THEN
    RAISE EXCEPTION 'Refusing Lorehold Variant 07 PG registration: % cards missing from cards catalog', missing_count;
  END IF;
  SELECT COALESCE(SUM(quantity),0)::int INTO total_qty FROM tmp_lorehold_variant07_picked;
  SELECT COALESCE(SUM(CASE WHEN is_commander THEN quantity ELSE 0 END),0)::int INTO commander_qty FROM tmp_lorehold_variant07_picked;
  IF total_qty <> 100 THEN
    RAISE EXCEPTION 'Refusing Lorehold Variant 07 PG registration: expected qty 100, got %', total_qty;
  END IF;
  IF commander_qty <> 1 THEN
    RAISE EXCEPTION 'Refusing Lorehold Variant 07 PG registration: expected commander qty 1, got %', commander_qty;
  END IF;
END $$;

INSERT INTO decks (
  id, user_id, name, format, description, is_public, synergy_score,
  strengths, weaknesses, archetype, bracket
) VALUES (
  '231281c3-e6a2-579b-93fe-21ddfdd13bda'::uuid,
  NULL,
  'PG REGISTERED Lorehold Variant 07 - Rafael Paste 2026-06-24',
  'commander',
  'Manual Lorehold deck registration for card validation. deck_hash=5570c465c492f07ba93dc89bfcb97bf3e08ae7e38bab6c7de0b24c77535a8648; source=docs/hermes-analysis/manaloom-knowledge/decks/lorehold-the-historian/2026-06-24-variant-07-user-decklist.md',
  false,
  0,
  'Pending validation: user-pasted Lorehold spell-copy combo deck registered for card logic review.',
  'Pending card-rule validation; not promoted as definitive deck.',
  'spell-copy-combo-variant',
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

DELETE FROM deck_cards WHERE deck_id = '231281c3-e6a2-579b-93fe-21ddfdd13bda'::uuid;

INSERT INTO deck_cards (deck_id, card_id, quantity, is_commander, condition)
SELECT
  '231281c3-e6a2-579b-93fe-21ddfdd13bda'::uuid,
  card_id,
  quantity,
  is_commander,
  'NM'
FROM tmp_lorehold_variant07_picked
ORDER BY ord;

INSERT INTO commander_learned_decks (
  id, commander_name, commander_name_normalized, deck_name,
  source_system, source_ref, source_url, archetype, card_list, card_count,
  score, wincon_primary, wincon_backup, legal_status, notes, metadata,
  is_active, promoted_at, updated_at
) VALUES (
  '493ebe46-6458-54b3-871c-93bf4863e1e8'::uuid,
  'Lorehold, the Historian',
  'lorehold, the historian',
  'Lorehold Variant 07 - Rafael Paste 2026-06-24',
  'manual_user_deck_registration',
  'lorehold_variant07_20260624_5570c465c492',
  'docs/hermes-analysis/manaloom-knowledge/decks/lorehold-the-historian/2026-06-24-variant-07-user-decklist.md',
  'spell-copy-combo-variant',
  '1 Lorehold, the Historian
1 Agate Instigator
1 Ancient Gold Dragon
1 Ancient Tomb
1 Approach of the Second Sun
1 Arcane Signet
1 Arena of Glory
1 Arid Mesa
1 Artist''s Talent
1 Austere Command
1 Barbarian Ring
1 Basalt Monolith
1 Birgi, God of Storytelling // Harnfel, Horn of Bounty
1 Blasphemous Act
1 Bloodstained Mire
1 Boros Charm
1 Boros Reckoner
1 Boseiju, Who Shelters All
1 Brass''s Bounty
1 Call Forth the Tempest
1 Cavern of Souls
1 Charmbreaker Devils
1 City of Brass
1 City of Traitors
1 Cloud Key
1 Command Tower
1 Crystal Vein
1 Dualcaster Mage
1 Eiganjo, Seat of the Empire
1 Elegant Parlor
1 Enlightened Tutor
1 Ephemerate
1 Flare of Duplication
1 Flooded Strand
1 Forbidden Orchard
1 Fury Storm
1 Gamble
1 Gemstone Caverns
1 Gisela, Blade of Goldnight
1 Grinding Station
1 Heat Shimmer
1 Helm of Awakening
1 Impact Tremors
1 Increasing Vengeance
1 Jeska''s Will
1 Library of Leng
1 Lion''s Eye Diamond
1 Longshot, Rebel Bowman
1 Mana Confluence
1 Mana Geyser
1 Mana Vault
1 Marsh Flats
1 Mizzix''s Mastery
1 Molten Duplication
1 Molten Gatekeeper
1 Monologue Tax
1 Past in Flames
1 Pearl Medallion
1 Plains // Plains
1 Plateau
1 Purphoros, God of the Forge
1 Pyromancer''s Goggles
1 Red Elemental Blast
1 Reforge the Soul
1 Reiterate
1 Rem Karolus, Stalwart Slayer
1 Repercussion
1 Reprieve
1 Restoration Seminar
1 Return the Favor
1 Reverberate
1 Ruby Medallion
1 Sacred Foundry
1 Scalding Tarn
1 Scroll Rack
1 Seething Song
1 Semblance Anvil
1 Sensei''s Divining Top
1 Shivan Gorge
1 Silence
1 Smothering Tithe
1 Sokenzan, Crucible of Defiance
1 Sol Ring
1 Starfall Invocation
1 Storm-Kiln Artist
1 Taii Wakeen, Perfect Shot
1 Teferi''s Protection
1 Terror of the Peaks
1 Toralf, God of Fury // Toralf''s Hammer
1 Twinflame
1 Ultima
1 Underworld Breach
1 Urza''s Saga
1 Warleader''s Call
1 Wheel of Fortune
1 Wild Ricochet
1 Windswept Heath
1 Wooded Foothills
1 Young Pyromancer
1 Zirda, the Dawnwaker',
  100,
  0,
  'pending_validation',
  'pending_validation',
  'registered_pending_card_rule_validation',
  'Manual user-pasted Lorehold spell-copy combo deck registered for downstream card validation; not promoted active.',
  '{"deck_hash": "5570c465c492f07ba93dc89bfcb97bf3e08ae7e38bab6c7de0b24c77535a8648", "hermes_deck_id": 612, "notes": "Registered from user-pasted Lorehold spell-copy combo list. Not promoted as active learned deck.", "oracle_missing_after_registration": 0, "pg_deck_id": "231281c3-e6a2-579b-93fe-21ddfdd13bda", "registration_scope": "deck_intake_for_card_validation", "source_decklist": "docs/hermes-analysis/manaloom-knowledge/decks/lorehold-the-historian/2026-06-24-variant-07-user-decklist.md", "staging_report": "docs/hermes-analysis/master_optimizer_reports/lorehold_variant_staging_20260624_122804.json", "staging_warning_count": 23, "validation_status": "registered_pending_card_rule_validation"}'::jsonb,
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
