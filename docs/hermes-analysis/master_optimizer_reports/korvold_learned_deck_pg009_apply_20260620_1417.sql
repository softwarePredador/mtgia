-- PG009 apply: promote accepted Korvold commander_reference_decks corpus and
-- deactivate the stale partial EDHREC learned_deck:7 row.
--
-- Source of truth for the replacement row:
-- commander_reference_decks/source_deck_key =
-- edhrec_korvold_fae_cursed_king_default_average_sprint3_lot_b_2026_05_14
--
-- This does not touch user decks or deck_cards.

BEGIN;

DO $$
DECLARE
  old_partial_total_count integer;
  old_partial_active_count integer;
  replacement_active_count integer;
  source_deck_count integer;
  source_quantity integer;
  source_commander_quantity integer;
  source_unresolved_count integer;
  source_off_color_count integer;
BEGIN
  SELECT COUNT(*)
  INTO old_partial_total_count
  FROM commander_learned_decks
  WHERE source_system = 'edhrec'
    AND source_ref = 'learned_deck:7'
    AND commander_name = 'Korvold, Fae-Cursed King';

  SELECT COUNT(*)
  INTO old_partial_active_count
  FROM commander_learned_decks
  WHERE source_system = 'edhrec'
    AND source_ref = 'learned_deck:7'
    AND commander_name = 'Korvold, Fae-Cursed King'
    AND is_active = TRUE;

  SELECT COUNT(*)
  INTO replacement_active_count
  FROM commander_learned_decks
  WHERE source_system = 'commander_reference_decks'
    AND source_ref =
      'edhrec_korvold_fae_cursed_king_default_average_sprint3_lot_b_2026_05_14'
    AND commander_name = 'Korvold, Fae-Cursed King'
    AND is_active = TRUE;

  SELECT COUNT(*)
  INTO source_deck_count
  FROM commander_reference_decks
  WHERE source_deck_key =
    'edhrec_korvold_fae_cursed_king_default_average_sprint3_lot_b_2026_05_14'
    AND commander_name = 'Korvold, Fae-Cursed King'
    AND accepted = TRUE
    AND main_quantity = 99
    AND commander_quantity = 1
    AND unresolved_count = 0
    AND off_color_count = 0;

  SELECT
    COALESCE(SUM(quantity), 0)::int,
    COALESCE(SUM(CASE WHEN board = 'commander' THEN quantity ELSE 0 END), 0)::int,
    COALESCE(SUM(CASE WHEN unresolved THEN quantity ELSE 0 END), 0)::int,
    COALESCE(SUM(CASE WHEN off_color THEN quantity ELSE 0 END), 0)::int
  INTO
    source_quantity,
    source_commander_quantity,
    source_unresolved_count,
    source_off_color_count
  FROM commander_reference_deck_cards
  WHERE source_deck_key =
    'edhrec_korvold_fae_cursed_king_default_average_sprint3_lot_b_2026_05_14';

  IF old_partial_total_count != 1 THEN
    RAISE EXCEPTION
      'PG009 expected one old partial row, found %',
      old_partial_total_count;
  END IF;
  IF old_partial_active_count NOT IN (0, 1) THEN
    RAISE EXCEPTION
      'PG009 expected old partial active count 0 or 1, found %',
      old_partial_active_count;
  END IF;
  IF old_partial_active_count = 0 AND replacement_active_count != 1 THEN
    RAISE EXCEPTION
      'PG009 expected active old row or active replacement row, replacement active count %',
      replacement_active_count;
  END IF;
  IF source_deck_count != 1 THEN
    RAISE EXCEPTION
      'PG009 expected one accepted replacement source deck, found %',
      source_deck_count;
  END IF;
  IF source_quantity != 100 THEN
    RAISE EXCEPTION 'PG009 expected source quantity 100, found %', source_quantity;
  END IF;
  IF source_commander_quantity != 1 THEN
    RAISE EXCEPTION
      'PG009 expected commander quantity 1, found %',
      source_commander_quantity;
  END IF;
  IF source_unresolved_count != 0 THEN
    RAISE EXCEPTION
      'PG009 expected unresolved quantity 0, found %',
      source_unresolved_count;
  END IF;
  IF source_off_color_count != 0 THEN
    RAISE EXCEPTION
      'PG009 expected off-color quantity 0, found %',
      source_off_color_count;
  END IF;
END $$;

UPDATE commander_learned_decks
SET is_active = FALSE,
    updated_at = NOW()
WHERE source_system = 'edhrec'
  AND source_ref = 'learned_deck:7'
  AND commander_name = 'Korvold, Fae-Cursed King'
  AND is_active = TRUE;

WITH source_deck AS (
  SELECT
    source_deck_key,
    commander_name,
    source,
    source_url,
    power_lane,
    theme,
    role_summary
  FROM commander_reference_decks
  WHERE source_deck_key =
    'edhrec_korvold_fae_cursed_king_default_average_sprint3_lot_b_2026_05_14'
),
source_cards AS (
  SELECT
    source_deck_key,
    STRING_AGG(
      FORMAT('%s %s', quantity, card_name),
      E'\n'
      ORDER BY
        CASE WHEN board = 'commander' THEN 0 ELSE 1 END,
        card_name
    ) AS card_list,
    COALESCE(SUM(quantity), 0)::int AS card_count
  FROM commander_reference_deck_cards
  WHERE source_deck_key =
    'edhrec_korvold_fae_cursed_king_default_average_sprint3_lot_b_2026_05_14'
  GROUP BY source_deck_key
)
INSERT INTO commander_learned_decks (
  commander_name,
  commander_name_normalized,
  deck_name,
  source_system,
  source_ref,
  source_url,
  archetype,
  card_list,
  card_count,
  score,
  wincon_primary,
  wincon_backup,
  legal_status,
  notes,
  metadata,
  is_active,
  promoted_at
)
SELECT
  sd.commander_name,
  'korvold, fae-cursed king',
  'EDHREC Average - Korvold, Fae-Cursed King',
  'commander_reference_decks',
  sd.source_deck_key,
  sd.source_url,
  sd.theme,
  sc.card_list,
  sc.card_count,
  NULL,
  NULL,
  NULL,
  'commander_legal',
  'PG009 replacement for stale partial edhrec learned_deck:7. Source is accepted commander_reference_decks corpus.',
  jsonb_build_object(
    'source_table', 'commander_reference_decks',
    'source_deck_key', sd.source_deck_key,
    'source', sd.source,
    'power_lane', sd.power_lane,
    'theme', sd.theme,
    'role_summary', sd.role_summary,
    'role_summary_source', 'learned_deck_coherence_audit_pg009',
    'total_lands', 34,
    'ramp_count', 65,
    'draw_count', 10,
    'removal_count', 9,
    'tutor_count', 5,
    'engine_count', 18,
    'wincon_count', 4,
    'protection_count', 3,
    'recursion_count', 6,
    'board_wipe_count', 1,
    'replaces_source_system', 'edhrec',
    'replaces_source_ref', 'learned_deck:7',
    'replacement_reason', 'old row had card_count 90 and commander_quantity 0'
  ),
  TRUE,
  NOW()
FROM source_deck sd
JOIN source_cards sc ON sc.source_deck_key = sd.source_deck_key
ON CONFLICT (source_system, source_ref)
DO UPDATE SET
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
  is_active = TRUE,
  promoted_at = EXCLUDED.promoted_at,
  updated_at = NOW();

COMMIT;
