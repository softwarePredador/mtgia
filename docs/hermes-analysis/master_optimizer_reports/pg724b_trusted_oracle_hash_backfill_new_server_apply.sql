BEGIN;

CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit;

CREATE TABLE IF NOT EXISTS manaloom_deploy_audit.pg724b_trusted_oracle_hash_backfill_new_server_20260710 AS
SELECT br.*
FROM public.card_battle_rules br
JOIN public.cards c ON c.id = br.card_id
WHERE br.review_status IN ('verified', 'active')
  AND br.execution_status = 'auto'
  AND coalesce(btrim(br.oracle_hash), '') = ''
  AND btrim(coalesce(c.oracle_text, '')) <> '';

WITH updated AS (
  UPDATE public.card_battle_rules br
  SET
    oracle_hash = md5(coalesce(c.oracle_text, '')),
    updated_at = now(),
    notes = concat_ws(
      E'\n',
      nullif(br.notes, ''),
      'PG724B trusted oracle_hash backfill from cards.oracle_text on new server.'
    )
  FROM public.cards c
  WHERE c.id = br.card_id
    AND br.review_status IN ('verified', 'active')
    AND br.execution_status = 'auto'
    AND coalesce(btrim(br.oracle_hash), '') = ''
    AND btrim(coalesce(c.oracle_text, '')) <> ''
  RETURNING br.normalized_name, br.logical_rule_key, br.oracle_hash
)
SELECT count(*) AS backfilled_rows FROM updated;

COMMIT;
