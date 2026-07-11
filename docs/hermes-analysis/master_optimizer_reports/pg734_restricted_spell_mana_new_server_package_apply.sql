BEGIN;

CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit;

CREATE TABLE IF NOT EXISTS manaloom_deploy_audit.pg734_restricted_spell_mana_new_server_20260711_021310 AS
SELECT *
FROM public.card_battle_rules
WHERE normalized_name IN ('beastcaller savant', 'curious homunculus // voracious reader', 'herd heirloom', 'humble naturalist', 'ore-rich stalactite // cosmium catalyst', 'pelargir survivor', 'vodalian arcanist')
   OR normalized_name LIKE 'beastcaller savant // %'
   OR normalized_name LIKE 'curious homunculus // voracious reader // %'
   OR normalized_name LIKE 'herd heirloom // %'
   OR normalized_name LIKE 'humble naturalist // %'
   OR normalized_name LIKE 'ore-rich stalactite // cosmium catalyst // %'
   OR normalized_name LIKE 'pelargir survivor // %'
   OR normalized_name LIKE 'vodalian arcanist // %';

DO $$
DECLARE
  v_missing jsonb;
BEGIN
  WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('beastcaller savant', 'Beastcaller Savant', '377d469bc5133f822592179495484481', 'battle_rule_v1:4e1ac64b55d5a6a30387c9e4960a297b', '{"_keywords_are_self":true,"ability_kind":"activated_mana","activation_requires_tap":true,"battle_model_scope":"xmage_simple_tap_restricted_mana_source_permanent_v1","conditional_mana_modes":[{"color":"W","mode":"restricted_spell_mana","restriction":"creature_spell","status":"runtime_executor_v1"},{"color":"U","mode":"restricted_spell_mana","restriction":"creature_spell","status":"runtime_executor_v1"},{"color":"B","mode":"restricted_spell_mana","restriction":"creature_spell","status":"runtime_executor_v1"},{"color":"R","mode":"restricted_spell_mana","restriction":"creature_spell","status":"runtime_executor_v1"},{"color":"G","mode":"restricted_spell_mana","restriction":"creature_spell","status":"runtime_executor_v1"}],"conditional_mana_modes_status":"runtime_executor_v1","effect":"ramp_permanent","is_mana_source":true,"keywords":["haste"],"mana_activation_requires_tap":true,"mana_produced":1,"permanent_type":"creature","produces":"WUBRG","xmage_ability_classes":["ConditionalAnyColorManaAbility","HasteAbility"],"xmage_effect_classes":[],"xmage_mana_ability_classes":["ConditionalAnyColorManaAbility"]}'::jsonb, '{"category":"ramp","effect":"ramp_permanent"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class BeastcallerSavant translated into ManaLoom runtime scope xmage_simple_tap_restricted_mana_source_permanent_v1. This row is package-ready only because the source signature is a narrow activated mana-source permanent with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('curious homunculus // voracious reader', 'Curious Homunculus // Voracious Reader', '29dca779d4d43708b0dc1a0d599e306f', 'battle_rule_v1:4c4569da91ea463c145f9409f3ff8f67', '{"ability_kind":"activated_mana","activation_requires_tap":true,"battle_model_scope":"xmage_simple_tap_restricted_mana_source_permanent_v1","conditional_mana_modes":[{"color":"C","mode":"restricted_spell_mana","restriction":"instant_or_sorcery_spell","status":"runtime_executor_v1"}],"conditional_mana_modes_status":"runtime_executor_v1","effect":"ramp_permanent","is_mana_source":true,"mana_activation_requires_tap":true,"mana_produced":1,"permanent_type":"creature","produced_mana_symbols":["C"],"produces":"C","xmage_ability_classes":["BeginningOfUpkeepTriggeredAbility","ConditionalColorlessManaAbility","ProwessAbility","SimpleStaticAbility"],"xmage_effect_classes":["SpellsCostReductionControllerEffect","TransformSourceEffect"],"xmage_mana_ability_classes":["ConditionalColorlessManaAbility"]}'::jsonb, '{"category":"ramp","effect":"ramp_permanent"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class CuriousHomunculus translated into ManaLoom runtime scope xmage_simple_tap_restricted_mana_source_permanent_v1. This row is package-ready only because the source signature is a narrow activated mana-source permanent with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('herd heirloom', 'Herd Heirloom', 'f02a5af674eb306b322e0583e61952d5', 'battle_rule_v1:2980bcca26e2eb39bbe1fc936cf1a6ad', '{"_keywords_are_self":true,"ability_kind":"activated_mana","activation_requires_tap":true,"battle_model_scope":"xmage_simple_tap_restricted_mana_source_permanent_v1","conditional_mana_modes":[{"color":"W","mode":"restricted_spell_mana","restriction":"creature_spell","status":"runtime_executor_v1"},{"color":"U","mode":"restricted_spell_mana","restriction":"creature_spell","status":"runtime_executor_v1"},{"color":"B","mode":"restricted_spell_mana","restriction":"creature_spell","status":"runtime_executor_v1"},{"color":"R","mode":"restricted_spell_mana","restriction":"creature_spell","status":"runtime_executor_v1"},{"color":"G","mode":"restricted_spell_mana","restriction":"creature_spell","status":"runtime_executor_v1"}],"conditional_mana_modes_status":"runtime_executor_v1","effect":"ramp_permanent","is_mana_source":true,"keywords":["trample"],"mana_activation_requires_tap":true,"mana_produced":1,"permanent_type":"artifact","produces":"WUBRG","xmage_ability_classes":["ConditionalAnyColorManaAbility","DealsCombatDamageToAPlayerTriggeredAbility","SimpleActivatedAbility","TrampleAbility"],"xmage_effect_classes":["DrawCardSourceControllerEffect","GainAbilityTargetEffect"],"xmage_mana_ability_classes":["ConditionalAnyColorManaAbility"]}'::jsonb, '{"category":"ramp","effect":"ramp_permanent"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class HerdHeirloom translated into ManaLoom runtime scope xmage_simple_tap_restricted_mana_source_permanent_v1. This row is package-ready only because the source signature is a narrow activated mana-source permanent with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('humble naturalist', 'Humble Naturalist', '4db6d51e675ae38af560e0dd2eea4cf0', 'battle_rule_v1:02baef79930a6020aa304e70017ac47f', '{"ability_kind":"activated_mana","activation_requires_tap":true,"battle_model_scope":"xmage_simple_tap_restricted_mana_source_permanent_v1","conditional_mana_modes":[{"color":"W","mode":"restricted_spell_mana","restriction":"creature_spell","status":"runtime_executor_v1"},{"color":"U","mode":"restricted_spell_mana","restriction":"creature_spell","status":"runtime_executor_v1"},{"color":"B","mode":"restricted_spell_mana","restriction":"creature_spell","status":"runtime_executor_v1"},{"color":"R","mode":"restricted_spell_mana","restriction":"creature_spell","status":"runtime_executor_v1"},{"color":"G","mode":"restricted_spell_mana","restriction":"creature_spell","status":"runtime_executor_v1"}],"conditional_mana_modes_status":"runtime_executor_v1","effect":"ramp_permanent","is_mana_source":true,"mana_activation_requires_tap":true,"mana_produced":1,"permanent_type":"creature","produces":"WUBRG","xmage_ability_classes":["ConditionalAnyColorManaAbility"],"xmage_effect_classes":[],"xmage_mana_ability_classes":["ConditionalAnyColorManaAbility"]}'::jsonb, '{"category":"ramp","effect":"ramp_permanent"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class HumbleNaturalist translated into ManaLoom runtime scope xmage_simple_tap_restricted_mana_source_permanent_v1. This row is package-ready only because the source signature is a narrow activated mana-source permanent with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('ore-rich stalactite // cosmium catalyst', 'Ore-Rich Stalactite // Cosmium Catalyst', 'fdd3a3210d203f4d462e824002d87a05', 'battle_rule_v1:d6089d7e6f331bab1d12cdbc67cedcf8', '{"ability_kind":"activated_mana","activation_requires_tap":true,"battle_model_scope":"xmage_simple_tap_restricted_mana_source_permanent_v1","conditional_mana_modes":[{"color":"R","mode":"restricted_spell_mana","restriction":"instant_or_sorcery_spell","status":"runtime_executor_v1"}],"conditional_mana_modes_status":"runtime_executor_v1","effect":"ramp_permanent","is_mana_source":true,"mana_activation_requires_tap":true,"mana_produced":1,"permanent_type":"artifact","produced_mana_symbols":["R"],"produces":"R","xmage_ability_classes":["ConditionalColoredManaAbility","CraftAbility","SimpleActivatedAbility"],"xmage_effect_classes":["CosmiumCatalystEffect","OneShotEffect"],"xmage_mana_ability_classes":["ConditionalColoredManaAbility"]}'::jsonb, '{"category":"ramp","effect":"ramp_permanent"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class OreRichStalactite translated into ManaLoom runtime scope xmage_simple_tap_restricted_mana_source_permanent_v1. This row is package-ready only because the source signature is a narrow activated mana-source permanent with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('pelargir survivor', 'Pelargir Survivor', '3a0f5cdb5f344e9fbda22cf5696f439c', 'battle_rule_v1:74cea72a465b0a2b93ba9caced259133', '{"ability_kind":"activated_mana","activation_requires_tap":true,"battle_model_scope":"xmage_simple_tap_restricted_mana_source_permanent_v1","conditional_mana_modes":[{"color":"W","mode":"restricted_spell_mana","restriction":"instant_or_sorcery_spell","status":"runtime_executor_v1"},{"color":"U","mode":"restricted_spell_mana","restriction":"instant_or_sorcery_spell","status":"runtime_executor_v1"},{"color":"B","mode":"restricted_spell_mana","restriction":"instant_or_sorcery_spell","status":"runtime_executor_v1"},{"color":"R","mode":"restricted_spell_mana","restriction":"instant_or_sorcery_spell","status":"runtime_executor_v1"},{"color":"G","mode":"restricted_spell_mana","restriction":"instant_or_sorcery_spell","status":"runtime_executor_v1"}],"conditional_mana_modes_status":"runtime_executor_v1","effect":"ramp_permanent","is_mana_source":true,"mana_activation_requires_tap":true,"mana_produced":1,"permanent_type":"creature","produces":"WUBRG","xmage_ability_classes":["ConditionalAnyColorManaAbility","SimpleActivatedAbility"],"xmage_effect_classes":["MillCardsTargetEffect"],"xmage_mana_ability_classes":["ConditionalAnyColorManaAbility"]}'::jsonb, '{"category":"ramp","effect":"ramp_permanent"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class PelargirSurvivor translated into ManaLoom runtime scope xmage_simple_tap_restricted_mana_source_permanent_v1. This row is package-ready only because the source signature is a narrow activated mana-source permanent with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('vodalian arcanist', 'Vodalian Arcanist', '9be7040c01ffd0f87b7152ae9064475c', 'battle_rule_v1:aaac34c3bb4f25a401d62975f76373f2', '{"ability_kind":"activated_mana","activation_requires_tap":true,"battle_model_scope":"xmage_simple_tap_restricted_mana_source_permanent_v1","conditional_mana_modes":[{"color":"C","mode":"restricted_spell_mana","restriction":"instant_or_sorcery_spell","status":"runtime_executor_v1"}],"conditional_mana_modes_status":"runtime_executor_v1","effect":"ramp_permanent","is_mana_source":true,"mana_activation_requires_tap":true,"mana_produced":1,"permanent_type":"creature","produced_mana_symbols":["C"],"produces":"C","xmage_ability_classes":["ConditionalColorlessManaAbility"],"xmage_effect_classes":[],"xmage_mana_ability_classes":["ConditionalColorlessManaAbility"]}'::jsonb, '{"category":"ramp","effect":"ramp_permanent"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class VodalianArcanist translated into ManaLoom runtime scope xmage_simple_tap_restricted_mana_source_permanent_v1. This row is package-ready only because the source signature is a narrow activated mana-source permanent with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
    ('beastcaller savant', 'Beastcaller Savant', '377d469bc5133f822592179495484481', 'battle_rule_v1:4e1ac64b55d5a6a30387c9e4960a297b', '{"_keywords_are_self":true,"ability_kind":"activated_mana","activation_requires_tap":true,"battle_model_scope":"xmage_simple_tap_restricted_mana_source_permanent_v1","conditional_mana_modes":[{"color":"W","mode":"restricted_spell_mana","restriction":"creature_spell","status":"runtime_executor_v1"},{"color":"U","mode":"restricted_spell_mana","restriction":"creature_spell","status":"runtime_executor_v1"},{"color":"B","mode":"restricted_spell_mana","restriction":"creature_spell","status":"runtime_executor_v1"},{"color":"R","mode":"restricted_spell_mana","restriction":"creature_spell","status":"runtime_executor_v1"},{"color":"G","mode":"restricted_spell_mana","restriction":"creature_spell","status":"runtime_executor_v1"}],"conditional_mana_modes_status":"runtime_executor_v1","effect":"ramp_permanent","is_mana_source":true,"keywords":["haste"],"mana_activation_requires_tap":true,"mana_produced":1,"permanent_type":"creature","produces":"WUBRG","xmage_ability_classes":["ConditionalAnyColorManaAbility","HasteAbility"],"xmage_effect_classes":[],"xmage_mana_ability_classes":["ConditionalAnyColorManaAbility"]}'::jsonb, '{"category":"ramp","effect":"ramp_permanent"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class BeastcallerSavant translated into ManaLoom runtime scope xmage_simple_tap_restricted_mana_source_permanent_v1. This row is package-ready only because the source signature is a narrow activated mana-source permanent with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('curious homunculus // voracious reader', 'Curious Homunculus // Voracious Reader', '29dca779d4d43708b0dc1a0d599e306f', 'battle_rule_v1:4c4569da91ea463c145f9409f3ff8f67', '{"ability_kind":"activated_mana","activation_requires_tap":true,"battle_model_scope":"xmage_simple_tap_restricted_mana_source_permanent_v1","conditional_mana_modes":[{"color":"C","mode":"restricted_spell_mana","restriction":"instant_or_sorcery_spell","status":"runtime_executor_v1"}],"conditional_mana_modes_status":"runtime_executor_v1","effect":"ramp_permanent","is_mana_source":true,"mana_activation_requires_tap":true,"mana_produced":1,"permanent_type":"creature","produced_mana_symbols":["C"],"produces":"C","xmage_ability_classes":["BeginningOfUpkeepTriggeredAbility","ConditionalColorlessManaAbility","ProwessAbility","SimpleStaticAbility"],"xmage_effect_classes":["SpellsCostReductionControllerEffect","TransformSourceEffect"],"xmage_mana_ability_classes":["ConditionalColorlessManaAbility"]}'::jsonb, '{"category":"ramp","effect":"ramp_permanent"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class CuriousHomunculus translated into ManaLoom runtime scope xmage_simple_tap_restricted_mana_source_permanent_v1. This row is package-ready only because the source signature is a narrow activated mana-source permanent with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('herd heirloom', 'Herd Heirloom', 'f02a5af674eb306b322e0583e61952d5', 'battle_rule_v1:2980bcca26e2eb39bbe1fc936cf1a6ad', '{"_keywords_are_self":true,"ability_kind":"activated_mana","activation_requires_tap":true,"battle_model_scope":"xmage_simple_tap_restricted_mana_source_permanent_v1","conditional_mana_modes":[{"color":"W","mode":"restricted_spell_mana","restriction":"creature_spell","status":"runtime_executor_v1"},{"color":"U","mode":"restricted_spell_mana","restriction":"creature_spell","status":"runtime_executor_v1"},{"color":"B","mode":"restricted_spell_mana","restriction":"creature_spell","status":"runtime_executor_v1"},{"color":"R","mode":"restricted_spell_mana","restriction":"creature_spell","status":"runtime_executor_v1"},{"color":"G","mode":"restricted_spell_mana","restriction":"creature_spell","status":"runtime_executor_v1"}],"conditional_mana_modes_status":"runtime_executor_v1","effect":"ramp_permanent","is_mana_source":true,"keywords":["trample"],"mana_activation_requires_tap":true,"mana_produced":1,"permanent_type":"artifact","produces":"WUBRG","xmage_ability_classes":["ConditionalAnyColorManaAbility","DealsCombatDamageToAPlayerTriggeredAbility","SimpleActivatedAbility","TrampleAbility"],"xmage_effect_classes":["DrawCardSourceControllerEffect","GainAbilityTargetEffect"],"xmage_mana_ability_classes":["ConditionalAnyColorManaAbility"]}'::jsonb, '{"category":"ramp","effect":"ramp_permanent"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class HerdHeirloom translated into ManaLoom runtime scope xmage_simple_tap_restricted_mana_source_permanent_v1. This row is package-ready only because the source signature is a narrow activated mana-source permanent with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('humble naturalist', 'Humble Naturalist', '4db6d51e675ae38af560e0dd2eea4cf0', 'battle_rule_v1:02baef79930a6020aa304e70017ac47f', '{"ability_kind":"activated_mana","activation_requires_tap":true,"battle_model_scope":"xmage_simple_tap_restricted_mana_source_permanent_v1","conditional_mana_modes":[{"color":"W","mode":"restricted_spell_mana","restriction":"creature_spell","status":"runtime_executor_v1"},{"color":"U","mode":"restricted_spell_mana","restriction":"creature_spell","status":"runtime_executor_v1"},{"color":"B","mode":"restricted_spell_mana","restriction":"creature_spell","status":"runtime_executor_v1"},{"color":"R","mode":"restricted_spell_mana","restriction":"creature_spell","status":"runtime_executor_v1"},{"color":"G","mode":"restricted_spell_mana","restriction":"creature_spell","status":"runtime_executor_v1"}],"conditional_mana_modes_status":"runtime_executor_v1","effect":"ramp_permanent","is_mana_source":true,"mana_activation_requires_tap":true,"mana_produced":1,"permanent_type":"creature","produces":"WUBRG","xmage_ability_classes":["ConditionalAnyColorManaAbility"],"xmage_effect_classes":[],"xmage_mana_ability_classes":["ConditionalAnyColorManaAbility"]}'::jsonb, '{"category":"ramp","effect":"ramp_permanent"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class HumbleNaturalist translated into ManaLoom runtime scope xmage_simple_tap_restricted_mana_source_permanent_v1. This row is package-ready only because the source signature is a narrow activated mana-source permanent with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('ore-rich stalactite // cosmium catalyst', 'Ore-Rich Stalactite // Cosmium Catalyst', 'fdd3a3210d203f4d462e824002d87a05', 'battle_rule_v1:d6089d7e6f331bab1d12cdbc67cedcf8', '{"ability_kind":"activated_mana","activation_requires_tap":true,"battle_model_scope":"xmage_simple_tap_restricted_mana_source_permanent_v1","conditional_mana_modes":[{"color":"R","mode":"restricted_spell_mana","restriction":"instant_or_sorcery_spell","status":"runtime_executor_v1"}],"conditional_mana_modes_status":"runtime_executor_v1","effect":"ramp_permanent","is_mana_source":true,"mana_activation_requires_tap":true,"mana_produced":1,"permanent_type":"artifact","produced_mana_symbols":["R"],"produces":"R","xmage_ability_classes":["ConditionalColoredManaAbility","CraftAbility","SimpleActivatedAbility"],"xmage_effect_classes":["CosmiumCatalystEffect","OneShotEffect"],"xmage_mana_ability_classes":["ConditionalColoredManaAbility"]}'::jsonb, '{"category":"ramp","effect":"ramp_permanent"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class OreRichStalactite translated into ManaLoom runtime scope xmage_simple_tap_restricted_mana_source_permanent_v1. This row is package-ready only because the source signature is a narrow activated mana-source permanent with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('pelargir survivor', 'Pelargir Survivor', '3a0f5cdb5f344e9fbda22cf5696f439c', 'battle_rule_v1:74cea72a465b0a2b93ba9caced259133', '{"ability_kind":"activated_mana","activation_requires_tap":true,"battle_model_scope":"xmage_simple_tap_restricted_mana_source_permanent_v1","conditional_mana_modes":[{"color":"W","mode":"restricted_spell_mana","restriction":"instant_or_sorcery_spell","status":"runtime_executor_v1"},{"color":"U","mode":"restricted_spell_mana","restriction":"instant_or_sorcery_spell","status":"runtime_executor_v1"},{"color":"B","mode":"restricted_spell_mana","restriction":"instant_or_sorcery_spell","status":"runtime_executor_v1"},{"color":"R","mode":"restricted_spell_mana","restriction":"instant_or_sorcery_spell","status":"runtime_executor_v1"},{"color":"G","mode":"restricted_spell_mana","restriction":"instant_or_sorcery_spell","status":"runtime_executor_v1"}],"conditional_mana_modes_status":"runtime_executor_v1","effect":"ramp_permanent","is_mana_source":true,"mana_activation_requires_tap":true,"mana_produced":1,"permanent_type":"creature","produces":"WUBRG","xmage_ability_classes":["ConditionalAnyColorManaAbility","SimpleActivatedAbility"],"xmage_effect_classes":["MillCardsTargetEffect"],"xmage_mana_ability_classes":["ConditionalAnyColorManaAbility"]}'::jsonb, '{"category":"ramp","effect":"ramp_permanent"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class PelargirSurvivor translated into ManaLoom runtime scope xmage_simple_tap_restricted_mana_source_permanent_v1. This row is package-ready only because the source signature is a narrow activated mana-source permanent with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('vodalian arcanist', 'Vodalian Arcanist', '9be7040c01ffd0f87b7152ae9064475c', 'battle_rule_v1:aaac34c3bb4f25a401d62975f76373f2', '{"ability_kind":"activated_mana","activation_requires_tap":true,"battle_model_scope":"xmage_simple_tap_restricted_mana_source_permanent_v1","conditional_mana_modes":[{"color":"C","mode":"restricted_spell_mana","restriction":"instant_or_sorcery_spell","status":"runtime_executor_v1"}],"conditional_mana_modes_status":"runtime_executor_v1","effect":"ramp_permanent","is_mana_source":true,"mana_activation_requires_tap":true,"mana_produced":1,"permanent_type":"creature","produced_mana_symbols":["C"],"produces":"C","xmage_ability_classes":["ConditionalColorlessManaAbility"],"xmage_effect_classes":[],"xmage_mana_ability_classes":["ConditionalColorlessManaAbility"]}'::jsonb, '{"category":"ramp","effect":"ramp_permanent"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class VodalianArcanist translated into ManaLoom runtime scope xmage_simple_tap_restricted_mana_source_permanent_v1. This row is package-ready only because the source signature is a narrow activated mana-source permanent with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
    ('beastcaller savant', 'Beastcaller Savant', '377d469bc5133f822592179495484481', 'battle_rule_v1:4e1ac64b55d5a6a30387c9e4960a297b', '{"_keywords_are_self":true,"ability_kind":"activated_mana","activation_requires_tap":true,"battle_model_scope":"xmage_simple_tap_restricted_mana_source_permanent_v1","conditional_mana_modes":[{"color":"W","mode":"restricted_spell_mana","restriction":"creature_spell","status":"runtime_executor_v1"},{"color":"U","mode":"restricted_spell_mana","restriction":"creature_spell","status":"runtime_executor_v1"},{"color":"B","mode":"restricted_spell_mana","restriction":"creature_spell","status":"runtime_executor_v1"},{"color":"R","mode":"restricted_spell_mana","restriction":"creature_spell","status":"runtime_executor_v1"},{"color":"G","mode":"restricted_spell_mana","restriction":"creature_spell","status":"runtime_executor_v1"}],"conditional_mana_modes_status":"runtime_executor_v1","effect":"ramp_permanent","is_mana_source":true,"keywords":["haste"],"mana_activation_requires_tap":true,"mana_produced":1,"permanent_type":"creature","produces":"WUBRG","xmage_ability_classes":["ConditionalAnyColorManaAbility","HasteAbility"],"xmage_effect_classes":[],"xmage_mana_ability_classes":["ConditionalAnyColorManaAbility"]}'::jsonb, '{"category":"ramp","effect":"ramp_permanent"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class BeastcallerSavant translated into ManaLoom runtime scope xmage_simple_tap_restricted_mana_source_permanent_v1. This row is package-ready only because the source signature is a narrow activated mana-source permanent with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('curious homunculus // voracious reader', 'Curious Homunculus // Voracious Reader', '29dca779d4d43708b0dc1a0d599e306f', 'battle_rule_v1:4c4569da91ea463c145f9409f3ff8f67', '{"ability_kind":"activated_mana","activation_requires_tap":true,"battle_model_scope":"xmage_simple_tap_restricted_mana_source_permanent_v1","conditional_mana_modes":[{"color":"C","mode":"restricted_spell_mana","restriction":"instant_or_sorcery_spell","status":"runtime_executor_v1"}],"conditional_mana_modes_status":"runtime_executor_v1","effect":"ramp_permanent","is_mana_source":true,"mana_activation_requires_tap":true,"mana_produced":1,"permanent_type":"creature","produced_mana_symbols":["C"],"produces":"C","xmage_ability_classes":["BeginningOfUpkeepTriggeredAbility","ConditionalColorlessManaAbility","ProwessAbility","SimpleStaticAbility"],"xmage_effect_classes":["SpellsCostReductionControllerEffect","TransformSourceEffect"],"xmage_mana_ability_classes":["ConditionalColorlessManaAbility"]}'::jsonb, '{"category":"ramp","effect":"ramp_permanent"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class CuriousHomunculus translated into ManaLoom runtime scope xmage_simple_tap_restricted_mana_source_permanent_v1. This row is package-ready only because the source signature is a narrow activated mana-source permanent with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('herd heirloom', 'Herd Heirloom', 'f02a5af674eb306b322e0583e61952d5', 'battle_rule_v1:2980bcca26e2eb39bbe1fc936cf1a6ad', '{"_keywords_are_self":true,"ability_kind":"activated_mana","activation_requires_tap":true,"battle_model_scope":"xmage_simple_tap_restricted_mana_source_permanent_v1","conditional_mana_modes":[{"color":"W","mode":"restricted_spell_mana","restriction":"creature_spell","status":"runtime_executor_v1"},{"color":"U","mode":"restricted_spell_mana","restriction":"creature_spell","status":"runtime_executor_v1"},{"color":"B","mode":"restricted_spell_mana","restriction":"creature_spell","status":"runtime_executor_v1"},{"color":"R","mode":"restricted_spell_mana","restriction":"creature_spell","status":"runtime_executor_v1"},{"color":"G","mode":"restricted_spell_mana","restriction":"creature_spell","status":"runtime_executor_v1"}],"conditional_mana_modes_status":"runtime_executor_v1","effect":"ramp_permanent","is_mana_source":true,"keywords":["trample"],"mana_activation_requires_tap":true,"mana_produced":1,"permanent_type":"artifact","produces":"WUBRG","xmage_ability_classes":["ConditionalAnyColorManaAbility","DealsCombatDamageToAPlayerTriggeredAbility","SimpleActivatedAbility","TrampleAbility"],"xmage_effect_classes":["DrawCardSourceControllerEffect","GainAbilityTargetEffect"],"xmage_mana_ability_classes":["ConditionalAnyColorManaAbility"]}'::jsonb, '{"category":"ramp","effect":"ramp_permanent"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class HerdHeirloom translated into ManaLoom runtime scope xmage_simple_tap_restricted_mana_source_permanent_v1. This row is package-ready only because the source signature is a narrow activated mana-source permanent with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('humble naturalist', 'Humble Naturalist', '4db6d51e675ae38af560e0dd2eea4cf0', 'battle_rule_v1:02baef79930a6020aa304e70017ac47f', '{"ability_kind":"activated_mana","activation_requires_tap":true,"battle_model_scope":"xmage_simple_tap_restricted_mana_source_permanent_v1","conditional_mana_modes":[{"color":"W","mode":"restricted_spell_mana","restriction":"creature_spell","status":"runtime_executor_v1"},{"color":"U","mode":"restricted_spell_mana","restriction":"creature_spell","status":"runtime_executor_v1"},{"color":"B","mode":"restricted_spell_mana","restriction":"creature_spell","status":"runtime_executor_v1"},{"color":"R","mode":"restricted_spell_mana","restriction":"creature_spell","status":"runtime_executor_v1"},{"color":"G","mode":"restricted_spell_mana","restriction":"creature_spell","status":"runtime_executor_v1"}],"conditional_mana_modes_status":"runtime_executor_v1","effect":"ramp_permanent","is_mana_source":true,"mana_activation_requires_tap":true,"mana_produced":1,"permanent_type":"creature","produces":"WUBRG","xmage_ability_classes":["ConditionalAnyColorManaAbility"],"xmage_effect_classes":[],"xmage_mana_ability_classes":["ConditionalAnyColorManaAbility"]}'::jsonb, '{"category":"ramp","effect":"ramp_permanent"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class HumbleNaturalist translated into ManaLoom runtime scope xmage_simple_tap_restricted_mana_source_permanent_v1. This row is package-ready only because the source signature is a narrow activated mana-source permanent with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('ore-rich stalactite // cosmium catalyst', 'Ore-Rich Stalactite // Cosmium Catalyst', 'fdd3a3210d203f4d462e824002d87a05', 'battle_rule_v1:d6089d7e6f331bab1d12cdbc67cedcf8', '{"ability_kind":"activated_mana","activation_requires_tap":true,"battle_model_scope":"xmage_simple_tap_restricted_mana_source_permanent_v1","conditional_mana_modes":[{"color":"R","mode":"restricted_spell_mana","restriction":"instant_or_sorcery_spell","status":"runtime_executor_v1"}],"conditional_mana_modes_status":"runtime_executor_v1","effect":"ramp_permanent","is_mana_source":true,"mana_activation_requires_tap":true,"mana_produced":1,"permanent_type":"artifact","produced_mana_symbols":["R"],"produces":"R","xmage_ability_classes":["ConditionalColoredManaAbility","CraftAbility","SimpleActivatedAbility"],"xmage_effect_classes":["CosmiumCatalystEffect","OneShotEffect"],"xmage_mana_ability_classes":["ConditionalColoredManaAbility"]}'::jsonb, '{"category":"ramp","effect":"ramp_permanent"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class OreRichStalactite translated into ManaLoom runtime scope xmage_simple_tap_restricted_mana_source_permanent_v1. This row is package-ready only because the source signature is a narrow activated mana-source permanent with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('pelargir survivor', 'Pelargir Survivor', '3a0f5cdb5f344e9fbda22cf5696f439c', 'battle_rule_v1:74cea72a465b0a2b93ba9caced259133', '{"ability_kind":"activated_mana","activation_requires_tap":true,"battle_model_scope":"xmage_simple_tap_restricted_mana_source_permanent_v1","conditional_mana_modes":[{"color":"W","mode":"restricted_spell_mana","restriction":"instant_or_sorcery_spell","status":"runtime_executor_v1"},{"color":"U","mode":"restricted_spell_mana","restriction":"instant_or_sorcery_spell","status":"runtime_executor_v1"},{"color":"B","mode":"restricted_spell_mana","restriction":"instant_or_sorcery_spell","status":"runtime_executor_v1"},{"color":"R","mode":"restricted_spell_mana","restriction":"instant_or_sorcery_spell","status":"runtime_executor_v1"},{"color":"G","mode":"restricted_spell_mana","restriction":"instant_or_sorcery_spell","status":"runtime_executor_v1"}],"conditional_mana_modes_status":"runtime_executor_v1","effect":"ramp_permanent","is_mana_source":true,"mana_activation_requires_tap":true,"mana_produced":1,"permanent_type":"creature","produces":"WUBRG","xmage_ability_classes":["ConditionalAnyColorManaAbility","SimpleActivatedAbility"],"xmage_effect_classes":["MillCardsTargetEffect"],"xmage_mana_ability_classes":["ConditionalAnyColorManaAbility"]}'::jsonb, '{"category":"ramp","effect":"ramp_permanent"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class PelargirSurvivor translated into ManaLoom runtime scope xmage_simple_tap_restricted_mana_source_permanent_v1. This row is package-ready only because the source signature is a narrow activated mana-source permanent with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('vodalian arcanist', 'Vodalian Arcanist', '9be7040c01ffd0f87b7152ae9064475c', 'battle_rule_v1:aaac34c3bb4f25a401d62975f76373f2', '{"ability_kind":"activated_mana","activation_requires_tap":true,"battle_model_scope":"xmage_simple_tap_restricted_mana_source_permanent_v1","conditional_mana_modes":[{"color":"C","mode":"restricted_spell_mana","restriction":"instant_or_sorcery_spell","status":"runtime_executor_v1"}],"conditional_mana_modes_status":"runtime_executor_v1","effect":"ramp_permanent","is_mana_source":true,"mana_activation_requires_tap":true,"mana_produced":1,"permanent_type":"creature","produced_mana_symbols":["C"],"produces":"C","xmage_ability_classes":["ConditionalColorlessManaAbility"],"xmage_effect_classes":[],"xmage_mana_ability_classes":["ConditionalColorlessManaAbility"]}'::jsonb, '{"category":"ramp","effect":"ramp_permanent"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class VodalianArcanist translated into ManaLoom runtime scope xmage_simple_tap_restricted_mana_source_permanent_v1. This row is package-ready only because the source signature is a narrow activated mana-source permanent with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
