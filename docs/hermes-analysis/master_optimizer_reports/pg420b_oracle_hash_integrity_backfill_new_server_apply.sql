BEGIN;

CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit;

DO $$
BEGIN
  IF to_regclass('manaloom_deploy_audit.pg420b_oracle_hash_integrity_backfill_new_server_20260704') IS NOT NULL THEN
    RAISE EXCEPTION 'Backup table manaloom_deploy_audit.pg420b_oracle_hash_integrity_backfill_new_server_20260704 already exists';
  END IF;
END $$;

CREATE TABLE manaloom_deploy_audit.pg420b_oracle_hash_integrity_backfill_new_server_20260704 AS
SELECT r.*
FROM public.card_battle_rules r
JOIN public.cards c
  ON c.id = r.card_id
WHERE r.source IN ('curated', 'manual')
  AND r.review_status IN ('verified', 'active')
  AND r.execution_status IN ('auto', 'executable')
  AND coalesce(r.oracle_hash, '') = ''
  AND coalesce(c.oracle_text, '') <> '';

WITH candidate AS (
  SELECT
    r.normalized_name,
    r.logical_rule_key,
    md5(coalesce(c.oracle_text, '')) AS computed_oracle_hash
  FROM public.card_battle_rules r
  JOIN public.cards c
    ON c.id = r.card_id
  WHERE r.source IN ('curated', 'manual')
    AND r.review_status IN ('verified', 'active')
    AND r.execution_status IN ('auto', 'executable')
    AND coalesce(r.oracle_hash, '') = ''
    AND coalesce(c.oracle_text, '') <> ''
),
updated AS (
  UPDATE public.card_battle_rules r
  SET
    oracle_hash = c.computed_oracle_hash,
    updated_at = now(),
    notes = concat_ws(
      E'\n',
      nullif(r.notes, ''),
      'PG420b contract cleanup: oracle_hash backfilled from current PostgreSQL cards.oracle_text after PG/Hermes/SQLite integrity audit.'
    )
  FROM candidate c
  WHERE r.normalized_name = c.normalized_name
    AND r.logical_rule_key = c.logical_rule_key
  RETURNING r.normalized_name, r.card_name, r.logical_rule_key, r.oracle_hash
)
SELECT count(*) AS updated_rows
FROM updated;

COMMIT;
