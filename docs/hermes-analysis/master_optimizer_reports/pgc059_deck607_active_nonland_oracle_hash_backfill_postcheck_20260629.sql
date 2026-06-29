WITH expected(normalized_name, logical_rule_key, expected_oracle_hash) AS (
  VALUES
    ('fellwar stone', 'battle_rule_v1:3906ffa3cbf7d3437d68e44e13e10bba', 'd63befc8ac40d9a38732f9b5c1a7414a'),
    ('library of leng', 'battle_rule_v1:b6491cf6f7d7df9a3fb0d91abd3d31c3', '575aef3cc2523831e440ea7dcd55fa6e'),
    ('scroll rack', 'battle_rule_v1:3b58ff16a7eb52fb05c1bd8517225cd2', '8133928f03d5a5a77f2beecfcbd09e30'),
    ('talisman of conviction', 'battle_rule_v1:02133e513da5ea98ac74d32d39b16470', 'd49ceec937367a344a9f0948eea4f8f2'),
    ('unexpected windfall', 'battle_rule_v1:f9f98ea1925518eea7a7c94c21ef2dc4', '9c4fbe06104051a2e8b1d295d307b26a')
),
target AS (
  SELECT
    r.normalized_name,
    r.logical_rule_key,
    r.oracle_hash,
    md5(coalesce(c.oracle_text, '')) AS computed_oracle_hash,
    e.expected_oracle_hash,
    r.review_status,
    r.execution_status,
    r.rule_version
  FROM expected e
  JOIN public.card_battle_rules r
    ON r.normalized_name = e.normalized_name
   AND r.logical_rule_key = e.logical_rule_key
  JOIN public.cards c
    ON c.id = r.card_id
)
SELECT
  count(*) AS target_rows,
  count(*) FILTER (
    WHERE oracle_hash = expected_oracle_hash
      AND oracle_hash = computed_oracle_hash
  ) AS restored_hash_rows,
  count(*) FILTER (
    WHERE review_status IN ('verified', 'active')
      AND execution_status IN ('auto', 'executable')
      AND rule_version >= 2
  ) AS trusted_v2_executable_rows,
  (
    SELECT count(*)
    FROM manaloom_deploy_audit.pgc059_deck607_active_nonland_oracle_hash_backfill_20260629
  ) AS backup_rows
FROM target;
