\pset pager off
\set ON_ERROR_STOP on

BEGIN;

DO $$
DECLARE
  v_deck_id uuid := '528c877f-f829-4207-95e6-73981776c323'::uuid;
  v_backup_rows integer;
  v_updated integer;
BEGIN
  SELECT count(*)
  INTO v_backup_rows
  FROM manaloom_deploy_audit.pg026_lorehold_magus_sphere_deck_swap_20260622_165810
  WHERE deck_id = v_deck_id;

  IF v_backup_rows <> 2 THEN
    RAISE EXCEPTION 'PG026 rollback expected 2 backup rows, found %', v_backup_rows;
  END IF;

  UPDATE deck_cards dc
  SET card_id = b.old_card_id
  FROM manaloom_deploy_audit.pg026_lorehold_magus_sphere_deck_swap_20260622_165810 b
  WHERE dc.id = b.deck_card_id
    AND dc.deck_id = b.deck_id
    AND b.deck_id = v_deck_id
    AND dc.card_id = b.new_card_id;

  GET DIAGNOSTICS v_updated = ROW_COUNT;
  IF v_updated <> 2 THEN
    RAISE EXCEPTION 'PG026 rollback expected 2 updated rows, got %', v_updated;
  END IF;
END $$;

COMMIT;

WITH target AS (
  SELECT '528c877f-f829-4207-95e6-73981776c323'::uuid AS deck_id
)
SELECT
  'pg026_lorehold_magus_sphere_rollback' AS check_name,
  count(*) FILTER (WHERE lower(c.name) = 'electroduplicate') AS electroduplicate_rows,
  count(*) FILTER (WHERE lower(c.name) = 'victory chimes') AS victory_chimes_rows,
  count(*) FILTER (WHERE lower(c.name) = 'magus of the moat') AS magus_rows,
  count(*) FILTER (WHERE lower(c.name) = 'sphere of safety') AS sphere_rows,
  coalesce(sum(dc.quantity), 0) AS total_quantity
FROM deck_cards dc
JOIN cards c ON c.id = dc.card_id
JOIN target t ON t.deck_id = dc.deck_id;
