WITH wanted(normalized_name, expected_hash, expected_rule_key) AS (
  VALUES
    (
      'surge to victory',
      '5381f78ff0798b9afad371e0fa495831',
      'battle_rule_v1:44a0c5f4d0c51f52db6a36d12f9db98e'
    )
),
card_matches AS (
  SELECT
    w.normalized_name,
    w.expected_hash,
    count(c.id) AS card_rows
  FROM wanted w
  LEFT JOIN public.cards c
    ON lower(c.name) = w.normalized_name
   AND md5(coalesce(c.oracle_text, '')) = w.expected_hash
  GROUP BY w.normalized_name, w.expected_hash
),
existing_rules AS (
  SELECT
    w.normalized_name,
    count(r.*) AS existing_rule_rows,
    count(*) FILTER (
      WHERE r.logical_rule_key = w.expected_rule_key
        AND r.review_status IN ('verified', 'active')
        AND r.execution_status IN ('auto', 'executable')
    ) AS target_active_rows
  FROM wanted w
  LEFT JOIN public.card_battle_rules r
    ON r.normalized_name = w.normalized_name
  GROUP BY w.normalized_name
)
SELECT
  cm.normalized_name,
  cm.expected_hash,
  cm.card_rows,
  er.existing_rule_rows,
  er.target_active_rows
FROM card_matches cm
JOIN existing_rules er USING (normalized_name);

SELECT
  r.normalized_name,
  r.logical_rule_key,
  r.review_status,
  r.execution_status,
  r.rule_version,
  r.oracle_hash,
  r.effect_json,
  r.deck_role_json
FROM public.card_battle_rules r
WHERE r.normalized_name = 'surge to victory'
ORDER BY r.review_status, r.execution_status, r.logical_rule_key;
