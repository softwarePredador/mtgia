BEGIN;

UPDATE public.card_battle_rules r
SET
  oracle_hash = b.oracle_hash,
  notes = b.notes,
  updated_at = b.updated_at
FROM manaloom_deploy_audit.pg764b_trusted_rule_oracle_hash_backfill_new_server_20260711 b
WHERE b.normalized_name = r.normalized_name
  AND b.logical_rule_key = r.logical_rule_key;

COMMIT;
