\pset pager off
\set ON_ERROR_STOP on

-- PG244 rollback: restore the single backed-up Promise of Loyalty deck row
-- from manaloom_deploy_audit.pg244_lorehold_ghostly_prison_deck_swap_20260627.

BEGIN;

DO $$
DECLARE
  v_deck_id uuid := '528c877f-f829-4207-95e6-73981776c323'::uuid;
  v_backup_rows integer;
  v_current_ghostly_rows integer;
  v_current_promise_rows integer;
  v_updated integer;
BEGIN
  SELECT COUNT(*)
  INTO v_backup_rows
  FROM manaloom_deploy_audit.pg244_lorehold_ghostly_prison_deck_swap_20260627
  WHERE deck_id = v_deck_id;

  IF v_backup_rows <> 1 THEN
    RAISE EXCEPTION 'PG244 rollback requires exactly 1 backup row, found %', v_backup_rows;
  END IF;

  SELECT
    COUNT(*) FILTER (WHERE dc.card_id = b.new_card_id),
    COUNT(*) FILTER (WHERE dc.card_id = b.old_card_id)
  INTO v_current_ghostly_rows, v_current_promise_rows
  FROM deck_cards dc
  CROSS JOIN manaloom_deploy_audit.pg244_lorehold_ghostly_prison_deck_swap_20260627 b
  WHERE dc.deck_id = v_deck_id
    AND b.deck_id = v_deck_id;

  IF v_current_ghostly_rows <> 1 OR v_current_promise_rows <> 0 THEN
    RAISE EXCEPTION 'PG244 rollback current-state guard failed: ghostly_rows=%, promise_rows=%',
      v_current_ghostly_rows, v_current_promise_rows;
  END IF;

  UPDATE deck_cards dc
  SET card_id = b.old_card_id
  FROM manaloom_deploy_audit.pg244_lorehold_ghostly_prison_deck_swap_20260627 b
  WHERE dc.id = b.deck_card_id
    AND dc.deck_id = b.deck_id
    AND dc.card_id = b.new_card_id
    AND b.deck_id = v_deck_id;

  GET DIAGNOSTICS v_updated = ROW_COUNT;
  IF v_updated <> 1 THEN
    RAISE EXCEPTION 'PG244 rollback expected 1 updated row, got %', v_updated;
  END IF;
END $$;

COMMIT;

WITH target AS (
  SELECT '528c877f-f829-4207-95e6-73981776c323'::uuid AS deck_id
)
SELECT
  'pg244_lorehold_ghostly_prison_deck_swap_rollback' AS check_name,
  COUNT(*) FILTER (WHERE lower(c.name) = 'promise of loyalty') AS promise_rows,
  COUNT(*) FILTER (WHERE lower(c.name) = 'ghostly prison') AS ghostly_prison_rows,
  COALESCE(SUM(dc.quantity), 0) AS total_quantity
FROM deck_cards dc
JOIN cards c ON c.id = dc.card_id
JOIN target t ON t.deck_id = dc.deck_id;
