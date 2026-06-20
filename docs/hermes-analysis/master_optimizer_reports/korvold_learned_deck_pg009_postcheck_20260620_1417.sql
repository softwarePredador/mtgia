-- PG009 postcheck. Expected after apply:
-- - exactly one active Korvold learned deck
-- - active source is commander_reference_decks/default average
-- - card_count = 100
-- - parsed quantity from stored lines = 100
-- - commander quantity from stored lines = 1
-- - old edhrec learned_deck:7 row is inactive

BEGIN READ ONLY;

WITH active_korvold AS (
  SELECT
    id,
    source_system,
    source_ref,
    commander_name,
    deck_name,
    card_list,
    card_count,
    metadata,
    is_active,
    updated_at
  FROM commander_learned_decks
  WHERE commander_name = 'Korvold, Fae-Cursed King'
    AND is_active = TRUE
),
line_parse AS (
  SELECT
    source_system,
    source_ref,
    CASE
      WHEN line ~ '^[0-9]+ '
        THEN split_part(line, ' ', 1)::int
      ELSE 1
    END AS quantity,
    CASE
      WHEN line ~ '^[0-9]+ '
        THEN substring(line from '^[0-9]+ (.*)$')
      ELSE line
    END AS card_name
  FROM active_korvold
  CROSS JOIN LATERAL regexp_split_to_table(card_list, E'\n') AS line
  WHERE btrim(line) <> ''
),
old_partial AS (
  SELECT id, is_active, card_count, updated_at
  FROM commander_learned_decks
  WHERE source_system = 'edhrec'
    AND source_ref = 'learned_deck:7'
    AND commander_name = 'Korvold, Fae-Cursed King'
)
SELECT
  (SELECT COUNT(*) FROM active_korvold) AS active_korvold_count,
  (SELECT source_system FROM active_korvold LIMIT 1) AS active_source_system,
  (SELECT source_ref FROM active_korvold LIMIT 1) AS active_source_ref,
  (SELECT card_count FROM active_korvold LIMIT 1) AS active_card_count,
  (SELECT metadata->>'total_lands' FROM active_korvold LIMIT 1)
    AS metadata_total_lands,
  (SELECT metadata->>'ramp_count' FROM active_korvold LIMIT 1)
    AS metadata_ramp_count,
  (SELECT metadata->>'draw_count' FROM active_korvold LIMIT 1)
    AS metadata_draw_count,
  (SELECT metadata->>'removal_count' FROM active_korvold LIMIT 1)
    AS metadata_removal_count,
  (SELECT metadata->>'tutor_count' FROM active_korvold LIMIT 1)
    AS metadata_tutor_count,
  (SELECT metadata->>'engine_count' FROM active_korvold LIMIT 1)
    AS metadata_engine_count,
  (SELECT metadata->>'wincon_count' FROM active_korvold LIMIT 1)
    AS metadata_wincon_count,
  (SELECT metadata->>'protection_count' FROM active_korvold LIMIT 1)
    AS metadata_protection_count,
  (SELECT COALESCE(SUM(quantity), 0)::int FROM line_parse)
    AS parsed_quantity,
  (
    SELECT COALESCE(SUM(quantity), 0)::int
    FROM line_parse
    WHERE lower(card_name) = lower('Korvold, Fae-Cursed King')
  ) AS parsed_commander_quantity,
  (SELECT COUNT(*) FROM old_partial WHERE is_active = TRUE)
    AS old_partial_active_count,
  (SELECT card_count FROM old_partial LIMIT 1) AS old_partial_card_count;

ROLLBACK;
