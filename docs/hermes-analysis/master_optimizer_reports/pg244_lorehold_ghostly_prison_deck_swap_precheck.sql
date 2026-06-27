\pset pager off
\set ON_ERROR_STOP on

-- PG244 precheck: promote the battle-validated Lorehold pressure swap only
-- if the PostgreSQL materialized deck is still in the exact pre-apply state.

WITH target AS (
  SELECT '528c877f-f829-4207-95e6-73981776c323'::uuid AS deck_id
),
resolved_cards AS (
  SELECT
    (array_agg(c.id ORDER BY c.id::text) FILTER (WHERE lower(c.name) = 'promise of loyalty'))[1] AS promise_id,
    (array_agg(c.id ORDER BY c.id::text) FILTER (WHERE lower(c.name) = 'ghostly prison'))[1] AS ghostly_prison_id,
    COUNT(*) FILTER (WHERE lower(c.name) = 'promise of loyalty') AS promise_printings,
    COUNT(*) FILTER (WHERE lower(c.name) = 'ghostly prison') AS ghostly_prison_printings
  FROM cards c
  WHERE lower(c.name) IN ('promise of loyalty', 'ghostly prison')
),
deck_shape AS (
  SELECT COUNT(dc.id) AS deck_rows, COALESCE(SUM(dc.quantity), 0) AS deck_quantity
  FROM target t
  LEFT JOIN deck_cards dc ON dc.deck_id = t.deck_id
),
current_cards AS (
  SELECT
    COUNT(*) FILTER (WHERE dc.card_id = rc.promise_id) AS current_promise_rows,
    COALESCE(SUM(dc.quantity) FILTER (WHERE dc.card_id = rc.promise_id), 0) AS current_promise_qty,
    COALESCE(BOOL_OR(dc.is_commander) FILTER (WHERE dc.card_id = rc.promise_id), false) AS promise_is_commander,
    COUNT(*) FILTER (WHERE dc.card_id = rc.ghostly_prison_id) AS current_ghostly_prison_rows,
    COALESCE(SUM(dc.quantity) FILTER (WHERE dc.card_id = rc.ghostly_prison_id), 0) AS current_ghostly_prison_qty
  FROM target t
  CROSS JOIN resolved_cards rc
  LEFT JOIN deck_cards dc ON dc.deck_id = t.deck_id
),
ghostly_legality AS (
  SELECT COUNT(*) AS commander_legal_rows
  FROM card_legalities cl
  CROSS JOIN resolved_cards rc
  WHERE cl.card_id = rc.ghostly_prison_id
    AND cl.format = 'commander'
    AND cl.status = 'legal'
),
ghostly_color AS (
  SELECT (
    SELECT c.color_identity::text
    FROM cards c
    CROSS JOIN resolved_cards rc
    WHERE c.id = rc.ghostly_prison_id
  ) AS color_identity
),
ghostly_rule AS (
  SELECT COUNT(*) AS verified_rule_rows
  FROM card_battle_rules cbr
  CROSS JOIN resolved_cards rc
  WHERE cbr.card_id = rc.ghostly_prison_id
    AND cbr.logical_rule_key = 'battle_rule_v1:99151859bece89ba3ead032e05b1f65a'
    AND cbr.source = 'curated'
    AND cbr.review_status = 'verified'
    AND cbr.execution_status = 'auto'
    AND cbr.oracle_hash = '5725b39ca4bb7c5e8e4bebf0d246be13'
    AND cbr.effect_json->>'effect' = 'attack_tax'
    AND COALESCE((cbr.effect_json->>'attack_tax_per_creature')::int, 0) = 2
),
backup_state AS (
  SELECT COUNT(*) AS existing_backup_table_rows
  FROM information_schema.tables
  WHERE table_schema = 'manaloom_deploy_audit'
    AND table_name = 'pg244_lorehold_ghostly_prison_deck_swap_20260627'
)
SELECT
  'pg244_lorehold_ghostly_prison_deck_swap_precheck' AS check_name,
  d.name AS deck_name,
  d.format AS deck_format,
  ds.deck_rows,
  ds.deck_quantity,
  rc.promise_id::text AS promise_id,
  rc.ghostly_prison_id::text AS ghostly_prison_id,
  rc.promise_printings,
  rc.ghostly_prison_printings,
  cc.current_promise_rows,
  cc.current_promise_qty,
  cc.promise_is_commander,
  cc.current_ghostly_prison_rows,
  cc.current_ghostly_prison_qty,
  gl.commander_legal_rows AS ghostly_prison_commander_legal_rows,
  gc.color_identity AS ghostly_prison_color_identity,
  gr.verified_rule_rows AS ghostly_prison_verified_rule_rows,
  bs.existing_backup_table_rows,
  (
    d.format = 'commander'
    AND ds.deck_rows = 100
    AND ds.deck_quantity = 100
    AND rc.promise_printings = 1
    AND rc.ghostly_prison_printings = 1
    AND cc.current_promise_rows = 1
    AND cc.current_promise_qty = 1
    AND cc.promise_is_commander = false
    AND cc.current_ghostly_prison_rows = 0
    AND cc.current_ghostly_prison_qty = 0
    AND gl.commander_legal_rows = 1
    AND gc.color_identity = '{W}'
    AND gr.verified_rule_rows = 1
    AND bs.existing_backup_table_rows = 0
  ) AS ready_to_apply
FROM target t
JOIN decks d ON d.id = t.deck_id
CROSS JOIN resolved_cards rc
CROSS JOIN deck_shape ds
CROSS JOIN current_cards cc
CROSS JOIN ghostly_legality gl
CROSS JOIN ghostly_color gc
CROSS JOIN ghostly_rule gr
CROSS JOIN backup_state bs;
