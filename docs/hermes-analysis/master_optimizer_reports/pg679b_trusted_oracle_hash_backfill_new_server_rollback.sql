BEGIN;

UPDATE public.card_battle_rules r
SET
  oracle_hash = b.old_oracle_hash,
  updated_at = now(),
  notes = concat_ws(
    E'\n',
    nullif(r.notes, ''),
    'PG679B rollback: restored prior oracle_hash from deploy audit backup.'
  )
FROM manaloom_deploy_audit.pg679b_trusted_oracle_hash_backfill_backup b
WHERE r.card_id = b.card_id
  AND r.logical_rule_key = b.logical_rule_key
  AND coalesce(r.oracle_hash, '') = coalesce(b.new_oracle_hash, '');

SELECT count(*) AS rollback_candidate_rows
FROM manaloom_deploy_audit.pg679b_trusted_oracle_hash_backfill_backup;

COMMIT;
