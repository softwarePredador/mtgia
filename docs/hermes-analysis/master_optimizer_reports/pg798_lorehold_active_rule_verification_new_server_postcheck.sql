WITH target(card_name, normalized_name, logical_rule_key, expected_oracle_hash) AS (
  VALUES
    ('Fellwar Stone', 'fellwar stone', 'battle_rule_v1:3906ffa3cbf7d3437d68e44e13e10bba', 'd63befc8ac40d9a38732f9b5c1a7414a'),
    ('Library of Leng', 'library of leng', 'battle_rule_v1:b6491cf6f7d7df9a3fb0d91abd3d31c3', '575aef3cc2523831e440ea7dcd55fa6e'),
    ('Scroll Rack', 'scroll rack', 'battle_rule_v1:3b58ff16a7eb52fb05c1bd8517225cd2', '8133928f03d5a5a77f2beecfcbd09e30'),
    ('Talisman of Conviction', 'talisman of conviction', 'battle_rule_v1:02133e513da5ea98ac74d32d39b16470', 'd49ceec937367a344a9f0948eea4f8f2')
),
rule_rows AS (
  SELECT
    t.card_name,
    r.review_status,
    r.execution_status,
    r.oracle_hash,
    cis.verified_battle_rule_count
  FROM target t
  LEFT JOIN public.card_battle_rules r
    ON r.normalized_name = t.normalized_name
   AND r.logical_rule_key = t.logical_rule_key
  LEFT JOIN public.cards c
    ON lower(c.name) = t.normalized_name
  LEFT JOIN public.card_intelligence_snapshot cis
    ON cis.card_id = c.id
)
SELECT
  card_name,
  count(*) FILTER (WHERE review_status = 'verified' AND execution_status = 'auto') AS verified_auto_rows,
  count(*) FILTER (WHERE oracle_hash = expected_oracle_hash) AS expected_hash_rows,
  max(verified_battle_rule_count) AS snapshot_verified_battle_rule_count,
  (SELECT count(*) FROM manaloom_deploy_audit.pg798_lorehold_active_rule_verification_new_server_20260712) AS backup_rows
FROM target
LEFT JOIN rule_rows USING (card_name)
GROUP BY card_name, expected_oracle_hash
ORDER BY card_name;
