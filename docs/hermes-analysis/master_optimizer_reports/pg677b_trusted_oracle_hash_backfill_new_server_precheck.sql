WITH target_rows AS (
  SELECT
    r.card_id,
    c.name AS card_name,
    r.normalized_name,
    r.logical_rule_key,
    r.review_status,
    r.execution_status,
    r.source,
    r.rule_version,
    r.oracle_hash AS current_oracle_hash,
    md5(coalesce(c.oracle_text, '')) AS computed_oracle_hash
  FROM card_battle_rules r
  JOIN cards c ON c.id = r.card_id
  WHERE coalesce(r.oracle_hash, '') = ''
    AND coalesce(c.oracle_text, '') <> ''
    AND coalesce(r.execution_status, '') = 'auto'
    AND coalesce(r.review_status, '') IN ('verified', 'active')
)
SELECT
  count(*) AS rows_to_backfill,
  count(*) FILTER (WHERE computed_oracle_hash IS NOT NULL AND computed_oracle_hash <> '') AS rows_with_computed_hash,
  count(DISTINCT card_id) AS distinct_cards
FROM target_rows;

WITH target_rows AS (
  SELECT
    r.card_id,
    c.name AS card_name,
    r.normalized_name,
    r.logical_rule_key,
    r.review_status,
    r.execution_status,
    r.source,
    r.rule_version,
    r.oracle_hash AS current_oracle_hash,
    md5(coalesce(c.oracle_text, '')) AS computed_oracle_hash
  FROM card_battle_rules r
  JOIN cards c ON c.id = r.card_id
  WHERE coalesce(r.oracle_hash, '') = ''
    AND coalesce(c.oracle_text, '') <> ''
    AND coalesce(r.execution_status, '') = 'auto'
    AND coalesce(r.review_status, '') IN ('verified', 'active')
)
SELECT
  card_name,
  normalized_name,
  logical_rule_key,
  review_status,
  execution_status,
  source,
  rule_version,
  computed_oracle_hash
FROM target_rows
ORDER BY card_name, normalized_name
LIMIT 80;
