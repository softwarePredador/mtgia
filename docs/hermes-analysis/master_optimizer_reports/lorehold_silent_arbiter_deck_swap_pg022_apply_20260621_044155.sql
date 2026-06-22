\pset pager off
\set ON_ERROR_STOP on

BEGIN;

CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit;

CREATE TABLE IF NOT EXISTS manaloom_deploy_audit.pg022_lorehold_silent_arbiter_deck_swap_20260621_044155 (
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
  v_monument_id uuid;
  v_silent_id uuid;
  v_monument_printings integer;
  v_silent_printings integer;
  v_deck_rows integer;
  v_deck_qty integer;
  v_monument_rows integer;
  v_monument_qty integer;
  v_monument_is_commander boolean;
  v_silent_rows integer;
  v_silent_qty integer;
  v_silent_legal integer;
  v_silent_color text;
  v_silent_rule_ready boolean;
  v_existing_backup integer;
BEGIN
  SELECT (array_agg(id ORDER BY id::text))[1], count(*)
  INTO v_monument_id, v_monument_printings
  FROM cards
  WHERE lower(name) = 'monument to endurance';

  SELECT (array_agg(id ORDER BY id::text))[1], count(*)
  INTO v_silent_id, v_silent_printings
  FROM cards
  WHERE lower(name) = 'silent arbiter';

  IF v_monument_id IS NULL OR v_silent_id IS NULL THEN
    RAISE EXCEPTION 'PG022 card identity resolution failed: monument=%, silent=%',
      v_monument_id, v_silent_id;
  END IF;

  IF v_monument_printings <> 1 OR v_silent_printings <> 1 THEN
    RAISE EXCEPTION 'PG022 card identity uniqueness failed: monument_printings=%, silent_printings=%',
      v_monument_printings, v_silent_printings;
  END IF;

  SELECT count(*), coalesce(sum(quantity), 0)
  INTO v_deck_rows, v_deck_qty
  FROM deck_cards
  WHERE deck_id = v_deck_id;

  SELECT
    count(*) FILTER (WHERE card_id = v_monument_id),
    coalesce(sum(quantity) FILTER (WHERE card_id = v_monument_id), 0),
    coalesce(bool_or(is_commander) FILTER (WHERE card_id = v_monument_id), false),
    count(*) FILTER (WHERE card_id = v_silent_id),
    coalesce(sum(quantity) FILTER (WHERE card_id = v_silent_id), 0)
  INTO
    v_monument_rows,
    v_monument_qty,
    v_monument_is_commander,
    v_silent_rows,
    v_silent_qty
  FROM deck_cards
  WHERE deck_id = v_deck_id;

  SELECT count(*)
  INTO v_silent_legal
  FROM card_legalities
  WHERE card_id = v_silent_id
    AND format = 'commander'
    AND status = 'legal';

  SELECT color_identity::text
  INTO v_silent_color
  FROM cards
  WHERE id = v_silent_id;

  SELECT bool_or(
    effect_json->>'battle_model_scope' = 'silent_arbiter_global_single_attacker_v2'
    AND effect_json ? 'max_attackers'
    AND NOT (effect_json ? 'max_attackers_against_you')
    AND review_status = 'verified'
    AND execution_status = 'auto'
  )
  INTO v_silent_rule_ready
  FROM card_battle_rules
  WHERE normalized_name = 'silent arbiter'
    AND logical_rule_key = 'battle_rule_v1:6f6089b73fb8f7f9aee20cacb64fffc7';

  SELECT count(*)
  INTO v_existing_backup
  FROM manaloom_deploy_audit.pg022_lorehold_silent_arbiter_deck_swap_20260621_044155
  WHERE deck_id = v_deck_id;

  IF v_existing_backup <> 0 THEN
    RAISE EXCEPTION 'PG022 backup table already has % row(s) for deck %, refusing reapply',
      v_existing_backup, v_deck_id;
  END IF;

  IF v_deck_rows <> 100 OR v_deck_qty <> 100 THEN
    RAISE EXCEPTION 'PG022 deck shape guard failed: rows=%, qty=%',
      v_deck_rows, v_deck_qty;
  END IF;

  IF v_monument_rows <> 1 OR v_monument_qty <> 1 OR v_monument_is_commander THEN
    RAISE EXCEPTION 'PG022 Monument guard failed: rows=%, qty=%, is_commander=%',
      v_monument_rows, v_monument_qty, v_monument_is_commander;
  END IF;

  IF v_silent_rows <> 0 OR v_silent_qty <> 0 THEN
    RAISE EXCEPTION 'PG022 Silent pre-existence guard failed: rows=%, qty=%',
      v_silent_rows, v_silent_qty;
  END IF;

  IF v_silent_legal <> 1 OR v_silent_color <> '{}' THEN
    RAISE EXCEPTION 'PG022 Silent legality/color guard failed: legal_rows=%, color=%',
      v_silent_legal, v_silent_color;
  END IF;

  IF NOT coalesce(v_silent_rule_ready, false) THEN
    RAISE EXCEPTION 'PG022 Silent global rule guard failed';
  END IF;

  INSERT INTO manaloom_deploy_audit.pg022_lorehold_silent_arbiter_deck_swap_20260621_044155 (
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
    'Corrected 64-seed battle after PG021: Silent Arbiter over Monument to Endurance improved Lorehold from 4/64 to 8/64 with clean mandatory gates; net +4 seed wins.',
    dc.deck_id,
    dc.id,
    dc.card_id,
    old_card.name,
    v_silent_id,
    new_card.name,
    dc.quantity,
    dc.is_commander,
    dc.condition
  FROM deck_cards dc
  JOIN cards old_card ON old_card.id = dc.card_id
  JOIN cards new_card ON new_card.id = v_silent_id
  WHERE dc.deck_id = v_deck_id
    AND dc.card_id = v_monument_id;

  UPDATE deck_cards
  SET card_id = v_silent_id
  WHERE deck_id = v_deck_id
    AND card_id = v_monument_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'PG022 update affected no rows';
  END IF;
END $$;

COMMIT;

WITH target AS (
  SELECT '528c877f-f829-4207-95e6-73981776c323'::uuid AS deck_id
)
SELECT
  'pg022_lorehold_silent_arbiter_apply' AS check_name,
  count(*) FILTER (WHERE lower(c.name) = 'monument to endurance') AS monument_rows,
  count(*) FILTER (WHERE lower(c.name) = 'silent arbiter') AS silent_rows,
  coalesce(sum(dc.quantity), 0) AS total_quantity
FROM deck_cards dc
JOIN cards c ON c.id = dc.card_id
JOIN target t ON t.deck_id = dc.deck_id;
