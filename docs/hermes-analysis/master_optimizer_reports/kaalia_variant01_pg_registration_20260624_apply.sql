\pset pager off
BEGIN;
-- PG register apply for Kaalia Variant 01.
-- Scope: insert/update one decks row, replace its deck_cards rows, upsert one inactive commander_learned_decks row.
DROP TABLE IF EXISTS tmp_kaalia_variant01_input;
CREATE TEMP TABLE tmp_kaalia_variant01_input(ord int, card_name text, quantity int, is_commander boolean);
INSERT INTO tmp_kaalia_variant01_input(ord, card_name, quantity, is_commander) VALUES
  (1, 'Kaalia of the Vast'::text, 1::int, true::boolean),
  (2, 'Alicia Masters, Skilled Sculptor'::text, 1::int, false::boolean),
  (3, 'Ancient Tomb'::text, 1::int, false::boolean),
  (4, 'Arcane Signet'::text, 1::int, false::boolean),
  (5, 'Archaeomancer''s Map'::text, 1::int, false::boolean),
  (6, 'Ardenn, Intrepid Archaeologist'::text, 1::int, false::boolean),
  (7, 'Arid Mesa'::text, 1::int, false::boolean),
  (8, 'Basalt Monolith'::text, 1::int, false::boolean),
  (9, 'Biotransference'::text, 1::int, false::boolean),
  (10, 'Birgi, God of Storytelling'::text, 1::int, false::boolean),
  (11, 'Blightsteel Colossus'::text, 1::int, false::boolean),
  (12, 'Blood Crypt'::text, 1::int, false::boolean),
  (13, 'Bloodstained Mire'::text, 1::int, false::boolean),
  (14, 'Bloodthirster'::text, 1::int, false::boolean),
  (15, 'Burnt Offering'::text, 1::int, false::boolean),
  (16, 'Cabal Ritual'::text, 1::int, false::boolean),
  (17, 'City of Traitors'::text, 1::int, false::boolean),
  (18, 'Clifftop Retreat'::text, 1::int, false::boolean),
  (19, 'Command Tower'::text, 1::int, false::boolean),
  (20, 'Culling the Weak'::text, 1::int, false::boolean),
  (21, 'Dark Ritual'::text, 1::int, false::boolean),
  (22, 'Delney, Streetwise Lookout'::text, 1::int, false::boolean),
  (23, 'Demonic Tutor'::text, 1::int, false::boolean),
  (24, 'Desperate Ritual'::text, 1::int, false::boolean),
  (25, 'Diabolic Intent'::text, 1::int, false::boolean),
  (26, 'Dragonskull Summit'::text, 1::int, false::boolean),
  (27, 'Elegant Parlor'::text, 1::int, false::boolean),
  (28, 'Enlightened Tutor'::text, 1::int, false::boolean),
  (29, 'Esper Sentinel'::text, 1::int, false::boolean),
  (30, 'Fable of the Mirror-Breaker'::text, 1::int, false::boolean),
  (31, 'Fabled Passage'::text, 1::int, false::boolean),
  (32, 'Forge Anew'::text, 1::int, false::boolean),
  (33, 'Genji Glove'::text, 1::int, false::boolean),
  (34, 'Godless Shrine'::text, 1::int, false::boolean),
  (35, 'Grand Abolisher'::text, 1::int, false::boolean),
  (36, 'Grim Monolith'::text, 1::int, false::boolean),
  (37, 'Grim Tutor'::text, 1::int, false::boolean),
  (38, 'Hammer of Nazahn'::text, 1::int, false::boolean),
  (39, 'Haunted Ridge'::text, 1::int, false::boolean),
  (40, 'Imperial Seal'::text, 1::int, false::boolean),
  (41, 'Infernal Plunge'::text, 1::int, false::boolean),
  (42, 'Isolated Chapel'::text, 1::int, false::boolean),
  (43, 'Jeska''s Will'::text, 1::int, false::boolean),
  (44, 'Karlach, Fury of Avernus'::text, 1::int, false::boolean),
  (45, 'Lightning Greaves'::text, 1::int, false::boolean),
  (46, 'Lightning, Army of One'::text, 1::int, false::boolean),
  (47, 'Mana Vault'::text, 1::int, false::boolean),
  (48, 'Marsh Flats'::text, 1::int, false::boolean),
  (49, 'Maskwood Nexus'::text, 1::int, false::boolean),
  (50, 'Master of Cruelties'::text, 1::int, false::boolean),
  (51, 'Mjölnir, Hammer of Thor'::text, 1::int, false::boolean),
  (52, 'Monologue Tax'::text, 1::int, false::boolean),
  (53, 'Mountain'::text, 2::int, false::boolean),
  (54, 'Necrodominance'::text, 1::int, false::boolean),
  (55, 'Necropotence'::text, 1::int, false::boolean),
  (56, 'Ornithopter of Paradise'::text, 1::int, false::boolean),
  (57, 'Oswald Fiddlebender'::text, 1::int, false::boolean),
  (58, 'Plains'::text, 9::int, false::boolean),
  (59, 'Professional Face-Breaker'::text, 1::int, false::boolean),
  (60, 'Puresteel Paladin'::text, 1::int, false::boolean),
  (61, 'Pyretic Ritual'::text, 1::int, false::boolean),
  (62, 'Ragavan, Nimble Pilferer'::text, 1::int, false::boolean),
  (63, 'Ranger-Captain of Eos'::text, 1::int, false::boolean),
  (64, 'Raucous Theater'::text, 1::int, false::boolean),
  (65, 'Razaketh, the Foulblooded'::text, 1::int, false::boolean),
  (66, 'Rune-Scarred Demon'::text, 1::int, false::boolean),
  (67, 'Sacred Foundry'::text, 1::int, false::boolean),
  (68, 'Savai Triome'::text, 1::int, false::boolean),
  (69, 'Shadowy Backstreet'::text, 1::int, false::boolean),
  (70, 'Shattered Sanctum'::text, 1::int, false::boolean),
  (71, 'Sigarda''s Aid'::text, 1::int, false::boolean),
  (72, 'Silence'::text, 1::int, false::boolean),
  (73, 'Smothering Tithe'::text, 1::int, false::boolean),
  (74, 'Smuggler''s Share'::text, 1::int, false::boolean),
  (75, 'Sol Ring'::text, 1::int, false::boolean),
  (76, 'Sram, Senior Edificer'::text, 1::int, false::boolean),
  (77, 'Steelshaper''s Gift'::text, 1::int, false::boolean),
  (78, 'Stoneforge Mystic'::text, 1::int, false::boolean),
  (79, 'Strike It Rich'::text, 1::int, false::boolean),
  (80, 'Sundown Pass'::text, 1::int, false::boolean),
  (81, 'Sunforger'::text, 1::int, false::boolean),
  (82, 'Swamp'::text, 3::int, false::boolean),
  (83, 'The One Ring'::text, 1::int, false::boolean),
  (84, 'The Seriema'::text, 1::int, false::boolean),
  (85, 'Trouble in Pairs'::text, 1::int, false::boolean),
  (86, 'Vampiric Tutor'::text, 1::int, false::boolean),
  (87, 'Voice of Victory'::text, 1::int, false::boolean),
  (88, 'Vorpal Sword'::text, 1::int, false::boolean),
  (89, 'Wishclaw Talisman'::text, 1::int, false::boolean);

