WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('sage of the maze', 'Sage of the Maze', 'daad64346959bcce99bbacd2fe8b446b', 'battle_rule_v1:2fb3b8cb0466f30ea443828df0589bed', '{"_activated_rule_effects":[{"ability_kind":"activated","activate_only_as_sorcery":true,"activated_effect":"land_animation","activated_land_animation":true,"activation_requires_tap":true,"battle_model_scope":"xmage_activated_land_becomes_creature_gate_count_v1","effect":"land_animation","land_animation_count_subtype":"Gate","land_animation_duration":"until_end_of_turn","land_animation_granted_keywords":["haste"],"land_animation_multiplier":2,"land_animation_power_toughness_source":"controlled_subtype_count_times","land_animation_subtype":"Citizen","target":"land","target_constraints":{"card_types":["land"],"controller":"self"},"target_controller":"self","xmage_ability_class":"ActivateAsSorceryActivatedAbility","xmage_effect_class":"SageOfTheMazeEffect"},{"ability_kind":"activated","activated_effect":"untap_source","activation_requires_tap_target":true,"activation_tap_cost":"untapped_controlled_gate","activation_tap_cost_controller":"self","activation_tap_cost_subtype":"Gate","battle_model_scope":"xmage_activated_tap_gate_untap_source_v1","effect":"untap_source","gate_tap_untap_source":true,"xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"UntapSourceEffect"}],"ability_kind":"mana_and_activated","activated_battle_model_scope":"xmage_activated_land_becomes_creature_gate_count_v1","activated_effect":"land_animation_and_gate_untap_source","activation_requires_tap":true,"battle_model_scope":"xmage_simple_tap_mana_source_with_gate_land_animation_untap_v1","effect":"ramp_permanent","gate_tap_untap_source":true,"gate_tap_untap_source_cost_subtype":"Gate","is_mana_source":true,"land_animation_count_subtype":"Gate","land_animation_duration":"until_end_of_turn","land_animation_granted_keywords":["haste"],"land_animation_multiplier":2,"land_animation_power_toughness_source":"controlled_subtype_count_times","land_animation_subtype":"Citizen","mana_activation_requires_tap":true,"mana_produced":2,"permanent_type":"creature","produces":"WUBRG","source_mana_cost":"{2}{G}","source_type_line":"Creature \u2014 Elf Wizard","xmage_ability_classes":["ActivateAsSorceryActivatedAbility","HasteAbility","SimpleActivatedAbility","SimpleManaAbility"],"xmage_effect_classes":["AddManaInAnyCombinationEffect","BecomesCreatureTargetEffect","OneShotEffect","SageOfTheMazeEffect","UntapSourceEffect"],"xmage_mana_ability_classes":["SimpleManaAbility"]}'::jsonb, '{"category":"ramp","effect":"ramp_permanent"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class SageOfTheMaze translated into ManaLoom runtime scope xmage_simple_tap_mana_source_with_gate_land_animation_untap_v1. This row is package-ready only because the source signature is a narrow activated mana-source permanent with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
  (SELECT count(*) FROM manaloom_deploy_audit.pg822_sage_gate_land_animation_new_serve_20260712_092035) AS backup_rows
FROM proposed p
LEFT JOIN rule_rows r
  ON r.normalized_name = p.normalized_name
 AND r.logical_rule_key = p.logical_rule_key
 AND r.oracle_hash = p.oracle_hash
GROUP BY p.card_name, p.normalized_name, p.logical_rule_key, p.oracle_hash
ORDER BY p.card_name;
