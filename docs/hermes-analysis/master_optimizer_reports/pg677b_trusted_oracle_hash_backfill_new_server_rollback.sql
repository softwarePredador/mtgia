BEGIN;

UPDATE card_battle_rules r
SET
  oracle_hash = nullif(b.previous_oracle_hash, ''),
  updated_at = now()
FROM manaloom_deploy_audit.pg677b_trusted_oracle_hash_backfill_backup b
WHERE b.deploy_id = 'pg677b'
  AND b.card_id = r.card_id
  AND b.normalized_name = r.normalized_name
  AND b.logical_rule_key = r.logical_rule_key;

COMMIT;
