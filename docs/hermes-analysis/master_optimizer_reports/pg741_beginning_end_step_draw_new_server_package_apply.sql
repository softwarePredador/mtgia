BEGIN;

CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit;

CREATE TABLE IF NOT EXISTS manaloom_deploy_audit.pg741_beginning_end_step_draw_new_server_20260711_045427 AS
SELECT *
FROM public.card_battle_rules
WHERE normalized_name IN ('deathreap ritual', 'mercadian atlas', 'owlbear shepherd', 'sygg, river cutthroat', 'the gaffer', 'twinblade assassins', 'well of discovery')
   OR normalized_name LIKE 'deathreap ritual // %'
   OR normalized_name LIKE 'mercadian atlas // %'
   OR normalized_name LIKE 'owlbear shepherd // %'
   OR normalized_name LIKE 'sygg, river cutthroat // %'
   OR normalized_name LIKE 'the gaffer // %'
   OR normalized_name LIKE 'twinblade assassins // %'
   OR normalized_name LIKE 'well of discovery // %';

DO $$
DECLARE
  v_missing jsonb;
BEGIN
  WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('deathreap ritual', 'Deathreap Ritual', '3a2b787a9baa1e5deb9cdf7d4c9412d0', 'battle_rule_v1:b96df7a05d6dd5cddfb8203c4c22a5f2', '{"ability_kind":"triggered","battle_model_scope":"xmage_beginning_end_step_conditional_draw_v1","effect":"draw_engine","end_step_draw_condition":"creature_died_this_turn","end_step_draw_condition_status":"runtime_executor_v1","end_step_draw_count":1,"end_step_draw_optional":true,"trigger":"each_end_step","trigger_effect":"draw_cards","xmage_ability_class":"BeginningOfEndStepTriggeredAbility","xmage_effect_class":"DrawCardSourceControllerEffect"}'::jsonb, '{"category":"draw","effect":"draw_engine"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class DeathreapRitual translated into ManaLoom runtime scope xmage_beginning_end_step_conditional_draw_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('mercadian atlas', 'Mercadian Atlas', 'c0cdb0863bf2a20247312e48ba4801e8', 'battle_rule_v1:7acc3adc0a28b308a447e6a850210efb', '{"ability_kind":"triggered","battle_model_scope":"xmage_beginning_end_step_conditional_draw_v1","effect":"draw_engine","end_step_draw_condition":"controller_did_not_play_land_this_turn","end_step_draw_condition_status":"runtime_executor_v1","end_step_draw_count":1,"end_step_draw_optional":true,"trigger":"controller_end_step","trigger_effect":"draw_cards","xmage_ability_class":"BeginningOfEndStepTriggeredAbility","xmage_effect_class":"DrawCardSourceControllerEffect"}'::jsonb, '{"category":"draw","effect":"draw_engine"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class MercadianAtlas translated into ManaLoom runtime scope xmage_beginning_end_step_conditional_draw_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('owlbear shepherd', 'Owlbear Shepherd', 'd30d89d549fe6fd0824f4d39537322ac', 'battle_rule_v1:12545c02f606b4ec5aa00e3aa833f1be', '{"ability_kind":"triggered","battle_model_scope":"xmage_beginning_end_step_conditional_draw_v1","effect":"creature","end_step_draw_condition":"controlled_creatures_total_power_gte","end_step_draw_condition_status":"runtime_executor_v1","end_step_draw_condition_threshold":8,"end_step_draw_count":1,"end_step_draw_optional":false,"is_creature_permanent":true,"trigger":"controller_end_step","trigger_effect":"draw_cards","xmage_ability_class":"BeginningOfEndStepTriggeredAbility","xmage_effect_class":"DrawCardSourceControllerEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class OwlbearShepherd translated into ManaLoom runtime scope xmage_beginning_end_step_conditional_draw_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('sygg, river cutthroat', 'Sygg, River Cutthroat', '9a7a849585f81a1e1c6199432027f213', 'battle_rule_v1:dd4b8987ae497ad050d0ada5e491d122', '{"ability_kind":"triggered","battle_model_scope":"xmage_beginning_end_step_conditional_draw_v1","effect":"creature","end_step_draw_condition":"opponent_lost_life_gte","end_step_draw_condition_status":"runtime_executor_v1","end_step_draw_condition_threshold":3,"end_step_draw_count":1,"end_step_draw_optional":true,"is_creature_permanent":true,"trigger":"each_end_step","trigger_effect":"draw_cards","xmage_ability_class":"BeginningOfEndStepTriggeredAbility","xmage_effect_class":"DrawCardSourceControllerEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class SyggRiverCutthroat translated into ManaLoom runtime scope xmage_beginning_end_step_conditional_draw_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('the gaffer', 'The Gaffer', 'f2cfb32b3314493afd737d0b6cae2a4f', 'battle_rule_v1:364521bf8772f4f0a3b3d283334411d0', '{"ability_kind":"triggered","battle_model_scope":"xmage_beginning_end_step_conditional_draw_v1","effect":"creature","end_step_draw_condition":"controller_gained_life_gte","end_step_draw_condition_status":"runtime_executor_v1","end_step_draw_condition_threshold":3,"end_step_draw_count":1,"end_step_draw_optional":false,"is_creature_permanent":true,"trigger":"each_end_step","trigger_effect":"draw_cards","xmage_ability_class":"BeginningOfEndStepTriggeredAbility","xmage_effect_class":"DrawCardSourceControllerEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class TheGaffer translated into ManaLoom runtime scope xmage_beginning_end_step_conditional_draw_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('twinblade assassins', 'Twinblade Assassins', 'c1ae690ea3d614c9e254fb4f27e93aff', 'battle_rule_v1:1506d707a427fb391ca0a225d35558d2', '{"ability_kind":"triggered","battle_model_scope":"xmage_beginning_end_step_conditional_draw_v1","effect":"creature","end_step_draw_condition":"creature_died_this_turn","end_step_draw_condition_status":"runtime_executor_v1","end_step_draw_count":1,"end_step_draw_optional":false,"is_creature_permanent":true,"trigger":"controller_end_step","trigger_effect":"draw_cards","xmage_ability_class":"BeginningOfEndStepTriggeredAbility","xmage_effect_class":"DrawCardSourceControllerEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class TwinbladeAssassins translated into ManaLoom runtime scope xmage_beginning_end_step_conditional_draw_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('well of discovery', 'Well of Discovery', '3afd21e4065afb7492b392e78a50e29b', 'battle_rule_v1:04931c0d85ab9f7a9b9f343969b897e0', '{"ability_kind":"triggered","battle_model_scope":"xmage_beginning_end_step_conditional_draw_v1","effect":"draw_engine","end_step_draw_condition":"controller_controls_no_untapped_lands","end_step_draw_condition_status":"runtime_executor_v1","end_step_draw_count":1,"end_step_draw_optional":false,"trigger":"controller_end_step","trigger_effect":"draw_cards","xmage_ability_class":"BeginningOfEndStepTriggeredAbility","xmage_effect_class":"DrawCardSourceControllerEffect"}'::jsonb, '{"category":"draw","effect":"draw_engine"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class WellOfDiscovery translated into ManaLoom runtime scope xmage_beginning_end_step_conditional_draw_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
    ('deathreap ritual', 'Deathreap Ritual', '3a2b787a9baa1e5deb9cdf7d4c9412d0', 'battle_rule_v1:b96df7a05d6dd5cddfb8203c4c22a5f2', '{"ability_kind":"triggered","battle_model_scope":"xmage_beginning_end_step_conditional_draw_v1","effect":"draw_engine","end_step_draw_condition":"creature_died_this_turn","end_step_draw_condition_status":"runtime_executor_v1","end_step_draw_count":1,"end_step_draw_optional":true,"trigger":"each_end_step","trigger_effect":"draw_cards","xmage_ability_class":"BeginningOfEndStepTriggeredAbility","xmage_effect_class":"DrawCardSourceControllerEffect"}'::jsonb, '{"category":"draw","effect":"draw_engine"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class DeathreapRitual translated into ManaLoom runtime scope xmage_beginning_end_step_conditional_draw_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('mercadian atlas', 'Mercadian Atlas', 'c0cdb0863bf2a20247312e48ba4801e8', 'battle_rule_v1:7acc3adc0a28b308a447e6a850210efb', '{"ability_kind":"triggered","battle_model_scope":"xmage_beginning_end_step_conditional_draw_v1","effect":"draw_engine","end_step_draw_condition":"controller_did_not_play_land_this_turn","end_step_draw_condition_status":"runtime_executor_v1","end_step_draw_count":1,"end_step_draw_optional":true,"trigger":"controller_end_step","trigger_effect":"draw_cards","xmage_ability_class":"BeginningOfEndStepTriggeredAbility","xmage_effect_class":"DrawCardSourceControllerEffect"}'::jsonb, '{"category":"draw","effect":"draw_engine"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class MercadianAtlas translated into ManaLoom runtime scope xmage_beginning_end_step_conditional_draw_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('owlbear shepherd', 'Owlbear Shepherd', 'd30d89d549fe6fd0824f4d39537322ac', 'battle_rule_v1:12545c02f606b4ec5aa00e3aa833f1be', '{"ability_kind":"triggered","battle_model_scope":"xmage_beginning_end_step_conditional_draw_v1","effect":"creature","end_step_draw_condition":"controlled_creatures_total_power_gte","end_step_draw_condition_status":"runtime_executor_v1","end_step_draw_condition_threshold":8,"end_step_draw_count":1,"end_step_draw_optional":false,"is_creature_permanent":true,"trigger":"controller_end_step","trigger_effect":"draw_cards","xmage_ability_class":"BeginningOfEndStepTriggeredAbility","xmage_effect_class":"DrawCardSourceControllerEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class OwlbearShepherd translated into ManaLoom runtime scope xmage_beginning_end_step_conditional_draw_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('sygg, river cutthroat', 'Sygg, River Cutthroat', '9a7a849585f81a1e1c6199432027f213', 'battle_rule_v1:dd4b8987ae497ad050d0ada5e491d122', '{"ability_kind":"triggered","battle_model_scope":"xmage_beginning_end_step_conditional_draw_v1","effect":"creature","end_step_draw_condition":"opponent_lost_life_gte","end_step_draw_condition_status":"runtime_executor_v1","end_step_draw_condition_threshold":3,"end_step_draw_count":1,"end_step_draw_optional":true,"is_creature_permanent":true,"trigger":"each_end_step","trigger_effect":"draw_cards","xmage_ability_class":"BeginningOfEndStepTriggeredAbility","xmage_effect_class":"DrawCardSourceControllerEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class SyggRiverCutthroat translated into ManaLoom runtime scope xmage_beginning_end_step_conditional_draw_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('the gaffer', 'The Gaffer', 'f2cfb32b3314493afd737d0b6cae2a4f', 'battle_rule_v1:364521bf8772f4f0a3b3d283334411d0', '{"ability_kind":"triggered","battle_model_scope":"xmage_beginning_end_step_conditional_draw_v1","effect":"creature","end_step_draw_condition":"controller_gained_life_gte","end_step_draw_condition_status":"runtime_executor_v1","end_step_draw_condition_threshold":3,"end_step_draw_count":1,"end_step_draw_optional":false,"is_creature_permanent":true,"trigger":"each_end_step","trigger_effect":"draw_cards","xmage_ability_class":"BeginningOfEndStepTriggeredAbility","xmage_effect_class":"DrawCardSourceControllerEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class TheGaffer translated into ManaLoom runtime scope xmage_beginning_end_step_conditional_draw_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('twinblade assassins', 'Twinblade Assassins', 'c1ae690ea3d614c9e254fb4f27e93aff', 'battle_rule_v1:1506d707a427fb391ca0a225d35558d2', '{"ability_kind":"triggered","battle_model_scope":"xmage_beginning_end_step_conditional_draw_v1","effect":"creature","end_step_draw_condition":"creature_died_this_turn","end_step_draw_condition_status":"runtime_executor_v1","end_step_draw_count":1,"end_step_draw_optional":false,"is_creature_permanent":true,"trigger":"controller_end_step","trigger_effect":"draw_cards","xmage_ability_class":"BeginningOfEndStepTriggeredAbility","xmage_effect_class":"DrawCardSourceControllerEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class TwinbladeAssassins translated into ManaLoom runtime scope xmage_beginning_end_step_conditional_draw_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('well of discovery', 'Well of Discovery', '3afd21e4065afb7492b392e78a50e29b', 'battle_rule_v1:04931c0d85ab9f7a9b9f343969b897e0', '{"ability_kind":"triggered","battle_model_scope":"xmage_beginning_end_step_conditional_draw_v1","effect":"draw_engine","end_step_draw_condition":"controller_controls_no_untapped_lands","end_step_draw_condition_status":"runtime_executor_v1","end_step_draw_count":1,"end_step_draw_optional":false,"trigger":"controller_end_step","trigger_effect":"draw_cards","xmage_ability_class":"BeginningOfEndStepTriggeredAbility","xmage_effect_class":"DrawCardSourceControllerEffect"}'::jsonb, '{"category":"draw","effect":"draw_engine"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class WellOfDiscovery translated into ManaLoom runtime scope xmage_beginning_end_step_conditional_draw_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
    ('deathreap ritual', 'Deathreap Ritual', '3a2b787a9baa1e5deb9cdf7d4c9412d0', 'battle_rule_v1:b96df7a05d6dd5cddfb8203c4c22a5f2', '{"ability_kind":"triggered","battle_model_scope":"xmage_beginning_end_step_conditional_draw_v1","effect":"draw_engine","end_step_draw_condition":"creature_died_this_turn","end_step_draw_condition_status":"runtime_executor_v1","end_step_draw_count":1,"end_step_draw_optional":true,"trigger":"each_end_step","trigger_effect":"draw_cards","xmage_ability_class":"BeginningOfEndStepTriggeredAbility","xmage_effect_class":"DrawCardSourceControllerEffect"}'::jsonb, '{"category":"draw","effect":"draw_engine"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class DeathreapRitual translated into ManaLoom runtime scope xmage_beginning_end_step_conditional_draw_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('mercadian atlas', 'Mercadian Atlas', 'c0cdb0863bf2a20247312e48ba4801e8', 'battle_rule_v1:7acc3adc0a28b308a447e6a850210efb', '{"ability_kind":"triggered","battle_model_scope":"xmage_beginning_end_step_conditional_draw_v1","effect":"draw_engine","end_step_draw_condition":"controller_did_not_play_land_this_turn","end_step_draw_condition_status":"runtime_executor_v1","end_step_draw_count":1,"end_step_draw_optional":true,"trigger":"controller_end_step","trigger_effect":"draw_cards","xmage_ability_class":"BeginningOfEndStepTriggeredAbility","xmage_effect_class":"DrawCardSourceControllerEffect"}'::jsonb, '{"category":"draw","effect":"draw_engine"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class MercadianAtlas translated into ManaLoom runtime scope xmage_beginning_end_step_conditional_draw_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('owlbear shepherd', 'Owlbear Shepherd', 'd30d89d549fe6fd0824f4d39537322ac', 'battle_rule_v1:12545c02f606b4ec5aa00e3aa833f1be', '{"ability_kind":"triggered","battle_model_scope":"xmage_beginning_end_step_conditional_draw_v1","effect":"creature","end_step_draw_condition":"controlled_creatures_total_power_gte","end_step_draw_condition_status":"runtime_executor_v1","end_step_draw_condition_threshold":8,"end_step_draw_count":1,"end_step_draw_optional":false,"is_creature_permanent":true,"trigger":"controller_end_step","trigger_effect":"draw_cards","xmage_ability_class":"BeginningOfEndStepTriggeredAbility","xmage_effect_class":"DrawCardSourceControllerEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class OwlbearShepherd translated into ManaLoom runtime scope xmage_beginning_end_step_conditional_draw_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('sygg, river cutthroat', 'Sygg, River Cutthroat', '9a7a849585f81a1e1c6199432027f213', 'battle_rule_v1:dd4b8987ae497ad050d0ada5e491d122', '{"ability_kind":"triggered","battle_model_scope":"xmage_beginning_end_step_conditional_draw_v1","effect":"creature","end_step_draw_condition":"opponent_lost_life_gte","end_step_draw_condition_status":"runtime_executor_v1","end_step_draw_condition_threshold":3,"end_step_draw_count":1,"end_step_draw_optional":true,"is_creature_permanent":true,"trigger":"each_end_step","trigger_effect":"draw_cards","xmage_ability_class":"BeginningOfEndStepTriggeredAbility","xmage_effect_class":"DrawCardSourceControllerEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class SyggRiverCutthroat translated into ManaLoom runtime scope xmage_beginning_end_step_conditional_draw_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('the gaffer', 'The Gaffer', 'f2cfb32b3314493afd737d0b6cae2a4f', 'battle_rule_v1:364521bf8772f4f0a3b3d283334411d0', '{"ability_kind":"triggered","battle_model_scope":"xmage_beginning_end_step_conditional_draw_v1","effect":"creature","end_step_draw_condition":"controller_gained_life_gte","end_step_draw_condition_status":"runtime_executor_v1","end_step_draw_condition_threshold":3,"end_step_draw_count":1,"end_step_draw_optional":false,"is_creature_permanent":true,"trigger":"each_end_step","trigger_effect":"draw_cards","xmage_ability_class":"BeginningOfEndStepTriggeredAbility","xmage_effect_class":"DrawCardSourceControllerEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class TheGaffer translated into ManaLoom runtime scope xmage_beginning_end_step_conditional_draw_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('twinblade assassins', 'Twinblade Assassins', 'c1ae690ea3d614c9e254fb4f27e93aff', 'battle_rule_v1:1506d707a427fb391ca0a225d35558d2', '{"ability_kind":"triggered","battle_model_scope":"xmage_beginning_end_step_conditional_draw_v1","effect":"creature","end_step_draw_condition":"creature_died_this_turn","end_step_draw_condition_status":"runtime_executor_v1","end_step_draw_count":1,"end_step_draw_optional":false,"is_creature_permanent":true,"trigger":"controller_end_step","trigger_effect":"draw_cards","xmage_ability_class":"BeginningOfEndStepTriggeredAbility","xmage_effect_class":"DrawCardSourceControllerEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class TwinbladeAssassins translated into ManaLoom runtime scope xmage_beginning_end_step_conditional_draw_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('well of discovery', 'Well of Discovery', '3afd21e4065afb7492b392e78a50e29b', 'battle_rule_v1:04931c0d85ab9f7a9b9f343969b897e0', '{"ability_kind":"triggered","battle_model_scope":"xmage_beginning_end_step_conditional_draw_v1","effect":"draw_engine","end_step_draw_condition":"controller_controls_no_untapped_lands","end_step_draw_condition_status":"runtime_executor_v1","end_step_draw_count":1,"end_step_draw_optional":false,"trigger":"controller_end_step","trigger_effect":"draw_cards","xmage_ability_class":"BeginningOfEndStepTriggeredAbility","xmage_effect_class":"DrawCardSourceControllerEffect"}'::jsonb, '{"category":"draw","effect":"draw_engine"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class WellOfDiscovery translated into ManaLoom runtime scope xmage_beginning_end_step_conditional_draw_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
