\pset pager off
\set ON_ERROR_STOP on

BEGIN;

DO $$
DECLARE
  v_deck_backup_rows integer;
  v_rule_backup_rows integer;
BEGIN
  SELECT count(*)
  INTO v_deck_backup_rows
  FROM manaloom_deploy_audit.pg023_lorehold_brainstone_deck_swap_20260621_114447_deck
  WHERE deck_id = '528c877f-f829-4207-95e6-73981776c323'::uuid;

  SELECT count(*)
  INTO v_rule_backup_rows
  FROM manaloom_deploy_audit.pg023_lorehold_brainstone_deck_swap_20260621_114447_rule
  WHERE normalized_name = 'brainstone'
    AND logical_rule_key = 'battle_rule_v1:03bed5506a427743723cd7676c6a67d9';

  IF v_deck_backup_rows <> 1 OR v_rule_backup_rows <> 1 THEN
    RAISE EXCEPTION 'PG023 rollback backup guard failed: deck_backup=%, rule_backup=%',
      v_deck_backup_rows, v_rule_backup_rows;
  END IF;

  UPDATE deck_cards dc
  SET card_id = b.old_card_id
  FROM manaloom_deploy_audit.pg023_lorehold_brainstone_deck_swap_20260621_114447_deck b
  WHERE dc.id = b.deck_card_id
    AND dc.deck_id = b.deck_id
    AND dc.card_id = b.new_card_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'PG023 rollback deck update affected no rows';
  END IF;

  UPDATE card_battle_rules r
  SET
    card_id = b.card_id,
    card_name = b.card_name,
    effect_json = b.effect_json,
    deck_role_json = b.deck_role_json,
    source = b.source,
    confidence = b.confidence,
    review_status = b.review_status,
    execution_status = b.execution_status,
    rule_version = b.rule_version,
    oracle_hash = b.oracle_hash,
    notes = b.notes,
    reviewed_by = b.reviewed_by,
    reviewed_at = b.reviewed_at,
    created_at = b.created_at,
    updated_at = now(),
    last_seen_at = b.last_seen_at
  FROM manaloom_deploy_audit.pg023_lorehold_brainstone_deck_swap_20260621_114447_rule b
  WHERE r.normalized_name = b.normalized_name
    AND r.logical_rule_key = b.logical_rule_key;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'PG023 rollback rule update affected no rows';
  END IF;
END $$;

COMMIT;

WITH target AS (
  SELECT '528c877f-f829-4207-95e6-73981776c323'::uuid AS deck_id
)
SELECT
  'pg023_lorehold_brainstone_rollback' AS check_name,
  count(*) FILTER (WHERE lower(c.name) = 'generous gift') AS gift_rows,
  count(*) FILTER (WHERE lower(c.name) = 'brainstone') AS brainstone_rows,
  coalesce(sum(dc.quantity), 0) AS total_quantity
FROM deck_cards dc
JOIN cards c ON c.id = dc.card_id
JOIN target t ON t.deck_id = dc.deck_id;
