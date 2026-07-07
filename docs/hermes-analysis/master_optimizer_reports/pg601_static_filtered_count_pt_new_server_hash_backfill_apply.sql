BEGIN;

CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit;

CREATE TABLE manaloom_deploy_audit.pg601_static_filtered_hash_backfill_20260707 AS
SELECT *
FROM public.card_battle_rules
WHERE source = 'curated'
  AND execution_status = 'auto'
  AND review_status IN ('active', 'verified')
  AND coalesce(oracle_hash, '') = '';

WITH updated AS (
  UPDATE public.card_battle_rules r
  SET
    oracle_hash = md5(coalesce(c.oracle_text, '')),
    updated_at = now(),
    notes = concat_ws(E'\n', nullif(r.notes, ''), 'PG601 hash backfill: populated oracle_hash from cards.oracle_text for previously promoted executable curated rule.')
  FROM public.cards c
  WHERE c.id = r.card_id
    AND r.source = 'curated'
    AND r.execution_status = 'auto'
    AND r.review_status IN ('active', 'verified')
    AND coalesce(r.oracle_hash, '') = ''
  RETURNING r.card_name, r.normalized_name, r.logical_rule_key, r.oracle_hash
)
SELECT count(*) AS backfilled_oracle_hash_rows
FROM updated;

COMMIT;
