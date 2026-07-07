WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('breath of malfegor', 'Breath of Malfegor', '63b809af7c5db7172b1864065f6665a5', 'battle_rule_v1:1c0ff8f9f93d2b1561b7a3eb9d7c8fd6', '{"ability_kind":"one_shot","amount":5,"battle_model_scope":"spell_damage_each_opponent_v1","damage":5,"effect":"damage_each_opponent","instant":true,"sorcery":false,"target_controller":"opponents","xmage_effect_class":"DamagePlayersEffect"}'::jsonb, '{"category":"unknown","effect":"damage_each_opponent","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class BreathOfMalfegor translated into ManaLoom runtime scope spell_damage_each_opponent_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('sizzle', 'Sizzle', 'cca674b36ac5b061baaf47773f166470', 'battle_rule_v1:f893e75f14f2e36880d6fdc27b063d57', '{"ability_kind":"one_shot","amount":3,"battle_model_scope":"spell_damage_each_opponent_v1","damage":3,"effect":"damage_each_opponent","instant":false,"sorcery":true,"target_controller":"opponents","xmage_effect_class":"DamagePlayersEffect"}'::jsonb, '{"category":"unknown","effect":"damage_each_opponent"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Sizzle translated into ManaLoom runtime scope spell_damage_each_opponent_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
  (SELECT count(*) FROM manaloom_deploy_audit.pg589_damage_each_opponent_new_server_20260707_031213) AS backup_rows
FROM proposed p
LEFT JOIN rule_rows r
  ON r.normalized_name = p.normalized_name
 AND r.logical_rule_key = p.logical_rule_key
 AND r.oracle_hash = p.oracle_hash
GROUP BY p.card_name, p.normalized_name, p.logical_rule_key, p.oracle_hash
ORDER BY p.card_name;
