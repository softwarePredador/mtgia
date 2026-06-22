-- PG-020 postcheck: verify the PostgreSQL materialized Lorehold deck now
-- contains Windborn Muse and no Guttersnipe while preserving 100/100 shape.

WITH target AS (
  SELECT '528c877f-f829-4207-95e6-73981776c323'::uuid AS deck_id
),
deck_shape AS (
  SELECT COUNT(*) AS deck_rows, COALESCE(SUM(quantity), 0) AS deck_quantity
  FROM deck_cards dc
  JOIN target t ON t.deck_id = dc.deck_id
),
current_cards AS (
  SELECT
    COUNT(*) FILTER (WHERE lower(c.name) = 'guttersnipe') AS guttersnipe_rows,
    COALESCE(SUM(dc.quantity) FILTER (WHERE lower(c.name) = 'guttersnipe'), 0) AS guttersnipe_qty,
    COUNT(*) FILTER (WHERE lower(c.name) = 'windborn muse') AS windborn_rows,
    COALESCE(SUM(dc.quantity) FILTER (WHERE lower(c.name) = 'windborn muse'), 0) AS windborn_qty,
    BOOL_OR(dc.is_commander) FILTER (WHERE lower(c.name) = 'windborn muse') AS windborn_is_commander
  FROM deck_cards dc
  JOIN cards c ON c.id = dc.card_id
  JOIN target t ON t.deck_id = dc.deck_id
),
backup AS (
  SELECT COUNT(*) AS backup_rows
  FROM manaloom_deploy_audit.pg020_lorehold_windborn_deck_swap_20260621_022046
  WHERE deck_id = (SELECT deck_id FROM target)
)
SELECT
  'pg020_lorehold_windborn_deck_swap_postcheck' AS check_name,
  ds.deck_rows,
  ds.deck_quantity,
  cc.guttersnipe_rows,
  cc.guttersnipe_qty,
  cc.windborn_rows,
  cc.windborn_qty,
  COALESCE(cc.windborn_is_commander, false) AS windborn_is_commander,
  backup.backup_rows,
  (
    ds.deck_rows = 100
    AND ds.deck_quantity = 100
    AND cc.guttersnipe_rows = 0
    AND cc.guttersnipe_qty = 0
    AND cc.windborn_rows = 1
    AND cc.windborn_qty = 1
    AND COALESCE(cc.windborn_is_commander, false) = false
    AND backup.backup_rows = 1
  ) AS postcheck_passed
FROM deck_shape ds
CROSS JOIN current_cards cc
CROSS JOIN backup;
