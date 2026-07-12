\echo 'PG843B trusted rule oracle_hash backfill precheck'

WITH target AS (
  SELECT
    br.card_id,
    br.normalized_name,
    br.card_name,
    br.logical_rule_key,
    br.source,
    br.review_status,
    br.execution_status,
    br.rule_version,
    br.oracle_hash AS old_oracle_hash,
    md5(c.oracle_text) AS new_oracle_hash
  FROM card_battle_rules br
  JOIN cards c ON c.id = br.card_id
  WHERE br.source IN ('curated', 'manual')
    AND br.review_status IN ('verified', 'active')
    AND br.execution_status IN ('auto', 'executable')
    AND COALESCE(br.oracle_hash, '') = ''
    AND COALESCE(BTRIM(c.oracle_text), '') <> ''
)
SELECT
  COUNT(*) AS trusted_executable_rules_missing_oracle_hash,
  COUNT(*) FILTER (WHERE new_oracle_hash IS NOT NULL AND new_oracle_hash <> '') AS rows_with_computable_oracle_hash
FROM target;

WITH missing_uncomputable AS (
  SELECT
    br.card_id,
    br.normalized_name,
    br.card_name,
    br.logical_rule_key,
    br.source,
    br.review_status,
    br.execution_status,
    br.rule_version
  FROM card_battle_rules br
  LEFT JOIN cards c ON c.id = br.card_id
  WHERE br.source IN ('curated', 'manual')
    AND br.review_status IN ('verified', 'active')
    AND br.execution_status IN ('auto', 'executable')
    AND COALESCE(br.oracle_hash, '') = ''
    AND COALESCE(BTRIM(c.oracle_text), '') = ''
)
SELECT COUNT(*) AS trusted_executable_missing_hash_without_oracle_text
FROM missing_uncomputable;

WITH target AS (
  SELECT
    br.card_name,
    br.normalized_name,
    br.logical_rule_key,
    br.source,
    br.review_status,
    br.execution_status,
    br.rule_version,
    md5(c.oracle_text) AS new_oracle_hash
  FROM card_battle_rules br
  JOIN cards c ON c.id = br.card_id
  WHERE br.source IN ('curated', 'manual')
    AND br.review_status IN ('verified', 'active')
    AND br.execution_status IN ('auto', 'executable')
    AND COALESCE(br.oracle_hash, '') = ''
    AND COALESCE(BTRIM(c.oracle_text), '') <> ''
)
SELECT *
FROM target
ORDER BY normalized_name, logical_rule_key;
