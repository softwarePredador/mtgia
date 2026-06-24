\pset pager off
BEGIN;
-- PG register apply for Sauron Variant 01.
-- Scope: insert/update one decks row, replace its deck_cards rows, upsert one inactive commander_learned_decks row.
DROP TABLE IF EXISTS tmp_sauron_variant01_input;
CREATE TEMP TABLE tmp_sauron_variant01_input(ord int, card_name text, quantity int, is_commander boolean);
INSERT INTO tmp_sauron_variant01_input(ord, card_name, quantity, is_commander) VALUES
  (1, 'Sauron, the Dark Lord'::text, 1::int, true::boolean),
  (2, 'Afterlife from the Loam'::text, 1::int, false::boolean),
  (3, 'An Offer You Can''t Refuse'::text, 1::int, false::boolean),
  (4, 'Ancient Tomb'::text, 1::int, false::boolean),
  (5, 'Anger'::text, 1::int, false::boolean),
  (6, 'Animate Dead'::text, 1::int, false::boolean),
  (7, 'Arcane Signet'::text, 1::int, false::boolean),
  (8, 'Archfiend of Ifnir'::text, 1::int, false::boolean),
  (9, 'Arid Mesa'::text, 1::int, false::boolean),
  (10, 'Bilbo, Retired Burglar'::text, 1::int, false::boolean),
  (11, 'Blood Crypt'::text, 1::int, false::boolean),
  (12, 'Blood for the Blood God!'::text, 1::int, false::boolean),
  (13, 'Bloodstained Mire'::text, 1::int, false::boolean),
  (14, 'Cabal Coffers'::text, 1::int, false::boolean),
  (15, 'Call of the Ring'::text, 1::int, false::boolean),
  (16, 'Cavern of Souls'::text, 1::int, false::boolean),
  (17, 'Cavern-Hoard Dragon'::text, 1::int, false::boolean),
  (18, 'City of Brass'::text, 1::int, false::boolean),
  (19, 'Command Tower'::text, 1::int, false::boolean),
  (20, 'Culling the Weak'::text, 1::int, false::boolean),
  (21, 'Cursed Mirror'::text, 1::int, false::boolean),
  (22, 'Damnation'::text, 1::int, false::boolean),
  (23, 'Dark Ritual'::text, 1::int, false::boolean),
  (24, 'Devastating Onslaught'::text, 1::int, false::boolean),
  (25, 'Diabolic Intent'::text, 1::int, false::boolean),
  (26, 'Dismember'::text, 1::int, false::boolean),
  (27, 'Displacer Kitten'::text, 1::int, false::boolean),
  (28, 'Dragonskull Summit'::text, 1::int, false::boolean),
  (29, 'Entomb'::text, 1::int, false::boolean),
  (30, 'Fellwar Stone'::text, 1::int, false::boolean),
  (31, 'Flooded Strand'::text, 1::int, false::boolean),
  (32, 'Gemstone Caverns'::text, 1::int, false::boolean),
  (33, 'Hullbreaker Horror'::text, 1::int, false::boolean),
  (34, 'Island'::text, 2::int, false::boolean),
  (35, 'Likeness Looter'::text, 1::int, false::boolean),
  (36, 'Living Death'::text, 1::int, false::boolean),
  (37, 'Luxury Suite'::text, 1::int, false::boolean),
  (38, 'Mana Drain'::text, 1::int, false::boolean),
  (39, 'Misty Rainforest'::text, 1::int, false::boolean),
  (40, 'Morphic Pool'::text, 1::int, false::boolean),
  (41, 'Mount Doom'::text, 1::int, false::boolean),
  (42, 'Mountain'::text, 2::int, false::boolean),
  (43, 'Nazgûl'::text, 9::int, false::boolean),
  (44, 'Necromancy'::text, 1::int, false::boolean),
  (45, 'Orcish Bowmasters'::text, 1::int, false::boolean),
  (46, 'Pact of Negation'::text, 1::int, false::boolean),
  (47, 'Phyrexian Tower'::text, 1::int, false::boolean),
  (48, 'Polluted Delta'::text, 1::int, false::boolean),
  (49, 'Razaketh, the Foulblooded'::text, 1::int, false::boolean),
  (50, 'Reanimate'::text, 1::int, false::boolean),
  (51, 'Reflecting Pool'::text, 1::int, false::boolean),
  (52, 'Relic of Sauron'::text, 1::int, false::boolean),
  (53, 'Rise of the Dark Realms'::text, 1::int, false::boolean),
  (54, 'Ruthless Technomancer'::text, 1::int, false::boolean),
  (55, 'Scalding Tarn'::text, 1::int, false::boolean),
  (56, 'Seething Landscape'::text, 1::int, false::boolean),
  (57, 'Shadowspear'::text, 1::int, false::boolean),
  (58, 'Sheoldred, the Apocalypse'::text, 1::int, false::boolean),
  (59, 'Sol Ring'::text, 1::int, false::boolean),
  (60, 'Soothing of Sméagol'::text, 1::int, false::boolean),
  (61, 'Spiteful Banditry'::text, 1::int, false::boolean),
  (62, 'Starwinder'::text, 1::int, false::boolean),
  (63, 'Steam Vents'::text, 1::int, false::boolean),
  (64, 'Strix Serenade'::text, 1::int, false::boolean),
  (65, 'Sulfurous Springs'::text, 1::int, false::boolean),
  (66, 'Swamp'::text, 2::int, false::boolean),
  (67, 'Swan Song'::text, 1::int, false::boolean),
  (68, 'Talisman of Creativity'::text, 1::int, false::boolean),
  (69, 'Talisman of Dominance'::text, 1::int, false::boolean),
  (70, 'Talisman of Indulgence'::text, 1::int, false::boolean),
  (71, 'Terror of the Peaks'::text, 1::int, false::boolean),
  (72, 'The Balrog of Moria'::text, 1::int, false::boolean),
  (73, 'The Black Gate'::text, 1::int, false::boolean),
  (74, 'The One Ring'::text, 1::int, false::boolean),
  (75, 'The Ozolith'::text, 1::int, false::boolean),
  (76, 'The Reaver Cleaver'::text, 1::int, false::boolean),
  (77, 'The Soul Stone'::text, 1::int, false::boolean),
  (78, 'Toxic Deluge'::text, 1::int, false::boolean),
  (79, 'Underground River'::text, 1::int, false::boolean),
  (80, 'Urborg, Tomb of Yawgmoth'::text, 1::int, false::boolean),
  (81, 'Urza''s Saga'::text, 1::int, false::boolean),
  (82, 'Verdant Catacombs'::text, 1::int, false::boolean),
  (83, 'Victimize'::text, 1::int, false::boolean),
  (84, 'Volrath''s Stronghold'::text, 1::int, false::boolean),
  (85, 'Warren Soultrader'::text, 1::int, false::boolean),
  (86, 'Watery Grave'::text, 1::int, false::boolean),
  (87, 'Windfall'::text, 1::int, false::boolean),
  (88, 'Withering Torment'::text, 1::int, false::boolean),
  (89, 'Wooded Foothills'::text, 1::int, false::boolean);

