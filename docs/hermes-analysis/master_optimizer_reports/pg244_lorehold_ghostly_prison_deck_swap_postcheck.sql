\pset pager off
\set ON_ERROR_STOP on

-- PG244 postcheck: verify the PostgreSQL materialized Lorehold deck now
-- contains Ghostly Prison and no Promise of Loyalty while preserving 100/100.

WITH target AS (
  SELECT '528c877f-f829-4207-95e6-73981776c323'::uuid AS deck_id
),
resolved_cards AS (
  SELECT
    (array_agg(c.id ORDER BY c.id::text) FILTER (WHERE lower(c.name) = 'promise of loyalty'))[1] AS promise_id,
    (array_agg(c.id ORDER BY c.id::text) FILTER (WHERE lower(c.name) = 'ghostly prison'))[1] AS ghostly_prison_id
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
    COUNT(*) FILTER (WHERE dc.card_id = rc.promise_id) AS promise_rows,
    COALESCE(SUM(dc.quantity) FILTER (WHERE dc.card_id = rc.promise_id), 0) AS promise_qty,
    COUNT(*) FILTER (WHERE dc.card_id = rc.ghostly_prison_id) AS ghostly_prison_rows,
    COALESCE(SUM(dc.quantity) FILTER (WHERE dc.card_id = rc.ghostly_prison_id), 0) AS ghostly_prison_qty,
    COALESCE(BOOL_OR(dc.is_commander) FILTER (WHERE dc.card_id = rc.ghostly_prison_id), false) AS ghostly_prison_is_commander
  FROM target t
  CROSS JOIN resolved_cards rc
  LEFT JOIN deck_cards dc ON dc.deck_id = t.deck_id
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
backup AS (
  SELECT COUNT(*) AS backup_rows
  FROM manaloom_deploy_audit.pg244_lorehold_ghostly_prison_deck_swap_20260627
  WHERE deck_id = (SELECT deck_id FROM target)
)
SELECT
  'pg244_lorehold_ghostly_prison_deck_swap_postcheck' AS check_name,
  ds.deck_rows,
  ds.deck_quantity,
  cc.promise_rows,
  cc.promise_qty,
  cc.ghostly_prison_rows,
  cc.ghostly_prison_qty,
  cc.ghostly_prison_is_commander,
  gr.verified_rule_rows AS ghostly_prison_verified_rule_rows,
  backup.backup_rows,
  (
    ds.deck_rows = 100
    AND ds.deck_quantity = 100
    AND cc.promise_rows = 0
    AND cc.promise_qty = 0
    AND cc.ghostly_prison_rows = 1
    AND cc.ghostly_prison_qty = 1
    AND cc.ghostly_prison_is_commander = false
    AND gr.verified_rule_rows = 1
    AND backup.backup_rows = 1
  ) AS postcheck_passed
FROM deck_shape ds
CROSS JOIN current_cards cc
CROSS JOIN ghostly_rule gr
CROSS JOIN backup;
