BEGIN;

DO $$
BEGIN
  IF to_regclass('manaloom_deploy_audit.pgc067_buyback_runtime_20260629') IS NULL THEN
    RAISE EXCEPTION 'PGC067 backup table is missing';
  END IF;
END $$;

UPDATE public.card_battle_rules r
SET
  effect_json = b.effect_json,
  source = b.source,
  confidence = b.confidence,
  review_status = b.review_status,
  execution_status = b.execution_status,
  rule_version = b.rule_version,
  oracle_hash = b.oracle_hash,
  notes = b.notes,
  reviewed_by = b.reviewed_by,
  reviewed_at = b.reviewed_at,
  updated_at = now()
FROM manaloom_deploy_audit.pgc067_buyback_runtime_20260629 b
WHERE r.normalized_name = b.normalized_name
  AND r.logical_rule_key = b.logical_rule_key;

COMMIT;
