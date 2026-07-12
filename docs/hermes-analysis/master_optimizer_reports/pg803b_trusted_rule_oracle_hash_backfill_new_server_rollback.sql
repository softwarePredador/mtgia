\echo 'PG803B trusted rule oracle_hash backfill rollback'

BEGIN;

UPDATE public.card_battle_rules br
SET
  oracle_hash = backup.oracle_hash,
  updated_at = NOW(),
  notes = CONCAT_WS(
    E'\n',
    NULLIF(br.notes, ''),
    'PG803B rollback: restored pre-backfill oracle_hash value.'
  )
FROM manaloom_deploy_audit.pg803b_trusted_rule_oracle_hash_backfill_new_server_20260712 backup
WHERE br.card_id = backup.card_id
  AND br.normalized_name = backup.normalized_name
  AND br.logical_rule_key = backup.logical_rule_key
  AND br.source = backup.source
  AND br.notes LIKE '%PG803B: backfilled oracle_hash%';

COMMIT;
