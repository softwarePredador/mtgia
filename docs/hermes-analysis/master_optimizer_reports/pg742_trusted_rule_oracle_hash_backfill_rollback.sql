BEGIN;

UPDATE public.card_battle_rules r
SET
  oracle_hash = b.oracle_hash,
  updated_at = now(),
  notes = concat_ws(
    E'\n',
    nullif(r.notes, ''),
    'PG742 rollback: oracle_hash restored from pg742_trusted_rule_oracle_hash_backfill_20260711 backup.'
  )
FROM manaloom_deploy_audit.pg742_trusted_rule_oracle_hash_backfill_20260711 b
WHERE r.normalized_name = b.normalized_name
  AND r.logical_rule_key = b.logical_rule_key;

COMMIT;
