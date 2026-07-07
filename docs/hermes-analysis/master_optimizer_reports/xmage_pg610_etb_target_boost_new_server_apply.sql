BEGIN;

CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit;

CREATE TABLE IF NOT EXISTS manaloom_deploy_audit.pg610_etb_target_boost_new_server_20260707_105801 AS
SELECT *
FROM public.card_battle_rules
WHERE normalized_name IN ('blister beetle', 'daybreak charger', 'farbog boneflinger', 'guardian of pilgrims', 'jadecraft artisan', 'kinsbaile skirmisher', 'rubblebelt boar', 'tenth district guard', 'vulshok heartstoker', 'yeva''s forcemage')
   OR normalized_name LIKE 'blister beetle // %'
   OR normalized_name LIKE 'daybreak charger // %'
   OR normalized_name LIKE 'farbog boneflinger // %'
   OR normalized_name LIKE 'guardian of pilgrims // %'
   OR normalized_name LIKE 'jadecraft artisan // %'
   OR normalized_name LIKE 'kinsbaile skirmisher // %'
   OR normalized_name LIKE 'rubblebelt boar // %'
   OR normalized_name LIKE 'tenth district guard // %'
   OR normalized_name LIKE 'vulshok heartstoker // %'
   OR normalized_name LIKE 'yeva''s forcemage // %';

DO $$
DECLARE
  v_missing jsonb;
