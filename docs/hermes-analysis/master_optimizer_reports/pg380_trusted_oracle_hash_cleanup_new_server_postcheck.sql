SELECT
  cbr.card_name,
  cbr.normalized_name,
  cbr.logical_rule_key,
  cbr.source,
  cbr.review_status,
  cbr.execution_status,
  cbr.oracle_hash,
  md5(coalesce(c.oracle_text, '')) AS expected_oracle_hash,
  CASE
    WHEN cbr.oracle_hash = md5(coalesce(c.oracle_text, '')) THEN 'pass'
    ELSE 'fail'
  END AS oracle_hash_status
FROM card_battle_rules cbr
JOIN cards c
  ON lower(c.name) = cbr.normalized_name
WHERE (
    cbr.normalized_name = 'angel''s grace'
    AND cbr.logical_rule_key = 'battle_rule_v1:2833836fd4d943d3e02d1cfa2d284227'
  )
  OR (
    cbr.normalized_name = 'seething song'
    AND cbr.logical_rule_key = 'battle_rule_v1:3eb15dc581c6b913158f9b63c023f3d7'
  )
ORDER BY cbr.normalized_name, cbr.logical_rule_key;
