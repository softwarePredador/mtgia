BEGIN;

UPDATE public.card_battle_rules r
SET
  oracle_hash = b.previous_oracle_hash,
  updated_at = b.previous_updated_at
FROM manaloom_deploy_audit.pg604b_trusted_rule_oracle_hash_backfill_new_server_backup b
WHERE r.card_id = b.card_id
  AND r.logical_rule_key = b.logical_rule_key;

COMMIT;