BEGIN
  WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('blister beetle', 'Blister Beetle', 'ee848485353b6bbf8f21c7045b8f5e2d', 'battle_rule_v1:df7da59e6120c06e7a7cf424d0806dab', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_fixed_boost_target_until_eot_v1","duration":"until_end_of_turn","effect":"creature","etb_target_stat_modifier":true,"power_boost":-1,"power_delta":-1,"target":"creature","target_constraints":{"card_types":["creature"]},"target_controller":"any","toughness_boost":-1,"toughness_delta":-1,"trigger":"enters_battlefield","trigger_effect":"stat_modifier_until_eot","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"BoostTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class BlisterBeetle translated into ManaLoom runtime scope xmage_creature_etb_fixed_boost_target_until_eot_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('daybreak charger', 'Daybreak Charger', '351d6e15733b5c222f490fffe42dbdb6', 'battle_rule_v1:d676ca7df8e0a239c44ff49b71a31ead', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_fixed_boost_target_until_eot_v1","duration":"until_end_of_turn","effect":"creature","etb_target_stat_modifier":true,"power_boost":2,"power_delta":2,"target":"creature","target_constraints":{"card_types":["creature"]},"target_controller":"any","toughness_boost":0,"toughness_delta":0,"trigger":"enters_battlefield","trigger_effect":"stat_modifier_until_eot","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"BoostTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class DaybreakCharger translated into ManaLoom runtime scope xmage_creature_etb_fixed_boost_target_until_eot_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('farbog boneflinger', 'Farbog Boneflinger', '0cd8a1d30db1c953ec4a0999f5685834', 'battle_rule_v1:a9c6733045b3ee8db1367ecbab9832c8', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_fixed_boost_target_until_eot_v1","duration":"until_end_of_turn","effect":"creature","etb_target_stat_modifier":true,"power_boost":-2,"power_delta":-2,"target":"creature","target_constraints":{"card_types":["creature"]},"target_controller":"any","toughness_boost":-2,"toughness_delta":-2,"trigger":"enters_battlefield","trigger_effect":"stat_modifier_until_eot","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"BoostTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class FarbogBoneflinger translated into ManaLoom runtime scope xmage_creature_etb_fixed_boost_target_until_eot_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('guardian of pilgrims', 'Guardian of Pilgrims', '42c5389430b63b6e1a46e3a5437ea12d', 'battle_rule_v1:7c3fad25d40df83682dac894512cec82', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_fixed_boost_target_until_eot_v1","duration":"until_end_of_turn","effect":"creature","etb_target_stat_modifier":true,"power_boost":1,"power_delta":1,"target":"creature","target_constraints":{"card_types":["creature"]},"target_controller":"any","toughness_boost":1,"toughness_delta":1,"trigger":"enters_battlefield","trigger_effect":"stat_modifier_until_eot","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"BoostTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class GuardianOfPilgrims translated into ManaLoom runtime scope xmage_creature_etb_fixed_boost_target_until_eot_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('jadecraft artisan', 'Jadecraft Artisan', '3200139f56f87c26184f67fe4a5b3a54', 'battle_rule_v1:545d0764d4993cc2ec59375083699f4e', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_fixed_boost_target_until_eot_v1","duration":"until_end_of_turn","effect":"creature","etb_target_stat_modifier":true,"power_boost":2,"power_delta":2,"target":"creature","target_constraints":{"card_types":["creature"]},"target_controller":"any","toughness_boost":2,"toughness_delta":2,"trigger":"enters_battlefield","trigger_effect":"stat_modifier_until_eot","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"BoostTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class JadecraftArtisan translated into ManaLoom runtime scope xmage_creature_etb_fixed_boost_target_until_eot_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('kinsbaile skirmisher', 'Kinsbaile Skirmisher', '42c5389430b63b6e1a46e3a5437ea12d', 'battle_rule_v1:7c3fad25d40df83682dac894512cec82', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_fixed_boost_target_until_eot_v1","duration":"until_end_of_turn","effect":"creature","etb_target_stat_modifier":true,"power_boost":1,"power_delta":1,"target":"creature","target_constraints":{"card_types":["creature"]},"target_controller":"any","toughness_boost":1,"toughness_delta":1,"trigger":"enters_battlefield","trigger_effect":"stat_modifier_until_eot","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"BoostTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class KinsbaileSkirmisher translated into ManaLoom runtime scope xmage_creature_etb_fixed_boost_target_until_eot_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('rubblebelt boar', 'Rubblebelt Boar', '351d6e15733b5c222f490fffe42dbdb6', 'battle_rule_v1:d676ca7df8e0a239c44ff49b71a31ead', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_fixed_boost_target_until_eot_v1","duration":"until_end_of_turn","effect":"creature","etb_target_stat_modifier":true,"power_boost":2,"power_delta":2,"target":"creature","target_constraints":{"card_types":["creature"]},"target_controller":"any","toughness_boost":0,"toughness_delta":0,"trigger":"enters_battlefield","trigger_effect":"stat_modifier_until_eot","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"BoostTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class RubblebeltBoar translated into ManaLoom runtime scope xmage_creature_etb_fixed_boost_target_until_eot_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('tenth district guard', 'Tenth District Guard', 'aeac46be153986453a88dd35b683fe46', 'battle_rule_v1:72fca02cd157f856fd67771dba303dce', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_fixed_boost_target_until_eot_v1","duration":"until_end_of_turn","effect":"creature","etb_target_stat_modifier":true,"power_boost":0,"power_delta":0,"target":"creature","target_constraints":{"card_types":["creature"]},"target_controller":"any","toughness_boost":1,"toughness_delta":1,"trigger":"enters_battlefield","trigger_effect":"stat_modifier_until_eot","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"BoostTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class TenthDistrictGuard translated into ManaLoom runtime scope xmage_creature_etb_fixed_boost_target_until_eot_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('vulshok heartstoker', 'Vulshok Heartstoker', '351d6e15733b5c222f490fffe42dbdb6', 'battle_rule_v1:d676ca7df8e0a239c44ff49b71a31ead', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_fixed_boost_target_until_eot_v1","duration":"until_end_of_turn","effect":"creature","etb_target_stat_modifier":true,"power_boost":2,"power_delta":2,"target":"creature","target_constraints":{"card_types":["creature"]},"target_controller":"any","toughness_boost":0,"toughness_delta":0,"trigger":"enters_battlefield","trigger_effect":"stat_modifier_until_eot","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"BoostTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class VulshokHeartstoker translated into ManaLoom runtime scope xmage_creature_etb_fixed_boost_target_until_eot_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('yeva''s forcemage', 'Yeva''s Forcemage', '3200139f56f87c26184f67fe4a5b3a54', 'battle_rule_v1:545d0764d4993cc2ec59375083699f4e', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_fixed_boost_target_until_eot_v1","duration":"until_end_of_turn","effect":"creature","etb_target_stat_modifier":true,"power_boost":2,"power_delta":2,"target":"creature","target_constraints":{"card_types":["creature"]},"target_controller":"any","toughness_boost":2,"toughness_delta":2,"trigger":"enters_battlefield","trigger_effect":"stat_modifier_until_eot","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"BoostTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class YevasForcemage translated into ManaLoom runtime scope xmage_creature_etb_fixed_boost_target_until_eot_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
    ('blister beetle', 'Blister Beetle', 'ee848485353b6bbf8f21c7045b8f5e2d', 'battle_rule_v1:df7da59e6120c06e7a7cf424d0806dab', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_fixed_boost_target_until_eot_v1","duration":"until_end_of_turn","effect":"creature","etb_target_stat_modifier":true,"power_boost":-1,"power_delta":-1,"target":"creature","target_constraints":{"card_types":["creature"]},"target_controller":"any","toughness_boost":-1,"toughness_delta":-1,"trigger":"enters_battlefield","trigger_effect":"stat_modifier_until_eot","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"BoostTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class BlisterBeetle translated into ManaLoom runtime scope xmage_creature_etb_fixed_boost_target_until_eot_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('daybreak charger', 'Daybreak Charger', '351d6e15733b5c222f490fffe42dbdb6', 'battle_rule_v1:d676ca7df8e0a239c44ff49b71a31ead', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_fixed_boost_target_until_eot_v1","duration":"until_end_of_turn","effect":"creature","etb_target_stat_modifier":true,"power_boost":2,"power_delta":2,"target":"creature","target_constraints":{"card_types":["creature"]},"target_controller":"any","toughness_boost":0,"toughness_delta":0,"trigger":"enters_battlefield","trigger_effect":"stat_modifier_until_eot","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"BoostTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class DaybreakCharger translated into ManaLoom runtime scope xmage_creature_etb_fixed_boost_target_until_eot_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('farbog boneflinger', 'Farbog Boneflinger', '0cd8a1d30db1c953ec4a0999f5685834', 'battle_rule_v1:a9c6733045b3ee8db1367ecbab9832c8', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_fixed_boost_target_until_eot_v1","duration":"until_end_of_turn","effect":"creature","etb_target_stat_modifier":true,"power_boost":-2,"power_delta":-2,"target":"creature","target_constraints":{"card_types":["creature"]},"target_controller":"any","toughness_boost":-2,"toughness_delta":-2,"trigger":"enters_battlefield","trigger_effect":"stat_modifier_until_eot","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"BoostTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class FarbogBoneflinger translated into ManaLoom runtime scope xmage_creature_etb_fixed_boost_target_until_eot_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('guardian of pilgrims', 'Guardian of Pilgrims', '42c5389430b63b6e1a46e3a5437ea12d', 'battle_rule_v1:7c3fad25d40df83682dac894512cec82', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_fixed_boost_target_until_eot_v1","duration":"until_end_of_turn","effect":"creature","etb_target_stat_modifier":true,"power_boost":1,"power_delta":1,"target":"creature","target_constraints":{"card_types":["creature"]},"target_controller":"any","toughness_boost":1,"toughness_delta":1,"trigger":"enters_battlefield","trigger_effect":"stat_modifier_until_eot","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"BoostTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class GuardianOfPilgrims translated into ManaLoom runtime scope xmage_creature_etb_fixed_boost_target_until_eot_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('jadecraft artisan', 'Jadecraft Artisan', '3200139f56f87c26184f67fe4a5b3a54', 'battle_rule_v1:545d0764d4993cc2ec59375083699f4e', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_fixed_boost_target_until_eot_v1","duration":"until_end_of_turn","effect":"creature","etb_target_stat_modifier":true,"power_boost":2,"power_delta":2,"target":"creature","target_constraints":{"card_types":["creature"]},"target_controller":"any","toughness_boost":2,"toughness_delta":2,"trigger":"enters_battlefield","trigger_effect":"stat_modifier_until_eot","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"BoostTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class JadecraftArtisan translated into ManaLoom runtime scope xmage_creature_etb_fixed_boost_target_until_eot_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('kinsbaile skirmisher', 'Kinsbaile Skirmisher', '42c5389430b63b6e1a46e3a5437ea12d', 'battle_rule_v1:7c3fad25d40df83682dac894512cec82', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_fixed_boost_target_until_eot_v1","duration":"until_end_of_turn","effect":"creature","etb_target_stat_modifier":true,"power_boost":1,"power_delta":1,"target":"creature","target_constraints":{"card_types":["creature"]},"target_controller":"any","toughness_boost":1,"toughness_delta":1,"trigger":"enters_battlefield","trigger_effect":"stat_modifier_until_eot","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"BoostTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class KinsbaileSkirmisher translated into ManaLoom runtime scope xmage_creature_etb_fixed_boost_target_until_eot_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('rubblebelt boar', 'Rubblebelt Boar', '351d6e15733b5c222f490fffe42dbdb6', 'battle_rule_v1:d676ca7df8e0a239c44ff49b71a31ead', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_fixed_boost_target_until_eot_v1","duration":"until_end_of_turn","effect":"creature","etb_target_stat_modifier":true,"power_boost":2,"power_delta":2,"target":"creature","target_constraints":{"card_types":["creature"]},"target_controller":"any","toughness_boost":0,"toughness_delta":0,"trigger":"enters_battlefield","trigger_effect":"stat_modifier_until_eot","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"BoostTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class RubblebeltBoar translated into ManaLoom runtime scope xmage_creature_etb_fixed_boost_target_until_eot_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('tenth district guard', 'Tenth District Guard', 'aeac46be153986453a88dd35b683fe46', 'battle_rule_v1:72fca02cd157f856fd67771dba303dce', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_fixed_boost_target_until_eot_v1","duration":"until_end_of_turn","effect":"creature","etb_target_stat_modifier":true,"power_boost":0,"power_delta":0,"target":"creature","target_constraints":{"card_types":["creature"]},"target_controller":"any","toughness_boost":1,"toughness_delta":1,"trigger":"enters_battlefield","trigger_effect":"stat_modifier_until_eot","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"BoostTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class TenthDistrictGuard translated into ManaLoom runtime scope xmage_creature_etb_fixed_boost_target_until_eot_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('vulshok heartstoker', 'Vulshok Heartstoker', '351d6e15733b5c222f490fffe42dbdb6', 'battle_rule_v1:d676ca7df8e0a239c44ff49b71a31ead', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_fixed_boost_target_until_eot_v1","duration":"until_end_of_turn","effect":"creature","etb_target_stat_modifier":true,"power_boost":2,"power_delta":2,"target":"creature","target_constraints":{"card_types":["creature"]},"target_controller":"any","toughness_boost":0,"toughness_delta":0,"trigger":"enters_battlefield","trigger_effect":"stat_modifier_until_eot","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"BoostTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class VulshokHeartstoker translated into ManaLoom runtime scope xmage_creature_etb_fixed_boost_target_until_eot_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('yeva''s forcemage', 'Yeva''s Forcemage', '3200139f56f87c26184f67fe4a5b3a54', 'battle_rule_v1:545d0764d4993cc2ec59375083699f4e', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_fixed_boost_target_until_eot_v1","duration":"until_end_of_turn","effect":"creature","etb_target_stat_modifier":true,"power_boost":2,"power_delta":2,"target":"creature","target_constraints":{"card_types":["creature"]},"target_controller":"any","toughness_boost":2,"toughness_delta":2,"trigger":"enters_battlefield","trigger_effect":"stat_modifier_until_eot","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"BoostTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class YevasForcemage translated into ManaLoom runtime scope xmage_creature_etb_fixed_boost_target_until_eot_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
    ('blister beetle', 'Blister Beetle', 'ee848485353b6bbf8f21c7045b8f5e2d', 'battle_rule_v1:df7da59e6120c06e7a7cf424d0806dab', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_fixed_boost_target_until_eot_v1","duration":"until_end_of_turn","effect":"creature","etb_target_stat_modifier":true,"power_boost":-1,"power_delta":-1,"target":"creature","target_constraints":{"card_types":["creature"]},"target_controller":"any","toughness_boost":-1,"toughness_delta":-1,"trigger":"enters_battlefield","trigger_effect":"stat_modifier_until_eot","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"BoostTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class BlisterBeetle translated into ManaLoom runtime scope xmage_creature_etb_fixed_boost_target_until_eot_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('daybreak charger', 'Daybreak Charger', '351d6e15733b5c222f490fffe42dbdb6', 'battle_rule_v1:d676ca7df8e0a239c44ff49b71a31ead', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_fixed_boost_target_until_eot_v1","duration":"until_end_of_turn","effect":"creature","etb_target_stat_modifier":true,"power_boost":2,"power_delta":2,"target":"creature","target_constraints":{"card_types":["creature"]},"target_controller":"any","toughness_boost":0,"toughness_delta":0,"trigger":"enters_battlefield","trigger_effect":"stat_modifier_until_eot","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"BoostTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class DaybreakCharger translated into ManaLoom runtime scope xmage_creature_etb_fixed_boost_target_until_eot_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('farbog boneflinger', 'Farbog Boneflinger', '0cd8a1d30db1c953ec4a0999f5685834', 'battle_rule_v1:a9c6733045b3ee8db1367ecbab9832c8', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_fixed_boost_target_until_eot_v1","duration":"until_end_of_turn","effect":"creature","etb_target_stat_modifier":true,"power_boost":-2,"power_delta":-2,"target":"creature","target_constraints":{"card_types":["creature"]},"target_controller":"any","toughness_boost":-2,"toughness_delta":-2,"trigger":"enters_battlefield","trigger_effect":"stat_modifier_until_eot","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"BoostTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class FarbogBoneflinger translated into ManaLoom runtime scope xmage_creature_etb_fixed_boost_target_until_eot_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('guardian of pilgrims', 'Guardian of Pilgrims', '42c5389430b63b6e1a46e3a5437ea12d', 'battle_rule_v1:7c3fad25d40df83682dac894512cec82', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_fixed_boost_target_until_eot_v1","duration":"until_end_of_turn","effect":"creature","etb_target_stat_modifier":true,"power_boost":1,"power_delta":1,"target":"creature","target_constraints":{"card_types":["creature"]},"target_controller":"any","toughness_boost":1,"toughness_delta":1,"trigger":"enters_battlefield","trigger_effect":"stat_modifier_until_eot","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"BoostTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class GuardianOfPilgrims translated into ManaLoom runtime scope xmage_creature_etb_fixed_boost_target_until_eot_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('jadecraft artisan', 'Jadecraft Artisan', '3200139f56f87c26184f67fe4a5b3a54', 'battle_rule_v1:545d0764d4993cc2ec59375083699f4e', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_fixed_boost_target_until_eot_v1","duration":"until_end_of_turn","effect":"creature","etb_target_stat_modifier":true,"power_boost":2,"power_delta":2,"target":"creature","target_constraints":{"card_types":["creature"]},"target_controller":"any","toughness_boost":2,"toughness_delta":2,"trigger":"enters_battlefield","trigger_effect":"stat_modifier_until_eot","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"BoostTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class JadecraftArtisan translated into ManaLoom runtime scope xmage_creature_etb_fixed_boost_target_until_eot_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('kinsbaile skirmisher', 'Kinsbaile Skirmisher', '42c5389430b63b6e1a46e3a5437ea12d', 'battle_rule_v1:7c3fad25d40df83682dac894512cec82', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_fixed_boost_target_until_eot_v1","duration":"until_end_of_turn","effect":"creature","etb_target_stat_modifier":true,"power_boost":1,"power_delta":1,"target":"creature","target_constraints":{"card_types":["creature"]},"target_controller":"any","toughness_boost":1,"toughness_delta":1,"trigger":"enters_battlefield","trigger_effect":"stat_modifier_until_eot","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"BoostTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class KinsbaileSkirmisher translated into ManaLoom runtime scope xmage_creature_etb_fixed_boost_target_until_eot_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('rubblebelt boar', 'Rubblebelt Boar', '351d6e15733b5c222f490fffe42dbdb6', 'battle_rule_v1:d676ca7df8e0a239c44ff49b71a31ead', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_fixed_boost_target_until_eot_v1","duration":"until_end_of_turn","effect":"creature","etb_target_stat_modifier":true,"power_boost":2,"power_delta":2,"target":"creature","target_constraints":{"card_types":["creature"]},"target_controller":"any","toughness_boost":0,"toughness_delta":0,"trigger":"enters_battlefield","trigger_effect":"stat_modifier_until_eot","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"BoostTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class RubblebeltBoar translated into ManaLoom runtime scope xmage_creature_etb_fixed_boost_target_until_eot_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('tenth district guard', 'Tenth District Guard', 'aeac46be153986453a88dd35b683fe46', 'battle_rule_v1:72fca02cd157f856fd67771dba303dce', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_fixed_boost_target_until_eot_v1","duration":"until_end_of_turn","effect":"creature","etb_target_stat_modifier":true,"power_boost":0,"power_delta":0,"target":"creature","target_constraints":{"card_types":["creature"]},"target_controller":"any","toughness_boost":1,"toughness_delta":1,"trigger":"enters_battlefield","trigger_effect":"stat_modifier_until_eot","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"BoostTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class TenthDistrictGuard translated into ManaLoom runtime scope xmage_creature_etb_fixed_boost_target_until_eot_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('vulshok heartstoker', 'Vulshok Heartstoker', '351d6e15733b5c222f490fffe42dbdb6', 'battle_rule_v1:d676ca7df8e0a239c44ff49b71a31ead', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_fixed_boost_target_until_eot_v1","duration":"until_end_of_turn","effect":"creature","etb_target_stat_modifier":true,"power_boost":2,"power_delta":2,"target":"creature","target_constraints":{"card_types":["creature"]},"target_controller":"any","toughness_boost":0,"toughness_delta":0,"trigger":"enters_battlefield","trigger_effect":"stat_modifier_until_eot","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"BoostTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class VulshokHeartstoker translated into ManaLoom runtime scope xmage_creature_etb_fixed_boost_target_until_eot_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('yeva''s forcemage', 'Yeva''s Forcemage', '3200139f56f87c26184f67fe4a5b3a54', 'battle_rule_v1:545d0764d4993cc2ec59375083699f4e', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_fixed_boost_target_until_eot_v1","duration":"until_end_of_turn","effect":"creature","etb_target_stat_modifier":true,"power_boost":2,"power_delta":2,"target":"creature","target_constraints":{"card_types":["creature"]},"target_controller":"any","toughness_boost":2,"toughness_delta":2,"trigger":"enters_battlefield","trigger_effect":"stat_modifier_until_eot","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"BoostTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class YevasForcemage translated into ManaLoom runtime scope xmage_creature_etb_fixed_boost_target_until_eot_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
