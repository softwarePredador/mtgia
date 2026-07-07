BEGIN;

UPDATE public.card_battle_rules r
SET oracle_hash = b.previous_oracle_hash,
    updated_at = b.previous_updated_at
FROM manaloom_deploy_audit.pg582_trusted_rule_oracle_hash_backfill_backup b
WHERE r.normalized_name = b.normalized_name
  AND r.logical_rule_key = b.logical_rule_key;

COMMIT;
