BEGIN;

CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit;

CREATE TABLE IF NOT EXISTS manaloom_deploy_audit.pg757b_trusted_rule_oracle_hash_backfill_20260711 AS
SELECT *
FROM public.card_battle_rules r
WHERE r.review_status IN ('verified', 'active')
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
      'PG757B contract backfill: oracle_hash restored from cards.oracle_text for trusted executable rule.'
    )
  FROM public.cards c
  WHERE c.id = r.card_id
    AND r.review_status IN ('verified', 'active')
    AND r.execution_status = 'auto'
    AND coalesce(r.oracle_hash, '') = ''
    AND coalesce(c.oracle_text, '') <> ''
  RETURNING r.normalized_name, r.card_name, r.logical_rule_key, r.oracle_hash
)
SELECT count(*) AS backfilled_rows
FROM updated;

COMMIT;
