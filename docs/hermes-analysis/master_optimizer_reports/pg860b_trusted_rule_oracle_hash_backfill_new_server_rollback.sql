\echo 'PG860B trusted rule oracle_hash backfill rollback'

BEGIN;

WITH restored AS (
  UPDATE public.card_battle_rules br
  SET
    oracle_hash = backup.oracle_hash,
    updated_at = NOW(),
    notes = CONCAT_WS(
      E'\n',
      NULLIF(br.notes, ''),
      'PG860B rollback: restored prior oracle_hash value from deploy audit backup.'
    )
  FROM manaloom_deploy_audit.pg860b_trusted_rule_oracle_hash_backfill_new_server_20260713 backup
  WHERE br.card_id = backup.card_id
    AND br.normalized_name = backup.normalized_name
    AND br.logical_rule_key = backup.logical_rule_key
    AND br.source = backup.source
    AND br.oracle_hash = backup.pg860b_new_oracle_hash
  RETURNING br.card_id, br.normalized_name, br.logical_rule_key, br.source
)
SELECT COUNT(*) AS restored_rows
FROM restored;

COMMIT;
