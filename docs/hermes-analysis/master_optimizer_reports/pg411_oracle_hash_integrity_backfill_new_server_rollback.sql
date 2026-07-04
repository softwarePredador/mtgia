BEGIN;

UPDATE public.card_battle_rules r
SET
  oracle_hash = b.oracle_hash,
  updated_at = b.updated_at,
  notes = b.notes
FROM manaloom_deploy_audit.pg411_oracle_hash_integrity_backfill_new_server_20260704_152449 b
WHERE r.normalized_name = b.normalized_name
  AND r.logical_rule_key = b.logical_rule_key;

COMMIT;
