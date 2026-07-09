WITH missing AS (
  SELECT
    r.card_id,
    r.card_name,
    r.normalized_name,
    r.logical_rule_key,
    r.review_status,
    r.execution_status,
    r.rule_version,
    md5(coalesce(c.oracle_text, '')) AS computed_oracle_hash
  FROM public.card_battle_rules r
  JOIN public.cards c ON c.id = r.card_id
  WHERE r.source = 'curated'
    AND r.review_status IN ('active', 'verified')
    AND r.execution_status = 'auto'
    AND coalesce(r.oracle_hash, '') = ''
)
SELECT
  count(*) AS trusted_executable_rules_missing_oracle_hash,
  count(*) FILTER (WHERE coalesce(computed_oracle_hash, '') <> '') AS backfillable_rows
FROM missing;

WITH missing AS (
  SELECT
    r.card_name,
    r.normalized_name,
    r.logical_rule_key,
    r.review_status,
    r.rule_version,
    md5(coalesce(c.oracle_text, '')) AS computed_oracle_hash
  FROM public.card_battle_rules r
  JOIN public.cards c ON c.id = r.card_id
  WHERE r.source = 'curated'
    AND r.review_status IN ('active', 'verified')
    AND r.execution_status = 'auto'
    AND coalesce(r.oracle_hash, '') = ''
)
SELECT *
FROM missing
ORDER BY card_name, logical_rule_key;
