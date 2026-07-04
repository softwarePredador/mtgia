WITH oracle_counts AS (
  SELECT
    lower(name) AS normalized_name,
    count(*) AS matched_card_rows,
    count(DISTINCT md5(coalesce(oracle_text, ''))) AS matched_distinct_oracle_hashes
  FROM cards
  WHERE lower(name) IN ('angel''s grace', 'seething song')
  GROUP BY lower(name)
),
target AS (
  SELECT
    cbr.card_name,
    cbr.normalized_name,
    cbr.logical_rule_key,
    cbr.source,
    cbr.review_status,
    cbr.execution_status,
    cbr.oracle_hash AS current_oracle_hash,
    md5(coalesce(c.oracle_text, '')) AS expected_oracle_hash,
    oc.matched_card_rows,
    oc.matched_distinct_oracle_hashes
  FROM card_battle_rules cbr
  JOIN cards c
    ON lower(c.name) = cbr.normalized_name
  JOIN oracle_counts oc
    ON oc.normalized_name = cbr.normalized_name
  WHERE cbr.normalized_name IN ('angel''s grace', 'seething song')
    AND cbr.source IN ('curated', 'manual')
    AND cbr.review_status IN ('verified', 'active')
    AND cbr.execution_status IN ('auto', 'executable')
)
SELECT *
FROM target
ORDER BY normalized_name, logical_rule_key;
