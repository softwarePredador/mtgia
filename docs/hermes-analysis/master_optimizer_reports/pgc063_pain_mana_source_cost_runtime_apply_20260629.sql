BEGIN;

CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit;

DO $$
BEGIN
  IF to_regclass('manaloom_deploy_audit.pgc063_pain_mana_source_cost_runtime_20260629') IS NOT NULL THEN
    RAISE EXCEPTION 'PGC063 backup table already exists';
  END IF;
END $$;

CREATE TABLE manaloom_deploy_audit.pgc063_pain_mana_source_cost_runtime_20260629 AS
SELECT *
FROM public.card_battle_rules
WHERE (
    normalized_name = 'city of brass'
    AND logical_rule_key = 'battle_rule_v1:603c776839827f2f21cef8b62e22a1be'
    AND oracle_hash = '969b41c45b968319b44f77454c6ac55b'
  )
  OR (
    normalized_name = 'elves of deep shadow'
    AND logical_rule_key = 'battle_rule_v1:1272fb910383d34360702e343ec16b37'
    AND oracle_hash = '5dd30cbea74064369bcba667795049e2'
  )
  OR (
    normalized_name = 'mana confluence'
    AND logical_rule_key = 'battle_rule_v1:603c776839827f2f21cef8b62e22a1be'
    AND oracle_hash = '11173c5296485bfd3cdd28822d4634e9'
  )
  OR (
    normalized_name = 'tarnished citadel'
    AND logical_rule_key = 'battle_rule_v1:d5663032352408a845b7602f9cb5adf9'
    AND oracle_hash = 'd8bdb24e586e16274f0bd42e40e2dc58'
  );

DO $$
DECLARE
  updated_count integer;
