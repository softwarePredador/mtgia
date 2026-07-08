\echo 'PG661 trusted rule oracle_hash backfill precheck'

WITH target_rows AS (
  SELECT
    r.card_id,
    r.card_name,
    r.normalized_name,
    r.logical_rule_key,
    r.source,
    r.review_status,
    r.execution_status,
    md5(COALESCE(c.oracle_text, '')) AS computed_oracle_hash
  FROM public.card_battle_rules r
  JOIN public.cards c ON c.id = r.card_id
  WHERE r.source IN ('curated', 'manual')
    AND r.review_status IN ('verified', 'active')
    AND r.execution_status IN ('auto', 'executable')
    AND COALESCE(r.oracle_hash, '') = ''
    AND COALESCE(c.oracle_text, '') <> ''
),
grouped AS (
  SELECT
    normalized_name,
    logical_rule_key,
    COUNT(*) AS rows,
    COUNT(DISTINCT computed_oracle_hash) AS distinct_hashes,
    MIN(computed_oracle_hash) AS computed_oracle_hash
  FROM target_rows
  GROUP BY normalized_name, logical_rule_key
)
SELECT
  COUNT(*) AS target_missing_oracle_hash_rows,
  COUNT(*) FILTER (WHERE distinct_hashes = 1) AS safe_groups,
  COUNT(*) FILTER (WHERE distinct_hashes <> 1) AS unsafe_groups
FROM grouped;

WITH target_rows AS (
  SELECT
    r.card_id,
    r.card_name,
    r.normalized_name,
    r.logical_rule_key,
    r.source,
    r.review_status,
    r.execution_status,
    md5(COALESCE(c.oracle_text, '')) AS computed_oracle_hash
  FROM public.card_battle_rules r
  JOIN public.cards c ON c.id = r.card_id
  WHERE r.source IN ('curated', 'manual')
    AND r.review_status IN ('verified', 'active')
    AND r.execution_status IN ('auto', 'executable')
    AND COALESCE(r.oracle_hash, '') = ''
    AND COALESCE(c.oracle_text, '') <> ''
)
SELECT
  card_name,
  normalized_name,
  logical_rule_key,
  source,
  review_status,
  execution_status,
  computed_oracle_hash
FROM target_rows
ORDER BY normalized_name, logical_rule_key
LIMIT 60;
