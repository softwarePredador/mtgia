-- PG634 apply: backfill missing oracle_hash for trusted executable curated/manual rules.
-- Run via:
--   ./server/bin/with_new_server_pg.sh psql -X -v ON_ERROR_STOP=1 -f docs/hermes-analysis/master_optimizer_reports/pg634_trusted_rule_oracle_hash_backfill_apply.sql

BEGIN;

CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit;

CREATE TABLE IF NOT EXISTS manaloom_deploy_audit.pg634_trusted_rule_oracle_hash_backfill_20260707 AS
SELECT cbr.*
FROM public.card_battle_rules cbr
JOIN public.cards c ON c.id = cbr.card_id
WHERE cbr.source IN ('curated', 'manual')
  AND cbr.review_status IN ('verified', 'active')
  AND cbr.execution_status IN ('auto', 'executable')
  AND COALESCE(cbr.oracle_hash, '') = ''
  AND COALESCE(c.oracle_text, '') <> '';

WITH target_rows AS (
  SELECT
    cbr.normalized_name,
    cbr.logical_rule_key,
    md5(coalesce(c.oracle_text, '')) AS expected_oracle_hash
  FROM public.card_battle_rules cbr
  JOIN public.cards c ON c.id = cbr.card_id
  WHERE cbr.source IN ('curated', 'manual')
    AND cbr.review_status IN ('verified', 'active')
    AND cbr.execution_status IN ('auto', 'executable')
    AND COALESCE(cbr.oracle_hash, '') = ''
    AND COALESCE(c.oracle_text, '') <> ''
)
UPDATE public.card_battle_rules cbr
SET oracle_hash = target_rows.expected_oracle_hash,
    reviewed_by = 'codex-pg634-trusted-rule-oracle-hash-backfill',
    updated_at = CURRENT_TIMESTAMP,
    notes = concat_ws(
      E'\n',
      NULLIF(cbr.notes, ''),
      'PG634 2026-07-07: backfilled oracle_hash from current cards.oracle_text for trusted executable curated/manual rule; no behavior fields changed.'
    )
FROM target_rows
WHERE cbr.normalized_name = target_rows.normalized_name
  AND cbr.logical_rule_key = target_rows.logical_rule_key;

COMMIT;
