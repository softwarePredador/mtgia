\echo 'PG839 trusted verified/auto oracle_hash backfill rollback'

BEGIN;

WITH backup AS (
  SELECT *
  FROM manaloom_deploy_audit.pg839_trusted_rule_oracle_hash_backfill_new_server_20260712
),
restored AS (
  UPDATE public.card_battle_rules br
  SET
    oracle_hash = backup.oracle_hash,
    updated_at = NOW(),
    notes = CONCAT_WS(
      E'\n',
      NULLIF(br.notes, ''),
      'PG839 rollback: restored oracle_hash from deploy audit backup.'
    )
  FROM backup
  WHERE br.card_id = backup.card_id
    AND br.normalized_name = backup.normalized_name
    AND br.logical_rule_key = backup.logical_rule_key
    AND br.source = backup.source
  RETURNING br.card_id, br.normalized_name, br.logical_rule_key, br.source
)
SELECT COUNT(*) AS restored_rows
FROM restored;

COMMIT;
