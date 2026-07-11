BEGIN;

UPDATE public.card_battle_rules r
SET
  oracle_hash = b.oracle_hash,
  updated_at = now(),
  notes = concat_ws(E'\n', nullif(r.notes, ''), 'PG747 integrity backfill rollback: restored prior oracle_hash value.')
FROM manaloom_deploy_audit.pg747_hash_backfill_20260711_0730 b
WHERE b.normalized_name = r.normalized_name
  AND b.logical_rule_key = r.logical_rule_key;

COMMIT;
