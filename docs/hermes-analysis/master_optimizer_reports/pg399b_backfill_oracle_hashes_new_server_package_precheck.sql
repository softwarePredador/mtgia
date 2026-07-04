WITH target(normalized_name, card_name, logical_rule_key) AS (
  VALUES
    ('angel''s grace', 'Angel''s Grace', 'battle_rule_v1:2833836fd4d943d3e02d1cfa2d284227'),
    ('seething song', 'Seething Song', 'battle_rule_v1:3eb15dc581c6b913158f9b63c023f3d7')
),
candidate AS (
  SELECT
    t.card_name,
    r.normalized_name,
    r.logical_rule_key,
    r.card_id,
    r.review_status,
    r.execution_status,
    r.rule_version,
    r.oracle_hash AS current_oracle_hash,
    c.name AS pg_card_name,
    md5(coalesce(c.oracle_text, '')) AS computed_oracle_hash,
    length(coalesce(c.oracle_text, '')) AS oracle_text_length
  FROM target t
  LEFT JOIN public.card_battle_rules r
    ON r.normalized_name = t.normalized_name
   AND r.logical_rule_key = t.logical_rule_key
  LEFT JOIN public.cards c
    ON c.id = r.card_id
)
SELECT *
FROM candidate
ORDER BY card_name;
