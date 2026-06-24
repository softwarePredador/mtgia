\pset pager off
BEGIN;
-- PG register apply for Kefka Variant 01.
-- Scope: insert/update one decks row, replace its deck_cards rows, upsert one inactive commander_learned_decks row.
DROP TABLE IF EXISTS tmp_kefka_variant01_input;
CREATE TEMP TABLE tmp_kefka_variant01_input(ord int, card_name text, quantity int, is_commander boolean);
INSERT INTO tmp_kefka_variant01_input(ord, card_name, quantity, is_commander) VALUES
  (1, 'Kefka, Court Mage'::text, 1::int, true::boolean),
  (2, 'Aclazotz, Deepest Betrayal'::text, 1::int, false::boolean),
  (3, 'Arcane Denial'::text, 1::int, false::boolean),
  (4, 'Arcane Signet'::text, 1::int, false::boolean),
  (5, 'Archfiend of Ifnir'::text, 1::int, false::boolean),
  (6, 'Black Market Connections'::text, 1::int, false::boolean),
  (7, 'Blazemire Verge'::text, 1::int, false::boolean),
  (8, 'Blood Crypt'::text, 1::int, false::boolean),
  (9, 'Bloodchief Ascension'::text, 1::int, false::boolean),
  (10, 'Bloodletter of Aclazotz'::text, 1::int, false::boolean),
  (11, 'Bloodthirsty Conqueror'::text, 1::int, false::boolean),
  (12, 'Bojuka Bog'::text, 1::int, false::boolean),
  (13, 'Bone Miser'::text, 1::int, false::boolean),
  (14, 'Brallin, Skyshark Rider'::text, 1::int, false::boolean),
  (15, 'Cathartic Reunion'::text, 1::int, false::boolean),
  (16, 'Chaos Warp'::text, 1::int, false::boolean),
  (17, 'Command Tower'::text, 1::int, false::boolean),
  (18, 'Containment Construct'::text, 1::int, false::boolean),
  (19, 'Court of Ambition'::text, 1::int, false::boolean),
  (20, 'Crumbling Necropolis'::text, 1::int, false::boolean),
  (21, 'Dark Deal'::text, 1::int, false::boolean),
  (22, 'Davros, Dalek Creator'::text, 1::int, false::boolean),
  (23, 'Deflecting Swat'::text, 1::int, false::boolean),
  (24, 'Demolition Field'::text, 1::int, false::boolean),
  (25, 'Dragonskull Summit'::text, 1::int, false::boolean),
  (26, 'Drossforge Bridge'::text, 1::int, false::boolean),
  (27, 'Drowned Catacomb'::text, 1::int, false::boolean),
  (28, 'Entropic Battlecruiser'::text, 1::int, false::boolean),
  (29, 'Exotic Orchard'::text, 1::int, false::boolean),
  (30, 'Exquisite Blood'::text, 1::int, false::boolean),
  (31, 'Faithless Looting'::text, 1::int, false::boolean),
  (32, 'Feast of Sanity'::text, 1::int, false::boolean),
  (33, 'Fell Specter'::text, 1::int, false::boolean),
  (34, 'Geth''s Grimoire'::text, 1::int, false::boolean),
  (35, 'Glint-Horn Buccaneer'::text, 1::int, false::boolean),
  (36, 'Gloomlake Verge'::text, 1::int, false::boolean),
  (37, 'Green Goblin, Nemesis'::text, 1::int, false::boolean),
  (38, 'Harmonic Prodigy'::text, 1::int, false::boolean),
  (39, 'Haunted Ridge'::text, 1::int, false::boolean),
  (40, 'Island'::text, 2::int, false::boolean),
  (41, 'Kaya''s Ghostform'::text, 1::int, false::boolean),
  (42, 'Liliana''s Caress'::text, 1::int, false::boolean),
  (43, 'Luxury Suite'::text, 1::int, false::boolean),
  (44, 'Magmakin Artillerist'::text, 1::int, false::boolean),
  (45, 'Mana Drain'::text, 1::int, false::boolean),
  (46, 'Megrim'::text, 1::int, false::boolean),
  (47, 'Mistvault Bridge'::text, 1::int, false::boolean),
  (48, 'Monument to Endurance'::text, 1::int, false::boolean),
  (49, 'Morphic Pool'::text, 1::int, false::boolean),
  (50, 'Mountain'::text, 2::int, false::boolean),
  (51, 'Necrogoyf'::text, 1::int, false::boolean),
  (52, 'Niv-Mizzet, Parun'::text, 1::int, false::boolean),
  (53, 'Oppression'::text, 1::int, false::boolean),
  (54, 'Painful Quandary'::text, 1::int, false::boolean),
  (55, 'Phyrexian Arena'::text, 1::int, false::boolean),
  (56, 'Psychic Frog'::text, 1::int, false::boolean),
  (57, 'Psychosis Crawler'::text, 1::int, false::boolean),
  (58, 'Raiders'' Wake'::text, 1::int, false::boolean),
  (59, 'Raucous Theater'::text, 1::int, false::boolean),
  (60, 'Riverpyre Verge'::text, 1::int, false::boolean),
  (61, 'Rogue''s Passage'::text, 1::int, false::boolean),
  (62, 'Sangromancer'::text, 1::int, false::boolean),
  (63, 'Scalding Tarn'::text, 1::int, false::boolean),
  (64, 'Scavenger Grounds'::text, 1::int, false::boolean),
  (65, 'Sheoldred'::text, 1::int, false::boolean),
  (66, 'Sheoldred, the Apocalypse'::text, 1::int, false::boolean),
  (67, 'Shipwreck Marsh'::text, 1::int, false::boolean),
  (68, 'Silverbluff Bridge'::text, 1::int, false::boolean),
  (69, 'Sol Ring'::text, 1::int, false::boolean),
  (70, 'Solphim, Mayhem Dominus'::text, 1::int, false::boolean),
  (71, 'Steam Vents'::text, 1::int, false::boolean),
  (72, 'Stormcarved Coast'::text, 1::int, false::boolean),
  (73, 'Sulfur Falls'::text, 1::int, false::boolean),
  (74, 'Surly Badgersaur'::text, 1::int, false::boolean),
  (75, 'Swamp'::text, 2::int, false::boolean),
  (76, 'Swan Song'::text, 1::int, false::boolean),
  (77, 'Swiftfoot Boots'::text, 1::int, false::boolean),
  (78, 'Syr Konrad, the Grim'::text, 1::int, false::boolean),
  (79, 'Teferi''s Time Twist'::text, 1::int, false::boolean),
  (80, 'The Haunt of Hightower'::text, 1::int, false::boolean),
  (81, 'The Locust God'::text, 1::int, false::boolean),
  (82, 'Thundering Falls'::text, 1::int, false::boolean),
  (83, 'Tinybones, Bauble Burglar'::text, 1::int, false::boolean),
  (84, 'Tinybones, Trinket Thief'::text, 1::int, false::boolean),
  (85, 'Toxic Deluge'::text, 1::int, false::boolean),
  (86, 'Training Center'::text, 1::int, false::boolean),
  (87, 'Underworld Dreams'::text, 1::int, false::boolean),
  (88, 'Urborg, Tomb of Yawgmoth'::text, 1::int, false::boolean),
  (89, 'Vandalblast'::text, 1::int, false::boolean),
  (90, 'Vivi Ornitier'::text, 1::int, false::boolean),
  (91, 'Waste Not'::text, 1::int, false::boolean),
  (92, 'Watery Grave'::text, 1::int, false::boolean),
  (93, 'Whip of Erebos'::text, 1::int, false::boolean),
  (94, 'Withering Torment'::text, 1::int, false::boolean),
  (95, 'Words of Waste'::text, 1::int, false::boolean),
  (96, 'Wound Reflection'::text, 1::int, false::boolean),
  (97, 'Xander''s Lounge'::text, 1::int, false::boolean);

