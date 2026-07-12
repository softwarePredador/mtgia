\echo 'PG851B trusted rule oracle_hash backfill rollback'

BEGIN;

UPDATE public.card_battle_rules br
SET
  oracle_hash = b.oracle_hash,
  notes = b.notes,
  updated_at = b.updated_at
FROM manaloom_deploy_audit.pg851b_trusted_rule_oracle_hash_backfill_new_server_20260712 b
WHERE br.card_id = b.card_id
  AND br.normalized_name = b.normalized_name
  AND br.logical_rule_key = b.logical_rule_key
  AND br.source = b.source;

COMMIT;
