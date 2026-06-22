\pset pager off
\set ON_ERROR_STOP on

BEGIN;

CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit;

CREATE TABLE IF NOT EXISTS manaloom_deploy_audit.pg023_lorehold_brainstone_deck_swap_20260621_114447_deck (
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

CREATE TABLE IF NOT EXISTS manaloom_deploy_audit.pg023_lorehold_brainstone_deck_swap_20260621_114447_rule (
  backup_id bigserial PRIMARY KEY,
  backed_up_at timestamptz NOT NULL DEFAULT now(),
  reason text NOT NULL,
  normalized_name text NOT NULL,
  logical_rule_key text NOT NULL,
  card_id uuid,
  card_name text NOT NULL,
  effect_json jsonb NOT NULL,
  deck_role_json jsonb NOT NULL,
  source text NOT NULL,
  confidence numeric(4,3) NOT NULL,
  review_status text NOT NULL,
  execution_status text NOT NULL,
  rule_version integer NOT NULL,
  oracle_hash text,
  notes text,
  reviewed_by text,
  reviewed_at timestamptz,
  created_at timestamptz,
  updated_at timestamptz,
  last_seen_at timestamptz
);

DO $$
DECLARE
  v_deck_id uuid := '528c877f-f829-4207-95e6-73981776c323'::uuid;
  v_gift_id uuid;
  v_brainstone_id uuid;
  v_gift_printings integer;
  v_brainstone_printings integer;
  v_deck_rows integer;
  v_deck_qty integer;
  v_gift_rows integer;
  v_gift_qty integer;
  v_gift_is_commander boolean;
  v_brainstone_rows integer;
  v_brainstone_qty integer;
  v_brainstone_legal integer;
  v_brainstone_color text;
  v_rule_rows integer;
  v_rule_ready boolean;
  v_existing_deck_backup integer;
  v_existing_rule_backup integer;
BEGIN
  SELECT (array_agg(id ORDER BY id::text))[1], count(*)
  INTO v_gift_id, v_gift_printings
  FROM cards
  WHERE lower(name) = 'generous gift';

  SELECT (array_agg(id ORDER BY id::text))[1], count(*)
  INTO v_brainstone_id, v_brainstone_printings
  FROM cards
  WHERE lower(name) = 'brainstone';

  IF v_gift_id IS NULL OR v_brainstone_id IS NULL THEN
    RAISE EXCEPTION 'PG023 card identity resolution failed: gift=%, brainstone=%',
      v_gift_id, v_brainstone_id;
  END IF;

  IF v_gift_printings <> 1 OR v_brainstone_printings <> 1 THEN
    RAISE EXCEPTION 'PG023 card identity uniqueness failed: gift_printings=%, brainstone_printings=%',
      v_gift_printings, v_brainstone_printings;
  END IF;

  SELECT count(*), coalesce(sum(quantity), 0)
  INTO v_deck_rows, v_deck_qty
  FROM deck_cards
  WHERE deck_id = v_deck_id;

  SELECT
    count(*) FILTER (WHERE card_id = v_gift_id),
    coalesce(sum(quantity) FILTER (WHERE card_id = v_gift_id), 0),
    coalesce(bool_or(is_commander) FILTER (WHERE card_id = v_gift_id), false),
    count(*) FILTER (WHERE card_id = v_brainstone_id),
    coalesce(sum(quantity) FILTER (WHERE card_id = v_brainstone_id), 0)
  INTO
    v_gift_rows,
    v_gift_qty,
    v_gift_is_commander,
    v_brainstone_rows,
    v_brainstone_qty
  FROM deck_cards
  WHERE deck_id = v_deck_id;

  SELECT count(*)
  INTO v_brainstone_legal
  FROM card_legalities
  WHERE card_id = v_brainstone_id
    AND format = 'commander'
    AND status = 'legal';

  SELECT color_identity::text
  INTO v_brainstone_color
  FROM cards
  WHERE id = v_brainstone_id;

  SELECT
    count(*) FILTER (
      WHERE logical_rule_key = 'battle_rule_v1:03bed5506a427743723cd7676c6a67d9'
    ),
    bool_or(
      logical_rule_key = 'battle_rule_v1:03bed5506a427743723cd7676c6a67d9'
      AND source = 'curated'
      AND review_status IN ('active', 'verified')
      AND execution_status = 'auto'
      AND effect_json->>'battle_model_scope' = 'brainstone_draw_three_put_two_back_unexecuted_v1'
      AND effect_json->>'effect' = 'topdeck_manipulation'
    )
  INTO v_rule_rows, v_rule_ready
  FROM card_battle_rules
  WHERE normalized_name = 'brainstone';

  SELECT count(*)
  INTO v_existing_deck_backup
  FROM manaloom_deploy_audit.pg023_lorehold_brainstone_deck_swap_20260621_114447_deck
  WHERE deck_id = v_deck_id;

  SELECT count(*)
  INTO v_existing_rule_backup
  FROM manaloom_deploy_audit.pg023_lorehold_brainstone_deck_swap_20260621_114447_rule
  WHERE normalized_name = 'brainstone'
    AND logical_rule_key = 'battle_rule_v1:03bed5506a427743723cd7676c6a67d9';

  IF v_existing_deck_backup <> 0 OR v_existing_rule_backup <> 0 THEN
    RAISE EXCEPTION 'PG023 backup already exists: deck_backup=%, rule_backup=%',
      v_existing_deck_backup, v_existing_rule_backup;
  END IF;

  IF v_deck_rows <> 100 OR v_deck_qty <> 100 THEN
    RAISE EXCEPTION 'PG023 deck shape guard failed: rows=%, qty=%',
      v_deck_rows, v_deck_qty;
  END IF;

  IF v_gift_rows <> 1 OR v_gift_qty <> 1 OR v_gift_is_commander THEN
    RAISE EXCEPTION 'PG023 Generous Gift guard failed: rows=%, qty=%, is_commander=%',
      v_gift_rows, v_gift_qty, v_gift_is_commander;
  END IF;

  IF v_brainstone_rows <> 0 OR v_brainstone_qty <> 0 THEN
    RAISE EXCEPTION 'PG023 Brainstone pre-existence guard failed: rows=%, qty=%',
      v_brainstone_rows, v_brainstone_qty;
  END IF;

  IF v_brainstone_legal <> 1 OR v_brainstone_color <> '{}' THEN
    RAISE EXCEPTION 'PG023 Brainstone legality/color guard failed: legal_rows=%, color=%',
      v_brainstone_legal, v_brainstone_color;
  END IF;

  IF v_rule_rows <> 1 OR NOT coalesce(v_rule_ready, false) THEN
    RAISE EXCEPTION 'PG023 Brainstone rule guard failed: rows=%, ready=%',
      v_rule_rows, v_rule_ready;
  END IF;

  INSERT INTO manaloom_deploy_audit.pg023_lorehold_brainstone_deck_swap_20260621_114447_deck (
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
    'Corrected 64-seed battle after PG022: Brainstone over Generous Gift improved Lorehold from 8/64 to 14/64 with clean mandatory gates; net +6 seed wins.',
    dc.deck_id,
    dc.id,
    dc.card_id,
    old_card.name,
    v_brainstone_id,
    new_card.name,
    dc.quantity,
    dc.is_commander,
    dc.condition
  FROM deck_cards dc
  JOIN cards old_card ON old_card.id = dc.card_id
  JOIN cards new_card ON new_card.id = v_brainstone_id
  WHERE dc.deck_id = v_deck_id
    AND dc.card_id = v_gift_id;

  INSERT INTO manaloom_deploy_audit.pg023_lorehold_brainstone_deck_swap_20260621_114447_rule (
    reason,
    normalized_name,
    logical_rule_key,
    card_id,
    card_name,
    effect_json,
    deck_role_json,
    source,
    confidence,
    review_status,
    execution_status,
    rule_version,
    oracle_hash,
    notes,
    reviewed_by,
    reviewed_at,
    created_at,
    updated_at,
    last_seen_at
  )
  SELECT
    'Brainstone rule promoted to verified after PG023 64-seed candidate validation and targeted miracle/stack tests.',
    normalized_name,
    logical_rule_key,
    card_id,
    card_name,
    effect_json,
    deck_role_json,
    source,
    confidence,
    review_status,
    execution_status,
    rule_version,
    oracle_hash,
    notes,
    reviewed_by,
    reviewed_at,
    created_at,
    updated_at,
    last_seen_at
  FROM card_battle_rules
  WHERE normalized_name = 'brainstone'
    AND logical_rule_key = 'battle_rule_v1:03bed5506a427743723cd7676c6a67d9';

  UPDATE deck_cards
  SET card_id = v_brainstone_id
  WHERE deck_id = v_deck_id
    AND card_id = v_gift_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'PG023 deck update affected no rows';
  END IF;

  UPDATE card_battle_rules
  SET
    review_status = 'verified',
    execution_status = 'auto',
    reviewed_by = 'codex-central-auditor',
    reviewed_at = now(),
    updated_at = now(),
    notes = concat_ws(E'\n',
      notes,
      'PG-023: verified after 20260621_080706 64-seed candidate battle, targeted Brainstone miracle tests, and clean mandatory gates.'
    )
  WHERE normalized_name = 'brainstone'
    AND logical_rule_key = 'battle_rule_v1:03bed5506a427743723cd7676c6a67d9';

  IF NOT FOUND THEN
    RAISE EXCEPTION 'PG023 rule update affected no rows';
  END IF;
END $$;

COMMIT;

WITH target AS (
  SELECT '528c877f-f829-4207-95e6-73981776c323'::uuid AS deck_id
)
SELECT
  'pg023_lorehold_brainstone_apply' AS check_name,
  count(*) FILTER (WHERE lower(c.name) = 'generous gift') AS gift_rows,
  count(*) FILTER (WHERE lower(c.name) = 'brainstone') AS brainstone_rows,
  coalesce(sum(dc.quantity), 0) AS total_quantity
FROM deck_cards dc
JOIN cards c ON c.id = dc.card_id
JOIN target t ON t.deck_id = dc.deck_id;
