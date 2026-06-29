BEGIN;

CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit;

DO $$
BEGIN
  IF to_regclass('manaloom_deploy_audit.pgc061_basic_land_compensation_runtime_20260629') IS NOT NULL THEN
    RAISE EXCEPTION 'PGC061 backup table already exists';
  END IF;
END $$;

CREATE TABLE manaloom_deploy_audit.pgc061_basic_land_compensation_runtime_20260629 AS
SELECT *
FROM public.card_battle_rules
WHERE (normalized_name = 'erode'
   AND logical_rule_key = 'battle_rule_v1:dd175af9c77feea940de97138a916fe3')
   OR (normalized_name = 'sundering eruption // volcanic fissure'
   AND logical_rule_key = 'battle_rule_v1:98d0006543fc622cfc1d82991bd5a66a');

DO $$
DECLARE
  updated_count integer;
BEGIN
  UPDATE public.card_battle_rules r
  SET
    effect_json = r.effect_json || CASE r.logical_rule_key
      WHEN 'battle_rule_v1:dd175af9c77feea940de97138a916fe3' THEN $json${
        "basic_land_compensation_status": "runtime_executor_v1",
        "basic_land_compensation_count": 1,
        "basic_land_compensation_destination": "battlefield_tapped",
        "battle_model_scope": "destroy_creature_or_planeswalker_target_controller_basic_land_tapped_runtime_v1",
        "oracle_runtime_scope": "target_controller_basic_land_search_to_battlefield_tapped_runtime_v1",
        "shuffle_after_basic_land_compensation": true
      }$json$::jsonb
      WHEN 'battle_rule_v1:98d0006543fc622cfc1d82991bd5a66a' THEN $json${
        "basic_land_compensation_status": "runtime_executor_v1",
        "basic_land_compensation_count": 1,
        "basic_land_compensation_destination": "battlefield_tapped",
        "battle_model_scope": "destroy_target_land_target_controller_basic_land_tapped_runtime_nonfliers_cant_block_annotation_v1",
        "oracle_runtime_scope": "target_controller_basic_land_search_to_battlefield_tapped_runtime_v1",
        "shuffle_after_basic_land_compensation": true
      }$json$::jsonb
      ELSE '{}'::jsonb
    END,
    rule_version = greatest(r.rule_version + 1, 3),
    reviewed_by = 'codex-pgc061',
    reviewed_at = now(),
    updated_at = now(),
    last_seen_at = now(),
    notes = concat_ws(
      E'\n',
      nullif(r.notes, ''),
      'PGC061: promoted target-controller basic land compensation from annotation_only to runtime_executor_v1 after generic no-override package validation.'
    )
  WHERE (
      (
        r.normalized_name = 'erode'
        AND r.logical_rule_key = 'battle_rule_v1:dd175af9c77feea940de97138a916fe3'
        AND r.oracle_hash = 'fade62a3cbc3e6987d7988b711a5a834'
      )
      OR (
        r.normalized_name = 'sundering eruption // volcanic fissure'
        AND r.logical_rule_key = 'battle_rule_v1:98d0006543fc622cfc1d82991bd5a66a'
        AND r.oracle_hash = '09148a5a6f4d14c04a30bf19819e20b8'
      )
    )
    AND r.review_status = 'verified'
    AND r.execution_status = 'auto';

  GET DIAGNOSTICS updated_count = ROW_COUNT;
  IF updated_count <> 2 THEN
    RAISE EXCEPTION 'PGC061 expected to update 2 basic land compensation rows, updated %', updated_count;
  END IF;
END $$;

COMMIT;
