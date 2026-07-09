BEGIN;

CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit;

DROP TABLE IF EXISTS manaloom_deploy_audit.pg679b_trusted_oracle_hash_backfill_backup;

CREATE TABLE manaloom_deploy_audit.pg679b_trusted_oracle_hash_backfill_backup AS
SELECT
  r.card_id,
  r.card_name,
  r.normalized_name,
  r.logical_rule_key,
  r.oracle_hash AS old_oracle_hash,
  md5(coalesce(c.oracle_text, '')) AS new_oracle_hash,
  now() AS backed_up_at
FROM public.card_battle_rules r
JOIN public.cards c ON c.id = r.card_id
WHERE r.source = 'curated'
  AND r.review_status IN ('active', 'verified')
  AND r.execution_status = 'auto'
  AND coalesce(r.oracle_hash, '') = '';

SELECT count(*) AS backup_rows
FROM manaloom_deploy_audit.pg679b_trusted_oracle_hash_backfill_backup;

WITH updated AS (
  UPDATE public.card_battle_rules r
  SET
    oracle_hash = b.new_oracle_hash,
    notes = concat_ws(
      E'\n',
      nullif(r.notes, ''),
      'PG679B: backfilled oracle_hash from cards.oracle_text md5 for trusted executable rule contract.'
    ),
    updated_at = now()
  FROM manaloom_deploy_audit.pg679b_trusted_oracle_hash_backfill_backup b
  WHERE r.card_id = b.card_id
    AND r.logical_rule_key = b.logical_rule_key
    AND coalesce(r.oracle_hash, '') = coalesce(b.old_oracle_hash, '')
    AND coalesce(r.oracle_hash, '') = ''
  RETURNING r.card_name, r.normalized_name, r.logical_rule_key, r.oracle_hash
)
SELECT count(*) AS updated_rows
FROM updated;

COMMIT;
