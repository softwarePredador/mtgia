BEGIN;

UPDATE public.card_battle_rules cbr
SET
  oracle_hash = b.oracle_hash,
  updated_at = CURRENT_TIMESTAMP
FROM manaloom_deploy_audit.pg722b_trusted_oracle_hash_backfill_20260710 b
WHERE b.normalized_name = cbr.normalized_name
  AND b.logical_rule_key = cbr.logical_rule_key;

COMMIT;
