\pset pager off

SELECT
  count(*) AS target_rule_rows,
  count(*) FILTER (
    WHERE (normalized_name, logical_rule_key, oracle_hash) IN (
      ('fellwar stone', 'battle_rule_v1:3906ffa3cbf7d3437d68e44e13e10bba', 'd63befc8ac40d9a38732f9b5c1a7414a'),
      ('mana vault', 'battle_rule_v1:5a2533694ffd19223d3cde1e25d258ff', '35e3fd94c8453c0e326033af49ae18c8'),
      ('mox amber', 'battle_rule_v1:972703914ee50acd7a4e6f529fea1adf', 'e47b40cf2afc4c9ceac6bf91815da706'),
      ('talisman of conviction', 'battle_rule_v1:02133e513da5ea98ac74d32d39b16470', 'd49ceec937367a344a9f0948eea4f8f2')
    )
    AND execution_status = 'auto'
  ) AS expected_runtime_rows,
  count(*) FILTER (
    WHERE coalesce(oracle_hash, '') = ''
  ) AS target_missing_hash_rows,
  (
    SELECT count(*)
    FROM manaloom_deploy_audit.pg073_pg055_mana_rocks_hash_restore_20260623_052713
  ) AS backup_rows
FROM card_battle_rules
WHERE (normalized_name, logical_rule_key) IN (
  ('fellwar stone', 'battle_rule_v1:3906ffa3cbf7d3437d68e44e13e10bba'),
  ('mana vault', 'battle_rule_v1:5a2533694ffd19223d3cde1e25d258ff'),
  ('mox amber', 'battle_rule_v1:972703914ee50acd7a4e6f529fea1adf'),
  ('talisman of conviction', 'battle_rule_v1:02133e513da5ea98ac74d32d39b16470')
);

SELECT
  normalized_name,
  logical_rule_key,
  source,
  review_status,
  execution_status,
  confidence,
  oracle_hash,
  effect_json,
  notes
FROM card_battle_rules
WHERE (normalized_name, logical_rule_key) IN (
  ('fellwar stone', 'battle_rule_v1:3906ffa3cbf7d3437d68e44e13e10bba'),
  ('mana vault', 'battle_rule_v1:5a2533694ffd19223d3cde1e25d258ff'),
  ('mox amber', 'battle_rule_v1:972703914ee50acd7a4e6f529fea1adf'),
  ('talisman of conviction', 'battle_rule_v1:02133e513da5ea98ac74d32d39b16470')
)
ORDER BY normalized_name, logical_rule_key;
