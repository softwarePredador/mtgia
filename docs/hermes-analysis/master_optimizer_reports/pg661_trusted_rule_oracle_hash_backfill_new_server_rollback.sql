\echo 'PG661 trusted rule oracle_hash backfill rollback'

BEGIN;

UPDATE public.card_battle_rules r
SET
  oracle_hash = b.oracle_hash,
  updated_at = now(),
  notes = concat_ws(
    E'\n',
    NULLIF(r.notes, ''),
    'PG661 rollback 2026-07-08: restored previous oracle_hash from deploy audit backup.'
  )
FROM manaloom_deploy_audit.pg661_trusted_rule_oracle_hash_backfill_new_server_20260708 b
WHERE r.normalized_name = b.normalized_name
  AND r.logical_rule_key = b.logical_rule_key;

COMMIT;
