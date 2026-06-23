BEGIN;

CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit;

DO $$
BEGIN
  IF to_regclass('manaloom_deploy_audit.pg073_deck6_l4_card_flow_20260623_051141') IS NOT NULL THEN
    RAISE EXCEPTION 'PG073 backup table already exists';
  END IF;
END $$;

CREATE TABLE manaloom_deploy_audit.pg073_deck6_l4_card_flow_20260623_051141 AS
SELECT now() AS backed_up_at, to_jsonb(cbr) AS payload
FROM card_battle_rules cbr
WHERE cbr.normalized_name IN ('esper sentinel', 'wheel of misfortune');

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
      c.name = 'Esper Sentinel'
      AND md5(coalesce(c.oracle_text, '')) = 'd8e8e60e34140942af13aa1be250a961'
    )
    OR (
      c.name = 'Wheel of Misfortune'
      AND md5(coalesce(c.oracle_text, '')) = 'fa744c33b4bc56c05977ec9c378e5b7d'
    );

  SELECT count(*)
  INTO v_rules
  FROM card_battle_rules
  WHERE normalized_name IN ('esper sentinel', 'wheel of misfortune');

  SELECT count(*)
  INTO v_specific
  FROM card_battle_rules
  WHERE (normalized_name = 'esper sentinel'
      AND logical_rule_key = 'battle_rule_v1:83dbd32fed8c770f977cd7b1fcd2883d')
    OR (normalized_name = 'wheel of misfortune'
      AND logical_rule_key = 'battle_rule_v1:402155f35799993b812ca441586017cd');

  IF v_cards <> 2 THEN
    RAISE EXCEPTION 'PG073 precondition failed: expected 2 target cards with current oracle hashes, got %', v_cards;
  END IF;
  IF v_rules <> 4 THEN
    RAISE EXCEPTION 'PG073 precondition failed: expected 4 target rules, got %', v_rules;
  END IF;
  IF v_specific <> 2 THEN
    RAISE EXCEPTION 'PG073 precondition failed: expected 2 existing curated runtime rows, got %', v_specific;
  END IF;
END $$;

UPDATE card_battle_rules
SET
  oracle_hash = 'fa744c33b4bc56c05977ec9c378e5b7d',
  effect_json = effect_json || jsonb_build_object(
    'effect', 'draw_cards',
    'count', 7,
    'wheel_like', true,
    'misfortune_secret_number_model', true,
    'controller_secret_number', 7,
    'opponent_secret_number', 0,
    'secret_number_choice_model', 'compact_controller_draw_count_opponents_zero_v1',
    'damage_model_status', 'runtime_highest_number_damage',
    'discard_draw_model', 'runtime_non_lowest_discard_draw_seven',
    'hidden_choice_status', 'compact_deterministic_not_full_secret_choice_equilibrium',
    'battle_model_scope', 'wheel_of_misfortune_secret_number_damage_discard_draw_compact_v1',
    'oracle_runtime_scope', 'secret_number_highest_damage_non_lowest_discard_draw_seven_compact_v1'
  ),
  deck_role_json = deck_role_json || jsonb_build_object(
    'effect', 'draw_cards',
    'category', 'draw',
    'subtype', 'wheel',
    'choice_model', 'compact_secret_number'
  ),
  confidence = 0.960,
  rule_version = greatest(rule_version, 2),
  reviewed_by = 'codex-auditor',
  reviewed_at = now(),
  updated_at = now(),
  last_seen_at = now(),
  notes = concat_ws(
    E'\n',
    nullif(notes, ''),
    'PG073: replaced generic draw-seven with Wheel of Misfortune compact secret-number runtime: controller chooses 7, opponents choose 0 by default, highest number takes damage, non-lowest players discard/draw seven. Full hidden-choice equilibrium remains compact-mode only.'
  )
WHERE normalized_name = 'wheel of misfortune'
  AND logical_rule_key = 'battle_rule_v1:402155f35799993b812ca441586017cd';

UPDATE card_battle_rules
SET
  review_status = 'deprecated',
  execution_status = 'disabled',
  updated_at = now(),
  last_seen_at = now(),
  notes = concat_ws(
    E'\n',
    nullif(notes, ''),
    'PG073: disabled superseded generated review-only row after scoped card-flow runtime validation.'
  )
WHERE normalized_name IN ('esper sentinel', 'wheel of misfortune')
  AND logical_rule_key = 'battle_rule_v1:3bd7f7866ce30619d4d92b4e9e7b520e';

COMMIT;
