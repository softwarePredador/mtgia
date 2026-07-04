WITH target(normalized_name, card_name, logical_rule_key) AS (
  VALUES
    ('angel''s grace', 'Angel''s Grace', 'battle_rule_v1:2833836fd4d943d3e02d1cfa2d284227'),
    ('seething song', 'Seething Song', 'battle_rule_v1:3eb15dc581c6b913158f9b63c023f3d7')
),
card_hash AS (
  SELECT lower(name) AS normalized_name, name, md5(coalesce(oracle_text, '')) AS oracle_hash
  FROM public.cards
  WHERE lower(name) IN (SELECT normalized_name FROM target)
)
SELECT
  t.card_name,
  t.normalized_name,
  t.logical_rule_key,
  r.review_status,
  r.execution_status,
  r.source,
  coalesce(r.oracle_hash, '') AS current_rule_oracle_hash,
  ch.oracle_hash AS expected_oracle_hash,
  (coalesce(r.oracle_hash, '') = '') AS needs_backfill,
  (r.review_status = 'verified' AND r.execution_status = 'auto' AND r.source = 'curated') AS eligible
FROM target t
JOIN public.card_battle_rules r
  ON r.normalized_name = t.normalized_name
 AND r.logical_rule_key = t.logical_rule_key
JOIN card_hash ch
  ON ch.normalized_name = t.normalized_name
ORDER BY t.card_name;
