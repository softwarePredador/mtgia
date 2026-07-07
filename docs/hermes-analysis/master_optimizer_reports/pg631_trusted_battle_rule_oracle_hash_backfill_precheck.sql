-- PG631 precheck: backfill oracle_hash for trusted executable battle rules.
-- Expected before apply after PG630: target_missing_hash_rows = 40.
-- This package is metadata-only; it does not change effect_json, status, or rule keys.
-- Run via: ./server/bin/with_new_server_pg.sh psql -X -v ON_ERROR_STOP=1 -f <this file>

WITH target_rows AS (
  SELECT cbr.normalized_name, cbr.logical_rule_key, cbr.card_name, md5(coalesce(c.oracle_text, '')) AS computed_oracle_hash
  FROM card_battle_rules cbr
  JOIN cards c ON c.id = cbr.card_id
  WHERE cbr.source IN ('curated', 'manual')
    AND cbr.review_status IN ('verified', 'active')
    AND cbr.execution_status IN ('auto', 'executable')
    AND COALESCE(cbr.oracle_hash, '') = ''
    AND COALESCE(c.oracle_text, '') <> ''
)
SELECT 'target_missing_hash_rows' AS check_name, COUNT(*)::text AS value FROM target_rows
UNION ALL
SELECT 'distinct_computed_hashes', COUNT(DISTINCT computed_oracle_hash)::text FROM target_rows
UNION ALL
SELECT 'missing_card_id_rows', COUNT(*)::text
FROM card_battle_rules cbr
WHERE cbr.source IN ('curated', 'manual')
  AND cbr.review_status IN ('verified', 'active')
  AND cbr.execution_status IN ('auto', 'executable')
  AND COALESCE(cbr.oracle_hash, '') = ''
  AND cbr.card_id IS NULL;
