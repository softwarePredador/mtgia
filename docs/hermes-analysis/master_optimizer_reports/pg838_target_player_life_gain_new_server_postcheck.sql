WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('heroes'' reunion', 'Heroes'' Reunion', '51ee20702a81f565c6068f3e01b3d93c', 'battle_rule_v1:675a903affa974b767d7032ed17c9cf0', '{"battle_model_scope":"xmage_fixed_target_player_gain_life_spell_v1","effect":"life_total_change","instant":true,"life_gain_amount":7,"sorcery":false,"target":"player","target_constraints":{"players":["any"]},"target_controller":"target_player","target_player_life_gain":true,"target_preference":"self","xmage_effect_class":"GainLifeTargetEffect"}'::jsonb, '{"category":"unknown","effect":"life_total_change","target":"player","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class HeroesReunion translated into ManaLoom runtime scope xmage_fixed_target_player_gain_life_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('natural spring', 'Natural Spring', 'e386fc1de5b84be7abebce58811b70c3', 'battle_rule_v1:9e59eee82b6f319acb39d325b85d403a', '{"battle_model_scope":"xmage_fixed_target_player_gain_life_spell_v1","effect":"life_total_change","instant":false,"life_gain_amount":8,"sorcery":true,"target":"player","target_constraints":{"players":["any"]},"target_controller":"target_player","target_player_life_gain":true,"target_preference":"self","xmage_effect_class":"GainLifeTargetEffect"}'::jsonb, '{"category":"unknown","effect":"life_total_change","target":"player"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class NaturalSpring translated into ManaLoom runtime scope xmage_fixed_target_player_gain_life_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('soothing balm', 'Soothing Balm', '31d97defbfc2ea173e5eaf1581070d8b', 'battle_rule_v1:276b06bc2c0276fb1a68e9a57b8b3ed8', '{"battle_model_scope":"xmage_fixed_target_player_gain_life_spell_v1","effect":"life_total_change","instant":true,"life_gain_amount":5,"sorcery":false,"target":"player","target_constraints":{"players":["any"]},"target_controller":"target_player","target_player_life_gain":true,"target_preference":"self","xmage_effect_class":"GainLifeTargetEffect"}'::jsonb, '{"category":"unknown","effect":"life_total_change","target":"player","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class SoothingBalm translated into ManaLoom runtime scope xmage_fixed_target_player_gain_life_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
  (SELECT count(*) FROM manaloom_deploy_audit.pg838_target_player_life_gain_new_server_20260712_190745) AS backup_rows
FROM proposed p
LEFT JOIN rule_rows r
  ON r.normalized_name = p.normalized_name
 AND r.logical_rule_key = p.logical_rule_key
 AND r.oracle_hash = p.oracle_hash
GROUP BY p.card_name, p.normalized_name, p.logical_rule_key, p.oracle_hash
ORDER BY p.card_name;
