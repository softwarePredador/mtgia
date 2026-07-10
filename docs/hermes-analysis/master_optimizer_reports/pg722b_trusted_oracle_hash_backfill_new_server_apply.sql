BEGIN;

CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit;

DROP TABLE IF EXISTS manaloom_deploy_audit.pg722b_trusted_oracle_hash_backfill_20260710;

CREATE TABLE manaloom_deploy_audit.pg722b_trusted_oracle_hash_backfill_20260710 AS
SELECT cbr.*
FROM public.card_battle_rules cbr
JOIN public.cards c ON c.id = cbr.card_id
WHERE cbr.review_status IN ('verified', 'active')
  AND cbr.execution_status IN ('auto', 'executable')
  AND COALESCE(btrim(cbr.oracle_hash), '') = ''
  AND btrim(COALESCE(c.oracle_text, '')) <> '';

WITH updated AS (
  UPDATE public.card_battle_rules cbr
  SET
    oracle_hash = md5(c.oracle_text),
    updated_at = CURRENT_TIMESTAMP
  FROM public.cards c
  WHERE c.id = cbr.card_id
    AND cbr.review_status IN ('verified', 'active')
    AND cbr.execution_status IN ('auto', 'executable')
    AND COALESCE(btrim(cbr.oracle_hash), '') = ''
    AND btrim(COALESCE(c.oracle_text, '')) <> ''
  RETURNING cbr.normalized_name, cbr.logical_rule_key, cbr.card_name, cbr.oracle_hash
)
SELECT count(*) AS backfilled_rows
FROM updated;

COMMIT;
