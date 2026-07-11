WITH missing AS (
  SELECT
    r.card_name,
    r.normalized_name,
    r.logical_rule_key,
    r.review_status,
    r.execution_status,
    r.rule_version,
    r.source,
    c.id AS matched_card_id,
    md5(coalesce(c.oracle_text, '')) AS proposed_oracle_hash
  FROM public.card_battle_rules r
  JOIN public.cards c
    ON c.id = r.card_id
  WHERE r.source IN ('curated', 'manual')
    AND r.review_status IN ('verified', 'active')
    AND r.execution_status IN ('auto', 'executable')
    AND coalesce(r.oracle_hash, '') = ''
    AND coalesce(c.oracle_text, '') <> ''
)
SELECT
  count(*) AS trusted_executable_rules_missing_oracle_hash,
  count(DISTINCT normalized_name) AS distinct_normalized_names,
  count(*) FILTER (WHERE matched_card_id IS NOT NULL) AS matched_card_rows,
  count(*) FILTER (WHERE proposed_oracle_hash IS NOT NULL AND proposed_oracle_hash <> '') AS proposed_hash_rows
FROM missing;

WITH missing AS (
  SELECT
    r.card_name,
    r.normalized_name,
    r.logical_rule_key,
    r.review_status,
    r.execution_status,
    r.rule_version,
    r.source,
    c.id AS matched_card_id,
    md5(coalesce(c.oracle_text, '')) AS proposed_oracle_hash
  FROM public.card_battle_rules r
  JOIN public.cards c
    ON c.id = r.card_id
  WHERE r.source IN ('curated', 'manual')
    AND r.review_status IN ('verified', 'active')
    AND r.execution_status IN ('auto', 'executable')
    AND coalesce(r.oracle_hash, '') = ''
    AND coalesce(c.oracle_text, '') <> ''
)
SELECT *
FROM missing
ORDER BY normalized_name, logical_rule_key
LIMIT 100;
