BEGIN;

CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit;

DO $$
BEGIN
  IF to_regclass('manaloom_deploy_audit.pgc062_conditional_etb_lands_runtime_20260629') IS NOT NULL THEN
    RAISE EXCEPTION 'PGC062 backup table already exists';
  END IF;
END $$;

CREATE TABLE manaloom_deploy_audit.pgc062_conditional_etb_lands_runtime_20260629 AS
SELECT *
FROM public.card_battle_rules
WHERE logical_rule_key = 'battle_rule_v1:603c776839827f2f21cef8b62e22a1be'
  AND normalized_name IN ('clifftop retreat', 'inspiring vantage', 'sundown pass');

DO $$
DECLARE
  updated_count integer;
BEGIN
  UPDATE public.card_battle_rules r
  SET
    effect_json = r.effect_json || CASE r.normalized_name
      WHEN 'clifftop retreat' THEN $json${
        "battle_model_scope": "check_land_dual_source_etb_runtime_v1",
        "conditional_enters_tapped_status": "runtime_executor_v1",
        "conditional_enters_tapped_profile": "checkland",
        "enters_tapped_unless_control_land_subtypes": ["Mountain", "Plains"],
        "oracle_runtime_scope": "conditional_etb_checkland_subtype_runtime_v1"
      }$json$::jsonb
      WHEN 'inspiring vantage' THEN $json${
        "battle_model_scope": "fastland_dual_source_etb_runtime_v1",
        "conditional_enters_tapped_status": "runtime_executor_v1",
        "conditional_enters_tapped_profile": "fastland",
        "enters_tapped_if_control_lands_min": 3,
        "oracle_runtime_scope": "conditional_etb_fastland_other_land_count_runtime_v1"
      }$json$::jsonb
      WHEN 'sundown pass' THEN $json${
        "battle_model_scope": "slowland_dual_source_etb_runtime_v1",
        "conditional_enters_tapped_status": "runtime_executor_v1",
        "conditional_enters_tapped_profile": "slowland",
        "enters_tapped_unless_control_lands_min": 2,
        "oracle_runtime_scope": "conditional_etb_slowland_other_land_count_runtime_v1"
      }$json$::jsonb
      ELSE '{}'::jsonb
    END,
    rule_version = greatest(r.rule_version + 1, 2),
    reviewed_by = 'codex-pgc062',
    reviewed_at = now(),
    updated_at = now(),
    last_seen_at = now(),
    notes = concat_ws(
      E'\n',
      nullif(r.notes, ''),
      'PGC062: promoted conditional enters-tapped land clauses from annotation_only to runtime_executor_v1 after generic no-override land-play validation.'
    )
  WHERE r.logical_rule_key = 'battle_rule_v1:603c776839827f2f21cef8b62e22a1be'
    AND (
      (
        r.normalized_name = 'clifftop retreat'
        AND r.oracle_hash = '48ea345a9823024a12c03d458106af4e'
      )
      OR (
        r.normalized_name = 'inspiring vantage'
        AND r.oracle_hash = 'eb2813246000c2c0bfe218cb61fed144'
      )
      OR (
        r.normalized_name = 'sundown pass'
        AND r.oracle_hash = '2f86ee5bc9a587b6a45b4eddf98e663c'
      )
    )
    AND r.review_status = 'verified'
    AND r.execution_status = 'auto';

  GET DIAGNOSTICS updated_count = ROW_COUNT;
  IF updated_count <> 3 THEN
    RAISE EXCEPTION 'PGC062 expected to update 3 conditional ETB land rows, updated %', updated_count;
  END IF;
END $$;

COMMIT;
