WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('ogre siegebreaker', 'Ogre Siegebreaker', 'd9fe6fc297eeb748b517f9c308c77065', 'battle_rule_v1:034bd4c748e35fe57e52d223c648e8fd', '{"_activated_rule_effects":[{"ability_kind":"activated","activated_effect":"destroy_target","activated_remove_effect":"remove_creature","activated_remove_target":"creature_damaged_this_turn","activation_cost_colors":["B","R"],"activation_cost_generic":2,"activation_cost_mana":"{2}{B}{R}","activation_requires_sacrifice":false,"activation_requires_tap":false,"battle_model_scope":"xmage_permanent_simple_activated_destroy_target_v1","destination":"graveyard","effect":"remove_creature","target":"creature","target_constraints":{"card_types":["creature"],"damaged_this_turn":true},"xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"DestroyTargetEffect"}],"ability_kind":"static_and_activated","activated_battle_model_scope":"xmage_permanent_simple_activated_destroy_target_v1","activated_effect":"destroy_target","activated_remove_effect":"remove_creature","activated_remove_target":"creature_damaged_this_turn","activation_cost_colors":["B","R"],"activation_cost_generic":2,"activation_cost_mana":"{2}{B}{R}","activation_requires_sacrifice":false,"activation_requires_tap":false,"battle_model_scope":"xmage_permanent_simple_activated_destroy_target_v1","destination":"graveyard","effect":"creature","target":"creature","target_constraints":{"card_types":["creature"],"damaged_this_turn":true},"xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"DestroyTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class OgreSiegebreaker translated into ManaLoom runtime scope xmage_permanent_simple_activated_destroy_target_v1. This row is package-ready only because the source signature is a narrow permanent with a simple activated destroy-target ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('opportunist', 'Opportunist', 'aba5ffef49bc71c0b02a3ce50eca9c8c', 'battle_rule_v1:06261c009c5bcea9c7932e535c7b3359', '{"_activated_rule_effects":[{"ability_kind":"activated","activated_effect":"direct_damage","activation_cost_colors":[],"activation_cost_generic":0,"activation_cost_mana":"{0}","activation_requires_sacrifice":false,"activation_requires_tap":true,"activation_sacrifice_cost":null,"amount":1,"battle_model_scope":"xmage_permanent_simple_activated_damage_v1","damage":1,"effect":"direct_damage","target":"creature_damaged_this_turn","target_constraints":{"card_types":["creature"],"damaged_this_turn":true},"xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"DamageTargetEffect"}],"ability_kind":"static_and_activated","activated_battle_model_scope":"xmage_permanent_simple_activated_damage_v1","activated_damage_amount":1,"activated_effect":"direct_damage","activation_cost_colors":[],"activation_cost_generic":0,"activation_cost_mana":"{0}","activation_requires_sacrifice":false,"activation_requires_tap":true,"battle_model_scope":"xmage_permanent_simple_activated_damage_v1","effect":"creature","target":"creature_damaged_this_turn","target_constraints":{"card_types":["creature"],"damaged_this_turn":true},"xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"DamageTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"creature_damaged_this_turn"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Opportunist translated into ManaLoom runtime scope xmage_permanent_simple_activated_damage_v1. This row is package-ready only because the source signature is a narrow permanent with a simple activated damage ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('witch''s mist', 'Witch''s Mist', '6feafae65830ccd4967852c92320404b', 'battle_rule_v1:9b34535f520f3ad0fd7e365e758a83b0', '{"_activated_rule_effects":[{"ability_kind":"activated","activated_effect":"destroy_target","activated_remove_effect":"remove_creature","activated_remove_target":"creature_damaged_this_turn","activation_cost_colors":["B"],"activation_cost_generic":2,"activation_cost_mana":"{2}{B}","activation_requires_sacrifice":false,"activation_requires_tap":true,"battle_model_scope":"xmage_permanent_simple_activated_destroy_target_v1","destination":"graveyard","effect":"remove_creature","target":"creature","target_constraints":{"card_types":["creature"],"damaged_this_turn":true},"xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"DestroyTargetEffect"}],"ability_kind":"static_and_activated","activated_battle_model_scope":"xmage_permanent_simple_activated_destroy_target_v1","activated_effect":"destroy_target","activated_remove_effect":"remove_creature","activated_remove_target":"creature_damaged_this_turn","activation_cost_colors":["B"],"activation_cost_generic":2,"activation_cost_mana":"{2}{B}","activation_requires_sacrifice":false,"activation_requires_tap":true,"battle_model_scope":"xmage_permanent_simple_activated_destroy_target_v1","destination":"graveyard","effect":"enchantment","target":"creature","target_constraints":{"card_types":["creature"],"damaged_this_turn":true},"xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"DestroyTargetEffect"}'::jsonb, '{"category":"unknown","effect":"enchantment","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class WitchsMist translated into ManaLoom runtime scope xmage_permanent_simple_activated_destroy_target_v1. This row is package-ready only because the source signature is a narrow permanent with a simple activated destroy-target ability with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
  (SELECT count(*) FROM manaloom_deploy_audit.pg506_xmage_pg506_activated_damaged_crea_20260705_124220) AS backup_rows
FROM proposed p
LEFT JOIN rule_rows r
  ON r.normalized_name = p.normalized_name
 AND r.logical_rule_key = p.logical_rule_key
 AND r.oracle_hash = p.oracle_hash
GROUP BY p.card_name, p.normalized_name, p.logical_rule_key, p.oracle_hash
ORDER BY p.card_name;
