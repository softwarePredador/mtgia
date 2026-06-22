\pset pager off
\set ON_ERROR_STOP on

BEGIN;

DO $$
DECLARE
  v_backup_rows integer;
BEGIN
  SELECT count(*)
  INTO v_backup_rows
  FROM manaloom_deploy_audit.pg022_lorehold_silent_arbiter_deck_swap_20260621_044155
  WHERE deck_id = '528c877f-f829-4207-95e6-73981776c323'::uuid;

  IF v_backup_rows <> 1 THEN
    RAISE EXCEPTION 'PG022 rollback requires exactly 1 backup row for target deck, found %', v_backup_rows;
  END IF;
END $$;

UPDATE deck_cards dc
SET card_id = backup.old_card_id
FROM manaloom_deploy_audit.pg022_lorehold_silent_arbiter_deck_swap_20260621_044155 backup
WHERE dc.id = backup.deck_card_id
  AND dc.deck_id = backup.deck_id
  AND dc.card_id = backup.new_card_id;

COMMIT;

WITH target AS (
  SELECT '528c877f-f829-4207-95e6-73981776c323'::uuid AS deck_id
)
SELECT
  'pg022_lorehold_silent_arbiter_rollback' AS check_name,
  count(*) FILTER (WHERE lower(c.name) = 'monument to endurance') AS monument_rows,
  count(*) FILTER (WHERE lower(c.name) = 'silent arbiter') AS silent_rows,
  coalesce(sum(dc.quantity), 0) AS total_quantity
FROM deck_cards dc
JOIN cards c ON c.id = dc.card_id
JOIN target t ON t.deck_id = dc.deck_id;
