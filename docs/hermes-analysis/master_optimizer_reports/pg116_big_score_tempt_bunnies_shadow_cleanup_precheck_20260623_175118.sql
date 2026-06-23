WITH wanted(normalized_name, display_name, expected_hash, promoted_rule_key) AS (
  VALUES
    (
      'big score',
      'Big Score',
      '9c4fbe06104051a2e8b1d295d307b26a',
      'battle_rule_v1:af9f14d18cc283719be2ef2680b6f1ed'
    ),
    (
      'tempt with bunnies',
      'Tempt with Bunnies',
      '201f6c7234bfef550f3d497e736f0d7a',
      'battle_rule_v1:64814289c1def19e7cd5bb7462c4cf86'
    ),
    (
      'tempt with bunnies',
      'Tempt with Bunnies',
      '201f6c7234bfef550f3d497e736f0d7a',
      'battle_rule_v1:ac96c7799172699f5d7b6b0dc5e4aa80'
    )
),
card_matches AS (
  SELECT
    w.normalized_name,
    min(w.display_name) AS display_name,
    min(w.expected_hash) AS expected_hash,
    count(DISTINCT c.id) AS card_rows
  FROM wanted w
  LEFT JOIN public.cards c
    ON lower(c.name) = w.normalized_name
   AND md5(coalesce(c.oracle_text, '')) = w.expected_hash
  GROUP BY w.normalized_name
),
rule_counts AS (
  SELECT
    w.normalized_name,
    count(r.*) AS existing_rule_rows,
    count(*) FILTER (
      WHERE r.logical_rule_key = w.promoted_rule_key
        AND r.review_status IN ('verified', 'active')
        AND r.execution_status IN ('auto', 'executable')
        AND coalesce(r.oracle_hash, '') = w.expected_hash
    ) AS promoted_rows,
    count(*) FILTER (
      WHERE r.logical_rule_key NOT IN (
        'battle_rule_v1:af9f14d18cc283719be2ef2680b6f1ed',
        'battle_rule_v1:64814289c1def19e7cd5bb7462c4cf86',
        'battle_rule_v1:ac96c7799172699f5d7b6b0dc5e4aa80'
      )
    ) AS shadow_rows
  FROM wanted w
  LEFT JOIN public.card_battle_rules r
    ON r.normalized_name = w.normalized_name
  GROUP BY w.normalized_name
)
SELECT
  cm.display_name,
  cm.expected_hash,
  cm.card_rows,
  rc.existing_rule_rows,
  rc.promoted_rows,
  rc.shadow_rows
FROM card_matches cm
JOIN rule_counts rc USING (normalized_name)
ORDER BY cm.display_name;

SELECT
  r.card_name,
  r.logical_rule_key,
  r.review_status,
  r.execution_status,
  r.rule_version,
  r.oracle_hash,
  r.effect_json
FROM public.card_battle_rules r
WHERE r.normalized_name IN ('big score', 'tempt with bunnies')
ORDER BY r.card_name, r.review_status, r.execution_status, r.logical_rule_key;