DROP TABLE IF EXISTS tmp_kefka_variant01_picked;
CREATE TEMP TABLE tmp_kefka_variant01_picked AS
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
  FROM tmp_kefka_variant01_input i
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
  SELECT COUNT(*) INTO missing_count FROM tmp_kefka_variant01_picked WHERE card_id IS NULL;
  IF missing_count <> 0 THEN
    RAISE EXCEPTION 'Refusing Kefka Variant 01 PG registration: % cards missing from cards catalog', missing_count;
  END IF;
  SELECT COALESCE(SUM(quantity),0)::int INTO total_qty FROM tmp_kefka_variant01_picked;
  SELECT COALESCE(SUM(CASE WHEN is_commander THEN quantity ELSE 0 END),0)::int INTO commander_qty FROM tmp_kefka_variant01_picked;
  IF total_qty <> 100 THEN
    RAISE EXCEPTION 'Refusing Kefka Variant 01 PG registration: expected qty 100, got %', total_qty;
  END IF;
  IF commander_qty <> 1 THEN
    RAISE EXCEPTION 'Refusing Kefka Variant 01 PG registration: expected commander qty 1, got %', commander_qty;
  END IF;
END $$;

INSERT INTO decks (
  id, user_id, name, format, description, is_public, synergy_score,
  strengths, weaknesses, archetype, bracket
) VALUES (
  '34508aae-e393-577a-97d8-6259353664af'::uuid,
  NULL,
  'PG REGISTERED Kefka Variant 01 - Rafael Paste 2026-06-24',
  'commander',
  'Manual non-Lorehold deck registration for card validation. deck_hash=ec4ca73a3063b8af06bd443b5dfb3d2578ae8df8970446a9b7fc8dbc52eeb1ea; source=docs/hermes-analysis/manaloom-knowledge/decks/kefka-court-mage/2026-06-24-variant-01-user-decklist.md',
  false,
  0,
  'Pending validation: user-pasted Kefka Grixis discard/punisher deck registered for card logic review.',
  'Pending card-rule validation; not promoted as definitive deck.',
  'grixis-discard-punisher-variant',
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

DELETE FROM deck_cards WHERE deck_id = '34508aae-e393-577a-97d8-6259353664af'::uuid;

INSERT INTO deck_cards (deck_id, card_id, quantity, is_commander, condition)
SELECT
  '34508aae-e393-577a-97d8-6259353664af'::uuid,
  card_id,
  quantity,
  is_commander,
  'NM'
FROM tmp_kefka_variant01_picked
ORDER BY ord;

INSERT INTO commander_learned_decks (
  id, commander_name, commander_name_normalized, deck_name,
  source_system, source_ref, source_url, archetype, card_list, card_count,
  score, wincon_primary, wincon_backup, legal_status, notes, metadata,
  is_active, promoted_at, updated_at
) VALUES (
  'a019fb43-6586-5040-b49a-5e0fe6943abb'::uuid,
  'Kefka, Court Mage',
  'kefka, court mage',
  'Kefka Variant 01 - Rafael Paste 2026-06-24',
  'manual_user_deck_registration',
  'kefka_variant01_20260624_ec4ca73a3063',
  'docs/hermes-analysis/manaloom-knowledge/decks/kefka-court-mage/2026-06-24-variant-01-user-decklist.md',
  'grixis-discard-punisher-variant',
  '1 Kefka, Court Mage // Kefka, Ruler of Ruin
1 Aclazotz, Deepest Betrayal // Temple of the Dead
1 Arcane Denial
1 Arcane Signet
1 Archfiend of Ifnir
1 Black Market Connections
1 Blazemire Verge
1 Blood Crypt // Blood Crypt
1 Bloodchief Ascension
1 Bloodletter of Aclazotz
1 Bloodthirsty Conqueror
1 Bojuka Bog
1 Bone Miser
1 Brallin, Skyshark Rider
1 Cathartic Reunion
1 Chaos Warp
1 Command Tower
1 Containment Construct
1 Court of Ambition
1 Crumbling Necropolis
1 Dark Deal
1 Davros, Dalek Creator
1 Deflecting Swat
1 Demolition Field
1 Dragonskull Summit
1 Drossforge Bridge
1 Drowned Catacomb
1 Entropic Battlecruiser
1 Exotic Orchard
1 Exquisite Blood
1 Faithless Looting
1 Feast of Sanity
1 Fell Specter
1 Geth''s Grimoire
1 Glint-Horn Buccaneer
1 Gloomlake Verge
1 Green Goblin, Nemesis
1 Harmonic Prodigy
1 Haunted Ridge
2 Island // Island
1 Kaya''s Ghostform
1 Liliana''s Caress
1 Luxury Suite
1 Magmakin Artillerist
1 Mana Drain
1 Megrim
1 Mistvault Bridge
1 Monument to Endurance
1 Morphic Pool
2 Mountain // Mountain
1 Necrogoyf
1 Niv-Mizzet, Parun
1 Oppression
1 Painful Quandary
1 Phyrexian Arena
1 Psychic Frog
1 Psychosis Crawler
1 Raiders'' Wake
1 Raucous Theater
1 Riverpyre Verge
1 Rogue''s Passage
1 Sangromancer
1 Scalding Tarn
1 Scavenger Grounds
1 Sheoldred // The True Scriptures
1 Sheoldred, the Apocalypse
1 Shipwreck Marsh
1 Silverbluff Bridge
1 Sol Ring
1 Solphim, Mayhem Dominus
1 Steam Vents // Steam Vents
1 Stormcarved Coast
1 Sulfur Falls
1 Surly Badgersaur
2 Swamp // Swamp
1 Swan Song
1 Swiftfoot Boots
1 Syr Konrad, the Grim
1 Teferi''s Time Twist
1 The Haunt of Hightower
1 The Locust God
1 Thundering Falls
1 Tinybones, Bauble Burglar
1 Tinybones, Trinket Thief
1 Toxic Deluge
1 Training Center
1 Underworld Dreams
1 Urborg, Tomb of Yawgmoth
1 Vandalblast
1 Vivi Ornitier
1 Waste Not
1 Watery Grave
1 Whip of Erebos
1 Withering Torment
1 Words of Waste
1 Wound Reflection
1 Xander''s Lounge',
  100,
  0,
  'discard-punisher life drain',
  'wheel and draw-discard payoff engines',
  'registered_pending_card_rule_validation',
  'Manual user-pasted Kefka Grixis discard/punisher deck registered for downstream card validation; not promoted active.',
  '{"deck_hash": "ec4ca73a3063b8af06bd443b5dfb3d2578ae8df8970446a9b7fc8dbc52eeb1ea", "hermes_deck_id": 617, "input_qty": 100, "input_rows": 97, "notes": "Registered from user-pasted Kefka Grixis discard/punisher list. Not promoted active.", "oracle_missing_after_registration": 0, "pg_deck_id": "34508aae-e393-577a-97d8-6259353664af", "pg_learned_id": "a019fb43-6586-5040-b49a-5e0fe6943abb", "registration_scope": "non_lorehold_deck_intake_for_card_validation", "resolved_rows": 97, "source_decklist": "docs/hermes-analysis/manaloom-knowledge/decks/kefka-court-mage/2026-06-24-variant-01-user-decklist.md", "validation_status": "registered_pending_card_rule_validation"}'::jsonb,
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
