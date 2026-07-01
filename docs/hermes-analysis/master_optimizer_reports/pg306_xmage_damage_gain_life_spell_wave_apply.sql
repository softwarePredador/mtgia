BEGIN;

CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit;

CREATE TABLE manaloom_deploy_audit.pg306_xmage_damage_gain_life_spell_wave_20260701_125800 AS
SELECT *
FROM public.card_battle_rules
WHERE normalized_name IN ('agonizing syphon', 'dark nourishment', 'defibrillating current', 'douse in gloom', 'essence drain', 'essence extraction', 'last kiss', 'pharika''s cure', 'sorin''s thirst', 'vampiric feast', 'vicious hunger', 'warleader''s helix', 'winter''s intervention')
   OR normalized_name LIKE 'agonizing syphon // %'
   OR normalized_name LIKE 'dark nourishment // %'
   OR normalized_name LIKE 'defibrillating current // %'
   OR normalized_name LIKE 'douse in gloom // %'
   OR normalized_name LIKE 'essence drain // %'
   OR normalized_name LIKE 'essence extraction // %'
   OR normalized_name LIKE 'last kiss // %'
   OR normalized_name LIKE 'pharika''s cure // %'
   OR normalized_name LIKE 'sorin''s thirst // %'
   OR normalized_name LIKE 'vampiric feast // %'
   OR normalized_name LIKE 'vicious hunger // %'
   OR normalized_name LIKE 'warleader''s helix // %'
   OR normalized_name LIKE 'winter''s intervention // %';

DO $$
DECLARE
  v_missing jsonb;
