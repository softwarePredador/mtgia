-- PG780B trusted oracle_hash backfill rollback.
-- Target: new-server PostgreSQL via server/bin/with_new_server_pg.sh.

BEGIN;

UPDATE public.card_battle_rules br
SET oracle_hash = backup.oracle_hash,
    notes = backup.notes,
    updated_at = NOW()
FROM public.card_battle_rules_backup_pg780b_hash_new_server backup
WHERE backup.normalized_name = br.normalized_name
  AND backup.logical_rule_key = br.logical_rule_key;

SELECT COUNT(*) AS restored_rows
FROM public.card_battle_rules_backup_pg780b_hash_new_server;

COMMIT;
