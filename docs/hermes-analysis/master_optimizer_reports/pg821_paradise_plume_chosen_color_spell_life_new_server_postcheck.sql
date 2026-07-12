WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('paradise plume', 'Paradise Plume', 'a2880170c087ee9a6c80e6b600d90f87', 'battle_rule_v1:8e6d57e4b283029ea7dffebfc3f096a5', '{"_composite_rule_components":[{"ability_kind":"triggered","battle_model_scope":"xmage_spell_cast_gain_life_v1","effect":"life_gain_engine","spell_cast_gain_life":true,"spell_cast_gain_life_amount":1,"spell_cast_gain_life_any_player":true,"spell_cast_gain_life_optional":true,"spell_cast_gain_life_required_chosen_color":true,"trigger":"spell_cast","trigger_effect":"gain_life","xmage_ability_class":"ParadisePlumeSpellCastTriggeredAbility","xmage_effect_class":"GainLifeEffect"}],"ability_kind":"activated_mana_and_triggered","activation_requires_tap":true,"battle_model_scope":"xmage_simple_tap_mana_source_permanent_v1","chosen_color_mana":true,"conditional_mana_modes":[{"color":"W","mode":"chosen_color_mana","restriction":"any_spell","status":"runtime_executor_v1"},{"color":"U","mode":"chosen_color_mana","restriction":"any_spell","status":"runtime_executor_v1"},{"color":"B","mode":"chosen_color_mana","restriction":"any_spell","status":"runtime_executor_v1"},{"color":"R","mode":"chosen_color_mana","restriction":"any_spell","status":"runtime_executor_v1"},{"color":"G","mode":"chosen_color_mana","restriction":"any_spell","status":"runtime_executor_v1"}],"conditional_mana_modes_status":"runtime_executor_v1","conditional_mana_same_color_choice":true,"effect":"ramp_permanent","is_mana_source":true,"mana_activation_requires_tap":true,"mana_produced":1,"modeled_ability_subset":"mana_source_and_chosen_color_spell_cast_gain_life","permanent_type":"artifact","produces":"WUBRG","xmage_ability_classes":["AsEntersBattlefieldAbility","ParadisePlumeSpellCastTriggeredAbility","SimpleManaAbility"],"xmage_auxiliary_ability_classes":["AsEntersBattlefieldAbility","ParadisePlumeSpellCastTriggeredAbility"],"xmage_effect_classes":["AddManaChosenColorEffect","ChooseColorEffect","GainLifeEffect"],"xmage_mana_ability_classes":["SimpleManaAbility"]}'::jsonb, '{"category":"ramp","effect":"ramp_permanent"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ParadisePlume translated into ManaLoom runtime scope xmage_simple_tap_mana_source_permanent_v1. This row is package-ready only because the source signature is a narrow activated mana-source permanent with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
  (SELECT count(*) FROM manaloom_deploy_audit.pg821_paradise_plume_chosen_color_spell_20260712_085838) AS backup_rows
FROM proposed p
LEFT JOIN rule_rows r
  ON r.normalized_name = p.normalized_name
 AND r.logical_rule_key = p.logical_rule_key
 AND r.oracle_hash = p.oracle_hash
GROUP BY p.card_name, p.normalized_name, p.logical_rule_key, p.oracle_hash
ORDER BY p.card_name;
