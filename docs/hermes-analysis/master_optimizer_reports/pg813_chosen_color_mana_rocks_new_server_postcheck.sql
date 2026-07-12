WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('coldsteel heart', 'Coldsteel Heart', '9d6650367df528200e461a450bf72316', 'battle_rule_v1:6b6db0a08a852de8bdd7f907d94579e6', '{"activation_requires_tap":true,"battle_model_scope":"xmage_simple_tap_mana_source_permanent_v1","chosen_color_mana":true,"conditional_mana_modes":[{"color":"W","mode":"chosen_color_mana","restriction":"any_spell","status":"runtime_executor_v1"},{"color":"U","mode":"chosen_color_mana","restriction":"any_spell","status":"runtime_executor_v1"},{"color":"B","mode":"chosen_color_mana","restriction":"any_spell","status":"runtime_executor_v1"},{"color":"R","mode":"chosen_color_mana","restriction":"any_spell","status":"runtime_executor_v1"},{"color":"G","mode":"chosen_color_mana","restriction":"any_spell","status":"runtime_executor_v1"}],"conditional_mana_modes_status":"runtime_executor_v1","conditional_mana_same_color_choice":true,"effect":"ramp_permanent","enters_tapped":true,"is_mana_source":true,"mana_activation_requires_tap":true,"mana_produced":1,"permanent_type":"artifact","produces":"WUBRG","xmage_ability_classes":["EntersBattlefieldAbility","EntersBattlefieldTappedAbility","SimpleManaAbility"],"xmage_auxiliary_ability_classes":["EntersBattlefieldAbility","EntersBattlefieldTappedAbility"],"xmage_effect_classes":["AddManaChosenColorEffect","ChooseColorEffect"],"xmage_mana_ability_classes":["SimpleManaAbility"]}'::jsonb, '{"category":"ramp","effect":"ramp_permanent"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ColdsteelHeart translated into ManaLoom runtime scope xmage_simple_tap_mana_source_permanent_v1. This row is package-ready only because the source signature is a narrow activated mana-source permanent with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('silhana starfletcher', 'Silhana Starfletcher', '99a589ba0512a29d3d4e826388562944', 'battle_rule_v1:f9fcea12e78f1c1e8bc84bd02310a448', '{"activation_requires_tap":true,"battle_model_scope":"xmage_simple_tap_mana_source_permanent_v1","chosen_color_mana":true,"conditional_mana_modes":[{"color":"W","mode":"chosen_color_mana","restriction":"any_spell","status":"runtime_executor_v1"},{"color":"U","mode":"chosen_color_mana","restriction":"any_spell","status":"runtime_executor_v1"},{"color":"B","mode":"chosen_color_mana","restriction":"any_spell","status":"runtime_executor_v1"},{"color":"R","mode":"chosen_color_mana","restriction":"any_spell","status":"runtime_executor_v1"},{"color":"G","mode":"chosen_color_mana","restriction":"any_spell","status":"runtime_executor_v1"}],"conditional_mana_modes_status":"runtime_executor_v1","conditional_mana_same_color_choice":true,"effect":"ramp_permanent","is_mana_source":true,"keywords":["reach"],"mana_activation_requires_tap":true,"mana_produced":1,"permanent_type":"creature","produces":"WUBRG","xmage_ability_classes":["AsEntersBattlefieldAbility","ReachAbility","SimpleManaAbility"],"xmage_auxiliary_ability_classes":["AsEntersBattlefieldAbility","ReachAbility"],"xmage_effect_classes":["AddManaChosenColorEffect","ChooseColorEffect"],"xmage_mana_ability_classes":["SimpleManaAbility"]}'::jsonb, '{"category":"ramp","effect":"ramp_permanent"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class SilhanaStarfletcher translated into ManaLoom runtime scope xmage_simple_tap_mana_source_permanent_v1. This row is package-ready only because the source signature is a narrow activated mana-source permanent with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('sol grail', 'Sol Grail', 'f6dec29a6733b7575f987330b3e15f6e', 'battle_rule_v1:e4a191f4762f3bac6907af7c632ee849', '{"activation_requires_tap":true,"battle_model_scope":"xmage_simple_tap_mana_source_permanent_v1","chosen_color_mana":true,"conditional_mana_modes":[{"color":"W","mode":"chosen_color_mana","restriction":"any_spell","status":"runtime_executor_v1"},{"color":"U","mode":"chosen_color_mana","restriction":"any_spell","status":"runtime_executor_v1"},{"color":"B","mode":"chosen_color_mana","restriction":"any_spell","status":"runtime_executor_v1"},{"color":"R","mode":"chosen_color_mana","restriction":"any_spell","status":"runtime_executor_v1"},{"color":"G","mode":"chosen_color_mana","restriction":"any_spell","status":"runtime_executor_v1"}],"conditional_mana_modes_status":"runtime_executor_v1","conditional_mana_same_color_choice":true,"effect":"ramp_permanent","is_mana_source":true,"mana_activation_requires_tap":true,"mana_produced":1,"permanent_type":"artifact","produces":"WUBRG","xmage_ability_classes":["AsEntersBattlefieldAbility","SimpleManaAbility"],"xmage_auxiliary_ability_classes":["AsEntersBattlefieldAbility"],"xmage_effect_classes":["AddManaChosenColorEffect","ChooseColorEffect"],"xmage_mana_ability_classes":["SimpleManaAbility"]}'::jsonb, '{"category":"ramp","effect":"ramp_permanent"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class SolGrail translated into ManaLoom runtime scope xmage_simple_tap_mana_source_permanent_v1. This row is package-ready only because the source signature is a narrow activated mana-source permanent with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
  (SELECT count(*) FROM manaloom_deploy_audit.pg813_chosen_color_mana_rocks_new_server_20260712_072553) AS backup_rows
FROM proposed p
LEFT JOIN rule_rows r
  ON r.normalized_name = p.normalized_name
 AND r.logical_rule_key = p.logical_rule_key
 AND r.oracle_hash = p.oracle_hash
GROUP BY p.card_name, p.normalized_name, p.logical_rule_key, p.oracle_hash
ORDER BY p.card_name;
