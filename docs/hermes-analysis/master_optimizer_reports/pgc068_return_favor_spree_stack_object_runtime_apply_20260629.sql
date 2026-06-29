BEGIN;

CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit;

DO $$
BEGIN
  IF to_regclass('manaloom_deploy_audit.pgc068_return_favor_spree_stack_object_runtime_20260629') IS NOT NULL THEN
    RAISE EXCEPTION 'PGC068 backup table already exists';
  END IF;
END $$;

CREATE TABLE manaloom_deploy_audit.pgc068_return_favor_spree_stack_object_runtime_20260629 AS
SELECT *
FROM public.card_battle_rules
WHERE normalized_name = 'return the favor'
  AND logical_rule_key = 'battle_rule_v1:fb3ee27205e34477fa9753b38433e9a2'
  AND oracle_hash = 'a24911b7ea2027ebba59bb6792eee776';

DO $$
DECLARE
  updated_count integer;
BEGIN
  UPDATE public.card_battle_rules r
  SET
    effect_json = r.effect_json || $json${
      "battle_model_scope": "spree_copy_stack_object_change_target_selected_mode_runtime_v1",
      "target": "stack_object",
      "copy_stack_object_types": [
        "instant_spell",
        "sorcery_spell",
        "activated_ability",
        "triggered_ability"
      ],
      "spree": true,
      "spree_additional_cost_status": "runtime_executor_v1",
      "spree_selected_mode_cost_status": "runtime_executor_v1",
      "spree_mode_costs": {
        "copy_instant_or_sorcery_spell": "{1}",
        "change_single_target": "{1}"
      },
      "copy_activated_triggered_ability_status": "runtime_executor_v1",
      "change_target_mode_status": "runtime_executor_v1",
      "target_change_pipeline": "single_target_stack_object_redirect_runtime_v1",
      "oracle_runtime_scope": "copy_stack_object_or_change_single_target_spree_selected_mode_runtime_v1"
    }$json$::jsonb,
    rule_version = greatest(r.rule_version + 1, 4),
    reviewed_by = 'codex-pgc068',
    reviewed_at = now(),
    updated_at = now(),
    last_seen_at = now(),
    notes = concat_ws(
      E'\n',
      nullif(r.notes, ''),
      'PGC068: promoted Return the Favor spree selected-mode additional costs and activated/triggered ability stack-object copy from annotation_only to runtime_executor_v1. Runtime pays {R}{R}+{1} for selected copy/change-target response modes, can copy triggered or activated ability stack objects, and preserves the existing single-target redirect executor.'
    )
  WHERE r.normalized_name = 'return the favor'
    AND r.logical_rule_key = 'battle_rule_v1:fb3ee27205e34477fa9753b38433e9a2'
    AND r.oracle_hash = 'a24911b7ea2027ebba59bb6792eee776'
    AND r.review_status IN ('active', 'verified')
    AND r.execution_status = 'auto';

  GET DIAGNOSTICS updated_count = ROW_COUNT;
  IF updated_count <> 1 THEN
    RAISE EXCEPTION 'PGC068 expected to update 1 Return the Favor row, updated %', updated_count;
  END IF;
END $$;

COMMIT;
