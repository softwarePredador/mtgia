BEGIN;

UPDATE public.card_battle_rules r
SET
  oracle_hash = b.oracle_hash,
  notes = b.notes,
  updated_at = b.updated_at,
  last_seen_at = b.last_seen_at
FROM manaloom_deploy_audit.pg655b_trusted_oracle_hash_backfill_20260708 b
WHERE b.card_id = r.card_id
  AND b.logical_rule_key = r.logical_rule_key;

SELECT count(*) AS restored_rows
FROM manaloom_deploy_audit.pg655b_trusted_oracle_hash_backfill_20260708;

COMMIT;
