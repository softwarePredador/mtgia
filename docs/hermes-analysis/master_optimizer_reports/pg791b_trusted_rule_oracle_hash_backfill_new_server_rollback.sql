-- PG791B trusted rule oracle_hash backfill rollback.
-- Target: new-server PostgreSQL via server/bin/with_new_server_pg.sh.

BEGIN;

UPDATE public.card_battle_rules br
SET oracle_hash = backup.oracle_hash,
    notes = backup.notes,
    updated_at = NOW()
FROM manaloom_deploy_audit.pg791b_trusted_rule_oracle_hash_backfill_new_server_20260711 backup
WHERE backup.normalized_name = br.normalized_name
  AND backup.logical_rule_key = br.logical_rule_key;

SELECT COUNT(*) AS restored_rows
FROM manaloom_deploy_audit.pg791b_trusted_rule_oracle_hash_backfill_new_server_20260711;

COMMIT;
