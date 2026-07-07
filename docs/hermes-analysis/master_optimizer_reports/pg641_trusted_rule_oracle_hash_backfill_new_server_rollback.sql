\echo 'PG641 trusted rule oracle_hash backfill rollback'

BEGIN;

UPDATE public.card_battle_rules r
SET
  oracle_hash = b.previous_oracle_hash,
  updated_at = COALESCE(b.previous_updated_at, r.updated_at),
  notes = b.previous_notes
FROM manaloom_deploy_audit.pg641_trusted_rule_oracle_hash_backfill_new_server_20260707 b
WHERE b.normalized_name = r.normalized_name
  AND b.logical_rule_key = r.logical_rule_key;

COMMIT;
