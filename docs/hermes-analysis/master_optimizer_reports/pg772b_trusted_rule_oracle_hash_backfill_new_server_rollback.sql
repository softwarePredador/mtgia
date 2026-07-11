UPDATE public.card_battle_rules r
SET
  oracle_hash = b.oracle_hash,
  updated_at = now(),
  notes = concat_ws(
    E'\n',
    nullif(r.notes, ''),
    'PG772B rollback: oracle_hash restored from pg772b trusted-rule backup.'
  )
FROM manaloom_deploy_audit.pg772b_trusted_rule_oracle_hash_backfill_new_server_20260711 b
WHERE b.normalized_name = r.normalized_name
  AND b.logical_rule_key = r.logical_rule_key;
