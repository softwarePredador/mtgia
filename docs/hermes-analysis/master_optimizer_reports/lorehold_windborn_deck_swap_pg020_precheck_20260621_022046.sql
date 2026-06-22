-- PG-020 precheck: promote the Hermes-validated Lorehold deck swap to the
-- PostgreSQL materialized deck only if the target deck is still in the exact
-- expected pre-apply state.

WITH target AS (
  SELECT '528c877f-f829-4207-95e6-73981776c323'::uuid AS deck_id
),
resolved_cards AS (
  SELECT
    (array_agg(c.id ORDER BY c.id::text) FILTER (WHERE lower(c.name) = 'guttersnipe'))[1] AS guttersnipe_id,
    (array_agg(c.id ORDER BY c.id::text) FILTER (WHERE lower(c.name) = 'windborn muse'))[1] AS windborn_muse_id,
    COUNT(*) FILTER (WHERE lower(c.name) = 'guttersnipe') AS guttersnipe_printings,
    COUNT(*) FILTER (WHERE lower(c.name) = 'windborn muse') AS windborn_muse_printings
  FROM cards c
  WHERE lower(c.name) IN ('guttersnipe', 'windborn muse')
),
deck_shape AS (
  SELECT
    COUNT(*) AS deck_rows,
    COALESCE(SUM(dc.quantity), 0) AS deck_quantity
  FROM deck_cards dc
  JOIN target t ON t.deck_id = dc.deck_id
),
current_cards AS (
  SELECT
    COUNT(*) FILTER (WHERE lower(c.name) = 'guttersnipe') AS current_guttersnipe_rows,
    COALESCE(SUM(dc.quantity) FILTER (WHERE lower(c.name) = 'guttersnipe'), 0) AS current_guttersnipe_qty,
    COUNT(*) FILTER (WHERE lower(c.name) = 'windborn muse') AS current_windborn_rows,
    COALESCE(SUM(dc.quantity) FILTER (WHERE lower(c.name) = 'windborn muse'), 0) AS current_windborn_qty,
    BOOL_OR(dc.is_commander) FILTER (WHERE lower(c.name) = 'guttersnipe') AS guttersnipe_is_commander
  FROM deck_cards dc
  JOIN cards c ON c.id = dc.card_id
  JOIN target t ON t.deck_id = dc.deck_id
),
windborn_legality AS (
  SELECT COUNT(*) AS commander_legal_rows
  FROM card_legalities cl
  JOIN resolved_cards rc ON rc.windborn_muse_id = cl.card_id
  WHERE cl.format = 'commander'
    AND cl.status = 'legal'
),
windborn_color AS (
  SELECT c.color_identity::text AS color_identity
  FROM cards c
  JOIN resolved_cards rc ON rc.windborn_muse_id = c.id
)
SELECT
  'pg020_lorehold_windborn_deck_swap_precheck' AS check_name,
  d.name AS deck_name,
  d.format AS deck_format,
  ds.deck_rows,
  ds.deck_quantity,
  rc.guttersnipe_id::text AS guttersnipe_id,
  rc.windborn_muse_id::text AS windborn_muse_id,
  rc.guttersnipe_printings,
  rc.windborn_muse_printings,
  cc.current_guttersnipe_rows,
  cc.current_guttersnipe_qty,
  COALESCE(cc.guttersnipe_is_commander, false) AS guttersnipe_is_commander,
  cc.current_windborn_rows,
  cc.current_windborn_qty,
  wl.commander_legal_rows AS windborn_commander_legal_rows,
  wc.color_identity AS windborn_color_identity,
  (
    d.format = 'commander'
    AND ds.deck_rows = 100
    AND ds.deck_quantity = 100
    AND rc.guttersnipe_printings = 1
    AND rc.windborn_muse_printings = 1
    AND cc.current_guttersnipe_rows = 1
    AND cc.current_guttersnipe_qty = 1
    AND COALESCE(cc.guttersnipe_is_commander, false) = false
    AND cc.current_windborn_rows = 0
    AND cc.current_windborn_qty = 0
    AND wl.commander_legal_rows = 1
    AND wc.color_identity = '{W}'
  ) AS ready_to_apply
FROM target t
JOIN decks d ON d.id = t.deck_id
CROSS JOIN resolved_cards rc
CROSS JOIN deck_shape ds
CROSS JOIN current_cards cc
CROSS JOIN windborn_legality wl
CROSS JOIN windborn_color wc;
