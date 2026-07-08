BEGIN;

UPDATE public.card_battle_rules r
SET
  oracle_hash = b.oracle_hash,
  notes = b.notes,
  updated_at = now(),
  last_seen_at = b.last_seen_at
FROM manaloom_deploy_audit.pg667_trusted_rule_oracle_hash_backfill_20260708 b
WHERE r.card_id = b.card_id
  AND r.logical_rule_key = b.logical_rule_key;

COMMIT;
