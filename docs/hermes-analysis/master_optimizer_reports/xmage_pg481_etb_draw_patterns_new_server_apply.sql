BEGIN;

CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit;

CREATE TABLE IF NOT EXISTS manaloom_deploy_audit.pg481_etb_draw_patterns_new_server_20260705_042634 AS
SELECT *
FROM public.card_battle_rules
WHERE normalized_name IN ('armorcraft judge', 'discerning peddler', 'earthshaker dreadmaw', 'fissure wizard', 'immersturm raider', 'keldon raider', 'plundering predator', 'prophet of the scarab', 'regal force', 'shinestriker', 'viashino racketeer', 'yuyan archers')
   OR normalized_name LIKE 'armorcraft judge // %'
   OR normalized_name LIKE 'discerning peddler // %'
   OR normalized_name LIKE 'earthshaker dreadmaw // %'
   OR normalized_name LIKE 'fissure wizard // %'
   OR normalized_name LIKE 'immersturm raider // %'
   OR normalized_name LIKE 'keldon raider // %'
   OR normalized_name LIKE 'plundering predator // %'
   OR normalized_name LIKE 'prophet of the scarab // %'
   OR normalized_name LIKE 'regal force // %'
   OR normalized_name LIKE 'shinestriker // %'
   OR normalized_name LIKE 'viashino racketeer // %'
   OR normalized_name LIKE 'yuyan archers // %';

DO $$
DECLARE
  v_missing jsonb;
