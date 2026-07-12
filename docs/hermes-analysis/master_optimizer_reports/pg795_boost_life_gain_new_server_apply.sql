BEGIN;

CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit;

CREATE TABLE IF NOT EXISTS manaloom_deploy_audit.pg795_boost_life_gain_new_server_20260712_002511 AS
SELECT *
FROM public.card_battle_rules
WHERE normalized_name IN ('moment of craving', 'moment of triumph', 'syphon fuel', 'tandem tactics')
   OR normalized_name LIKE 'moment of craving // %'
   OR normalized_name LIKE 'moment of triumph // %'
   OR normalized_name LIKE 'syphon fuel // %'
   OR normalized_name LIKE 'tandem tactics // %';

DO $$
DECLARE
  v_missing jsonb;
BEGIN
  WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('moment of craving', 'Moment of Craving', 'dc486e3f0b4387b644d636f58918b41f', 'battle_rule_v1:b63f76d6ec9977d6406965136735a100', '{"_composite_rule_components":[{"battle_model_scope":"xmage_fixed_boost_target_creature_until_eot_spell_v1","compose_on_resolution":true,"duration":"until_end_of_turn","effect":"stat_modifier_until_eot","power_boost":-2,"power_delta":-2,"target":"creature","target_constraints":{"card_types":["creature"]},"target_controller":"any","toughness_boost":-2,"toughness_delta":-2,"xmage_effect_class":"BoostTargetEffect"},{"battle_model_scope":"xmage_fixed_controller_gain_life_spell_v1","compose_on_resolution":true,"effect":"life_total_change","life_gain_amount":2,"target":"self","xmage_effect_class":"GainLifeEffect"}],"battle_model_scope":"xmage_fixed_boost_target_creature_until_eot_gain_life_spell_v1","effect":"composite_resolution","instant":true,"life_gain_amount":2,"power_boost":-2,"power_delta":-2,"resolution_order":"boost_then_gain","sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"]},"target_controller":"any","toughness_boost":-2,"toughness_delta":-2,"xmage_effect_classes":["BoostTargetEffect","GainLifeEffect"]}'::jsonb, '{"category":"draw","effect":"composite_resolution","target":"creature","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class MomentOfCraving translated into ManaLoom runtime scope xmage_fixed_boost_target_creature_until_eot_gain_life_spell_v1. This row is package-ready only because the source signature is a narrow fixed target-creature boost plus controller life-gain spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('moment of triumph', 'Moment of Triumph', '5953b146ebacdef49f8cf977f511f0f6', 'battle_rule_v1:133a9d7b7187d216ca297d65b8d3028b', '{"_composite_rule_components":[{"battle_model_scope":"xmage_fixed_boost_target_creature_until_eot_spell_v1","compose_on_resolution":true,"duration":"until_end_of_turn","effect":"stat_modifier_until_eot","power_boost":2,"power_delta":2,"target":"creature","target_constraints":{"card_types":["creature"]},"target_controller":"any","toughness_boost":2,"toughness_delta":2,"xmage_effect_class":"BoostTargetEffect"},{"battle_model_scope":"xmage_fixed_controller_gain_life_spell_v1","compose_on_resolution":true,"effect":"life_total_change","life_gain_amount":2,"target":"self","xmage_effect_class":"GainLifeEffect"}],"battle_model_scope":"xmage_fixed_boost_target_creature_until_eot_gain_life_spell_v1","effect":"composite_resolution","instant":true,"life_gain_amount":2,"power_boost":2,"power_delta":2,"resolution_order":"boost_then_gain","sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"]},"target_controller":"any","toughness_boost":2,"toughness_delta":2,"xmage_effect_classes":["BoostTargetEffect","GainLifeEffect"]}'::jsonb, '{"category":"draw","effect":"composite_resolution","target":"creature","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class MomentOfTriumph translated into ManaLoom runtime scope xmage_fixed_boost_target_creature_until_eot_gain_life_spell_v1. This row is package-ready only because the source signature is a narrow fixed target-creature boost plus controller life-gain spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('syphon fuel', 'Syphon Fuel', '424c2ba6a7cd5c1a82e1bfd31594a768', 'battle_rule_v1:5a6480818679773b600d24b5f84861f6', '{"_composite_rule_components":[{"battle_model_scope":"xmage_fixed_boost_target_creature_until_eot_spell_v1","compose_on_resolution":true,"duration":"until_end_of_turn","effect":"stat_modifier_until_eot","power_boost":-6,"power_delta":-6,"target":"creature","target_constraints":{"card_types":["creature"]},"target_controller":"any","toughness_boost":-6,"toughness_delta":-6,"xmage_effect_class":"BoostTargetEffect"},{"battle_model_scope":"xmage_fixed_controller_gain_life_spell_v1","compose_on_resolution":true,"effect":"life_total_change","life_gain_amount":2,"target":"self","xmage_effect_class":"GainLifeEffect"}],"battle_model_scope":"xmage_fixed_boost_target_creature_until_eot_gain_life_spell_v1","effect":"composite_resolution","instant":true,"life_gain_amount":2,"power_boost":-6,"power_delta":-6,"resolution_order":"boost_then_gain","sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"]},"target_controller":"any","toughness_boost":-6,"toughness_delta":-6,"xmage_effect_classes":["BoostTargetEffect","GainLifeEffect"]}'::jsonb, '{"category":"draw","effect":"composite_resolution","target":"creature","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class SyphonFuel translated into ManaLoom runtime scope xmage_fixed_boost_target_creature_until_eot_gain_life_spell_v1. This row is package-ready only because the source signature is a narrow fixed target-creature boost plus controller life-gain spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('tandem tactics', 'Tandem Tactics', '84c5a871f4a5b344ae46515e616900d6', 'battle_rule_v1:6535eb0fb5f92bbde58e0340d48c6672', '{"_composite_rule_components":[{"battle_model_scope":"xmage_fixed_boost_target_creature_until_eot_spell_v1","compose_on_resolution":true,"duration":"until_end_of_turn","effect":"stat_modifier_until_eot","power_boost":1,"power_delta":1,"target":"creature","target_constraints":{"card_types":["creature"]},"target_controller":"any","target_count":2,"target_count_max":2,"target_count_min":0,"toughness_boost":2,"toughness_delta":2,"up_to_count":true,"xmage_effect_class":"BoostTargetEffect"},{"battle_model_scope":"xmage_fixed_controller_gain_life_spell_v1","compose_on_resolution":true,"effect":"life_total_change","life_gain_amount":2,"target":"self","xmage_effect_class":"GainLifeEffect"}],"battle_model_scope":"xmage_fixed_boost_target_creature_until_eot_gain_life_spell_v1","effect":"composite_resolution","instant":true,"life_gain_amount":2,"power_boost":1,"power_delta":1,"resolution_order":"boost_then_gain","sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"]},"target_controller":"any","target_count":2,"target_count_max":2,"target_count_min":0,"toughness_boost":2,"toughness_delta":2,"up_to_count":true,"xmage_effect_classes":["BoostTargetEffect","GainLifeEffect"]}'::jsonb, '{"category":"draw","effect":"composite_resolution","target":"creature","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class TandemTactics translated into ManaLoom runtime scope xmage_fixed_boost_target_creature_until_eot_gain_life_spell_v1. This row is package-ready only because the source signature is a narrow fixed target-creature boost plus controller life-gain spell with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
    ('moment of craving', 'Moment of Craving', 'dc486e3f0b4387b644d636f58918b41f', 'battle_rule_v1:b63f76d6ec9977d6406965136735a100', '{"_composite_rule_components":[{"battle_model_scope":"xmage_fixed_boost_target_creature_until_eot_spell_v1","compose_on_resolution":true,"duration":"until_end_of_turn","effect":"stat_modifier_until_eot","power_boost":-2,"power_delta":-2,"target":"creature","target_constraints":{"card_types":["creature"]},"target_controller":"any","toughness_boost":-2,"toughness_delta":-2,"xmage_effect_class":"BoostTargetEffect"},{"battle_model_scope":"xmage_fixed_controller_gain_life_spell_v1","compose_on_resolution":true,"effect":"life_total_change","life_gain_amount":2,"target":"self","xmage_effect_class":"GainLifeEffect"}],"battle_model_scope":"xmage_fixed_boost_target_creature_until_eot_gain_life_spell_v1","effect":"composite_resolution","instant":true,"life_gain_amount":2,"power_boost":-2,"power_delta":-2,"resolution_order":"boost_then_gain","sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"]},"target_controller":"any","toughness_boost":-2,"toughness_delta":-2,"xmage_effect_classes":["BoostTargetEffect","GainLifeEffect"]}'::jsonb, '{"category":"draw","effect":"composite_resolution","target":"creature","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class MomentOfCraving translated into ManaLoom runtime scope xmage_fixed_boost_target_creature_until_eot_gain_life_spell_v1. This row is package-ready only because the source signature is a narrow fixed target-creature boost plus controller life-gain spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('moment of triumph', 'Moment of Triumph', '5953b146ebacdef49f8cf977f511f0f6', 'battle_rule_v1:133a9d7b7187d216ca297d65b8d3028b', '{"_composite_rule_components":[{"battle_model_scope":"xmage_fixed_boost_target_creature_until_eot_spell_v1","compose_on_resolution":true,"duration":"until_end_of_turn","effect":"stat_modifier_until_eot","power_boost":2,"power_delta":2,"target":"creature","target_constraints":{"card_types":["creature"]},"target_controller":"any","toughness_boost":2,"toughness_delta":2,"xmage_effect_class":"BoostTargetEffect"},{"battle_model_scope":"xmage_fixed_controller_gain_life_spell_v1","compose_on_resolution":true,"effect":"life_total_change","life_gain_amount":2,"target":"self","xmage_effect_class":"GainLifeEffect"}],"battle_model_scope":"xmage_fixed_boost_target_creature_until_eot_gain_life_spell_v1","effect":"composite_resolution","instant":true,"life_gain_amount":2,"power_boost":2,"power_delta":2,"resolution_order":"boost_then_gain","sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"]},"target_controller":"any","toughness_boost":2,"toughness_delta":2,"xmage_effect_classes":["BoostTargetEffect","GainLifeEffect"]}'::jsonb, '{"category":"draw","effect":"composite_resolution","target":"creature","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class MomentOfTriumph translated into ManaLoom runtime scope xmage_fixed_boost_target_creature_until_eot_gain_life_spell_v1. This row is package-ready only because the source signature is a narrow fixed target-creature boost plus controller life-gain spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('syphon fuel', 'Syphon Fuel', '424c2ba6a7cd5c1a82e1bfd31594a768', 'battle_rule_v1:5a6480818679773b600d24b5f84861f6', '{"_composite_rule_components":[{"battle_model_scope":"xmage_fixed_boost_target_creature_until_eot_spell_v1","compose_on_resolution":true,"duration":"until_end_of_turn","effect":"stat_modifier_until_eot","power_boost":-6,"power_delta":-6,"target":"creature","target_constraints":{"card_types":["creature"]},"target_controller":"any","toughness_boost":-6,"toughness_delta":-6,"xmage_effect_class":"BoostTargetEffect"},{"battle_model_scope":"xmage_fixed_controller_gain_life_spell_v1","compose_on_resolution":true,"effect":"life_total_change","life_gain_amount":2,"target":"self","xmage_effect_class":"GainLifeEffect"}],"battle_model_scope":"xmage_fixed_boost_target_creature_until_eot_gain_life_spell_v1","effect":"composite_resolution","instant":true,"life_gain_amount":2,"power_boost":-6,"power_delta":-6,"resolution_order":"boost_then_gain","sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"]},"target_controller":"any","toughness_boost":-6,"toughness_delta":-6,"xmage_effect_classes":["BoostTargetEffect","GainLifeEffect"]}'::jsonb, '{"category":"draw","effect":"composite_resolution","target":"creature","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class SyphonFuel translated into ManaLoom runtime scope xmage_fixed_boost_target_creature_until_eot_gain_life_spell_v1. This row is package-ready only because the source signature is a narrow fixed target-creature boost plus controller life-gain spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('tandem tactics', 'Tandem Tactics', '84c5a871f4a5b344ae46515e616900d6', 'battle_rule_v1:6535eb0fb5f92bbde58e0340d48c6672', '{"_composite_rule_components":[{"battle_model_scope":"xmage_fixed_boost_target_creature_until_eot_spell_v1","compose_on_resolution":true,"duration":"until_end_of_turn","effect":"stat_modifier_until_eot","power_boost":1,"power_delta":1,"target":"creature","target_constraints":{"card_types":["creature"]},"target_controller":"any","target_count":2,"target_count_max":2,"target_count_min":0,"toughness_boost":2,"toughness_delta":2,"up_to_count":true,"xmage_effect_class":"BoostTargetEffect"},{"battle_model_scope":"xmage_fixed_controller_gain_life_spell_v1","compose_on_resolution":true,"effect":"life_total_change","life_gain_amount":2,"target":"self","xmage_effect_class":"GainLifeEffect"}],"battle_model_scope":"xmage_fixed_boost_target_creature_until_eot_gain_life_spell_v1","effect":"composite_resolution","instant":true,"life_gain_amount":2,"power_boost":1,"power_delta":1,"resolution_order":"boost_then_gain","sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"]},"target_controller":"any","target_count":2,"target_count_max":2,"target_count_min":0,"toughness_boost":2,"toughness_delta":2,"up_to_count":true,"xmage_effect_classes":["BoostTargetEffect","GainLifeEffect"]}'::jsonb, '{"category":"draw","effect":"composite_resolution","target":"creature","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class TandemTactics translated into ManaLoom runtime scope xmage_fixed_boost_target_creature_until_eot_gain_life_spell_v1. This row is package-ready only because the source signature is a narrow fixed target-creature boost plus controller life-gain spell with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
    ('moment of craving', 'Moment of Craving', 'dc486e3f0b4387b644d636f58918b41f', 'battle_rule_v1:b63f76d6ec9977d6406965136735a100', '{"_composite_rule_components":[{"battle_model_scope":"xmage_fixed_boost_target_creature_until_eot_spell_v1","compose_on_resolution":true,"duration":"until_end_of_turn","effect":"stat_modifier_until_eot","power_boost":-2,"power_delta":-2,"target":"creature","target_constraints":{"card_types":["creature"]},"target_controller":"any","toughness_boost":-2,"toughness_delta":-2,"xmage_effect_class":"BoostTargetEffect"},{"battle_model_scope":"xmage_fixed_controller_gain_life_spell_v1","compose_on_resolution":true,"effect":"life_total_change","life_gain_amount":2,"target":"self","xmage_effect_class":"GainLifeEffect"}],"battle_model_scope":"xmage_fixed_boost_target_creature_until_eot_gain_life_spell_v1","effect":"composite_resolution","instant":true,"life_gain_amount":2,"power_boost":-2,"power_delta":-2,"resolution_order":"boost_then_gain","sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"]},"target_controller":"any","toughness_boost":-2,"toughness_delta":-2,"xmage_effect_classes":["BoostTargetEffect","GainLifeEffect"]}'::jsonb, '{"category":"draw","effect":"composite_resolution","target":"creature","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class MomentOfCraving translated into ManaLoom runtime scope xmage_fixed_boost_target_creature_until_eot_gain_life_spell_v1. This row is package-ready only because the source signature is a narrow fixed target-creature boost plus controller life-gain spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('moment of triumph', 'Moment of Triumph', '5953b146ebacdef49f8cf977f511f0f6', 'battle_rule_v1:133a9d7b7187d216ca297d65b8d3028b', '{"_composite_rule_components":[{"battle_model_scope":"xmage_fixed_boost_target_creature_until_eot_spell_v1","compose_on_resolution":true,"duration":"until_end_of_turn","effect":"stat_modifier_until_eot","power_boost":2,"power_delta":2,"target":"creature","target_constraints":{"card_types":["creature"]},"target_controller":"any","toughness_boost":2,"toughness_delta":2,"xmage_effect_class":"BoostTargetEffect"},{"battle_model_scope":"xmage_fixed_controller_gain_life_spell_v1","compose_on_resolution":true,"effect":"life_total_change","life_gain_amount":2,"target":"self","xmage_effect_class":"GainLifeEffect"}],"battle_model_scope":"xmage_fixed_boost_target_creature_until_eot_gain_life_spell_v1","effect":"composite_resolution","instant":true,"life_gain_amount":2,"power_boost":2,"power_delta":2,"resolution_order":"boost_then_gain","sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"]},"target_controller":"any","toughness_boost":2,"toughness_delta":2,"xmage_effect_classes":["BoostTargetEffect","GainLifeEffect"]}'::jsonb, '{"category":"draw","effect":"composite_resolution","target":"creature","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class MomentOfTriumph translated into ManaLoom runtime scope xmage_fixed_boost_target_creature_until_eot_gain_life_spell_v1. This row is package-ready only because the source signature is a narrow fixed target-creature boost plus controller life-gain spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('syphon fuel', 'Syphon Fuel', '424c2ba6a7cd5c1a82e1bfd31594a768', 'battle_rule_v1:5a6480818679773b600d24b5f84861f6', '{"_composite_rule_components":[{"battle_model_scope":"xmage_fixed_boost_target_creature_until_eot_spell_v1","compose_on_resolution":true,"duration":"until_end_of_turn","effect":"stat_modifier_until_eot","power_boost":-6,"power_delta":-6,"target":"creature","target_constraints":{"card_types":["creature"]},"target_controller":"any","toughness_boost":-6,"toughness_delta":-6,"xmage_effect_class":"BoostTargetEffect"},{"battle_model_scope":"xmage_fixed_controller_gain_life_spell_v1","compose_on_resolution":true,"effect":"life_total_change","life_gain_amount":2,"target":"self","xmage_effect_class":"GainLifeEffect"}],"battle_model_scope":"xmage_fixed_boost_target_creature_until_eot_gain_life_spell_v1","effect":"composite_resolution","instant":true,"life_gain_amount":2,"power_boost":-6,"power_delta":-6,"resolution_order":"boost_then_gain","sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"]},"target_controller":"any","toughness_boost":-6,"toughness_delta":-6,"xmage_effect_classes":["BoostTargetEffect","GainLifeEffect"]}'::jsonb, '{"category":"draw","effect":"composite_resolution","target":"creature","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class SyphonFuel translated into ManaLoom runtime scope xmage_fixed_boost_target_creature_until_eot_gain_life_spell_v1. This row is package-ready only because the source signature is a narrow fixed target-creature boost plus controller life-gain spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('tandem tactics', 'Tandem Tactics', '84c5a871f4a5b344ae46515e616900d6', 'battle_rule_v1:6535eb0fb5f92bbde58e0340d48c6672', '{"_composite_rule_components":[{"battle_model_scope":"xmage_fixed_boost_target_creature_until_eot_spell_v1","compose_on_resolution":true,"duration":"until_end_of_turn","effect":"stat_modifier_until_eot","power_boost":1,"power_delta":1,"target":"creature","target_constraints":{"card_types":["creature"]},"target_controller":"any","target_count":2,"target_count_max":2,"target_count_min":0,"toughness_boost":2,"toughness_delta":2,"up_to_count":true,"xmage_effect_class":"BoostTargetEffect"},{"battle_model_scope":"xmage_fixed_controller_gain_life_spell_v1","compose_on_resolution":true,"effect":"life_total_change","life_gain_amount":2,"target":"self","xmage_effect_class":"GainLifeEffect"}],"battle_model_scope":"xmage_fixed_boost_target_creature_until_eot_gain_life_spell_v1","effect":"composite_resolution","instant":true,"life_gain_amount":2,"power_boost":1,"power_delta":1,"resolution_order":"boost_then_gain","sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"]},"target_controller":"any","target_count":2,"target_count_max":2,"target_count_min":0,"toughness_boost":2,"toughness_delta":2,"up_to_count":true,"xmage_effect_classes":["BoostTargetEffect","GainLifeEffect"]}'::jsonb, '{"category":"draw","effect":"composite_resolution","target":"creature","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class TandemTactics translated into ManaLoom runtime scope xmage_fixed_boost_target_creature_until_eot_gain_life_spell_v1. This row is package-ready only because the source signature is a narrow fixed target-creature boost plus controller life-gain spell with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
