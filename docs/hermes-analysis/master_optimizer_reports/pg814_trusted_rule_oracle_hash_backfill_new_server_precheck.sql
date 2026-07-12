WITH candidates AS (
  SELECT
    r.card_id,
    c.name AS card_name,
    r.normalized_name,
    r.logical_rule_key,
    r.review_status,
    r.execution_status,
    r.oracle_hash AS current_oracle_hash,
    md5(c.oracle_text) AS expected_oracle_hash
  FROM card_battle_rules r
  JOIN cards c ON c.id = r.card_id
  WHERE r.review_status = 'verified'
    AND r.execution_status = 'auto'
    AND COALESCE(BTRIM(r.oracle_hash), '') = ''
    AND NULLIF(BTRIM(c.oracle_text), '') IS NOT NULL
)
SELECT
  count(*) AS candidate_rows,
  count(DISTINCT card_id) AS candidate_cards,
  count(*) FILTER (WHERE expected_oracle_hash IS NOT NULL) AS hashable_rows
FROM candidates;

WITH candidates AS (
  SELECT
    c.name AS card_name,
    r.normalized_name,
    r.logical_rule_key,
    md5(c.oracle_text) AS expected_oracle_hash
  FROM card_battle_rules r
  JOIN cards c ON c.id = r.card_id
  WHERE r.review_status = 'verified'
    AND r.execution_status = 'auto'
    AND COALESCE(BTRIM(r.oracle_hash), '') = ''
    AND NULLIF(BTRIM(c.oracle_text), '') IS NOT NULL
)
SELECT *
FROM candidates
ORDER BY card_name, logical_rule_key;
