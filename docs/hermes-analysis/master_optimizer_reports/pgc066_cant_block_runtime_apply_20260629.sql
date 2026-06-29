BEGIN;

CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit;

DO $$
BEGIN
  IF to_regclass('manaloom_deploy_audit.pgc066_cant_block_runtime_20260629') IS NOT NULL THEN
    RAISE EXCEPTION 'PGC066 backup table already exists';
  END IF;
END $$;

CREATE TABLE manaloom_deploy_audit.pgc066_cant_block_runtime_20260629 AS
SELECT *
FROM public.card_battle_rules
WHERE (
    normalized_name = 'sundering eruption // volcanic fissure'
    AND logical_rule_key = 'battle_rule_v1:98d0006543fc622cfc1d82991bd5a66a'
    AND oracle_hash = '09148a5a6f4d14c04a30bf19819e20b8'
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
      WHEN 'sundering eruption // volcanic fissure' THEN $json${
        "battle_model_scope": "destroy_target_land_target_controller_basic_land_tapped_runtime_nonfliers_cant_block_runtime_v1",
        "cant_block_mode_status": "runtime_executor_v1",
        "oracle_runtime_scope": "target_controller_basic_land_search_to_battlefield_tapped_nonfliers_cant_block_runtime_v1"
      }$json$::jsonb
      WHEN 'untimely malfunction' THEN $json${
        "battle_model_scope": "modal_destroy_artifact_redirect_target_cant_block_runtime_v1",
        "cant_block_mode_status": "runtime_executor_v1",
        "oracle_runtime_scope": "destroy_target_artifact_redirect_target_cant_block_runtime_v1"
      }$json$::jsonb
      ELSE '{}'::jsonb
    END,
    rule_version = greatest(r.rule_version + 1, 4),
    reviewed_by = 'codex-pgc066',
    reviewed_at = now(),
    updated_at = now(),
    last_seen_at = now(),
    notes = concat_ws(
      E'\n',
      nullif(r.notes, ''),
      'PGC066: promoted cant_block_mode_status from annotation_only to runtime_executor_v1 after no-override combat validation. Untimely target-creature mode applies cant_block until EOT without destroying the creature; Sundering nonfliers rider affects creatures without flying until EOT.'
    )
  WHERE (
      (
        r.normalized_name = 'sundering eruption // volcanic fissure'
        AND r.logical_rule_key = 'battle_rule_v1:98d0006543fc622cfc1d82991bd5a66a'
        AND r.oracle_hash = '09148a5a6f4d14c04a30bf19819e20b8'
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
    RAISE EXCEPTION 'PGC066 expected to update 2 cant-block rows, updated %', updated_count;
  END IF;
END $$;

COMMIT;
