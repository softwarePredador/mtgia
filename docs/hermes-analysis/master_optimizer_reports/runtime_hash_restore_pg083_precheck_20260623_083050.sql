\pset pager off

WITH expected(normalized_name, card_name, logical_rule_key, expected_oracle_hash) AS (
  VALUES
    ('fellwar stone', 'Fellwar Stone', 'battle_rule_v1:3906ffa3cbf7d3437d68e44e13e10bba', 'd63befc8ac40d9a38732f9b5c1a7414a'),
    ('mana vault', 'Mana Vault', 'battle_rule_v1:5a2533694ffd19223d3cde1e25d258ff', '35e3fd94c8453c0e326033af49ae18c8'),
    ('mox amber', 'Mox Amber', 'battle_rule_v1:972703914ee50acd7a4e6f529fea1adf', 'e47b40cf2afc4c9ceac6bf91815da706'),
    ('talisman of conviction', 'Talisman of Conviction', 'battle_rule_v1:02133e513da5ea98ac74d32d39b16470', 'd49ceec937367a344a9f0948eea4f8f2'),
    ('seething song', 'Seething Song', 'battle_rule_v1:3eb15dc581c6b913158f9b63c023f3d7', 'ccd492289c6f1c14c8fb7a248d7bbf32')
),
target_rows AS (
  SELECT
    e.*,
    cbr.review_status,
    cbr.execution_status,
    cbr.oracle_hash,
    md5(coalesce(c.oracle_text, '')) AS current_oracle_hash,
    cbr.effect_json->>'battle_model_scope' AS battle_model_scope
  FROM expected e
  JOIN card_battle_rules cbr
    ON cbr.normalized_name = e.normalized_name
   AND cbr.logical_rule_key = e.logical_rule_key
  JOIN cards c
    ON c.id = cbr.card_id
)
SELECT
  count(*) AS target_rows,
  count(*) FILTER (WHERE oracle_hash IS NULL OR oracle_hash = '') AS missing_hash_rows,
  count(*) FILTER (WHERE current_oracle_hash = expected_oracle_hash) AS current_hash_match_rows,
  count(*) FILTER (WHERE review_status IN ('verified', 'active') AND execution_status = 'auto') AS trusted_auto_rows
FROM target_rows;

WITH expected(normalized_name, card_name, logical_rule_key, expected_oracle_hash) AS (
  VALUES
    ('fellwar stone', 'Fellwar Stone', 'battle_rule_v1:3906ffa3cbf7d3437d68e44e13e10bba', 'd63befc8ac40d9a38732f9b5c1a7414a'),
    ('mana vault', 'Mana Vault', 'battle_rule_v1:5a2533694ffd19223d3cde1e25d258ff', '35e3fd94c8453c0e326033af49ae18c8'),
    ('mox amber', 'Mox Amber', 'battle_rule_v1:972703914ee50acd7a4e6f529fea1adf', 'e47b40cf2afc4c9ceac6bf91815da706'),
    ('talisman of conviction', 'Talisman of Conviction', 'battle_rule_v1:02133e513da5ea98ac74d32d39b16470', 'd49ceec937367a344a9f0948eea4f8f2'),
    ('seething song', 'Seething Song', 'battle_rule_v1:3eb15dc581c6b913158f9b63c023f3d7', 'ccd492289c6f1c14c8fb7a248d7bbf32')
)
SELECT
  cbr.card_name,
  cbr.logical_rule_key,
  cbr.oracle_hash,
  md5(coalesce(c.oracle_text, '')) AS current_oracle_hash,
  e.expected_oracle_hash,
  cbr.review_status,
  cbr.execution_status,
  cbr.effect_json->>'battle_model_scope' AS battle_model_scope
FROM expected e
JOIN card_battle_rules cbr
  ON cbr.normalized_name = e.normalized_name
 AND cbr.logical_rule_key = e.logical_rule_key
JOIN cards c
  ON c.id = cbr.card_id
ORDER BY cbr.card_name;
