-- PG631 rollback: clear oracle_hash only from rows annotated by PG631.
-- Run only if PG631 postcheck or downstream audits fail.
-- Run via: ./server/bin/with_new_server_pg.sh psql -X -v ON_ERROR_STOP=1 -f <this file>

BEGIN;

UPDATE card_battle_rules
SET oracle_hash = NULL,
    updated_at = CURRENT_TIMESTAMP,
    notes = concat_ws(
      E'\n',
      NULLIF(notes, ''),
      'PG631 rollback 2026-07-07: cleared metadata-only oracle_hash backfill.'
    )
WHERE notes LIKE '%PG631 2026-07-07: metadata-only oracle_hash backfill%';

COMMIT;
