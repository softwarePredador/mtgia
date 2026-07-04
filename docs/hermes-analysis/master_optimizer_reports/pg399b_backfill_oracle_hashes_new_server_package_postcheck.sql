WITH target(normalized_name, card_name, logical_rule_key) AS (
  VALUES
    ('angel''s grace', 'Angel''s Grace', 'battle_rule_v1:2833836fd4d943d3e02d1cfa2d284227'),
    ('seething song', 'Seething Song', 'battle_rule_v1:3eb15dc581c6b913158f9b63c023f3d7')
),
checked AS (
  SELECT
    t.card_name,
    r.normalized_name,
    r.logical_rule_key,
    r.review_status,
    r.execution_status,
    r.rule_version,
    r.oracle_hash,
    md5(coalesce(c.oracle_text, '')) AS computed_oracle_hash,
    (r.oracle_hash = md5(coalesce(c.oracle_text, ''))) AS oracle_hash_matches
  FROM target t
  JOIN public.card_battle_rules r
    ON r.normalized_name = t.normalized_name
   AND r.logical_rule_key = t.logical_rule_key
  JOIN public.cards c
    ON c.id = r.card_id
)
SELECT *
FROM checked
ORDER BY card_name;

SELECT
  count(*) FILTER (
    WHERE review_status IN ('verified', 'active')
      AND execution_status = 'auto'
      AND coalesce(oracle_hash, '') = ''
  ) AS trusted_executable_rules_missing_oracle_hash
FROM public.card_battle_rules;
