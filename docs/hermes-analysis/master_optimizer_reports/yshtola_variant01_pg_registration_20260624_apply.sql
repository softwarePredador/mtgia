\pset pager off
BEGIN;
-- PG register apply for Y'shtola Variant 01.
-- Scope: insert/update one decks row, replace its deck_cards rows, upsert one inactive commander_learned_decks row.
DROP TABLE IF EXISTS tmp_yshtola_variant01_input;
CREATE TEMP TABLE tmp_yshtola_variant01_input(ord int, card_name text, quantity int, is_commander boolean);
INSERT INTO tmp_yshtola_variant01_input(ord, card_name, quantity, is_commander) VALUES
  (1, 'Y''shtola, Night''s Blessed'::text, 1::int, true::boolean),
  (2, 'Adarkar Wastes'::text, 1::int, false::boolean),
  (3, 'An Offer You Can''t Refuse'::text, 1::int, false::boolean),
  (4, 'Ancient Tomb'::text, 1::int, false::boolean),
  (5, 'Arcane Signet'::text, 1::int, false::boolean),
  (6, 'Authority of the Consuls'::text, 1::int, false::boolean),
  (7, 'Blood Pact'::text, 1::int, false::boolean),
  (8, 'Bloodthirsty Conqueror'::text, 1::int, false::boolean),
  (9, 'Brainstorm'::text, 1::int, false::boolean),
  (10, 'Brainsurge'::text, 1::int, false::boolean),
  (11, 'Caves of Koilos'::text, 1::int, false::boolean),
  (12, 'Command Tower'::text, 1::int, false::boolean),
  (13, 'Commander''s Sphere'::text, 1::int, false::boolean),
  (14, 'Crawlspace'::text, 1::int, false::boolean),
  (15, 'Curiosity'::text, 1::int, false::boolean),
  (16, 'Cyclonic Rift'::text, 1::int, false::boolean),
  (17, 'Dark Ritual'::text, 1::int, false::boolean),
  (18, 'Deadly Rollick'::text, 1::int, false::boolean),
  (19, 'Delney, Streetwise Lookout'::text, 1::int, false::boolean),
  (20, 'Dimir Signet'::text, 1::int, false::boolean),
  (21, 'Enduring Tenacity'::text, 1::int, false::boolean),
  (22, 'Enlightened Tutor'::text, 1::int, false::boolean),
  (23, 'Esper Sentinel'::text, 1::int, false::boolean),
  (24, 'Exotic Orchard'::text, 1::int, false::boolean),
  (25, 'Exquisite Blood'::text, 1::int, false::boolean),
  (26, 'Exsanguinate'::text, 1::int, false::boolean),
  (27, 'Fabled Passage'::text, 1::int, false::boolean),
  (28, 'Farewell'::text, 1::int, false::boolean),
  (29, 'Fierce Guardianship'::text, 1::int, false::boolean),
  (30, 'Flare of Denial'::text, 1::int, false::boolean),
  (31, 'Flawless Maneuver'::text, 1::int, false::boolean),
  (32, 'Flooded Strand'::text, 1::int, false::boolean),
  (33, 'Ghostly Prison'::text, 1::int, false::boolean),
  (34, 'Gloomlake Verge'::text, 1::int, false::boolean),
  (35, 'Godless Shrine'::text, 1::int, false::boolean),
  (36, 'Grand Abolisher'::text, 1::int, false::boolean),
  (37, 'Grim Tutor'::text, 1::int, false::boolean),
  (38, 'Hallowed Fountain'::text, 1::int, false::boolean),
  (39, 'High Fae Trickster'::text, 1::int, false::boolean),
  (40, 'Idyllic Tutor'::text, 1::int, false::boolean),
  (41, 'Island'::text, 3::int, false::boolean),
  (42, 'Kambal, Consul of Allocation'::text, 1::int, false::boolean),
  (43, 'Kira, Great Glass-Spinner'::text, 1::int, false::boolean),
  (44, 'Lightning Greaves'::text, 1::int, false::boolean),
  (45, 'Malakir Rebirth'::text, 1::int, false::boolean),
  (46, 'Mana Vault'::text, 1::int, false::boolean),
  (47, 'Marauding Blight-Priest'::text, 1::int, false::boolean),
  (48, 'Marsh Flats'::text, 1::int, false::boolean),
  (49, 'Misleading Signpost'::text, 1::int, false::boolean),
  (50, 'Mox Amber'::text, 1::int, false::boolean),
  (51, 'Mystic Remora'::text, 1::int, false::boolean),
  (52, 'Mystical Tutor'::text, 1::int, false::boolean),
  (53, 'Ophidian Eye'::text, 1::int, false::boolean),
  (54, 'Orzhov Signet'::text, 1::int, false::boolean),
  (55, 'Otawara, Soaring City'::text, 1::int, false::boolean),
  (56, 'Plains'::text, 3::int, false::boolean),
  (57, 'Polluted Delta'::text, 1::int, false::boolean),
  (58, 'Ponder'::text, 1::int, false::boolean),
  (59, 'Prismatic Vista'::text, 1::int, false::boolean),
  (60, 'Propaganda'::text, 1::int, false::boolean),
  (61, 'Reflecting Pool'::text, 1::int, false::boolean),
  (62, 'Reliquary Tower'::text, 1::int, false::boolean),
  (63, 'Rhystic Study'::text, 1::int, false::boolean),
  (64, 'Sanguine Bond'::text, 1::int, false::boolean),
  (65, 'Scrubland'::text, 1::int, false::boolean),
  (66, 'Sejiri Shelter'::text, 1::int, false::boolean),
  (67, 'Shattered Sanctum'::text, 1::int, false::boolean),
  (68, 'Sheoldred, the Apocalypse'::text, 1::int, false::boolean),
  (69, 'Sigil of Sleep'::text, 1::int, false::boolean),
  (70, 'Sink into Stupor'::text, 1::int, false::boolean),
  (71, 'Smothering Tithe'::text, 1::int, false::boolean),
  (72, 'Sol Ring'::text, 1::int, false::boolean),
  (73, 'Spirit Link'::text, 1::int, false::boolean),
  (74, 'Starfall Invocation'::text, 1::int, false::boolean),
  (75, 'Starting Town'::text, 1::int, false::boolean),
  (76, 'Sudden Spoiling'::text, 1::int, false::boolean),
  (77, 'Sunken Ruins'::text, 1::int, false::boolean),
  (78, 'Swamp'::text, 4::int, false::boolean),
  (79, 'Swiftfoot Boots'::text, 1::int, false::boolean),
  (80, 'Talisman of Dominance'::text, 1::int, false::boolean),
  (81, 'Talisman of Hierarchy'::text, 1::int, false::boolean),
  (82, 'Talisman of Progress'::text, 1::int, false::boolean),
  (83, 'Teferi''s Protection'::text, 1::int, false::boolean),
  (84, 'Teferi, Time Raveler'::text, 1::int, false::boolean),
  (85, 'The Darkness Crystal'::text, 1::int, false::boolean),
  (86, 'The Meathook Massacre'::text, 1::int, false::boolean),
  (87, 'The One Ring'::text, 1::int, false::boolean),
  (88, 'The Wind Crystal'::text, 1::int, false::boolean),
  (89, 'Think Twice'::text, 1::int, false::boolean),
  (90, 'Underground River'::text, 1::int, false::boolean),
  (91, 'Vito, Thorn of the Dusk Rose'::text, 1::int, false::boolean),
  (92, 'Watery Grave'::text, 1::int, false::boolean),
  (93, 'Witch Enchanter'::text, 1::int, false::boolean);

