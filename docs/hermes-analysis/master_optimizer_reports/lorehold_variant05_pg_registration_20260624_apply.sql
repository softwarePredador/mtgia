\pset pager off
BEGIN;
-- PG register apply for Lorehold Variant 05.
-- Scope: insert/update one decks row, replace its deck_cards rows, upsert one inactive commander_learned_decks row.
DROP TABLE IF EXISTS tmp_lorehold_variant05_input;
CREATE TEMP TABLE tmp_lorehold_variant05_input(ord int, card_name text, quantity int, is_commander boolean);
INSERT INTO tmp_lorehold_variant05_input(ord, card_name, quantity, is_commander) VALUES
  (1, 'Lorehold, the Historian'::text, 1::int, true::boolean),
  (2, 'Adagia, Windswept Bastion'::text, 1::int, false::boolean),
  (3, 'All Is Dust'::text, 1::int, false::boolean),
  (4, 'Ancient Den'::text, 1::int, false::boolean),
  (5, 'Apex of Power'::text, 1::int, false::boolean),
  (6, 'Approach of the Second Sun'::text, 1::int, false::boolean),
  (7, 'Arcane Signet'::text, 1::int, false::boolean),
  (8, 'Artist''s Talent'::text, 1::int, false::boolean),
  (9, 'Assemble the Players'::text, 1::int, false::boolean),
  (10, 'Austere Command'::text, 1::int, false::boolean),
  (11, 'Basalt Monolith'::text, 1::int, false::boolean),
  (12, 'Battlefield Forge'::text, 1::int, false::boolean),
  (13, 'Beacon of Immortality'::text, 1::int, false::boolean),
  (14, 'Bender''s Waterskin'::text, 1::int, false::boolean),
  (15, 'Blasphemous Act'::text, 1::int, false::boolean),
  (16, 'Boros Garrison'::text, 1::int, false::boolean),
  (17, 'Brilliant Restoration'::text, 1::int, false::boolean),
  (18, 'Buried Ruin'::text, 1::int, false::boolean),
  (19, 'Call Forth the Tempest'::text, 1::int, false::boolean),
  (20, 'Clifftop Retreat'::text, 1::int, false::boolean),
  (21, 'Codex Shredder'::text, 1::int, false::boolean),
  (22, 'Command Tower'::text, 1::int, false::boolean),
  (23, 'Crawlspace'::text, 1::int, false::boolean),
  (24, 'Darksteel Citadel'::text, 1::int, false::boolean),
  (25, 'Elegant Parlor'::text, 1::int, false::boolean),
  (26, 'Ensnaring Bridge'::text, 1::int, false::boolean),
  (27, 'Fellwar Stone'::text, 1::int, false::boolean),
  (28, 'Fomori Vault'::text, 1::int, false::boolean),
  (29, 'Generous Gift'::text, 1::int, false::boolean),
  (30, 'Ghoulcaller''s Bell'::text, 1::int, false::boolean),
  (31, 'Goblin Engineer'::text, 1::int, false::boolean),
  (32, 'Great Furnace'::text, 1::int, false::boolean),
  (33, 'Helm of Awakening'::text, 1::int, false::boolean),
  (34, 'Hit the Mother Lode'::text, 1::int, false::boolean),
  (35, 'Improvisation Capstone'::text, 1::int, false::boolean),
  (36, 'Inventors'' Fair'::text, 1::int, false::boolean),
  (37, 'Invincible Hymn'::text, 1::int, false::boolean),
  (38, 'Karn''s Sylex'::text, 1::int, false::boolean),
  (39, 'Karn, the Great Creator'::text, 1::int, false::boolean),
  (40, 'Kayla''s Music Box'::text, 1::int, false::boolean),
  (41, 'Land Tax'::text, 1::int, false::boolean),
  (42, 'Lantern of Insight'::text, 1::int, false::boolean),
  (43, 'Lens of Clarity'::text, 1::int, false::boolean),
  (44, 'Leyline Dowser'::text, 1::int, false::boolean),
  (45, 'Library of Leng'::text, 1::int, false::boolean),
  (46, 'Manifold Key'::text, 1::int, false::boolean),
  (47, 'Millikin'::text, 1::int, false::boolean),
  (48, 'Mizzix''s Mastery'::text, 1::int, false::boolean),
  (49, 'Mountain // Mountain'::text, 3::int, false::boolean),
  (50, 'Mox Opal'::text, 1::int, false::boolean),
  (51, 'Mystic Forge'::text, 1::int, false::boolean),
  (52, 'Norn''s Annex'::text, 1::int, false::boolean),
  (53, 'Open the Vaults'::text, 1::int, false::boolean),
  (54, 'Orcish Spy'::text, 1::int, false::boolean),
  (55, 'Oswald Fiddlebender'::text, 1::int, false::boolean),
  (56, 'Perch Protection'::text, 1::int, false::boolean),
  (57, 'Perpetual Timepiece'::text, 1::int, false::boolean),
  (58, 'Pinnacle Monk // Mystic Peak'::text, 1::int, false::boolean),
  (59, 'Plains // Plains'::text, 4::int, false::boolean),
  (60, 'Plateau'::text, 1::int, false::boolean),
  (61, 'Primal Amulet // Primal Wellspring'::text, 1::int, false::boolean),
  (62, 'Prototype Portal'::text, 1::int, false::boolean),
  (63, 'Pyxis of Pandemonium'::text, 1::int, false::boolean),
  (64, 'Redress Fate'::text, 1::int, false::boolean),
  (65, 'Restoration Seminar'::text, 1::int, false::boolean),
  (66, 'Roar of Reclamation'::text, 1::int, false::boolean),
  (67, 'Rugged Prairie'::text, 1::int, false::boolean),
  (68, 'Rustvale Bridge'::text, 1::int, false::boolean),
  (69, 'Sacred Foundry'::text, 1::int, false::boolean),
  (70, 'Scroll Rack'::text, 1::int, false::boolean),
  (71, 'Sculpting Steel'::text, 1::int, false::boolean),
  (72, 'Sensei''s Divining Top'::text, 1::int, false::boolean),
  (73, 'Silent Arbiter'::text, 1::int, false::boolean),
  (74, 'Sol Ring'::text, 1::int, false::boolean),
  (75, 'Spectator Seating'::text, 1::int, false::boolean),
  (76, 'Spire of Industry'::text, 1::int, false::boolean),
  (77, 'Squee, Goblin Nabob'::text, 1::int, false::boolean),
  (78, 'Stroke of Midnight'::text, 1::int, false::boolean),
  (79, 'Sunbaked Canyon'::text, 1::int, false::boolean),
  (80, 'Sunbillow Verge'::text, 1::int, false::boolean),
  (81, 'Swords to Plowshares'::text, 1::int, false::boolean),
  (82, 'Tezzeret, Cruel Captain'::text, 1::int, false::boolean),
  (83, 'The Mycosynth Gardens'::text, 1::int, false::boolean),
  (84, 'The Warring Triad'::text, 1::int, false::boolean),
  (85, 'Tocasia''s Dig Site'::text, 1::int, false::boolean),
  (86, 'Triumphant Reckoning'::text, 1::int, false::boolean),
  (87, 'Unstable Glyphbridge // Sandswirl Wanderglyph'::text, 1::int, false::boolean),
  (88, 'Unwinding Clock'::text, 1::int, false::boolean),
  (89, 'Urza''s Saga'::text, 1::int, false::boolean),
  (90, 'Valakut Awakening // Valakut Stoneforge'::text, 1::int, false::boolean),
  (91, 'Vanquish the Horde'::text, 1::int, false::boolean),
  (92, 'Victory Chimes'::text, 1::int, false::boolean),
  (93, 'Voltaic Key'::text, 1::int, false::boolean),
  (94, 'Wake the Past'::text, 1::int, false::boolean),
  (95, 'Wand of Vertebrae'::text, 1::int, false::boolean);

