SELECT
  count(*) AS trusted_executable_rules_missing_oracle_hash
FROM card_battle_rules b
JOIN cards c ON c.id = b.card_id
WHERE b.review_status IN ('verified', 'active')
  AND b.execution_status IN ('auto', 'executable')
  AND coalesce(b.oracle_hash, '') = '';

WITH params AS (
  SELECT 'PG623_TRUSTED_ORACLE_HASH_BACKFILL_20260707: oracle_hash=md5(cards.oracle_text); previous oracle_hash was blank.'::text AS marker
)
SELECT
  count(*) AS pg623_marked_rows,
  count(*) FILTER (WHERE b.oracle_hash = md5(coalesce(c.oracle_text, ''))) AS pg623_rows_matching_current_oracle_text,
  count(*) FILTER (WHERE b.oracle_hash <> md5(coalesce(c.oracle_text, ''))) AS pg623_rows_mismatching_current_oracle_text
FROM card_battle_rules b
JOIN cards c ON c.id = b.card_id
CROSS JOIN params
WHERE coalesce(b.notes, '') LIKE '%' || params.marker || '%';