BEGIN
  WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('agonizing syphon', 'Agonizing Syphon', 'bb99dc3202d60eebefd671ebb94d5fdd', 'battle_rule_v1:c1efa9874143362f23fce5bed164f104', '{"amount":3,"battle_model_scope":"xmage_fixed_damage_target_and_controller_gain_life_spell_v1","controller_gain_life":3,"damage":3,"effect":"direct_damage","gain_life":3,"instant":false,"sorcery":true,"target":"any_target","target_constraints":{"scope":"any_target"},"xmage_effect_classes":["DamageTargetEffect","GainLifeEffect"]}'::jsonb, '{"category":"unknown","effect":"direct_damage","target":"any_target"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class AgonizingSyphon translated into ManaLoom runtime scope xmage_fixed_damage_target_and_controller_gain_life_spell_v1. This row is package-ready only because the source signature is a narrow fixed damage plus controller life-gain spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('dark nourishment', 'Dark Nourishment', '9ad9181ce8b6bf194df67591eba0005d', 'battle_rule_v1:029f28307ce7b3b6c69a0d41cc7deab2', '{"amount":3,"battle_model_scope":"xmage_fixed_damage_target_and_controller_gain_life_spell_v1","controller_gain_life":3,"damage":3,"effect":"direct_damage","gain_life":3,"instant":true,"sorcery":false,"target":"any_target","target_constraints":{"scope":"any_target"},"xmage_effect_classes":["DamageTargetEffect","GainLifeEffect"]}'::jsonb, '{"category":"unknown","effect":"direct_damage","target":"any_target","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class DarkNourishment translated into ManaLoom runtime scope xmage_fixed_damage_target_and_controller_gain_life_spell_v1. This row is package-ready only because the source signature is a narrow fixed damage plus controller life-gain spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('defibrillating current', 'Defibrillating Current', '32b8aad46992cb58b5cfae49735140ca', 'battle_rule_v1:8b75e08deb84e2d0e42ca28533f68bea', '{"amount":4,"battle_model_scope":"xmage_fixed_damage_target_and_controller_gain_life_spell_v1","controller_gain_life":2,"damage":4,"effect":"direct_damage","gain_life":2,"instant":false,"sorcery":true,"target":"creature_or_planeswalker","target_constraints":{"card_types":["creature","planeswalker"]},"xmage_effect_classes":["DamageTargetEffect","GainLifeEffect"]}'::jsonb, '{"category":"unknown","effect":"direct_damage","target":"creature_or_planeswalker"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class DefibrillatingCurrent translated into ManaLoom runtime scope xmage_fixed_damage_target_and_controller_gain_life_spell_v1. This row is package-ready only because the source signature is a narrow fixed damage plus controller life-gain spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('douse in gloom', 'Douse in Gloom', '790b89d001d4612f47355b6eaa3c4090', 'battle_rule_v1:788f7c2c874671de1271b7435856eb66', '{"amount":2,"battle_model_scope":"xmage_fixed_damage_target_and_controller_gain_life_spell_v1","controller_gain_life":2,"damage":2,"effect":"direct_damage","gain_life":2,"instant":true,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"]},"xmage_effect_classes":["DamageTargetEffect","GainLifeEffect"]}'::jsonb, '{"category":"unknown","effect":"direct_damage","target":"creature","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class DouseInGloom translated into ManaLoom runtime scope xmage_fixed_damage_target_and_controller_gain_life_spell_v1. This row is package-ready only because the source signature is a narrow fixed damage plus controller life-gain spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('essence drain', 'Essence Drain', 'f7797f346011287d89fbfc7663670476', 'battle_rule_v1:c1efa9874143362f23fce5bed164f104', '{"amount":3,"battle_model_scope":"xmage_fixed_damage_target_and_controller_gain_life_spell_v1","controller_gain_life":3,"damage":3,"effect":"direct_damage","gain_life":3,"instant":false,"sorcery":true,"target":"any_target","target_constraints":{"scope":"any_target"},"xmage_effect_classes":["DamageTargetEffect","GainLifeEffect"]}'::jsonb, '{"category":"unknown","effect":"direct_damage","target":"any_target"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class EssenceDrain translated into ManaLoom runtime scope xmage_fixed_damage_target_and_controller_gain_life_spell_v1. This row is package-ready only because the source signature is a narrow fixed damage plus controller life-gain spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('essence extraction', 'Essence Extraction', 'd96959f3a27de4e120c64de80c6a9aaa', 'battle_rule_v1:fd24ff97747cfcb1638dbf9636156765', '{"amount":3,"battle_model_scope":"xmage_fixed_damage_target_and_controller_gain_life_spell_v1","controller_gain_life":3,"damage":3,"effect":"direct_damage","gain_life":3,"instant":true,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"]},"xmage_effect_classes":["DamageTargetEffect","GainLifeEffect"]}'::jsonb, '{"category":"unknown","effect":"direct_damage","target":"creature","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class EssenceExtraction translated into ManaLoom runtime scope xmage_fixed_damage_target_and_controller_gain_life_spell_v1. This row is package-ready only because the source signature is a narrow fixed damage plus controller life-gain spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('last kiss', 'Last Kiss', '2b9469002ffd3fc0a880f6f8c3c0cf19', 'battle_rule_v1:788f7c2c874671de1271b7435856eb66', '{"amount":2,"battle_model_scope":"xmage_fixed_damage_target_and_controller_gain_life_spell_v1","controller_gain_life":2,"damage":2,"effect":"direct_damage","gain_life":2,"instant":true,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"]},"xmage_effect_classes":["DamageTargetEffect","GainLifeEffect"]}'::jsonb, '{"category":"unknown","effect":"direct_damage","target":"creature","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class LastKiss translated into ManaLoom runtime scope xmage_fixed_damage_target_and_controller_gain_life_spell_v1. This row is package-ready only because the source signature is a narrow fixed damage plus controller life-gain spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('pharika''s cure', 'Pharika''s Cure', '4a9e7997580341e5bcf6dd7fd9c1e887', 'battle_rule_v1:788f7c2c874671de1271b7435856eb66', '{"amount":2,"battle_model_scope":"xmage_fixed_damage_target_and_controller_gain_life_spell_v1","controller_gain_life":2,"damage":2,"effect":"direct_damage","gain_life":2,"instant":true,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"]},"xmage_effect_classes":["DamageTargetEffect","GainLifeEffect"]}'::jsonb, '{"category":"unknown","effect":"direct_damage","target":"creature","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class PharikasCure translated into ManaLoom runtime scope xmage_fixed_damage_target_and_controller_gain_life_spell_v1. This row is package-ready only because the source signature is a narrow fixed damage plus controller life-gain spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('sorin''s thirst', 'Sorin''s Thirst', '1e54bf29b16bbc69cf01b968ef142778', 'battle_rule_v1:788f7c2c874671de1271b7435856eb66', '{"amount":2,"battle_model_scope":"xmage_fixed_damage_target_and_controller_gain_life_spell_v1","controller_gain_life":2,"damage":2,"effect":"direct_damage","gain_life":2,"instant":true,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"]},"xmage_effect_classes":["DamageTargetEffect","GainLifeEffect"]}'::jsonb, '{"category":"unknown","effect":"direct_damage","target":"creature","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class SorinsThirst translated into ManaLoom runtime scope xmage_fixed_damage_target_and_controller_gain_life_spell_v1. This row is package-ready only because the source signature is a narrow fixed damage plus controller life-gain spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('vampiric feast', 'Vampiric Feast', 'b395d91294a22cd813bfe27939364c56', 'battle_rule_v1:1d56c7af6c995b8069895ee5a393b1b5', '{"amount":4,"battle_model_scope":"xmage_fixed_damage_target_and_controller_gain_life_spell_v1","controller_gain_life":4,"damage":4,"effect":"direct_damage","gain_life":4,"instant":false,"sorcery":true,"target":"any_target","target_constraints":{"scope":"any_target"},"xmage_effect_classes":["DamageTargetEffect","GainLifeEffect"]}'::jsonb, '{"category":"unknown","effect":"direct_damage","target":"any_target"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class VampiricFeast translated into ManaLoom runtime scope xmage_fixed_damage_target_and_controller_gain_life_spell_v1. This row is package-ready only because the source signature is a narrow fixed damage plus controller life-gain spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('vicious hunger', 'Vicious Hunger', '0d8c6360af4725e1e185f7d7c48e0596', 'battle_rule_v1:afdcaac9d85814160b0c5bdc9cad24ed', '{"amount":2,"battle_model_scope":"xmage_fixed_damage_target_and_controller_gain_life_spell_v1","controller_gain_life":2,"damage":2,"effect":"direct_damage","gain_life":2,"instant":false,"sorcery":true,"target":"creature","target_constraints":{"card_types":["creature"]},"xmage_effect_classes":["DamageTargetEffect","GainLifeEffect"]}'::jsonb, '{"category":"unknown","effect":"direct_damage","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ViciousHunger translated into ManaLoom runtime scope xmage_fixed_damage_target_and_controller_gain_life_spell_v1. This row is package-ready only because the source signature is a narrow fixed damage plus controller life-gain spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('warleader''s helix', 'Warleader''s Helix', '70dd7a07d63e3c7d3705cf0efdb341d6', 'battle_rule_v1:b30ee9a5fcd603703d248235230ed80f', '{"amount":4,"battle_model_scope":"xmage_fixed_damage_target_and_controller_gain_life_spell_v1","controller_gain_life":4,"damage":4,"effect":"direct_damage","gain_life":4,"instant":true,"sorcery":false,"target":"any_target","target_constraints":{"scope":"any_target"},"xmage_effect_classes":["DamageTargetEffect","GainLifeEffect"]}'::jsonb, '{"category":"unknown","effect":"direct_damage","target":"any_target","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class WarleadersHelix translated into ManaLoom runtime scope xmage_fixed_damage_target_and_controller_gain_life_spell_v1. This row is package-ready only because the source signature is a narrow fixed damage plus controller life-gain spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('winter''s intervention', 'Winter''s Intervention', '6a5018c20fad5c79a5f827f693574a27', 'battle_rule_v1:788f7c2c874671de1271b7435856eb66', '{"amount":2,"battle_model_scope":"xmage_fixed_damage_target_and_controller_gain_life_spell_v1","controller_gain_life":2,"damage":2,"effect":"direct_damage","gain_life":2,"instant":true,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"]},"xmage_effect_classes":["DamageTargetEffect","GainLifeEffect"]}'::jsonb, '{"category":"unknown","effect":"direct_damage","target":"creature","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class WintersIntervention translated into ManaLoom runtime scope xmage_fixed_damage_target_and_controller_gain_life_spell_v1. This row is package-ready only because the source signature is a narrow fixed damage plus controller life-gain spell with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
    ('agonizing syphon', 'Agonizing Syphon', 'bb99dc3202d60eebefd671ebb94d5fdd', 'battle_rule_v1:c1efa9874143362f23fce5bed164f104', '{"amount":3,"battle_model_scope":"xmage_fixed_damage_target_and_controller_gain_life_spell_v1","controller_gain_life":3,"damage":3,"effect":"direct_damage","gain_life":3,"instant":false,"sorcery":true,"target":"any_target","target_constraints":{"scope":"any_target"},"xmage_effect_classes":["DamageTargetEffect","GainLifeEffect"]}'::jsonb, '{"category":"unknown","effect":"direct_damage","target":"any_target"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class AgonizingSyphon translated into ManaLoom runtime scope xmage_fixed_damage_target_and_controller_gain_life_spell_v1. This row is package-ready only because the source signature is a narrow fixed damage plus controller life-gain spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('dark nourishment', 'Dark Nourishment', '9ad9181ce8b6bf194df67591eba0005d', 'battle_rule_v1:029f28307ce7b3b6c69a0d41cc7deab2', '{"amount":3,"battle_model_scope":"xmage_fixed_damage_target_and_controller_gain_life_spell_v1","controller_gain_life":3,"damage":3,"effect":"direct_damage","gain_life":3,"instant":true,"sorcery":false,"target":"any_target","target_constraints":{"scope":"any_target"},"xmage_effect_classes":["DamageTargetEffect","GainLifeEffect"]}'::jsonb, '{"category":"unknown","effect":"direct_damage","target":"any_target","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class DarkNourishment translated into ManaLoom runtime scope xmage_fixed_damage_target_and_controller_gain_life_spell_v1. This row is package-ready only because the source signature is a narrow fixed damage plus controller life-gain spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('defibrillating current', 'Defibrillating Current', '32b8aad46992cb58b5cfae49735140ca', 'battle_rule_v1:8b75e08deb84e2d0e42ca28533f68bea', '{"amount":4,"battle_model_scope":"xmage_fixed_damage_target_and_controller_gain_life_spell_v1","controller_gain_life":2,"damage":4,"effect":"direct_damage","gain_life":2,"instant":false,"sorcery":true,"target":"creature_or_planeswalker","target_constraints":{"card_types":["creature","planeswalker"]},"xmage_effect_classes":["DamageTargetEffect","GainLifeEffect"]}'::jsonb, '{"category":"unknown","effect":"direct_damage","target":"creature_or_planeswalker"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class DefibrillatingCurrent translated into ManaLoom runtime scope xmage_fixed_damage_target_and_controller_gain_life_spell_v1. This row is package-ready only because the source signature is a narrow fixed damage plus controller life-gain spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('douse in gloom', 'Douse in Gloom', '790b89d001d4612f47355b6eaa3c4090', 'battle_rule_v1:788f7c2c874671de1271b7435856eb66', '{"amount":2,"battle_model_scope":"xmage_fixed_damage_target_and_controller_gain_life_spell_v1","controller_gain_life":2,"damage":2,"effect":"direct_damage","gain_life":2,"instant":true,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"]},"xmage_effect_classes":["DamageTargetEffect","GainLifeEffect"]}'::jsonb, '{"category":"unknown","effect":"direct_damage","target":"creature","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class DouseInGloom translated into ManaLoom runtime scope xmage_fixed_damage_target_and_controller_gain_life_spell_v1. This row is package-ready only because the source signature is a narrow fixed damage plus controller life-gain spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('essence drain', 'Essence Drain', 'f7797f346011287d89fbfc7663670476', 'battle_rule_v1:c1efa9874143362f23fce5bed164f104', '{"amount":3,"battle_model_scope":"xmage_fixed_damage_target_and_controller_gain_life_spell_v1","controller_gain_life":3,"damage":3,"effect":"direct_damage","gain_life":3,"instant":false,"sorcery":true,"target":"any_target","target_constraints":{"scope":"any_target"},"xmage_effect_classes":["DamageTargetEffect","GainLifeEffect"]}'::jsonb, '{"category":"unknown","effect":"direct_damage","target":"any_target"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class EssenceDrain translated into ManaLoom runtime scope xmage_fixed_damage_target_and_controller_gain_life_spell_v1. This row is package-ready only because the source signature is a narrow fixed damage plus controller life-gain spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('essence extraction', 'Essence Extraction', 'd96959f3a27de4e120c64de80c6a9aaa', 'battle_rule_v1:fd24ff97747cfcb1638dbf9636156765', '{"amount":3,"battle_model_scope":"xmage_fixed_damage_target_and_controller_gain_life_spell_v1","controller_gain_life":3,"damage":3,"effect":"direct_damage","gain_life":3,"instant":true,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"]},"xmage_effect_classes":["DamageTargetEffect","GainLifeEffect"]}'::jsonb, '{"category":"unknown","effect":"direct_damage","target":"creature","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class EssenceExtraction translated into ManaLoom runtime scope xmage_fixed_damage_target_and_controller_gain_life_spell_v1. This row is package-ready only because the source signature is a narrow fixed damage plus controller life-gain spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('last kiss', 'Last Kiss', '2b9469002ffd3fc0a880f6f8c3c0cf19', 'battle_rule_v1:788f7c2c874671de1271b7435856eb66', '{"amount":2,"battle_model_scope":"xmage_fixed_damage_target_and_controller_gain_life_spell_v1","controller_gain_life":2,"damage":2,"effect":"direct_damage","gain_life":2,"instant":true,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"]},"xmage_effect_classes":["DamageTargetEffect","GainLifeEffect"]}'::jsonb, '{"category":"unknown","effect":"direct_damage","target":"creature","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class LastKiss translated into ManaLoom runtime scope xmage_fixed_damage_target_and_controller_gain_life_spell_v1. This row is package-ready only because the source signature is a narrow fixed damage plus controller life-gain spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('pharika''s cure', 'Pharika''s Cure', '4a9e7997580341e5bcf6dd7fd9c1e887', 'battle_rule_v1:788f7c2c874671de1271b7435856eb66', '{"amount":2,"battle_model_scope":"xmage_fixed_damage_target_and_controller_gain_life_spell_v1","controller_gain_life":2,"damage":2,"effect":"direct_damage","gain_life":2,"instant":true,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"]},"xmage_effect_classes":["DamageTargetEffect","GainLifeEffect"]}'::jsonb, '{"category":"unknown","effect":"direct_damage","target":"creature","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class PharikasCure translated into ManaLoom runtime scope xmage_fixed_damage_target_and_controller_gain_life_spell_v1. This row is package-ready only because the source signature is a narrow fixed damage plus controller life-gain spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('sorin''s thirst', 'Sorin''s Thirst', '1e54bf29b16bbc69cf01b968ef142778', 'battle_rule_v1:788f7c2c874671de1271b7435856eb66', '{"amount":2,"battle_model_scope":"xmage_fixed_damage_target_and_controller_gain_life_spell_v1","controller_gain_life":2,"damage":2,"effect":"direct_damage","gain_life":2,"instant":true,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"]},"xmage_effect_classes":["DamageTargetEffect","GainLifeEffect"]}'::jsonb, '{"category":"unknown","effect":"direct_damage","target":"creature","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class SorinsThirst translated into ManaLoom runtime scope xmage_fixed_damage_target_and_controller_gain_life_spell_v1. This row is package-ready only because the source signature is a narrow fixed damage plus controller life-gain spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('vampiric feast', 'Vampiric Feast', 'b395d91294a22cd813bfe27939364c56', 'battle_rule_v1:1d56c7af6c995b8069895ee5a393b1b5', '{"amount":4,"battle_model_scope":"xmage_fixed_damage_target_and_controller_gain_life_spell_v1","controller_gain_life":4,"damage":4,"effect":"direct_damage","gain_life":4,"instant":false,"sorcery":true,"target":"any_target","target_constraints":{"scope":"any_target"},"xmage_effect_classes":["DamageTargetEffect","GainLifeEffect"]}'::jsonb, '{"category":"unknown","effect":"direct_damage","target":"any_target"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class VampiricFeast translated into ManaLoom runtime scope xmage_fixed_damage_target_and_controller_gain_life_spell_v1. This row is package-ready only because the source signature is a narrow fixed damage plus controller life-gain spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('vicious hunger', 'Vicious Hunger', '0d8c6360af4725e1e185f7d7c48e0596', 'battle_rule_v1:afdcaac9d85814160b0c5bdc9cad24ed', '{"amount":2,"battle_model_scope":"xmage_fixed_damage_target_and_controller_gain_life_spell_v1","controller_gain_life":2,"damage":2,"effect":"direct_damage","gain_life":2,"instant":false,"sorcery":true,"target":"creature","target_constraints":{"card_types":["creature"]},"xmage_effect_classes":["DamageTargetEffect","GainLifeEffect"]}'::jsonb, '{"category":"unknown","effect":"direct_damage","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ViciousHunger translated into ManaLoom runtime scope xmage_fixed_damage_target_and_controller_gain_life_spell_v1. This row is package-ready only because the source signature is a narrow fixed damage plus controller life-gain spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('warleader''s helix', 'Warleader''s Helix', '70dd7a07d63e3c7d3705cf0efdb341d6', 'battle_rule_v1:b30ee9a5fcd603703d248235230ed80f', '{"amount":4,"battle_model_scope":"xmage_fixed_damage_target_and_controller_gain_life_spell_v1","controller_gain_life":4,"damage":4,"effect":"direct_damage","gain_life":4,"instant":true,"sorcery":false,"target":"any_target","target_constraints":{"scope":"any_target"},"xmage_effect_classes":["DamageTargetEffect","GainLifeEffect"]}'::jsonb, '{"category":"unknown","effect":"direct_damage","target":"any_target","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class WarleadersHelix translated into ManaLoom runtime scope xmage_fixed_damage_target_and_controller_gain_life_spell_v1. This row is package-ready only because the source signature is a narrow fixed damage plus controller life-gain spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('winter''s intervention', 'Winter''s Intervention', '6a5018c20fad5c79a5f827f693574a27', 'battle_rule_v1:788f7c2c874671de1271b7435856eb66', '{"amount":2,"battle_model_scope":"xmage_fixed_damage_target_and_controller_gain_life_spell_v1","controller_gain_life":2,"damage":2,"effect":"direct_damage","gain_life":2,"instant":true,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"]},"xmage_effect_classes":["DamageTargetEffect","GainLifeEffect"]}'::jsonb, '{"category":"unknown","effect":"direct_damage","target":"creature","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class WintersIntervention translated into ManaLoom runtime scope xmage_fixed_damage_target_and_controller_gain_life_spell_v1. This row is package-ready only because the source signature is a narrow fixed damage plus controller life-gain spell with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
    ('agonizing syphon', 'Agonizing Syphon', 'bb99dc3202d60eebefd671ebb94d5fdd', 'battle_rule_v1:c1efa9874143362f23fce5bed164f104', '{"amount":3,"battle_model_scope":"xmage_fixed_damage_target_and_controller_gain_life_spell_v1","controller_gain_life":3,"damage":3,"effect":"direct_damage","gain_life":3,"instant":false,"sorcery":true,"target":"any_target","target_constraints":{"scope":"any_target"},"xmage_effect_classes":["DamageTargetEffect","GainLifeEffect"]}'::jsonb, '{"category":"unknown","effect":"direct_damage","target":"any_target"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class AgonizingSyphon translated into ManaLoom runtime scope xmage_fixed_damage_target_and_controller_gain_life_spell_v1. This row is package-ready only because the source signature is a narrow fixed damage plus controller life-gain spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('dark nourishment', 'Dark Nourishment', '9ad9181ce8b6bf194df67591eba0005d', 'battle_rule_v1:029f28307ce7b3b6c69a0d41cc7deab2', '{"amount":3,"battle_model_scope":"xmage_fixed_damage_target_and_controller_gain_life_spell_v1","controller_gain_life":3,"damage":3,"effect":"direct_damage","gain_life":3,"instant":true,"sorcery":false,"target":"any_target","target_constraints":{"scope":"any_target"},"xmage_effect_classes":["DamageTargetEffect","GainLifeEffect"]}'::jsonb, '{"category":"unknown","effect":"direct_damage","target":"any_target","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class DarkNourishment translated into ManaLoom runtime scope xmage_fixed_damage_target_and_controller_gain_life_spell_v1. This row is package-ready only because the source signature is a narrow fixed damage plus controller life-gain spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('defibrillating current', 'Defibrillating Current', '32b8aad46992cb58b5cfae49735140ca', 'battle_rule_v1:8b75e08deb84e2d0e42ca28533f68bea', '{"amount":4,"battle_model_scope":"xmage_fixed_damage_target_and_controller_gain_life_spell_v1","controller_gain_life":2,"damage":4,"effect":"direct_damage","gain_life":2,"instant":false,"sorcery":true,"target":"creature_or_planeswalker","target_constraints":{"card_types":["creature","planeswalker"]},"xmage_effect_classes":["DamageTargetEffect","GainLifeEffect"]}'::jsonb, '{"category":"unknown","effect":"direct_damage","target":"creature_or_planeswalker"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class DefibrillatingCurrent translated into ManaLoom runtime scope xmage_fixed_damage_target_and_controller_gain_life_spell_v1. This row is package-ready only because the source signature is a narrow fixed damage plus controller life-gain spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('douse in gloom', 'Douse in Gloom', '790b89d001d4612f47355b6eaa3c4090', 'battle_rule_v1:788f7c2c874671de1271b7435856eb66', '{"amount":2,"battle_model_scope":"xmage_fixed_damage_target_and_controller_gain_life_spell_v1","controller_gain_life":2,"damage":2,"effect":"direct_damage","gain_life":2,"instant":true,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"]},"xmage_effect_classes":["DamageTargetEffect","GainLifeEffect"]}'::jsonb, '{"category":"unknown","effect":"direct_damage","target":"creature","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class DouseInGloom translated into ManaLoom runtime scope xmage_fixed_damage_target_and_controller_gain_life_spell_v1. This row is package-ready only because the source signature is a narrow fixed damage plus controller life-gain spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('essence drain', 'Essence Drain', 'f7797f346011287d89fbfc7663670476', 'battle_rule_v1:c1efa9874143362f23fce5bed164f104', '{"amount":3,"battle_model_scope":"xmage_fixed_damage_target_and_controller_gain_life_spell_v1","controller_gain_life":3,"damage":3,"effect":"direct_damage","gain_life":3,"instant":false,"sorcery":true,"target":"any_target","target_constraints":{"scope":"any_target"},"xmage_effect_classes":["DamageTargetEffect","GainLifeEffect"]}'::jsonb, '{"category":"unknown","effect":"direct_damage","target":"any_target"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class EssenceDrain translated into ManaLoom runtime scope xmage_fixed_damage_target_and_controller_gain_life_spell_v1. This row is package-ready only because the source signature is a narrow fixed damage plus controller life-gain spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('essence extraction', 'Essence Extraction', 'd96959f3a27de4e120c64de80c6a9aaa', 'battle_rule_v1:fd24ff97747cfcb1638dbf9636156765', '{"amount":3,"battle_model_scope":"xmage_fixed_damage_target_and_controller_gain_life_spell_v1","controller_gain_life":3,"damage":3,"effect":"direct_damage","gain_life":3,"instant":true,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"]},"xmage_effect_classes":["DamageTargetEffect","GainLifeEffect"]}'::jsonb, '{"category":"unknown","effect":"direct_damage","target":"creature","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class EssenceExtraction translated into ManaLoom runtime scope xmage_fixed_damage_target_and_controller_gain_life_spell_v1. This row is package-ready only because the source signature is a narrow fixed damage plus controller life-gain spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('last kiss', 'Last Kiss', '2b9469002ffd3fc0a880f6f8c3c0cf19', 'battle_rule_v1:788f7c2c874671de1271b7435856eb66', '{"amount":2,"battle_model_scope":"xmage_fixed_damage_target_and_controller_gain_life_spell_v1","controller_gain_life":2,"damage":2,"effect":"direct_damage","gain_life":2,"instant":true,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"]},"xmage_effect_classes":["DamageTargetEffect","GainLifeEffect"]}'::jsonb, '{"category":"unknown","effect":"direct_damage","target":"creature","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class LastKiss translated into ManaLoom runtime scope xmage_fixed_damage_target_and_controller_gain_life_spell_v1. This row is package-ready only because the source signature is a narrow fixed damage plus controller life-gain spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('pharika''s cure', 'Pharika''s Cure', '4a9e7997580341e5bcf6dd7fd9c1e887', 'battle_rule_v1:788f7c2c874671de1271b7435856eb66', '{"amount":2,"battle_model_scope":"xmage_fixed_damage_target_and_controller_gain_life_spell_v1","controller_gain_life":2,"damage":2,"effect":"direct_damage","gain_life":2,"instant":true,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"]},"xmage_effect_classes":["DamageTargetEffect","GainLifeEffect"]}'::jsonb, '{"category":"unknown","effect":"direct_damage","target":"creature","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class PharikasCure translated into ManaLoom runtime scope xmage_fixed_damage_target_and_controller_gain_life_spell_v1. This row is package-ready only because the source signature is a narrow fixed damage plus controller life-gain spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('sorin''s thirst', 'Sorin''s Thirst', '1e54bf29b16bbc69cf01b968ef142778', 'battle_rule_v1:788f7c2c874671de1271b7435856eb66', '{"amount":2,"battle_model_scope":"xmage_fixed_damage_target_and_controller_gain_life_spell_v1","controller_gain_life":2,"damage":2,"effect":"direct_damage","gain_life":2,"instant":true,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"]},"xmage_effect_classes":["DamageTargetEffect","GainLifeEffect"]}'::jsonb, '{"category":"unknown","effect":"direct_damage","target":"creature","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class SorinsThirst translated into ManaLoom runtime scope xmage_fixed_damage_target_and_controller_gain_life_spell_v1. This row is package-ready only because the source signature is a narrow fixed damage plus controller life-gain spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('vampiric feast', 'Vampiric Feast', 'b395d91294a22cd813bfe27939364c56', 'battle_rule_v1:1d56c7af6c995b8069895ee5a393b1b5', '{"amount":4,"battle_model_scope":"xmage_fixed_damage_target_and_controller_gain_life_spell_v1","controller_gain_life":4,"damage":4,"effect":"direct_damage","gain_life":4,"instant":false,"sorcery":true,"target":"any_target","target_constraints":{"scope":"any_target"},"xmage_effect_classes":["DamageTargetEffect","GainLifeEffect"]}'::jsonb, '{"category":"unknown","effect":"direct_damage","target":"any_target"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class VampiricFeast translated into ManaLoom runtime scope xmage_fixed_damage_target_and_controller_gain_life_spell_v1. This row is package-ready only because the source signature is a narrow fixed damage plus controller life-gain spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('vicious hunger', 'Vicious Hunger', '0d8c6360af4725e1e185f7d7c48e0596', 'battle_rule_v1:afdcaac9d85814160b0c5bdc9cad24ed', '{"amount":2,"battle_model_scope":"xmage_fixed_damage_target_and_controller_gain_life_spell_v1","controller_gain_life":2,"damage":2,"effect":"direct_damage","gain_life":2,"instant":false,"sorcery":true,"target":"creature","target_constraints":{"card_types":["creature"]},"xmage_effect_classes":["DamageTargetEffect","GainLifeEffect"]}'::jsonb, '{"category":"unknown","effect":"direct_damage","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ViciousHunger translated into ManaLoom runtime scope xmage_fixed_damage_target_and_controller_gain_life_spell_v1. This row is package-ready only because the source signature is a narrow fixed damage plus controller life-gain spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('warleader''s helix', 'Warleader''s Helix', '70dd7a07d63e3c7d3705cf0efdb341d6', 'battle_rule_v1:b30ee9a5fcd603703d248235230ed80f', '{"amount":4,"battle_model_scope":"xmage_fixed_damage_target_and_controller_gain_life_spell_v1","controller_gain_life":4,"damage":4,"effect":"direct_damage","gain_life":4,"instant":true,"sorcery":false,"target":"any_target","target_constraints":{"scope":"any_target"},"xmage_effect_classes":["DamageTargetEffect","GainLifeEffect"]}'::jsonb, '{"category":"unknown","effect":"direct_damage","target":"any_target","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class WarleadersHelix translated into ManaLoom runtime scope xmage_fixed_damage_target_and_controller_gain_life_spell_v1. This row is package-ready only because the source signature is a narrow fixed damage plus controller life-gain spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('winter''s intervention', 'Winter''s Intervention', '6a5018c20fad5c79a5f827f693574a27', 'battle_rule_v1:788f7c2c874671de1271b7435856eb66', '{"amount":2,"battle_model_scope":"xmage_fixed_damage_target_and_controller_gain_life_spell_v1","controller_gain_life":2,"damage":2,"effect":"direct_damage","gain_life":2,"instant":true,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"]},"xmage_effect_classes":["DamageTargetEffect","GainLifeEffect"]}'::jsonb, '{"category":"unknown","effect":"direct_damage","target":"creature","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class WintersIntervention translated into ManaLoom runtime scope xmage_fixed_damage_target_and_controller_gain_life_spell_v1. This row is package-ready only because the source signature is a narrow fixed damage plus controller life-gain spell with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
