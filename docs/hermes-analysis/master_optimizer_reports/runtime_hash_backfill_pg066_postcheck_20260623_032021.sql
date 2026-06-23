\pset pager off

WITH expected(normalized_name, logical_rule_key, expected_oracle_hash) AS (
  VALUES
    ('silence', 'battle_rule_v1:74b210b77b004a677906e0216d44e445', 'a0ca3c09a7db091c435ab31adb9c1780'),
    ('fellwar stone', 'battle_rule_v1:3906ffa3cbf7d3437d68e44e13e10bba', 'd63befc8ac40d9a38732f9b5c1a7414a'),
    ('mana vault', 'battle_rule_v1:5a2533694ffd19223d3cde1e25d258ff', '35e3fd94c8453c0e326033af49ae18c8'),
    ('mox amber', 'battle_rule_v1:972703914ee50acd7a4e6f529fea1adf', 'e47b40cf2afc4c9ceac6bf91815da706'),
    ('seething song', 'battle_rule_v1:3eb15dc581c6b913158f9b63c023f3d7', 'ccd492289c6f1c14c8fb7a248d7bbf32'),
    ('talisman of conviction', 'battle_rule_v1:02133e513da5ea98ac74d32d39b16470', 'd49ceec937367a344a9f0948eea4f8f2'),
    ('valakut awakening', 'battle_rule_v1:245b8d2627720fadfd7a30464d07605a', '22b42fcc181b7aed71f78b2e1e51e887'),
    ('valakut awakening // valakut stoneforge', 'battle_rule_v1:6e1f3b876822abafe1de47610f46858d', '22b42fcc181b7aed71f78b2e1e51e887')
),
joined AS (
  SELECT e.*, cbr.card_name, cbr.review_status, cbr.execution_status, cbr.oracle_hash, cbr.effect_json
  FROM expected e
  LEFT JOIN card_battle_rules cbr
    ON cbr.normalized_name = e.normalized_name
   AND cbr.logical_rule_key = e.logical_rule_key
)
SELECT
  count(*) AS expected_rows,
  count(*) FILTER (WHERE review_status IN ('verified', 'active') AND execution_status IN ('auto', 'executable')) AS trusted_runtime_rows,
  count(*) FILTER (WHERE oracle_hash = expected_oracle_hash) AS expected_hash_rows,
  count(*) FILTER (WHERE oracle_hash IS DISTINCT FROM expected_oracle_hash) AS hash_mismatch_rows,
  (
    SELECT count(*)
    FROM manaloom_deploy_audit.pg066_runtime_hash_backfill_20260623_032021
  ) AS backup_rows,
  jsonb_pretty(jsonb_agg(to_jsonb(joined) ORDER BY card_name, normalized_name, logical_rule_key)) AS target_rows
FROM joined;
