WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('accelerate', 'Accelerate', '0ef3b42b4549f96183cf071626ac47e5', 'battle_rule_v1:aa92338a2783b8ee4e9be40857bfea0e', '{"_composite_rule_components":[{"battle_model_scope":"xmage_fixed_boost_and_keyword_target_creature_until_eot_spell_v1","compose_on_resolution":true,"duration":"until_end_of_turn","effect":"stat_modifier_until_eot","granted_keywords_until_eot":["haste"],"power_boost":0,"power_delta":0,"target":"creature","target_constraints":{"card_types":["creature"]},"target_controller":"any","toughness_boost":0,"toughness_delta":0,"xmage_ability_class":"HasteAbility","xmage_effect_class":"GainAbilityTargetEffect"},{"battle_model_scope":"xmage_fixed_source_controller_draw_spell_v1","compose_on_resolution":true,"count":1,"effect":"draw_cards","xmage_effect_class":"DrawCardSourceControllerEffect"}],"battle_model_scope":"xmage_fixed_keyword_target_creature_until_eot_draw_card_spell_v1","count":1,"draw_count":1,"duration":"until_end_of_turn","effect":"composite_resolution","granted_keywords_until_eot":["haste"],"instant":true,"power_boost":0,"power_delta":0,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"]},"target_controller":"any","toughness_boost":0,"toughness_delta":0,"xmage_ability_class":"HasteAbility","xmage_effect_classes":["GainAbilityTargetEffect","DrawCardSourceControllerEffect"]}'::jsonb, '{"category":"draw","effect":"composite_resolution","target":"creature","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Accelerate translated into ManaLoom runtime scope xmage_fixed_keyword_target_creature_until_eot_draw_card_spell_v1. This row is package-ready only because the source signature is a narrow fixed target-creature keyword plus draw-card spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('bladebrand', 'Bladebrand', 'e367c4edeba5549a79de45ff03e70747', 'battle_rule_v1:bf20e953cf978d7e7822f44345c8f2a5', '{"_composite_rule_components":[{"battle_model_scope":"xmage_fixed_boost_and_keyword_target_creature_until_eot_spell_v1","compose_on_resolution":true,"duration":"until_end_of_turn","effect":"stat_modifier_until_eot","granted_keywords_until_eot":["deathtouch"],"power_boost":0,"power_delta":0,"target":"creature","target_constraints":{"card_types":["creature"]},"target_controller":"any","toughness_boost":0,"toughness_delta":0,"xmage_ability_class":"DeathtouchAbility","xmage_effect_class":"GainAbilityTargetEffect"},{"battle_model_scope":"xmage_fixed_source_controller_draw_spell_v1","compose_on_resolution":true,"count":1,"effect":"draw_cards","xmage_effect_class":"DrawCardSourceControllerEffect"}],"battle_model_scope":"xmage_fixed_keyword_target_creature_until_eot_draw_card_spell_v1","count":1,"draw_count":1,"duration":"until_end_of_turn","effect":"composite_resolution","granted_keywords_until_eot":["deathtouch"],"instant":true,"power_boost":0,"power_delta":0,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"]},"target_controller":"any","toughness_boost":0,"toughness_delta":0,"xmage_ability_class":"DeathtouchAbility","xmage_effect_classes":["GainAbilityTargetEffect","DrawCardSourceControllerEffect"]}'::jsonb, '{"category":"draw","effect":"composite_resolution","target":"creature","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Bladebrand translated into ManaLoom runtime scope xmage_fixed_keyword_target_creature_until_eot_draw_card_spell_v1. This row is package-ready only because the source signature is a narrow fixed target-creature keyword plus draw-card spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('cloak of feathers', 'Cloak of Feathers', '75595da321130e1de061cf53c9daba76', 'battle_rule_v1:88bfc41687baea7b9c58ea7edd4b8140', '{"_composite_rule_components":[{"battle_model_scope":"xmage_fixed_boost_and_keyword_target_creature_until_eot_spell_v1","compose_on_resolution":true,"duration":"until_end_of_turn","effect":"stat_modifier_until_eot","granted_keywords_until_eot":["flying"],"power_boost":0,"power_delta":0,"target":"creature","target_constraints":{"card_types":["creature"]},"target_controller":"any","toughness_boost":0,"toughness_delta":0,"xmage_ability_class":"FlyingAbility","xmage_effect_class":"GainAbilityTargetEffect"},{"battle_model_scope":"xmage_fixed_source_controller_draw_spell_v1","compose_on_resolution":true,"count":1,"effect":"draw_cards","xmage_effect_class":"DrawCardSourceControllerEffect"}],"battle_model_scope":"xmage_fixed_keyword_target_creature_until_eot_draw_card_spell_v1","count":1,"draw_count":1,"duration":"until_end_of_turn","effect":"composite_resolution","granted_keywords_until_eot":["flying"],"instant":false,"power_boost":0,"power_delta":0,"sorcery":true,"target":"creature","target_constraints":{"card_types":["creature"]},"target_controller":"any","toughness_boost":0,"toughness_delta":0,"xmage_ability_class":"FlyingAbility","xmage_effect_classes":["GainAbilityTargetEffect","DrawCardSourceControllerEffect"]}'::jsonb, '{"category":"draw","effect":"composite_resolution","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class CloakOfFeathers translated into ManaLoom runtime scope xmage_fixed_keyword_target_creature_until_eot_draw_card_spell_v1. This row is package-ready only because the source signature is a narrow fixed target-creature keyword plus draw-card spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('lace with moonglove', 'Lace with Moonglove', 'c932047f2530a47806464d955000e956', 'battle_rule_v1:bf20e953cf978d7e7822f44345c8f2a5', '{"_composite_rule_components":[{"battle_model_scope":"xmage_fixed_boost_and_keyword_target_creature_until_eot_spell_v1","compose_on_resolution":true,"duration":"until_end_of_turn","effect":"stat_modifier_until_eot","granted_keywords_until_eot":["deathtouch"],"power_boost":0,"power_delta":0,"target":"creature","target_constraints":{"card_types":["creature"]},"target_controller":"any","toughness_boost":0,"toughness_delta":0,"xmage_ability_class":"DeathtouchAbility","xmage_effect_class":"GainAbilityTargetEffect"},{"battle_model_scope":"xmage_fixed_source_controller_draw_spell_v1","compose_on_resolution":true,"count":1,"effect":"draw_cards","xmage_effect_class":"DrawCardSourceControllerEffect"}],"battle_model_scope":"xmage_fixed_keyword_target_creature_until_eot_draw_card_spell_v1","count":1,"draw_count":1,"duration":"until_end_of_turn","effect":"composite_resolution","granted_keywords_until_eot":["deathtouch"],"instant":true,"power_boost":0,"power_delta":0,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"]},"target_controller":"any","toughness_boost":0,"toughness_delta":0,"xmage_ability_class":"DeathtouchAbility","xmage_effect_classes":["GainAbilityTargetEffect","DrawCardSourceControllerEffect"]}'::jsonb, '{"category":"draw","effect":"composite_resolution","target":"creature","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class LaceWithMoonglove translated into ManaLoom runtime scope xmage_fixed_keyword_target_creature_until_eot_draw_card_spell_v1. This row is package-ready only because the source signature is a narrow fixed target-creature keyword plus draw-card spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('leap', 'Leap', '75595da321130e1de061cf53c9daba76', 'battle_rule_v1:9136574ebfdcfa63c54f60f028d73783', '{"_composite_rule_components":[{"battle_model_scope":"xmage_fixed_boost_and_keyword_target_creature_until_eot_spell_v1","compose_on_resolution":true,"duration":"until_end_of_turn","effect":"stat_modifier_until_eot","granted_keywords_until_eot":["flying"],"power_boost":0,"power_delta":0,"target":"creature","target_constraints":{"card_types":["creature"]},"target_controller":"any","toughness_boost":0,"toughness_delta":0,"xmage_ability_class":"FlyingAbility","xmage_effect_class":"GainAbilityTargetEffect"},{"battle_model_scope":"xmage_fixed_source_controller_draw_spell_v1","compose_on_resolution":true,"count":1,"effect":"draw_cards","xmage_effect_class":"DrawCardSourceControllerEffect"}],"battle_model_scope":"xmage_fixed_keyword_target_creature_until_eot_draw_card_spell_v1","count":1,"draw_count":1,"duration":"until_end_of_turn","effect":"composite_resolution","granted_keywords_until_eot":["flying"],"instant":true,"power_boost":0,"power_delta":0,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"]},"target_controller":"any","toughness_boost":0,"toughness_delta":0,"xmage_ability_class":"FlyingAbility","xmage_effect_classes":["GainAbilityTargetEffect","DrawCardSourceControllerEffect"]}'::jsonb, '{"category":"draw","effect":"composite_resolution","target":"creature","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Leap translated into ManaLoom runtime scope xmage_fixed_keyword_target_creature_until_eot_draw_card_spell_v1. This row is package-ready only because the source signature is a narrow fixed target-creature keyword plus draw-card spell with focused runtime coverage.', 'deprecate_nonmatching_rows')
),
matched_cards AS (
  SELECT
    p.normalized_name,
    p.card_name,
    p.oracle_hash,
    c.id AS card_id,
    c.name AS db_card_name
  FROM proposed p
  LEFT JOIN public.cards c
    ON (
         lower(c.name) = p.normalized_name
         OR split_part(lower(c.name), ' // ', 1) = p.normalized_name
       )
   AND md5(coalesce(c.oracle_text, '')) = p.oracle_hash
),
target_cards AS (
  SELECT
    normalized_name,
    card_name,
    oracle_hash,
    count(card_id) AS target_card_rows,
    min(card_id::text)::uuid AS canonical_card_id,
    min(db_card_name) AS canonical_card_name
  FROM matched_cards
  GROUP BY normalized_name, card_name, oracle_hash
),
rule_rows AS (
  SELECT p.normalized_name, count(r.*) AS existing_rule_rows
  FROM proposed p
  LEFT JOIN public.card_battle_rules r
    ON (
         r.normalized_name = p.normalized_name
         OR r.normalized_name LIKE p.normalized_name || ' // %'
       )
  GROUP BY p.normalized_name
),
expected_rows AS (
  SELECT p.normalized_name, count(r.*) AS expected_rule_rows_before
  FROM proposed p
  LEFT JOIN public.card_battle_rules r
    ON (
         r.normalized_name = p.normalized_name
         OR r.normalized_name LIKE p.normalized_name || ' // %'
       )
   AND r.logical_rule_key = p.logical_rule_key
  GROUP BY p.normalized_name
),
shadow_rows AS (
  SELECT p.normalized_name, count(r.*) AS would_deprecate_shadow_rows
  FROM proposed p
  LEFT JOIN public.card_battle_rules r
    ON (
         r.normalized_name = p.normalized_name
         OR r.normalized_name LIKE p.normalized_name || ' // %'
       )
   AND r.logical_rule_key <> p.logical_rule_key
   AND r.review_status NOT IN ('deprecated', 'rejected')
   AND r.execution_status <> 'disabled'
  GROUP BY p.normalized_name
)
SELECT
  p.card_name,
  p.normalized_name,
  p.oracle_hash,
  p.logical_rule_key,
  p.shadow_handling,
  tc.target_card_rows,
  tc.canonical_card_id,
  rr.existing_rule_rows,
  er.expected_rule_rows_before,
  sr.would_deprecate_shadow_rows
FROM proposed p
JOIN target_cards tc USING (normalized_name, card_name, oracle_hash)
JOIN rule_rows rr USING (normalized_name)
JOIN expected_rows er USING (normalized_name)
JOIN shadow_rows sr USING (normalized_name)
ORDER BY p.card_name;
