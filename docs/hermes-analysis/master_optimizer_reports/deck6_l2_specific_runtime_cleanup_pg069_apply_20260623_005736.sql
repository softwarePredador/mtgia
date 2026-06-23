BEGIN;

CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit;

DO $$
BEGIN
  IF to_regclass('manaloom_deploy_audit.pg069_deck6_l2_specific_runtime_cleanup_20260623_005736') IS NOT NULL THEN
    RAISE EXCEPTION 'PG069 backup table already exists';
  END IF;
END $$;

CREATE TABLE manaloom_deploy_audit.pg069_deck6_l2_specific_runtime_cleanup_20260623_005736 AS
SELECT now() AS backed_up_at, to_jsonb(cbr) AS payload
FROM card_battle_rules cbr
WHERE cbr.normalized_name IN ('the one ring', 'unexpected windfall');

DO $$
DECLARE
  v_cards integer;
  v_rules integer;
  v_specific integer;
BEGIN
  SELECT count(*)
  INTO v_cards
  FROM cards c
  WHERE (
      c.name = 'The One Ring'
      AND md5(coalesce(c.oracle_text, '')) = '644d5305e6be932586a6d3b7325cadf7'
    )
    OR (
      c.name = 'Unexpected Windfall'
      AND md5(coalesce(c.oracle_text, '')) = '9c4fbe06104051a2e8b1d295d307b26a'
    );

  SELECT count(*)
  INTO v_rules
  FROM card_battle_rules
  WHERE normalized_name IN ('the one ring', 'unexpected windfall');

  SELECT count(*)
  INTO v_specific
  FROM card_battle_rules
  WHERE (normalized_name = 'the one ring'
      AND logical_rule_key = 'battle_rule_v1:a71907ee296b5801e92e8d7f1940dba1'
      AND effect_json->>'battle_model_scope' = 'the_one_ring_etb_protection_burden_draw_v1')
    OR (normalized_name = 'unexpected windfall'
      AND logical_rule_key = 'battle_rule_v1:f9f98ea1925518eea7a7c94c21ef2dc4'
      AND effect_json->>'battle_model_scope' = 'discard_draw_create_treasures_v1');

  IF v_cards <> 2 THEN
    RAISE EXCEPTION 'PG069 precondition failed: expected 2 target cards with current oracle hashes, got %', v_cards;
  END IF;
  IF v_rules <> 6 THEN
    RAISE EXCEPTION 'PG069 precondition failed: expected 6 target rules, got %', v_rules;
  END IF;
  IF v_specific <> 2 THEN
    RAISE EXCEPTION 'PG069 precondition failed: expected 2 existing specific runtime rows, got %', v_specific;
  END IF;
END $$;

UPDATE card_battle_rules
SET
  oracle_hash = '644d5305e6be932586a6d3b7325cadf7',
  effect_json = effect_json || jsonb_build_object(
    'oracle_runtime_scope', 'indestructible_cast_etb_protection_upkeep_burden_tap_draw_v1'
  ),
  rule_version = greatest(rule_version, 2),
  reviewed_by = coalesce(reviewed_by, 'codex-auditor'),
  reviewed_at = coalesce(reviewed_at, now()),
  updated_at = now(),
  last_seen_at = now(),
  notes = concat_ws(
    E'\n',
    nullif(notes, ''),
    'PG069: refreshed The One Ring oracle_hash from current PostgreSQL oracle text and kept existing scoped runtime semantics.'
  )
WHERE normalized_name = 'the one ring'
  AND logical_rule_key = 'battle_rule_v1:a71907ee296b5801e92e8d7f1940dba1';

UPDATE card_battle_rules
SET
  oracle_hash = '9c4fbe06104051a2e8b1d295d307b26a',
  effect_json = effect_json || jsonb_build_object(
    'oracle_runtime_scope', 'additional_cost_discard_draw_two_create_two_treasures_v1',
    'additional_cost_discard_status', 'runtime_required_card_discard'
  ),
  rule_version = greatest(rule_version, 2),
  reviewed_by = coalesce(reviewed_by, 'codex-auditor'),
  reviewed_at = coalesce(reviewed_at, now()),
  updated_at = now(),
  last_seen_at = now(),
  notes = concat_ws(
    E'\n',
    nullif(notes, ''),
    'PG069: added current oracle_hash and runtime-scope metadata for discard/draw/two Treasure executor.'
  )
WHERE normalized_name = 'unexpected windfall'
  AND logical_rule_key = 'battle_rule_v1:f9f98ea1925518eea7a7c94c21ef2dc4';

UPDATE card_battle_rules
SET
  review_status = 'deprecated',
  execution_status = 'disabled',
  updated_at = now(),
  last_seen_at = now(),
  notes = concat_ws(
    E'\n',
    nullif(notes, ''),
    'PG069: disabled superseded review-only or duplicate broad row after confirming a scoped runtime replacement.'
  )
WHERE normalized_name IN ('the one ring', 'unexpected windfall')
  AND logical_rule_key IN (
    'battle_rule_v1:cddd177eac9b084e9366e1448a48974c',
    'battle_rule_v1:ff9144b5fff75408e1a76a99888fdeca',
    'battle_rule_v1:b965bf2683a8977ac8a6c559ebc441ab'
  );

COMMIT;
