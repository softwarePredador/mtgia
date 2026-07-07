BEGIN;

UPDATE public.card_battle_rules r
SET
  oracle_hash = b.oracle_hash,
  notes = b.notes,
  updated_at = now()
FROM manaloom_deploy_audit.pg637_trusted_oracle_hash_backfill_new_server_20260707_202000 b
WHERE b.normalized_name = r.normalized_name
  AND b.logical_rule_key = r.logical_rule_key;

COMMIT;
