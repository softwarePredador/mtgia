-- PG-020 rollback: restore the single backed-up deck_cards row from
-- manaloom_deploy_audit.pg020_lorehold_windborn_deck_swap_20260621_022046.

BEGIN;

DO $$
DECLARE
  v_deck_id uuid := '528c877f-f829-4207-95e6-73981776c323'::uuid;
  v_backup_rows integer;
  v_current_windborn_rows integer;
  v_current_guttersnipe_rows integer;
BEGIN
  SELECT COUNT(*)
  INTO v_backup_rows
  FROM manaloom_deploy_audit.pg020_lorehold_windborn_deck_swap_20260621_022046
  WHERE deck_id = v_deck_id;

  IF v_backup_rows <> 1 THEN
    RAISE EXCEPTION 'PG020 rollback requires exactly 1 backup row, found %', v_backup_rows;
  END IF;

  SELECT
    COUNT(*) FILTER (WHERE dc.card_id = b.new_card_id),
    COUNT(*) FILTER (WHERE dc.card_id = b.old_card_id)
  INTO v_current_windborn_rows, v_current_guttersnipe_rows
  FROM deck_cards dc
  CROSS JOIN manaloom_deploy_audit.pg020_lorehold_windborn_deck_swap_20260621_022046 b
  WHERE dc.deck_id = v_deck_id
    AND b.deck_id = v_deck_id;

  IF v_current_windborn_rows <> 1 OR v_current_guttersnipe_rows <> 0 THEN
    RAISE EXCEPTION 'PG020 rollback current-state guard failed: windborn_rows=%, guttersnipe_rows=%',
      v_current_windborn_rows, v_current_guttersnipe_rows;
  END IF;

  UPDATE deck_cards dc
  SET card_id = b.old_card_id
  FROM manaloom_deploy_audit.pg020_lorehold_windborn_deck_swap_20260621_022046 b
  WHERE dc.id = b.deck_card_id
    AND dc.deck_id = b.deck_id
    AND dc.card_id = b.new_card_id
    AND b.deck_id = v_deck_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'PG020 rollback update affected no rows';
  END IF;
END $$;

COMMIT;

WITH target AS (
  SELECT '528c877f-f829-4207-95e6-73981776c323'::uuid AS deck_id
)
SELECT
  'pg020_lorehold_windborn_deck_swap_rollback' AS check_name,
  COUNT(*) FILTER (WHERE lower(c.name) = 'guttersnipe') AS guttersnipe_rows,
  COUNT(*) FILTER (WHERE lower(c.name) = 'windborn muse') AS windborn_rows,
  COALESCE(SUM(dc.quantity), 0) AS total_quantity
FROM deck_cards dc
JOIN cards c ON c.id = dc.card_id
JOIN target t ON t.deck_id = dc.deck_id;
