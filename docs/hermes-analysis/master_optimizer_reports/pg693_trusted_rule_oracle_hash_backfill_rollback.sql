BEGIN;

UPDATE card_battle_rules b
SET
  oracle_hash = backup.old_oracle_hash,
  updated_at = now()
FROM manaloom_deploy_audit.pg693_trusted_rule_oracle_hash_backfill_backup backup
WHERE b.normalized_name = backup.normalized_name
  AND b.logical_rule_key = backup.logical_rule_key;

COMMIT;