BEGIN
  UPDATE public.card_battle_rules r
  SET
    effect_json = r.effect_json || CASE r.normalized_name
      WHEN 'city of brass' THEN $json${
        "battle_model_scope": "five_color_tap_damage_land_runtime_v1",
        "tap_damage_status": "runtime_executor_v1",
        "damage_on_tap": 1,
        "conditional_mana_modes_status": "runtime_executor_v1",
        "conditional_mana_modes": [
          {"color": "W", "mode": "damage_on_tap", "restriction": "any_spell", "status": "runtime_executor_v1", "life_loss_on_spend": 1, "life_loss_kind": "damage_on_tap", "life_loss_status": "tap_damage_status"},
          {"color": "U", "mode": "damage_on_tap", "restriction": "any_spell", "status": "runtime_executor_v1", "life_loss_on_spend": 1, "life_loss_kind": "damage_on_tap", "life_loss_status": "tap_damage_status"},
          {"color": "B", "mode": "damage_on_tap", "restriction": "any_spell", "status": "runtime_executor_v1", "life_loss_on_spend": 1, "life_loss_kind": "damage_on_tap", "life_loss_status": "tap_damage_status"},
          {"color": "R", "mode": "damage_on_tap", "restriction": "any_spell", "status": "runtime_executor_v1", "life_loss_on_spend": 1, "life_loss_kind": "damage_on_tap", "life_loss_status": "tap_damage_status"},
          {"color": "G", "mode": "damage_on_tap", "restriction": "any_spell", "status": "runtime_executor_v1", "life_loss_on_spend": 1, "life_loss_kind": "damage_on_tap", "life_loss_status": "tap_damage_status"}
        ],
        "oracle_runtime_scope": "pain_mana_source_life_cost_runtime_v1"
      }$json$::jsonb
      WHEN 'elves of deep shadow' THEN $json${
        "battle_model_scope": "one_mana_one_one_black_pain_mana_dork_runtime_v1",
        "tap_damage_status": "runtime_executor_v1",
        "damage_on_tap": 1,
        "conditional_mana_modes_status": "runtime_executor_v1",
        "conditional_mana_modes": [
          {"color": "B", "mode": "damage_on_tap", "restriction": "any_spell", "status": "runtime_executor_v1", "life_loss_on_spend": 1, "life_loss_kind": "damage_on_tap", "life_loss_status": "tap_damage_status"}
        ],
        "oracle_runtime_scope": "pain_mana_source_life_cost_runtime_v1"
      }$json$::jsonb
      WHEN 'mana confluence' THEN $json${
        "battle_model_scope": "five_color_life_paid_land_runtime_v1",
        "life_payment_status": "runtime_executor_v1",
        "life_payment": 1,
        "conditional_mana_modes_status": "runtime_executor_v1",
        "conditional_mana_modes": [
          {"color": "W", "mode": "pay_life_activation", "restriction": "any_spell", "status": "runtime_executor_v1", "life_loss_on_spend": 1, "life_loss_kind": "pay_life_activation", "life_loss_status": "life_payment_status"},
          {"color": "U", "mode": "pay_life_activation", "restriction": "any_spell", "status": "runtime_executor_v1", "life_loss_on_spend": 1, "life_loss_kind": "pay_life_activation", "life_loss_status": "life_payment_status"},
          {"color": "B", "mode": "pay_life_activation", "restriction": "any_spell", "status": "runtime_executor_v1", "life_loss_on_spend": 1, "life_loss_kind": "pay_life_activation", "life_loss_status": "life_payment_status"},
          {"color": "R", "mode": "pay_life_activation", "restriction": "any_spell", "status": "runtime_executor_v1", "life_loss_on_spend": 1, "life_loss_kind": "pay_life_activation", "life_loss_status": "life_payment_status"},
          {"color": "G", "mode": "pay_life_activation", "restriction": "any_spell", "status": "runtime_executor_v1", "life_loss_on_spend": 1, "life_loss_kind": "pay_life_activation", "life_loss_status": "life_payment_status"}
        ],
        "oracle_runtime_scope": "pain_mana_source_life_cost_runtime_v1"
      }$json$::jsonb
      WHEN 'tarnished citadel' THEN $json${
        "battle_model_scope": "colorless_or_any_color_pain_land_runtime_v1",
        "life_loss_on_colored_mana_status": "runtime_executor_v1",
        "life_for_colored_mana": 3,
        "conditional_mana_modes_status": "runtime_executor_v1",
        "conditional_mana_modes": [
          {"color": "C", "mode": "colorless_no_life_loss", "restriction": "any_spell", "status": "runtime_executor_v1", "life_loss_on_spend": 0, "life_loss_kind": "none", "life_loss_status": "runtime_executor_v1"},
          {"color": "W", "mode": "damage_on_colored_mana", "restriction": "any_spell", "status": "runtime_executor_v1", "life_loss_on_spend": 3, "life_loss_kind": "damage_on_colored_mana", "life_loss_status": "life_loss_on_colored_mana_status"},
          {"color": "U", "mode": "damage_on_colored_mana", "restriction": "any_spell", "status": "runtime_executor_v1", "life_loss_on_spend": 3, "life_loss_kind": "damage_on_colored_mana", "life_loss_status": "life_loss_on_colored_mana_status"},
          {"color": "B", "mode": "damage_on_colored_mana", "restriction": "any_spell", "status": "runtime_executor_v1", "life_loss_on_spend": 3, "life_loss_kind": "damage_on_colored_mana", "life_loss_status": "life_loss_on_colored_mana_status"},
          {"color": "R", "mode": "damage_on_colored_mana", "restriction": "any_spell", "status": "runtime_executor_v1", "life_loss_on_spend": 3, "life_loss_kind": "damage_on_colored_mana", "life_loss_status": "life_loss_on_colored_mana_status"},
          {"color": "G", "mode": "damage_on_colored_mana", "restriction": "any_spell", "status": "runtime_executor_v1", "life_loss_on_spend": 3, "life_loss_kind": "damage_on_colored_mana", "life_loss_status": "life_loss_on_colored_mana_status"}
        ],
        "oracle_runtime_scope": "pain_mana_source_life_cost_runtime_v1"
      }$json$::jsonb
      ELSE '{}'::jsonb
    END,
    rule_version = greatest(r.rule_version + 1, 3),
    reviewed_by = 'codex-pgc063',
    reviewed_at = now(),
    updated_at = now(),
    last_seen_at = now(),
    notes = concat_ws(
      E'\n',
      nullif(r.notes, ''),
      'PGC063: promoted pain/five-color mana source life/damage costs from annotation_only to runtime_executor_v1 after no-override spend validation.'
    )
  WHERE (
      (
        r.normalized_name = 'city of brass'
        AND r.logical_rule_key = 'battle_rule_v1:603c776839827f2f21cef8b62e22a1be'
        AND r.oracle_hash = '969b41c45b968319b44f77454c6ac55b'
      )
      OR (
        r.normalized_name = 'elves of deep shadow'
        AND r.logical_rule_key = 'battle_rule_v1:1272fb910383d34360702e343ec16b37'
        AND r.oracle_hash = '5dd30cbea74064369bcba667795049e2'
      )
      OR (
        r.normalized_name = 'mana confluence'
        AND r.logical_rule_key = 'battle_rule_v1:603c776839827f2f21cef8b62e22a1be'
        AND r.oracle_hash = '11173c5296485bfd3cdd28822d4634e9'
      )
      OR (
        r.normalized_name = 'tarnished citadel'
        AND r.logical_rule_key = 'battle_rule_v1:d5663032352408a845b7602f9cb5adf9'
        AND r.oracle_hash = 'd8bdb24e586e16274f0bd42e40e2dc58'
      )
    )
    AND r.review_status = 'verified'
    AND r.execution_status = 'auto';

  GET DIAGNOSTICS updated_count = ROW_COUNT;
  IF updated_count <> 4 THEN
    RAISE EXCEPTION 'PGC063 expected to update 4 pain mana source rows, updated %', updated_count;
  END IF;
END $$;

COMMIT;
