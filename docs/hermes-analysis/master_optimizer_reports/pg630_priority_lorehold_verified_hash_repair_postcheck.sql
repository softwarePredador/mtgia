-- PG630 postcheck: expected after apply:
-- target_verified_auto_rows = 4
-- target_active_auto_rows = 0
-- target_expected_oracle_hash_rows = 4
-- trusted_executable_missing_oracle_hash = 0
-- Run via: ./server/bin/with_new_server_pg.sh psql -X -v ON_ERROR_STOP=1 -f <this file>

WITH target_rules(normalized_name, logical_rule_key, expected_hash) AS (
  VALUES
    ('fellwar stone', 'battle_rule_v1:3906ffa3cbf7d3437d68e44e13e10bba', 'd63befc8ac40d9a38732f9b5c1a7414a'),
    ('library of leng', 'battle_rule_v1:b6491cf6f7d7df9a3fb0d91abd3d31c3', '575aef3cc2523831e440ea7dcd55fa6e'),
    ('scroll rack', 'battle_rule_v1:3b58ff16a7eb52fb05c1bd8517225cd2', '8133928f03d5a5a77f2beecfcbd09e30'),
    ('talisman of conviction', 'battle_rule_v1:02133e513da5ea98ac74d32d39b16470', 'd49ceec937367a344a9f0948eea4f8f2')
)
SELECT
  'target_verified_auto_rows' AS check_name,
  COUNT(*)::text AS value
FROM card_battle_rules cbr
JOIN target_rules t USING (normalized_name, logical_rule_key)
WHERE cbr.review_status = 'verified'
  AND cbr.execution_status = 'auto'
UNION ALL
SELECT
  'target_active_auto_rows',
  COUNT(*)::text
FROM card_battle_rules cbr
JOIN target_rules t USING (normalized_name, logical_rule_key)
WHERE cbr.review_status = 'active'
  AND cbr.execution_status = 'auto'
UNION ALL
SELECT
  'target_expected_oracle_hash_rows',
  COUNT(*)::text
FROM card_battle_rules cbr
JOIN target_rules t USING (normalized_name, logical_rule_key)
WHERE cbr.oracle_hash = t.expected_hash
UNION ALL
SELECT
  'trusted_executable_missing_oracle_hash',
  COUNT(*)::text
FROM card_battle_rules
WHERE source IN ('curated', 'manual')
  AND review_status IN ('verified', 'active')
  AND execution_status IN ('auto', 'executable')
  AND COALESCE(oracle_hash, '') = '';
