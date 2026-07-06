BEGIN;

CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit;

CREATE TABLE IF NOT EXISTS manaloom_deploy_audit.pg560_target_keyword_spell_new_server_pg_20260706_102811 AS
SELECT *
FROM public.card_battle_rules
WHERE normalized_name IN ('alesha''s legacy', 'assault strobe', 'battle-rage blessing', 'double cleave', 'horrid vigor', 'jump', 'offer immortality', 'serpent''s gift', 'ticked off', 'unnatural speed')
   OR normalized_name LIKE 'alesha''s legacy // %'
   OR normalized_name LIKE 'assault strobe // %'
   OR normalized_name LIKE 'battle-rage blessing // %'
   OR normalized_name LIKE 'double cleave // %'
   OR normalized_name LIKE 'horrid vigor // %'
   OR normalized_name LIKE 'jump // %'
   OR normalized_name LIKE 'offer immortality // %'
   OR normalized_name LIKE 'serpent''s gift // %'
   OR normalized_name LIKE 'ticked off // %'
   OR normalized_name LIKE 'unnatural speed // %';

DO $$
DECLARE
  v_missing jsonb;
BEGIN
  WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('alesha''s legacy', 'Alesha''s Legacy', '44ab417eb2baba0b3f2656837a23f3fe', 'battle_rule_v1:86ddbb4414847a4263d461473c72a882', '{"battle_model_scope":"xmage_fixed_keyword_target_creature_until_eot_spell_v1","duration":"until_end_of_turn","effect":"stat_modifier_until_eot","granted_keywords_until_eot":["deathtouch","indestructible"],"instant":true,"power_boost":0,"power_delta":0,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"]},"target_controller":"self","toughness_boost":0,"toughness_delta":0,"xmage_ability_classes":["DeathtouchAbility","IndestructibleAbility"],"xmage_effect_class":"GainAbilityTargetEffect"}'::jsonb, '{"category":"support","effect":"stat_modifier_until_eot","subtype":"temporary_pump","target":"creature","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class AleshasLegacy translated into ManaLoom runtime scope xmage_fixed_keyword_target_creature_until_eot_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('assault strobe', 'Assault Strobe', '3becb38db1b3dcd8a0306eddd402ed13', 'battle_rule_v1:19a7bc7320a3d5f9fe2138f567b9f336', '{"battle_model_scope":"xmage_fixed_keyword_target_creature_until_eot_spell_v1","duration":"until_end_of_turn","effect":"stat_modifier_until_eot","granted_keywords_until_eot":["double_strike"],"instant":false,"power_boost":0,"power_delta":0,"sorcery":true,"target":"creature","target_constraints":{"card_types":["creature"]},"target_controller":"any","toughness_boost":0,"toughness_delta":0,"xmage_ability_classes":["DoubleStrikeAbility"],"xmage_effect_class":"GainAbilityTargetEffect"}'::jsonb, '{"category":"support","effect":"stat_modifier_until_eot","subtype":"temporary_pump","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class AssaultStrobe translated into ManaLoom runtime scope xmage_fixed_keyword_target_creature_until_eot_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('battle-rage blessing', 'Battle-Rage Blessing', '5738b136f3a8c1bc122429dee47d55c3', 'battle_rule_v1:eba43c09036c5996f18ebb89e91080bb', '{"battle_model_scope":"xmage_fixed_keyword_target_creature_until_eot_spell_v1","duration":"until_end_of_turn","effect":"stat_modifier_until_eot","granted_keywords_until_eot":["deathtouch","indestructible"],"instant":true,"power_boost":0,"power_delta":0,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"]},"target_controller":"any","toughness_boost":0,"toughness_delta":0,"xmage_ability_classes":["DeathtouchAbility","IndestructibleAbility"],"xmage_effect_class":"GainAbilityTargetEffect"}'::jsonb, '{"category":"support","effect":"stat_modifier_until_eot","subtype":"temporary_pump","target":"creature","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class BattleRageBlessing translated into ManaLoom runtime scope xmage_fixed_keyword_target_creature_until_eot_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('double cleave', 'Double Cleave', '3becb38db1b3dcd8a0306eddd402ed13', 'battle_rule_v1:8bf9be1f48750780ffd5a7059ae47e75', '{"battle_model_scope":"xmage_fixed_keyword_target_creature_until_eot_spell_v1","duration":"until_end_of_turn","effect":"stat_modifier_until_eot","granted_keywords_until_eot":["double_strike"],"instant":true,"power_boost":0,"power_delta":0,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"]},"target_controller":"any","toughness_boost":0,"toughness_delta":0,"xmage_ability_classes":["DoubleStrikeAbility"],"xmage_effect_class":"GainAbilityTargetEffect"}'::jsonb, '{"category":"support","effect":"stat_modifier_until_eot","subtype":"temporary_pump","target":"creature","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class DoubleCleave translated into ManaLoom runtime scope xmage_fixed_keyword_target_creature_until_eot_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('horrid vigor', 'Horrid Vigor', '16f72812647b7b6ebd06602a3e8415fe', 'battle_rule_v1:eba43c09036c5996f18ebb89e91080bb', '{"battle_model_scope":"xmage_fixed_keyword_target_creature_until_eot_spell_v1","duration":"until_end_of_turn","effect":"stat_modifier_until_eot","granted_keywords_until_eot":["deathtouch","indestructible"],"instant":true,"power_boost":0,"power_delta":0,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"]},"target_controller":"any","toughness_boost":0,"toughness_delta":0,"xmage_ability_classes":["DeathtouchAbility","IndestructibleAbility"],"xmage_effect_class":"GainAbilityTargetEffect"}'::jsonb, '{"category":"support","effect":"stat_modifier_until_eot","subtype":"temporary_pump","target":"creature","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class HorridVigor translated into ManaLoom runtime scope xmage_fixed_keyword_target_creature_until_eot_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('jump', 'Jump', 'ae63312ccd991825d03f1229015c8d36', 'battle_rule_v1:8edc824d3b408970c2be21310425c6c8', '{"battle_model_scope":"xmage_fixed_keyword_target_creature_until_eot_spell_v1","duration":"until_end_of_turn","effect":"stat_modifier_until_eot","granted_keywords_until_eot":["flying"],"instant":true,"power_boost":0,"power_delta":0,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"]},"target_controller":"any","toughness_boost":0,"toughness_delta":0,"xmage_ability_classes":["FlyingAbility"],"xmage_effect_class":"GainAbilityTargetEffect"}'::jsonb, '{"category":"support","effect":"stat_modifier_until_eot","subtype":"temporary_pump","target":"creature","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Jump translated into ManaLoom runtime scope xmage_fixed_keyword_target_creature_until_eot_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('offer immortality', 'Offer Immortality', '5738b136f3a8c1bc122429dee47d55c3', 'battle_rule_v1:eba43c09036c5996f18ebb89e91080bb', '{"battle_model_scope":"xmage_fixed_keyword_target_creature_until_eot_spell_v1","duration":"until_end_of_turn","effect":"stat_modifier_until_eot","granted_keywords_until_eot":["deathtouch","indestructible"],"instant":true,"power_boost":0,"power_delta":0,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"]},"target_controller":"any","toughness_boost":0,"toughness_delta":0,"xmage_ability_classes":["DeathtouchAbility","IndestructibleAbility"],"xmage_effect_class":"GainAbilityTargetEffect"}'::jsonb, '{"category":"support","effect":"stat_modifier_until_eot","subtype":"temporary_pump","target":"creature","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class OfferImmortality translated into ManaLoom runtime scope xmage_fixed_keyword_target_creature_until_eot_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('serpent''s gift', 'Serpent''s Gift', '01593088748dd471d3846b334c388118', 'battle_rule_v1:d8dcdb430502bd2b37d661018bd32aa9', '{"battle_model_scope":"xmage_fixed_keyword_target_creature_until_eot_spell_v1","duration":"until_end_of_turn","effect":"stat_modifier_until_eot","granted_keywords_until_eot":["deathtouch"],"instant":true,"power_boost":0,"power_delta":0,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"]},"target_controller":"any","toughness_boost":0,"toughness_delta":0,"xmage_ability_classes":["DeathtouchAbility"],"xmage_effect_class":"GainAbilityTargetEffect"}'::jsonb, '{"category":"support","effect":"stat_modifier_until_eot","subtype":"temporary_pump","target":"creature","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class SerpentsGift translated into ManaLoom runtime scope xmage_fixed_keyword_target_creature_until_eot_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('ticked off', 'Ticked Off', '3becb38db1b3dcd8a0306eddd402ed13', 'battle_rule_v1:19a7bc7320a3d5f9fe2138f567b9f336', '{"battle_model_scope":"xmage_fixed_keyword_target_creature_until_eot_spell_v1","duration":"until_end_of_turn","effect":"stat_modifier_until_eot","granted_keywords_until_eot":["double_strike"],"instant":false,"power_boost":0,"power_delta":0,"sorcery":true,"target":"creature","target_constraints":{"card_types":["creature"]},"target_controller":"any","toughness_boost":0,"toughness_delta":0,"xmage_ability_classes":["DoubleStrikeAbility"],"xmage_effect_class":"GainAbilityTargetEffect"}'::jsonb, '{"category":"support","effect":"stat_modifier_until_eot","subtype":"temporary_pump","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class TickedOff translated into ManaLoom runtime scope xmage_fixed_keyword_target_creature_until_eot_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('unnatural speed', 'Unnatural Speed', '763d6a49451a4cdbf02081795e2be17a', 'battle_rule_v1:ddd9fa2026191b67377e3d53084771fc', '{"battle_model_scope":"xmage_fixed_keyword_target_creature_until_eot_spell_v1","duration":"until_end_of_turn","effect":"stat_modifier_until_eot","granted_keywords_until_eot":["haste"],"instant":true,"power_boost":0,"power_delta":0,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"]},"target_controller":"any","toughness_boost":0,"toughness_delta":0,"xmage_ability_classes":["HasteAbility"],"xmage_effect_class":"GainAbilityTargetEffect"}'::jsonb, '{"category":"support","effect":"stat_modifier_until_eot","subtype":"temporary_pump","target":"creature","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class UnnaturalSpeed translated into ManaLoom runtime scope xmage_fixed_keyword_target_creature_until_eot_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
    ('alesha''s legacy', 'Alesha''s Legacy', '44ab417eb2baba0b3f2656837a23f3fe', 'battle_rule_v1:86ddbb4414847a4263d461473c72a882', '{"battle_model_scope":"xmage_fixed_keyword_target_creature_until_eot_spell_v1","duration":"until_end_of_turn","effect":"stat_modifier_until_eot","granted_keywords_until_eot":["deathtouch","indestructible"],"instant":true,"power_boost":0,"power_delta":0,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"]},"target_controller":"self","toughness_boost":0,"toughness_delta":0,"xmage_ability_classes":["DeathtouchAbility","IndestructibleAbility"],"xmage_effect_class":"GainAbilityTargetEffect"}'::jsonb, '{"category":"support","effect":"stat_modifier_until_eot","subtype":"temporary_pump","target":"creature","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class AleshasLegacy translated into ManaLoom runtime scope xmage_fixed_keyword_target_creature_until_eot_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('assault strobe', 'Assault Strobe', '3becb38db1b3dcd8a0306eddd402ed13', 'battle_rule_v1:19a7bc7320a3d5f9fe2138f567b9f336', '{"battle_model_scope":"xmage_fixed_keyword_target_creature_until_eot_spell_v1","duration":"until_end_of_turn","effect":"stat_modifier_until_eot","granted_keywords_until_eot":["double_strike"],"instant":false,"power_boost":0,"power_delta":0,"sorcery":true,"target":"creature","target_constraints":{"card_types":["creature"]},"target_controller":"any","toughness_boost":0,"toughness_delta":0,"xmage_ability_classes":["DoubleStrikeAbility"],"xmage_effect_class":"GainAbilityTargetEffect"}'::jsonb, '{"category":"support","effect":"stat_modifier_until_eot","subtype":"temporary_pump","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class AssaultStrobe translated into ManaLoom runtime scope xmage_fixed_keyword_target_creature_until_eot_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('battle-rage blessing', 'Battle-Rage Blessing', '5738b136f3a8c1bc122429dee47d55c3', 'battle_rule_v1:eba43c09036c5996f18ebb89e91080bb', '{"battle_model_scope":"xmage_fixed_keyword_target_creature_until_eot_spell_v1","duration":"until_end_of_turn","effect":"stat_modifier_until_eot","granted_keywords_until_eot":["deathtouch","indestructible"],"instant":true,"power_boost":0,"power_delta":0,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"]},"target_controller":"any","toughness_boost":0,"toughness_delta":0,"xmage_ability_classes":["DeathtouchAbility","IndestructibleAbility"],"xmage_effect_class":"GainAbilityTargetEffect"}'::jsonb, '{"category":"support","effect":"stat_modifier_until_eot","subtype":"temporary_pump","target":"creature","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class BattleRageBlessing translated into ManaLoom runtime scope xmage_fixed_keyword_target_creature_until_eot_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('double cleave', 'Double Cleave', '3becb38db1b3dcd8a0306eddd402ed13', 'battle_rule_v1:8bf9be1f48750780ffd5a7059ae47e75', '{"battle_model_scope":"xmage_fixed_keyword_target_creature_until_eot_spell_v1","duration":"until_end_of_turn","effect":"stat_modifier_until_eot","granted_keywords_until_eot":["double_strike"],"instant":true,"power_boost":0,"power_delta":0,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"]},"target_controller":"any","toughness_boost":0,"toughness_delta":0,"xmage_ability_classes":["DoubleStrikeAbility"],"xmage_effect_class":"GainAbilityTargetEffect"}'::jsonb, '{"category":"support","effect":"stat_modifier_until_eot","subtype":"temporary_pump","target":"creature","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class DoubleCleave translated into ManaLoom runtime scope xmage_fixed_keyword_target_creature_until_eot_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('horrid vigor', 'Horrid Vigor', '16f72812647b7b6ebd06602a3e8415fe', 'battle_rule_v1:eba43c09036c5996f18ebb89e91080bb', '{"battle_model_scope":"xmage_fixed_keyword_target_creature_until_eot_spell_v1","duration":"until_end_of_turn","effect":"stat_modifier_until_eot","granted_keywords_until_eot":["deathtouch","indestructible"],"instant":true,"power_boost":0,"power_delta":0,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"]},"target_controller":"any","toughness_boost":0,"toughness_delta":0,"xmage_ability_classes":["DeathtouchAbility","IndestructibleAbility"],"xmage_effect_class":"GainAbilityTargetEffect"}'::jsonb, '{"category":"support","effect":"stat_modifier_until_eot","subtype":"temporary_pump","target":"creature","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class HorridVigor translated into ManaLoom runtime scope xmage_fixed_keyword_target_creature_until_eot_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('jump', 'Jump', 'ae63312ccd991825d03f1229015c8d36', 'battle_rule_v1:8edc824d3b408970c2be21310425c6c8', '{"battle_model_scope":"xmage_fixed_keyword_target_creature_until_eot_spell_v1","duration":"until_end_of_turn","effect":"stat_modifier_until_eot","granted_keywords_until_eot":["flying"],"instant":true,"power_boost":0,"power_delta":0,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"]},"target_controller":"any","toughness_boost":0,"toughness_delta":0,"xmage_ability_classes":["FlyingAbility"],"xmage_effect_class":"GainAbilityTargetEffect"}'::jsonb, '{"category":"support","effect":"stat_modifier_until_eot","subtype":"temporary_pump","target":"creature","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Jump translated into ManaLoom runtime scope xmage_fixed_keyword_target_creature_until_eot_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('offer immortality', 'Offer Immortality', '5738b136f3a8c1bc122429dee47d55c3', 'battle_rule_v1:eba43c09036c5996f18ebb89e91080bb', '{"battle_model_scope":"xmage_fixed_keyword_target_creature_until_eot_spell_v1","duration":"until_end_of_turn","effect":"stat_modifier_until_eot","granted_keywords_until_eot":["deathtouch","indestructible"],"instant":true,"power_boost":0,"power_delta":0,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"]},"target_controller":"any","toughness_boost":0,"toughness_delta":0,"xmage_ability_classes":["DeathtouchAbility","IndestructibleAbility"],"xmage_effect_class":"GainAbilityTargetEffect"}'::jsonb, '{"category":"support","effect":"stat_modifier_until_eot","subtype":"temporary_pump","target":"creature","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class OfferImmortality translated into ManaLoom runtime scope xmage_fixed_keyword_target_creature_until_eot_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('serpent''s gift', 'Serpent''s Gift', '01593088748dd471d3846b334c388118', 'battle_rule_v1:d8dcdb430502bd2b37d661018bd32aa9', '{"battle_model_scope":"xmage_fixed_keyword_target_creature_until_eot_spell_v1","duration":"until_end_of_turn","effect":"stat_modifier_until_eot","granted_keywords_until_eot":["deathtouch"],"instant":true,"power_boost":0,"power_delta":0,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"]},"target_controller":"any","toughness_boost":0,"toughness_delta":0,"xmage_ability_classes":["DeathtouchAbility"],"xmage_effect_class":"GainAbilityTargetEffect"}'::jsonb, '{"category":"support","effect":"stat_modifier_until_eot","subtype":"temporary_pump","target":"creature","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class SerpentsGift translated into ManaLoom runtime scope xmage_fixed_keyword_target_creature_until_eot_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('ticked off', 'Ticked Off', '3becb38db1b3dcd8a0306eddd402ed13', 'battle_rule_v1:19a7bc7320a3d5f9fe2138f567b9f336', '{"battle_model_scope":"xmage_fixed_keyword_target_creature_until_eot_spell_v1","duration":"until_end_of_turn","effect":"stat_modifier_until_eot","granted_keywords_until_eot":["double_strike"],"instant":false,"power_boost":0,"power_delta":0,"sorcery":true,"target":"creature","target_constraints":{"card_types":["creature"]},"target_controller":"any","toughness_boost":0,"toughness_delta":0,"xmage_ability_classes":["DoubleStrikeAbility"],"xmage_effect_class":"GainAbilityTargetEffect"}'::jsonb, '{"category":"support","effect":"stat_modifier_until_eot","subtype":"temporary_pump","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class TickedOff translated into ManaLoom runtime scope xmage_fixed_keyword_target_creature_until_eot_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('unnatural speed', 'Unnatural Speed', '763d6a49451a4cdbf02081795e2be17a', 'battle_rule_v1:ddd9fa2026191b67377e3d53084771fc', '{"battle_model_scope":"xmage_fixed_keyword_target_creature_until_eot_spell_v1","duration":"until_end_of_turn","effect":"stat_modifier_until_eot","granted_keywords_until_eot":["haste"],"instant":true,"power_boost":0,"power_delta":0,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"]},"target_controller":"any","toughness_boost":0,"toughness_delta":0,"xmage_ability_classes":["HasteAbility"],"xmage_effect_class":"GainAbilityTargetEffect"}'::jsonb, '{"category":"support","effect":"stat_modifier_until_eot","subtype":"temporary_pump","target":"creature","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class UnnaturalSpeed translated into ManaLoom runtime scope xmage_fixed_keyword_target_creature_until_eot_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
    ('alesha''s legacy', 'Alesha''s Legacy', '44ab417eb2baba0b3f2656837a23f3fe', 'battle_rule_v1:86ddbb4414847a4263d461473c72a882', '{"battle_model_scope":"xmage_fixed_keyword_target_creature_until_eot_spell_v1","duration":"until_end_of_turn","effect":"stat_modifier_until_eot","granted_keywords_until_eot":["deathtouch","indestructible"],"instant":true,"power_boost":0,"power_delta":0,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"]},"target_controller":"self","toughness_boost":0,"toughness_delta":0,"xmage_ability_classes":["DeathtouchAbility","IndestructibleAbility"],"xmage_effect_class":"GainAbilityTargetEffect"}'::jsonb, '{"category":"support","effect":"stat_modifier_until_eot","subtype":"temporary_pump","target":"creature","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class AleshasLegacy translated into ManaLoom runtime scope xmage_fixed_keyword_target_creature_until_eot_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('assault strobe', 'Assault Strobe', '3becb38db1b3dcd8a0306eddd402ed13', 'battle_rule_v1:19a7bc7320a3d5f9fe2138f567b9f336', '{"battle_model_scope":"xmage_fixed_keyword_target_creature_until_eot_spell_v1","duration":"until_end_of_turn","effect":"stat_modifier_until_eot","granted_keywords_until_eot":["double_strike"],"instant":false,"power_boost":0,"power_delta":0,"sorcery":true,"target":"creature","target_constraints":{"card_types":["creature"]},"target_controller":"any","toughness_boost":0,"toughness_delta":0,"xmage_ability_classes":["DoubleStrikeAbility"],"xmage_effect_class":"GainAbilityTargetEffect"}'::jsonb, '{"category":"support","effect":"stat_modifier_until_eot","subtype":"temporary_pump","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class AssaultStrobe translated into ManaLoom runtime scope xmage_fixed_keyword_target_creature_until_eot_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('battle-rage blessing', 'Battle-Rage Blessing', '5738b136f3a8c1bc122429dee47d55c3', 'battle_rule_v1:eba43c09036c5996f18ebb89e91080bb', '{"battle_model_scope":"xmage_fixed_keyword_target_creature_until_eot_spell_v1","duration":"until_end_of_turn","effect":"stat_modifier_until_eot","granted_keywords_until_eot":["deathtouch","indestructible"],"instant":true,"power_boost":0,"power_delta":0,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"]},"target_controller":"any","toughness_boost":0,"toughness_delta":0,"xmage_ability_classes":["DeathtouchAbility","IndestructibleAbility"],"xmage_effect_class":"GainAbilityTargetEffect"}'::jsonb, '{"category":"support","effect":"stat_modifier_until_eot","subtype":"temporary_pump","target":"creature","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class BattleRageBlessing translated into ManaLoom runtime scope xmage_fixed_keyword_target_creature_until_eot_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('double cleave', 'Double Cleave', '3becb38db1b3dcd8a0306eddd402ed13', 'battle_rule_v1:8bf9be1f48750780ffd5a7059ae47e75', '{"battle_model_scope":"xmage_fixed_keyword_target_creature_until_eot_spell_v1","duration":"until_end_of_turn","effect":"stat_modifier_until_eot","granted_keywords_until_eot":["double_strike"],"instant":true,"power_boost":0,"power_delta":0,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"]},"target_controller":"any","toughness_boost":0,"toughness_delta":0,"xmage_ability_classes":["DoubleStrikeAbility"],"xmage_effect_class":"GainAbilityTargetEffect"}'::jsonb, '{"category":"support","effect":"stat_modifier_until_eot","subtype":"temporary_pump","target":"creature","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class DoubleCleave translated into ManaLoom runtime scope xmage_fixed_keyword_target_creature_until_eot_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('horrid vigor', 'Horrid Vigor', '16f72812647b7b6ebd06602a3e8415fe', 'battle_rule_v1:eba43c09036c5996f18ebb89e91080bb', '{"battle_model_scope":"xmage_fixed_keyword_target_creature_until_eot_spell_v1","duration":"until_end_of_turn","effect":"stat_modifier_until_eot","granted_keywords_until_eot":["deathtouch","indestructible"],"instant":true,"power_boost":0,"power_delta":0,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"]},"target_controller":"any","toughness_boost":0,"toughness_delta":0,"xmage_ability_classes":["DeathtouchAbility","IndestructibleAbility"],"xmage_effect_class":"GainAbilityTargetEffect"}'::jsonb, '{"category":"support","effect":"stat_modifier_until_eot","subtype":"temporary_pump","target":"creature","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class HorridVigor translated into ManaLoom runtime scope xmage_fixed_keyword_target_creature_until_eot_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('jump', 'Jump', 'ae63312ccd991825d03f1229015c8d36', 'battle_rule_v1:8edc824d3b408970c2be21310425c6c8', '{"battle_model_scope":"xmage_fixed_keyword_target_creature_until_eot_spell_v1","duration":"until_end_of_turn","effect":"stat_modifier_until_eot","granted_keywords_until_eot":["flying"],"instant":true,"power_boost":0,"power_delta":0,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"]},"target_controller":"any","toughness_boost":0,"toughness_delta":0,"xmage_ability_classes":["FlyingAbility"],"xmage_effect_class":"GainAbilityTargetEffect"}'::jsonb, '{"category":"support","effect":"stat_modifier_until_eot","subtype":"temporary_pump","target":"creature","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Jump translated into ManaLoom runtime scope xmage_fixed_keyword_target_creature_until_eot_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('offer immortality', 'Offer Immortality', '5738b136f3a8c1bc122429dee47d55c3', 'battle_rule_v1:eba43c09036c5996f18ebb89e91080bb', '{"battle_model_scope":"xmage_fixed_keyword_target_creature_until_eot_spell_v1","duration":"until_end_of_turn","effect":"stat_modifier_until_eot","granted_keywords_until_eot":["deathtouch","indestructible"],"instant":true,"power_boost":0,"power_delta":0,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"]},"target_controller":"any","toughness_boost":0,"toughness_delta":0,"xmage_ability_classes":["DeathtouchAbility","IndestructibleAbility"],"xmage_effect_class":"GainAbilityTargetEffect"}'::jsonb, '{"category":"support","effect":"stat_modifier_until_eot","subtype":"temporary_pump","target":"creature","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class OfferImmortality translated into ManaLoom runtime scope xmage_fixed_keyword_target_creature_until_eot_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('serpent''s gift', 'Serpent''s Gift', '01593088748dd471d3846b334c388118', 'battle_rule_v1:d8dcdb430502bd2b37d661018bd32aa9', '{"battle_model_scope":"xmage_fixed_keyword_target_creature_until_eot_spell_v1","duration":"until_end_of_turn","effect":"stat_modifier_until_eot","granted_keywords_until_eot":["deathtouch"],"instant":true,"power_boost":0,"power_delta":0,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"]},"target_controller":"any","toughness_boost":0,"toughness_delta":0,"xmage_ability_classes":["DeathtouchAbility"],"xmage_effect_class":"GainAbilityTargetEffect"}'::jsonb, '{"category":"support","effect":"stat_modifier_until_eot","subtype":"temporary_pump","target":"creature","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class SerpentsGift translated into ManaLoom runtime scope xmage_fixed_keyword_target_creature_until_eot_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('ticked off', 'Ticked Off', '3becb38db1b3dcd8a0306eddd402ed13', 'battle_rule_v1:19a7bc7320a3d5f9fe2138f567b9f336', '{"battle_model_scope":"xmage_fixed_keyword_target_creature_until_eot_spell_v1","duration":"until_end_of_turn","effect":"stat_modifier_until_eot","granted_keywords_until_eot":["double_strike"],"instant":false,"power_boost":0,"power_delta":0,"sorcery":true,"target":"creature","target_constraints":{"card_types":["creature"]},"target_controller":"any","toughness_boost":0,"toughness_delta":0,"xmage_ability_classes":["DoubleStrikeAbility"],"xmage_effect_class":"GainAbilityTargetEffect"}'::jsonb, '{"category":"support","effect":"stat_modifier_until_eot","subtype":"temporary_pump","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class TickedOff translated into ManaLoom runtime scope xmage_fixed_keyword_target_creature_until_eot_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('unnatural speed', 'Unnatural Speed', '763d6a49451a4cdbf02081795e2be17a', 'battle_rule_v1:ddd9fa2026191b67377e3d53084771fc', '{"battle_model_scope":"xmage_fixed_keyword_target_creature_until_eot_spell_v1","duration":"until_end_of_turn","effect":"stat_modifier_until_eot","granted_keywords_until_eot":["haste"],"instant":true,"power_boost":0,"power_delta":0,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"]},"target_controller":"any","toughness_boost":0,"toughness_delta":0,"xmage_ability_classes":["HasteAbility"],"xmage_effect_class":"GainAbilityTargetEffect"}'::jsonb, '{"category":"support","effect":"stat_modifier_until_eot","subtype":"temporary_pump","target":"creature","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class UnnaturalSpeed translated into ManaLoom runtime scope xmage_fixed_keyword_target_creature_until_eot_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
