BEGIN;

CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit;

CREATE TABLE IF NOT EXISTS manaloom_deploy_audit.pg602_static_controlled_pt_filters_new_s_20260707_075017 AS
SELECT *
FROM public.card_battle_rules
WHERE normalized_name IN ('builder''s blessing', 'castle', 'dire fleet neckbreaker', 'goblin oriflamme', 'honor of the pure', 'jacques le vert', 'kaysa', 'orcish oriflamme', 'war horn')
   OR normalized_name LIKE 'builder''s blessing // %'
   OR normalized_name LIKE 'castle // %'
   OR normalized_name LIKE 'dire fleet neckbreaker // %'
   OR normalized_name LIKE 'goblin oriflamme // %'
   OR normalized_name LIKE 'honor of the pure // %'
   OR normalized_name LIKE 'jacques le vert // %'
   OR normalized_name LIKE 'kaysa // %'
   OR normalized_name LIKE 'orcish oriflamme // %'
   OR normalized_name LIKE 'war horn // %';

DO $$
DECLARE
  v_missing jsonb;
BEGIN
  WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('builder''s blessing', 'Builder''s Blessing', 'ad19443ea215d62f8c1bd4fb81e0d6aa', 'battle_rule_v1:879c6fd1182165350d95adb96bccf042', '{"ability_kind":"static","battle_model_scope":"xmage_static_controlled_power_toughness_boost_v1","effect":"passive","permanent_type":"enchantment","static_applies_to":"creatures_you_control","static_effect":"controlled_power_toughness_boost","static_exclude_source":false,"static_power_bonus":0,"static_required_tapped_state":"untapped","static_toughness_bonus":2,"target":"controlled_creatures","target_constraints":{"card_types":["creature"],"controller":"self","tapped_state":"untapped"},"target_controller":"self","xmage_ability_class":"SimpleStaticAbility","xmage_effect_class":"BoostControlledEffect"}'::jsonb, '{"category":"unknown","effect":"passive","target":"controlled_creatures"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class BuildersBlessing translated into ManaLoom runtime scope xmage_static_controlled_power_toughness_boost_v1. This row is package-ready only because the source signature is a narrow permanent static controlled-creature power/toughness boost with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('castle', 'Castle', 'ad19443ea215d62f8c1bd4fb81e0d6aa', 'battle_rule_v1:879c6fd1182165350d95adb96bccf042', '{"ability_kind":"static","battle_model_scope":"xmage_static_controlled_power_toughness_boost_v1","effect":"passive","permanent_type":"enchantment","static_applies_to":"creatures_you_control","static_effect":"controlled_power_toughness_boost","static_exclude_source":false,"static_power_bonus":0,"static_required_tapped_state":"untapped","static_toughness_bonus":2,"target":"controlled_creatures","target_constraints":{"card_types":["creature"],"controller":"self","tapped_state":"untapped"},"target_controller":"self","xmage_ability_class":"SimpleStaticAbility","xmage_effect_class":"BoostControlledEffect"}'::jsonb, '{"category":"unknown","effect":"passive","target":"controlled_creatures"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Castle translated into ManaLoom runtime scope xmage_static_controlled_power_toughness_boost_v1. This row is package-ready only because the source signature is a narrow permanent static controlled-creature power/toughness boost with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('dire fleet neckbreaker', 'Dire Fleet Neckbreaker', 'b4eb782b3781b4f82e89f44d8600c582', 'battle_rule_v1:7ee525c101a785af954a07783655f297', '{"ability_kind":"static","battle_model_scope":"xmage_static_controlled_power_toughness_boost_v1","effect":"creature","permanent_type":"creature","static_applies_to":"creatures_you_control","static_effect":"controlled_power_toughness_boost","static_exclude_source":false,"static_power_bonus":2,"static_required_combat_state":"attacking","static_required_subtypes":["pirate"],"static_toughness_bonus":0,"target":"controlled_creatures","target_constraints":{"card_types":["creature"],"combat_state":"attacking","controller":"self","subtypes":["pirate"]},"target_controller":"self","xmage_ability_class":"SimpleStaticAbility","xmage_effect_class":"BoostControlledEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"controlled_creatures"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class DireFleetNeckbreaker translated into ManaLoom runtime scope xmage_static_controlled_power_toughness_boost_v1. This row is package-ready only because the source signature is a narrow permanent static controlled-creature power/toughness boost with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('goblin oriflamme', 'Goblin Oriflamme', 'ac2e29ddff9b3a465105f4582b40f012', 'battle_rule_v1:4b0f6181adb21e48fae116054fe4e08b', '{"ability_kind":"static","battle_model_scope":"xmage_static_controlled_power_toughness_boost_v1","effect":"passive","permanent_type":"enchantment","static_applies_to":"creatures_you_control","static_effect":"controlled_power_toughness_boost","static_exclude_source":false,"static_power_bonus":1,"static_required_combat_state":"attacking","static_toughness_bonus":0,"target":"controlled_creatures","target_constraints":{"card_types":["creature"],"combat_state":"attacking","controller":"self"},"target_controller":"self","xmage_ability_class":"SimpleStaticAbility","xmage_effect_class":"BoostControlledEffect"}'::jsonb, '{"category":"unknown","effect":"passive","target":"controlled_creatures"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class GoblinOriflamme translated into ManaLoom runtime scope xmage_static_controlled_power_toughness_boost_v1. This row is package-ready only because the source signature is a narrow permanent static controlled-creature power/toughness boost with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('honor of the pure', 'Honor of the Pure', '7278ea48e2b98eab9c6802bb5d454ed7', 'battle_rule_v1:8ab29fd8f0c26aceb442058cc885461f', '{"ability_kind":"static","battle_model_scope":"xmage_static_controlled_power_toughness_boost_v1","effect":"passive","permanent_type":"enchantment","static_applies_to":"creatures_you_control","static_effect":"controlled_power_toughness_boost","static_exclude_source":false,"static_power_bonus":1,"static_required_colors":["W"],"static_toughness_bonus":1,"target":"controlled_creatures","target_constraints":{"card_types":["creature"],"colors":["W"],"controller":"self"},"target_controller":"self","xmage_ability_class":"SimpleStaticAbility","xmage_effect_class":"BoostControlledEffect"}'::jsonb, '{"category":"unknown","effect":"passive","target":"controlled_creatures"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class HonorOfThePure translated into ManaLoom runtime scope xmage_static_controlled_power_toughness_boost_v1. This row is package-ready only because the source signature is a narrow permanent static controlled-creature power/toughness boost with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('jacques le vert', 'Jacques le Vert', '4cb50df0f1c67841d4e69aaaf617d95d', 'battle_rule_v1:964e27bcaf5c95d549770883d5697b90', '{"ability_kind":"static","battle_model_scope":"xmage_static_controlled_power_toughness_boost_v1","effect":"creature","permanent_type":"creature","static_applies_to":"creatures_you_control","static_effect":"controlled_power_toughness_boost","static_exclude_source":false,"static_power_bonus":0,"static_required_colors":["G"],"static_toughness_bonus":2,"target":"controlled_creatures","target_constraints":{"card_types":["creature"],"colors":["G"],"controller":"self"},"target_controller":"self","xmage_ability_class":"SimpleStaticAbility","xmage_effect_class":"BoostControlledEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"controlled_creatures"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class JacquesLeVert translated into ManaLoom runtime scope xmage_static_controlled_power_toughness_boost_v1. This row is package-ready only because the source signature is a narrow permanent static controlled-creature power/toughness boost with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('kaysa', 'Kaysa', '2d6428d94870902d477189d5c7405c5f', 'battle_rule_v1:c5d36e3805d11b92e963645e9f2eb522', '{"ability_kind":"static","battle_model_scope":"xmage_static_controlled_power_toughness_boost_v1","effect":"creature","permanent_type":"creature","static_applies_to":"creatures_you_control","static_effect":"controlled_power_toughness_boost","static_exclude_source":false,"static_power_bonus":1,"static_required_colors":["G"],"static_toughness_bonus":1,"target":"controlled_creatures","target_constraints":{"card_types":["creature"],"colors":["G"],"controller":"self"},"target_controller":"self","xmage_ability_class":"SimpleStaticAbility","xmage_effect_class":"BoostControlledEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"controlled_creatures"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Kaysa translated into ManaLoom runtime scope xmage_static_controlled_power_toughness_boost_v1. This row is package-ready only because the source signature is a narrow permanent static controlled-creature power/toughness boost with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('orcish oriflamme', 'Orcish Oriflamme', 'ac2e29ddff9b3a465105f4582b40f012', 'battle_rule_v1:4b0f6181adb21e48fae116054fe4e08b', '{"ability_kind":"static","battle_model_scope":"xmage_static_controlled_power_toughness_boost_v1","effect":"passive","permanent_type":"enchantment","static_applies_to":"creatures_you_control","static_effect":"controlled_power_toughness_boost","static_exclude_source":false,"static_power_bonus":1,"static_required_combat_state":"attacking","static_toughness_bonus":0,"target":"controlled_creatures","target_constraints":{"card_types":["creature"],"combat_state":"attacking","controller":"self"},"target_controller":"self","xmage_ability_class":"SimpleStaticAbility","xmage_effect_class":"BoostControlledEffect"}'::jsonb, '{"category":"unknown","effect":"passive","target":"controlled_creatures"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class OrcishOriflamme translated into ManaLoom runtime scope xmage_static_controlled_power_toughness_boost_v1. This row is package-ready only because the source signature is a narrow permanent static controlled-creature power/toughness boost with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('war horn', 'War Horn', 'ac2e29ddff9b3a465105f4582b40f012', 'battle_rule_v1:0eedfd9a81253b55467d6dfbd75213ba', '{"ability_kind":"static","battle_model_scope":"xmage_static_controlled_power_toughness_boost_v1","effect":"passive","permanent_type":"artifact","static_applies_to":"creatures_you_control","static_effect":"controlled_power_toughness_boost","static_exclude_source":false,"static_power_bonus":1,"static_required_combat_state":"attacking","static_toughness_bonus":0,"target":"controlled_creatures","target_constraints":{"card_types":["creature"],"combat_state":"attacking","controller":"self"},"target_controller":"self","xmage_ability_class":"SimpleStaticAbility","xmage_effect_class":"BoostControlledEffect"}'::jsonb, '{"category":"unknown","effect":"passive","target":"controlled_creatures"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class WarHorn translated into ManaLoom runtime scope xmage_static_controlled_power_toughness_boost_v1. This row is package-ready only because the source signature is a narrow permanent static controlled-creature power/toughness boost with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
    ('builder''s blessing', 'Builder''s Blessing', 'ad19443ea215d62f8c1bd4fb81e0d6aa', 'battle_rule_v1:879c6fd1182165350d95adb96bccf042', '{"ability_kind":"static","battle_model_scope":"xmage_static_controlled_power_toughness_boost_v1","effect":"passive","permanent_type":"enchantment","static_applies_to":"creatures_you_control","static_effect":"controlled_power_toughness_boost","static_exclude_source":false,"static_power_bonus":0,"static_required_tapped_state":"untapped","static_toughness_bonus":2,"target":"controlled_creatures","target_constraints":{"card_types":["creature"],"controller":"self","tapped_state":"untapped"},"target_controller":"self","xmage_ability_class":"SimpleStaticAbility","xmage_effect_class":"BoostControlledEffect"}'::jsonb, '{"category":"unknown","effect":"passive","target":"controlled_creatures"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class BuildersBlessing translated into ManaLoom runtime scope xmage_static_controlled_power_toughness_boost_v1. This row is package-ready only because the source signature is a narrow permanent static controlled-creature power/toughness boost with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('castle', 'Castle', 'ad19443ea215d62f8c1bd4fb81e0d6aa', 'battle_rule_v1:879c6fd1182165350d95adb96bccf042', '{"ability_kind":"static","battle_model_scope":"xmage_static_controlled_power_toughness_boost_v1","effect":"passive","permanent_type":"enchantment","static_applies_to":"creatures_you_control","static_effect":"controlled_power_toughness_boost","static_exclude_source":false,"static_power_bonus":0,"static_required_tapped_state":"untapped","static_toughness_bonus":2,"target":"controlled_creatures","target_constraints":{"card_types":["creature"],"controller":"self","tapped_state":"untapped"},"target_controller":"self","xmage_ability_class":"SimpleStaticAbility","xmage_effect_class":"BoostControlledEffect"}'::jsonb, '{"category":"unknown","effect":"passive","target":"controlled_creatures"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Castle translated into ManaLoom runtime scope xmage_static_controlled_power_toughness_boost_v1. This row is package-ready only because the source signature is a narrow permanent static controlled-creature power/toughness boost with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('dire fleet neckbreaker', 'Dire Fleet Neckbreaker', 'b4eb782b3781b4f82e89f44d8600c582', 'battle_rule_v1:7ee525c101a785af954a07783655f297', '{"ability_kind":"static","battle_model_scope":"xmage_static_controlled_power_toughness_boost_v1","effect":"creature","permanent_type":"creature","static_applies_to":"creatures_you_control","static_effect":"controlled_power_toughness_boost","static_exclude_source":false,"static_power_bonus":2,"static_required_combat_state":"attacking","static_required_subtypes":["pirate"],"static_toughness_bonus":0,"target":"controlled_creatures","target_constraints":{"card_types":["creature"],"combat_state":"attacking","controller":"self","subtypes":["pirate"]},"target_controller":"self","xmage_ability_class":"SimpleStaticAbility","xmage_effect_class":"BoostControlledEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"controlled_creatures"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class DireFleetNeckbreaker translated into ManaLoom runtime scope xmage_static_controlled_power_toughness_boost_v1. This row is package-ready only because the source signature is a narrow permanent static controlled-creature power/toughness boost with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('goblin oriflamme', 'Goblin Oriflamme', 'ac2e29ddff9b3a465105f4582b40f012', 'battle_rule_v1:4b0f6181adb21e48fae116054fe4e08b', '{"ability_kind":"static","battle_model_scope":"xmage_static_controlled_power_toughness_boost_v1","effect":"passive","permanent_type":"enchantment","static_applies_to":"creatures_you_control","static_effect":"controlled_power_toughness_boost","static_exclude_source":false,"static_power_bonus":1,"static_required_combat_state":"attacking","static_toughness_bonus":0,"target":"controlled_creatures","target_constraints":{"card_types":["creature"],"combat_state":"attacking","controller":"self"},"target_controller":"self","xmage_ability_class":"SimpleStaticAbility","xmage_effect_class":"BoostControlledEffect"}'::jsonb, '{"category":"unknown","effect":"passive","target":"controlled_creatures"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class GoblinOriflamme translated into ManaLoom runtime scope xmage_static_controlled_power_toughness_boost_v1. This row is package-ready only because the source signature is a narrow permanent static controlled-creature power/toughness boost with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('honor of the pure', 'Honor of the Pure', '7278ea48e2b98eab9c6802bb5d454ed7', 'battle_rule_v1:8ab29fd8f0c26aceb442058cc885461f', '{"ability_kind":"static","battle_model_scope":"xmage_static_controlled_power_toughness_boost_v1","effect":"passive","permanent_type":"enchantment","static_applies_to":"creatures_you_control","static_effect":"controlled_power_toughness_boost","static_exclude_source":false,"static_power_bonus":1,"static_required_colors":["W"],"static_toughness_bonus":1,"target":"controlled_creatures","target_constraints":{"card_types":["creature"],"colors":["W"],"controller":"self"},"target_controller":"self","xmage_ability_class":"SimpleStaticAbility","xmage_effect_class":"BoostControlledEffect"}'::jsonb, '{"category":"unknown","effect":"passive","target":"controlled_creatures"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class HonorOfThePure translated into ManaLoom runtime scope xmage_static_controlled_power_toughness_boost_v1. This row is package-ready only because the source signature is a narrow permanent static controlled-creature power/toughness boost with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('jacques le vert', 'Jacques le Vert', '4cb50df0f1c67841d4e69aaaf617d95d', 'battle_rule_v1:964e27bcaf5c95d549770883d5697b90', '{"ability_kind":"static","battle_model_scope":"xmage_static_controlled_power_toughness_boost_v1","effect":"creature","permanent_type":"creature","static_applies_to":"creatures_you_control","static_effect":"controlled_power_toughness_boost","static_exclude_source":false,"static_power_bonus":0,"static_required_colors":["G"],"static_toughness_bonus":2,"target":"controlled_creatures","target_constraints":{"card_types":["creature"],"colors":["G"],"controller":"self"},"target_controller":"self","xmage_ability_class":"SimpleStaticAbility","xmage_effect_class":"BoostControlledEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"controlled_creatures"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class JacquesLeVert translated into ManaLoom runtime scope xmage_static_controlled_power_toughness_boost_v1. This row is package-ready only because the source signature is a narrow permanent static controlled-creature power/toughness boost with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('kaysa', 'Kaysa', '2d6428d94870902d477189d5c7405c5f', 'battle_rule_v1:c5d36e3805d11b92e963645e9f2eb522', '{"ability_kind":"static","battle_model_scope":"xmage_static_controlled_power_toughness_boost_v1","effect":"creature","permanent_type":"creature","static_applies_to":"creatures_you_control","static_effect":"controlled_power_toughness_boost","static_exclude_source":false,"static_power_bonus":1,"static_required_colors":["G"],"static_toughness_bonus":1,"target":"controlled_creatures","target_constraints":{"card_types":["creature"],"colors":["G"],"controller":"self"},"target_controller":"self","xmage_ability_class":"SimpleStaticAbility","xmage_effect_class":"BoostControlledEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"controlled_creatures"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Kaysa translated into ManaLoom runtime scope xmage_static_controlled_power_toughness_boost_v1. This row is package-ready only because the source signature is a narrow permanent static controlled-creature power/toughness boost with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('orcish oriflamme', 'Orcish Oriflamme', 'ac2e29ddff9b3a465105f4582b40f012', 'battle_rule_v1:4b0f6181adb21e48fae116054fe4e08b', '{"ability_kind":"static","battle_model_scope":"xmage_static_controlled_power_toughness_boost_v1","effect":"passive","permanent_type":"enchantment","static_applies_to":"creatures_you_control","static_effect":"controlled_power_toughness_boost","static_exclude_source":false,"static_power_bonus":1,"static_required_combat_state":"attacking","static_toughness_bonus":0,"target":"controlled_creatures","target_constraints":{"card_types":["creature"],"combat_state":"attacking","controller":"self"},"target_controller":"self","xmage_ability_class":"SimpleStaticAbility","xmage_effect_class":"BoostControlledEffect"}'::jsonb, '{"category":"unknown","effect":"passive","target":"controlled_creatures"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class OrcishOriflamme translated into ManaLoom runtime scope xmage_static_controlled_power_toughness_boost_v1. This row is package-ready only because the source signature is a narrow permanent static controlled-creature power/toughness boost with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('war horn', 'War Horn', 'ac2e29ddff9b3a465105f4582b40f012', 'battle_rule_v1:0eedfd9a81253b55467d6dfbd75213ba', '{"ability_kind":"static","battle_model_scope":"xmage_static_controlled_power_toughness_boost_v1","effect":"passive","permanent_type":"artifact","static_applies_to":"creatures_you_control","static_effect":"controlled_power_toughness_boost","static_exclude_source":false,"static_power_bonus":1,"static_required_combat_state":"attacking","static_toughness_bonus":0,"target":"controlled_creatures","target_constraints":{"card_types":["creature"],"combat_state":"attacking","controller":"self"},"target_controller":"self","xmage_ability_class":"SimpleStaticAbility","xmage_effect_class":"BoostControlledEffect"}'::jsonb, '{"category":"unknown","effect":"passive","target":"controlled_creatures"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class WarHorn translated into ManaLoom runtime scope xmage_static_controlled_power_toughness_boost_v1. This row is package-ready only because the source signature is a narrow permanent static controlled-creature power/toughness boost with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
    ('builder''s blessing', 'Builder''s Blessing', 'ad19443ea215d62f8c1bd4fb81e0d6aa', 'battle_rule_v1:879c6fd1182165350d95adb96bccf042', '{"ability_kind":"static","battle_model_scope":"xmage_static_controlled_power_toughness_boost_v1","effect":"passive","permanent_type":"enchantment","static_applies_to":"creatures_you_control","static_effect":"controlled_power_toughness_boost","static_exclude_source":false,"static_power_bonus":0,"static_required_tapped_state":"untapped","static_toughness_bonus":2,"target":"controlled_creatures","target_constraints":{"card_types":["creature"],"controller":"self","tapped_state":"untapped"},"target_controller":"self","xmage_ability_class":"SimpleStaticAbility","xmage_effect_class":"BoostControlledEffect"}'::jsonb, '{"category":"unknown","effect":"passive","target":"controlled_creatures"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class BuildersBlessing translated into ManaLoom runtime scope xmage_static_controlled_power_toughness_boost_v1. This row is package-ready only because the source signature is a narrow permanent static controlled-creature power/toughness boost with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('castle', 'Castle', 'ad19443ea215d62f8c1bd4fb81e0d6aa', 'battle_rule_v1:879c6fd1182165350d95adb96bccf042', '{"ability_kind":"static","battle_model_scope":"xmage_static_controlled_power_toughness_boost_v1","effect":"passive","permanent_type":"enchantment","static_applies_to":"creatures_you_control","static_effect":"controlled_power_toughness_boost","static_exclude_source":false,"static_power_bonus":0,"static_required_tapped_state":"untapped","static_toughness_bonus":2,"target":"controlled_creatures","target_constraints":{"card_types":["creature"],"controller":"self","tapped_state":"untapped"},"target_controller":"self","xmage_ability_class":"SimpleStaticAbility","xmage_effect_class":"BoostControlledEffect"}'::jsonb, '{"category":"unknown","effect":"passive","target":"controlled_creatures"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Castle translated into ManaLoom runtime scope xmage_static_controlled_power_toughness_boost_v1. This row is package-ready only because the source signature is a narrow permanent static controlled-creature power/toughness boost with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('dire fleet neckbreaker', 'Dire Fleet Neckbreaker', 'b4eb782b3781b4f82e89f44d8600c582', 'battle_rule_v1:7ee525c101a785af954a07783655f297', '{"ability_kind":"static","battle_model_scope":"xmage_static_controlled_power_toughness_boost_v1","effect":"creature","permanent_type":"creature","static_applies_to":"creatures_you_control","static_effect":"controlled_power_toughness_boost","static_exclude_source":false,"static_power_bonus":2,"static_required_combat_state":"attacking","static_required_subtypes":["pirate"],"static_toughness_bonus":0,"target":"controlled_creatures","target_constraints":{"card_types":["creature"],"combat_state":"attacking","controller":"self","subtypes":["pirate"]},"target_controller":"self","xmage_ability_class":"SimpleStaticAbility","xmage_effect_class":"BoostControlledEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"controlled_creatures"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class DireFleetNeckbreaker translated into ManaLoom runtime scope xmage_static_controlled_power_toughness_boost_v1. This row is package-ready only because the source signature is a narrow permanent static controlled-creature power/toughness boost with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('goblin oriflamme', 'Goblin Oriflamme', 'ac2e29ddff9b3a465105f4582b40f012', 'battle_rule_v1:4b0f6181adb21e48fae116054fe4e08b', '{"ability_kind":"static","battle_model_scope":"xmage_static_controlled_power_toughness_boost_v1","effect":"passive","permanent_type":"enchantment","static_applies_to":"creatures_you_control","static_effect":"controlled_power_toughness_boost","static_exclude_source":false,"static_power_bonus":1,"static_required_combat_state":"attacking","static_toughness_bonus":0,"target":"controlled_creatures","target_constraints":{"card_types":["creature"],"combat_state":"attacking","controller":"self"},"target_controller":"self","xmage_ability_class":"SimpleStaticAbility","xmage_effect_class":"BoostControlledEffect"}'::jsonb, '{"category":"unknown","effect":"passive","target":"controlled_creatures"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class GoblinOriflamme translated into ManaLoom runtime scope xmage_static_controlled_power_toughness_boost_v1. This row is package-ready only because the source signature is a narrow permanent static controlled-creature power/toughness boost with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('honor of the pure', 'Honor of the Pure', '7278ea48e2b98eab9c6802bb5d454ed7', 'battle_rule_v1:8ab29fd8f0c26aceb442058cc885461f', '{"ability_kind":"static","battle_model_scope":"xmage_static_controlled_power_toughness_boost_v1","effect":"passive","permanent_type":"enchantment","static_applies_to":"creatures_you_control","static_effect":"controlled_power_toughness_boost","static_exclude_source":false,"static_power_bonus":1,"static_required_colors":["W"],"static_toughness_bonus":1,"target":"controlled_creatures","target_constraints":{"card_types":["creature"],"colors":["W"],"controller":"self"},"target_controller":"self","xmage_ability_class":"SimpleStaticAbility","xmage_effect_class":"BoostControlledEffect"}'::jsonb, '{"category":"unknown","effect":"passive","target":"controlled_creatures"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class HonorOfThePure translated into ManaLoom runtime scope xmage_static_controlled_power_toughness_boost_v1. This row is package-ready only because the source signature is a narrow permanent static controlled-creature power/toughness boost with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('jacques le vert', 'Jacques le Vert', '4cb50df0f1c67841d4e69aaaf617d95d', 'battle_rule_v1:964e27bcaf5c95d549770883d5697b90', '{"ability_kind":"static","battle_model_scope":"xmage_static_controlled_power_toughness_boost_v1","effect":"creature","permanent_type":"creature","static_applies_to":"creatures_you_control","static_effect":"controlled_power_toughness_boost","static_exclude_source":false,"static_power_bonus":0,"static_required_colors":["G"],"static_toughness_bonus":2,"target":"controlled_creatures","target_constraints":{"card_types":["creature"],"colors":["G"],"controller":"self"},"target_controller":"self","xmage_ability_class":"SimpleStaticAbility","xmage_effect_class":"BoostControlledEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"controlled_creatures"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class JacquesLeVert translated into ManaLoom runtime scope xmage_static_controlled_power_toughness_boost_v1. This row is package-ready only because the source signature is a narrow permanent static controlled-creature power/toughness boost with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('kaysa', 'Kaysa', '2d6428d94870902d477189d5c7405c5f', 'battle_rule_v1:c5d36e3805d11b92e963645e9f2eb522', '{"ability_kind":"static","battle_model_scope":"xmage_static_controlled_power_toughness_boost_v1","effect":"creature","permanent_type":"creature","static_applies_to":"creatures_you_control","static_effect":"controlled_power_toughness_boost","static_exclude_source":false,"static_power_bonus":1,"static_required_colors":["G"],"static_toughness_bonus":1,"target":"controlled_creatures","target_constraints":{"card_types":["creature"],"colors":["G"],"controller":"self"},"target_controller":"self","xmage_ability_class":"SimpleStaticAbility","xmage_effect_class":"BoostControlledEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"controlled_creatures"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Kaysa translated into ManaLoom runtime scope xmage_static_controlled_power_toughness_boost_v1. This row is package-ready only because the source signature is a narrow permanent static controlled-creature power/toughness boost with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('orcish oriflamme', 'Orcish Oriflamme', 'ac2e29ddff9b3a465105f4582b40f012', 'battle_rule_v1:4b0f6181adb21e48fae116054fe4e08b', '{"ability_kind":"static","battle_model_scope":"xmage_static_controlled_power_toughness_boost_v1","effect":"passive","permanent_type":"enchantment","static_applies_to":"creatures_you_control","static_effect":"controlled_power_toughness_boost","static_exclude_source":false,"static_power_bonus":1,"static_required_combat_state":"attacking","static_toughness_bonus":0,"target":"controlled_creatures","target_constraints":{"card_types":["creature"],"combat_state":"attacking","controller":"self"},"target_controller":"self","xmage_ability_class":"SimpleStaticAbility","xmage_effect_class":"BoostControlledEffect"}'::jsonb, '{"category":"unknown","effect":"passive","target":"controlled_creatures"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class OrcishOriflamme translated into ManaLoom runtime scope xmage_static_controlled_power_toughness_boost_v1. This row is package-ready only because the source signature is a narrow permanent static controlled-creature power/toughness boost with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('war horn', 'War Horn', 'ac2e29ddff9b3a465105f4582b40f012', 'battle_rule_v1:0eedfd9a81253b55467d6dfbd75213ba', '{"ability_kind":"static","battle_model_scope":"xmage_static_controlled_power_toughness_boost_v1","effect":"passive","permanent_type":"artifact","static_applies_to":"creatures_you_control","static_effect":"controlled_power_toughness_boost","static_exclude_source":false,"static_power_bonus":1,"static_required_combat_state":"attacking","static_toughness_bonus":0,"target":"controlled_creatures","target_constraints":{"card_types":["creature"],"combat_state":"attacking","controller":"self"},"target_controller":"self","xmage_ability_class":"SimpleStaticAbility","xmage_effect_class":"BoostControlledEffect"}'::jsonb, '{"category":"unknown","effect":"passive","target":"controlled_creatures"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class WarHorn translated into ManaLoom runtime scope xmage_static_controlled_power_toughness_boost_v1. This row is package-ready only because the source signature is a narrow permanent static controlled-creature power/toughness boost with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
