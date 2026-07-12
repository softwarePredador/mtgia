\echo 'PG808B trusted rule oracle_hash backfill rollback'

BEGIN;

WITH restored AS (
  UPDATE public.card_battle_rules br
  SET
    oracle_hash = b.oracle_hash,
    updated_at = NOW(),
    notes = CONCAT_WS(
      E'\n',
      NULLIF(br.notes, ''),
      'PG808B rollback: oracle_hash restored from trusted-rule backup.'
    )
  FROM manaloom_deploy_audit.pg808b_trusted_rule_oracle_hash_backfill_new_server_20260712 b
  WHERE b.card_id = br.card_id
    AND b.normalized_name = br.normalized_name
    AND b.logical_rule_key = br.logical_rule_key
    AND b.source = br.source
  RETURNING br.card_id, br.normalized_name, br.logical_rule_key, br.source
)
SELECT COUNT(*) AS restored_rows
FROM restored;

COMMIT;
