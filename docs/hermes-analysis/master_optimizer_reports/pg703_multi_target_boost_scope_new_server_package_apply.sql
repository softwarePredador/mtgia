BEGIN;

CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit;

CREATE TABLE IF NOT EXISTS manaloom_deploy_audit.pg703_multi_target_boost_scope_new_serve_20260710_140443 AS
SELECT *
FROM public.card_battle_rules
WHERE normalized_name IN ('dauntless onslaught', 'hearts on fire', 'mischief and mayhem', 'nahiri''s stoneblades', 'sick and tired', 'symbiosis', 'windborne charge')
   OR normalized_name LIKE 'dauntless onslaught // %'
   OR normalized_name LIKE 'hearts on fire // %'
   OR normalized_name LIKE 'mischief and mayhem // %'
   OR normalized_name LIKE 'nahiri''s stoneblades // %'
   OR normalized_name LIKE 'sick and tired // %'
   OR normalized_name LIKE 'symbiosis // %'
   OR normalized_name LIKE 'windborne charge // %';

DO $$
DECLARE
  v_missing jsonb;
BEGIN
  WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('dauntless onslaught', 'Dauntless Onslaught', 'b25037b66b47c2746777fca994bbd047', 'battle_rule_v1:2833a7f6bfdb677cd0d3f0a26cc5cc6e', '{"battle_model_scope":"xmage_fixed_boost_target_creature_until_eot_spell_v1","duration":"until_end_of_turn","effect":"stat_modifier_until_eot","instant":true,"power_boost":2,"power_delta":2,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"]},"target_controller":"any","target_count":2,"target_count_max":2,"target_count_min":0,"toughness_boost":2,"toughness_delta":2,"up_to_count":true,"xmage_effect_class":"BoostTargetEffect"}'::jsonb, '{"category":"support","effect":"stat_modifier_until_eot","subtype":"temporary_pump","target":"creature","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class DauntlessOnslaught translated into ManaLoom runtime scope xmage_fixed_boost_target_creature_until_eot_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('hearts on fire', 'Hearts on Fire', '95679abe60fdb5c15a1ddf3b711c0dfc', 'battle_rule_v1:d588e7158b14dfec37cf73bd0ec5a7e8', '{"battle_model_scope":"xmage_fixed_boost_target_creature_until_eot_spell_v1","duration":"until_end_of_turn","effect":"stat_modifier_until_eot","instant":true,"power_boost":2,"power_delta":2,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"]},"target_controller":"any","target_count":2,"target_count_max":2,"target_count_min":1,"toughness_boost":1,"toughness_delta":1,"up_to_count":true,"xmage_effect_class":"BoostTargetEffect"}'::jsonb, '{"category":"support","effect":"stat_modifier_until_eot","subtype":"temporary_pump","target":"creature","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class HeartsOnFire translated into ManaLoom runtime scope xmage_fixed_boost_target_creature_until_eot_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('mischief and mayhem', 'Mischief and Mayhem', 'dc7da00dadc9a5d5c2ddb477a35f1985', 'battle_rule_v1:9df4b1214f52a2f3cc04a1b09fd9850d', '{"battle_model_scope":"xmage_fixed_boost_target_creature_until_eot_spell_v1","duration":"until_end_of_turn","effect":"stat_modifier_until_eot","instant":false,"power_boost":4,"power_delta":4,"sorcery":true,"target":"creature","target_constraints":{"card_types":["creature"]},"target_controller":"any","target_count":2,"target_count_max":2,"target_count_min":0,"toughness_boost":4,"toughness_delta":4,"up_to_count":true,"xmage_effect_class":"BoostTargetEffect"}'::jsonb, '{"category":"support","effect":"stat_modifier_until_eot","subtype":"temporary_pump","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class MischiefAndMayhem translated into ManaLoom runtime scope xmage_fixed_boost_target_creature_until_eot_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('nahiri''s stoneblades', 'Nahiri''s Stoneblades', '7b1fa83ffeda7fba0b3f63f028916559', 'battle_rule_v1:2f81c811687ee235821a0248d8e3e5b5', '{"battle_model_scope":"xmage_fixed_boost_target_creature_until_eot_spell_v1","duration":"until_end_of_turn","effect":"stat_modifier_until_eot","instant":true,"power_boost":2,"power_delta":2,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"]},"target_controller":"any","target_count":2,"target_count_max":2,"target_count_min":0,"toughness_boost":0,"toughness_delta":0,"up_to_count":true,"xmage_effect_class":"BoostTargetEffect"}'::jsonb, '{"category":"support","effect":"stat_modifier_until_eot","subtype":"temporary_pump","target":"creature","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class NahirisStoneblades translated into ManaLoom runtime scope xmage_fixed_boost_target_creature_until_eot_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('sick and tired', 'Sick and Tired', 'b6c3e113eb33fa162891fc31678a71b0', 'battle_rule_v1:c8493813d11edd236b1ba95205a08489', '{"battle_model_scope":"xmage_fixed_boost_target_creature_until_eot_spell_v1","duration":"until_end_of_turn","effect":"stat_modifier_until_eot","instant":true,"power_boost":-1,"power_delta":-1,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"]},"target_controller":"any","target_count":2,"target_count_max":2,"target_count_min":2,"toughness_boost":-1,"toughness_delta":-1,"up_to_count":false,"xmage_effect_class":"BoostTargetEffect"}'::jsonb, '{"category":"removal","effect":"stat_modifier_until_eot","subtype":"temporary_debuff","target":"creature","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class SickAndTired translated into ManaLoom runtime scope xmage_fixed_boost_target_creature_until_eot_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('symbiosis', 'Symbiosis', '8a7990bc274aafbd6d9ea4ab8c5d4be6', 'battle_rule_v1:0f4076c66f0ce555911e06dfb18b0fcc', '{"battle_model_scope":"xmage_fixed_boost_target_creature_until_eot_spell_v1","duration":"until_end_of_turn","effect":"stat_modifier_until_eot","instant":true,"power_boost":2,"power_delta":2,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"]},"target_controller":"any","target_count":2,"target_count_max":2,"target_count_min":2,"toughness_boost":2,"toughness_delta":2,"up_to_count":false,"xmage_effect_class":"BoostTargetEffect"}'::jsonb, '{"category":"support","effect":"stat_modifier_until_eot","subtype":"temporary_pump","target":"creature","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Symbiosis translated into ManaLoom runtime scope xmage_fixed_boost_target_creature_until_eot_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('windborne charge', 'Windborne Charge', 'c2c0cfb8033dadc8e9ae44225f033808', 'battle_rule_v1:eab89b66d1672720d20f40cbd7bc7387', '{"battle_model_scope":"xmage_fixed_boost_and_keyword_target_creature_until_eot_spell_v1","duration":"until_end_of_turn","effect":"stat_modifier_until_eot","granted_keywords_until_eot":["flying"],"instant":false,"power_boost":2,"power_delta":2,"sorcery":true,"target":"creature","target_constraints":{"card_types":["creature"]},"target_controller":"self","target_count":2,"target_count_max":2,"target_count_min":2,"toughness_boost":2,"toughness_delta":2,"up_to_count":false,"xmage_ability_classes":["FlyingAbility"],"xmage_effect_classes":["BoostTargetEffect","GainAbilityTargetEffect"]}'::jsonb, '{"category":"support","effect":"stat_modifier_until_eot","subtype":"temporary_pump","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class WindborneCharge translated into ManaLoom runtime scope xmage_fixed_boost_and_keyword_target_creature_until_eot_spell_v1. This row is package-ready only because the source signature is a narrow fixed target-creature boost plus until-end-of-turn keyword spell with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
    ('dauntless onslaught', 'Dauntless Onslaught', 'b25037b66b47c2746777fca994bbd047', 'battle_rule_v1:2833a7f6bfdb677cd0d3f0a26cc5cc6e', '{"battle_model_scope":"xmage_fixed_boost_target_creature_until_eot_spell_v1","duration":"until_end_of_turn","effect":"stat_modifier_until_eot","instant":true,"power_boost":2,"power_delta":2,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"]},"target_controller":"any","target_count":2,"target_count_max":2,"target_count_min":0,"toughness_boost":2,"toughness_delta":2,"up_to_count":true,"xmage_effect_class":"BoostTargetEffect"}'::jsonb, '{"category":"support","effect":"stat_modifier_until_eot","subtype":"temporary_pump","target":"creature","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class DauntlessOnslaught translated into ManaLoom runtime scope xmage_fixed_boost_target_creature_until_eot_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('hearts on fire', 'Hearts on Fire', '95679abe60fdb5c15a1ddf3b711c0dfc', 'battle_rule_v1:d588e7158b14dfec37cf73bd0ec5a7e8', '{"battle_model_scope":"xmage_fixed_boost_target_creature_until_eot_spell_v1","duration":"until_end_of_turn","effect":"stat_modifier_until_eot","instant":true,"power_boost":2,"power_delta":2,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"]},"target_controller":"any","target_count":2,"target_count_max":2,"target_count_min":1,"toughness_boost":1,"toughness_delta":1,"up_to_count":true,"xmage_effect_class":"BoostTargetEffect"}'::jsonb, '{"category":"support","effect":"stat_modifier_until_eot","subtype":"temporary_pump","target":"creature","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class HeartsOnFire translated into ManaLoom runtime scope xmage_fixed_boost_target_creature_until_eot_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('mischief and mayhem', 'Mischief and Mayhem', 'dc7da00dadc9a5d5c2ddb477a35f1985', 'battle_rule_v1:9df4b1214f52a2f3cc04a1b09fd9850d', '{"battle_model_scope":"xmage_fixed_boost_target_creature_until_eot_spell_v1","duration":"until_end_of_turn","effect":"stat_modifier_until_eot","instant":false,"power_boost":4,"power_delta":4,"sorcery":true,"target":"creature","target_constraints":{"card_types":["creature"]},"target_controller":"any","target_count":2,"target_count_max":2,"target_count_min":0,"toughness_boost":4,"toughness_delta":4,"up_to_count":true,"xmage_effect_class":"BoostTargetEffect"}'::jsonb, '{"category":"support","effect":"stat_modifier_until_eot","subtype":"temporary_pump","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class MischiefAndMayhem translated into ManaLoom runtime scope xmage_fixed_boost_target_creature_until_eot_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('nahiri''s stoneblades', 'Nahiri''s Stoneblades', '7b1fa83ffeda7fba0b3f63f028916559', 'battle_rule_v1:2f81c811687ee235821a0248d8e3e5b5', '{"battle_model_scope":"xmage_fixed_boost_target_creature_until_eot_spell_v1","duration":"until_end_of_turn","effect":"stat_modifier_until_eot","instant":true,"power_boost":2,"power_delta":2,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"]},"target_controller":"any","target_count":2,"target_count_max":2,"target_count_min":0,"toughness_boost":0,"toughness_delta":0,"up_to_count":true,"xmage_effect_class":"BoostTargetEffect"}'::jsonb, '{"category":"support","effect":"stat_modifier_until_eot","subtype":"temporary_pump","target":"creature","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class NahirisStoneblades translated into ManaLoom runtime scope xmage_fixed_boost_target_creature_until_eot_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('sick and tired', 'Sick and Tired', 'b6c3e113eb33fa162891fc31678a71b0', 'battle_rule_v1:c8493813d11edd236b1ba95205a08489', '{"battle_model_scope":"xmage_fixed_boost_target_creature_until_eot_spell_v1","duration":"until_end_of_turn","effect":"stat_modifier_until_eot","instant":true,"power_boost":-1,"power_delta":-1,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"]},"target_controller":"any","target_count":2,"target_count_max":2,"target_count_min":2,"toughness_boost":-1,"toughness_delta":-1,"up_to_count":false,"xmage_effect_class":"BoostTargetEffect"}'::jsonb, '{"category":"removal","effect":"stat_modifier_until_eot","subtype":"temporary_debuff","target":"creature","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class SickAndTired translated into ManaLoom runtime scope xmage_fixed_boost_target_creature_until_eot_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('symbiosis', 'Symbiosis', '8a7990bc274aafbd6d9ea4ab8c5d4be6', 'battle_rule_v1:0f4076c66f0ce555911e06dfb18b0fcc', '{"battle_model_scope":"xmage_fixed_boost_target_creature_until_eot_spell_v1","duration":"until_end_of_turn","effect":"stat_modifier_until_eot","instant":true,"power_boost":2,"power_delta":2,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"]},"target_controller":"any","target_count":2,"target_count_max":2,"target_count_min":2,"toughness_boost":2,"toughness_delta":2,"up_to_count":false,"xmage_effect_class":"BoostTargetEffect"}'::jsonb, '{"category":"support","effect":"stat_modifier_until_eot","subtype":"temporary_pump","target":"creature","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Symbiosis translated into ManaLoom runtime scope xmage_fixed_boost_target_creature_until_eot_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('windborne charge', 'Windborne Charge', 'c2c0cfb8033dadc8e9ae44225f033808', 'battle_rule_v1:eab89b66d1672720d20f40cbd7bc7387', '{"battle_model_scope":"xmage_fixed_boost_and_keyword_target_creature_until_eot_spell_v1","duration":"until_end_of_turn","effect":"stat_modifier_until_eot","granted_keywords_until_eot":["flying"],"instant":false,"power_boost":2,"power_delta":2,"sorcery":true,"target":"creature","target_constraints":{"card_types":["creature"]},"target_controller":"self","target_count":2,"target_count_max":2,"target_count_min":2,"toughness_boost":2,"toughness_delta":2,"up_to_count":false,"xmage_ability_classes":["FlyingAbility"],"xmage_effect_classes":["BoostTargetEffect","GainAbilityTargetEffect"]}'::jsonb, '{"category":"support","effect":"stat_modifier_until_eot","subtype":"temporary_pump","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class WindborneCharge translated into ManaLoom runtime scope xmage_fixed_boost_and_keyword_target_creature_until_eot_spell_v1. This row is package-ready only because the source signature is a narrow fixed target-creature boost plus until-end-of-turn keyword spell with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
    ('dauntless onslaught', 'Dauntless Onslaught', 'b25037b66b47c2746777fca994bbd047', 'battle_rule_v1:2833a7f6bfdb677cd0d3f0a26cc5cc6e', '{"battle_model_scope":"xmage_fixed_boost_target_creature_until_eot_spell_v1","duration":"until_end_of_turn","effect":"stat_modifier_until_eot","instant":true,"power_boost":2,"power_delta":2,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"]},"target_controller":"any","target_count":2,"target_count_max":2,"target_count_min":0,"toughness_boost":2,"toughness_delta":2,"up_to_count":true,"xmage_effect_class":"BoostTargetEffect"}'::jsonb, '{"category":"support","effect":"stat_modifier_until_eot","subtype":"temporary_pump","target":"creature","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class DauntlessOnslaught translated into ManaLoom runtime scope xmage_fixed_boost_target_creature_until_eot_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('hearts on fire', 'Hearts on Fire', '95679abe60fdb5c15a1ddf3b711c0dfc', 'battle_rule_v1:d588e7158b14dfec37cf73bd0ec5a7e8', '{"battle_model_scope":"xmage_fixed_boost_target_creature_until_eot_spell_v1","duration":"until_end_of_turn","effect":"stat_modifier_until_eot","instant":true,"power_boost":2,"power_delta":2,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"]},"target_controller":"any","target_count":2,"target_count_max":2,"target_count_min":1,"toughness_boost":1,"toughness_delta":1,"up_to_count":true,"xmage_effect_class":"BoostTargetEffect"}'::jsonb, '{"category":"support","effect":"stat_modifier_until_eot","subtype":"temporary_pump","target":"creature","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class HeartsOnFire translated into ManaLoom runtime scope xmage_fixed_boost_target_creature_until_eot_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('mischief and mayhem', 'Mischief and Mayhem', 'dc7da00dadc9a5d5c2ddb477a35f1985', 'battle_rule_v1:9df4b1214f52a2f3cc04a1b09fd9850d', '{"battle_model_scope":"xmage_fixed_boost_target_creature_until_eot_spell_v1","duration":"until_end_of_turn","effect":"stat_modifier_until_eot","instant":false,"power_boost":4,"power_delta":4,"sorcery":true,"target":"creature","target_constraints":{"card_types":["creature"]},"target_controller":"any","target_count":2,"target_count_max":2,"target_count_min":0,"toughness_boost":4,"toughness_delta":4,"up_to_count":true,"xmage_effect_class":"BoostTargetEffect"}'::jsonb, '{"category":"support","effect":"stat_modifier_until_eot","subtype":"temporary_pump","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class MischiefAndMayhem translated into ManaLoom runtime scope xmage_fixed_boost_target_creature_until_eot_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('nahiri''s stoneblades', 'Nahiri''s Stoneblades', '7b1fa83ffeda7fba0b3f63f028916559', 'battle_rule_v1:2f81c811687ee235821a0248d8e3e5b5', '{"battle_model_scope":"xmage_fixed_boost_target_creature_until_eot_spell_v1","duration":"until_end_of_turn","effect":"stat_modifier_until_eot","instant":true,"power_boost":2,"power_delta":2,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"]},"target_controller":"any","target_count":2,"target_count_max":2,"target_count_min":0,"toughness_boost":0,"toughness_delta":0,"up_to_count":true,"xmage_effect_class":"BoostTargetEffect"}'::jsonb, '{"category":"support","effect":"stat_modifier_until_eot","subtype":"temporary_pump","target":"creature","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class NahirisStoneblades translated into ManaLoom runtime scope xmage_fixed_boost_target_creature_until_eot_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('sick and tired', 'Sick and Tired', 'b6c3e113eb33fa162891fc31678a71b0', 'battle_rule_v1:c8493813d11edd236b1ba95205a08489', '{"battle_model_scope":"xmage_fixed_boost_target_creature_until_eot_spell_v1","duration":"until_end_of_turn","effect":"stat_modifier_until_eot","instant":true,"power_boost":-1,"power_delta":-1,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"]},"target_controller":"any","target_count":2,"target_count_max":2,"target_count_min":2,"toughness_boost":-1,"toughness_delta":-1,"up_to_count":false,"xmage_effect_class":"BoostTargetEffect"}'::jsonb, '{"category":"removal","effect":"stat_modifier_until_eot","subtype":"temporary_debuff","target":"creature","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class SickAndTired translated into ManaLoom runtime scope xmage_fixed_boost_target_creature_until_eot_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('symbiosis', 'Symbiosis', '8a7990bc274aafbd6d9ea4ab8c5d4be6', 'battle_rule_v1:0f4076c66f0ce555911e06dfb18b0fcc', '{"battle_model_scope":"xmage_fixed_boost_target_creature_until_eot_spell_v1","duration":"until_end_of_turn","effect":"stat_modifier_until_eot","instant":true,"power_boost":2,"power_delta":2,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"]},"target_controller":"any","target_count":2,"target_count_max":2,"target_count_min":2,"toughness_boost":2,"toughness_delta":2,"up_to_count":false,"xmage_effect_class":"BoostTargetEffect"}'::jsonb, '{"category":"support","effect":"stat_modifier_until_eot","subtype":"temporary_pump","target":"creature","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Symbiosis translated into ManaLoom runtime scope xmage_fixed_boost_target_creature_until_eot_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('windborne charge', 'Windborne Charge', 'c2c0cfb8033dadc8e9ae44225f033808', 'battle_rule_v1:eab89b66d1672720d20f40cbd7bc7387', '{"battle_model_scope":"xmage_fixed_boost_and_keyword_target_creature_until_eot_spell_v1","duration":"until_end_of_turn","effect":"stat_modifier_until_eot","granted_keywords_until_eot":["flying"],"instant":false,"power_boost":2,"power_delta":2,"sorcery":true,"target":"creature","target_constraints":{"card_types":["creature"]},"target_controller":"self","target_count":2,"target_count_max":2,"target_count_min":2,"toughness_boost":2,"toughness_delta":2,"up_to_count":false,"xmage_ability_classes":["FlyingAbility"],"xmage_effect_classes":["BoostTargetEffect","GainAbilityTargetEffect"]}'::jsonb, '{"category":"support","effect":"stat_modifier_until_eot","subtype":"temporary_pump","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class WindborneCharge translated into ManaLoom runtime scope xmage_fixed_boost_and_keyword_target_creature_until_eot_spell_v1. This row is package-ready only because the source signature is a narrow fixed target-creature boost plus until-end-of-turn keyword spell with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
