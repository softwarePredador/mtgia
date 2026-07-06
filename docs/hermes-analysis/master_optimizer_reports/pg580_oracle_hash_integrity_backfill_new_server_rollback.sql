\echo 'PG580 oracle_hash integrity backfill rollback'

BEGIN;

UPDATE card_battle_rules cbr
SET
    oracle_hash = b.oracle_hash,
    updated_at = now(),
    notes = concat_ws(
        E'\n',
        NULLIF(cbr.notes, ''),
        'PG580 rollback: restored oracle_hash value from deploy audit backup.'
    )
FROM manaloom_deploy_audit.pg580_oracle_hash_integrity_backfill_new_server_20260706 b
WHERE cbr.card_id = b.card_id
  AND cbr.logical_rule_key = b.logical_rule_key
  AND cbr.source = b.source
  AND cbr.review_status = b.review_status
  AND cbr.execution_status = b.execution_status
  AND cbr.rule_version = b.rule_version;

COMMIT;
