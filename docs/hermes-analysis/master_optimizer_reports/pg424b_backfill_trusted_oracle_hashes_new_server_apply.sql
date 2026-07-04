BEGIN;

CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit;

CREATE TABLE IF NOT EXISTS manaloom_deploy_audit.pg424b_backfill_trusted_oracle_hashes_new_server_20260704_1923 AS
SELECT *
FROM public.card_battle_rules r
WHERE r.source = 'curated'
  AND r.review_status IN ('verified', 'active')
  AND r.execution_status = 'auto'
  AND coalesce(r.oracle_hash, '') = '';

WITH updated AS (
  UPDATE public.card_battle_rules r
  SET
    oracle_hash = md5(coalesce(c.oracle_text, '')),
    updated_at = now(),
    notes = concat_ws(
      E'\n',
      nullif(r.notes, ''),
      'PG424b: backfilled oracle_hash from cards.oracle_text for trusted executable rule.'
    )
  FROM public.cards c
  WHERE c.id = r.card_id
    AND coalesce(c.oracle_text, '') <> ''
    AND r.source = 'curated'
    AND r.review_status IN ('verified', 'active')
    AND r.execution_status = 'auto'
    AND coalesce(r.oracle_hash, '') = ''
  RETURNING r.normalized_name, r.logical_rule_key, r.oracle_hash
)
SELECT count(*) AS updated_rows
FROM updated;

COMMIT;
