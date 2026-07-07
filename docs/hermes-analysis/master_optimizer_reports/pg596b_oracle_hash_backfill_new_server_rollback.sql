BEGIN;

UPDATE public.card_battle_rules r
SET
  oracle_hash = b.previous_oracle_hash,
  updated_at = b.previous_updated_at
FROM public.pg596b_oracle_hash_backfill_backup b
WHERE r.card_id = b.card_id
  AND r.logical_rule_key = b.logical_rule_key;

SELECT COUNT(*) AS restored_rows
FROM public.pg596b_oracle_hash_backfill_backup;

COMMIT;
