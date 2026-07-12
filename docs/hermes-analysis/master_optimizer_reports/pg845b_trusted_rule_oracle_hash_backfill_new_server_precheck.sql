\echo 'PG845B trusted rule oracle_hash backfill precheck'

SELECT
  count(*) AS trusted_executable_rules_missing_oracle_hash,
  count(*) FILTER (WHERE COALESCE(BTRIM(c.oracle_text), '') <> '') AS rows_with_oracle_text,
  count(*) FILTER (WHERE COALESCE(BTRIM(c.oracle_text), '') = '') AS rows_without_oracle_text
FROM card_battle_rules br
JOIN cards c ON c.id = br.card_id
WHERE br.source IN ('curated', 'manual')
  AND br.review_status IN ('verified', 'active')
  AND br.execution_status IN ('auto', 'executable')
  AND COALESCE(br.oracle_hash, '') = '';

SELECT
  c.name AS card_name,
  br.normalized_name,
  br.logical_rule_key,
  br.source,
  br.rule_version,
  md5(c.oracle_text) AS proposed_oracle_hash
FROM card_battle_rules br
JOIN cards c ON c.id = br.card_id
WHERE br.source IN ('curated', 'manual')
  AND br.review_status IN ('verified', 'active')
  AND br.execution_status IN ('auto', 'executable')
  AND COALESCE(br.oracle_hash, '') = ''
  AND COALESCE(BTRIM(c.oracle_text), '') <> ''
ORDER BY c.name, br.logical_rule_key
LIMIT 60;
