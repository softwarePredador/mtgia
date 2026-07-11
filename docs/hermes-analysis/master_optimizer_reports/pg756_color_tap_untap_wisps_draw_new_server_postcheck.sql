WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('cerulean wisps', 'Cerulean Wisps', 'a22692ce047d0fce1a8da5f13a5866d2', 'battle_rule_v1:e5609b3e5a362543a10712e8a39506cd', '{"_composite_rule_components":[{"battle_model_scope":"xmage_fixed_color_untap_target_creature_until_eot_draw_card_spell_v1","compose_on_resolution":true,"duration":"until_end_of_turn","effect":"stat_modifier_until_eot_untap_target","power_boost":0,"power_delta":0,"target":"creature","target_colors_until_eot":["U"],"target_constraints":{"card_types":["creature"]},"target_controller":"any","toughness_boost":0,"toughness_delta":0,"untap_target":true,"xmage_effect_classes":["BecomesColorTargetEffect","UntapTargetEffect"]},{"battle_model_scope":"xmage_fixed_source_controller_draw_spell_v1","compose_on_resolution":true,"count":1,"effect":"draw_cards","xmage_effect_class":"DrawCardSourceControllerEffect"}],"battle_model_scope":"xmage_fixed_color_untap_target_creature_until_eot_draw_card_spell_v1","count":1,"draw_count":1,"duration":"until_end_of_turn","effect":"composite_resolution","instant":true,"sorcery":false,"tap_target":false,"target":"creature","target_colors_until_eot":["U"],"target_constraints":{"card_types":["creature"]},"target_controller":"any","untap_target":true,"xmage_effect_classes":["BecomesColorTargetEffect","UntapTargetEffect","DrawCardSourceControllerEffect"]}'::jsonb, '{"category":"draw","effect":"composite_resolution","target":"creature","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class CeruleanWisps translated into ManaLoom runtime scope xmage_fixed_color_untap_target_creature_until_eot_draw_card_spell_v1. This row is package-ready only because the source signature is a narrow fixed target-creature color plus untap plus draw-card spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('niveous wisps', 'Niveous Wisps', 'd9d9df0786e7bae924dd76f7e96011de', 'battle_rule_v1:9d1889e17266414aa7a75f27ae012dae', '{"_composite_rule_components":[{"battle_model_scope":"xmage_tap_target_spell_v1","compose_on_resolution":true,"duration":"until_end_of_turn","effect":"tap_target","target":"creature","target_colors_until_eot":["W"],"target_constraints":{"card_types":["creature"]},"target_controller":"any","target_count":1,"xmage_effect_classes":["BecomesColorTargetEffect","TapTargetEffect"]},{"battle_model_scope":"xmage_fixed_source_controller_draw_spell_v1","compose_on_resolution":true,"count":1,"effect":"draw_cards","xmage_effect_class":"DrawCardSourceControllerEffect"}],"battle_model_scope":"xmage_fixed_color_tap_target_creature_until_eot_draw_card_spell_v1","count":1,"draw_count":1,"duration":"until_end_of_turn","effect":"composite_resolution","instant":true,"sorcery":false,"tap_target":true,"target":"creature","target_colors_until_eot":["W"],"target_constraints":{"card_types":["creature"]},"target_controller":"any","untap_target":false,"xmage_effect_classes":["BecomesColorTargetEffect","TapTargetEffect","DrawCardSourceControllerEffect"]}'::jsonb, '{"category":"draw","effect":"composite_resolution","target":"creature","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class NiveousWisps translated into ManaLoom runtime scope xmage_fixed_color_tap_target_creature_until_eot_draw_card_spell_v1. This row is package-ready only because the source signature is a narrow fixed target-creature color plus tap plus draw-card spell with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
  (SELECT count(*) FROM manaloom_deploy_audit.pg756_color_tap_untap_wisps_draw_new_ser_20260711_103725) AS backup_rows
FROM proposed p
LEFT JOIN rule_rows r
  ON r.normalized_name = p.normalized_name
 AND r.logical_rule_key = p.logical_rule_key
 AND r.oracle_hash = p.oracle_hash
GROUP BY p.card_name, p.normalized_name, p.logical_rule_key, p.oracle_hash
ORDER BY p.card_name;
