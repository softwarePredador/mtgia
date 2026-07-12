\echo 'PG843B trusted rule oracle_hash backfill rollback'

BEGIN;

UPDATE card_battle_rules br
SET
  oracle_hash = backup.old_oracle_hash,
  notes = backup.old_notes,
  updated_at = backup.old_updated_at
FROM manaloom_deploy_audit.pg843b_hash_backfill_20260712 backup
WHERE br.card_id = backup.card_id
  AND br.normalized_name = backup.normalized_name
  AND br.logical_rule_key = backup.logical_rule_key
  AND br.source = backup.source;

COMMIT;
