\pset pager off
\set ON_ERROR_STOP on

BEGIN;

DO $$
DECLARE
  v_backup_rows integer;
BEGIN
  IF to_regclass('manaloom_deploy_audit.rule_competing_scope_cleanup_20260714') IS NULL THEN
    RAISE EXCEPTION 'rollback backup is missing';
  END IF;
  SELECT COUNT(*) INTO v_backup_rows
  FROM manaloom_deploy_audit.rule_competing_scope_cleanup_20260714;
  IF v_backup_rows <> 9 THEN
    RAISE EXCEPTION 'rollback backup expected 9 rows, got %', v_backup_rows;
  END IF;
END $$;

UPDATE card_battle_rules current_rule
SET
  review_status = backup.review_status,
  execution_status = backup.execution_status,
  notes = backup.notes,
  updated_at = backup.updated_at
FROM manaloom_deploy_audit.rule_competing_scope_cleanup_20260714 backup
WHERE current_rule.normalized_name = backup.normalized_name
  AND current_rule.logical_rule_key = backup.logical_rule_key;

DO $$
DECLARE
  v_restored_rows integer;
BEGIN
  SELECT COUNT(*) INTO v_restored_rows
  FROM card_battle_rules current_rule
  JOIN manaloom_deploy_audit.rule_competing_scope_cleanup_20260714 backup
    ON current_rule.normalized_name = backup.normalized_name
   AND current_rule.logical_rule_key = backup.logical_rule_key
  WHERE current_rule.review_status = backup.review_status
    AND current_rule.execution_status = backup.execution_status
    AND current_rule.notes IS NOT DISTINCT FROM backup.notes
    AND current_rule.updated_at = backup.updated_at;
  IF v_restored_rows <> 9 THEN
    RAISE EXCEPTION 'rollback expected 9 restored rows, got %', v_restored_rows;
  END IF;
END $$;

COMMIT;
