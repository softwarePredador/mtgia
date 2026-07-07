-- PG634 rollback: restore backed-up rows to their pre-backfill oracle_hash/review metadata.
-- Run only if PG634 postcheck fails.

BEGIN;

WITH backup AS (
  SELECT *
  FROM manaloom_deploy_audit.pg634_trusted_rule_oracle_hash_backfill_20260707
)
UPDATE public.card_battle_rules cbr
SET oracle_hash = backup.oracle_hash,
    reviewed_by = backup.reviewed_by,
    reviewed_at = backup.reviewed_at,
    updated_at = CURRENT_TIMESTAMP,
    notes = concat_ws(
      E'\n',
      NULLIF(backup.notes, ''),
      'PG634 rollback 2026-07-07: restored oracle_hash/review metadata from deploy audit backup.'
    )
FROM backup
WHERE cbr.normalized_name = backup.normalized_name
  AND cbr.logical_rule_key = backup.logical_rule_key;

COMMIT;
