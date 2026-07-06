\echo 'PG580 oracle_hash integrity backfill precheck'

WITH target AS (
    SELECT
        cbr.card_id,
        c.name AS card_name,
        cbr.logical_rule_key,
        cbr.source,
        cbr.review_status,
        cbr.execution_status,
        cbr.rule_version,
        c.oracle_text,
        md5(COALESCE(c.oracle_text, '')) AS expected_oracle_hash
    FROM card_battle_rules cbr
    JOIN cards c ON c.id = cbr.card_id
    WHERE cbr.source IN ('curated', 'manual')
      AND cbr.review_status IN ('verified', 'active')
      AND cbr.execution_status IN ('auto', 'executable')
      AND COALESCE(cbr.oracle_hash, '') = ''
)
SELECT
    COUNT(*) AS target_rows,
    COUNT(*) FILTER (WHERE oracle_text IS NOT NULL AND oracle_text <> '') AS safely_resolved_rows,
    COUNT(*) FILTER (WHERE oracle_text IS NULL OR oracle_text = '') AS unresolved_rows,
    COUNT(DISTINCT (card_id, logical_rule_key, source, review_status, execution_status, rule_version)) AS distinct_rule_keys
FROM target;

WITH target AS (
    SELECT
        cbr.card_id,
        c.name AS card_name,
        cbr.logical_rule_key,
        cbr.source,
        cbr.review_status,
        cbr.execution_status,
        cbr.rule_version,
        md5(COALESCE(c.oracle_text, '')) AS expected_oracle_hash
    FROM card_battle_rules cbr
    JOIN cards c ON c.id = cbr.card_id
    WHERE cbr.source IN ('curated', 'manual')
      AND cbr.review_status IN ('verified', 'active')
      AND cbr.execution_status IN ('auto', 'executable')
      AND COALESCE(cbr.oracle_hash, '') = ''
)
SELECT
    card_name,
    logical_rule_key,
    review_status,
    execution_status,
    source,
    rule_version,
    expected_oracle_hash
FROM target
ORDER BY card_name, logical_rule_key;
