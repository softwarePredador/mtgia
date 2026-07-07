BEGIN;

CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit;

CREATE TABLE IF NOT EXISTS manaloom_deploy_audit.pg637_trusted_oracle_hash_backfill_new_server_20260707_202000 AS
SELECT r.*
FROM public.card_battle_rules r
JOIN public.cards c
  ON c.id = r.card_id
WHERE r.review_status IN ('verified', 'active')
  AND r.execution_status IN ('auto', 'executable')
  AND nullif(r.oracle_hash, '') IS NULL
  AND nullif(c.oracle_text, '') IS NOT NULL;

WITH updated AS (
  UPDATE public.card_battle_rules r
  SET
    oracle_hash = md5(coalesce(c.oracle_text, '')),
    updated_at = now(),
    notes = concat_ws(
      E'\n',
      nullif(r.notes, ''),
      'PG637 trusted oracle hash backfill: filled md5(cards.oracle_text) for existing verified/active executable rule; effect_json unchanged.'
    )
  FROM public.cards c
  WHERE c.id = r.card_id
    AND r.review_status IN ('verified', 'active')
    AND r.execution_status IN ('auto', 'executable')
    AND nullif(r.oracle_hash, '') IS NULL
    AND nullif(c.oracle_text, '') IS NOT NULL
  RETURNING r.normalized_name, r.logical_rule_key, r.oracle_hash
)
SELECT count(*) AS updated_rows
FROM updated;

COMMIT;
