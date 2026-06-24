\pset pager off
BEGIN;
-- PG register apply for Valgavoth Variant 01.
-- Scope: insert/update one decks row, replace its deck_cards rows, upsert one inactive commander_learned_decks row.
DROP TABLE IF EXISTS tmp_valgavoth_variant01_input;
CREATE TEMP TABLE tmp_valgavoth_variant01_input(ord int, card_name text, quantity int, is_commander boolean);
INSERT INTO tmp_valgavoth_variant01_input(ord, card_name, quantity, is_commander) VALUES
  (1, 'Valgavoth, Harrower of Souls'::text, 1::int, true::boolean),
  (2, 'Arcane Signet'::text, 1::int, false::boolean),
  (3, 'Arena of Glory'::text, 1::int, false::boolean),
  (4, 'Arid Mesa'::text, 1::int, false::boolean),
  (5, 'Ash Barrens'::text, 1::int, false::boolean),
  (6, 'Badlands'::text, 1::int, false::boolean),
  (7, 'Basilisk Collar'::text, 1::int, false::boolean),
  (8, 'Bedevil'::text, 1::int, false::boolean),
  (9, 'Blasphemous Act'::text, 1::int, false::boolean),
  (10, 'Blood Artist'::text, 1::int, false::boolean),
  (11, 'Blood Crypt'::text, 1::int, false::boolean),
  (12, 'Blood Seeker'::text, 1::int, false::boolean),
  (13, 'Bloodchief Ascension'::text, 1::int, false::boolean),
  (14, 'Bloodstained Mire'::text, 1::int, false::boolean),
  (15, 'Brash Taunter'::text, 1::int, false::boolean),
  (16, 'Castle Locthwain'::text, 1::int, false::boolean),
  (17, 'Cemetery Gatekeeper'::text, 1::int, false::boolean),
  (18, 'Chaos Warp'::text, 1::int, false::boolean),
  (19, 'City of Brass'::text, 1::int, false::boolean),
  (20, 'Command Tower'::text, 1::int, false::boolean),
  (21, 'Decree of Pain'::text, 1::int, false::boolean),
  (22, 'Deflecting Swat'::text, 1::int, false::boolean),
  (23, 'Dragonskull Summit'::text, 1::int, false::boolean),
  (24, 'Exotic Orchard'::text, 1::int, false::boolean),
  (25, 'Falkenrath Noble'::text, 1::int, false::boolean),
  (26, 'Fate Unraveler'::text, 1::int, false::boolean),
  (27, 'Feed the Swarm'::text, 1::int, false::boolean),
  (28, 'Fellwar Stone'::text, 1::int, false::boolean),
  (29, 'Fiery Inscription'::text, 1::int, false::boolean),
  (30, 'Gleeful Arsonist'::text, 1::int, false::boolean),
  (31, 'Graven Cairns'::text, 1::int, false::boolean),
  (32, 'Gray Merchant of Asphodel'::text, 1::int, false::boolean),
  (33, 'Harsh Mentor'::text, 1::int, false::boolean),
  (34, 'Hexing Squelcher'::text, 1::int, false::boolean),
  (35, 'Infernal Grasp'::text, 1::int, false::boolean),
  (36, 'Kaervek the Merciless'::text, 1::int, false::boolean),
  (37, 'Kardur, Doomscourge'::text, 1::int, false::boolean),
  (38, 'Kederekt Parasite'::text, 1::int, false::boolean),
  (39, 'Light Up the Stage'::text, 1::int, false::boolean),
  (40, 'Lightning Greaves'::text, 1::int, false::boolean),
  (41, 'Mai, Scornful Striker'::text, 1::int, false::boolean),
  (42, 'Malakir Rebirth'::text, 1::int, false::boolean),
  (43, 'Marsh Flats'::text, 1::int, false::boolean),
  (44, 'Massacre Girl'::text, 1::int, false::boolean),
  (45, 'Massacre Wurm'::text, 1::int, false::boolean),
  (46, 'Mayhem Devil'::text, 1::int, false::boolean),
  (47, 'Mind Stone'::text, 1::int, false::boolean),
  (48, 'Mogis, God of Slaughter'::text, 1::int, false::boolean),
  (49, 'Morbid Opportunist'::text, 1::int, false::boolean),
  (50, 'Mountain'::text, 7::int, false::boolean),
  (51, 'Nightshade Harvester'::text, 1::int, false::boolean),
  (52, 'Persistent Constrictor'::text, 1::int, false::boolean),
  (53, 'Phyrexian Tower'::text, 1::int, false::boolean),
  (54, 'Ragavan, Nimble Pilferer'::text, 1::int, false::boolean),
  (55, 'Rakdos Charm'::text, 1::int, false::boolean),
  (56, 'Rakdos Signet'::text, 1::int, false::boolean),
  (57, 'Rampaging Ferocidon'::text, 1::int, false::boolean),
  (58, 'Raucous Theater'::text, 1::int, false::boolean),
  (59, 'Redirect Lightning'::text, 1::int, false::boolean),
  (60, 'Sadistic Shell Game'::text, 1::int, false::boolean),
  (61, 'Scalding Tarn'::text, 1::int, false::boolean),
  (62, 'Scrawling Crawler'::text, 1::int, false::boolean),
  (63, 'Shadowblood Ridge'::text, 1::int, false::boolean),
  (64, 'Sheoldred, the Apocalypse'::text, 1::int, false::boolean),
  (65, 'Shivan Gorge'::text, 1::int, false::boolean),
  (66, 'Sol Ring'::text, 1::int, false::boolean),
  (67, 'Solemn Simulacrum'::text, 1::int, false::boolean),
  (68, 'Spiked Corridor // Torture Pit'::text, 1::int, false::boolean),
  (69, 'Spiteful Visions'::text, 1::int, false::boolean),
  (70, 'Star Athlete'::text, 1::int, false::boolean),
  (71, 'Sulfurous Springs'::text, 1::int, false::boolean),
  (72, 'Suspended Sentence'::text, 1::int, false::boolean),
  (73, 'Swamp'::text, 8::int, false::boolean),
  (74, 'Syr Konrad, the Grim'::text, 1::int, false::boolean),
  (75, 'Séance Board'::text, 1::int, false::boolean),
  (76, 'Tainted Peak'::text, 1::int, false::boolean),
  (77, 'Talisman of Indulgence'::text, 1::int, false::boolean),
  (78, 'The Lord of Pain'::text, 1::int, false::boolean),
  (79, 'The Meathook Massacre'::text, 1::int, false::boolean),
  (80, 'The Soul Stone'::text, 1::int, false::boolean),
  (81, 'Tibalt''s Trickery'::text, 1::int, false::boolean),
  (82, 'Uncivil Unrest'::text, 1::int, false::boolean),
  (83, 'Untimely Malfunction'::text, 1::int, false::boolean),
  (84, 'Vandalblast'::text, 1::int, false::boolean),
  (85, 'Verdant Catacombs'::text, 1::int, false::boolean),
  (86, 'Vial Smasher the Fierce'::text, 1::int, false::boolean),
  (87, 'Witch''s Clinic'::text, 1::int, false::boolean);

