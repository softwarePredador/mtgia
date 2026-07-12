\echo 'PG801B trusted rule oracle_hash backfill rollback'

BEGIN;

WITH backup AS (
  SELECT *
  FROM manaloom_deploy_audit.pg801b_trusted_rule_oracle_hash_backfill_new_server_20260712
),
rolled_back AS (
  UPDATE public.card_battle_rules br
  SET
    oracle_hash = backup.oracle_hash,
    updated_at = NOW(),
    notes = CONCAT_WS(
      E'\n',
      NULLIF(br.notes, ''),
      'PG801B rollback: restored oracle_hash from deploy audit backup.'
    )
  FROM backup
  WHERE br.card_id = backup.card_id
    AND br.normalized_name = backup.normalized_name
    AND br.logical_rule_key = backup.logical_rule_key
    AND br.source = backup.source
  RETURNING br.card_id, br.normalized_name, br.logical_rule_key, br.source
)
SELECT COUNT(*) AS rolled_back_rows
FROM rolled_back;

COMMIT;
