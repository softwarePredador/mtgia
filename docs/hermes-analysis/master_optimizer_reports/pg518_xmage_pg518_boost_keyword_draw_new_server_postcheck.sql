WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('guided strike', 'Guided Strike', 'b3d4cd02e513dc7ee5a83669a6b8e10e', 'battle_rule_v1:88c885e72847e263872123f6ff2fe637', '{"_composite_rule_components":[{"battle_model_scope":"xmage_fixed_boost_and_keyword_target_creature_until_eot_spell_v1","compose_on_resolution":true,"duration":"until_end_of_turn","effect":"stat_modifier_until_eot","granted_keywords_until_eot":["first_strike"],"power_boost":1,"power_delta":1,"target":"creature","target_constraints":{"card_types":["creature"]},"target_controller":"any","toughness_boost":0,"toughness_delta":0,"xmage_ability_class":"FirstStrikeAbility","xmage_effect_classes":["BoostTargetEffect","GainAbilityTargetEffect"]},{"battle_model_scope":"xmage_fixed_source_controller_draw_spell_v1","compose_on_resolution":true,"count":1,"effect":"draw_cards","xmage_effect_class":"DrawCardSourceControllerEffect"}],"battle_model_scope":"xmage_fixed_boost_keyword_target_creature_until_eot_draw_card_spell_v1","count":1,"draw_count":1,"duration":"until_end_of_turn","effect":"composite_resolution","granted_keywords_until_eot":["first_strike"],"instant":true,"power_boost":1,"power_delta":1,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"]},"target_controller":"any","toughness_boost":0,"toughness_delta":0,"xmage_ability_class":"FirstStrikeAbility","xmage_effect_classes":["BoostTargetEffect","GainAbilityTargetEffect","DrawCardSourceControllerEffect"]}'::jsonb, '{"category":"draw","effect":"composite_resolution","target":"creature","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class GuidedStrike translated into ManaLoom runtime scope xmage_fixed_boost_keyword_target_creature_until_eot_draw_card_spell_v1. This row is package-ready only because the source signature is a narrow fixed target-creature boost plus keyword plus draw-card spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('moment of defiance', 'Moment of Defiance', '23906329d5b444b279c9ef6a7dd35514', 'battle_rule_v1:221bf8673582ca83b654cbb7f538c5b3', '{"_composite_rule_components":[{"battle_model_scope":"xmage_fixed_boost_and_keyword_target_creature_until_eot_spell_v1","compose_on_resolution":true,"duration":"until_end_of_turn","effect":"stat_modifier_until_eot","granted_keywords_until_eot":["lifelink"],"power_boost":2,"power_delta":2,"target":"creature","target_constraints":{"card_types":["creature"]},"target_controller":"any","toughness_boost":1,"toughness_delta":1,"xmage_ability_class":"LifelinkAbility","xmage_effect_classes":["BoostTargetEffect","GainAbilityTargetEffect"]},{"battle_model_scope":"xmage_fixed_source_controller_draw_spell_v1","compose_on_resolution":true,"count":1,"effect":"draw_cards","xmage_effect_class":"DrawCardSourceControllerEffect"}],"battle_model_scope":"xmage_fixed_boost_keyword_target_creature_until_eot_draw_card_spell_v1","count":1,"draw_count":1,"duration":"until_end_of_turn","effect":"composite_resolution","granted_keywords_until_eot":["lifelink"],"instant":true,"power_boost":2,"power_delta":2,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"]},"target_controller":"any","toughness_boost":1,"toughness_delta":1,"xmage_ability_class":"LifelinkAbility","xmage_effect_classes":["BoostTargetEffect","GainAbilityTargetEffect","DrawCardSourceControllerEffect"]}'::jsonb, '{"category":"draw","effect":"composite_resolution","target":"creature","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class MomentOfDefiance translated into ManaLoom runtime scope xmage_fixed_boost_keyword_target_creature_until_eot_draw_card_spell_v1. This row is package-ready only because the source signature is a narrow fixed target-creature boost plus keyword plus draw-card spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('wildsize', 'Wildsize', '53a7ce9768d844d0cd47da03bd002f14', 'battle_rule_v1:ab0e05cb41a3ff08d36f10f1a103d961', '{"_composite_rule_components":[{"battle_model_scope":"xmage_fixed_boost_and_keyword_target_creature_until_eot_spell_v1","compose_on_resolution":true,"duration":"until_end_of_turn","effect":"stat_modifier_until_eot","granted_keywords_until_eot":["trample"],"power_boost":2,"power_delta":2,"target":"creature","target_constraints":{"card_types":["creature"]},"target_controller":"any","toughness_boost":2,"toughness_delta":2,"xmage_ability_class":"TrampleAbility","xmage_effect_classes":["BoostTargetEffect","GainAbilityTargetEffect"]},{"battle_model_scope":"xmage_fixed_source_controller_draw_spell_v1","compose_on_resolution":true,"count":1,"effect":"draw_cards","xmage_effect_class":"DrawCardSourceControllerEffect"}],"battle_model_scope":"xmage_fixed_boost_keyword_target_creature_until_eot_draw_card_spell_v1","count":1,"draw_count":1,"duration":"until_end_of_turn","effect":"composite_resolution","granted_keywords_until_eot":["trample"],"instant":true,"power_boost":2,"power_delta":2,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"]},"target_controller":"any","toughness_boost":2,"toughness_delta":2,"xmage_ability_class":"TrampleAbility","xmage_effect_classes":["BoostTargetEffect","GainAbilityTargetEffect","DrawCardSourceControllerEffect"]}'::jsonb, '{"category":"draw","effect":"composite_resolution","target":"creature","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Wildsize translated into ManaLoom runtime scope xmage_fixed_boost_keyword_target_creature_until_eot_draw_card_spell_v1. This row is package-ready only because the source signature is a narrow fixed target-creature boost plus keyword plus draw-card spell with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
  (SELECT count(*) FROM manaloom_deploy_audit.xmage_pg518_boost_keyword_draw_new_serve_20260705_170024) AS backup_rows
FROM proposed p
LEFT JOIN rule_rows r
  ON r.normalized_name = p.normalized_name
 AND r.logical_rule_key = p.logical_rule_key
 AND r.oracle_hash = p.oracle_hash
GROUP BY p.card_name, p.normalized_name, p.logical_rule_key, p.oracle_hash
ORDER BY p.card_name;
