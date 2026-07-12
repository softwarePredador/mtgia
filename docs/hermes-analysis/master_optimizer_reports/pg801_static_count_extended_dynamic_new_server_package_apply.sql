BEGIN;

CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit;

CREATE TABLE IF NOT EXISTS manaloom_deploy_audit.pg801_static_count_extended_dynamic_new_20260712_022103 AS
SELECT *
FROM public.card_battle_rules
WHERE normalized_name IN ('abomination of llanowar', 'ancient ooze', 'awakened amalgam', 'primalcrux', 'soulless one', 'umbra stalker')
   OR normalized_name LIKE 'abomination of llanowar // %'
   OR normalized_name LIKE 'ancient ooze // %'
   OR normalized_name LIKE 'awakened amalgam // %'
   OR normalized_name LIKE 'primalcrux // %'
   OR normalized_name LIKE 'soulless one // %'
   OR normalized_name LIKE 'umbra stalker // %';

DO $$
DECLARE
  v_missing jsonb;
BEGIN
  WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('abomination of llanowar', 'Abomination of Llanowar', '4369101d94df2d8a510929acece13a32', 'battle_rule_v1:f86e9800757429d1b29f53915ec39e66', '{"_keywords_are_self":true,"ability_kind":"static","battle_model_scope":"xmage_static_source_power_toughness_equal_count_v1","battlefield_count_scope":"controller_battlefield","battlefield_count_subtypes":["elf"],"dynamic_power_equals_count":true,"dynamic_toughness_equals_count":true,"effect":"creature","graveyard_count_scope":"controller_graveyard","graveyard_count_subtypes":["elf"],"keywords":["menace","vigilance"],"menace":true,"stat_modifier_amount_source":"battlefield_plus_graveyard_subtype_count","static_effect":"source_power_toughness_equal_count","static_power_toughness_base":0,"static_power_toughness_count_multiplier":1,"static_power_toughness_source":"battlefield_plus_graveyard_subtype_count","target":"self","target_controller":"self","vigilance":true,"xmage_ability_class":"SimpleStaticAbility","xmage_effect_class":"SetBasePowerToughnessSourceEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class AbominationOfLlanowar translated into ManaLoom runtime scope xmage_static_source_power_toughness_equal_count_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('ancient ooze', 'Ancient Ooze', '05c8e65c443eace35db8b0fe1c27e7c8', 'battle_rule_v1:ef16f012ac351b877136c28bf84ac65d', '{"ability_kind":"static","battle_model_scope":"xmage_static_source_power_toughness_equal_count_v1","dynamic_power_equals_count":true,"dynamic_toughness_equals_count":true,"effect":"creature","stat_modifier_amount_source":"controlled_other_creature_total_mana_value","static_effect":"source_power_toughness_equal_count","static_power_toughness_base":0,"static_power_toughness_count_multiplier":1,"static_power_toughness_source":"controlled_other_creature_total_mana_value","target":"self","target_controller":"self","xmage_ability_class":"SimpleStaticAbility","xmage_effect_class":"SetBasePowerToughnessSourceEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class AncientOoze translated into ManaLoom runtime scope xmage_static_source_power_toughness_equal_count_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('awakened amalgam', 'Awakened Amalgam', 'adc7ce3ba484ac86e31f40d9bce8525f', 'battle_rule_v1:d00c4f5b57c8ca15b2a0a2f5f4b4eef4', '{"ability_kind":"static","battle_model_scope":"xmage_static_source_power_toughness_equal_count_v1","dynamic_power_equals_count":true,"dynamic_toughness_equals_count":true,"effect":"creature","stat_modifier_amount_source":"controlled_differently_named_lands","static_effect":"source_power_toughness_equal_count","static_power_toughness_base":0,"static_power_toughness_count_multiplier":1,"static_power_toughness_source":"controlled_differently_named_lands","target":"self","target_controller":"self","xmage_ability_class":"SimpleStaticAbility","xmage_effect_class":"SetBasePowerToughnessSourceEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class AwakenedAmalgam translated into ManaLoom runtime scope xmage_static_source_power_toughness_equal_count_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('primalcrux', 'Primalcrux', '98a3b9241e25afda9ee301f9a9a80937', 'battle_rule_v1:4c92b16bdb2a167171cc97020ed1289c', '{"_keywords_are_self":true,"ability_kind":"static","battle_model_scope":"xmage_static_source_power_toughness_equal_count_v1","dynamic_power_equals_count":true,"dynamic_toughness_equals_count":true,"effect":"creature","keywords":["trample"],"mana_symbol_count_color":"G","stat_modifier_amount_source":"controlled_permanents_mana_symbol_count","static_effect":"source_power_toughness_equal_count","static_power_toughness_base":0,"static_power_toughness_count_multiplier":1,"static_power_toughness_source":"controlled_permanents_mana_symbol_count","target":"self","target_controller":"self","trample":true,"xmage_ability_class":"SimpleStaticAbility","xmage_effect_class":"SetBasePowerToughnessSourceEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Primalcrux translated into ManaLoom runtime scope xmage_static_source_power_toughness_equal_count_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('soulless one', 'Soulless One', 'c2e594a0255824f7a65055ab845734ab', 'battle_rule_v1:abf9427e5a216be774dde789bc3821d8', '{"ability_kind":"static","battle_model_scope":"xmage_static_source_power_toughness_equal_count_v1","battlefield_count_scope":"all_battlefields","battlefield_count_subtypes":["zombie"],"dynamic_power_equals_count":true,"dynamic_toughness_equals_count":true,"effect":"creature","graveyard_count_scope":"all_graveyards","graveyard_count_subtypes":["zombie"],"stat_modifier_amount_source":"battlefield_plus_graveyard_subtype_count","static_effect":"source_power_toughness_equal_count","static_power_toughness_base":0,"static_power_toughness_count_multiplier":1,"static_power_toughness_source":"battlefield_plus_graveyard_subtype_count","target":"self","target_controller":"self","xmage_ability_class":"SimpleStaticAbility","xmage_effect_class":"SetBasePowerToughnessSourceEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class SoullessOne translated into ManaLoom runtime scope xmage_static_source_power_toughness_equal_count_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('umbra stalker', 'Umbra Stalker', 'e489972d1aaf696902097ee1dcda4935', 'battle_rule_v1:9575252a3e1c527a7597d6d28de6b93a', '{"ability_kind":"static","battle_model_scope":"xmage_static_source_power_toughness_equal_count_v1","dynamic_power_equals_count":true,"dynamic_toughness_equals_count":true,"effect":"creature","mana_symbol_count_color":"B","stat_modifier_amount_source":"controller_graveyard_mana_symbol_count","static_effect":"source_power_toughness_equal_count","static_power_toughness_base":0,"static_power_toughness_count_multiplier":1,"static_power_toughness_source":"controller_graveyard_mana_symbol_count","target":"self","target_controller":"self","xmage_ability_class":"SimpleStaticAbility","xmage_effect_class":"SetBasePowerToughnessSourceEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class UmbraStalker translated into ManaLoom runtime scope xmage_static_source_power_toughness_equal_count_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
    ('abomination of llanowar', 'Abomination of Llanowar', '4369101d94df2d8a510929acece13a32', 'battle_rule_v1:f86e9800757429d1b29f53915ec39e66', '{"_keywords_are_self":true,"ability_kind":"static","battle_model_scope":"xmage_static_source_power_toughness_equal_count_v1","battlefield_count_scope":"controller_battlefield","battlefield_count_subtypes":["elf"],"dynamic_power_equals_count":true,"dynamic_toughness_equals_count":true,"effect":"creature","graveyard_count_scope":"controller_graveyard","graveyard_count_subtypes":["elf"],"keywords":["menace","vigilance"],"menace":true,"stat_modifier_amount_source":"battlefield_plus_graveyard_subtype_count","static_effect":"source_power_toughness_equal_count","static_power_toughness_base":0,"static_power_toughness_count_multiplier":1,"static_power_toughness_source":"battlefield_plus_graveyard_subtype_count","target":"self","target_controller":"self","vigilance":true,"xmage_ability_class":"SimpleStaticAbility","xmage_effect_class":"SetBasePowerToughnessSourceEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class AbominationOfLlanowar translated into ManaLoom runtime scope xmage_static_source_power_toughness_equal_count_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('ancient ooze', 'Ancient Ooze', '05c8e65c443eace35db8b0fe1c27e7c8', 'battle_rule_v1:ef16f012ac351b877136c28bf84ac65d', '{"ability_kind":"static","battle_model_scope":"xmage_static_source_power_toughness_equal_count_v1","dynamic_power_equals_count":true,"dynamic_toughness_equals_count":true,"effect":"creature","stat_modifier_amount_source":"controlled_other_creature_total_mana_value","static_effect":"source_power_toughness_equal_count","static_power_toughness_base":0,"static_power_toughness_count_multiplier":1,"static_power_toughness_source":"controlled_other_creature_total_mana_value","target":"self","target_controller":"self","xmage_ability_class":"SimpleStaticAbility","xmage_effect_class":"SetBasePowerToughnessSourceEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class AncientOoze translated into ManaLoom runtime scope xmage_static_source_power_toughness_equal_count_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('awakened amalgam', 'Awakened Amalgam', 'adc7ce3ba484ac86e31f40d9bce8525f', 'battle_rule_v1:d00c4f5b57c8ca15b2a0a2f5f4b4eef4', '{"ability_kind":"static","battle_model_scope":"xmage_static_source_power_toughness_equal_count_v1","dynamic_power_equals_count":true,"dynamic_toughness_equals_count":true,"effect":"creature","stat_modifier_amount_source":"controlled_differently_named_lands","static_effect":"source_power_toughness_equal_count","static_power_toughness_base":0,"static_power_toughness_count_multiplier":1,"static_power_toughness_source":"controlled_differently_named_lands","target":"self","target_controller":"self","xmage_ability_class":"SimpleStaticAbility","xmage_effect_class":"SetBasePowerToughnessSourceEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class AwakenedAmalgam translated into ManaLoom runtime scope xmage_static_source_power_toughness_equal_count_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('primalcrux', 'Primalcrux', '98a3b9241e25afda9ee301f9a9a80937', 'battle_rule_v1:4c92b16bdb2a167171cc97020ed1289c', '{"_keywords_are_self":true,"ability_kind":"static","battle_model_scope":"xmage_static_source_power_toughness_equal_count_v1","dynamic_power_equals_count":true,"dynamic_toughness_equals_count":true,"effect":"creature","keywords":["trample"],"mana_symbol_count_color":"G","stat_modifier_amount_source":"controlled_permanents_mana_symbol_count","static_effect":"source_power_toughness_equal_count","static_power_toughness_base":0,"static_power_toughness_count_multiplier":1,"static_power_toughness_source":"controlled_permanents_mana_symbol_count","target":"self","target_controller":"self","trample":true,"xmage_ability_class":"SimpleStaticAbility","xmage_effect_class":"SetBasePowerToughnessSourceEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Primalcrux translated into ManaLoom runtime scope xmage_static_source_power_toughness_equal_count_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('soulless one', 'Soulless One', 'c2e594a0255824f7a65055ab845734ab', 'battle_rule_v1:abf9427e5a216be774dde789bc3821d8', '{"ability_kind":"static","battle_model_scope":"xmage_static_source_power_toughness_equal_count_v1","battlefield_count_scope":"all_battlefields","battlefield_count_subtypes":["zombie"],"dynamic_power_equals_count":true,"dynamic_toughness_equals_count":true,"effect":"creature","graveyard_count_scope":"all_graveyards","graveyard_count_subtypes":["zombie"],"stat_modifier_amount_source":"battlefield_plus_graveyard_subtype_count","static_effect":"source_power_toughness_equal_count","static_power_toughness_base":0,"static_power_toughness_count_multiplier":1,"static_power_toughness_source":"battlefield_plus_graveyard_subtype_count","target":"self","target_controller":"self","xmage_ability_class":"SimpleStaticAbility","xmage_effect_class":"SetBasePowerToughnessSourceEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class SoullessOne translated into ManaLoom runtime scope xmage_static_source_power_toughness_equal_count_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('umbra stalker', 'Umbra Stalker', 'e489972d1aaf696902097ee1dcda4935', 'battle_rule_v1:9575252a3e1c527a7597d6d28de6b93a', '{"ability_kind":"static","battle_model_scope":"xmage_static_source_power_toughness_equal_count_v1","dynamic_power_equals_count":true,"dynamic_toughness_equals_count":true,"effect":"creature","mana_symbol_count_color":"B","stat_modifier_amount_source":"controller_graveyard_mana_symbol_count","static_effect":"source_power_toughness_equal_count","static_power_toughness_base":0,"static_power_toughness_count_multiplier":1,"static_power_toughness_source":"controller_graveyard_mana_symbol_count","target":"self","target_controller":"self","xmage_ability_class":"SimpleStaticAbility","xmage_effect_class":"SetBasePowerToughnessSourceEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class UmbraStalker translated into ManaLoom runtime scope xmage_static_source_power_toughness_equal_count_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
    ('abomination of llanowar', 'Abomination of Llanowar', '4369101d94df2d8a510929acece13a32', 'battle_rule_v1:f86e9800757429d1b29f53915ec39e66', '{"_keywords_are_self":true,"ability_kind":"static","battle_model_scope":"xmage_static_source_power_toughness_equal_count_v1","battlefield_count_scope":"controller_battlefield","battlefield_count_subtypes":["elf"],"dynamic_power_equals_count":true,"dynamic_toughness_equals_count":true,"effect":"creature","graveyard_count_scope":"controller_graveyard","graveyard_count_subtypes":["elf"],"keywords":["menace","vigilance"],"menace":true,"stat_modifier_amount_source":"battlefield_plus_graveyard_subtype_count","static_effect":"source_power_toughness_equal_count","static_power_toughness_base":0,"static_power_toughness_count_multiplier":1,"static_power_toughness_source":"battlefield_plus_graveyard_subtype_count","target":"self","target_controller":"self","vigilance":true,"xmage_ability_class":"SimpleStaticAbility","xmage_effect_class":"SetBasePowerToughnessSourceEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class AbominationOfLlanowar translated into ManaLoom runtime scope xmage_static_source_power_toughness_equal_count_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('ancient ooze', 'Ancient Ooze', '05c8e65c443eace35db8b0fe1c27e7c8', 'battle_rule_v1:ef16f012ac351b877136c28bf84ac65d', '{"ability_kind":"static","battle_model_scope":"xmage_static_source_power_toughness_equal_count_v1","dynamic_power_equals_count":true,"dynamic_toughness_equals_count":true,"effect":"creature","stat_modifier_amount_source":"controlled_other_creature_total_mana_value","static_effect":"source_power_toughness_equal_count","static_power_toughness_base":0,"static_power_toughness_count_multiplier":1,"static_power_toughness_source":"controlled_other_creature_total_mana_value","target":"self","target_controller":"self","xmage_ability_class":"SimpleStaticAbility","xmage_effect_class":"SetBasePowerToughnessSourceEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class AncientOoze translated into ManaLoom runtime scope xmage_static_source_power_toughness_equal_count_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('awakened amalgam', 'Awakened Amalgam', 'adc7ce3ba484ac86e31f40d9bce8525f', 'battle_rule_v1:d00c4f5b57c8ca15b2a0a2f5f4b4eef4', '{"ability_kind":"static","battle_model_scope":"xmage_static_source_power_toughness_equal_count_v1","dynamic_power_equals_count":true,"dynamic_toughness_equals_count":true,"effect":"creature","stat_modifier_amount_source":"controlled_differently_named_lands","static_effect":"source_power_toughness_equal_count","static_power_toughness_base":0,"static_power_toughness_count_multiplier":1,"static_power_toughness_source":"controlled_differently_named_lands","target":"self","target_controller":"self","xmage_ability_class":"SimpleStaticAbility","xmage_effect_class":"SetBasePowerToughnessSourceEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class AwakenedAmalgam translated into ManaLoom runtime scope xmage_static_source_power_toughness_equal_count_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('primalcrux', 'Primalcrux', '98a3b9241e25afda9ee301f9a9a80937', 'battle_rule_v1:4c92b16bdb2a167171cc97020ed1289c', '{"_keywords_are_self":true,"ability_kind":"static","battle_model_scope":"xmage_static_source_power_toughness_equal_count_v1","dynamic_power_equals_count":true,"dynamic_toughness_equals_count":true,"effect":"creature","keywords":["trample"],"mana_symbol_count_color":"G","stat_modifier_amount_source":"controlled_permanents_mana_symbol_count","static_effect":"source_power_toughness_equal_count","static_power_toughness_base":0,"static_power_toughness_count_multiplier":1,"static_power_toughness_source":"controlled_permanents_mana_symbol_count","target":"self","target_controller":"self","trample":true,"xmage_ability_class":"SimpleStaticAbility","xmage_effect_class":"SetBasePowerToughnessSourceEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Primalcrux translated into ManaLoom runtime scope xmage_static_source_power_toughness_equal_count_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('soulless one', 'Soulless One', 'c2e594a0255824f7a65055ab845734ab', 'battle_rule_v1:abf9427e5a216be774dde789bc3821d8', '{"ability_kind":"static","battle_model_scope":"xmage_static_source_power_toughness_equal_count_v1","battlefield_count_scope":"all_battlefields","battlefield_count_subtypes":["zombie"],"dynamic_power_equals_count":true,"dynamic_toughness_equals_count":true,"effect":"creature","graveyard_count_scope":"all_graveyards","graveyard_count_subtypes":["zombie"],"stat_modifier_amount_source":"battlefield_plus_graveyard_subtype_count","static_effect":"source_power_toughness_equal_count","static_power_toughness_base":0,"static_power_toughness_count_multiplier":1,"static_power_toughness_source":"battlefield_plus_graveyard_subtype_count","target":"self","target_controller":"self","xmage_ability_class":"SimpleStaticAbility","xmage_effect_class":"SetBasePowerToughnessSourceEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class SoullessOne translated into ManaLoom runtime scope xmage_static_source_power_toughness_equal_count_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('umbra stalker', 'Umbra Stalker', 'e489972d1aaf696902097ee1dcda4935', 'battle_rule_v1:9575252a3e1c527a7597d6d28de6b93a', '{"ability_kind":"static","battle_model_scope":"xmage_static_source_power_toughness_equal_count_v1","dynamic_power_equals_count":true,"dynamic_toughness_equals_count":true,"effect":"creature","mana_symbol_count_color":"B","stat_modifier_amount_source":"controller_graveyard_mana_symbol_count","static_effect":"source_power_toughness_equal_count","static_power_toughness_base":0,"static_power_toughness_count_multiplier":1,"static_power_toughness_source":"controller_graveyard_mana_symbol_count","target":"self","target_controller":"self","xmage_ability_class":"SimpleStaticAbility","xmage_effect_class":"SetBasePowerToughnessSourceEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class UmbraStalker translated into ManaLoom runtime scope xmage_static_source_power_toughness_equal_count_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
