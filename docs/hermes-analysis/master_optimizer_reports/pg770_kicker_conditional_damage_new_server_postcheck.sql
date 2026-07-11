WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('burst lightning', 'Burst Lightning', 'fb96df51721f23975651d397f45cbaf6', 'battle_rule_v1:89baa42c48cb4963324ad583c78176f1', '{"amount":2,"battle_model_scope":"xmage_conditional_fixed_damage_target_spell_v1","conditional_damage_amount":4,"conditional_damage_base_amount":2,"conditional_damage_condition":"spell_was_kicked","damage":2,"effect":"direct_damage","instant":true,"kicker_mana_cost":"{4}","sorcery":false,"target":"any_target","target_constraints":{"scope":"any_target"},"xmage_effect_classes":["ConditionalOneShotEffect","DamageTargetEffect"]}'::jsonb, '{"category":"unknown","effect":"direct_damage","target":"any_target","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class BurstLightning translated into ManaLoom runtime scope xmage_conditional_fixed_damage_target_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('firebending lesson', 'Firebending Lesson', 'd5b939bd58e925df717bb458a8725b6a', 'battle_rule_v1:7941b219f17a558f7aadcb3166a8e336', '{"amount":2,"battle_model_scope":"xmage_conditional_fixed_damage_target_spell_v1","conditional_damage_amount":5,"conditional_damage_base_amount":2,"conditional_damage_condition":"spell_was_kicked","damage":2,"effect":"direct_damage","instant":true,"kicker_mana_cost":"{4}","sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"]},"xmage_effect_classes":["ConditionalOneShotEffect","DamageTargetEffect"]}'::jsonb, '{"category":"unknown","effect":"direct_damage","target":"creature","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class FirebendingLesson translated into ManaLoom runtime scope xmage_conditional_fixed_damage_target_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('roil eruption', 'Roil Eruption', 'e386358370a386896091f6964bb08e62', 'battle_rule_v1:f4110e72e2f14c1eab5f9c45a3df207d', '{"amount":3,"battle_model_scope":"xmage_conditional_fixed_damage_target_spell_v1","conditional_damage_amount":5,"conditional_damage_base_amount":3,"conditional_damage_condition":"spell_was_kicked","damage":3,"effect":"direct_damage","instant":false,"kicker_mana_cost":"{5}","sorcery":true,"target":"any_target","target_constraints":{"scope":"any_target"},"xmage_effect_classes":["ConditionalOneShotEffect","DamageTargetEffect"]}'::jsonb, '{"category":"unknown","effect":"direct_damage","target":"any_target"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class RoilEruption translated into ManaLoom runtime scope xmage_conditional_fixed_damage_target_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('shivan fire', 'Shivan Fire', 'f986322fbcfa63f5a2bb448cebf528f8', 'battle_rule_v1:5bef1665571b88b031b54efeb6563a0c', '{"amount":2,"battle_model_scope":"xmage_conditional_fixed_damage_target_spell_v1","conditional_damage_amount":4,"conditional_damage_base_amount":2,"conditional_damage_condition":"spell_was_kicked","damage":2,"effect":"direct_damage","instant":true,"kicker_mana_cost":"{4}","sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"]},"xmage_effect_classes":["ConditionalOneShotEffect","DamageTargetEffect"]}'::jsonb, '{"category":"unknown","effect":"direct_damage","target":"creature","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ShivanFire translated into ManaLoom runtime scope xmage_conditional_fixed_damage_target_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
  (SELECT count(*) FROM manaloom_deploy_audit.pg770_kicker_conditional_damage_new_serv_20260711_154242) AS backup_rows
FROM proposed p
LEFT JOIN rule_rows r
  ON r.normalized_name = p.normalized_name
 AND r.logical_rule_key = p.logical_rule_key
 AND r.oracle_hash = p.oracle_hash
GROUP BY p.card_name, p.normalized_name, p.logical_rule_key, p.oracle_hash
ORDER BY p.card_name;
