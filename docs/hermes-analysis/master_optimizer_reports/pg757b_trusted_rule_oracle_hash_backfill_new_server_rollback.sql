BEGIN;

UPDATE public.card_battle_rules r
SET
  oracle_hash = b.oracle_hash,
  notes = b.notes,
  updated_at = b.updated_at
FROM manaloom_deploy_audit.pg757b_trusted_rule_oracle_hash_backfill_20260711 b
WHERE b.card_id = r.card_id
  AND b.logical_rule_key = r.logical_rule_key;

COMMIT;
