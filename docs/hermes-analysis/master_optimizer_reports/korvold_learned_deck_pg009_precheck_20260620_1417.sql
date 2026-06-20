-- PG009 precheck: replace partial Korvold learned deck with accepted reference deck.
-- Read-only. Expected before apply:
-- - old_partial_active_count = 1
-- - source_deck_count = 1
-- - source_quantity = 100
-- - source_commander_quantity = 1
-- - source_unresolved_count = 0
-- - source_off_color_count = 0
-- - existing_new_source_rows is 0 or inactive.

BEGIN READ ONLY;

WITH old_partial AS (
  SELECT
    id,
    source_system,
    source_ref,
    commander_name,
    deck_name,
    card_count,
    is_active,
    updated_at
  FROM commander_learned_decks
  WHERE source_system = 'edhrec'
    AND source_ref = 'learned_deck:7'
    AND commander_name = 'Korvold, Fae-Cursed King'
),
source_deck AS (
  SELECT
    source_deck_key,
    commander_name,
    source,
    source_url,
    power_lane,
    theme,
    main_quantity,
    commander_quantity,
    resolved_count,
    unresolved_count,
    off_color_count,
    role_summary,
    accepted
  FROM commander_reference_decks
  WHERE source_deck_key =
    'edhrec_korvold_fae_cursed_king_default_average_sprint3_lot_b_2026_05_14'
    AND commander_name = 'Korvold, Fae-Cursed King'
),
source_cards AS (
  SELECT
    source_deck_key,
    COALESCE(SUM(quantity), 0)::int AS source_quantity,
    COALESCE(
      SUM(CASE WHEN board = 'commander' THEN quantity ELSE 0 END),
      0
    )::int AS source_commander_quantity,
    COALESCE(
      SUM(CASE WHEN unresolved THEN quantity ELSE 0 END),
      0
    )::int AS source_unresolved_count,
    COALESCE(
      SUM(CASE WHEN off_color THEN quantity ELSE 0 END),
      0
    )::int AS source_off_color_count,
    COUNT(*)::int AS source_rows
  FROM commander_reference_deck_cards
  WHERE source_deck_key =
    'edhrec_korvold_fae_cursed_king_default_average_sprint3_lot_b_2026_05_14'
  GROUP BY source_deck_key
),
new_source AS (
  SELECT id, is_active, card_count, updated_at
  FROM commander_learned_decks
  WHERE source_system = 'commander_reference_decks'
    AND source_ref =
      'edhrec_korvold_fae_cursed_king_default_average_sprint3_lot_b_2026_05_14'
)
SELECT
  (SELECT COUNT(*) FROM old_partial WHERE is_active = TRUE)
    AS old_partial_active_count,
  (SELECT COUNT(*) FROM old_partial)
    AS old_partial_total_rows,
  (SELECT card_count FROM old_partial LIMIT 1)
    AS old_partial_card_count,
  (SELECT COUNT(*) FROM source_deck WHERE accepted = TRUE)
    AS source_deck_count,
  (SELECT source_quantity FROM source_cards)
    AS source_quantity,
  (SELECT source_commander_quantity FROM source_cards)
    AS source_commander_quantity,
  (SELECT source_unresolved_count FROM source_cards)
    AS source_unresolved_count,
  (SELECT source_off_color_count FROM source_cards)
    AS source_off_color_count,
  (SELECT source_rows FROM source_cards)
    AS source_rows,
  (SELECT COUNT(*) FROM new_source)
    AS existing_new_source_rows,
  (SELECT COUNT(*) FROM new_source WHERE is_active = TRUE)
    AS existing_new_source_active_rows;

ROLLBACK;