DROP TABLE IF EXISTS tmp_lorehold_variant05_picked;
CREATE TEMP TABLE tmp_lorehold_variant05_picked AS
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
  FROM tmp_lorehold_variant05_input i
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
  SELECT COUNT(*) INTO missing_count FROM tmp_lorehold_variant05_picked WHERE card_id IS NULL;
  IF missing_count <> 0 THEN
    RAISE EXCEPTION 'Refusing Lorehold Variant 05 PG registration: % cards missing from cards catalog', missing_count;
  END IF;
  SELECT COALESCE(SUM(quantity),0)::int INTO total_qty FROM tmp_lorehold_variant05_picked;
  SELECT COALESCE(SUM(CASE WHEN is_commander THEN quantity ELSE 0 END),0)::int INTO commander_qty FROM tmp_lorehold_variant05_picked;
  IF total_qty <> 100 THEN
    RAISE EXCEPTION 'Refusing Lorehold Variant 05 PG registration: expected qty 100, got %', total_qty;
  END IF;
  IF commander_qty <> 1 THEN
    RAISE EXCEPTION 'Refusing Lorehold Variant 05 PG registration: expected commander qty 1, got %', commander_qty;
  END IF;
END $$;

INSERT INTO decks (
  id, user_id, name, format, description, is_public, synergy_score,
  strengths, weaknesses, archetype, bracket
) VALUES (
  '8aa57962-3a3e-5351-89fd-e4651456a3bd'::uuid,
  NULL,
  'PG REGISTERED Lorehold Variant 05 - Rafael Paste 2026-06-24',
  'commander',
  'Manual Lorehold deck registration for card validation. deck_hash=5154c88a8b0bff4bff121c164b0aff180b4515e52d46a3fac8b972c4ee026836; source=docs/hermes-analysis/manaloom-knowledge/decks/lorehold-the-historian/2026-06-24-variant-05-user-decklist.md',
  false,
  0,
  'Pending validation: user-pasted Lorehold artifact-control deck registered for card logic review.',
  'Pending card-rule validation; not promoted as definitive deck.',
  'artifact-control-variant',
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

DELETE FROM deck_cards WHERE deck_id = '8aa57962-3a3e-5351-89fd-e4651456a3bd'::uuid;

INSERT INTO deck_cards (deck_id, card_id, quantity, is_commander, condition)
SELECT
  '8aa57962-3a3e-5351-89fd-e4651456a3bd'::uuid,
  card_id,
  quantity,
  is_commander,
  'NM'
FROM tmp_lorehold_variant05_picked
ORDER BY ord;

INSERT INTO commander_learned_decks (
  id, commander_name, commander_name_normalized, deck_name,
  source_system, source_ref, source_url, archetype, card_list, card_count,
  score, wincon_primary, wincon_backup, legal_status, notes, metadata,
  is_active, promoted_at, updated_at
) VALUES (
  '757f8ebd-10a4-5f33-82a1-749603afa7e1'::uuid,
  'Lorehold, the Historian',
  'lorehold, the historian',
  'Lorehold Variant 05 - Rafael Paste 2026-06-24',
  'manual_user_deck_registration',
  'lorehold_variant05_20260624_5154c88a8b0b',
  'docs/hermes-analysis/manaloom-knowledge/decks/lorehold-the-historian/2026-06-24-variant-05-user-decklist.md',
  'artifact-control-variant',
  '1 Lorehold, the Historian
1 Adagia, Windswept Bastion
1 All Is Dust
1 Ancient Den
1 Apex of Power
1 Approach of the Second Sun
1 Arcane Signet
1 Artist''s Talent
1 Assemble the Players
1 Austere Command
1 Basalt Monolith
1 Battlefield Forge
1 Beacon of Immortality
1 Bender''s Waterskin
1 Blasphemous Act
1 Boros Garrison
1 Brilliant Restoration
1 Buried Ruin
1 Call Forth the Tempest
1 Clifftop Retreat
1 Codex Shredder
1 Command Tower
1 Crawlspace
1 Darksteel Citadel
1 Elegant Parlor
1 Ensnaring Bridge
1 Fellwar Stone
1 Fomori Vault
1 Generous Gift
1 Ghoulcaller''s Bell
1 Goblin Engineer
1 Great Furnace
1 Helm of Awakening
1 Hit the Mother Lode
1 Improvisation Capstone
1 Inventors'' Fair
1 Invincible Hymn
1 Karn''s Sylex
1 Karn, the Great Creator
1 Kayla''s Music Box
1 Land Tax
1 Lantern of Insight
1 Lens of Clarity
1 Leyline Dowser
1 Library of Leng
1 Manifold Key
1 Millikin
1 Mizzix''s Mastery
3 Mountain // Mountain
1 Mox Opal
1 Mystic Forge
1 Norn''s Annex
1 Open the Vaults
1 Orcish Spy
1 Oswald Fiddlebender
1 Perch Protection
1 Perpetual Timepiece
1 Pinnacle Monk // Mystic Peak
4 Plains // Plains
1 Plateau
1 Primal Amulet // Primal Wellspring
1 Prototype Portal
1 Pyxis of Pandemonium
1 Redress Fate
1 Restoration Seminar
1 Roar of Reclamation
1 Rugged Prairie
1 Rustvale Bridge
1 Sacred Foundry
1 Scroll Rack
1 Sculpting Steel
1 Sensei''s Divining Top
1 Silent Arbiter
1 Sol Ring
1 Spectator Seating
1 Spire of Industry
1 Squee, Goblin Nabob
1 Stroke of Midnight
1 Sunbaked Canyon
1 Sunbillow Verge
1 Swords to Plowshares
1 Tezzeret, Cruel Captain
1 The Mycosynth Gardens
1 The Warring Triad
1 Tocasia''s Dig Site
1 Triumphant Reckoning
1 Unstable Glyphbridge // Sandswirl Wanderglyph
1 Unwinding Clock
1 Urza''s Saga
1 Valakut Awakening // Valakut Stoneforge
1 Vanquish the Horde
1 Victory Chimes
1 Voltaic Key
1 Wake the Past
1 Wand of Vertebrae',
  100,
  NULL,
  'Approach of the Second Sun',
  'Mizzix''s Mastery / Brilliant Restoration / Triumphant Reckoning',
  'registered_pending_card_rule_validation',
  'Manual user-pasted Lorehold artifact-control deck registered for downstream card validation; not promoted active.',
  '{"deck_hash": "5154c88a8b0bff4bff121c164b0aff180b4515e52d46a3fac8b972c4ee026836", "hermes_deck_id": 610, "notes": "Registered from user-pasted Lorehold artifact-control list. Not promoted as active learned deck.", "oracle_missing_after_registration": 0, "pg_deck_id": "8aa57962-3a3e-5351-89fd-e4651456a3bd", "registration_scope": "deck_intake_for_card_validation", "source_decklist": "docs/hermes-analysis/manaloom-knowledge/decks/lorehold-the-historian/2026-06-24-variant-05-user-decklist.md", "staging_report": "docs/hermes-analysis/master_optimizer_reports/lorehold_variant_staging_20260624_121428.json", "staging_warning_count": 29, "validation_status": "registered_pending_card_rule_validation"}'::jsonb,
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
