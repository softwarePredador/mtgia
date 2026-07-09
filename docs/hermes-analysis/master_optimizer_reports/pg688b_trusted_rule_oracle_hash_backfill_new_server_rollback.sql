BEGIN;

UPDATE public.card_battle_rules r
SET
  oracle_hash = b.oracle_hash,
  notes = b.notes,
  updated_at = now(),
  last_seen_at = b.last_seen_at
FROM manaloom_deploy_audit.pg688b_trusted_rule_oracle_hash_backfill_new_server_20260709 b
WHERE b.card_id = r.card_id
  AND b.logical_rule_key = r.logical_rule_key
  AND r.notes LIKE '%PG688b 2026-07-09: metadata-only oracle_hash backfill%';

COMMIT;
