\pset pager off

WITH target AS (
  SELECT '528c877f-f829-4207-95e6-73981776c323'::uuid AS deck_id
),
state AS (
  SELECT
    count(*) AS deck_rows,
    coalesce(sum(dc.quantity), 0) AS deck_quantity,
    count(*) FILTER (WHERE lower(c.name) = 'monument to endurance') AS monument_rows,
    coalesce(sum(dc.quantity) FILTER (WHERE lower(c.name) = 'monument to endurance'), 0) AS monument_quantity,
    count(*) FILTER (WHERE lower(c.name) = 'silent arbiter') AS silent_rows,
    coalesce(sum(dc.quantity) FILTER (WHERE lower(c.name) = 'silent arbiter'), 0) AS silent_quantity,
    coalesce(bool_or(dc.is_commander) FILTER (WHERE lower(c.name) = 'silent arbiter'), false) AS silent_is_commander
  FROM deck_cards dc
  JOIN cards c ON c.id = dc.card_id
  JOIN target t ON t.deck_id = dc.deck_id
),
backup AS (
  SELECT count(*) AS backup_rows
  FROM manaloom_deploy_audit.pg022_lorehold_silent_arbiter_deck_swap_20260621_044155
  WHERE deck_id = (SELECT deck_id FROM target)
)
SELECT
  'pg022_lorehold_silent_arbiter_postcheck' AS check_name,
  state.*,
  backup.backup_rows,
  (
    state.deck_rows = 100
    AND state.deck_quantity = 100
    AND state.monument_rows = 0
    AND state.monument_quantity = 0
    AND state.silent_rows = 1
    AND state.silent_quantity = 1
    AND NOT state.silent_is_commander
    AND backup.backup_rows = 1
  ) AS postcheck_passed
FROM state
CROSS JOIN backup;
