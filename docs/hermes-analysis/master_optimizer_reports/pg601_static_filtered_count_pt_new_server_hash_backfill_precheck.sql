WITH missing AS (
  SELECT
    r.card_name,
    r.normalized_name,
    r.logical_rule_key,
    r.review_status,
    r.execution_status,
    r.rule_version,
    c.id AS matched_card_id,
    c.name AS matched_card_name,
    md5(coalesce(c.oracle_text, '')) AS computed_oracle_hash
  FROM public.card_battle_rules r
  LEFT JOIN public.cards c
    ON c.id = r.card_id
  WHERE r.source = 'curated'
    AND r.execution_status = 'auto'
    AND r.review_status IN ('active', 'verified')
    AND coalesce(r.oracle_hash, '') = ''
)
SELECT
  count(*) AS missing_oracle_hash_rows,
  count(matched_card_id) AS matched_by_card_id_rows,
  count(*) FILTER (WHERE computed_oracle_hash IS NULL OR computed_oracle_hash = '') AS missing_computed_hash_rows
FROM missing;

WITH missing AS (
  SELECT
    r.card_name,
    r.normalized_name,
    r.logical_rule_key,
    r.review_status,
    r.execution_status,
    r.rule_version,
    c.name AS matched_card_name,
    md5(coalesce(c.oracle_text, '')) AS computed_oracle_hash
  FROM public.card_battle_rules r
  JOIN public.cards c
    ON c.id = r.card_id
  WHERE r.source = 'curated'
    AND r.execution_status = 'auto'
    AND r.review_status IN ('active', 'verified')
    AND coalesce(r.oracle_hash, '') = ''
)
SELECT *
FROM missing
ORDER BY card_name, logical_rule_key;
