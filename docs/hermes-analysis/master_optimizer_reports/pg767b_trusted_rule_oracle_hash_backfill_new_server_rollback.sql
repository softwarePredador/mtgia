BEGIN;

UPDATE public.card_battle_rules r
SET
  oracle_hash = b.oracle_hash,
  notes = concat_ws(
    E'\n',
    nullif(r.notes, ''),
    'PG767B rollback: oracle_hash restored from pg767b_trusted_rule_oracle_hash_backfill_20260711 backup.'
  ),
  updated_at = now()
FROM manaloom_deploy_audit.pg767b_trusted_rule_oracle_hash_backfill_20260711 b
WHERE b.normalized_name = r.normalized_name
  AND b.logical_rule_key = r.logical_rule_key;

COMMIT;
