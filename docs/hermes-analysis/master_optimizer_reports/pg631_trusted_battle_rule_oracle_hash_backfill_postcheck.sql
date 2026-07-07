-- PG631 postcheck: expected after apply:
-- trusted_executable_missing_oracle_hash = 0
-- pg631_backfilled_rows = 40
-- missing_card_id_rows = 0
-- Run via: ./server/bin/with_new_server_pg.sh psql -X -v ON_ERROR_STOP=1 -f <this file>

SELECT
  'trusted_executable_missing_oracle_hash' AS check_name,
  COUNT(*)::text AS value
FROM card_battle_rules
WHERE source IN ('curated', 'manual')
  AND review_status IN ('verified', 'active')
  AND execution_status IN ('auto', 'executable')
  AND COALESCE(oracle_hash, '') = ''
UNION ALL
SELECT
  'pg631_backfilled_rows',
  COUNT(*)::text
FROM card_battle_rules
WHERE notes LIKE '%PG631 2026-07-07: metadata-only oracle_hash backfill%'
  AND COALESCE(oracle_hash, '') <> ''
UNION ALL
SELECT
  'missing_card_id_rows',
  COUNT(*)::text
FROM card_battle_rules
WHERE source IN ('curated', 'manual')
  AND review_status IN ('verified', 'active')
  AND execution_status IN ('auto', 'executable')
  AND COALESCE(oracle_hash, '') = ''
  AND card_id IS NULL;
