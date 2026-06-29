BEGIN;

CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit;

DO $$
BEGIN
  IF to_regclass('manaloom_deploy_audit.pgc067_buyback_runtime_20260629') IS NOT NULL THEN
    RAISE EXCEPTION 'PGC067 backup table already exists';
  END IF;
END $$;

CREATE TABLE manaloom_deploy_audit.pgc067_buyback_runtime_20260629 AS
SELECT *
FROM public.card_battle_rules
WHERE normalized_name = 'reiterate'
  AND logical_rule_key = 'battle_rule_v1:18eeabc2a2fa631d99caf65a43a8c405'
  AND oracle_hash = '996fb5f02f16605ff7f1c899f2c50f60';

DO $$
DECLARE
  updated_count integer;
BEGIN
  UPDATE public.card_battle_rules r
  SET
    effect_json = r.effect_json || $json${
      "battle_model_scope": "copy_stack_instant_or_sorcery_new_targets_runtime_buyback_runtime_v1",
      "buyback_status": "runtime_executor_v1",
      "buyback_cost": "{3}",
      "oracle_runtime_scope": "copy_target_instant_or_sorcery_stack_spell_choose_new_targets_buyback_runtime_v1"
    }$json$::jsonb,
    rule_version = greatest(r.rule_version + 1, 3),
    reviewed_by = 'codex-pgc067',
    reviewed_at = now(),
    updated_at = now(),
    last_seen_at = now(),
    notes = concat_ws(
      E'\n',
      nullif(r.notes, ''),
      'PGC067: promoted Reiterate buyback_status from annotation_only to runtime_executor_v1 after response-copy validation. Runtime pays optional {3} buyback when available and returns the resolved spell to hand; otherwise it resolves to graveyard.'
    )
  WHERE r.normalized_name = 'reiterate'
    AND r.logical_rule_key = 'battle_rule_v1:18eeabc2a2fa631d99caf65a43a8c405'
    AND r.oracle_hash = '996fb5f02f16605ff7f1c899f2c50f60'
    AND r.review_status IN ('active', 'verified')
    AND r.execution_status = 'auto';

  GET DIAGNOSTICS updated_count = ROW_COUNT;
  IF updated_count <> 1 THEN
    RAISE EXCEPTION 'PGC067 expected to update 1 Reiterate row, updated %', updated_count;
  END IF;
END $$;

COMMIT;
