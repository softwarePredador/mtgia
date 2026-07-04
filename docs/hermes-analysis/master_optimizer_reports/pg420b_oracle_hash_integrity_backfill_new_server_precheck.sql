WITH candidate AS (
  SELECT
    r.card_name,
    r.normalized_name,
    r.logical_rule_key,
    r.source,
    r.review_status,
    r.execution_status,
    r.rule_version,
    md5(coalesce(c.oracle_text, '')) AS computed_oracle_hash
  FROM public.card_battle_rules r
  JOIN public.cards c
    ON c.id = r.card_id
  WHERE r.source IN ('curated', 'manual')
    AND r.review_status IN ('verified', 'active')
    AND r.execution_status IN ('auto', 'executable')
    AND coalesce(r.oracle_hash, '') = ''
    AND coalesce(c.oracle_text, '') <> ''
)
SELECT
  count(*) AS candidate_rows,
  count(*) FILTER (WHERE computed_oracle_hash <> '') AS computable_hash_rows,
  count(DISTINCT normalized_name || '|' || logical_rule_key) AS distinct_rule_keys
FROM candidate;

WITH candidate AS (
  SELECT
    r.card_name,
    r.normalized_name,
    r.logical_rule_key,
    r.source,
    r.review_status,
    r.execution_status,
    r.rule_version,
    md5(coalesce(c.oracle_text, '')) AS computed_oracle_hash
  FROM public.card_battle_rules r
  JOIN public.cards c
    ON c.id = r.card_id
  WHERE r.source IN ('curated', 'manual')
    AND r.review_status IN ('verified', 'active')
    AND r.execution_status IN ('auto', 'executable')
    AND coalesce(r.oracle_hash, '') = ''
    AND coalesce(c.oracle_text, '') <> ''
)
SELECT *
FROM candidate
ORDER BY normalized_name, logical_rule_key
LIMIT 80;
