BEGIN;

CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit;

DO $$
BEGIN
  IF to_regclass('manaloom_deploy_audit.pgc064_copy_spell_choose_new_targets_runtime_20260629') IS NOT NULL THEN
    RAISE EXCEPTION 'PGC064 backup table already exists';
  END IF;
END $$;

CREATE TABLE manaloom_deploy_audit.pgc064_copy_spell_choose_new_targets_runtime_20260629 AS
SELECT *
FROM public.card_battle_rules
WHERE (
    normalized_name = 'dualcaster mage'
    AND logical_rule_key = 'battle_rule_v1:e176019b87d68d22e2388e08a4efbf55'
    AND oracle_hash = 'e26f613394b72e9724d299512983218a'
  )
  OR (
    normalized_name = 'reverberate'
    AND logical_rule_key = 'battle_rule_v1:0269136edf067f696c8576740b720e14'
    AND oracle_hash = 'cbae05dee4261e3ed5412fd5f3591c17'
  )
  OR (
    normalized_name = 'reiterate'
    AND logical_rule_key = 'battle_rule_v1:18eeabc2a2fa631d99caf65a43a8c405'
    AND oracle_hash = '996fb5f02f16605ff7f1c899f2c50f60'
  );

DO $$
DECLARE
  updated_count integer;
BEGIN
  UPDATE public.card_battle_rules r
  SET
    effect_json = r.effect_json || CASE r.normalized_name
      WHEN 'dualcaster mage' THEN $json${
        "battle_model_scope": "creature_etb_copy_stack_instant_or_sorcery_new_targets_runtime_v1",
        "choose_new_targets_status": "runtime_executor_v1",
        "copy_target_selection_status": "runtime_executor_v1",
        "copy_target_selection_pipeline": "copy_spell_runtime_choose_new_targets_v1",
        "oracle_runtime_scope": "copy_target_instant_or_sorcery_stack_spell_choose_new_targets_runtime_v1"
      }$json$::jsonb
      WHEN 'reverberate' THEN $json${
        "battle_model_scope": "copy_stack_instant_or_sorcery_new_targets_runtime_v1",
        "choose_new_targets_status": "runtime_executor_v1",
        "copy_target_selection_status": "runtime_executor_v1",
        "copy_target_selection_pipeline": "copy_spell_runtime_choose_new_targets_v1",
        "oracle_runtime_scope": "copy_target_instant_or_sorcery_stack_spell_choose_new_targets_runtime_v1"
      }$json$::jsonb
      WHEN 'reiterate' THEN $json${
        "battle_model_scope": "copy_stack_instant_or_sorcery_new_targets_runtime_buyback_annotation_v1",
        "choose_new_targets_status": "runtime_executor_v1",
        "copy_target_selection_status": "runtime_executor_v1",
        "copy_target_selection_pipeline": "copy_spell_runtime_choose_new_targets_v1",
        "oracle_runtime_scope": "copy_target_instant_or_sorcery_stack_spell_choose_new_targets_runtime_v1"
      }$json$::jsonb
      ELSE '{}'::jsonb
    END,
    rule_version = greatest(r.rule_version + 1, 2),
    reviewed_by = 'codex-pgc064',
    reviewed_at = now(),
    updated_at = now(),
    last_seen_at = now(),
    notes = concat_ws(
      E'\n',
      nullif(r.notes, ''),
      'PGC064: promoted may-choose-new-targets copy-spell selection from annotation_only to runtime_executor_v1 after stack-copy target-selection executor validation. Reiterate buyback remains annotation_only.'
    )
  WHERE (
      (
        r.normalized_name = 'dualcaster mage'
        AND r.logical_rule_key = 'battle_rule_v1:e176019b87d68d22e2388e08a4efbf55'
        AND r.oracle_hash = 'e26f613394b72e9724d299512983218a'
      )
      OR (
        r.normalized_name = 'reverberate'
        AND r.logical_rule_key = 'battle_rule_v1:0269136edf067f696c8576740b720e14'
        AND r.oracle_hash = 'cbae05dee4261e3ed5412fd5f3591c17'
      )
      OR (
        r.normalized_name = 'reiterate'
        AND r.logical_rule_key = 'battle_rule_v1:18eeabc2a2fa631d99caf65a43a8c405'
        AND r.oracle_hash = '996fb5f02f16605ff7f1c899f2c50f60'
      )
    )
    AND r.review_status IN ('active', 'verified')
    AND r.execution_status = 'auto';

  GET DIAGNOSTICS updated_count = ROW_COUNT;
  IF updated_count <> 3 THEN
    RAISE EXCEPTION 'PGC064 expected to update 3 copy-spell rows, updated %', updated_count;
  END IF;
END $$;

COMMIT;
