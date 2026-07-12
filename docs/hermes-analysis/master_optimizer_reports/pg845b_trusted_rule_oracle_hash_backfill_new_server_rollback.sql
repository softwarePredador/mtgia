\echo 'PG845B trusted rule oracle_hash backfill rollback'

BEGIN;

UPDATE card_battle_rules br
SET
  oracle_hash = b.old_oracle_hash,
  notes = b.old_notes,
  updated_at = b.old_updated_at
FROM manaloom_deploy_audit.pg845b_trusted_rule_oracle_hash_backfill_new_server_20260712 b
WHERE br.card_id = b.card_id
  AND br.normalized_name = b.normalized_name
  AND br.logical_rule_key = b.logical_rule_key
  AND br.source = b.source;

COMMIT;
