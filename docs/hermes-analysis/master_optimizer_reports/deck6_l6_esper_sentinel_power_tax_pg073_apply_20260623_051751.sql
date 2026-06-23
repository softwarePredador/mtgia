BEGIN;

CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit;

DO $$
BEGIN
  IF to_regclass('manaloom_deploy_audit.pg073_deck6_l6_esper_sentinel_power_tax_20260623_051751') IS NOT NULL THEN
    RAISE EXCEPTION 'PG073 backup table already exists';
  END IF;
END $$;

CREATE TABLE manaloom_deploy_audit.pg073_deck6_l6_esper_sentinel_power_tax_20260623_051751 AS
SELECT now() AS backed_up_at, to_jsonb(cbr) AS payload
FROM card_battle_rules cbr
WHERE cbr.normalized_name = 'esper sentinel';

DO $$
DECLARE
  v_cards integer;
  v_rules integer;
  v_specific integer;
BEGIN
  SELECT count(*)
  INTO v_cards
  FROM cards c
  WHERE c.name = 'Esper Sentinel'
    AND md5(coalesce(c.oracle_text, '')) = 'd8e8e60e34140942af13aa1be250a961';

  SELECT count(*)
  INTO v_rules
  FROM card_battle_rules
  WHERE normalized_name = 'esper sentinel';

  SELECT count(*)
  INTO v_specific
  FROM card_battle_rules
  WHERE normalized_name = 'esper sentinel'
    AND logical_rule_key = 'battle_rule_v1:83dbd32fed8c770f977cd7b1fcd2883d';

  IF v_cards <> 1 THEN
    RAISE EXCEPTION 'PG073 precondition failed: expected 1 Esper Sentinel with current oracle hash, got %', v_cards;
  END IF;
  IF v_rules <> 2 THEN
    RAISE EXCEPTION 'PG073 precondition failed: expected 2 Esper Sentinel rules, got %', v_rules;
  END IF;
  IF v_specific <> 1 THEN
    RAISE EXCEPTION 'PG073 precondition failed: expected 1 existing curated runtime row, got %', v_specific;
  END IF;
END $$;

UPDATE card_battle_rules
SET
  oracle_hash = 'd8e8e60e34140942af13aa1be250a961',
  effect_json = effect_json || jsonb_build_object(
    'effect', 'draw_engine',
    'trigger', 'opponent_noncreature_spell',
    'opponent_first_noncreature_spell_each_turn', true,
    'tax_amount_equals_source_power', true,
    'tax_payment_model', 'runtime_random_pay_if_available',
    'tax_payment_status', 'runtime_random_pay_if_available',
    'battle_model_scope', 'first_opponent_noncreature_spell_power_tax_draw_v1',
    'oracle_runtime_scope', 'opponent_first_noncreature_spell_each_turn_draw_unless_power_tax_v1'
  ),
  deck_role_json = deck_role_json || jsonb_build_object(
    'effect', 'draw_engine',
    'category', 'draw',
    'trigger', 'opponent_noncreature_spell',
    'trigger_cadence', 'first_each_turn',
    'tax', 'source_power'
  ),
  confidence = 0.970,
  rule_version = greatest(rule_version, 2),
  reviewed_by = 'codex-auditor',
  reviewed_at = now(),
  updated_at = now(),
  last_seen_at = now(),
  notes = concat_ws(
    E'\n',
    nullif(notes, ''),
    'PG073: scoped Esper Sentinel to first opponent noncreature spell each turn with source-power tax; compact runtime draws if caster does not pay.'
  )
WHERE normalized_name = 'esper sentinel'
  AND logical_rule_key = 'battle_rule_v1:83dbd32fed8c770f977cd7b1fcd2883d';

UPDATE card_battle_rules
SET
  review_status = 'deprecated',
  execution_status = 'disabled',
  updated_at = now(),
  last_seen_at = now(),
  notes = concat_ws(
    E'\n',
    nullif(notes, ''),
    'PG073: disabled superseded generated review-only row after first-noncreature power-tax runtime validation.'
  )
WHERE normalized_name = 'esper sentinel'
  AND logical_rule_key = 'battle_rule_v1:e9a2f41b86aad0a56d142873b1267daf';

COMMIT;
