WITH targets AS (
  SELECT
    br.normalized_name,
    br.card_name,
    br.logical_rule_key,
    br.review_status,
    br.execution_status,
    br.rule_version,
    c.id AS card_id,
    c.name AS matched_card_name,
    md5(coalesce(c.oracle_text, '')) AS computed_oracle_hash
  FROM public.card_battle_rules br
  JOIN public.cards c ON c.id = br.card_id
  WHERE br.review_status IN ('verified', 'active')
    AND br.execution_status = 'auto'
    AND coalesce(btrim(br.oracle_hash), '') = ''
    AND btrim(coalesce(c.oracle_text, '')) <> ''
)
SELECT
  count(*) AS fillable_trusted_executable_missing_hash_rows,
  count(DISTINCT card_id) AS fillable_card_count,
  count(DISTINCT normalized_name) AS fillable_identity_count,
  count(*) FILTER (WHERE computed_oracle_hash IS NULL OR computed_oracle_hash = '') AS missing_computed_hash
FROM targets;

WITH targets AS (
  SELECT
    br.normalized_name,
    br.card_name,
    br.logical_rule_key,
    br.review_status,
    br.execution_status,
    br.rule_version,
    c.name AS matched_card_name,
    md5(coalesce(c.oracle_text, '')) AS computed_oracle_hash
  FROM public.card_battle_rules br
  JOIN public.cards c ON c.id = br.card_id
  WHERE br.review_status IN ('verified', 'active')
    AND br.execution_status = 'auto'
    AND coalesce(btrim(br.oracle_hash), '') = ''
    AND btrim(coalesce(c.oracle_text, '')) <> ''
)
SELECT
  normalized_name,
  card_name,
  matched_card_name,
  logical_rule_key,
  review_status,
  execution_status,
  rule_version,
  computed_oracle_hash
FROM targets
ORDER BY normalized_name, logical_rule_key;
