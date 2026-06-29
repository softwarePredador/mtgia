BEGIN;

DO $$
BEGIN
  IF to_regclass('manaloom_deploy_audit.pgc065_modal_target_change_runtime_20260629') IS NULL THEN
    RAISE EXCEPTION 'PGC065 backup table is missing';
  END IF;
END $$;

UPDATE public.card_battle_rules current
SET
  effect_json = backup.effect_json,
  deck_role_json = backup.deck_role_json,
  source = backup.source,
  confidence = backup.confidence,
  review_status = backup.review_status,
  execution_status = backup.execution_status,
  rule_version = backup.rule_version,
  oracle_hash = backup.oracle_hash,
  notes = backup.notes,
  reviewed_by = backup.reviewed_by,
  reviewed_at = backup.reviewed_at,
  updated_at = now(),
  last_seen_at = backup.last_seen_at
FROM manaloom_deploy_audit.pgc065_modal_target_change_runtime_20260629 backup
WHERE current.normalized_name = backup.normalized_name
  AND current.logical_rule_key = backup.logical_rule_key;

COMMIT;
