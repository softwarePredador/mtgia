BEGIN;

UPDATE card_battle_rules r
SET
  oracle_hash = b.old_oracle_hash,
  notes = concat_ws(
    E'\n',
    nullif(r.notes, ''),
    'PG589B rollback: restored prior oracle_hash after trusted executable hash backfill.'
  ),
  updated_at = now()
FROM manaloom_deploy_audit.pg589b_trusted_oracle_hash_backfill_backup b
WHERE r.card_id = b.card_id
  AND r.logical_rule_key = b.logical_rule_key;

SELECT count(*) AS rolled_back_rows
FROM card_battle_rules r
JOIN manaloom_deploy_audit.pg589b_trusted_oracle_hash_backfill_backup b
  ON b.card_id = r.card_id
 AND b.logical_rule_key = r.logical_rule_key
WHERE coalesce(r.oracle_hash, '') = coalesce(b.old_oracle_hash, '');

COMMIT;
