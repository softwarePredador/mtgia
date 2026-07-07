WITH missing AS (
  SELECT
    r.normalized_name,
    r.card_name,
    r.logical_rule_key,
    r.review_status,
    r.execution_status,
    r.rule_version,
    r.source,
    r.oracle_hash AS current_oracle_hash,
    md5(coalesce(c.oracle_text, '')) AS candidate_oracle_hash
  FROM public.card_battle_rules r
  JOIN public.cards c
    ON c.id = r.card_id
  WHERE r.review_status IN ('verified', 'active')
    AND r.execution_status IN ('auto', 'executable')
    AND nullif(r.oracle_hash, '') IS NULL
    AND nullif(c.oracle_text, '') IS NOT NULL
)
SELECT
  count(*) AS candidate_rows,
  count(*) FILTER (WHERE candidate_oracle_hash IS NOT NULL) AS hashable_rows,
  jsonb_agg(
    jsonb_build_object(
      'normalized_name', normalized_name,
      'card_name', card_name,
      'logical_rule_key', logical_rule_key,
      'candidate_oracle_hash', candidate_oracle_hash
    )
    ORDER BY normalized_name, logical_rule_key
  ) AS candidates
FROM missing;
