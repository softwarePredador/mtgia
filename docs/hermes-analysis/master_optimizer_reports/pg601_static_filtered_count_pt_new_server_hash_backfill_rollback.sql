BEGIN;

UPDATE public.card_battle_rules r
SET
  oracle_hash = b.oracle_hash,
  notes = b.notes,
  updated_at = now()
FROM manaloom_deploy_audit.pg601_static_filtered_hash_backfill_20260707 b
WHERE b.normalized_name = r.normalized_name
  AND b.logical_rule_key = r.logical_rule_key;

COMMIT;