DROP TABLE IF EXISTS tmp_sauron_variant01_picked;
CREATE TEMP TABLE tmp_sauron_variant01_picked AS
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
  FROM tmp_sauron_variant01_input i
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
  SELECT COUNT(*) INTO missing_count FROM tmp_sauron_variant01_picked WHERE card_id IS NULL;
  IF missing_count <> 0 THEN
    RAISE EXCEPTION 'Refusing Sauron Variant 01 PG registration: % cards missing from cards catalog', missing_count;
  END IF;
  SELECT COALESCE(SUM(quantity),0)::int INTO total_qty FROM tmp_sauron_variant01_picked;
  SELECT COALESCE(SUM(CASE WHEN is_commander THEN quantity ELSE 0 END),0)::int INTO commander_qty FROM tmp_sauron_variant01_picked;
  IF total_qty <> 100 THEN
    RAISE EXCEPTION 'Refusing Sauron Variant 01 PG registration: expected qty 100, got %', total_qty;
  END IF;
  IF commander_qty <> 1 THEN
    RAISE EXCEPTION 'Refusing Sauron Variant 01 PG registration: expected commander qty 1, got %', commander_qty;
  END IF;
END $$;

INSERT INTO decks (
  id, user_id, name, format, description, is_public, synergy_score,
  strengths, weaknesses, archetype, bracket
) VALUES (
  'c2230827-7963-52e4-a6ba-298d7be3478a'::uuid,
  NULL,
  'PG REGISTERED Sauron Variant 01 - Rafael Paste 2026-06-24',
  'commander',
  'Manual non-Lorehold deck registration for card validation. deck_hash=6aa4f012e11d7122d4652beead17c02c7e06e5e872de9932ab914f3b5556cadc; source=docs/hermes-analysis/manaloom-knowledge/decks/sauron-the-dark-lord/2026-06-24-variant-01-user-decklist.md',
  false,
  0,
  'Pending validation: user-pasted Sauron Grixis reanimator/ring-control deck registered for card logic review.',
  'Pending card-rule validation; not promoted as definitive deck.',
  'grixis-reanimator-ring-control-variant',
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

DELETE FROM deck_cards WHERE deck_id = 'c2230827-7963-52e4-a6ba-298d7be3478a'::uuid;

INSERT INTO deck_cards (deck_id, card_id, quantity, is_commander, condition)
SELECT
  'c2230827-7963-52e4-a6ba-298d7be3478a'::uuid,
  card_id,
  quantity,
  is_commander,
  'NM'
FROM tmp_sauron_variant01_picked
ORDER BY ord;

INSERT INTO commander_learned_decks (
  id, commander_name, commander_name_normalized, deck_name,
  source_system, source_ref, source_url, archetype, card_list, card_count,
  score, wincon_primary, wincon_backup, legal_status, notes, metadata,
  is_active, promoted_at, updated_at
) VALUES (
  '28600f83-7925-5ce8-99ed-833d7c00febc'::uuid,
  'Sauron, the Dark Lord',
  'sauron, the dark lord',
  'Sauron Variant 01 - Rafael Paste 2026-06-24',
  'manual_user_deck_registration',
  'sauron_variant01_20260624_6aa4f012e11d',
  'docs/hermes-analysis/manaloom-knowledge/decks/sauron-the-dark-lord/2026-06-24-variant-01-user-decklist.md',
  'grixis-reanimator-ring-control-variant',
  '1 Sauron, the Dark Lord
1 Afterlife from the Loam
1 An Offer You Can''t Refuse
1 Ancient Tomb
1 Anger
1 Animate Dead
1 Arcane Signet
1 Archfiend of Ifnir
1 Arid Mesa
1 Bilbo, Retired Burglar
1 Blood Crypt // Blood Crypt
1 Blood for the Blood God!
1 Bloodstained Mire
1 Cabal Coffers
1 Call of the Ring
1 Cavern of Souls
1 Cavern-Hoard Dragon
1 City of Brass
1 Command Tower
1 Culling the Weak
1 Cursed Mirror
1 Damnation
1 Dark Ritual
1 Devastating Onslaught
1 Diabolic Intent
1 Dismember
1 Displacer Kitten
1 Dragonskull Summit
1 Entomb
1 Fellwar Stone
1 Flooded Strand
1 Gemstone Caverns
1 Hullbreaker Horror
2 Island // Island
1 Likeness Looter
1 Living Death
1 Luxury Suite
1 Mana Drain
1 Misty Rainforest
1 Morphic Pool
1 Mount Doom
2 Mountain // Mountain
9 Nazgûl
1 Necromancy
1 Orcish Bowmasters
1 Pact of Negation
1 Phyrexian Tower
1 Polluted Delta
1 Razaketh, the Foulblooded
1 Reanimate
1 Reflecting Pool
1 Relic of Sauron
1 Rise of the Dark Realms
1 Ruthless Technomancer
1 Scalding Tarn
1 Seething Landscape
1 Shadowspear
1 Sheoldred, the Apocalypse
1 Sol Ring
1 Soothing of Sméagol
1 Spiteful Banditry
1 Starwinder
1 Steam Vents // Steam Vents
1 Strix Serenade
1 Sulfurous Springs
2 Swamp // Swamp
1 Swan Song
1 Talisman of Creativity
1 Talisman of Dominance
1 Talisman of Indulgence
1 Terror of the Peaks
1 The Balrog of Moria
1 The Black Gate
1 The One Ring
1 The Ozolith
1 The Reaver Cleaver
1 The Soul Stone
1 Toxic Deluge
1 Underground River
1 Urborg, Tomb of Yawgmoth
1 Urza''s Saga
1 Verdant Catacombs
1 Victimize
1 Volrath''s Stronghold
1 Warren Soultrader
1 Watery Grave
1 Windfall
1 Withering Torment
1 Wooded Foothills',
  100,
  0,
  'Sauron ring-control and mass reanimation',
  'Nazgul pressure plus Grixis reanimator haymakers',
  'registered_pending_card_rule_validation',
  'Registered from user paste for catalog/card-rule validation. Inactive learned row; not a definitive promoted deck.',
  '{"deck_hash": "6aa4f012e11d7122d4652beead17c02c7e06e5e872de9932ab914f3b5556cadc", "hermes_deck_id": 620, "intake_date": "2026-06-24", "resolution_artifact": "docs/hermes-analysis/master_optimizer_reports/sauron_variant01_resolution_20260624.json", "scope": "non-Lorehold deck intake only; no deck swap; learned deck inactive", "source_path": "docs/hermes-analysis/manaloom-knowledge/decks/sauron-the-dark-lord/2026-06-24-variant-01-user-decklist.md", "source_ref": "sauron_variant01_20260624_6aa4f012e11d"}'::jsonb,
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
