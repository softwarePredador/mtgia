-- PG786B trusted rule oracle_hash backfill apply.
-- Target: new-server PostgreSQL via server/bin/with_new_server_pg.sh.

BEGIN;

CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit;

DROP TABLE IF EXISTS manaloom_deploy_audit.pg786b_trusted_rule_oracle_hash_backfill_new_server_20260711;

CREATE TABLE manaloom_deploy_audit.pg786b_trusted_rule_oracle_hash_backfill_new_server_20260711 AS
SELECT br.*
FROM public.card_battle_rules br
JOIN public.cards c ON c.id = br.card_id
WHERE br.source IN ('curated', 'manual')
  AND br.review_status IN ('verified', 'active')
  AND br.execution_status IN ('auto', 'executable')
  AND COALESCE(br.oracle_hash, '') = ''
  AND COALESCE(c.oracle_text, '') <> '';

WITH updated AS (
  UPDATE public.card_battle_rules br
  SET oracle_hash = md5(c.oracle_text),
      notes = concat_ws(
        E'\n',
        NULLIF(br.notes, ''),
        'PG786B trusted rule oracle_hash backfill from cards.oracle_text on 2026-07-11.'
      ),
      updated_at = NOW()
  FROM public.cards c
  WHERE c.id = br.card_id
    AND br.source IN ('curated', 'manual')
    AND br.review_status IN ('verified', 'active')
    AND br.execution_status IN ('auto', 'executable')
    AND COALESCE(br.oracle_hash, '') = ''
    AND COALESCE(c.oracle_text, '') <> ''
  RETURNING 1
)
SELECT
  (SELECT COUNT(*) FROM manaloom_deploy_audit.pg786b_trusted_rule_oracle_hash_backfill_new_server_20260711) AS backup_rows,
  (SELECT COUNT(*) FROM updated) AS updated_rows;

COMMIT;
