BEGIN;

CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit;

CREATE TABLE IF NOT EXISTS manaloom_deploy_audit.pg760b_trusted_rule_oracle_hash_backfill_20260711 AS
SELECT
  r.*,
  md5(coalesce(c.oracle_text, '')) AS computed_oracle_hash,
  now() AS audit_created_at
FROM public.card_battle_rules r
JOIN public.cards c ON c.id = r.card_id
WHERE r.source IN ('curated', 'manual')
  AND r.review_status IN ('verified', 'active')
  AND r.execution_status IN ('auto', 'executable')
  AND coalesce(r.oracle_hash, '') = ''
  AND coalesce(c.oracle_text, '') <> '';

WITH updated AS (
  UPDATE public.card_battle_rules r
  SET
    oracle_hash = md5(coalesce(c.oracle_text, '')),
    updated_at = now(),
    notes = concat_ws(
      E'\n',
      nullif(r.notes, ''),
      'PG760B contract backfill: oracle_hash restored from cards.oracle_text for trusted executable rule after PG760 readiness audit.'
    )
  FROM public.cards c
  WHERE c.id = r.card_id
    AND r.source IN ('curated', 'manual')
    AND r.review_status IN ('verified', 'active')
    AND r.execution_status IN ('auto', 'executable')
    AND coalesce(r.oracle_hash, '') = ''
    AND coalesce(c.oracle_text, '') <> ''
  RETURNING r.normalized_name, r.card_name, r.logical_rule_key, r.oracle_hash
)
SELECT count(*) AS backfilled_rows
FROM updated;

COMMIT;
