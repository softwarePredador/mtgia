WITH target AS (
  SELECT
    r.card_name,
    r.normalized_name,
    r.logical_rule_key,
    r.source,
    r.review_status,
    r.execution_status,
    c.oracle_text,
    md5(coalesce(c.oracle_text, '')) AS computed_oracle_hash
  FROM public.card_battle_rules r
  LEFT JOIN public.cards c
    ON c.id = r.card_id
  WHERE r.source IN ('curated', 'manual')
    AND r.review_status IN ('verified', 'active')
    AND r.execution_status IN ('auto', 'executable')
    AND coalesce(r.oracle_hash, '') = ''
),
safe_target AS (
  SELECT *
  FROM target
  WHERE coalesce(oracle_text, '') <> ''
),
duplicate_key AS (
  SELECT normalized_name, logical_rule_key, count(*) AS row_count
  FROM safe_target
  GROUP BY normalized_name, logical_rule_key
  HAVING count(*) > 1
)
SELECT
  (SELECT count(*) FROM target) AS trusted_executable_rules_missing_oracle_hash_before,
  (SELECT count(*) FROM safe_target) AS safely_resolved_rows,
  (SELECT count(*) FROM target WHERE coalesce(oracle_text, '') = '') AS unresolved_rows,
  (SELECT count(DISTINCT normalized_name) FROM safe_target) AS distinct_affected_cards,
  (SELECT coalesce(sum(row_count), 0) FROM duplicate_key) AS duplicate_pk_rows;

WITH target AS (
  SELECT
    r.card_name,
    r.normalized_name,
    r.logical_rule_key,
    r.source,
    r.review_status,
    r.execution_status,
    c.oracle_text,
    md5(coalesce(c.oracle_text, '')) AS computed_oracle_hash
  FROM public.card_battle_rules r
  LEFT JOIN public.cards c
    ON c.id = r.card_id
  WHERE r.source IN ('curated', 'manual')
    AND r.review_status IN ('verified', 'active')
    AND r.execution_status IN ('auto', 'executable')
    AND coalesce(r.oracle_hash, '') = ''
)
SELECT
  card_name,
  normalized_name,
  logical_rule_key,
  source,
  review_status,
  execution_status,
  computed_oracle_hash
FROM (
  SELECT *
  FROM target
  WHERE coalesce(oracle_text, '') <> ''
) safe_target
ORDER BY normalized_name, logical_rule_key
LIMIT 80;
