\pset pager off
\set ON_ERROR_STOP on

BEGIN;

CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit;

CREATE TABLE IF NOT EXISTS manaloom_deploy_audit.pg026_lorehold_magus_sphere_deck_swap_20260622_165810 (
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
  v_electroduplicate_id uuid;
  v_victory_chimes_id uuid;
  v_magus_id uuid;
  v_sphere_id uuid;
  v_deck_rows integer;
  v_deck_qty integer;
  v_electro_rows integer;
  v_electro_qty integer;
  v_electro_commander boolean;
  v_victory_rows integer;
  v_victory_qty integer;
  v_victory_commander boolean;
  v_magus_rows integer;
  v_sphere_rows integer;
  v_magus_legal integer;
  v_sphere_legal integer;
  v_magus_rule_rows integer;
  v_sphere_rule_rows integer;
  v_existing_backup integer;
BEGIN
  SELECT (array_agg(id ORDER BY id::text))[1] INTO v_electroduplicate_id
  FROM cards WHERE lower(name) = 'electroduplicate';
  SELECT (array_agg(id ORDER BY id::text))[1] INTO v_victory_chimes_id
  FROM cards WHERE lower(name) = 'victory chimes';
  SELECT (array_agg(id ORDER BY id::text))[1] INTO v_magus_id
  FROM cards WHERE lower(name) = 'magus of the moat';
  SELECT (array_agg(id ORDER BY id::text))[1] INTO v_sphere_id
  FROM cards WHERE lower(name) = 'sphere of safety';

  IF v_electroduplicate_id IS NULL OR v_victory_chimes_id IS NULL
    OR v_magus_id IS NULL OR v_sphere_id IS NULL THEN
    RAISE EXCEPTION 'PG026 card identity resolution failed: electro=%, victory=%, magus=%, sphere=%',
      v_electroduplicate_id, v_victory_chimes_id, v_magus_id, v_sphere_id;
  END IF;

  IF (SELECT count(*) FROM cards WHERE lower(name) = 'electroduplicate') <> 1
    OR (SELECT count(*) FROM cards WHERE lower(name) = 'victory chimes') <> 1
    OR (SELECT count(*) FROM cards WHERE lower(name) = 'magus of the moat') <> 1
    OR (SELECT count(*) FROM cards WHERE lower(name) = 'sphere of safety') <> 1 THEN
    RAISE EXCEPTION 'PG026 card identity uniqueness failed';
  END IF;

  SELECT count(*), coalesce(sum(quantity), 0)
  INTO v_deck_rows, v_deck_qty
  FROM deck_cards
  WHERE deck_id = v_deck_id;

  SELECT
    count(*) FILTER (WHERE card_id = v_electroduplicate_id),
    coalesce(sum(quantity) FILTER (WHERE card_id = v_electroduplicate_id), 0),
    coalesce(bool_or(is_commander) FILTER (WHERE card_id = v_electroduplicate_id), false),
    count(*) FILTER (WHERE card_id = v_victory_chimes_id),
    coalesce(sum(quantity) FILTER (WHERE card_id = v_victory_chimes_id), 0),
    coalesce(bool_or(is_commander) FILTER (WHERE card_id = v_victory_chimes_id), false),
    count(*) FILTER (WHERE card_id = v_magus_id),
    count(*) FILTER (WHERE card_id = v_sphere_id)
  INTO
    v_electro_rows,
    v_electro_qty,
    v_electro_commander,
    v_victory_rows,
    v_victory_qty,
    v_victory_commander,
    v_magus_rows,
    v_sphere_rows
  FROM deck_cards
  WHERE deck_id = v_deck_id;

  SELECT count(*) INTO v_magus_legal
  FROM card_legalities
  WHERE card_id = v_magus_id AND format = 'commander' AND status = 'legal';

  SELECT count(*) INTO v_sphere_legal
  FROM card_legalities
  WHERE card_id = v_sphere_id AND format = 'commander' AND status = 'legal';

  SELECT count(*) INTO v_magus_rule_rows
  FROM card_battle_rules
  WHERE card_id = v_magus_id
    AND logical_rule_key = 'battle_rule_v1:439de5be33887bbce5dde1cfb367774a'
    AND source = 'curated'
    AND review_status = 'verified'
    AND execution_status = 'auto'
    AND effect_json->>'effect' = 'attack_limit'
    AND effect_json->>'battle_model_scope' = 'magus_of_the_moat_global_flying_attack_filter_v2';

  SELECT count(*) INTO v_sphere_rule_rows
  FROM card_battle_rules
  WHERE card_id = v_sphere_id
    AND logical_rule_key = 'battle_rule_v1:a619518cf24caa68fdd86b555687f20f'
    AND source = 'curated'
    AND review_status = 'verified'
    AND execution_status = 'auto'
    AND effect_json->>'effect' = 'attack_tax'
    AND effect_json->>'battle_model_scope' = 'sphere_of_safety_enchantment_scaled_attack_tax';

  SELECT count(*) INTO v_existing_backup
  FROM manaloom_deploy_audit.pg026_lorehold_magus_sphere_deck_swap_20260622_165810
  WHERE deck_id = v_deck_id;

  IF v_existing_backup <> 0 THEN
    RAISE EXCEPTION 'PG026 backup table already has % row(s) for deck %, refusing reapply',
      v_existing_backup, v_deck_id;
  END IF;

  IF v_deck_rows <> 100 OR v_deck_qty <> 100 THEN
    RAISE EXCEPTION 'PG026 deck shape guard failed: rows=%, qty=%', v_deck_rows, v_deck_qty;
  END IF;

  IF v_electro_rows <> 1 OR v_electro_qty <> 1 OR v_electro_commander THEN
    RAISE EXCEPTION 'PG026 Electroduplicate guard failed: rows=%, qty=%, is_commander=%',
      v_electro_rows, v_electro_qty, v_electro_commander;
  END IF;

  IF v_victory_rows <> 1 OR v_victory_qty <> 1 OR v_victory_commander THEN
    RAISE EXCEPTION 'PG026 Victory Chimes guard failed: rows=%, qty=%, is_commander=%',
      v_victory_rows, v_victory_qty, v_victory_commander;
  END IF;

  IF v_magus_rows <> 0 OR v_sphere_rows <> 0 THEN
    RAISE EXCEPTION 'PG026 candidate pre-existence guard failed: magus_rows=%, sphere_rows=%',
      v_magus_rows, v_sphere_rows;
  END IF;

  IF v_magus_legal <> 1 OR v_sphere_legal <> 1 THEN
    RAISE EXCEPTION 'PG026 legality guard failed: magus_legal=%, sphere_legal=%',
      v_magus_legal, v_sphere_legal;
  END IF;

  IF v_magus_rule_rows <> 1 OR v_sphere_rule_rows <> 1 THEN
    RAISE EXCEPTION 'PG026 rule guard failed: magus_rule_rows=%, sphere_rule_rows=%',
      v_magus_rule_rows, v_sphere_rule_rows;
  END IF;

  INSERT INTO manaloom_deploy_audit.pg026_lorehold_magus_sphere_deck_swap_20260622_165810 (
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
    'PG026 battle-validated deck correction: Magus of the Moat + Sphere of Safety over Electroduplicate + Victory Chimes. Comparable table-intent 16-seed evidence: official 20260622_165220 was 1/16; candidate 20260622_164720 was 6/16; all mandatory gates passed.',
    dc.deck_id,
    dc.id,
    dc.card_id,
    old_card.name,
    CASE WHEN dc.card_id = v_electroduplicate_id THEN v_magus_id ELSE v_sphere_id END,
    CASE WHEN dc.card_id = v_electroduplicate_id THEN magus.name ELSE sphere.name END,
    dc.quantity,
    dc.is_commander,
    dc.condition
  FROM deck_cards dc
  JOIN cards old_card ON old_card.id = dc.card_id
  JOIN cards magus ON magus.id = v_magus_id
  JOIN cards sphere ON sphere.id = v_sphere_id
  WHERE dc.deck_id = v_deck_id
    AND dc.card_id IN (v_electroduplicate_id, v_victory_chimes_id);

  UPDATE deck_cards
  SET card_id = CASE
    WHEN card_id = v_electroduplicate_id THEN v_magus_id
    WHEN card_id = v_victory_chimes_id THEN v_sphere_id
    ELSE card_id
  END
  WHERE deck_id = v_deck_id
    AND card_id IN (v_electroduplicate_id, v_victory_chimes_id);

  IF NOT FOUND THEN
    RAISE EXCEPTION 'PG026 update affected no rows';
  END IF;
END $$;

COMMIT;

WITH target AS (
  SELECT '528c877f-f829-4207-95e6-73981776c323'::uuid AS deck_id
)
SELECT
  'pg026_lorehold_magus_sphere_apply' AS check_name,
  count(*) FILTER (WHERE lower(c.name) = 'electroduplicate') AS electroduplicate_rows,
  count(*) FILTER (WHERE lower(c.name) = 'victory chimes') AS victory_chimes_rows,
  count(*) FILTER (WHERE lower(c.name) = 'magus of the moat') AS magus_rows,
  count(*) FILTER (WHERE lower(c.name) = 'sphere of safety') AS sphere_rows,
  coalesce(sum(dc.quantity), 0) AS total_quantity
FROM deck_cards dc
JOIN cards c ON c.id = dc.card_id
JOIN target t ON t.deck_id = dc.deck_id;
