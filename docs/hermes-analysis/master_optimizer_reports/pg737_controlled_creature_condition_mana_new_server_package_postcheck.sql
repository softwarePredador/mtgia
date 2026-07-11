WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('ilysian caryatid', 'Ilysian Caryatid', '38bdfde44fc92b2697d1939332bcf207', 'battle_rule_v1:f7bf9957a984ed49743b2184f4d94e68', '{"ability_kind":"activated_mana","activation_requires_tap":true,"battle_model_scope":"xmage_controlled_creature_condition_conditional_mana_source_permanent_v1","conditional_mana_controlled_creature_power_gte":4,"conditional_mana_modes":[{"color":"W","mode":"controlled_creature_power_gte","restriction":"any_spell","status":"runtime_executor_v1"},{"color":"U","mode":"controlled_creature_power_gte","restriction":"any_spell","status":"runtime_executor_v1"},{"color":"B","mode":"controlled_creature_power_gte","restriction":"any_spell","status":"runtime_executor_v1"},{"color":"R","mode":"controlled_creature_power_gte","restriction":"any_spell","status":"runtime_executor_v1"},{"color":"G","mode":"controlled_creature_power_gte","restriction":"any_spell","status":"runtime_executor_v1"}],"conditional_mana_modes_status":"runtime_executor_v1","conditional_mana_produced_when_condition_met":2,"conditional_mana_same_color_choice":true,"effect":"ramp_permanent","is_mana_source":true,"mana_activation_requires_tap":true,"mana_produced":1,"permanent_type":"creature","produces":"WUBRG","source_mana_cost":"{1}{G}","source_type_line":"Creature \u2014 Plant","xmage_ability_classes":["SimpleManaAbility"],"xmage_effect_classes":["AddManaOfAnyColorEffect","ConditionalManaEffect"],"xmage_mana_ability_classes":["SimpleManaAbility"]}'::jsonb, '{"category":"ramp","effect":"ramp_permanent"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class IlysianCaryatid translated into ManaLoom runtime scope xmage_controlled_creature_condition_conditional_mana_source_permanent_v1. This row is package-ready only because the source signature is a narrow activated mana-source permanent with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('leafkin druid', 'Leafkin Druid', 'f4f34beee7cb633d257735bb4e516104', 'battle_rule_v1:50ff722ab7e4ef327443b24ad10cfd68', '{"ability_kind":"activated_mana","activation_requires_tap":true,"battle_model_scope":"xmage_controlled_creature_condition_conditional_mana_source_permanent_v1","conditional_mana_controlled_creature_count_gte":4,"conditional_mana_produced_when_condition_met":2,"effect":"ramp_permanent","is_mana_source":true,"mana_activation_requires_tap":true,"mana_produced":1,"permanent_type":"creature","produced_mana_symbols":["G","G"],"produces":"G","source_mana_cost":"{1}{G}","source_type_line":"Creature \u2014 Elemental Druid","xmage_ability_classes":["SimpleManaAbility"],"xmage_effect_classes":["BasicManaEffect","ConditionalManaEffect"],"xmage_mana_ability_classes":["SimpleManaAbility"]}'::jsonb, '{"category":"ramp","effect":"ramp_permanent"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class LeafkinDruid translated into ManaLoom runtime scope xmage_controlled_creature_condition_conditional_mana_source_permanent_v1. This row is package-ready only because the source signature is a narrow activated mana-source permanent with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('raucous audience', 'Raucous Audience', '280a0375aa62b8b4018d4ebb02f8439e', 'battle_rule_v1:26d851707d7fc9eb84ba09ee75d9937a', '{"ability_kind":"activated_mana","activation_requires_tap":true,"battle_model_scope":"xmage_controlled_creature_condition_conditional_mana_source_permanent_v1","conditional_mana_controlled_creature_power_gte":4,"conditional_mana_produced_when_condition_met":2,"effect":"ramp_permanent","is_mana_source":true,"mana_activation_requires_tap":true,"mana_produced":1,"permanent_type":"creature","produced_mana_symbols":["G","G"],"produces":"G","source_mana_cost":"{1}{G}","source_type_line":"Creature \u2014 Human Citizen","xmage_ability_classes":["SimpleManaAbility"],"xmage_effect_classes":["BasicManaEffect","ConditionalManaEffect"],"xmage_mana_ability_classes":["SimpleManaAbility"]}'::jsonb, '{"category":"ramp","effect":"ramp_permanent"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class RaucousAudience translated into ManaLoom runtime scope xmage_controlled_creature_condition_conditional_mana_source_permanent_v1. This row is package-ready only because the source signature is a narrow activated mana-source permanent with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
  (SELECT count(*) FROM manaloom_deploy_audit.pg737_controlled_creature_condition_mana_20260711_032028) AS backup_rows
FROM proposed p
LEFT JOIN rule_rows r
  ON r.normalized_name = p.normalized_name
 AND r.logical_rule_key = p.logical_rule_key
 AND r.oracle_hash = p.oracle_hash
GROUP BY p.card_name, p.normalized_name, p.logical_rule_key, p.oracle_hash
ORDER BY p.card_name;
