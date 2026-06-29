BEGIN;

CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit;

DO $$
BEGIN
  IF to_regclass('manaloom_deploy_audit.pgc065_modal_target_change_runtime_20260629') IS NOT NULL THEN
    RAISE EXCEPTION 'PGC065 backup table already exists';
  END IF;
END $$;

CREATE TABLE manaloom_deploy_audit.pgc065_modal_target_change_runtime_20260629 AS
SELECT *
FROM public.card_battle_rules
WHERE (
    normalized_name = 'return the favor'
    AND logical_rule_key = 'battle_rule_v1:fb3ee27205e34477fa9753b38433e9a2'
    AND oracle_hash = 'a24911b7ea2027ebba59bb6792eee776'
  )
  OR (
    normalized_name = 'untimely malfunction'
    AND logical_rule_key = 'battle_rule_v1:667ba8e5e69696402f9cd213886e57a8'
    AND oracle_hash = '877f2d75c90c7886ca9536135829bb90'
  );

DO $$
DECLARE
  updated_count integer;
BEGIN
  UPDATE public.card_battle_rules r
  SET
    effect_json = r.effect_json || CASE r.normalized_name
      WHEN 'return the favor' THEN $json${
        "battle_model_scope": "spree_copy_instant_or_sorcery_stack_spell_change_target_runtime_v1",
        "change_target_mode_status": "runtime_executor_v1",
        "target_change_pipeline": "single_target_stack_object_redirect_runtime_v1",
        "oracle_runtime_scope": "copy_target_instant_or_sorcery_stack_spell_spree_change_target_runtime_partial_v1"
      }$json$::jsonb
      WHEN 'untimely malfunction' THEN $json${
        "battle_model_scope": "modal_destroy_artifact_redirect_runtime_cant_block_annotation_v1",
        "redirect_target_mode_status": "runtime_executor_v1",
        "target_change_pipeline": "single_target_stack_object_redirect_runtime_v1",
        "oracle_runtime_scope": "destroy_target_artifact_redirect_runtime_cant_block_annotation_v1"
      }$json$::jsonb
      ELSE '{}'::jsonb
    END,
    rule_version = greatest(r.rule_version + 1, 3),
    reviewed_by = 'codex-pgc065',
    reviewed_at = now(),
    updated_at = now(),
    last_seen_at = now(),
    notes = concat_ws(
      E'\n',
      nullif(r.notes, ''),
      'PGC065: promoted modal single-target stack redirect/change-target modes from annotation_only to runtime_executor_v1 after no-override priority response validation. Spree/copy-ability/cant-block residuals remain annotation_only.'
    )
  WHERE (
      (
        r.normalized_name = 'return the favor'
        AND r.logical_rule_key = 'battle_rule_v1:fb3ee27205e34477fa9753b38433e9a2'
        AND r.oracle_hash = 'a24911b7ea2027ebba59bb6792eee776'
      )
      OR (
        r.normalized_name = 'untimely malfunction'
        AND r.logical_rule_key = 'battle_rule_v1:667ba8e5e69696402f9cd213886e57a8'
        AND r.oracle_hash = '877f2d75c90c7886ca9536135829bb90'
      )
    )
    AND r.review_status = 'verified'
    AND r.execution_status = 'auto';

  GET DIAGNOSTICS updated_count = ROW_COUNT;
  IF updated_count <> 2 THEN
    RAISE EXCEPTION 'PGC065 expected to update 2 modal target-change rows, updated %', updated_count;
  END IF;
END $$;

COMMIT;
