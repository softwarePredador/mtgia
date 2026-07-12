BEGIN;

CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit;

CREATE TABLE IF NOT EXISTS manaloom_deploy_audit.pg803_attachment_graveyard_shared_type_n_20260712_031823 AS
SELECT *
FROM public.card_battle_rules
WHERE normalized_name IN ('alpha status', 'death''s approach', 'exoskeletal armor', 'stoneforge masterwork', 'wreath of geists')
   OR normalized_name LIKE 'alpha status // %'
   OR normalized_name LIKE 'death''s approach // %'
   OR normalized_name LIKE 'exoskeletal armor // %'
   OR normalized_name LIKE 'stoneforge masterwork // %'
   OR normalized_name LIKE 'wreath of geists // %';

DO $$
DECLARE
  v_missing jsonb;
BEGIN
  WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('alpha status', 'Alpha Status', 'dc2fe49152d99850434f64f24d3b6436', 'battle_rule_v1:4637a9f25fc3d815d44d059da775da61', '{"ability_kind":"aura_static","attachment_dynamic_boost":true,"aura":true,"battle_model_scope":"xmage_aura_static_power_toughness_attachment_v1","battlefield_count_scope":"all_battlefields","effect":"aura_static_attachment","enchant_target":"creature","enchant_target_controller":"any","instant":false,"power_base_delta":0,"power_boost":0,"power_delta_per_graveyard_count":2,"sorcery":false,"stat_modifier_amount_source":"attached_creature_shared_type_count","static_effect":"attached_creature_power_toughness_boost_equal_count","static_power_bonus":0,"static_toughness_bonus":0,"target":"creature","target_constraints":{"card_types":["creature"],"zone":"battlefield"},"toughness_base_delta":0,"toughness_boost":0,"toughness_delta_per_graveyard_count":2,"xmage_ability_classes":["EnchantAbility","SimpleStaticAbility"],"xmage_effect_classes":["AttachEffect","BoostEnchantedEffect"]}'::jsonb, '{"category":"support","effect":"aura_static_attachment","subtype":"aura_static_pump","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class AlphaStatus translated into ManaLoom runtime scope xmage_aura_static_power_toughness_attachment_v1. This row is package-ready only because the source signature is a narrow Aura attachment with static enchanted-creature power/toughness modifier with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('death''s approach', 'Death''s Approach', 'c33040d9c32eb56deeb4d9295862aa7a', 'battle_rule_v1:5893f8937a4b929d2a45bc185d7914f9', '{"ability_kind":"aura_static","attachment_dynamic_boost":true,"aura":true,"battle_model_scope":"xmage_aura_static_power_toughness_attachment_v1","effect":"aura_static_attachment","enchant_target":"creature","enchant_target_controller":"any","graveyard_count_card_types":["creature"],"graveyard_count_scope":"attached_creature_controller_graveyard","instant":false,"power_base_delta":0,"power_boost":0,"power_delta_per_graveyard_count":-1,"sorcery":false,"stat_modifier_amount_source":"graveyard_card_count","static_effect":"attached_creature_power_toughness_boost_equal_count","static_power_bonus":0,"static_toughness_bonus":0,"target":"creature","target_constraints":{"card_types":["creature"],"zone":"battlefield"},"toughness_base_delta":0,"toughness_boost":0,"toughness_delta_per_graveyard_count":-1,"xmage_ability_classes":["EnchantAbility","SimpleStaticAbility"],"xmage_effect_classes":["AttachEffect","BoostEnchantedEffect"]}'::jsonb, '{"category":"support","effect":"aura_static_attachment","subtype":"aura_static_pump","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class DeathsApproach translated into ManaLoom runtime scope xmage_aura_static_power_toughness_attachment_v1. This row is package-ready only because the source signature is a narrow Aura attachment with static enchanted-creature power/toughness modifier with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('exoskeletal armor', 'Exoskeletal Armor', '162e12aada2989c9078456aed98e2095', 'battle_rule_v1:fcc874adc294a491e7ac9a650df1f03e', '{"ability_kind":"aura_static","attachment_dynamic_boost":true,"aura":true,"battle_model_scope":"xmage_aura_static_power_toughness_attachment_v1","effect":"aura_static_attachment","enchant_target":"creature","enchant_target_controller":"any","graveyard_count_card_types":["creature"],"graveyard_count_scope":"all_graveyards","instant":false,"power_base_delta":0,"power_boost":0,"power_delta_per_graveyard_count":1,"sorcery":false,"stat_modifier_amount_source":"graveyard_card_count","static_effect":"attached_creature_power_toughness_boost_equal_count","static_power_bonus":0,"static_toughness_bonus":0,"target":"creature","target_constraints":{"card_types":["creature"],"zone":"battlefield"},"toughness_base_delta":0,"toughness_boost":0,"toughness_delta_per_graveyard_count":1,"xmage_ability_classes":["EnchantAbility","SimpleStaticAbility"],"xmage_effect_classes":["AttachEffect","BoostEnchantedEffect"]}'::jsonb, '{"category":"support","effect":"aura_static_attachment","subtype":"aura_static_pump","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ExoskeletalArmor translated into ManaLoom runtime scope xmage_aura_static_power_toughness_attachment_v1. This row is package-ready only because the source signature is a narrow Aura attachment with static enchanted-creature power/toughness modifier with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('stoneforge masterwork', 'Stoneforge Masterwork', 'dfe3dafdedf9063733f412f35e1c3eab', 'battle_rule_v1:949bd09f92871413f5d3497f1f71389a', '{"ability_kind":"equipment_static","attached_keywords":[],"attachment_dynamic_boost":true,"battle_model_scope":"xmage_equipment_static_power_toughness_attachment_v1","battlefield_count_scope":"controller_battlefield","effect":"equipment_static_attachment","equipment":true,"instant":false,"power_base_delta":0,"power_boost":0,"power_delta_per_graveyard_count":1,"sorcery":false,"stat_modifier_amount_source":"attached_creature_shared_type_count","static_effect":"attached_creature_power_toughness_boost_equal_count","static_power_bonus":0,"static_toughness_bonus":0,"target":"creature_you_control","target_constraints":{"card_types":["creature"],"controller":"self","zone":"battlefield"},"toughness_base_delta":0,"toughness_boost":0,"toughness_delta_per_graveyard_count":1,"xmage_ability_classes":["EquipAbility","SimpleStaticAbility"],"xmage_effect_classes":["BoostEquippedEffect"]}'::jsonb, '{"category":"support","effect":"equipment_static_attachment","subtype":"equipment_static_pump","target":"creature_you_control"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class StoneforgeMasterwork translated into ManaLoom runtime scope xmage_equipment_static_power_toughness_attachment_v1. This row is package-ready only because the source signature is a narrow Equipment attachment with static equipped-creature power/toughness and keyword modifier with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('wreath of geists', 'Wreath of Geists', '6789d58ba0ee8ed5de943dd5ca5a1be1', 'battle_rule_v1:5f327f69a479abce2987fea68bdbb46f', '{"ability_kind":"aura_static","attachment_dynamic_boost":true,"aura":true,"battle_model_scope":"xmage_aura_static_power_toughness_attachment_v1","effect":"aura_static_attachment","enchant_target":"creature","enchant_target_controller":"any","graveyard_count_card_types":["creature"],"graveyard_count_scope":"controller_graveyard","instant":false,"power_base_delta":0,"power_boost":0,"power_delta_per_graveyard_count":1,"sorcery":false,"stat_modifier_amount_source":"graveyard_card_count","static_effect":"attached_creature_power_toughness_boost_equal_count","static_power_bonus":0,"static_toughness_bonus":0,"target":"creature","target_constraints":{"card_types":["creature"],"zone":"battlefield"},"toughness_base_delta":0,"toughness_boost":0,"toughness_delta_per_graveyard_count":1,"xmage_ability_classes":["EnchantAbility","SimpleStaticAbility"],"xmage_effect_classes":["AttachEffect","BoostEnchantedEffect"]}'::jsonb, '{"category":"support","effect":"aura_static_attachment","subtype":"aura_static_pump","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class WreathOfGeists translated into ManaLoom runtime scope xmage_aura_static_power_toughness_attachment_v1. This row is package-ready only because the source signature is a narrow Aura attachment with static enchanted-creature power/toughness modifier with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
    ('alpha status', 'Alpha Status', 'dc2fe49152d99850434f64f24d3b6436', 'battle_rule_v1:4637a9f25fc3d815d44d059da775da61', '{"ability_kind":"aura_static","attachment_dynamic_boost":true,"aura":true,"battle_model_scope":"xmage_aura_static_power_toughness_attachment_v1","battlefield_count_scope":"all_battlefields","effect":"aura_static_attachment","enchant_target":"creature","enchant_target_controller":"any","instant":false,"power_base_delta":0,"power_boost":0,"power_delta_per_graveyard_count":2,"sorcery":false,"stat_modifier_amount_source":"attached_creature_shared_type_count","static_effect":"attached_creature_power_toughness_boost_equal_count","static_power_bonus":0,"static_toughness_bonus":0,"target":"creature","target_constraints":{"card_types":["creature"],"zone":"battlefield"},"toughness_base_delta":0,"toughness_boost":0,"toughness_delta_per_graveyard_count":2,"xmage_ability_classes":["EnchantAbility","SimpleStaticAbility"],"xmage_effect_classes":["AttachEffect","BoostEnchantedEffect"]}'::jsonb, '{"category":"support","effect":"aura_static_attachment","subtype":"aura_static_pump","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class AlphaStatus translated into ManaLoom runtime scope xmage_aura_static_power_toughness_attachment_v1. This row is package-ready only because the source signature is a narrow Aura attachment with static enchanted-creature power/toughness modifier with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('death''s approach', 'Death''s Approach', 'c33040d9c32eb56deeb4d9295862aa7a', 'battle_rule_v1:5893f8937a4b929d2a45bc185d7914f9', '{"ability_kind":"aura_static","attachment_dynamic_boost":true,"aura":true,"battle_model_scope":"xmage_aura_static_power_toughness_attachment_v1","effect":"aura_static_attachment","enchant_target":"creature","enchant_target_controller":"any","graveyard_count_card_types":["creature"],"graveyard_count_scope":"attached_creature_controller_graveyard","instant":false,"power_base_delta":0,"power_boost":0,"power_delta_per_graveyard_count":-1,"sorcery":false,"stat_modifier_amount_source":"graveyard_card_count","static_effect":"attached_creature_power_toughness_boost_equal_count","static_power_bonus":0,"static_toughness_bonus":0,"target":"creature","target_constraints":{"card_types":["creature"],"zone":"battlefield"},"toughness_base_delta":0,"toughness_boost":0,"toughness_delta_per_graveyard_count":-1,"xmage_ability_classes":["EnchantAbility","SimpleStaticAbility"],"xmage_effect_classes":["AttachEffect","BoostEnchantedEffect"]}'::jsonb, '{"category":"support","effect":"aura_static_attachment","subtype":"aura_static_pump","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class DeathsApproach translated into ManaLoom runtime scope xmage_aura_static_power_toughness_attachment_v1. This row is package-ready only because the source signature is a narrow Aura attachment with static enchanted-creature power/toughness modifier with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('exoskeletal armor', 'Exoskeletal Armor', '162e12aada2989c9078456aed98e2095', 'battle_rule_v1:fcc874adc294a491e7ac9a650df1f03e', '{"ability_kind":"aura_static","attachment_dynamic_boost":true,"aura":true,"battle_model_scope":"xmage_aura_static_power_toughness_attachment_v1","effect":"aura_static_attachment","enchant_target":"creature","enchant_target_controller":"any","graveyard_count_card_types":["creature"],"graveyard_count_scope":"all_graveyards","instant":false,"power_base_delta":0,"power_boost":0,"power_delta_per_graveyard_count":1,"sorcery":false,"stat_modifier_amount_source":"graveyard_card_count","static_effect":"attached_creature_power_toughness_boost_equal_count","static_power_bonus":0,"static_toughness_bonus":0,"target":"creature","target_constraints":{"card_types":["creature"],"zone":"battlefield"},"toughness_base_delta":0,"toughness_boost":0,"toughness_delta_per_graveyard_count":1,"xmage_ability_classes":["EnchantAbility","SimpleStaticAbility"],"xmage_effect_classes":["AttachEffect","BoostEnchantedEffect"]}'::jsonb, '{"category":"support","effect":"aura_static_attachment","subtype":"aura_static_pump","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ExoskeletalArmor translated into ManaLoom runtime scope xmage_aura_static_power_toughness_attachment_v1. This row is package-ready only because the source signature is a narrow Aura attachment with static enchanted-creature power/toughness modifier with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('stoneforge masterwork', 'Stoneforge Masterwork', 'dfe3dafdedf9063733f412f35e1c3eab', 'battle_rule_v1:949bd09f92871413f5d3497f1f71389a', '{"ability_kind":"equipment_static","attached_keywords":[],"attachment_dynamic_boost":true,"battle_model_scope":"xmage_equipment_static_power_toughness_attachment_v1","battlefield_count_scope":"controller_battlefield","effect":"equipment_static_attachment","equipment":true,"instant":false,"power_base_delta":0,"power_boost":0,"power_delta_per_graveyard_count":1,"sorcery":false,"stat_modifier_amount_source":"attached_creature_shared_type_count","static_effect":"attached_creature_power_toughness_boost_equal_count","static_power_bonus":0,"static_toughness_bonus":0,"target":"creature_you_control","target_constraints":{"card_types":["creature"],"controller":"self","zone":"battlefield"},"toughness_base_delta":0,"toughness_boost":0,"toughness_delta_per_graveyard_count":1,"xmage_ability_classes":["EquipAbility","SimpleStaticAbility"],"xmage_effect_classes":["BoostEquippedEffect"]}'::jsonb, '{"category":"support","effect":"equipment_static_attachment","subtype":"equipment_static_pump","target":"creature_you_control"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class StoneforgeMasterwork translated into ManaLoom runtime scope xmage_equipment_static_power_toughness_attachment_v1. This row is package-ready only because the source signature is a narrow Equipment attachment with static equipped-creature power/toughness and keyword modifier with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('wreath of geists', 'Wreath of Geists', '6789d58ba0ee8ed5de943dd5ca5a1be1', 'battle_rule_v1:5f327f69a479abce2987fea68bdbb46f', '{"ability_kind":"aura_static","attachment_dynamic_boost":true,"aura":true,"battle_model_scope":"xmage_aura_static_power_toughness_attachment_v1","effect":"aura_static_attachment","enchant_target":"creature","enchant_target_controller":"any","graveyard_count_card_types":["creature"],"graveyard_count_scope":"controller_graveyard","instant":false,"power_base_delta":0,"power_boost":0,"power_delta_per_graveyard_count":1,"sorcery":false,"stat_modifier_amount_source":"graveyard_card_count","static_effect":"attached_creature_power_toughness_boost_equal_count","static_power_bonus":0,"static_toughness_bonus":0,"target":"creature","target_constraints":{"card_types":["creature"],"zone":"battlefield"},"toughness_base_delta":0,"toughness_boost":0,"toughness_delta_per_graveyard_count":1,"xmage_ability_classes":["EnchantAbility","SimpleStaticAbility"],"xmage_effect_classes":["AttachEffect","BoostEnchantedEffect"]}'::jsonb, '{"category":"support","effect":"aura_static_attachment","subtype":"aura_static_pump","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class WreathOfGeists translated into ManaLoom runtime scope xmage_aura_static_power_toughness_attachment_v1. This row is package-ready only because the source signature is a narrow Aura attachment with static enchanted-creature power/toughness modifier with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
    ('alpha status', 'Alpha Status', 'dc2fe49152d99850434f64f24d3b6436', 'battle_rule_v1:4637a9f25fc3d815d44d059da775da61', '{"ability_kind":"aura_static","attachment_dynamic_boost":true,"aura":true,"battle_model_scope":"xmage_aura_static_power_toughness_attachment_v1","battlefield_count_scope":"all_battlefields","effect":"aura_static_attachment","enchant_target":"creature","enchant_target_controller":"any","instant":false,"power_base_delta":0,"power_boost":0,"power_delta_per_graveyard_count":2,"sorcery":false,"stat_modifier_amount_source":"attached_creature_shared_type_count","static_effect":"attached_creature_power_toughness_boost_equal_count","static_power_bonus":0,"static_toughness_bonus":0,"target":"creature","target_constraints":{"card_types":["creature"],"zone":"battlefield"},"toughness_base_delta":0,"toughness_boost":0,"toughness_delta_per_graveyard_count":2,"xmage_ability_classes":["EnchantAbility","SimpleStaticAbility"],"xmage_effect_classes":["AttachEffect","BoostEnchantedEffect"]}'::jsonb, '{"category":"support","effect":"aura_static_attachment","subtype":"aura_static_pump","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class AlphaStatus translated into ManaLoom runtime scope xmage_aura_static_power_toughness_attachment_v1. This row is package-ready only because the source signature is a narrow Aura attachment with static enchanted-creature power/toughness modifier with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('death''s approach', 'Death''s Approach', 'c33040d9c32eb56deeb4d9295862aa7a', 'battle_rule_v1:5893f8937a4b929d2a45bc185d7914f9', '{"ability_kind":"aura_static","attachment_dynamic_boost":true,"aura":true,"battle_model_scope":"xmage_aura_static_power_toughness_attachment_v1","effect":"aura_static_attachment","enchant_target":"creature","enchant_target_controller":"any","graveyard_count_card_types":["creature"],"graveyard_count_scope":"attached_creature_controller_graveyard","instant":false,"power_base_delta":0,"power_boost":0,"power_delta_per_graveyard_count":-1,"sorcery":false,"stat_modifier_amount_source":"graveyard_card_count","static_effect":"attached_creature_power_toughness_boost_equal_count","static_power_bonus":0,"static_toughness_bonus":0,"target":"creature","target_constraints":{"card_types":["creature"],"zone":"battlefield"},"toughness_base_delta":0,"toughness_boost":0,"toughness_delta_per_graveyard_count":-1,"xmage_ability_classes":["EnchantAbility","SimpleStaticAbility"],"xmage_effect_classes":["AttachEffect","BoostEnchantedEffect"]}'::jsonb, '{"category":"support","effect":"aura_static_attachment","subtype":"aura_static_pump","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class DeathsApproach translated into ManaLoom runtime scope xmage_aura_static_power_toughness_attachment_v1. This row is package-ready only because the source signature is a narrow Aura attachment with static enchanted-creature power/toughness modifier with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('exoskeletal armor', 'Exoskeletal Armor', '162e12aada2989c9078456aed98e2095', 'battle_rule_v1:fcc874adc294a491e7ac9a650df1f03e', '{"ability_kind":"aura_static","attachment_dynamic_boost":true,"aura":true,"battle_model_scope":"xmage_aura_static_power_toughness_attachment_v1","effect":"aura_static_attachment","enchant_target":"creature","enchant_target_controller":"any","graveyard_count_card_types":["creature"],"graveyard_count_scope":"all_graveyards","instant":false,"power_base_delta":0,"power_boost":0,"power_delta_per_graveyard_count":1,"sorcery":false,"stat_modifier_amount_source":"graveyard_card_count","static_effect":"attached_creature_power_toughness_boost_equal_count","static_power_bonus":0,"static_toughness_bonus":0,"target":"creature","target_constraints":{"card_types":["creature"],"zone":"battlefield"},"toughness_base_delta":0,"toughness_boost":0,"toughness_delta_per_graveyard_count":1,"xmage_ability_classes":["EnchantAbility","SimpleStaticAbility"],"xmage_effect_classes":["AttachEffect","BoostEnchantedEffect"]}'::jsonb, '{"category":"support","effect":"aura_static_attachment","subtype":"aura_static_pump","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ExoskeletalArmor translated into ManaLoom runtime scope xmage_aura_static_power_toughness_attachment_v1. This row is package-ready only because the source signature is a narrow Aura attachment with static enchanted-creature power/toughness modifier with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('stoneforge masterwork', 'Stoneforge Masterwork', 'dfe3dafdedf9063733f412f35e1c3eab', 'battle_rule_v1:949bd09f92871413f5d3497f1f71389a', '{"ability_kind":"equipment_static","attached_keywords":[],"attachment_dynamic_boost":true,"battle_model_scope":"xmage_equipment_static_power_toughness_attachment_v1","battlefield_count_scope":"controller_battlefield","effect":"equipment_static_attachment","equipment":true,"instant":false,"power_base_delta":0,"power_boost":0,"power_delta_per_graveyard_count":1,"sorcery":false,"stat_modifier_amount_source":"attached_creature_shared_type_count","static_effect":"attached_creature_power_toughness_boost_equal_count","static_power_bonus":0,"static_toughness_bonus":0,"target":"creature_you_control","target_constraints":{"card_types":["creature"],"controller":"self","zone":"battlefield"},"toughness_base_delta":0,"toughness_boost":0,"toughness_delta_per_graveyard_count":1,"xmage_ability_classes":["EquipAbility","SimpleStaticAbility"],"xmage_effect_classes":["BoostEquippedEffect"]}'::jsonb, '{"category":"support","effect":"equipment_static_attachment","subtype":"equipment_static_pump","target":"creature_you_control"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class StoneforgeMasterwork translated into ManaLoom runtime scope xmage_equipment_static_power_toughness_attachment_v1. This row is package-ready only because the source signature is a narrow Equipment attachment with static equipped-creature power/toughness and keyword modifier with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('wreath of geists', 'Wreath of Geists', '6789d58ba0ee8ed5de943dd5ca5a1be1', 'battle_rule_v1:5f327f69a479abce2987fea68bdbb46f', '{"ability_kind":"aura_static","attachment_dynamic_boost":true,"aura":true,"battle_model_scope":"xmage_aura_static_power_toughness_attachment_v1","effect":"aura_static_attachment","enchant_target":"creature","enchant_target_controller":"any","graveyard_count_card_types":["creature"],"graveyard_count_scope":"controller_graveyard","instant":false,"power_base_delta":0,"power_boost":0,"power_delta_per_graveyard_count":1,"sorcery":false,"stat_modifier_amount_source":"graveyard_card_count","static_effect":"attached_creature_power_toughness_boost_equal_count","static_power_bonus":0,"static_toughness_bonus":0,"target":"creature","target_constraints":{"card_types":["creature"],"zone":"battlefield"},"toughness_base_delta":0,"toughness_boost":0,"toughness_delta_per_graveyard_count":1,"xmage_ability_classes":["EnchantAbility","SimpleStaticAbility"],"xmage_effect_classes":["AttachEffect","BoostEnchantedEffect"]}'::jsonb, '{"category":"support","effect":"aura_static_attachment","subtype":"aura_static_pump","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class WreathOfGeists translated into ManaLoom runtime scope xmage_aura_static_power_toughness_attachment_v1. This row is package-ready only because the source signature is a narrow Aura attachment with static enchanted-creature power/toughness modifier with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
