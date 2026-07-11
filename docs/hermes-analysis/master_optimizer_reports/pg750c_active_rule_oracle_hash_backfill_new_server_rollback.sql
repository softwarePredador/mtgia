BEGIN;

UPDATE card_battle_rules cbr
SET
  oracle_hash = backup.oracle_hash,
  updated_at = backup.updated_at
FROM manaloom_deploy_audit.pg750c_active_rule_oracle_hash_backfill_new_server_20260711 backup
WHERE cbr.card_id = backup.card_id
  AND cbr.logical_rule_key = backup.logical_rule_key
  AND cbr.normalized_name = backup.normalized_name;

COMMIT;
