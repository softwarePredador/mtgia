\pset pager off
\set ON_ERROR_STOP on

-- PG244 apply: promote the battle-validated Ghostly Prison over Promise of
-- Loyalty pressure-lane swap to the PostgreSQL materialized Lorehold deck.
-- This script is guarded by exact pre-state checks and stores the previous
-- deck_card row in manaloom_deploy_audit before mutation.

BEGIN;

CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit;

CREATE TABLE IF NOT EXISTS manaloom_deploy_audit.pg244_lorehold_ghostly_prison_deck_swap_20260627 (
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
  v_promise_id uuid;
  v_ghostly_id uuid;
  v_promise_printings integer;
  v_ghostly_printings integer;
  v_deck_rows integer;
  v_deck_qty integer;
  v_promise_rows integer;
  v_promise_qty integer;
  v_promise_is_commander boolean;
  v_ghostly_rows integer;
  v_ghostly_qty integer;
  v_ghostly_legal integer;
  v_ghostly_color text;
  v_ghostly_rule_rows integer;
  v_existing_backup integer;
  v_inserted integer;
  v_updated integer;
BEGIN
  SELECT (array_agg(id ORDER BY id::text))[1], COUNT(*)
  INTO v_promise_id, v_promise_printings
  FROM cards
  WHERE lower(name) = 'promise of loyalty';

  SELECT (array_agg(id ORDER BY id::text))[1], COUNT(*)
  INTO v_ghostly_id, v_ghostly_printings
  FROM cards
  WHERE lower(name) = 'ghostly prison';

  IF v_promise_id IS NULL OR v_ghostly_id IS NULL THEN
    RAISE EXCEPTION 'PG244 card identity resolution failed: promise=%, ghostly=%',
      v_promise_id, v_ghostly_id;
  END IF;

  IF v_promise_printings <> 1 OR v_ghostly_printings <> 1 THEN
    RAISE EXCEPTION 'PG244 card identity uniqueness failed: promise_printings=%, ghostly_printings=%',
      v_promise_printings, v_ghostly_printings;
  END IF;

  SELECT COUNT(*), COALESCE(SUM(quantity), 0)
  INTO v_deck_rows, v_deck_qty
  FROM deck_cards
  WHERE deck_id = v_deck_id;

  SELECT
    COUNT(*) FILTER (WHERE card_id = v_promise_id),
    COALESCE(SUM(quantity) FILTER (WHERE card_id = v_promise_id), 0),
    COALESCE(BOOL_OR(is_commander) FILTER (WHERE card_id = v_promise_id), false),
    COUNT(*) FILTER (WHERE card_id = v_ghostly_id),
    COALESCE(SUM(quantity) FILTER (WHERE card_id = v_ghostly_id), 0)
  INTO
    v_promise_rows,
    v_promise_qty,
    v_promise_is_commander,
    v_ghostly_rows,
    v_ghostly_qty
  FROM deck_cards
  WHERE deck_id = v_deck_id;

  SELECT COUNT(*)
  INTO v_ghostly_legal
  FROM card_legalities
  WHERE card_id = v_ghostly_id
    AND format = 'commander'
    AND status = 'legal';

  SELECT color_identity::text
  INTO v_ghostly_color
  FROM cards
  WHERE id = v_ghostly_id;

  SELECT COUNT(*)
  INTO v_ghostly_rule_rows
  FROM card_battle_rules
  WHERE card_id = v_ghostly_id
    AND logical_rule_key = 'battle_rule_v1:99151859bece89ba3ead032e05b1f65a'
    AND source = 'curated'
    AND review_status = 'verified'
    AND execution_status = 'auto'
    AND oracle_hash = '5725b39ca4bb7c5e8e4bebf0d246be13'
    AND effect_json->>'effect' = 'attack_tax'
    AND COALESCE((effect_json->>'attack_tax_per_creature')::int, 0) = 2;

  SELECT COUNT(*)
  INTO v_existing_backup
  FROM manaloom_deploy_audit.pg244_lorehold_ghostly_prison_deck_swap_20260627
  WHERE deck_id = v_deck_id;

  IF v_existing_backup <> 0 THEN
    RAISE EXCEPTION 'PG244 backup table already has % row(s) for deck %, refusing reapply',
      v_existing_backup, v_deck_id;
  END IF;

  IF v_deck_rows <> 100 OR v_deck_qty <> 100 THEN
    RAISE EXCEPTION 'PG244 deck shape guard failed: rows=%, qty=%',
      v_deck_rows, v_deck_qty;
  END IF;

  IF v_promise_rows <> 1 OR v_promise_qty <> 1 OR v_promise_is_commander THEN
    RAISE EXCEPTION 'PG244 Promise of Loyalty guard failed: rows=%, qty=%, is_commander=%',
      v_promise_rows, v_promise_qty, v_promise_is_commander;
  END IF;

  IF v_ghostly_rows <> 0 OR v_ghostly_qty <> 0 THEN
    RAISE EXCEPTION 'PG244 Ghostly Prison pre-existence guard failed: rows=%, qty=%',
      v_ghostly_rows, v_ghostly_qty;
  END IF;

  IF v_ghostly_legal <> 1 OR v_ghostly_color <> '{W}' THEN
    RAISE EXCEPTION 'PG244 Ghostly Prison legality/color guard failed: legal_rows=%, color=%',
      v_ghostly_legal, v_ghostly_color;
  END IF;

  IF v_ghostly_rule_rows <> 1 THEN
    RAISE EXCEPTION 'PG244 Ghostly Prison verified runtime rule guard failed: rows=%',
      v_ghostly_rule_rows;
  END IF;

  INSERT INTO manaloom_deploy_audit.pg244_lorehold_ghostly_prison_deck_swap_20260627 (
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
    'PG244 battle-validated pressure swap: Ghostly Prison over Promise of Loyalty. Aggregate controlled gates improved from 13/59/0 to 27/45/0 (+19.44pp); instrumented gate restricted 20 attackers and charged 52 attack tax from Ghostly Prison.',
    dc.deck_id,
    dc.id,
    dc.card_id,
    old_card.name,
    v_ghostly_id,
    new_card.name,
    dc.quantity,
    dc.is_commander,
    dc.condition
  FROM deck_cards dc
  JOIN cards old_card ON old_card.id = dc.card_id
  JOIN cards new_card ON new_card.id = v_ghostly_id
  WHERE dc.deck_id = v_deck_id
    AND dc.card_id = v_promise_id;

  GET DIAGNOSTICS v_inserted = ROW_COUNT;
  IF v_inserted <> 1 THEN
    RAISE EXCEPTION 'PG244 expected 1 backup row, inserted %', v_inserted;
  END IF;

  UPDATE deck_cards
  SET card_id = v_ghostly_id
  WHERE deck_id = v_deck_id
    AND card_id = v_promise_id;

  GET DIAGNOSTICS v_updated = ROW_COUNT;
  IF v_updated <> 1 THEN
    RAISE EXCEPTION 'PG244 expected 1 updated deck row, got %', v_updated;
  END IF;
END $$;

COMMIT;

WITH target AS (
  SELECT '528c877f-f829-4207-95e6-73981776c323'::uuid AS deck_id
)
SELECT
  'pg244_lorehold_ghostly_prison_deck_swap_apply' AS check_name,
  COUNT(*) FILTER (WHERE lower(c.name) = 'promise of loyalty') AS promise_rows,
  COUNT(*) FILTER (WHERE lower(c.name) = 'ghostly prison') AS ghostly_prison_rows,
  COALESCE(SUM(dc.quantity), 0) AS total_quantity
FROM deck_cards dc
JOIN cards c ON c.id = dc.card_id
JOIN target t ON t.deck_id = dc.deck_id;
