BEGIN;

CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit;

DROP TABLE IF EXISTS manaloom_deploy_audit.pg589b_trusted_oracle_hash_backfill_backup;

CREATE TABLE manaloom_deploy_audit.pg589b_trusted_oracle_hash_backfill_backup AS
SELECT
  r.card_id,
  r.logical_rule_key,
  r.card_name,
  r.normalized_name,
  r.oracle_hash AS old_oracle_hash,
  md5(coalesce(c.oracle_text, '')) AS new_oracle_hash,
  now() AS backed_up_at
FROM card_battle_rules r
JOIN cards c ON c.id = r.card_id
WHERE r.source IN ('curated', 'manual')
  AND r.review_status IN ('verified', 'active')
  AND r.execution_status IN ('auto', 'executable')
  AND coalesce(r.oracle_hash, '') = '';

SELECT count(*) AS backed_up_rows
FROM manaloom_deploy_audit.pg589b_trusted_oracle_hash_backfill_backup;

UPDATE card_battle_rules r
SET
  oracle_hash = b.new_oracle_hash,
  notes = concat_ws(
    E'\n',
    nullif(r.notes, ''),
    'PG589B: backfilled oracle_hash from cards.oracle_text md5 for trusted executable rule contract.'
  ),
  updated_at = now()
FROM manaloom_deploy_audit.pg589b_trusted_oracle_hash_backfill_backup b
WHERE r.card_id = b.card_id
  AND r.logical_rule_key = b.logical_rule_key
  AND coalesce(r.oracle_hash, '') = coalesce(b.old_oracle_hash, '');

SELECT count(*) AS updated_rows
FROM card_battle_rules r
JOIN manaloom_deploy_audit.pg589b_trusted_oracle_hash_backfill_backup b
  ON b.card_id = r.card_id
 AND b.logical_rule_key = r.logical_rule_key
WHERE r.oracle_hash = b.new_oracle_hash;

COMMIT;