DROP TABLE IF EXISTS tmp_valgavoth_variant01_picked;
CREATE TEMP TABLE tmp_valgavoth_variant01_picked AS
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
  FROM tmp_valgavoth_variant01_input i
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
  SELECT COUNT(*) INTO missing_count FROM tmp_valgavoth_variant01_picked WHERE card_id IS NULL;
  IF missing_count <> 0 THEN
    RAISE EXCEPTION 'Refusing Valgavoth Variant 01 PG registration: % cards missing from cards catalog', missing_count;
  END IF;
  SELECT COALESCE(SUM(quantity),0)::int INTO total_qty FROM tmp_valgavoth_variant01_picked;
  SELECT COALESCE(SUM(CASE WHEN is_commander THEN quantity ELSE 0 END),0)::int INTO commander_qty FROM tmp_valgavoth_variant01_picked;
  IF total_qty <> 100 THEN
    RAISE EXCEPTION 'Refusing Valgavoth Variant 01 PG registration: expected qty 100, got %', total_qty;
  END IF;
  IF commander_qty <> 1 THEN
    RAISE EXCEPTION 'Refusing Valgavoth Variant 01 PG registration: expected commander qty 1, got %', commander_qty;
  END IF;
END $$;

INSERT INTO decks (
  id, user_id, name, format, description, is_public, synergy_score,
  strengths, weaknesses, archetype, bracket
) VALUES (
  'c77cb83c-dd28-5d66-a0d8-799079a848bb'::uuid,
  NULL,
  'PG REGISTERED Valgavoth Variant 01 - Rafael Paste 2026-06-24',
  'commander',
  'Manual non-Lorehold deck registration for card validation. deck_hash=b037751a69fa297355b67d7d3efac90cbeb3117303e9d9af1cbe2945e53b205f; source=docs/hermes-analysis/manaloom-knowledge/decks/valgavoth-harrower-of-souls/2026-06-24-variant-01-user-decklist.md',
  false,
  0,
  'Pending validation: user-pasted Valgavoth Rakdos pain/punisher deck registered for card logic review.',
  'Pending card-rule validation; not promoted as definitive deck.',
  'rakdos-pain-punisher-variant',
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

DELETE FROM deck_cards WHERE deck_id = 'c77cb83c-dd28-5d66-a0d8-799079a848bb'::uuid;

INSERT INTO deck_cards (deck_id, card_id, quantity, is_commander, condition)
SELECT
  'c77cb83c-dd28-5d66-a0d8-799079a848bb'::uuid,
  card_id,
  quantity,
  is_commander,
  'NM'
FROM tmp_valgavoth_variant01_picked
ORDER BY ord;

INSERT INTO commander_learned_decks (
  id, commander_name, commander_name_normalized, deck_name,
  source_system, source_ref, source_url, archetype, card_list, card_count,
  score, wincon_primary, wincon_backup, legal_status, notes, metadata,
  is_active, promoted_at, updated_at
) VALUES (
  'acdbd53f-f1a9-5c78-823e-3127d92c8b02'::uuid,
  'Valgavoth, Harrower of Souls',
  'valgavoth, harrower of souls',
  'Valgavoth Variant 01 - Rafael Paste 2026-06-24',
  'manual_user_deck_registration',
  'valgavoth_variant01_20260624_b037751a69fa',
  'docs/hermes-analysis/manaloom-knowledge/decks/valgavoth-harrower-of-souls/2026-06-24-variant-01-user-decklist.md',
  'rakdos-pain-punisher-variant',
  '1 Valgavoth, Harrower of Souls
1 Arcane Signet
1 Arena of Glory
1 Arid Mesa
1 Ash Barrens
1 Badlands
1 Basilisk Collar
1 Bedevil
1 Blasphemous Act
1 Blood Artist
1 Blood Crypt // Blood Crypt
1 Blood Seeker
1 Bloodchief Ascension
1 Bloodstained Mire
1 Brash Taunter
1 Castle Locthwain
1 Cemetery Gatekeeper
1 Chaos Warp
1 City of Brass
1 Command Tower
1 Decree of Pain
1 Deflecting Swat
1 Dragonskull Summit
1 Exotic Orchard
1 Falkenrath Noble
1 Fate Unraveler
1 Feed the Swarm
1 Fellwar Stone
1 Fiery Inscription
1 Gleeful Arsonist
1 Graven Cairns
1 Gray Merchant of Asphodel
1 Harsh Mentor
1 Hexing Squelcher
1 Infernal Grasp
1 Kaervek the Merciless
1 Kardur, Doomscourge // Kardur, Doomscourge
1 Kederekt Parasite
1 Light Up the Stage
1 Lightning Greaves
1 Mai, Scornful Striker
1 Malakir Rebirth // Malakir Mire
1 Marsh Flats
1 Massacre Girl
1 Massacre Wurm
1 Mayhem Devil
1 Mind Stone
1 Mogis, God of Slaughter
1 Morbid Opportunist
7 Mountain // Mountain
1 Nightshade Harvester
1 Persistent Constrictor
1 Phyrexian Tower
1 Ragavan, Nimble Pilferer
1 Rakdos Charm
1 Rakdos Signet
1 Rampaging Ferocidon
1 Raucous Theater
1 Redirect Lightning
1 Sadistic Shell Game
1 Scalding Tarn
1 Scrawling Crawler
1 Shadowblood Ridge
1 Sheoldred, the Apocalypse
1 Shivan Gorge
1 Sol Ring
1 Solemn Simulacrum
1 Spiked Corridor // Torture Pit
1 Spiteful Visions
1 Star Athlete
1 Sulfurous Springs
1 Suspended Sentence
8 Swamp // Swamp
1 Syr Konrad, the Grim
1 Séance Board
1 Tainted Peak
1 Talisman of Indulgence
1 The Lord of Pain
1 The Meathook Massacre
1 The Soul Stone
1 Tibalt''s Trickery
1 Uncivil Unrest
1 Untimely Malfunction
1 Vandalblast
1 Verdant Catacombs
1 Vial Smasher the Fierce
1 Witch''s Clinic',
  100,
  0,
  'damage and life-loss punishment',
  'aristocrats drain and table-wide pain engines',
  'registered_pending_card_rule_validation',
  'Manual user-pasted Valgavoth Rakdos pain/punisher deck registered for downstream card validation; not promoted active.',
  '{"deck_hash": "b037751a69fa297355b67d7d3efac90cbeb3117303e9d9af1cbe2945e53b205f", "hermes_deck_id": 618, "input_qty": 100, "input_rows": 87, "notes": "Registered from user-pasted Valgavoth Rakdos pain/punisher list. Not promoted active.", "oracle_missing_after_registration": 0, "pg_deck_id": "c77cb83c-dd28-5d66-a0d8-799079a848bb", "pg_learned_id": "acdbd53f-f1a9-5c78-823e-3127d92c8b02", "registration_scope": "non_lorehold_deck_intake_for_card_validation", "resolved_rows": 87, "source_decklist": "docs/hermes-analysis/manaloom-knowledge/decks/valgavoth-harrower-of-souls/2026-06-24-variant-01-user-decklist.md", "validation_status": "registered_pending_card_rule_validation"}'::jsonb,
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
