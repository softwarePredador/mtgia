BEGIN;

UPDATE public.card_battle_rules r
   SET oracle_hash = b.oracle_hash,
       updated_at = b.updated_at
  FROM manaloom_deploy_audit.pg713b_oracle_hash_integrity_backfill_20260710 b
 WHERE r.normalized_name = b.normalized_name
   AND r.logical_rule_key = b.logical_rule_key;

SELECT count(*) AS restored_rows
FROM manaloom_deploy_audit.pg713b_oracle_hash_integrity_backfill_20260710;

COMMIT;
