\pset pager off
\set ON_ERROR_STOP on

-- PG244 rollback: restore Promise of Loyalty over Ghostly Prison for the
-- PostgreSQL materialized Lorehold deck using the guarded backup row created by
-- pg244_lorehold_ghostly_prison_deck_swap_apply.sql.

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
    RAISE EXCEPTION 'PG244 rollback expected 1 backup row for deck %, got %',
      v_deck_id, v_backup_rows;
  END IF;

  SELECT
    COUNT(*) FILTER (WHERE dc.card_id = b.new_card_id),
    COUNT(*) FILTER (WHERE dc.card_id = b.old_card_id)
  INTO v_current_ghostly_rows, v_current_promise_rows
  FROM manaloom_deploy_audit.pg244_lorehold_ghostly_prison_deck_swap_20260627 b
  LEFT JOIN deck_cards dc ON dc.deck_id = b.deck_id
  WHERE b.deck_id = v_deck_id
  GROUP BY b.deck_id;

  IF v_current_ghostly_rows <> 1 OR v_current_promise_rows <> 0 THEN
    RAISE EXCEPTION 'PG244 rollback current-state guard failed: ghostly_rows=%, promise_rows=%',
      v_current_ghostly_rows, v_current_promise_rows;
  END IF;

  UPDATE deck_cards dc
  SET
    card_id = b.old_card_id,
    quantity = b.quantity,
    is_commander = b.is_commander,
    condition = b.condition
  FROM manaloom_deploy_audit.pg244_lorehold_ghostly_prison_deck_swap_20260627 b
  WHERE dc.deck_id = b.deck_id
    AND dc.id = b.deck_card_id
    AND dc.card_id = b.new_card_id
    AND b.deck_id = v_deck_id;

  GET DIAGNOSTICS v_updated = ROW_COUNT;
  IF v_updated <> 1 THEN
    RAISE EXCEPTION 'PG244 rollback expected 1 restored deck row, got %', v_updated;
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
