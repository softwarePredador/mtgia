WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('aang''s defense', 'Aang''s Defense', '64cefc51cdab7c6274154d69adda89e2', 'battle_rule_v1:e7bf87a85c25e1f0b6d32db6efff30b5', '{"_composite_rule_components":[{"battle_model_scope":"xmage_fixed_boost_target_creature_until_eot_spell_v1","compose_on_resolution":true,"duration":"until_end_of_turn","effect":"stat_modifier_until_eot","power_boost":2,"power_delta":2,"target":"creature","target_constraints":{"card_types":["creature"],"combat_state":"blocking","controller_scope":"self"},"target_controller":"self","toughness_boost":2,"toughness_delta":2,"xmage_effect_class":"BoostTargetEffect"},{"battle_model_scope":"xmage_fixed_source_controller_draw_spell_v1","compose_on_resolution":true,"count":1,"effect":"draw_cards","xmage_effect_class":"DrawCardSourceControllerEffect"}],"battle_model_scope":"xmage_fixed_boost_target_creature_until_eot_draw_card_spell_v1","count":1,"draw_count":1,"effect":"composite_resolution","instant":true,"power_boost":2,"power_delta":2,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"],"combat_state":"blocking","controller_scope":"self"},"target_controller":"self","toughness_boost":2,"toughness_delta":2,"xmage_effect_classes":["BoostTargetEffect","DrawCardSourceControllerEffect"]}'::jsonb, '{"category":"draw","effect":"composite_resolution","target":"creature","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class AangsDefense translated into ManaLoom runtime scope xmage_fixed_boost_target_creature_until_eot_draw_card_spell_v1. This row is package-ready only because the source signature is a narrow fixed target-creature boost plus draw-card spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('gallantry', 'Gallantry', '9858f271a2639fe3e21469a90f5aa4d1', 'battle_rule_v1:73cba2a058674ea5d048304fb6b16cfb', '{"_composite_rule_components":[{"battle_model_scope":"xmage_fixed_boost_target_creature_until_eot_spell_v1","compose_on_resolution":true,"duration":"until_end_of_turn","effect":"stat_modifier_until_eot","power_boost":4,"power_delta":4,"target":"creature","target_constraints":{"card_types":["creature"],"combat_state":"blocking"},"target_controller":"any","toughness_boost":4,"toughness_delta":4,"xmage_effect_class":"BoostTargetEffect"},{"battle_model_scope":"xmage_fixed_source_controller_draw_spell_v1","compose_on_resolution":true,"count":1,"effect":"draw_cards","xmage_effect_class":"DrawCardSourceControllerEffect"}],"battle_model_scope":"xmage_fixed_boost_target_creature_until_eot_draw_card_spell_v1","count":1,"draw_count":1,"effect":"composite_resolution","instant":true,"power_boost":4,"power_delta":4,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"],"combat_state":"blocking"},"target_controller":"any","toughness_boost":4,"toughness_delta":4,"xmage_effect_classes":["BoostTargetEffect","DrawCardSourceControllerEffect"]}'::jsonb, '{"category":"draw","effect":"composite_resolution","target":"creature","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Gallantry translated into ManaLoom runtime scope xmage_fixed_boost_target_creature_until_eot_draw_card_spell_v1. This row is package-ready only because the source signature is a narrow fixed target-creature boost plus draw-card spell with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
  (SELECT count(*) FROM manaloom_deploy_audit.pg718_blocking_boost_draw_new_server_blo_20260710_200045) AS backup_rows
FROM proposed p
LEFT JOIN rule_rows r
  ON r.normalized_name = p.normalized_name
 AND r.logical_rule_key = p.logical_rule_key
 AND r.oracle_hash = p.oracle_hash
GROUP BY p.card_name, p.normalized_name, p.logical_rule_key, p.oracle_hash
ORDER BY p.card_name;
