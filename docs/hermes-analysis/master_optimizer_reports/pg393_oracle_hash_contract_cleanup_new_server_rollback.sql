BEGIN;

UPDATE public.card_battle_rules r
   SET oracle_hash = b.oracle_hash,
       notes = b.notes,
       updated_at = now()
FROM public.card_battle_rules_pg393_oracle_hash_backfill_backup b
WHERE r.normalized_name = b.normalized_name
  AND r.logical_rule_key = b.logical_rule_key;

COMMIT;
