WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('fodder tosser', 'Fodder Tosser', 'fc32c851215fda8c42f0bf540c60b704', 'battle_rule_v1:d35ce8a381cc3d6a0cc576fb6108b3cc', '{"_activated_rule_effects":[{"ability_kind":"activated","activated_effect":"direct_damage","activation_cost_colors":[],"activation_cost_generic":0,"activation_cost_mana":"{0}","activation_discard_count":1,"activation_discard_target":"any_card","activation_requires_sacrifice":false,"activation_requires_tap":true,"activation_sacrifice_cost":null,"amount":2,"battle_model_scope":"xmage_permanent_simple_activated_damage_v1","damage":2,"effect":"direct_damage","target":"player_or_planeswalker","target_constraints":{"scope":"player_or_planeswalker"},"xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"DamageTargetEffect"}],"ability_kind":"static_and_activated","activated_battle_model_scope":"xmage_permanent_simple_activated_damage_v1","activated_damage_amount":2,"activated_effect":"direct_damage","activation_cost_colors":[],"activation_cost_generic":0,"activation_cost_mana":"{0}","activation_discard_count":1,"activation_discard_target":"any_card","activation_requires_sacrifice":false,"activation_requires_tap":true,"battle_model_scope":"xmage_permanent_simple_activated_damage_v1","effect":"artifact","target":"player_or_planeswalker","target_constraints":{"scope":"player_or_planeswalker"},"xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"DamageTargetEffect"}'::jsonb, '{"category":"unknown","effect":"artifact","target":"player_or_planeswalker"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class FodderTosser translated into ManaLoom runtime scope xmage_permanent_simple_activated_damage_v1. This row is package-ready only because the source signature is a narrow permanent with a simple activated damage ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('kris mage', 'Kris Mage', '077c393a3a48b51541b86d4ee5673d59', 'battle_rule_v1:155303f01b41347d870d32c90f594ff8', '{"_activated_rule_effects":[{"ability_kind":"activated","activated_effect":"direct_damage","activation_cost_colors":["R"],"activation_cost_generic":0,"activation_cost_mana":"{R}","activation_discard_count":1,"activation_discard_target":"any_card","activation_requires_sacrifice":false,"activation_requires_tap":true,"activation_sacrifice_cost":null,"amount":1,"battle_model_scope":"xmage_permanent_simple_activated_damage_v1","damage":1,"effect":"direct_damage","target":"any_target","target_constraints":{"scope":"any_target"},"xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"DamageTargetEffect"}],"ability_kind":"static_and_activated","activated_battle_model_scope":"xmage_permanent_simple_activated_damage_v1","activated_damage_amount":1,"activated_effect":"direct_damage","activation_cost_colors":["R"],"activation_cost_generic":0,"activation_cost_mana":"{R}","activation_discard_count":1,"activation_discard_target":"any_card","activation_requires_sacrifice":false,"activation_requires_tap":true,"battle_model_scope":"xmage_permanent_simple_activated_damage_v1","effect":"creature","target":"any_target","target_constraints":{"scope":"any_target"},"xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"DamageTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"any_target"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class KrisMage translated into ManaLoom runtime scope xmage_permanent_simple_activated_damage_v1. This row is package-ready only because the source signature is a narrow permanent with a simple activated damage ability with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
  (SELECT count(*) FROM manaloom_deploy_audit.pg485_activated_damage_discard_cost_new_20260705_055422) AS backup_rows
FROM proposed p
LEFT JOIN rule_rows r
  ON r.normalized_name = p.normalized_name
 AND r.logical_rule_key = p.logical_rule_key
 AND r.oracle_hash = p.oracle_hash
GROUP BY p.card_name, p.normalized_name, p.logical_rule_key, p.oracle_hash
ORDER BY p.card_name;
