WITH target_rows AS (
  SELECT
    r.card_name,
    r.normalized_name,
    r.logical_rule_key,
    r.source,
    r.review_status,
    r.execution_status,
    r.rule_version,
    r.oracle_hash AS old_oracle_hash,
    md5(coalesce(c.oracle_text, '')) AS new_oracle_hash
  FROM card_battle_rules r
  JOIN cards c ON c.id = r.card_id
  WHERE r.source IN ('curated', 'manual')
    AND r.review_status IN ('verified', 'active')
    AND r.execution_status IN ('auto', 'executable')
    AND coalesce(r.oracle_hash, '') = ''
)
SELECT
  count(*) AS trusted_executable_rules_missing_oracle_hash,
  count(*) FILTER (WHERE coalesce(new_oracle_hash, '') <> '') AS backfillable_rows,
  count(DISTINCT normalized_name) AS distinct_cards
FROM target_rows;

WITH target_rows AS (
  SELECT
    r.card_name,
    r.normalized_name,
    r.logical_rule_key,
    r.source,
    r.review_status,
    r.execution_status,
    r.rule_version,
    r.oracle_hash AS old_oracle_hash,
    md5(coalesce(c.oracle_text, '')) AS new_oracle_hash
  FROM card_battle_rules r
  JOIN cards c ON c.id = r.card_id
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
  rule_version,
  new_oracle_hash
FROM target_rows
ORDER BY normalized_name, logical_rule_key
LIMIT 80;
