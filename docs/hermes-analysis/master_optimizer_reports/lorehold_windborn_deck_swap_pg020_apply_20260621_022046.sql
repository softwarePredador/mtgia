-- PG-020 apply: promote the Hermes-validated Windborn Muse over Guttersnipe
-- swap to the PostgreSQL materialized Lorehold deck. This script is guarded
-- by exact pre-state checks and stores the previous deck_card row in
-- manaloom_deploy_audit before mutation.

BEGIN;

CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit;

CREATE TABLE IF NOT EXISTS manaloom_deploy_audit.pg020_lorehold_windborn_deck_swap_20260621_022046 (
  backup_id bigserial PRIMARY KEY,
  backed_up_at timestamptz NOT NULL DEFAULT now(),
  reason text NOT NULL,
  deck_id uuid NOT NULL,
  deck_card_id uuid NOT NULL,
  old_card_id uuid NOT NULL,
  old_card_name text NOT NULL,
  new_card_id uuid NOT NULL,
  new_card_name text NOT NULL,
  quantity integer,
  is_commander boolean,
  condition text
);

DO $$
DECLARE
  v_deck_id uuid := '528c877f-f829-4207-95e6-73981776c323'::uuid;
  v_guttersnipe_id uuid;
  v_windborn_id uuid;
  v_guttersnipe_printings integer;
  v_windborn_printings integer;
  v_deck_rows integer;
  v_deck_qty integer;
  v_guttersnipe_rows integer;
  v_guttersnipe_qty integer;
  v_guttersnipe_is_commander boolean;
  v_windborn_rows integer;
  v_windborn_qty integer;
  v_windborn_legal integer;
  v_windborn_color text;
  v_existing_backup integer;
BEGIN
  SELECT
    (array_agg(id ORDER BY id::text))[1],
    COUNT(*)
  INTO v_guttersnipe_id, v_guttersnipe_printings
  FROM cards
  WHERE lower(name) = 'guttersnipe';

  SELECT
    (array_agg(id ORDER BY id::text))[1],
    COUNT(*)
  INTO v_windborn_id, v_windborn_printings
  FROM cards
  WHERE lower(name) = 'windborn muse';

  IF v_guttersnipe_id IS NULL OR v_windborn_id IS NULL THEN
    RAISE EXCEPTION 'PG020 card identity resolution failed: guttersnipe=%, windborn=%',
      v_guttersnipe_id, v_windborn_id;
  END IF;

  IF v_guttersnipe_printings <> 1 OR v_windborn_printings <> 1 THEN
    RAISE EXCEPTION 'PG020 card identity uniqueness failed: guttersnipe_printings=%, windborn_printings=%',
      v_guttersnipe_printings, v_windborn_printings;
  END IF;

  SELECT COUNT(*), COALESCE(SUM(quantity), 0)
  INTO v_deck_rows, v_deck_qty
  FROM deck_cards
  WHERE deck_id = v_deck_id;

  SELECT
    COUNT(*) FILTER (WHERE card_id = v_guttersnipe_id),
    COALESCE(SUM(quantity) FILTER (WHERE card_id = v_guttersnipe_id), 0),
    COALESCE(BOOL_OR(is_commander) FILTER (WHERE card_id = v_guttersnipe_id), false),
    COUNT(*) FILTER (WHERE card_id = v_windborn_id),
    COALESCE(SUM(quantity) FILTER (WHERE card_id = v_windborn_id), 0)
  INTO
    v_guttersnipe_rows,
    v_guttersnipe_qty,
    v_guttersnipe_is_commander,
    v_windborn_rows,
    v_windborn_qty
  FROM deck_cards
  WHERE deck_id = v_deck_id;

  SELECT COUNT(*)
  INTO v_windborn_legal
  FROM card_legalities
  WHERE card_id = v_windborn_id
    AND format = 'commander'
    AND status = 'legal';

  SELECT color_identity::text
  INTO v_windborn_color
  FROM cards
  WHERE id = v_windborn_id;

  SELECT COUNT(*)
  INTO v_existing_backup
  FROM manaloom_deploy_audit.pg020_lorehold_windborn_deck_swap_20260621_022046
  WHERE deck_id = v_deck_id;

  IF v_existing_backup <> 0 THEN
    RAISE EXCEPTION 'PG020 backup table already has % row(s) for deck %, refusing reapply',
      v_existing_backup, v_deck_id;
  END IF;

  IF v_deck_rows <> 100 OR v_deck_qty <> 100 THEN
    RAISE EXCEPTION 'PG020 deck shape guard failed: rows=%, qty=%',
      v_deck_rows, v_deck_qty;
  END IF;

  IF v_guttersnipe_rows <> 1 OR v_guttersnipe_qty <> 1 OR v_guttersnipe_is_commander THEN
    RAISE EXCEPTION 'PG020 Guttersnipe guard failed: rows=%, qty=%, is_commander=%',
      v_guttersnipe_rows, v_guttersnipe_qty, v_guttersnipe_is_commander;
  END IF;

  IF v_windborn_rows <> 0 OR v_windborn_qty <> 0 THEN
    RAISE EXCEPTION 'PG020 Windborn pre-existence guard failed: rows=%, qty=%',
      v_windborn_rows, v_windborn_qty;
  END IF;

  IF v_windborn_legal <> 1 OR v_windborn_color <> '{W}' THEN
    RAISE EXCEPTION 'PG020 Windborn legality/color guard failed: legal_rows=%, color=%',
      v_windborn_legal, v_windborn_color;
  END IF;

  INSERT INTO manaloom_deploy_audit.pg020_lorehold_windborn_deck_swap_20260621_022046 (
    reason,
    deck_id,
    deck_card_id,
    old_card_id,
    old_card_name,
    new_card_id,
    new_card_name,
    quantity,
    is_commander,
    condition
  )
  SELECT
    'Hermes PG019 trusted 64-seed battle: Windborn Muse over Guttersnipe improved Lorehold from 2/64 to 4/64 and kept all mandatory gates clean',
    dc.deck_id,
    dc.id,
    dc.card_id,
    old_card.name,
    v_windborn_id,
    new_card.name,
    dc.quantity,
    dc.is_commander,
    dc.condition
  FROM deck_cards dc
  JOIN cards old_card ON old_card.id = dc.card_id
  JOIN cards new_card ON new_card.id = v_windborn_id
  WHERE dc.deck_id = v_deck_id
    AND dc.card_id = v_guttersnipe_id;

  UPDATE deck_cards
  SET card_id = v_windborn_id
  WHERE deck_id = v_deck_id
    AND card_id = v_guttersnipe_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'PG020 update affected no rows';
  END IF;
END $$;

COMMIT;

WITH target AS (
  SELECT '528c877f-f829-4207-95e6-73981776c323'::uuid AS deck_id
)
SELECT
  'pg020_lorehold_windborn_deck_swap_apply' AS check_name,
  COUNT(*) FILTER (WHERE lower(c.name) = 'guttersnipe') AS guttersnipe_rows,
  COUNT(*) FILTER (WHERE lower(c.name) = 'windborn muse') AS windborn_rows,
  COALESCE(SUM(dc.quantity), 0) AS total_quantity
FROM deck_cards dc
JOIN cards c ON c.id = dc.card_id
JOIN target t ON t.deck_id = dc.deck_id;
