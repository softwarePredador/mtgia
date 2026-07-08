\echo 'PG661 trusted rule oracle_hash backfill apply'

BEGIN;

CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit;

DROP TABLE IF EXISTS manaloom_deploy_audit.pg661_trusted_rule_oracle_hash_backfill_new_server_20260708;

CREATE TABLE manaloom_deploy_audit.pg661_trusted_rule_oracle_hash_backfill_new_server_20260708 AS
SELECT
  r.*,
  c.name AS resolved_card_name,
  md5(COALESCE(c.oracle_text, '')) AS expected_oracle_hash,
  now() AS backed_up_at
FROM public.card_battle_rules r
JOIN public.cards c ON c.id = r.card_id
WHERE r.source IN ('curated', 'manual')
  AND r.review_status IN ('verified', 'active')
  AND r.execution_status IN ('auto', 'executable')
  AND COALESCE(r.oracle_hash, '') = ''
  AND COALESCE(c.oracle_text, '') <> '';

WITH updated AS (
  UPDATE public.card_battle_rules r
  SET
    oracle_hash = md5(COALESCE(c.oracle_text, '')),
    updated_at = now(),
    notes = concat_ws(
      E'\n',
      NULLIF(r.notes, ''),
      'PG661 2026-07-08: metadata-only oracle_hash backfill for trusted executable rules after post-PG660 contract audit.'
    )
  FROM public.cards c
  WHERE c.id = r.card_id
    AND r.source IN ('curated', 'manual')
    AND r.review_status IN ('verified', 'active')
    AND r.execution_status IN ('auto', 'executable')
    AND COALESCE(r.oracle_hash, '') = ''
    AND COALESCE(c.oracle_text, '') <> ''
  RETURNING r.card_id, r.normalized_name, r.logical_rule_key
)
SELECT COUNT(*) AS updated_rows
FROM updated;

SELECT COUNT(*) AS backup_rows
FROM manaloom_deploy_audit.pg661_trusted_rule_oracle_hash_backfill_new_server_20260708;

COMMIT;
