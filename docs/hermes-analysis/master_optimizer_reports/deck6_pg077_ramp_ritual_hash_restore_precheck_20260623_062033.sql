\pset pager off

CREATE TEMP TABLE pg077_hash_targets(
  normalized_name text,
  card_name text,
  logical_rule_key text,
  expected_oracle_hash text
);

INSERT INTO pg077_hash_targets(normalized_name, card_name, logical_rule_key, expected_oracle_hash)
VALUES
  ('fellwar stone', 'Fellwar Stone', 'battle_rule_v1:3906ffa3cbf7d3437d68e44e13e10bba', 'd63befc8ac40d9a38732f9b5c1a7414a'),
  ('mana vault', 'Mana Vault', 'battle_rule_v1:5a2533694ffd19223d3cde1e25d258ff', '35e3fd94c8453c0e326033af49ae18c8'),
  ('mox amber', 'Mox Amber', 'battle_rule_v1:972703914ee50acd7a4e6f529fea1adf', 'e47b40cf2afc4c9ceac6bf91815da706'),
  ('seething song', 'Seething Song', 'battle_rule_v1:3eb15dc581c6b913158f9b63c023f3d7', 'ccd492289c6f1c14c8fb7a248d7bbf32'),
  ('talisman of conviction', 'Talisman of Conviction', 'battle_rule_v1:02133e513da5ea98ac74d32d39b16470', 'd49ceec937367a344a9f0948eea4f8f2');

SELECT
  count(*) FILTER (WHERE md5(coalesce(c.oracle_text, '')) = t.expected_oracle_hash) AS target_cards_with_expected_oracle_hash,
  count(*) AS target_rule_rows,
  count(*) FILTER (WHERE cbr.oracle_hash IS NULL OR cbr.oracle_hash = '') AS target_missing_hash_rows,
  to_regclass('manaloom_deploy_audit.pg077_ramp_ritual_hash_restore_20260623_062033') IS NOT NULL AS backup_table_already_exists
FROM pg077_hash_targets t
JOIN cards c ON c.name = t.card_name
JOIN card_battle_rules cbr
  ON cbr.normalized_name = t.normalized_name
 AND cbr.logical_rule_key = t.logical_rule_key;

SELECT
  t.card_name,
  md5(coalesce(c.oracle_text, '')) AS current_oracle_hash,
  t.expected_oracle_hash,
  cbr.normalized_name,
  cbr.logical_rule_key,
  cbr.review_status,
  cbr.execution_status,
  cbr.rule_version,
  cbr.oracle_hash,
  cbr.effect_json
FROM pg077_hash_targets t
JOIN cards c ON c.name = t.card_name
JOIN card_battle_rules cbr
  ON cbr.normalized_name = t.normalized_name
 AND cbr.logical_rule_key = t.logical_rule_key
ORDER BY t.card_name;
