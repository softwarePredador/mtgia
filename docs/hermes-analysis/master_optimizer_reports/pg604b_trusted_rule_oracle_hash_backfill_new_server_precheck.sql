WITH missing AS (
  SELECT
    r.card_id,
    r.card_name,
    r.normalized_name,
    r.logical_rule_key
  FROM public.card_battle_rules r
  WHERE r.source IN ('curated', 'manual')
    AND r.review_status IN ('verified', 'active')
    AND r.execution_status IN ('auto', 'executable')
    AND COALESCE(r.oracle_hash, '') = ''
),
candidates AS (
  SELECT
    m.card_id,
    m.card_name,
    m.normalized_name,
    m.logical_rule_key,
    COUNT(c.*) AS matched_card_rows,
    COUNT(DISTINCT md5(COALESCE(c.oracle_text, ''))) AS distinct_hashes,
    MIN(md5(COALESCE(c.oracle_text, ''))) AS computed_oracle_hash
  FROM missing m
  LEFT JOIN public.cards c
    ON c.id = m.card_id
  GROUP BY m.card_id, m.card_name, m.normalized_name, m.logical_rule_key
)
SELECT
  (SELECT COUNT(*) FROM missing) AS missing_hash_rules,
  COUNT(*) AS candidate_rules,
  COUNT(*) FILTER (WHERE matched_card_rows > 0 AND distinct_hashes = 1) AS safe_candidate_rules,
  COUNT(*) FILTER (WHERE matched_card_rows = 0) AS no_card_match_rules,
  COUNT(*) FILTER (WHERE distinct_hashes <> 1) AS ambiguous_hash_rules
FROM candidates;
