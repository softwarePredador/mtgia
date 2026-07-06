BEGIN;

CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit;

CREATE TABLE IF NOT EXISTS manaloom_deploy_audit.pg557_etb_dynamic_life_gain_new_server_e_20260706_071903 AS
SELECT *
FROM public.card_battle_rules
WHERE normalized_name IN ('ancestor''s chosen', 'angel of renewal', 'archway angel', 'aven gagglemaster', 'dwarven priest', 'flourishing hunter', 'goldnight redeemer', 'kraul foragers', 'luminollusk', 'nylea''s disciple', 'setessan petitioner', 'shepherd of heroes')
   OR normalized_name LIKE 'ancestor''s chosen // %'
   OR normalized_name LIKE 'angel of renewal // %'
   OR normalized_name LIKE 'archway angel // %'
   OR normalized_name LIKE 'aven gagglemaster // %'
   OR normalized_name LIKE 'dwarven priest // %'
   OR normalized_name LIKE 'flourishing hunter // %'
   OR normalized_name LIKE 'goldnight redeemer // %'
   OR normalized_name LIKE 'kraul foragers // %'
   OR normalized_name LIKE 'luminollusk // %'
   OR normalized_name LIKE 'nylea''s disciple // %'
   OR normalized_name LIKE 'setessan petitioner // %'
   OR normalized_name LIKE 'shepherd of heroes // %';

DO $$
DECLARE
  v_missing jsonb;
