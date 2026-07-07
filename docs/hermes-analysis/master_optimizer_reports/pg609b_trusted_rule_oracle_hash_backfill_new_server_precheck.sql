WITH target AS (
  SELECT
    r.normalized_name,
    r.logical_rule_key,
    r.card_name,
    r.card_id,
    r.source,
    r.review_status,
    r.execution_status,
    r.rule_version
  FROM public.card_battle_rules r
  WHERE r.review_status IN ('verified', 'active')
    AND r.execution_status = 'auto'
    AND COALESCE(r.oracle_hash, '') = ''
),
candidates AS (
  SELECT
    t.normalized_name,
    t.logical_rule_key,
    md5(COALESCE(c.oracle_text, '')) AS computed_oracle_hash
  FROM target t
  JOIN public.cards c
    ON (
         (t.card_id IS NOT NULL AND c.id = t.card_id)
         OR (
              t.card_id IS NULL
              AND (
                   lower(c.name) = t.normalized_name
                   OR split_part(lower(c.name), ' // ', 1) = t.normalized_name
              )
            )
       )
  WHERE COALESCE(c.oracle_text, '') <> ''
),
grouped AS (
  SELECT
    normalized_name,
    logical_rule_key,
    count(DISTINCT computed_oracle_hash) AS distinct_hashes,
    min(computed_oracle_hash) AS computed_oracle_hash
  FROM candidates
  GROUP BY normalized_name, logical_rule_key
)
SELECT
  count(*) AS target_missing_oracle_hash_rows,
  count(g.*) FILTER (WHERE g.distinct_hashes = 1) AS safe_backfill_rows,
  count(g.*) FILTER (WHERE g.distinct_hashes <> 1) AS conflicting_backfill_rows,
  count(*) FILTER (WHERE g.logical_rule_key IS NULL) AS missing_oracle_text_or_card_rows
FROM target t
LEFT JOIN grouped g
  USING (normalized_name, logical_rule_key);

WITH target AS (
  SELECT
    r.normalized_name,
    r.logical_rule_key,
    r.card_name,
    r.card_id,
    r.source,
    r.review_status,
    r.execution_status,
    r.rule_version
  FROM public.card_battle_rules r
  WHERE r.review_status IN ('verified', 'active')
    AND r.execution_status = 'auto'
    AND COALESCE(r.oracle_hash, '') = ''
),
candidates AS (
  SELECT
    t.normalized_name,
    t.logical_rule_key,
    md5(COALESCE(c.oracle_text, '')) AS computed_oracle_hash
  FROM target t
  JOIN public.cards c
    ON (
         (t.card_id IS NOT NULL AND c.id = t.card_id)
         OR (
              t.card_id IS NULL
              AND (
                   lower(c.name) = t.normalized_name
                   OR split_part(lower(c.name), ' // ', 1) = t.normalized_name
              )
            )
       )
  WHERE COALESCE(c.oracle_text, '') <> ''
),
grouped AS (
  SELECT
    normalized_name,
    logical_rule_key,
    count(DISTINCT computed_oracle_hash) AS distinct_hashes,
    min(computed_oracle_hash) AS computed_oracle_hash
  FROM candidates
  GROUP BY normalized_name, logical_rule_key
)
SELECT
  t.card_name,
  t.normalized_name,
  t.logical_rule_key,
  t.source,
  t.review_status,
  t.execution_status,
  t.rule_version,
  g.computed_oracle_hash
FROM target t
JOIN grouped g
  USING (normalized_name, logical_rule_key)
WHERE g.distinct_hashes = 1
ORDER BY t.normalized_name, t.logical_rule_key;
