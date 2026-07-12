\echo 'PG819 trusted rule oracle_hash backfill rollback'

BEGIN;

UPDATE public.card_battle_rules br
SET
  oracle_hash = b.oracle_hash,
  updated_at = NOW(),
  notes = CONCAT_WS(
    E'\n',
    NULLIF(br.notes, ''),
    'PG819 rollback: restored oracle_hash from manaloom_deploy_audit backup.'
  )
FROM manaloom_deploy_audit.pg819_trusted_rule_oracle_hash_backfill_new_server_20260712 b
WHERE br.card_id = b.card_id
  AND br.normalized_name IS NOT DISTINCT FROM b.normalized_name
  AND br.logical_rule_key IS NOT DISTINCT FROM b.logical_rule_key
  AND br.source IS NOT DISTINCT FROM b.source;

COMMIT;
