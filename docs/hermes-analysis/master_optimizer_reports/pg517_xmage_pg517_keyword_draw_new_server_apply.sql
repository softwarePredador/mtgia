BEGIN;

CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit;

CREATE TABLE IF NOT EXISTS manaloom_deploy_audit.xmage_pg517_keyword_draw_new_server_pg51_20260705_163407 AS
SELECT *
FROM public.card_battle_rules
WHERE normalized_name IN ('accelerate', 'bladebrand', 'cloak of feathers', 'lace with moonglove', 'leap')
   OR normalized_name LIKE 'accelerate // %'
   OR normalized_name LIKE 'bladebrand // %'
   OR normalized_name LIKE 'cloak of feathers // %'
   OR normalized_name LIKE 'lace with moonglove // %'
   OR normalized_name LIKE 'leap // %';

DO $$
DECLARE
  v_missing jsonb;
BEGIN
  WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('accelerate', 'Accelerate', '0ef3b42b4549f96183cf071626ac47e5', 'battle_rule_v1:aa92338a2783b8ee4e9be40857bfea0e', '{"_composite_rule_components":[{"battle_model_scope":"xmage_fixed_boost_and_keyword_target_creature_until_eot_spell_v1","compose_on_resolution":true,"duration":"until_end_of_turn","effect":"stat_modifier_until_eot","granted_keywords_until_eot":["haste"],"power_boost":0,"power_delta":0,"target":"creature","target_constraints":{"card_types":["creature"]},"target_controller":"any","toughness_boost":0,"toughness_delta":0,"xmage_ability_class":"HasteAbility","xmage_effect_class":"GainAbilityTargetEffect"},{"battle_model_scope":"xmage_fixed_source_controller_draw_spell_v1","compose_on_resolution":true,"count":1,"effect":"draw_cards","xmage_effect_class":"DrawCardSourceControllerEffect"}],"battle_model_scope":"xmage_fixed_keyword_target_creature_until_eot_draw_card_spell_v1","count":1,"draw_count":1,"duration":"until_end_of_turn","effect":"composite_resolution","granted_keywords_until_eot":["haste"],"instant":true,"power_boost":0,"power_delta":0,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"]},"target_controller":"any","toughness_boost":0,"toughness_delta":0,"xmage_ability_class":"HasteAbility","xmage_effect_classes":["GainAbilityTargetEffect","DrawCardSourceControllerEffect"]}'::jsonb, '{"category":"draw","effect":"composite_resolution","target":"creature","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Accelerate translated into ManaLoom runtime scope xmage_fixed_keyword_target_creature_until_eot_draw_card_spell_v1. This row is package-ready only because the source signature is a narrow fixed target-creature keyword plus draw-card spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('bladebrand', 'Bladebrand', 'e367c4edeba5549a79de45ff03e70747', 'battle_rule_v1:bf20e953cf978d7e7822f44345c8f2a5', '{"_composite_rule_components":[{"battle_model_scope":"xmage_fixed_boost_and_keyword_target_creature_until_eot_spell_v1","compose_on_resolution":true,"duration":"until_end_of_turn","effect":"stat_modifier_until_eot","granted_keywords_until_eot":["deathtouch"],"power_boost":0,"power_delta":0,"target":"creature","target_constraints":{"card_types":["creature"]},"target_controller":"any","toughness_boost":0,"toughness_delta":0,"xmage_ability_class":"DeathtouchAbility","xmage_effect_class":"GainAbilityTargetEffect"},{"battle_model_scope":"xmage_fixed_source_controller_draw_spell_v1","compose_on_resolution":true,"count":1,"effect":"draw_cards","xmage_effect_class":"DrawCardSourceControllerEffect"}],"battle_model_scope":"xmage_fixed_keyword_target_creature_until_eot_draw_card_spell_v1","count":1,"draw_count":1,"duration":"until_end_of_turn","effect":"composite_resolution","granted_keywords_until_eot":["deathtouch"],"instant":true,"power_boost":0,"power_delta":0,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"]},"target_controller":"any","toughness_boost":0,"toughness_delta":0,"xmage_ability_class":"DeathtouchAbility","xmage_effect_classes":["GainAbilityTargetEffect","DrawCardSourceControllerEffect"]}'::jsonb, '{"category":"draw","effect":"composite_resolution","target":"creature","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Bladebrand translated into ManaLoom runtime scope xmage_fixed_keyword_target_creature_until_eot_draw_card_spell_v1. This row is package-ready only because the source signature is a narrow fixed target-creature keyword plus draw-card spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('cloak of feathers', 'Cloak of Feathers', '75595da321130e1de061cf53c9daba76', 'battle_rule_v1:88bfc41687baea7b9c58ea7edd4b8140', '{"_composite_rule_components":[{"battle_model_scope":"xmage_fixed_boost_and_keyword_target_creature_until_eot_spell_v1","compose_on_resolution":true,"duration":"until_end_of_turn","effect":"stat_modifier_until_eot","granted_keywords_until_eot":["flying"],"power_boost":0,"power_delta":0,"target":"creature","target_constraints":{"card_types":["creature"]},"target_controller":"any","toughness_boost":0,"toughness_delta":0,"xmage_ability_class":"FlyingAbility","xmage_effect_class":"GainAbilityTargetEffect"},{"battle_model_scope":"xmage_fixed_source_controller_draw_spell_v1","compose_on_resolution":true,"count":1,"effect":"draw_cards","xmage_effect_class":"DrawCardSourceControllerEffect"}],"battle_model_scope":"xmage_fixed_keyword_target_creature_until_eot_draw_card_spell_v1","count":1,"draw_count":1,"duration":"until_end_of_turn","effect":"composite_resolution","granted_keywords_until_eot":["flying"],"instant":false,"power_boost":0,"power_delta":0,"sorcery":true,"target":"creature","target_constraints":{"card_types":["creature"]},"target_controller":"any","toughness_boost":0,"toughness_delta":0,"xmage_ability_class":"FlyingAbility","xmage_effect_classes":["GainAbilityTargetEffect","DrawCardSourceControllerEffect"]}'::jsonb, '{"category":"draw","effect":"composite_resolution","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class CloakOfFeathers translated into ManaLoom runtime scope xmage_fixed_keyword_target_creature_until_eot_draw_card_spell_v1. This row is package-ready only because the source signature is a narrow fixed target-creature keyword plus draw-card spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('lace with moonglove', 'Lace with Moonglove', 'c932047f2530a47806464d955000e956', 'battle_rule_v1:bf20e953cf978d7e7822f44345c8f2a5', '{"_composite_rule_components":[{"battle_model_scope":"xmage_fixed_boost_and_keyword_target_creature_until_eot_spell_v1","compose_on_resolution":true,"duration":"until_end_of_turn","effect":"stat_modifier_until_eot","granted_keywords_until_eot":["deathtouch"],"power_boost":0,"power_delta":0,"target":"creature","target_constraints":{"card_types":["creature"]},"target_controller":"any","toughness_boost":0,"toughness_delta":0,"xmage_ability_class":"DeathtouchAbility","xmage_effect_class":"GainAbilityTargetEffect"},{"battle_model_scope":"xmage_fixed_source_controller_draw_spell_v1","compose_on_resolution":true,"count":1,"effect":"draw_cards","xmage_effect_class":"DrawCardSourceControllerEffect"}],"battle_model_scope":"xmage_fixed_keyword_target_creature_until_eot_draw_card_spell_v1","count":1,"draw_count":1,"duration":"until_end_of_turn","effect":"composite_resolution","granted_keywords_until_eot":["deathtouch"],"instant":true,"power_boost":0,"power_delta":0,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"]},"target_controller":"any","toughness_boost":0,"toughness_delta":0,"xmage_ability_class":"DeathtouchAbility","xmage_effect_classes":["GainAbilityTargetEffect","DrawCardSourceControllerEffect"]}'::jsonb, '{"category":"draw","effect":"composite_resolution","target":"creature","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class LaceWithMoonglove translated into ManaLoom runtime scope xmage_fixed_keyword_target_creature_until_eot_draw_card_spell_v1. This row is package-ready only because the source signature is a narrow fixed target-creature keyword plus draw-card spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('leap', 'Leap', '75595da321130e1de061cf53c9daba76', 'battle_rule_v1:9136574ebfdcfa63c54f60f028d73783', '{"_composite_rule_components":[{"battle_model_scope":"xmage_fixed_boost_and_keyword_target_creature_until_eot_spell_v1","compose_on_resolution":true,"duration":"until_end_of_turn","effect":"stat_modifier_until_eot","granted_keywords_until_eot":["flying"],"power_boost":0,"power_delta":0,"target":"creature","target_constraints":{"card_types":["creature"]},"target_controller":"any","toughness_boost":0,"toughness_delta":0,"xmage_ability_class":"FlyingAbility","xmage_effect_class":"GainAbilityTargetEffect"},{"battle_model_scope":"xmage_fixed_source_controller_draw_spell_v1","compose_on_resolution":true,"count":1,"effect":"draw_cards","xmage_effect_class":"DrawCardSourceControllerEffect"}],"battle_model_scope":"xmage_fixed_keyword_target_creature_until_eot_draw_card_spell_v1","count":1,"draw_count":1,"duration":"until_end_of_turn","effect":"composite_resolution","granted_keywords_until_eot":["flying"],"instant":true,"power_boost":0,"power_delta":0,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"]},"target_controller":"any","toughness_boost":0,"toughness_delta":0,"xmage_ability_class":"FlyingAbility","xmage_effect_classes":["GainAbilityTargetEffect","DrawCardSourceControllerEffect"]}'::jsonb, '{"category":"draw","effect":"composite_resolution","target":"creature","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Leap translated into ManaLoom runtime scope xmage_fixed_keyword_target_creature_until_eot_draw_card_spell_v1. This row is package-ready only because the source signature is a narrow fixed target-creature keyword plus draw-card spell with focused runtime coverage.', 'deprecate_nonmatching_rows')
),
  counts AS (
    SELECT
      p.card_name,
      p.normalized_name,
      p.oracle_hash,
      count(c.id) AS target_card_rows,
      min(c.id::text)::uuid AS canonical_card_id
    FROM proposed p
    LEFT JOIN public.cards c
      ON (
           lower(c.name) = p.normalized_name
           OR split_part(lower(c.name), ' // ', 1) = p.normalized_name
         )
     AND md5(coalesce(c.oracle_text, '')) = p.oracle_hash
    GROUP BY p.card_name, p.normalized_name, p.oracle_hash
  )
  SELECT jsonb_agg(counts ORDER BY card_name)
    INTO v_missing
  FROM counts
  WHERE target_card_rows < 1;

  IF v_missing IS NOT NULL THEN
    RAISE EXCEPTION 'XMage batch package abort: expected at least one Oracle-hash-matched card row for every proposed card: %', v_missing;
  END IF;
END $$;

WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('accelerate', 'Accelerate', '0ef3b42b4549f96183cf071626ac47e5', 'battle_rule_v1:aa92338a2783b8ee4e9be40857bfea0e', '{"_composite_rule_components":[{"battle_model_scope":"xmage_fixed_boost_and_keyword_target_creature_until_eot_spell_v1","compose_on_resolution":true,"duration":"until_end_of_turn","effect":"stat_modifier_until_eot","granted_keywords_until_eot":["haste"],"power_boost":0,"power_delta":0,"target":"creature","target_constraints":{"card_types":["creature"]},"target_controller":"any","toughness_boost":0,"toughness_delta":0,"xmage_ability_class":"HasteAbility","xmage_effect_class":"GainAbilityTargetEffect"},{"battle_model_scope":"xmage_fixed_source_controller_draw_spell_v1","compose_on_resolution":true,"count":1,"effect":"draw_cards","xmage_effect_class":"DrawCardSourceControllerEffect"}],"battle_model_scope":"xmage_fixed_keyword_target_creature_until_eot_draw_card_spell_v1","count":1,"draw_count":1,"duration":"until_end_of_turn","effect":"composite_resolution","granted_keywords_until_eot":["haste"],"instant":true,"power_boost":0,"power_delta":0,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"]},"target_controller":"any","toughness_boost":0,"toughness_delta":0,"xmage_ability_class":"HasteAbility","xmage_effect_classes":["GainAbilityTargetEffect","DrawCardSourceControllerEffect"]}'::jsonb, '{"category":"draw","effect":"composite_resolution","target":"creature","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Accelerate translated into ManaLoom runtime scope xmage_fixed_keyword_target_creature_until_eot_draw_card_spell_v1. This row is package-ready only because the source signature is a narrow fixed target-creature keyword plus draw-card spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('bladebrand', 'Bladebrand', 'e367c4edeba5549a79de45ff03e70747', 'battle_rule_v1:bf20e953cf978d7e7822f44345c8f2a5', '{"_composite_rule_components":[{"battle_model_scope":"xmage_fixed_boost_and_keyword_target_creature_until_eot_spell_v1","compose_on_resolution":true,"duration":"until_end_of_turn","effect":"stat_modifier_until_eot","granted_keywords_until_eot":["deathtouch"],"power_boost":0,"power_delta":0,"target":"creature","target_constraints":{"card_types":["creature"]},"target_controller":"any","toughness_boost":0,"toughness_delta":0,"xmage_ability_class":"DeathtouchAbility","xmage_effect_class":"GainAbilityTargetEffect"},{"battle_model_scope":"xmage_fixed_source_controller_draw_spell_v1","compose_on_resolution":true,"count":1,"effect":"draw_cards","xmage_effect_class":"DrawCardSourceControllerEffect"}],"battle_model_scope":"xmage_fixed_keyword_target_creature_until_eot_draw_card_spell_v1","count":1,"draw_count":1,"duration":"until_end_of_turn","effect":"composite_resolution","granted_keywords_until_eot":["deathtouch"],"instant":true,"power_boost":0,"power_delta":0,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"]},"target_controller":"any","toughness_boost":0,"toughness_delta":0,"xmage_ability_class":"DeathtouchAbility","xmage_effect_classes":["GainAbilityTargetEffect","DrawCardSourceControllerEffect"]}'::jsonb, '{"category":"draw","effect":"composite_resolution","target":"creature","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Bladebrand translated into ManaLoom runtime scope xmage_fixed_keyword_target_creature_until_eot_draw_card_spell_v1. This row is package-ready only because the source signature is a narrow fixed target-creature keyword plus draw-card spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('cloak of feathers', 'Cloak of Feathers', '75595da321130e1de061cf53c9daba76', 'battle_rule_v1:88bfc41687baea7b9c58ea7edd4b8140', '{"_composite_rule_components":[{"battle_model_scope":"xmage_fixed_boost_and_keyword_target_creature_until_eot_spell_v1","compose_on_resolution":true,"duration":"until_end_of_turn","effect":"stat_modifier_until_eot","granted_keywords_until_eot":["flying"],"power_boost":0,"power_delta":0,"target":"creature","target_constraints":{"card_types":["creature"]},"target_controller":"any","toughness_boost":0,"toughness_delta":0,"xmage_ability_class":"FlyingAbility","xmage_effect_class":"GainAbilityTargetEffect"},{"battle_model_scope":"xmage_fixed_source_controller_draw_spell_v1","compose_on_resolution":true,"count":1,"effect":"draw_cards","xmage_effect_class":"DrawCardSourceControllerEffect"}],"battle_model_scope":"xmage_fixed_keyword_target_creature_until_eot_draw_card_spell_v1","count":1,"draw_count":1,"duration":"until_end_of_turn","effect":"composite_resolution","granted_keywords_until_eot":["flying"],"instant":false,"power_boost":0,"power_delta":0,"sorcery":true,"target":"creature","target_constraints":{"card_types":["creature"]},"target_controller":"any","toughness_boost":0,"toughness_delta":0,"xmage_ability_class":"FlyingAbility","xmage_effect_classes":["GainAbilityTargetEffect","DrawCardSourceControllerEffect"]}'::jsonb, '{"category":"draw","effect":"composite_resolution","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class CloakOfFeathers translated into ManaLoom runtime scope xmage_fixed_keyword_target_creature_until_eot_draw_card_spell_v1. This row is package-ready only because the source signature is a narrow fixed target-creature keyword plus draw-card spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('lace with moonglove', 'Lace with Moonglove', 'c932047f2530a47806464d955000e956', 'battle_rule_v1:bf20e953cf978d7e7822f44345c8f2a5', '{"_composite_rule_components":[{"battle_model_scope":"xmage_fixed_boost_and_keyword_target_creature_until_eot_spell_v1","compose_on_resolution":true,"duration":"until_end_of_turn","effect":"stat_modifier_until_eot","granted_keywords_until_eot":["deathtouch"],"power_boost":0,"power_delta":0,"target":"creature","target_constraints":{"card_types":["creature"]},"target_controller":"any","toughness_boost":0,"toughness_delta":0,"xmage_ability_class":"DeathtouchAbility","xmage_effect_class":"GainAbilityTargetEffect"},{"battle_model_scope":"xmage_fixed_source_controller_draw_spell_v1","compose_on_resolution":true,"count":1,"effect":"draw_cards","xmage_effect_class":"DrawCardSourceControllerEffect"}],"battle_model_scope":"xmage_fixed_keyword_target_creature_until_eot_draw_card_spell_v1","count":1,"draw_count":1,"duration":"until_end_of_turn","effect":"composite_resolution","granted_keywords_until_eot":["deathtouch"],"instant":true,"power_boost":0,"power_delta":0,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"]},"target_controller":"any","toughness_boost":0,"toughness_delta":0,"xmage_ability_class":"DeathtouchAbility","xmage_effect_classes":["GainAbilityTargetEffect","DrawCardSourceControllerEffect"]}'::jsonb, '{"category":"draw","effect":"composite_resolution","target":"creature","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class LaceWithMoonglove translated into ManaLoom runtime scope xmage_fixed_keyword_target_creature_until_eot_draw_card_spell_v1. This row is package-ready only because the source signature is a narrow fixed target-creature keyword plus draw-card spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('leap', 'Leap', '75595da321130e1de061cf53c9daba76', 'battle_rule_v1:9136574ebfdcfa63c54f60f028d73783', '{"_composite_rule_components":[{"battle_model_scope":"xmage_fixed_boost_and_keyword_target_creature_until_eot_spell_v1","compose_on_resolution":true,"duration":"until_end_of_turn","effect":"stat_modifier_until_eot","granted_keywords_until_eot":["flying"],"power_boost":0,"power_delta":0,"target":"creature","target_constraints":{"card_types":["creature"]},"target_controller":"any","toughness_boost":0,"toughness_delta":0,"xmage_ability_class":"FlyingAbility","xmage_effect_class":"GainAbilityTargetEffect"},{"battle_model_scope":"xmage_fixed_source_controller_draw_spell_v1","compose_on_resolution":true,"count":1,"effect":"draw_cards","xmage_effect_class":"DrawCardSourceControllerEffect"}],"battle_model_scope":"xmage_fixed_keyword_target_creature_until_eot_draw_card_spell_v1","count":1,"draw_count":1,"duration":"until_end_of_turn","effect":"composite_resolution","granted_keywords_until_eot":["flying"],"instant":true,"power_boost":0,"power_delta":0,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"]},"target_controller":"any","toughness_boost":0,"toughness_delta":0,"xmage_ability_class":"FlyingAbility","xmage_effect_classes":["GainAbilityTargetEffect","DrawCardSourceControllerEffect"]}'::jsonb, '{"category":"draw","effect":"composite_resolution","target":"creature","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Leap translated into ManaLoom runtime scope xmage_fixed_keyword_target_creature_until_eot_draw_card_spell_v1. This row is package-ready only because the source signature is a narrow fixed target-creature keyword plus draw-card spell with focused runtime coverage.', 'deprecate_nonmatching_rows')
),
deprecated AS (
  UPDATE public.card_battle_rules r
  SET
    review_status = 'deprecated',
    execution_status = 'disabled',
    updated_at = now(),
    notes = concat_ws(E'\n', nullif(r.notes, ''), 'XMage batch package: deprecated stale shadow before curated batch rule upsert.')
  FROM proposed p
  WHERE (
        r.normalized_name = p.normalized_name
        OR r.normalized_name LIKE p.normalized_name || ' // %'
      )
    AND p.shadow_handling <> 'preserve_existing_rows'
    AND r.logical_rule_key <> p.logical_rule_key
  RETURNING r.*
)
SELECT count(*) AS deprecated_shadow_rows FROM deprecated;

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
  JOIN public.cards c
    ON (
         lower(c.name) = p.normalized_name
         OR split_part(lower(c.name), ' // ', 1) = p.normalized_name
       )
   AND md5(coalesce(c.oracle_text, '')) = p.oracle_hash
),
canonical_target_cards AS (
  SELECT
    p.*,
    min(m.card_id::text)::uuid AS card_id,
    min(m.db_card_name) AS db_card_name
  FROM proposed p
  JOIN matched_cards m
    USING (normalized_name, card_name, oracle_hash)
  GROUP BY
    p.normalized_name,
    p.card_name,
    p.oracle_hash,
    p.logical_rule_key,
    p.effect_json,
    p.deck_role_json,
    p.source,
    p.confidence,
    p.review_status,
    p.execution_status,
    p.notes,
    p.shadow_handling
),
upserted AS (
  INSERT INTO public.card_battle_rules (
    normalized_name,
    card_id,
    card_name,
    effect_json,
    deck_role_json,
    source,
    confidence,
    review_status,
    rule_version,
    oracle_hash,
    notes,
    reviewed_by,
    reviewed_at,
    created_at,
    updated_at,
    last_seen_at,
    logical_rule_key,
    execution_status
  )
  SELECT
    normalized_name,
    card_id,
    db_card_name,
    effect_json,
    deck_role_json,
    source,
    confidence,
    review_status,
    2,
    oracle_hash,
    notes,
    'codex-xmage-batch',
    now(),
    now(),
    now(),
    now(),
    logical_rule_key,
    execution_status
  FROM canonical_target_cards
  ON CONFLICT (normalized_name, logical_rule_key) DO UPDATE
  SET
    card_id = EXCLUDED.card_id,
    card_name = EXCLUDED.card_name,
    effect_json = EXCLUDED.effect_json,
    deck_role_json = EXCLUDED.deck_role_json,
    source = EXCLUDED.source,
    confidence = EXCLUDED.confidence,
    review_status = EXCLUDED.review_status,
    rule_version = EXCLUDED.rule_version,
    oracle_hash = EXCLUDED.oracle_hash,
    notes = EXCLUDED.notes,
    reviewed_by = EXCLUDED.reviewed_by,
    reviewed_at = EXCLUDED.reviewed_at,
    updated_at = EXCLUDED.updated_at,
    last_seen_at = EXCLUDED.last_seen_at,
    execution_status = EXCLUDED.execution_status
  RETURNING *
)
SELECT count(*) AS upserted_rows FROM upserted;

COMMIT;