BEGIN
  WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('armorcraft judge', 'Armorcraft Judge', '65f5fb37ad4d3ef91be154d862167c00', 'battle_rule_v1:798edea742b31763b31df11d91affedb', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_dynamic_draw_cards_v1","draw_count_source":"controlled_creatures_with_plus_one_counters","effect":"creature","etb_draw_count_source":"controlled_creatures_with_plus_one_counters","etb_dynamic_draw":true,"trigger":"enters_battlefield","trigger_effect":"dynamic_draw_cards","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"DrawCardSourceControllerEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ArmorcraftJudge translated into ManaLoom runtime scope xmage_creature_etb_dynamic_draw_cards_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('discerning peddler', 'Discerning Peddler', '4a03049727dc8bd1d3276fb24ac19ac4', 'battle_rule_v1:ce63d2591507d67fedbe7b9df933dd56', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_optional_discard_draw_cards_v1","draw_count":1,"effect":"creature","etb_optional_discard_count":1,"etb_optional_discard_draw":true,"etb_optional_discard_draw_count":1,"trigger":"enters_battlefield","trigger_effect":"optional_discard_draw","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"DrawCardSourceControllerEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class DiscerningPeddler translated into ManaLoom runtime scope xmage_creature_etb_optional_discard_draw_cards_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('earthshaker dreadmaw', 'Earthshaker Dreadmaw', '205fdf4d16a9f7b152df40dbb8ef2cb0', 'battle_rule_v1:1460d9964a9c870fce4a888c0305aff5', '{"_keywords_are_self":true,"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_dynamic_draw_cards_v1","draw_count_exclude_source":true,"draw_count_source":"controlled_creatures_with_subtype","draw_count_subtype":"dinosaur","effect":"creature","etb_draw_count_exclude_source":true,"etb_draw_count_source":"controlled_creatures_with_subtype","etb_draw_count_subtype":"dinosaur","etb_dynamic_draw":true,"keywords":["trample"],"trample":true,"trigger":"enters_battlefield","trigger_effect":"dynamic_draw_cards","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"DrawCardSourceControllerEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class EarthshakerDreadmaw translated into ManaLoom runtime scope xmage_creature_etb_dynamic_draw_cards_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('fissure wizard', 'Fissure Wizard', '4a03049727dc8bd1d3276fb24ac19ac4', 'battle_rule_v1:ce63d2591507d67fedbe7b9df933dd56', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_optional_discard_draw_cards_v1","draw_count":1,"effect":"creature","etb_optional_discard_count":1,"etb_optional_discard_draw":true,"etb_optional_discard_draw_count":1,"trigger":"enters_battlefield","trigger_effect":"optional_discard_draw","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"DrawCardSourceControllerEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class FissureWizard translated into ManaLoom runtime scope xmage_creature_etb_optional_discard_draw_cards_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('immersturm raider', 'Immersturm Raider', '4a03049727dc8bd1d3276fb24ac19ac4', 'battle_rule_v1:ce63d2591507d67fedbe7b9df933dd56', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_optional_discard_draw_cards_v1","draw_count":1,"effect":"creature","etb_optional_discard_count":1,"etb_optional_discard_draw":true,"etb_optional_discard_draw_count":1,"trigger":"enters_battlefield","trigger_effect":"optional_discard_draw","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"DrawCardSourceControllerEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ImmersturmRaider translated into ManaLoom runtime scope xmage_creature_etb_optional_discard_draw_cards_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('keldon raider', 'Keldon Raider', '4a03049727dc8bd1d3276fb24ac19ac4', 'battle_rule_v1:ce63d2591507d67fedbe7b9df933dd56', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_optional_discard_draw_cards_v1","draw_count":1,"effect":"creature","etb_optional_discard_count":1,"etb_optional_discard_draw":true,"etb_optional_discard_draw_count":1,"trigger":"enters_battlefield","trigger_effect":"optional_discard_draw","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"DrawCardSourceControllerEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class KeldonRaider translated into ManaLoom runtime scope xmage_creature_etb_optional_discard_draw_cards_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('plundering predator', 'Plundering Predator', '6bdbcc08451103c672467cdb832b2a5d', 'battle_rule_v1:5d8abd3f06a8143d6e95a9b6dc7d3ae6', '{"_keywords_are_self":true,"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_optional_discard_draw_cards_v1","draw_count":1,"effect":"creature","etb_optional_discard_count":1,"etb_optional_discard_draw":true,"etb_optional_discard_draw_count":1,"flying":true,"keywords":["flying"],"trigger":"enters_battlefield","trigger_effect":"optional_discard_draw","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"DrawCardSourceControllerEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class PlunderingPredator translated into ManaLoom runtime scope xmage_creature_etb_optional_discard_draw_cards_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('prophet of the scarab', 'Prophet of the Scarab', '9a05c6788d82d45f4afd8fdbc6c4f840', 'battle_rule_v1:f3b0129add2da610315a846e26298047', '{"_keywords_are_self":true,"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_dynamic_draw_cards_v1","draw_count_source":"max_controlled_creatures_or_graveyard_cards_with_subtype","draw_count_subtype":"zombie","effect":"creature","etb_draw_count_source":"max_controlled_creatures_or_graveyard_cards_with_subtype","etb_draw_count_subtype":"zombie","etb_dynamic_draw":true,"keywords":["vigilance"],"trigger":"enters_battlefield","trigger_effect":"dynamic_draw_cards","vigilance":true,"xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"DrawCardSourceControllerEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ProphetOfTheScarab translated into ManaLoom runtime scope xmage_creature_etb_dynamic_draw_cards_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('regal force', 'Regal Force', 'e1cc181a4a7dbe2ab2f4e134e645bd44', 'battle_rule_v1:0737848ba92559e79a57f30ddc669023', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_dynamic_draw_cards_v1","draw_count_color":"green","draw_count_source":"controlled_creatures_with_color","effect":"creature","etb_draw_count_color":"green","etb_draw_count_source":"controlled_creatures_with_color","etb_dynamic_draw":true,"trigger":"enters_battlefield","trigger_effect":"dynamic_draw_cards","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"DrawCardSourceControllerEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class RegalForce translated into ManaLoom runtime scope xmage_creature_etb_dynamic_draw_cards_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('shinestriker', 'Shinestriker', '8d47d7ff785ff98afeee18f1299c248f', 'battle_rule_v1:0cbc771700ceb397b083bd2407570aa0', '{"_keywords_are_self":true,"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_dynamic_draw_cards_v1","draw_count_source":"colors_among_permanents_you_control","effect":"creature","etb_draw_count_source":"colors_among_permanents_you_control","etb_dynamic_draw":true,"flying":true,"keywords":["flying"],"trigger":"enters_battlefield","trigger_effect":"dynamic_draw_cards","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"DrawCardSourceControllerEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Shinestriker translated into ManaLoom runtime scope xmage_creature_etb_dynamic_draw_cards_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('viashino racketeer', 'Viashino Racketeer', '4a03049727dc8bd1d3276fb24ac19ac4', 'battle_rule_v1:ce63d2591507d67fedbe7b9df933dd56', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_optional_discard_draw_cards_v1","draw_count":1,"effect":"creature","etb_optional_discard_count":1,"etb_optional_discard_draw":true,"etb_optional_discard_draw_count":1,"trigger":"enters_battlefield","trigger_effect":"optional_discard_draw","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"DrawCardSourceControllerEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ViashinoRacketeer translated into ManaLoom runtime scope xmage_creature_etb_optional_discard_draw_cards_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('yuyan archers', 'Yuyan Archers', '440c853db32deb7135135b5b6c743416', 'battle_rule_v1:131bdd23e09ae22db069dfc8ad08e46c', '{"_keywords_are_self":true,"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_optional_discard_draw_cards_v1","draw_count":1,"effect":"creature","etb_optional_discard_count":1,"etb_optional_discard_draw":true,"etb_optional_discard_draw_count":1,"keywords":["reach"],"reach":true,"trigger":"enters_battlefield","trigger_effect":"optional_discard_draw","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"DrawCardSourceControllerEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class YuyanArchers translated into ManaLoom runtime scope xmage_creature_etb_optional_discard_draw_cards_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
    ('armorcraft judge', 'Armorcraft Judge', '65f5fb37ad4d3ef91be154d862167c00', 'battle_rule_v1:798edea742b31763b31df11d91affedb', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_dynamic_draw_cards_v1","draw_count_source":"controlled_creatures_with_plus_one_counters","effect":"creature","etb_draw_count_source":"controlled_creatures_with_plus_one_counters","etb_dynamic_draw":true,"trigger":"enters_battlefield","trigger_effect":"dynamic_draw_cards","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"DrawCardSourceControllerEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ArmorcraftJudge translated into ManaLoom runtime scope xmage_creature_etb_dynamic_draw_cards_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('discerning peddler', 'Discerning Peddler', '4a03049727dc8bd1d3276fb24ac19ac4', 'battle_rule_v1:ce63d2591507d67fedbe7b9df933dd56', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_optional_discard_draw_cards_v1","draw_count":1,"effect":"creature","etb_optional_discard_count":1,"etb_optional_discard_draw":true,"etb_optional_discard_draw_count":1,"trigger":"enters_battlefield","trigger_effect":"optional_discard_draw","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"DrawCardSourceControllerEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class DiscerningPeddler translated into ManaLoom runtime scope xmage_creature_etb_optional_discard_draw_cards_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('earthshaker dreadmaw', 'Earthshaker Dreadmaw', '205fdf4d16a9f7b152df40dbb8ef2cb0', 'battle_rule_v1:1460d9964a9c870fce4a888c0305aff5', '{"_keywords_are_self":true,"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_dynamic_draw_cards_v1","draw_count_exclude_source":true,"draw_count_source":"controlled_creatures_with_subtype","draw_count_subtype":"dinosaur","effect":"creature","etb_draw_count_exclude_source":true,"etb_draw_count_source":"controlled_creatures_with_subtype","etb_draw_count_subtype":"dinosaur","etb_dynamic_draw":true,"keywords":["trample"],"trample":true,"trigger":"enters_battlefield","trigger_effect":"dynamic_draw_cards","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"DrawCardSourceControllerEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class EarthshakerDreadmaw translated into ManaLoom runtime scope xmage_creature_etb_dynamic_draw_cards_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('fissure wizard', 'Fissure Wizard', '4a03049727dc8bd1d3276fb24ac19ac4', 'battle_rule_v1:ce63d2591507d67fedbe7b9df933dd56', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_optional_discard_draw_cards_v1","draw_count":1,"effect":"creature","etb_optional_discard_count":1,"etb_optional_discard_draw":true,"etb_optional_discard_draw_count":1,"trigger":"enters_battlefield","trigger_effect":"optional_discard_draw","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"DrawCardSourceControllerEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class FissureWizard translated into ManaLoom runtime scope xmage_creature_etb_optional_discard_draw_cards_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('immersturm raider', 'Immersturm Raider', '4a03049727dc8bd1d3276fb24ac19ac4', 'battle_rule_v1:ce63d2591507d67fedbe7b9df933dd56', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_optional_discard_draw_cards_v1","draw_count":1,"effect":"creature","etb_optional_discard_count":1,"etb_optional_discard_draw":true,"etb_optional_discard_draw_count":1,"trigger":"enters_battlefield","trigger_effect":"optional_discard_draw","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"DrawCardSourceControllerEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ImmersturmRaider translated into ManaLoom runtime scope xmage_creature_etb_optional_discard_draw_cards_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('keldon raider', 'Keldon Raider', '4a03049727dc8bd1d3276fb24ac19ac4', 'battle_rule_v1:ce63d2591507d67fedbe7b9df933dd56', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_optional_discard_draw_cards_v1","draw_count":1,"effect":"creature","etb_optional_discard_count":1,"etb_optional_discard_draw":true,"etb_optional_discard_draw_count":1,"trigger":"enters_battlefield","trigger_effect":"optional_discard_draw","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"DrawCardSourceControllerEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class KeldonRaider translated into ManaLoom runtime scope xmage_creature_etb_optional_discard_draw_cards_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('plundering predator', 'Plundering Predator', '6bdbcc08451103c672467cdb832b2a5d', 'battle_rule_v1:5d8abd3f06a8143d6e95a9b6dc7d3ae6', '{"_keywords_are_self":true,"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_optional_discard_draw_cards_v1","draw_count":1,"effect":"creature","etb_optional_discard_count":1,"etb_optional_discard_draw":true,"etb_optional_discard_draw_count":1,"flying":true,"keywords":["flying"],"trigger":"enters_battlefield","trigger_effect":"optional_discard_draw","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"DrawCardSourceControllerEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class PlunderingPredator translated into ManaLoom runtime scope xmage_creature_etb_optional_discard_draw_cards_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('prophet of the scarab', 'Prophet of the Scarab', '9a05c6788d82d45f4afd8fdbc6c4f840', 'battle_rule_v1:f3b0129add2da610315a846e26298047', '{"_keywords_are_self":true,"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_dynamic_draw_cards_v1","draw_count_source":"max_controlled_creatures_or_graveyard_cards_with_subtype","draw_count_subtype":"zombie","effect":"creature","etb_draw_count_source":"max_controlled_creatures_or_graveyard_cards_with_subtype","etb_draw_count_subtype":"zombie","etb_dynamic_draw":true,"keywords":["vigilance"],"trigger":"enters_battlefield","trigger_effect":"dynamic_draw_cards","vigilance":true,"xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"DrawCardSourceControllerEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ProphetOfTheScarab translated into ManaLoom runtime scope xmage_creature_etb_dynamic_draw_cards_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('regal force', 'Regal Force', 'e1cc181a4a7dbe2ab2f4e134e645bd44', 'battle_rule_v1:0737848ba92559e79a57f30ddc669023', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_dynamic_draw_cards_v1","draw_count_color":"green","draw_count_source":"controlled_creatures_with_color","effect":"creature","etb_draw_count_color":"green","etb_draw_count_source":"controlled_creatures_with_color","etb_dynamic_draw":true,"trigger":"enters_battlefield","trigger_effect":"dynamic_draw_cards","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"DrawCardSourceControllerEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class RegalForce translated into ManaLoom runtime scope xmage_creature_etb_dynamic_draw_cards_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('shinestriker', 'Shinestriker', '8d47d7ff785ff98afeee18f1299c248f', 'battle_rule_v1:0cbc771700ceb397b083bd2407570aa0', '{"_keywords_are_self":true,"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_dynamic_draw_cards_v1","draw_count_source":"colors_among_permanents_you_control","effect":"creature","etb_draw_count_source":"colors_among_permanents_you_control","etb_dynamic_draw":true,"flying":true,"keywords":["flying"],"trigger":"enters_battlefield","trigger_effect":"dynamic_draw_cards","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"DrawCardSourceControllerEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Shinestriker translated into ManaLoom runtime scope xmage_creature_etb_dynamic_draw_cards_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('viashino racketeer', 'Viashino Racketeer', '4a03049727dc8bd1d3276fb24ac19ac4', 'battle_rule_v1:ce63d2591507d67fedbe7b9df933dd56', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_optional_discard_draw_cards_v1","draw_count":1,"effect":"creature","etb_optional_discard_count":1,"etb_optional_discard_draw":true,"etb_optional_discard_draw_count":1,"trigger":"enters_battlefield","trigger_effect":"optional_discard_draw","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"DrawCardSourceControllerEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ViashinoRacketeer translated into ManaLoom runtime scope xmage_creature_etb_optional_discard_draw_cards_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('yuyan archers', 'Yuyan Archers', '440c853db32deb7135135b5b6c743416', 'battle_rule_v1:131bdd23e09ae22db069dfc8ad08e46c', '{"_keywords_are_self":true,"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_optional_discard_draw_cards_v1","draw_count":1,"effect":"creature","etb_optional_discard_count":1,"etb_optional_discard_draw":true,"etb_optional_discard_draw_count":1,"keywords":["reach"],"reach":true,"trigger":"enters_battlefield","trigger_effect":"optional_discard_draw","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"DrawCardSourceControllerEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class YuyanArchers translated into ManaLoom runtime scope xmage_creature_etb_optional_discard_draw_cards_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
    ('armorcraft judge', 'Armorcraft Judge', '65f5fb37ad4d3ef91be154d862167c00', 'battle_rule_v1:798edea742b31763b31df11d91affedb', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_dynamic_draw_cards_v1","draw_count_source":"controlled_creatures_with_plus_one_counters","effect":"creature","etb_draw_count_source":"controlled_creatures_with_plus_one_counters","etb_dynamic_draw":true,"trigger":"enters_battlefield","trigger_effect":"dynamic_draw_cards","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"DrawCardSourceControllerEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ArmorcraftJudge translated into ManaLoom runtime scope xmage_creature_etb_dynamic_draw_cards_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('discerning peddler', 'Discerning Peddler', '4a03049727dc8bd1d3276fb24ac19ac4', 'battle_rule_v1:ce63d2591507d67fedbe7b9df933dd56', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_optional_discard_draw_cards_v1","draw_count":1,"effect":"creature","etb_optional_discard_count":1,"etb_optional_discard_draw":true,"etb_optional_discard_draw_count":1,"trigger":"enters_battlefield","trigger_effect":"optional_discard_draw","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"DrawCardSourceControllerEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class DiscerningPeddler translated into ManaLoom runtime scope xmage_creature_etb_optional_discard_draw_cards_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('earthshaker dreadmaw', 'Earthshaker Dreadmaw', '205fdf4d16a9f7b152df40dbb8ef2cb0', 'battle_rule_v1:1460d9964a9c870fce4a888c0305aff5', '{"_keywords_are_self":true,"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_dynamic_draw_cards_v1","draw_count_exclude_source":true,"draw_count_source":"controlled_creatures_with_subtype","draw_count_subtype":"dinosaur","effect":"creature","etb_draw_count_exclude_source":true,"etb_draw_count_source":"controlled_creatures_with_subtype","etb_draw_count_subtype":"dinosaur","etb_dynamic_draw":true,"keywords":["trample"],"trample":true,"trigger":"enters_battlefield","trigger_effect":"dynamic_draw_cards","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"DrawCardSourceControllerEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class EarthshakerDreadmaw translated into ManaLoom runtime scope xmage_creature_etb_dynamic_draw_cards_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('fissure wizard', 'Fissure Wizard', '4a03049727dc8bd1d3276fb24ac19ac4', 'battle_rule_v1:ce63d2591507d67fedbe7b9df933dd56', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_optional_discard_draw_cards_v1","draw_count":1,"effect":"creature","etb_optional_discard_count":1,"etb_optional_discard_draw":true,"etb_optional_discard_draw_count":1,"trigger":"enters_battlefield","trigger_effect":"optional_discard_draw","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"DrawCardSourceControllerEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class FissureWizard translated into ManaLoom runtime scope xmage_creature_etb_optional_discard_draw_cards_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('immersturm raider', 'Immersturm Raider', '4a03049727dc8bd1d3276fb24ac19ac4', 'battle_rule_v1:ce63d2591507d67fedbe7b9df933dd56', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_optional_discard_draw_cards_v1","draw_count":1,"effect":"creature","etb_optional_discard_count":1,"etb_optional_discard_draw":true,"etb_optional_discard_draw_count":1,"trigger":"enters_battlefield","trigger_effect":"optional_discard_draw","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"DrawCardSourceControllerEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ImmersturmRaider translated into ManaLoom runtime scope xmage_creature_etb_optional_discard_draw_cards_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('keldon raider', 'Keldon Raider', '4a03049727dc8bd1d3276fb24ac19ac4', 'battle_rule_v1:ce63d2591507d67fedbe7b9df933dd56', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_optional_discard_draw_cards_v1","draw_count":1,"effect":"creature","etb_optional_discard_count":1,"etb_optional_discard_draw":true,"etb_optional_discard_draw_count":1,"trigger":"enters_battlefield","trigger_effect":"optional_discard_draw","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"DrawCardSourceControllerEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class KeldonRaider translated into ManaLoom runtime scope xmage_creature_etb_optional_discard_draw_cards_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('plundering predator', 'Plundering Predator', '6bdbcc08451103c672467cdb832b2a5d', 'battle_rule_v1:5d8abd3f06a8143d6e95a9b6dc7d3ae6', '{"_keywords_are_self":true,"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_optional_discard_draw_cards_v1","draw_count":1,"effect":"creature","etb_optional_discard_count":1,"etb_optional_discard_draw":true,"etb_optional_discard_draw_count":1,"flying":true,"keywords":["flying"],"trigger":"enters_battlefield","trigger_effect":"optional_discard_draw","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"DrawCardSourceControllerEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class PlunderingPredator translated into ManaLoom runtime scope xmage_creature_etb_optional_discard_draw_cards_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('prophet of the scarab', 'Prophet of the Scarab', '9a05c6788d82d45f4afd8fdbc6c4f840', 'battle_rule_v1:f3b0129add2da610315a846e26298047', '{"_keywords_are_self":true,"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_dynamic_draw_cards_v1","draw_count_source":"max_controlled_creatures_or_graveyard_cards_with_subtype","draw_count_subtype":"zombie","effect":"creature","etb_draw_count_source":"max_controlled_creatures_or_graveyard_cards_with_subtype","etb_draw_count_subtype":"zombie","etb_dynamic_draw":true,"keywords":["vigilance"],"trigger":"enters_battlefield","trigger_effect":"dynamic_draw_cards","vigilance":true,"xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"DrawCardSourceControllerEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ProphetOfTheScarab translated into ManaLoom runtime scope xmage_creature_etb_dynamic_draw_cards_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('regal force', 'Regal Force', 'e1cc181a4a7dbe2ab2f4e134e645bd44', 'battle_rule_v1:0737848ba92559e79a57f30ddc669023', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_dynamic_draw_cards_v1","draw_count_color":"green","draw_count_source":"controlled_creatures_with_color","effect":"creature","etb_draw_count_color":"green","etb_draw_count_source":"controlled_creatures_with_color","etb_dynamic_draw":true,"trigger":"enters_battlefield","trigger_effect":"dynamic_draw_cards","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"DrawCardSourceControllerEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class RegalForce translated into ManaLoom runtime scope xmage_creature_etb_dynamic_draw_cards_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('shinestriker', 'Shinestriker', '8d47d7ff785ff98afeee18f1299c248f', 'battle_rule_v1:0cbc771700ceb397b083bd2407570aa0', '{"_keywords_are_self":true,"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_dynamic_draw_cards_v1","draw_count_source":"colors_among_permanents_you_control","effect":"creature","etb_draw_count_source":"colors_among_permanents_you_control","etb_dynamic_draw":true,"flying":true,"keywords":["flying"],"trigger":"enters_battlefield","trigger_effect":"dynamic_draw_cards","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"DrawCardSourceControllerEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Shinestriker translated into ManaLoom runtime scope xmage_creature_etb_dynamic_draw_cards_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('viashino racketeer', 'Viashino Racketeer', '4a03049727dc8bd1d3276fb24ac19ac4', 'battle_rule_v1:ce63d2591507d67fedbe7b9df933dd56', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_optional_discard_draw_cards_v1","draw_count":1,"effect":"creature","etb_optional_discard_count":1,"etb_optional_discard_draw":true,"etb_optional_discard_draw_count":1,"trigger":"enters_battlefield","trigger_effect":"optional_discard_draw","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"DrawCardSourceControllerEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ViashinoRacketeer translated into ManaLoom runtime scope xmage_creature_etb_optional_discard_draw_cards_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('yuyan archers', 'Yuyan Archers', '440c853db32deb7135135b5b6c743416', 'battle_rule_v1:131bdd23e09ae22db069dfc8ad08e46c', '{"_keywords_are_self":true,"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_optional_discard_draw_cards_v1","draw_count":1,"effect":"creature","etb_optional_discard_count":1,"etb_optional_discard_draw":true,"etb_optional_discard_draw_count":1,"keywords":["reach"],"reach":true,"trigger":"enters_battlefield","trigger_effect":"optional_discard_draw","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"DrawCardSourceControllerEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class YuyanArchers translated into ManaLoom runtime scope xmage_creature_etb_optional_discard_draw_cards_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