BEGIN
  WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('ancestor''s chosen', 'Ancestor''s Chosen', 'b747a70ff698503803efb0a8f90684c7', 'battle_rule_v1:b32118535b258365f98ae0a7fac3d53f', '{"_keywords_are_self":true,"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_dynamic_gain_life_v1","effect":"creature","etb_dynamic_life_gain":true,"first_strike":true,"graveyard_count_card_types":["card"],"graveyard_count_scope":"controller_graveyard","keywords":["first_strike"],"life_gain_amount_source":"graveyard_card_count","life_gain_base_amount":0,"life_gain_per_count":1,"trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"GainLifeEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class AncestorsChosen translated into ManaLoom runtime scope xmage_creature_etb_dynamic_gain_life_v1. This row is package-ready only because the source signature is a narrow creature ETB dynamic life-gain trigger with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('angel of renewal', 'Angel of Renewal', '4a915f33c4d231cbfbc6dc2806a98b30', 'battle_rule_v1:431fb7d37e21b6b06fc6917347dea517', '{"_keywords_are_self":true,"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_dynamic_gain_life_v1","battlefield_count_card_types":["creature"],"battlefield_count_scope":"controller_battlefield","effect":"creature","etb_dynamic_life_gain":true,"flying":true,"keywords":["flying"],"life_gain_amount_source":"battlefield_permanent_count","life_gain_base_amount":0,"life_gain_per_count":1,"trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"GainLifeEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class AngelOfRenewal translated into ManaLoom runtime scope xmage_creature_etb_dynamic_gain_life_v1. This row is package-ready only because the source signature is a narrow creature ETB dynamic life-gain trigger with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('archway angel', 'Archway Angel', 'c5369f445beae5a071259be3c0fadc2b', 'battle_rule_v1:4ba0dcd58b32218ce9543906e1125e00', '{"_keywords_are_self":true,"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_dynamic_gain_life_v1","battlefield_count_card_types":["permanent"],"battlefield_count_scope":"controller_battlefield","battlefield_count_subtypes":["gate"],"effect":"creature","etb_dynamic_life_gain":true,"flying":true,"keywords":["flying"],"life_gain_amount_source":"battlefield_permanent_count","life_gain_base_amount":0,"life_gain_per_count":2,"trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"GainLifeEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ArchwayAngel translated into ManaLoom runtime scope xmage_creature_etb_dynamic_gain_life_v1. This row is package-ready only because the source signature is a narrow creature ETB dynamic life-gain trigger with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('aven gagglemaster', 'Aven Gagglemaster', 'e74d2cc5afe677794289fe82ff3e0b43', 'battle_rule_v1:c9a00ec32e4c03c98efb5bb532c8a37a', '{"_keywords_are_self":true,"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_dynamic_gain_life_v1","battlefield_count_card_types":["creature"],"battlefield_count_keywords":["flying"],"battlefield_count_scope":"controller_battlefield","effect":"creature","etb_dynamic_life_gain":true,"flying":true,"keywords":["flying"],"life_gain_amount_source":"battlefield_permanent_count","life_gain_base_amount":0,"life_gain_per_count":2,"trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"GainLifeEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class AvenGagglemaster translated into ManaLoom runtime scope xmage_creature_etb_dynamic_gain_life_v1. This row is package-ready only because the source signature is a narrow creature ETB dynamic life-gain trigger with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('dwarven priest', 'Dwarven Priest', '808da1862ca641ddfd5cf92cda70025f', 'battle_rule_v1:6b63db417a759f8bb7ed56e89b6b5115', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_dynamic_gain_life_v1","battlefield_count_card_types":["creature"],"battlefield_count_scope":"controller_battlefield","effect":"creature","etb_dynamic_life_gain":true,"life_gain_amount_source":"battlefield_permanent_count","life_gain_base_amount":0,"life_gain_per_count":1,"trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"GainLifeEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class DwarvenPriest translated into ManaLoom runtime scope xmage_creature_etb_dynamic_gain_life_v1. This row is package-ready only because the source signature is a narrow creature ETB dynamic life-gain trigger with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('flourishing hunter', 'Flourishing Hunter', '4176d051992a19b744dad7fbcb7208a6', 'battle_rule_v1:dc06aa6c8a2edc5468ccf15367a43e40', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_dynamic_gain_life_v1","effect":"creature","etb_dynamic_life_gain":true,"life_gain_amount_source":"greatest_toughness_among_other_controlled_creatures","life_gain_base_amount":0,"life_gain_per_count":1,"trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"GainLifeEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class FlourishingHunter translated into ManaLoom runtime scope xmage_creature_etb_dynamic_gain_life_v1. This row is package-ready only because the source signature is a narrow creature ETB dynamic life-gain trigger with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('goldnight redeemer', 'Goldnight Redeemer', '53cb387e4cfa6073108d2521f02afa06', 'battle_rule_v1:891b42c06ce7f173aee31bd60f87222e', '{"_keywords_are_self":true,"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_dynamic_gain_life_v1","battlefield_count_card_types":["creature"],"battlefield_count_exclude_source":true,"battlefield_count_scope":"controller_battlefield","effect":"creature","etb_dynamic_life_gain":true,"flying":true,"keywords":["flying"],"life_gain_amount_source":"battlefield_permanent_count","life_gain_base_amount":0,"life_gain_per_count":2,"trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"GainLifeEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class GoldnightRedeemer translated into ManaLoom runtime scope xmage_creature_etb_dynamic_gain_life_v1. This row is package-ready only because the source signature is a narrow creature ETB dynamic life-gain trigger with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('kraul foragers', 'Kraul Foragers', '1d6314de33c255299d46542a146400bd', 'battle_rule_v1:dd60c22d45ed324b92e12c77deb12018', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_dynamic_gain_life_v1","effect":"creature","etb_dynamic_life_gain":true,"graveyard_count_card_types":["creature"],"graveyard_count_scope":"controller_graveyard","life_gain_amount_source":"graveyard_card_count","life_gain_base_amount":0,"life_gain_per_count":1,"trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"GainLifeEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class KraulForagers translated into ManaLoom runtime scope xmage_creature_etb_dynamic_gain_life_v1. This row is package-ready only because the source signature is a narrow creature ETB dynamic life-gain trigger with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('luminollusk', 'Luminollusk', 'c3be1e29deac8bd4e2ab1a7a11aa6150', 'battle_rule_v1:d4009ce1c19af31609c05dc4110c30b0', '{"_keywords_are_self":true,"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_dynamic_gain_life_v1","deathtouch":true,"effect":"creature","etb_dynamic_life_gain":true,"keywords":["deathtouch"],"life_gain_amount_source":"colors_among_permanents_you_control","life_gain_base_amount":0,"life_gain_per_count":1,"trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"GainLifeEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Luminollusk translated into ManaLoom runtime scope xmage_creature_etb_dynamic_gain_life_v1. This row is package-ready only because the source signature is a narrow creature ETB dynamic life-gain trigger with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('nylea''s disciple', 'Nylea''s Disciple', '68590e842acf21eba3bc15e0297a4e6f', 'battle_rule_v1:eaf661bb562df70f38ab3ec27704a383', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_dynamic_gain_life_v1","effect":"creature","etb_dynamic_life_gain":true,"life_gain_amount_source":"controlled_permanents_mana_symbol_count","life_gain_base_amount":0,"life_gain_per_count":1,"mana_symbol_count_color":"G","trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"GainLifeEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class NyleasDisciple translated into ManaLoom runtime scope xmage_creature_etb_dynamic_gain_life_v1. This row is package-ready only because the source signature is a narrow creature ETB dynamic life-gain trigger with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('setessan petitioner', 'Setessan Petitioner', '68590e842acf21eba3bc15e0297a4e6f', 'battle_rule_v1:eaf661bb562df70f38ab3ec27704a383', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_dynamic_gain_life_v1","effect":"creature","etb_dynamic_life_gain":true,"life_gain_amount_source":"controlled_permanents_mana_symbol_count","life_gain_base_amount":0,"life_gain_per_count":1,"mana_symbol_count_color":"G","trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"GainLifeEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class SetessanPetitioner translated into ManaLoom runtime scope xmage_creature_etb_dynamic_gain_life_v1. This row is package-ready only because the source signature is a narrow creature ETB dynamic life-gain trigger with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('shepherd of heroes', 'Shepherd of Heroes', '7abffd6b31986c73f45618e86eeeeb02', 'battle_rule_v1:8b66a372b74bf03dd3a71b037bed433a', '{"_keywords_are_self":true,"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_dynamic_gain_life_v1","effect":"creature","etb_dynamic_life_gain":true,"flying":true,"keywords":["flying"],"life_gain_amount_source":"party_count","life_gain_base_amount":0,"life_gain_per_count":2,"trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"GainLifeEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ShepherdOfHeroes translated into ManaLoom runtime scope xmage_creature_etb_dynamic_gain_life_v1. This row is package-ready only because the source signature is a narrow creature ETB dynamic life-gain trigger with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
    ('ancestor''s chosen', 'Ancestor''s Chosen', 'b747a70ff698503803efb0a8f90684c7', 'battle_rule_v1:b32118535b258365f98ae0a7fac3d53f', '{"_keywords_are_self":true,"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_dynamic_gain_life_v1","effect":"creature","etb_dynamic_life_gain":true,"first_strike":true,"graveyard_count_card_types":["card"],"graveyard_count_scope":"controller_graveyard","keywords":["first_strike"],"life_gain_amount_source":"graveyard_card_count","life_gain_base_amount":0,"life_gain_per_count":1,"trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"GainLifeEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class AncestorsChosen translated into ManaLoom runtime scope xmage_creature_etb_dynamic_gain_life_v1. This row is package-ready only because the source signature is a narrow creature ETB dynamic life-gain trigger with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('angel of renewal', 'Angel of Renewal', '4a915f33c4d231cbfbc6dc2806a98b30', 'battle_rule_v1:431fb7d37e21b6b06fc6917347dea517', '{"_keywords_are_self":true,"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_dynamic_gain_life_v1","battlefield_count_card_types":["creature"],"battlefield_count_scope":"controller_battlefield","effect":"creature","etb_dynamic_life_gain":true,"flying":true,"keywords":["flying"],"life_gain_amount_source":"battlefield_permanent_count","life_gain_base_amount":0,"life_gain_per_count":1,"trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"GainLifeEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class AngelOfRenewal translated into ManaLoom runtime scope xmage_creature_etb_dynamic_gain_life_v1. This row is package-ready only because the source signature is a narrow creature ETB dynamic life-gain trigger with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('archway angel', 'Archway Angel', 'c5369f445beae5a071259be3c0fadc2b', 'battle_rule_v1:4ba0dcd58b32218ce9543906e1125e00', '{"_keywords_are_self":true,"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_dynamic_gain_life_v1","battlefield_count_card_types":["permanent"],"battlefield_count_scope":"controller_battlefield","battlefield_count_subtypes":["gate"],"effect":"creature","etb_dynamic_life_gain":true,"flying":true,"keywords":["flying"],"life_gain_amount_source":"battlefield_permanent_count","life_gain_base_amount":0,"life_gain_per_count":2,"trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"GainLifeEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ArchwayAngel translated into ManaLoom runtime scope xmage_creature_etb_dynamic_gain_life_v1. This row is package-ready only because the source signature is a narrow creature ETB dynamic life-gain trigger with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('aven gagglemaster', 'Aven Gagglemaster', 'e74d2cc5afe677794289fe82ff3e0b43', 'battle_rule_v1:c9a00ec32e4c03c98efb5bb532c8a37a', '{"_keywords_are_self":true,"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_dynamic_gain_life_v1","battlefield_count_card_types":["creature"],"battlefield_count_keywords":["flying"],"battlefield_count_scope":"controller_battlefield","effect":"creature","etb_dynamic_life_gain":true,"flying":true,"keywords":["flying"],"life_gain_amount_source":"battlefield_permanent_count","life_gain_base_amount":0,"life_gain_per_count":2,"trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"GainLifeEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class AvenGagglemaster translated into ManaLoom runtime scope xmage_creature_etb_dynamic_gain_life_v1. This row is package-ready only because the source signature is a narrow creature ETB dynamic life-gain trigger with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('dwarven priest', 'Dwarven Priest', '808da1862ca641ddfd5cf92cda70025f', 'battle_rule_v1:6b63db417a759f8bb7ed56e89b6b5115', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_dynamic_gain_life_v1","battlefield_count_card_types":["creature"],"battlefield_count_scope":"controller_battlefield","effect":"creature","etb_dynamic_life_gain":true,"life_gain_amount_source":"battlefield_permanent_count","life_gain_base_amount":0,"life_gain_per_count":1,"trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"GainLifeEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class DwarvenPriest translated into ManaLoom runtime scope xmage_creature_etb_dynamic_gain_life_v1. This row is package-ready only because the source signature is a narrow creature ETB dynamic life-gain trigger with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('flourishing hunter', 'Flourishing Hunter', '4176d051992a19b744dad7fbcb7208a6', 'battle_rule_v1:dc06aa6c8a2edc5468ccf15367a43e40', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_dynamic_gain_life_v1","effect":"creature","etb_dynamic_life_gain":true,"life_gain_amount_source":"greatest_toughness_among_other_controlled_creatures","life_gain_base_amount":0,"life_gain_per_count":1,"trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"GainLifeEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class FlourishingHunter translated into ManaLoom runtime scope xmage_creature_etb_dynamic_gain_life_v1. This row is package-ready only because the source signature is a narrow creature ETB dynamic life-gain trigger with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('goldnight redeemer', 'Goldnight Redeemer', '53cb387e4cfa6073108d2521f02afa06', 'battle_rule_v1:891b42c06ce7f173aee31bd60f87222e', '{"_keywords_are_self":true,"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_dynamic_gain_life_v1","battlefield_count_card_types":["creature"],"battlefield_count_exclude_source":true,"battlefield_count_scope":"controller_battlefield","effect":"creature","etb_dynamic_life_gain":true,"flying":true,"keywords":["flying"],"life_gain_amount_source":"battlefield_permanent_count","life_gain_base_amount":0,"life_gain_per_count":2,"trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"GainLifeEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class GoldnightRedeemer translated into ManaLoom runtime scope xmage_creature_etb_dynamic_gain_life_v1. This row is package-ready only because the source signature is a narrow creature ETB dynamic life-gain trigger with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('kraul foragers', 'Kraul Foragers', '1d6314de33c255299d46542a146400bd', 'battle_rule_v1:dd60c22d45ed324b92e12c77deb12018', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_dynamic_gain_life_v1","effect":"creature","etb_dynamic_life_gain":true,"graveyard_count_card_types":["creature"],"graveyard_count_scope":"controller_graveyard","life_gain_amount_source":"graveyard_card_count","life_gain_base_amount":0,"life_gain_per_count":1,"trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"GainLifeEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class KraulForagers translated into ManaLoom runtime scope xmage_creature_etb_dynamic_gain_life_v1. This row is package-ready only because the source signature is a narrow creature ETB dynamic life-gain trigger with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('luminollusk', 'Luminollusk', 'c3be1e29deac8bd4e2ab1a7a11aa6150', 'battle_rule_v1:d4009ce1c19af31609c05dc4110c30b0', '{"_keywords_are_self":true,"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_dynamic_gain_life_v1","deathtouch":true,"effect":"creature","etb_dynamic_life_gain":true,"keywords":["deathtouch"],"life_gain_amount_source":"colors_among_permanents_you_control","life_gain_base_amount":0,"life_gain_per_count":1,"trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"GainLifeEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Luminollusk translated into ManaLoom runtime scope xmage_creature_etb_dynamic_gain_life_v1. This row is package-ready only because the source signature is a narrow creature ETB dynamic life-gain trigger with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('nylea''s disciple', 'Nylea''s Disciple', '68590e842acf21eba3bc15e0297a4e6f', 'battle_rule_v1:eaf661bb562df70f38ab3ec27704a383', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_dynamic_gain_life_v1","effect":"creature","etb_dynamic_life_gain":true,"life_gain_amount_source":"controlled_permanents_mana_symbol_count","life_gain_base_amount":0,"life_gain_per_count":1,"mana_symbol_count_color":"G","trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"GainLifeEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class NyleasDisciple translated into ManaLoom runtime scope xmage_creature_etb_dynamic_gain_life_v1. This row is package-ready only because the source signature is a narrow creature ETB dynamic life-gain trigger with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('setessan petitioner', 'Setessan Petitioner', '68590e842acf21eba3bc15e0297a4e6f', 'battle_rule_v1:eaf661bb562df70f38ab3ec27704a383', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_dynamic_gain_life_v1","effect":"creature","etb_dynamic_life_gain":true,"life_gain_amount_source":"controlled_permanents_mana_symbol_count","life_gain_base_amount":0,"life_gain_per_count":1,"mana_symbol_count_color":"G","trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"GainLifeEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class SetessanPetitioner translated into ManaLoom runtime scope xmage_creature_etb_dynamic_gain_life_v1. This row is package-ready only because the source signature is a narrow creature ETB dynamic life-gain trigger with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('shepherd of heroes', 'Shepherd of Heroes', '7abffd6b31986c73f45618e86eeeeb02', 'battle_rule_v1:8b66a372b74bf03dd3a71b037bed433a', '{"_keywords_are_self":true,"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_dynamic_gain_life_v1","effect":"creature","etb_dynamic_life_gain":true,"flying":true,"keywords":["flying"],"life_gain_amount_source":"party_count","life_gain_base_amount":0,"life_gain_per_count":2,"trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"GainLifeEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ShepherdOfHeroes translated into ManaLoom runtime scope xmage_creature_etb_dynamic_gain_life_v1. This row is package-ready only because the source signature is a narrow creature ETB dynamic life-gain trigger with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
    ('ancestor''s chosen', 'Ancestor''s Chosen', 'b747a70ff698503803efb0a8f90684c7', 'battle_rule_v1:b32118535b258365f98ae0a7fac3d53f', '{"_keywords_are_self":true,"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_dynamic_gain_life_v1","effect":"creature","etb_dynamic_life_gain":true,"first_strike":true,"graveyard_count_card_types":["card"],"graveyard_count_scope":"controller_graveyard","keywords":["first_strike"],"life_gain_amount_source":"graveyard_card_count","life_gain_base_amount":0,"life_gain_per_count":1,"trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"GainLifeEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class AncestorsChosen translated into ManaLoom runtime scope xmage_creature_etb_dynamic_gain_life_v1. This row is package-ready only because the source signature is a narrow creature ETB dynamic life-gain trigger with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('angel of renewal', 'Angel of Renewal', '4a915f33c4d231cbfbc6dc2806a98b30', 'battle_rule_v1:431fb7d37e21b6b06fc6917347dea517', '{"_keywords_are_self":true,"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_dynamic_gain_life_v1","battlefield_count_card_types":["creature"],"battlefield_count_scope":"controller_battlefield","effect":"creature","etb_dynamic_life_gain":true,"flying":true,"keywords":["flying"],"life_gain_amount_source":"battlefield_permanent_count","life_gain_base_amount":0,"life_gain_per_count":1,"trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"GainLifeEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class AngelOfRenewal translated into ManaLoom runtime scope xmage_creature_etb_dynamic_gain_life_v1. This row is package-ready only because the source signature is a narrow creature ETB dynamic life-gain trigger with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('archway angel', 'Archway Angel', 'c5369f445beae5a071259be3c0fadc2b', 'battle_rule_v1:4ba0dcd58b32218ce9543906e1125e00', '{"_keywords_are_self":true,"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_dynamic_gain_life_v1","battlefield_count_card_types":["permanent"],"battlefield_count_scope":"controller_battlefield","battlefield_count_subtypes":["gate"],"effect":"creature","etb_dynamic_life_gain":true,"flying":true,"keywords":["flying"],"life_gain_amount_source":"battlefield_permanent_count","life_gain_base_amount":0,"life_gain_per_count":2,"trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"GainLifeEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ArchwayAngel translated into ManaLoom runtime scope xmage_creature_etb_dynamic_gain_life_v1. This row is package-ready only because the source signature is a narrow creature ETB dynamic life-gain trigger with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('aven gagglemaster', 'Aven Gagglemaster', 'e74d2cc5afe677794289fe82ff3e0b43', 'battle_rule_v1:c9a00ec32e4c03c98efb5bb532c8a37a', '{"_keywords_are_self":true,"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_dynamic_gain_life_v1","battlefield_count_card_types":["creature"],"battlefield_count_keywords":["flying"],"battlefield_count_scope":"controller_battlefield","effect":"creature","etb_dynamic_life_gain":true,"flying":true,"keywords":["flying"],"life_gain_amount_source":"battlefield_permanent_count","life_gain_base_amount":0,"life_gain_per_count":2,"trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"GainLifeEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class AvenGagglemaster translated into ManaLoom runtime scope xmage_creature_etb_dynamic_gain_life_v1. This row is package-ready only because the source signature is a narrow creature ETB dynamic life-gain trigger with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('dwarven priest', 'Dwarven Priest', '808da1862ca641ddfd5cf92cda70025f', 'battle_rule_v1:6b63db417a759f8bb7ed56e89b6b5115', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_dynamic_gain_life_v1","battlefield_count_card_types":["creature"],"battlefield_count_scope":"controller_battlefield","effect":"creature","etb_dynamic_life_gain":true,"life_gain_amount_source":"battlefield_permanent_count","life_gain_base_amount":0,"life_gain_per_count":1,"trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"GainLifeEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class DwarvenPriest translated into ManaLoom runtime scope xmage_creature_etb_dynamic_gain_life_v1. This row is package-ready only because the source signature is a narrow creature ETB dynamic life-gain trigger with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('flourishing hunter', 'Flourishing Hunter', '4176d051992a19b744dad7fbcb7208a6', 'battle_rule_v1:dc06aa6c8a2edc5468ccf15367a43e40', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_dynamic_gain_life_v1","effect":"creature","etb_dynamic_life_gain":true,"life_gain_amount_source":"greatest_toughness_among_other_controlled_creatures","life_gain_base_amount":0,"life_gain_per_count":1,"trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"GainLifeEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class FlourishingHunter translated into ManaLoom runtime scope xmage_creature_etb_dynamic_gain_life_v1. This row is package-ready only because the source signature is a narrow creature ETB dynamic life-gain trigger with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('goldnight redeemer', 'Goldnight Redeemer', '53cb387e4cfa6073108d2521f02afa06', 'battle_rule_v1:891b42c06ce7f173aee31bd60f87222e', '{"_keywords_are_self":true,"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_dynamic_gain_life_v1","battlefield_count_card_types":["creature"],"battlefield_count_exclude_source":true,"battlefield_count_scope":"controller_battlefield","effect":"creature","etb_dynamic_life_gain":true,"flying":true,"keywords":["flying"],"life_gain_amount_source":"battlefield_permanent_count","life_gain_base_amount":0,"life_gain_per_count":2,"trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"GainLifeEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class GoldnightRedeemer translated into ManaLoom runtime scope xmage_creature_etb_dynamic_gain_life_v1. This row is package-ready only because the source signature is a narrow creature ETB dynamic life-gain trigger with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('kraul foragers', 'Kraul Foragers', '1d6314de33c255299d46542a146400bd', 'battle_rule_v1:dd60c22d45ed324b92e12c77deb12018', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_dynamic_gain_life_v1","effect":"creature","etb_dynamic_life_gain":true,"graveyard_count_card_types":["creature"],"graveyard_count_scope":"controller_graveyard","life_gain_amount_source":"graveyard_card_count","life_gain_base_amount":0,"life_gain_per_count":1,"trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"GainLifeEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class KraulForagers translated into ManaLoom runtime scope xmage_creature_etb_dynamic_gain_life_v1. This row is package-ready only because the source signature is a narrow creature ETB dynamic life-gain trigger with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('luminollusk', 'Luminollusk', 'c3be1e29deac8bd4e2ab1a7a11aa6150', 'battle_rule_v1:d4009ce1c19af31609c05dc4110c30b0', '{"_keywords_are_self":true,"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_dynamic_gain_life_v1","deathtouch":true,"effect":"creature","etb_dynamic_life_gain":true,"keywords":["deathtouch"],"life_gain_amount_source":"colors_among_permanents_you_control","life_gain_base_amount":0,"life_gain_per_count":1,"trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"GainLifeEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Luminollusk translated into ManaLoom runtime scope xmage_creature_etb_dynamic_gain_life_v1. This row is package-ready only because the source signature is a narrow creature ETB dynamic life-gain trigger with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('nylea''s disciple', 'Nylea''s Disciple', '68590e842acf21eba3bc15e0297a4e6f', 'battle_rule_v1:eaf661bb562df70f38ab3ec27704a383', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_dynamic_gain_life_v1","effect":"creature","etb_dynamic_life_gain":true,"life_gain_amount_source":"controlled_permanents_mana_symbol_count","life_gain_base_amount":0,"life_gain_per_count":1,"mana_symbol_count_color":"G","trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"GainLifeEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class NyleasDisciple translated into ManaLoom runtime scope xmage_creature_etb_dynamic_gain_life_v1. This row is package-ready only because the source signature is a narrow creature ETB dynamic life-gain trigger with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('setessan petitioner', 'Setessan Petitioner', '68590e842acf21eba3bc15e0297a4e6f', 'battle_rule_v1:eaf661bb562df70f38ab3ec27704a383', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_dynamic_gain_life_v1","effect":"creature","etb_dynamic_life_gain":true,"life_gain_amount_source":"controlled_permanents_mana_symbol_count","life_gain_base_amount":0,"life_gain_per_count":1,"mana_symbol_count_color":"G","trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"GainLifeEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class SetessanPetitioner translated into ManaLoom runtime scope xmage_creature_etb_dynamic_gain_life_v1. This row is package-ready only because the source signature is a narrow creature ETB dynamic life-gain trigger with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('shepherd of heroes', 'Shepherd of Heroes', '7abffd6b31986c73f45618e86eeeeb02', 'battle_rule_v1:8b66a372b74bf03dd3a71b037bed433a', '{"_keywords_are_self":true,"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_dynamic_gain_life_v1","effect":"creature","etb_dynamic_life_gain":true,"flying":true,"keywords":["flying"],"life_gain_amount_source":"party_count","life_gain_base_amount":0,"life_gain_per_count":2,"trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"GainLifeEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ShepherdOfHeroes translated into ManaLoom runtime scope xmage_creature_etb_dynamic_gain_life_v1. This row is package-ready only because the source signature is a narrow creature ETB dynamic life-gain trigger with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
