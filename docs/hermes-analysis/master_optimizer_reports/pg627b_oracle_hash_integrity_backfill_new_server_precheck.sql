\echo 'PG627b oracle_hash integrity backfill precheck'

WITH candidates AS (
    SELECT
        cbr.card_id,
        cbr.normalized_name,
        cbr.card_name,
        cbr.logical_rule_key,
        cbr.source,
        cbr.review_status,
        cbr.execution_status,
        md5(COALESCE(c.oracle_text, '')) AS computed_oracle_hash
    FROM public.card_battle_rules cbr
    JOIN public.cards c ON c.id = cbr.card_id
    WHERE cbr.source IN ('curated', 'manual')
      AND cbr.review_status IN ('verified', 'active')
      AND cbr.execution_status IN ('auto', 'executable')
      AND COALESCE(cbr.oracle_hash, '') = ''
      AND c.oracle_text IS NOT NULL
      AND c.oracle_text <> ''
)
SELECT
    COUNT(*) AS candidate_rows,
    COUNT(*) FILTER (WHERE computed_oracle_hash <> '') AS safely_resolved_rows
FROM candidates;

SELECT
    card_name,
    normalized_name,
    logical_rule_key,
    review_status,
    execution_status
FROM public.card_battle_rules
WHERE source IN ('curated', 'manual')
  AND review_status IN ('verified', 'active')
  AND execution_status IN ('auto', 'executable')
  AND COALESCE(oracle_hash, '') = ''
ORDER BY card_name, logical_rule_key;
