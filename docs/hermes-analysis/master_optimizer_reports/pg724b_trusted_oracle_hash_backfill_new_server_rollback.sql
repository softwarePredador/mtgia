BEGIN;

UPDATE public.card_battle_rules br
SET
  oracle_hash = backup.oracle_hash,
  notes = backup.notes,
  updated_at = now()
FROM manaloom_deploy_audit.pg724b_trusted_oracle_hash_backfill_new_server_20260710 backup
WHERE backup.normalized_name = br.normalized_name
  AND backup.logical_rule_key = br.logical_rule_key;

COMMIT;
