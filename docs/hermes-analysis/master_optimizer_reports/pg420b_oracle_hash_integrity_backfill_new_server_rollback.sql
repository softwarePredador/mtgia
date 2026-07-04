BEGIN;

WITH restored AS (
  UPDATE public.card_battle_rules r
  SET
    oracle_hash = b.oracle_hash,
    updated_at = now(),
    notes = concat_ws(
      E'\n',
      nullif(r.notes, ''),
      'PG420b rollback: restored oracle_hash from deploy-audit backup.'
    )
  FROM manaloom_deploy_audit.pg420b_oracle_hash_integrity_backfill_new_server_20260704 b
  WHERE b.normalized_name = r.normalized_name
    AND b.logical_rule_key = r.logical_rule_key
  RETURNING r.normalized_name, r.card_name, r.logical_rule_key
)
SELECT count(*) AS restored_rows
FROM restored;

COMMIT;
