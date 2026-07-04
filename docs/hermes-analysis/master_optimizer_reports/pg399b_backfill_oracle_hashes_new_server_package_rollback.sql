BEGIN;

UPDATE public.card_battle_rules r
SET
  oracle_hash = b.oracle_hash,
  notes = b.notes,
  updated_at = now()
FROM manaloom_deploy_audit.pg399b_backfill_oracle_hashes_new_server_2 b
WHERE r.normalized_name = b.normalized_name
  AND r.logical_rule_key = b.logical_rule_key;

COMMIT;
