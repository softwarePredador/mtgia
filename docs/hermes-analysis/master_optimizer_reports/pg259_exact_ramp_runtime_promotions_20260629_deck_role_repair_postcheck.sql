WITH expected(normalized_name, logical_rule_key, expected_deck_role_json) AS (
  VALUES
    ('bridgeworks battle', 'battle_rule_v1:d822fc4ce8a0850a7ee20dcee168e8f3', '{"category":"ramp","effect":"ramp_permanent"}'::jsonb),
    ('hydroelectric specimen', 'battle_rule_v1:88c8f7a7f18d2171c1d200c61f47e6d4', '{"category":"ramp","effect":"ramp_permanent"}'::jsonb),
    ('selvala, heart of the wilds', 'battle_rule_v1:1ee83f01d2315d8468be5462667233ad', '{"category":"ramp","effect":"ramp_permanent"}'::jsonb),
    ('devoted druid', 'battle_rule_v1:67f97b25cf58b747257151dada64b9e4', '{"category":"ramp","effect":"ramp_permanent"}'::jsonb),
    ('birgi, god of storytelling', 'battle_rule_v1:c21762e62b990dbb474be0b5764d71a7', '{"category":"ramp","effect":"ramp_engine"}'::jsonb),
    ('fractured powerstone', 'battle_rule_v1:0e90c515e59dff042e41f45158c63e97', '{"category":"ramp","effect":"ramp_permanent"}'::jsonb),
    ('incubation druid', 'battle_rule_v1:de0ac6ce79a7fff3d4b1f65e91e73d0d', '{"category":"ramp","effect":"ramp_permanent"}'::jsonb),
    ('delighted halfling', 'battle_rule_v1:3f0dd0a85440805f77ce47815c44214a', '{"category":"ramp","effect":"ramp_permanent"}'::jsonb)
)
SELECT
  e.normalized_name,
  r.card_name,
  e.logical_rule_key,
  count(r.*) FILTER (WHERE r.deck_role_json = e.expected_deck_role_json) AS repaired_deck_role_rows,
  count(r.*) FILTER (WHERE r.review_status = 'verified' AND r.execution_status = 'auto') AS verified_auto_rows,
  count(r.*) FILTER (WHERE r.oracle_hash IS NOT NULL AND r.oracle_hash <> '') AS oracle_hash_rows,
  (SELECT count(*) FROM manaloom_deploy_audit.pg259_exact_ramp_deck_role_repair_20260629_1718) AS backup_rows
FROM expected e
LEFT JOIN public.card_battle_rules r
  ON r.normalized_name = e.normalized_name
 AND r.logical_rule_key = e.logical_rule_key
GROUP BY e.normalized_name, r.card_name, e.logical_rule_key
ORDER BY e.normalized_name;
