\echo 'PG855B trusted rule oracle_hash backfill precheck'

SELECT
  COUNT(*) AS rows_missing_oracle_hash,
  COUNT(DISTINCT br.card_id) AS cards_missing_oracle_hash
FROM card_battle_rules br
JOIN cards c ON c.id = br.card_id
WHERE br.source = 'curated'
  AND br.review_status = 'verified'
  AND br.execution_status = 'auto'
  AND COALESCE(BTRIM(br.oracle_hash), '') = ''
  AND COALESCE(BTRIM(c.oracle_text), '') <> '';

SELECT
  c.name,
  br.normalized_name,
  br.logical_rule_key,
  md5(c.oracle_text) AS new_oracle_hash
FROM card_battle_rules br
JOIN cards c ON c.id = br.card_id
WHERE br.source = 'curated'
  AND br.review_status = 'verified'
  AND br.execution_status = 'auto'
  AND COALESCE(BTRIM(br.oracle_hash), '') = ''
  AND COALESCE(BTRIM(c.oracle_text), '') <> ''
ORDER BY c.name, br.logical_rule_key;
