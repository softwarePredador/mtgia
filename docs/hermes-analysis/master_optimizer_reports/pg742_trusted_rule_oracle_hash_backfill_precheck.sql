WITH target AS (
  SELECT
    r.normalized_name,
    r.card_name,
    r.card_id,
    r.logical_rule_key,
    r.review_status,
    r.execution_status,
    r.source,
    c.name AS matched_card_name,
    md5(coalesce(c.oracle_text, '')) AS computed_oracle_hash,
    coalesce(c.oracle_text, '') <> '' AS has_oracle_text
  FROM public.card_battle_rules r
  LEFT JOIN public.cards c ON c.id = r.card_id
  WHERE r.review_status IN ('verified', 'active')
    AND r.execution_status = 'auto'
    AND coalesce(r.oracle_hash, '') = ''
)
SELECT
  count(*) AS trusted_executable_rules_missing_oracle_hash,
  count(*) FILTER (WHERE card_id IS NULL) AS missing_card_id,
  count(*) FILTER (WHERE matched_card_name IS NULL) AS unmatched_card_id,
  count(*) FILTER (WHERE NOT has_oracle_text) AS matched_empty_oracle_text,
  count(*) FILTER (WHERE matched_card_name IS NOT NULL AND has_oracle_text) AS safe_backfill_rows
FROM target;