DROP TABLE IF EXISTS tmp_kaalia_variant01_picked;
CREATE TEMP TABLE tmp_kaalia_variant01_picked AS
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
  FROM tmp_kaalia_variant01_input i
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
  SELECT COUNT(*) INTO missing_count FROM tmp_kaalia_variant01_picked WHERE card_id IS NULL;
  IF missing_count <> 0 THEN
    RAISE EXCEPTION 'Refusing Kaalia Variant 01 PG registration: % cards missing from cards catalog', missing_count;
  END IF;
  SELECT COALESCE(SUM(quantity),0)::int INTO total_qty FROM tmp_kaalia_variant01_picked;
  SELECT COALESCE(SUM(CASE WHEN is_commander THEN quantity ELSE 0 END),0)::int INTO commander_qty FROM tmp_kaalia_variant01_picked;
  IF total_qty <> 100 THEN
    RAISE EXCEPTION 'Refusing Kaalia Variant 01 PG registration: expected qty 100, got %', total_qty;
  END IF;
  IF commander_qty <> 1 THEN
    RAISE EXCEPTION 'Refusing Kaalia Variant 01 PG registration: expected commander qty 1, got %', commander_qty;
  END IF;
END $$;

INSERT INTO decks (
  id, user_id, name, format, description, is_public, synergy_score,
  strengths, weaknesses, archetype, bracket
) VALUES (
  'b629f227-b2b2-5e71-9854-99d345a8e01c'::uuid,
  NULL,
  'PG REGISTERED Kaalia Variant 01 - Rafael Paste 2026-06-24',
  'commander',
  'Manual non-Lorehold deck registration for card validation. deck_hash=b895928feb6f33ab62223690fff760f8eebe0a5c2c12c013be4e9ffe02d96656; source=docs/hermes-analysis/manaloom-knowledge/decks/kaalia-of-the-vast/2026-06-24-variant-01-user-decklist.md; catalog_backfill=Alicia Masters, Skilled Sculptor',
  false,
  0,
  'Pending validation: user-pasted Kaalia Mardu cheat/equipment/combo deck registered for card logic review.',
  'Pending card-rule validation; not promoted as definitive deck.',
  'mardu-cheat-equipment-combo-variant',
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

DELETE FROM deck_cards WHERE deck_id = 'b629f227-b2b2-5e71-9854-99d345a8e01c'::uuid;

INSERT INTO deck_cards (deck_id, card_id, quantity, is_commander, condition)
SELECT
  'b629f227-b2b2-5e71-9854-99d345a8e01c'::uuid,
  card_id,
  quantity,
  is_commander,
  'NM'
FROM tmp_kaalia_variant01_picked
ORDER BY ord;

INSERT INTO commander_learned_decks (
  id, commander_name, commander_name_normalized, deck_name,
  source_system, source_ref, source_url, archetype, card_list, card_count,
  score, wincon_primary, wincon_backup, legal_status, notes, metadata,
  is_active, promoted_at, updated_at
) VALUES (
  'cb2e2acf-933c-5a01-8fab-5bad84122211'::uuid,
  'Kaalia of the Vast',
  'kaalia of the vast',
  'Kaalia Variant 01 - Rafael Paste 2026-06-24',
  'manual_user_deck_registration',
  'kaalia_variant01_20260624_b895928feb6f',
  'docs/hermes-analysis/manaloom-knowledge/decks/kaalia-of-the-vast/2026-06-24-variant-01-user-decklist.md',
  'mardu-cheat-equipment-combo-variant',
  '1 Kaalia of the Vast
1 Alicia Masters, Skilled Sculptor
1 Ancient Tomb
1 Arcane Signet
1 Archaeomancer''s Map
1 Ardenn, Intrepid Archaeologist
1 Arid Mesa
1 Basalt Monolith
1 Biotransference
1 Birgi, God of Storytelling // Harnfel, Horn of Bounty
1 Blightsteel Colossus // Blightsteel Colossus
1 Blood Crypt // Blood Crypt
1 Bloodstained Mire
1 Bloodthirster
1 Burnt Offering
1 Cabal Ritual
1 City of Traitors
1 Clifftop Retreat
1 Command Tower
1 Culling the Weak
1 Dark Ritual
1 Delney, Streetwise Lookout
1 Demonic Tutor
1 Desperate Ritual
1 Diabolic Intent
1 Dragonskull Summit
1 Elegant Parlor
1 Enlightened Tutor
1 Esper Sentinel
1 Fable of the Mirror-Breaker // Reflection of Kiki-Jiki
1 Fabled Passage
1 Forge Anew
1 Genji Glove
1 Godless Shrine
1 Grand Abolisher
1 Grim Monolith
1 Grim Tutor
1 Hammer of Nazahn
1 Haunted Ridge
1 Imperial Seal
1 Infernal Plunge
1 Isolated Chapel
1 Jeska''s Will
1 Karlach, Fury of Avernus
1 Lightning Greaves
1 Lightning, Army of One
1 Mana Vault
1 Marsh Flats
1 Maskwood Nexus
1 Master of Cruelties
1 Mjölnir, Hammer of Thor
1 Monologue Tax
2 Mountain // Mountain
1 Necrodominance
1 Necropotence
1 Ornithopter of Paradise
1 Oswald Fiddlebender
9 Plains // Plains
1 Professional Face-Breaker
1 Puresteel Paladin
1 Pyretic Ritual
1 Ragavan, Nimble Pilferer
1 Ranger-Captain of Eos
1 Raucous Theater
1 Razaketh, the Foulblooded
1 Rune-Scarred Demon
1 Sacred Foundry
1 Savai Triome
1 Shadowy Backstreet
1 Shattered Sanctum
1 Sigarda''s Aid
1 Silence
1 Smothering Tithe
1 Smuggler''s Share
1 Sol Ring
1 Sram, Senior Edificer
1 Steelshaper''s Gift
1 Stoneforge Mystic
1 Strike It Rich
1 Sundown Pass
1 Sunforger
3 Swamp // Swamp
1 The One Ring
1 The Seriema
1 Trouble in Pairs
1 Vampiric Tutor
1 Voice of Victory
1 Vorpal Sword
1 Wishclaw Talisman',
  100,
  0,
  'Kaalia cheat-attack demons angels dragons and burst combat damage',
  'equipment tutor package plus ritual acceleration into haymakers',
  'registered_pending_card_rule_validation',
  'Manual user-pasted Kaalia Mardu cheat/equipment/combo deck registered for downstream card validation; not promoted active.',
  '{"catalog_backfill": "docs/hermes-analysis/master_optimizer_reports/kaalia_variant01_alicia_masters_card_backfill_20260624_summary.md", "catalog_backfill_card": "Alicia Masters, Skilled Sculptor", "catalog_backfill_scryfall_id": "3db94749-340c-4454-a15d-ba6353e0c4a4", "deck_hash": "b895928feb6f33ab62223690fff760f8eebe0a5c2c12c013be4e9ffe02d96656", "hermes_deck_id": 619, "input_qty": 100, "input_rows": 89, "notes": "Registered from user-pasted Kaalia Mardu cheat/equipment/combo list. Not promoted active.", "oracle_missing_after_registration": 0, "pg_deck_id": "b629f227-b2b2-5e71-9854-99d345a8e01c", "pg_learned_id": "cb2e2acf-933c-5a01-8fab-5bad84122211", "registration_scope": "non_lorehold_deck_intake_for_card_validation", "resolved_rows": 89, "source_decklist": "docs/hermes-analysis/manaloom-knowledge/decks/kaalia-of-the-vast/2026-06-24-variant-01-user-decklist.md", "validation_status": "registered_pending_card_rule_validation"}'::jsonb,
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
