\echo 'PG627b oracle_hash integrity backfill apply'

BEGIN;

CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit;

DROP TABLE IF EXISTS manaloom_deploy_audit.pg627b_oracle_hash_integrity_backfill_new_server_20260707;

CREATE TABLE manaloom_deploy_audit.pg627b_oracle_hash_integrity_backfill_new_server_20260707 AS
SELECT
    cbr.*,
    c.name AS resolved_card_name,
    md5(COALESCE(c.oracle_text, '')) AS expected_oracle_hash,
    now() AS backed_up_at
FROM public.card_battle_rules cbr
JOIN public.cards c ON c.id = cbr.card_id
WHERE cbr.source IN ('curated', 'manual')
  AND cbr.review_status IN ('verified', 'active')
  AND cbr.execution_status IN ('auto', 'executable')
  AND COALESCE(cbr.oracle_hash, '') = ''
  AND c.oracle_text IS NOT NULL
  AND c.oracle_text <> '';

WITH updated AS (
    UPDATE public.card_battle_rules cbr
    SET
        oracle_hash = md5(COALESCE(c.oracle_text, '')),
        updated_at = now(),
        notes = concat_ws(
            E'\n',
            NULLIF(cbr.notes, ''),
            'PG627b metadata-only integrity backfill: restored oracle_hash from cards.oracle_text after post-PG627 contract audit.'
        )
    FROM public.cards c
    WHERE c.id = cbr.card_id
      AND cbr.source IN ('curated', 'manual')
      AND cbr.review_status IN ('verified', 'active')
      AND cbr.execution_status IN ('auto', 'executable')
      AND COALESCE(cbr.oracle_hash, '') = ''
      AND c.oracle_text IS NOT NULL
      AND c.oracle_text <> ''
    RETURNING cbr.card_id, cbr.logical_rule_key
)
SELECT COUNT(*) AS updated_rows FROM updated;

SELECT COUNT(*) AS backup_rows
FROM manaloom_deploy_audit.pg627b_oracle_hash_integrity_backfill_new_server_20260707;

COMMIT;
