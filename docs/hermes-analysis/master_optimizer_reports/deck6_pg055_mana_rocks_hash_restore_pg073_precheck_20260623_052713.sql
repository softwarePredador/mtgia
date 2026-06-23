\pset pager off

WITH expected_cards(name, oracle_hash, logical_rule_key) AS (
  VALUES
    ('Fellwar Stone', 'd63befc8ac40d9a38732f9b5c1a7414a', 'battle_rule_v1:3906ffa3cbf7d3437d68e44e13e10bba'),
    ('Mana Vault', '35e3fd94c8453c0e326033af49ae18c8', 'battle_rule_v1:5a2533694ffd19223d3cde1e25d258ff'),
    ('Mox Amber', 'e47b40cf2afc4c9ceac6bf91815da706', 'battle_rule_v1:972703914ee50acd7a4e6f529fea1adf'),
    ('Talisman of Conviction', 'd49ceec937367a344a9f0948eea4f8f2', 'battle_rule_v1:02133e513da5ea98ac74d32d39b16470')
)
SELECT
  count(*) FILTER (
    WHERE c.name = e.name
      AND md5(coalesce(c.oracle_text, '')) = e.oracle_hash
  ) AS target_cards_with_expected_oracle_hash,
  count(*) FILTER (
    WHERE r.normalized_name = lower(e.name)
      AND r.logical_rule_key = e.logical_rule_key
  ) AS target_rule_rows,
  count(*) FILTER (
    WHERE r.normalized_name = lower(e.name)
      AND r.logical_rule_key = e.logical_rule_key
      AND r.execution_status = 'auto'
      AND coalesce(r.oracle_hash, '') = ''
  ) AS target_missing_hash_rows,
  to_regclass('manaloom_deploy_audit.pg073_pg055_mana_rocks_hash_restore_20260623_052713') IS NOT NULL AS backup_table_already_exists
FROM expected_cards e
LEFT JOIN cards c ON c.name = e.name
LEFT JOIN card_battle_rules r ON r.normalized_name = lower(e.name)
  AND r.logical_rule_key = e.logical_rule_key;

SELECT
  c.name,
  md5(coalesce(c.oracle_text, '')) AS card_oracle_hash,
  r.normalized_name,
  r.logical_rule_key,
  r.source,
  r.review_status,
  r.execution_status,
  r.confidence,
  r.oracle_hash,
  r.effect_json,
  r.notes
FROM cards c
JOIN card_battle_rules r ON r.card_id = c.id OR r.normalized_name = lower(c.name)
WHERE (c.name, r.logical_rule_key) IN (
  ('Fellwar Stone', 'battle_rule_v1:3906ffa3cbf7d3437d68e44e13e10bba'),
  ('Mana Vault', 'battle_rule_v1:5a2533694ffd19223d3cde1e25d258ff'),
  ('Mox Amber', 'battle_rule_v1:972703914ee50acd7a4e6f529fea1adf'),
  ('Talisman of Conviction', 'battle_rule_v1:02133e513da5ea98ac74d32d39b16470')
)
ORDER BY c.name, r.logical_rule_key;
