WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('heraldic banner', 'Heraldic Banner', 'ed7379514aeb8e44fccbd2964c6fedda', 'battle_rule_v1:c47ed426b45962ec47c53926d1a6c9e3', '{"_composite_rule_components":[{"ability_kind":"static","battle_model_scope":"xmage_static_controlled_power_toughness_boost_v1","effect":"passive","static_applies_to":"creatures_you_control","static_effect":"controlled_power_toughness_boost","static_power_bonus":1,"static_required_chosen_color":true,"static_toughness_bonus":0,"target":"controlled_creatures","target_constraints":{"card_types":["creature"],"colors":"chosen_color","controller":"self"},"target_controller":"self","xmage_ability_class":"SimpleStaticAbility","xmage_effect_class":"HeraldicBannerEffect"}],"ability_kind":"activated_mana_and_static","activation_requires_tap":true,"battle_model_scope":"xmage_simple_tap_mana_source_permanent_v1","chosen_color_mana":true,"conditional_mana_modes":[{"color":"W","mode":"chosen_color_mana","restriction":"any_spell","status":"runtime_executor_v1"},{"color":"U","mode":"chosen_color_mana","restriction":"any_spell","status":"runtime_executor_v1"},{"color":"B","mode":"chosen_color_mana","restriction":"any_spell","status":"runtime_executor_v1"},{"color":"R","mode":"chosen_color_mana","restriction":"any_spell","status":"runtime_executor_v1"},{"color":"G","mode":"chosen_color_mana","restriction":"any_spell","status":"runtime_executor_v1"}],"conditional_mana_modes_status":"runtime_executor_v1","conditional_mana_same_color_choice":true,"effect":"ramp_permanent","is_mana_source":true,"mana_activation_requires_tap":true,"mana_produced":1,"modeled_ability_subset":"mana_source_and_chosen_color_static_boost","permanent_type":"artifact","produces":"WUBRG","xmage_ability_classes":["AsEntersBattlefieldAbility","SimpleManaAbility","SimpleStaticAbility"],"xmage_auxiliary_ability_classes":["AsEntersBattlefieldAbility","SimpleStaticAbility"],"xmage_effect_classes":["AddManaChosenColorEffect","ChooseColorEffect","HeraldicBannerEffect"],"xmage_mana_ability_classes":["SimpleManaAbility"]}'::jsonb, '{"category":"ramp","effect":"ramp_permanent"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class HeraldicBanner translated into ManaLoom runtime scope xmage_simple_tap_mana_source_permanent_v1. This row is package-ready only because the source signature is a narrow activated mana-source permanent with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
  (SELECT count(*) FROM manaloom_deploy_audit.pg820_heraldic_banner_chosen_color_stati_20260712_084027) AS backup_rows
FROM proposed p
LEFT JOIN rule_rows r
  ON r.normalized_name = p.normalized_name
 AND r.logical_rule_key = p.logical_rule_key
 AND r.oracle_hash = p.oracle_hash
GROUP BY p.card_name, p.normalized_name, p.logical_rule_key, p.oracle_hash
ORDER BY p.card_name;