DROP TABLE IF EXISTS tmp_yshtola_variant01_picked;
CREATE TEMP TABLE tmp_yshtola_variant01_picked AS
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
  FROM tmp_yshtola_variant01_input i
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
  SELECT COUNT(*) INTO missing_count FROM tmp_yshtola_variant01_picked WHERE card_id IS NULL;
  IF missing_count <> 0 THEN
    RAISE EXCEPTION 'Refusing Y''shtola Variant 01 PG registration: % cards missing from cards catalog', missing_count;
  END IF;
  SELECT COALESCE(SUM(quantity),0)::int INTO total_qty FROM tmp_yshtola_variant01_picked;
  SELECT COALESCE(SUM(CASE WHEN is_commander THEN quantity ELSE 0 END),0)::int INTO commander_qty FROM tmp_yshtola_variant01_picked;
  IF total_qty <> 100 THEN
    RAISE EXCEPTION 'Refusing Y''shtola Variant 01 PG registration: expected qty 100, got %', total_qty;
  END IF;
  IF commander_qty <> 1 THEN
    RAISE EXCEPTION 'Refusing Y''shtola Variant 01 PG registration: expected commander qty 1, got %', commander_qty;
  END IF;
END $$;

INSERT INTO decks (
  id, user_id, name, format, description, is_public, synergy_score,
  strengths, weaknesses, archetype, bracket
) VALUES (
  '982cf6a6-c84a-5c3e-b9fc-e79127598b89'::uuid,
  NULL,
  'PG REGISTERED Y''shtola Variant 01 - Rafael Paste 2026-06-24',
  'commander',
  'Manual non-Lorehold deck registration for card validation. deck_hash=2165c4d41e8526ce5b0deae48422dba71d5a585747cdde5c9d6fdca0d34406fd; source=docs/hermes-analysis/manaloom-knowledge/decks/yshtola-nights-blessed/2026-06-24-variant-01-user-decklist.md',
  false,
  0,
  'Pending validation: user-pasted Y''shtola Esper life-drain/control deck registered for card logic review.',
  'Pending card-rule validation; not promoted as definitive deck.',
  'esper-life-drain-control-variant',
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

DELETE FROM deck_cards WHERE deck_id = '982cf6a6-c84a-5c3e-b9fc-e79127598b89'::uuid;

INSERT INTO deck_cards (deck_id, card_id, quantity, is_commander, condition)
SELECT
  '982cf6a6-c84a-5c3e-b9fc-e79127598b89'::uuid,
  card_id,
  quantity,
  is_commander,
  'NM'
FROM tmp_yshtola_variant01_picked
ORDER BY ord;

INSERT INTO commander_learned_decks (
  id, commander_name, commander_name_normalized, deck_name,
  source_system, source_ref, source_url, archetype, card_list, card_count,
  score, wincon_primary, wincon_backup, legal_status, notes, metadata,
  is_active, promoted_at, updated_at
) VALUES (
  '3ee6a17e-c72f-540e-90fe-e05dc37ed5e9'::uuid,
  'Y''shtola, Night''s Blessed',
  'y''shtola, night''s blessed',
  'Y''shtola Variant 01 - Rafael Paste 2026-06-24',
  'manual_user_deck_registration',
  'yshtola_variant01_20260624_2165c4d41e85',
  'docs/hermes-analysis/manaloom-knowledge/decks/yshtola-nights-blessed/2026-06-24-variant-01-user-decklist.md',
  'esper-life-drain-control-variant',
  '1 Y''shtola, Night''s Blessed
1 Adarkar Wastes
1 An Offer You Can''t Refuse
1 Ancient Tomb
1 Arcane Signet
1 Authority of the Consuls
1 Blood Pact
1 Bloodthirsty Conqueror
1 Brainstorm
1 Brainsurge
1 Caves of Koilos
1 Command Tower
1 Commander''s Sphere
1 Crawlspace
1 Curiosity
1 Cyclonic Rift
1 Dark Ritual
1 Deadly Rollick
1 Delney, Streetwise Lookout
1 Dimir Signet
1 Enduring Tenacity
1 Enlightened Tutor
1 Esper Sentinel
1 Exotic Orchard
1 Exquisite Blood
1 Exsanguinate
1 Fabled Passage
1 Farewell
1 Fierce Guardianship
1 Flare of Denial
1 Flawless Maneuver
1 Flooded Strand
1 Ghostly Prison
1 Gloomlake Verge
1 Godless Shrine
1 Grand Abolisher
1 Grim Tutor
1 Hallowed Fountain // Hallowed Fountain
1 High Fae Trickster
1 Idyllic Tutor
3 Island // Island
1 Kambal, Consul of Allocation
1 Kira, Great Glass-Spinner
1 Lightning Greaves
1 Malakir Rebirth // Malakir Mire
1 Mana Vault
1 Marauding Blight-Priest
1 Marsh Flats
1 Misleading Signpost
1 Mox Amber
1 Mystic Remora
1 Mystical Tutor
1 Ophidian Eye
1 Orzhov Signet
1 Otawara, Soaring City
3 Plains // Plains
1 Polluted Delta
1 Ponder
1 Prismatic Vista
1 Propaganda // Propaganda
1 Reflecting Pool
1 Reliquary Tower
1 Rhystic Study
1 Sanguine Bond
1 Scrubland
1 Sejiri Shelter // Sejiri Glacier
1 Shattered Sanctum
1 Sheoldred, the Apocalypse
1 Sigil of Sleep
1 Sink into Stupor // Soporific Springs
1 Smothering Tithe
1 Sol Ring
1 Spirit Link
1 Starfall Invocation
1 Starting Town
1 Sudden Spoiling
1 Sunken Ruins
4 Swamp // Swamp
1 Swiftfoot Boots
1 Talisman of Dominance
1 Talisman of Hierarchy
1 Talisman of Progress
1 Teferi''s Protection
1 Teferi, Time Raveler
1 The Darkness Crystal
1 The Meathook Massacre
1 The One Ring
1 The Wind Crystal
1 Think Twice
1 Underground River
1 Vito, Thorn of the Dusk Rose
1 Watery Grave
1 Witch Enchanter // Witch-Blessed Meadow',
  100,
  0,
  'Y''shtola life-drain control with draw-punisher engines',
  'Esper combo finish through Exquisite Blood/Sanguine Bond/Vito package',
  'registered_pending_card_rule_validation',
  'Registered from user paste for catalog/card-rule validation. Inactive learned row; not a definitive promoted deck.',
  '{"deck_hash": "2165c4d41e8526ce5b0deae48422dba71d5a585747cdde5c9d6fdca0d34406fd", "hermes_deck_id": 621, "intake_date": "2026-06-24", "resolution_artifact": "docs/hermes-analysis/master_optimizer_reports/yshtola_variant01_resolution_20260624.json", "scope": "non-Lorehold deck intake only; no deck swap; learned deck inactive", "source_path": "docs/hermes-analysis/manaloom-knowledge/decks/yshtola-nights-blessed/2026-06-24-variant-01-user-decklist.md", "source_ref": "yshtola_variant01_20260624_2165c4d41e85"}'::jsonb,
  false,
  NULL,
  now()
)
ON CONFLICT (id) DO UPDATE SET
  commander_name = EXCLUDED.commander_name,
  commander_name_normalized = EXCLUDED.commander_name_normalized,
  deck_name = EXCLUDED.deck_name,
  source_system = EXCLUDED.source_system,
  source_ref = EXCLUDED.source_ref,
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
