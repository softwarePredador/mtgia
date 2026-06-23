WITH wanted(normalized_name, expected_hash, expected_rule_key) AS (
  VALUES
    (
      'promise of loyalty',
      '21dd715160fde6e50b8edc015ce83b0f',
      'battle_rule_v1:78fff8e218103b0710bc5ee9cf174ee9'
    ),
    (
      'starfall invocation',
      '3429884949eac8ffe09d86dc85bee1ae',
      'battle_rule_v1:58cfb4628b4a4a879f6f9c5e0ab3ee5f'
    ),
    (
      'tragic arrogance',
      'efdf5d051aaa7f94b12c4dccbbfd7d3d',
      'battle_rule_v1:d4d676e6ecea500f7aca4cbc7f7ae04a'
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
    ) AS target_active_rows,
    count(*) FILTER (
      WHERE r.logical_rule_key <> w.expected_rule_key
    ) AS shadow_rows
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
  er.target_active_rows,
  er.shadow_rows
FROM card_matches cm
JOIN existing_rules er USING (normalized_name)
ORDER BY cm.normalized_name;

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
WHERE r.normalized_name IN (
  'promise of loyalty',
  'starfall invocation',
  'tragic arrogance'
)
ORDER BY r.normalized_name, r.review_status, r.execution_status, r.logical_rule_key;
