WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('stream of life', 'Stream of Life', 'f3a7424b1617ff88e5d0d3a6a9137e6d', 'battle_rule_v1:aeedf5dfe932f52a340bafd8c6f63680', '{"battle_model_scope":"xmage_fixed_target_player_gain_life_spell_v1","effect":"life_total_change","instant":false,"life_gain_amount":0,"life_gain_amount_source":"x_value","sorcery":true,"target":"player","target_constraints":{"players":["any"]},"target_controller":"target_player","target_player_life_gain":true,"target_preference":"self","xmage_effect_class":"GainLifeTargetEffect"}'::jsonb, '{"category":"unknown","effect":"life_total_change","target":"player"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class StreamOfLife translated into ManaLoom runtime scope xmage_fixed_target_player_gain_life_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows')
),
rule_rows AS (
  SELECT
    r.normalized_name,
    r.logical_rule_key,
    r.oracle_hash,
    r.review_status,
    r.execution_status
  FROM proposed p
  LEFT JOIN public.card_battle_rules r
    ON (
         r.normalized_name = p.normalized_name
         OR r.normalized_name LIKE p.normalized_name || ' // %'
       )
   AND r.logical_rule_key = p.logical_rule_key
)
SELECT
  p.card_name,
  p.normalized_name,
  p.logical_rule_key,
  count(r.*) FILTER (WHERE r.logical_rule_key = p.logical_rule_key) AS promoted_rule_rows,
  count(r.*) FILTER (WHERE r.review_status = 'verified' AND r.execution_status = 'auto') AS promoted_verified_auto_rows,
  count(r.*) FILTER (WHERE r.oracle_hash = p.oracle_hash) AS promoted_oracle_hash_rows,
  (SELECT count(*) FROM manaloom_deploy_audit.pg840_target_player_x_life_gain_new_serv_20260712_193737) AS backup_rows
FROM proposed p
LEFT JOIN rule_rows r
  ON r.normalized_name = p.normalized_name
 AND r.logical_rule_key = p.logical_rule_key
 AND r.oracle_hash = p.oracle_hash
GROUP BY p.card_name, p.normalized_name, p.logical_rule_key, p.oracle_hash
ORDER BY p.card_name;
