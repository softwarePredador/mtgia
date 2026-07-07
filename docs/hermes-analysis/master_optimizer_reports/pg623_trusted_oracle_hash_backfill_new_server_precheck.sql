WITH target AS (
  SELECT
    b.card_name,
    b.normalized_name,
    b.logical_rule_key,
    b.source,
    b.review_status,
    b.execution_status,
    md5(coalesce(c.oracle_text, '')) AS computed_oracle_hash,
    length(coalesce(c.oracle_text, '')) AS oracle_text_len
  FROM card_battle_rules b
  JOIN cards c ON c.id = b.card_id
  WHERE b.review_status IN ('verified', 'active')
    AND b.execution_status IN ('auto', 'executable')
    AND coalesce(b.oracle_hash, '') = ''
)
SELECT
  count(*) AS candidate_rows,
  count(*) FILTER (WHERE oracle_text_len > 0) AS candidates_with_oracle_text,
  count(*) FILTER (WHERE oracle_text_len = 0) AS candidates_missing_oracle_text
FROM target;

WITH target AS (
  SELECT
    b.card_name,
    b.normalized_name,
    b.logical_rule_key,
    b.source,
    b.review_status,
    b.execution_status,
    md5(coalesce(c.oracle_text, '')) AS computed_oracle_hash,
    length(coalesce(c.oracle_text, '')) AS oracle_text_len
  FROM card_battle_rules b
  JOIN cards c ON c.id = b.card_id
  WHERE b.review_status IN ('verified', 'active')
    AND b.execution_status IN ('auto', 'executable')
    AND coalesce(b.oracle_hash, '') = ''
)
SELECT
  card_name,
  normalized_name,
  logical_rule_key,
  source,
  review_status,
  execution_status,
  computed_oracle_hash,
  oracle_text_len
FROM target
ORDER BY card_name, logical_rule_key;
