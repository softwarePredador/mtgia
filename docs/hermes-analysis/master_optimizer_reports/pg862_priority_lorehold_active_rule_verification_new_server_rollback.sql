BEGIN;

UPDATE public.card_battle_rules r
SET
  review_status = b.review_status,
  execution_status = b.execution_status,
  oracle_hash = b.oracle_hash,
  reviewed_by = b.reviewed_by,
  reviewed_at = b.reviewed_at,
  updated_at = now(),
  notes = concat_ws(E'\n', nullif(r.notes, ''), 'PG862 rollback: restored status/hash fields from deploy audit backup.')
FROM manaloom_deploy_audit.pg862_priority_lorehold_active_rule_verification_new_server_202 b
WHERE r.normalized_name = b.normalized_name
  AND r.logical_rule_key = b.logical_rule_key;

COMMIT;
