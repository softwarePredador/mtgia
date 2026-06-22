\pset pager off
\set ON_ERROR_STOP on

WITH target AS (
  SELECT '528c877f-f829-4207-95e6-73981776c323'::uuid AS deck_id
)
SELECT
  'pg026_lorehold_magus_sphere_postcheck' AS check_name,
  count(*) AS deck_rows,
  coalesce(sum(dc.quantity), 0) AS deck_qty,
  count(*) FILTER (WHERE lower(c.name) = 'electroduplicate') AS electroduplicate_rows,
  count(*) FILTER (WHERE lower(c.name) = 'victory chimes') AS victory_chimes_rows,
  count(*) FILTER (WHERE lower(c.name) = 'magus of the moat') AS magus_rows,
  count(*) FILTER (WHERE lower(c.name) = 'sphere of safety') AS sphere_rows,
  (
    SELECT count(*)
    FROM manaloom_deploy_audit.pg026_lorehold_magus_sphere_deck_swap_20260622_165810 b
    JOIN target t ON t.deck_id = b.deck_id
  ) AS backup_rows
FROM deck_cards dc
JOIN cards c ON c.id = dc.card_id
JOIN target t ON t.deck_id = dc.deck_id;

WITH target AS (
  SELECT '528c877f-f829-4207-95e6-73981776c323'::uuid AS deck_id
)
SELECT
  c.name,
  dc.quantity,
  dc.is_commander,
  c.color_identity::text AS color_identity
FROM deck_cards dc
JOIN cards c ON c.id = dc.card_id
JOIN target t ON t.deck_id = dc.deck_id
WHERE lower(c.name) IN (
  'electroduplicate',
  'victory chimes',
  'magus of the moat',
  'sphere of safety'
)
ORDER BY c.name;
