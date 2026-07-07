BEGIN;

CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit;

CREATE TABLE IF NOT EXISTS manaloom_deploy_audit.pg609_etb_draw_discard_new_server_20260707_102827 AS
SELECT *
FROM public.card_battle_rules
WHERE normalized_name IN ('bazaar trademage', 'bellowing crier', 'elite instructor', 'icewind elemental', 'merfolk traders', 'owl familiar', 'quicksilver fisher', 'screeching drake', 'sky-eel school', 'temur tawnyback', 'vodalian merchant')
   OR normalized_name LIKE 'bazaar trademage // %'
   OR normalized_name LIKE 'bellowing crier // %'
   OR normalized_name LIKE 'elite instructor // %'
   OR normalized_name LIKE 'icewind elemental // %'
   OR normalized_name LIKE 'merfolk traders // %'
   OR normalized_name LIKE 'owl familiar // %'
   OR normalized_name LIKE 'quicksilver fisher // %'
   OR normalized_name LIKE 'screeching drake // %'
   OR normalized_name LIKE 'sky-eel school // %'
   OR normalized_name LIKE 'temur tawnyback // %'
   OR normalized_name LIKE 'vodalian merchant // %';

DO $$
DECLARE
  v_missing jsonb;
BEGIN
  WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('bazaar trademage', 'Bazaar Trademage', '0a1ea50959fedbabf7f09c82e3ab9123', 'battle_rule_v1:6f175c276cdab1952e05a4e76489ee01', '{"_keywords_are_self":true,"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_draw_discard_cards_v1","discard_count":3,"draw_count":2,"draw_discard_order":"draw_then_discard","effect":"creature","etb_discard_count":3,"etb_draw_count":2,"etb_draw_discard":true,"flying":true,"keywords":["flying"],"trigger":"enters_battlefield","trigger_effect":"draw_discard","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"DrawDiscardControllerEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class BazaarTrademage translated into ManaLoom runtime scope xmage_creature_etb_draw_discard_cards_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('bellowing crier', 'Bellowing Crier', 'd98cfb952a222f31dbae77593bad4349', 'battle_rule_v1:9b76976677d2fe7bf777fd5cba120e55', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_draw_discard_cards_v1","discard_count":1,"draw_count":1,"draw_discard_order":"draw_then_discard","effect":"creature","etb_discard_count":1,"etb_draw_count":1,"etb_draw_discard":true,"trigger":"enters_battlefield","trigger_effect":"draw_discard","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"DrawDiscardControllerEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class BellowingCrier translated into ManaLoom runtime scope xmage_creature_etb_draw_discard_cards_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('elite instructor', 'Elite Instructor', 'd98cfb952a222f31dbae77593bad4349', 'battle_rule_v1:9b76976677d2fe7bf777fd5cba120e55', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_draw_discard_cards_v1","discard_count":1,"draw_count":1,"draw_discard_order":"draw_then_discard","effect":"creature","etb_discard_count":1,"etb_draw_count":1,"etb_draw_discard":true,"trigger":"enters_battlefield","trigger_effect":"draw_discard","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"DrawDiscardControllerEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class EliteInstructor translated into ManaLoom runtime scope xmage_creature_etb_draw_discard_cards_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('icewind elemental', 'Icewind Elemental', 'd8046b3557308357bd8cd0ab2fcb91f7', 'battle_rule_v1:d868cbde8fd80fcce770a888bf4c2729', '{"_keywords_are_self":true,"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_draw_discard_cards_v1","discard_count":1,"draw_count":1,"draw_discard_order":"draw_then_discard","effect":"creature","etb_discard_count":1,"etb_draw_count":1,"etb_draw_discard":true,"flying":true,"keywords":["flying"],"trigger":"enters_battlefield","trigger_effect":"draw_discard","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"DrawDiscardControllerEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class IcewindElemental translated into ManaLoom runtime scope xmage_creature_etb_draw_discard_cards_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('merfolk traders', 'Merfolk Traders', 'd98cfb952a222f31dbae77593bad4349', 'battle_rule_v1:9b76976677d2fe7bf777fd5cba120e55', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_draw_discard_cards_v1","discard_count":1,"draw_count":1,"draw_discard_order":"draw_then_discard","effect":"creature","etb_discard_count":1,"etb_draw_count":1,"etb_draw_discard":true,"trigger":"enters_battlefield","trigger_effect":"draw_discard","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"DrawDiscardControllerEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class MerfolkTraders translated into ManaLoom runtime scope xmage_creature_etb_draw_discard_cards_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('owl familiar', 'Owl Familiar', 'd8046b3557308357bd8cd0ab2fcb91f7', 'battle_rule_v1:d868cbde8fd80fcce770a888bf4c2729', '{"_keywords_are_self":true,"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_draw_discard_cards_v1","discard_count":1,"draw_count":1,"draw_discard_order":"draw_then_discard","effect":"creature","etb_discard_count":1,"etb_draw_count":1,"etb_draw_discard":true,"flying":true,"keywords":["flying"],"trigger":"enters_battlefield","trigger_effect":"draw_discard","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"DrawDiscardControllerEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class OwlFamiliar translated into ManaLoom runtime scope xmage_creature_etb_draw_discard_cards_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('quicksilver fisher', 'Quicksilver Fisher', 'd8046b3557308357bd8cd0ab2fcb91f7', 'battle_rule_v1:d868cbde8fd80fcce770a888bf4c2729', '{"_keywords_are_self":true,"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_draw_discard_cards_v1","discard_count":1,"draw_count":1,"draw_discard_order":"draw_then_discard","effect":"creature","etb_discard_count":1,"etb_draw_count":1,"etb_draw_discard":true,"flying":true,"keywords":["flying"],"trigger":"enters_battlefield","trigger_effect":"draw_discard","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"DrawDiscardControllerEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class QuicksilverFisher translated into ManaLoom runtime scope xmage_creature_etb_draw_discard_cards_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('screeching drake', 'Screeching Drake', 'd8046b3557308357bd8cd0ab2fcb91f7', 'battle_rule_v1:d868cbde8fd80fcce770a888bf4c2729', '{"_keywords_are_self":true,"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_draw_discard_cards_v1","discard_count":1,"draw_count":1,"draw_discard_order":"draw_then_discard","effect":"creature","etb_discard_count":1,"etb_draw_count":1,"etb_draw_discard":true,"flying":true,"keywords":["flying"],"trigger":"enters_battlefield","trigger_effect":"draw_discard","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"DrawDiscardControllerEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ScreechingDrake translated into ManaLoom runtime scope xmage_creature_etb_draw_discard_cards_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('sky-eel school', 'Sky-Eel School', 'd8046b3557308357bd8cd0ab2fcb91f7', 'battle_rule_v1:d868cbde8fd80fcce770a888bf4c2729', '{"_keywords_are_self":true,"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_draw_discard_cards_v1","discard_count":1,"draw_count":1,"draw_discard_order":"draw_then_discard","effect":"creature","etb_discard_count":1,"etb_draw_count":1,"etb_draw_discard":true,"flying":true,"keywords":["flying"],"trigger":"enters_battlefield","trigger_effect":"draw_discard","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"DrawDiscardControllerEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class SkyEelSchool translated into ManaLoom runtime scope xmage_creature_etb_draw_discard_cards_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('temur tawnyback', 'Temur Tawnyback', 'd98cfb952a222f31dbae77593bad4349', 'battle_rule_v1:9b76976677d2fe7bf777fd5cba120e55', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_draw_discard_cards_v1","discard_count":1,"draw_count":1,"draw_discard_order":"draw_then_discard","effect":"creature","etb_discard_count":1,"etb_draw_count":1,"etb_draw_discard":true,"trigger":"enters_battlefield","trigger_effect":"draw_discard","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"DrawDiscardControllerEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class TemurTawnyback translated into ManaLoom runtime scope xmage_creature_etb_draw_discard_cards_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('vodalian merchant', 'Vodalian Merchant', 'd98cfb952a222f31dbae77593bad4349', 'battle_rule_v1:9b76976677d2fe7bf777fd5cba120e55', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_draw_discard_cards_v1","discard_count":1,"draw_count":1,"draw_discard_order":"draw_then_discard","effect":"creature","etb_discard_count":1,"etb_draw_count":1,"etb_draw_discard":true,"trigger":"enters_battlefield","trigger_effect":"draw_discard","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"DrawDiscardControllerEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class VodalianMerchant translated into ManaLoom runtime scope xmage_creature_etb_draw_discard_cards_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
    ('bazaar trademage', 'Bazaar Trademage', '0a1ea50959fedbabf7f09c82e3ab9123', 'battle_rule_v1:6f175c276cdab1952e05a4e76489ee01', '{"_keywords_are_self":true,"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_draw_discard_cards_v1","discard_count":3,"draw_count":2,"draw_discard_order":"draw_then_discard","effect":"creature","etb_discard_count":3,"etb_draw_count":2,"etb_draw_discard":true,"flying":true,"keywords":["flying"],"trigger":"enters_battlefield","trigger_effect":"draw_discard","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"DrawDiscardControllerEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class BazaarTrademage translated into ManaLoom runtime scope xmage_creature_etb_draw_discard_cards_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('bellowing crier', 'Bellowing Crier', 'd98cfb952a222f31dbae77593bad4349', 'battle_rule_v1:9b76976677d2fe7bf777fd5cba120e55', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_draw_discard_cards_v1","discard_count":1,"draw_count":1,"draw_discard_order":"draw_then_discard","effect":"creature","etb_discard_count":1,"etb_draw_count":1,"etb_draw_discard":true,"trigger":"enters_battlefield","trigger_effect":"draw_discard","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"DrawDiscardControllerEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class BellowingCrier translated into ManaLoom runtime scope xmage_creature_etb_draw_discard_cards_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('elite instructor', 'Elite Instructor', 'd98cfb952a222f31dbae77593bad4349', 'battle_rule_v1:9b76976677d2fe7bf777fd5cba120e55', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_draw_discard_cards_v1","discard_count":1,"draw_count":1,"draw_discard_order":"draw_then_discard","effect":"creature","etb_discard_count":1,"etb_draw_count":1,"etb_draw_discard":true,"trigger":"enters_battlefield","trigger_effect":"draw_discard","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"DrawDiscardControllerEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class EliteInstructor translated into ManaLoom runtime scope xmage_creature_etb_draw_discard_cards_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('icewind elemental', 'Icewind Elemental', 'd8046b3557308357bd8cd0ab2fcb91f7', 'battle_rule_v1:d868cbde8fd80fcce770a888bf4c2729', '{"_keywords_are_self":true,"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_draw_discard_cards_v1","discard_count":1,"draw_count":1,"draw_discard_order":"draw_then_discard","effect":"creature","etb_discard_count":1,"etb_draw_count":1,"etb_draw_discard":true,"flying":true,"keywords":["flying"],"trigger":"enters_battlefield","trigger_effect":"draw_discard","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"DrawDiscardControllerEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class IcewindElemental translated into ManaLoom runtime scope xmage_creature_etb_draw_discard_cards_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('merfolk traders', 'Merfolk Traders', 'd98cfb952a222f31dbae77593bad4349', 'battle_rule_v1:9b76976677d2fe7bf777fd5cba120e55', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_draw_discard_cards_v1","discard_count":1,"draw_count":1,"draw_discard_order":"draw_then_discard","effect":"creature","etb_discard_count":1,"etb_draw_count":1,"etb_draw_discard":true,"trigger":"enters_battlefield","trigger_effect":"draw_discard","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"DrawDiscardControllerEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class MerfolkTraders translated into ManaLoom runtime scope xmage_creature_etb_draw_discard_cards_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('owl familiar', 'Owl Familiar', 'd8046b3557308357bd8cd0ab2fcb91f7', 'battle_rule_v1:d868cbde8fd80fcce770a888bf4c2729', '{"_keywords_are_self":true,"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_draw_discard_cards_v1","discard_count":1,"draw_count":1,"draw_discard_order":"draw_then_discard","effect":"creature","etb_discard_count":1,"etb_draw_count":1,"etb_draw_discard":true,"flying":true,"keywords":["flying"],"trigger":"enters_battlefield","trigger_effect":"draw_discard","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"DrawDiscardControllerEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class OwlFamiliar translated into ManaLoom runtime scope xmage_creature_etb_draw_discard_cards_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('quicksilver fisher', 'Quicksilver Fisher', 'd8046b3557308357bd8cd0ab2fcb91f7', 'battle_rule_v1:d868cbde8fd80fcce770a888bf4c2729', '{"_keywords_are_self":true,"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_draw_discard_cards_v1","discard_count":1,"draw_count":1,"draw_discard_order":"draw_then_discard","effect":"creature","etb_discard_count":1,"etb_draw_count":1,"etb_draw_discard":true,"flying":true,"keywords":["flying"],"trigger":"enters_battlefield","trigger_effect":"draw_discard","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"DrawDiscardControllerEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class QuicksilverFisher translated into ManaLoom runtime scope xmage_creature_etb_draw_discard_cards_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('screeching drake', 'Screeching Drake', 'd8046b3557308357bd8cd0ab2fcb91f7', 'battle_rule_v1:d868cbde8fd80fcce770a888bf4c2729', '{"_keywords_are_self":true,"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_draw_discard_cards_v1","discard_count":1,"draw_count":1,"draw_discard_order":"draw_then_discard","effect":"creature","etb_discard_count":1,"etb_draw_count":1,"etb_draw_discard":true,"flying":true,"keywords":["flying"],"trigger":"enters_battlefield","trigger_effect":"draw_discard","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"DrawDiscardControllerEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ScreechingDrake translated into ManaLoom runtime scope xmage_creature_etb_draw_discard_cards_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('sky-eel school', 'Sky-Eel School', 'd8046b3557308357bd8cd0ab2fcb91f7', 'battle_rule_v1:d868cbde8fd80fcce770a888bf4c2729', '{"_keywords_are_self":true,"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_draw_discard_cards_v1","discard_count":1,"draw_count":1,"draw_discard_order":"draw_then_discard","effect":"creature","etb_discard_count":1,"etb_draw_count":1,"etb_draw_discard":true,"flying":true,"keywords":["flying"],"trigger":"enters_battlefield","trigger_effect":"draw_discard","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"DrawDiscardControllerEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class SkyEelSchool translated into ManaLoom runtime scope xmage_creature_etb_draw_discard_cards_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('temur tawnyback', 'Temur Tawnyback', 'd98cfb952a222f31dbae77593bad4349', 'battle_rule_v1:9b76976677d2fe7bf777fd5cba120e55', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_draw_discard_cards_v1","discard_count":1,"draw_count":1,"draw_discard_order":"draw_then_discard","effect":"creature","etb_discard_count":1,"etb_draw_count":1,"etb_draw_discard":true,"trigger":"enters_battlefield","trigger_effect":"draw_discard","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"DrawDiscardControllerEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class TemurTawnyback translated into ManaLoom runtime scope xmage_creature_etb_draw_discard_cards_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('vodalian merchant', 'Vodalian Merchant', 'd98cfb952a222f31dbae77593bad4349', 'battle_rule_v1:9b76976677d2fe7bf777fd5cba120e55', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_draw_discard_cards_v1","discard_count":1,"draw_count":1,"draw_discard_order":"draw_then_discard","effect":"creature","etb_discard_count":1,"etb_draw_count":1,"etb_draw_discard":true,"trigger":"enters_battlefield","trigger_effect":"draw_discard","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"DrawDiscardControllerEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class VodalianMerchant translated into ManaLoom runtime scope xmage_creature_etb_draw_discard_cards_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
    ('bazaar trademage', 'Bazaar Trademage', '0a1ea50959fedbabf7f09c82e3ab9123', 'battle_rule_v1:6f175c276cdab1952e05a4e76489ee01', '{"_keywords_are_self":true,"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_draw_discard_cards_v1","discard_count":3,"draw_count":2,"draw_discard_order":"draw_then_discard","effect":"creature","etb_discard_count":3,"etb_draw_count":2,"etb_draw_discard":true,"flying":true,"keywords":["flying"],"trigger":"enters_battlefield","trigger_effect":"draw_discard","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"DrawDiscardControllerEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class BazaarTrademage translated into ManaLoom runtime scope xmage_creature_etb_draw_discard_cards_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('bellowing crier', 'Bellowing Crier', 'd98cfb952a222f31dbae77593bad4349', 'battle_rule_v1:9b76976677d2fe7bf777fd5cba120e55', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_draw_discard_cards_v1","discard_count":1,"draw_count":1,"draw_discard_order":"draw_then_discard","effect":"creature","etb_discard_count":1,"etb_draw_count":1,"etb_draw_discard":true,"trigger":"enters_battlefield","trigger_effect":"draw_discard","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"DrawDiscardControllerEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class BellowingCrier translated into ManaLoom runtime scope xmage_creature_etb_draw_discard_cards_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('elite instructor', 'Elite Instructor', 'd98cfb952a222f31dbae77593bad4349', 'battle_rule_v1:9b76976677d2fe7bf777fd5cba120e55', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_draw_discard_cards_v1","discard_count":1,"draw_count":1,"draw_discard_order":"draw_then_discard","effect":"creature","etb_discard_count":1,"etb_draw_count":1,"etb_draw_discard":true,"trigger":"enters_battlefield","trigger_effect":"draw_discard","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"DrawDiscardControllerEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class EliteInstructor translated into ManaLoom runtime scope xmage_creature_etb_draw_discard_cards_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('icewind elemental', 'Icewind Elemental', 'd8046b3557308357bd8cd0ab2fcb91f7', 'battle_rule_v1:d868cbde8fd80fcce770a888bf4c2729', '{"_keywords_are_self":true,"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_draw_discard_cards_v1","discard_count":1,"draw_count":1,"draw_discard_order":"draw_then_discard","effect":"creature","etb_discard_count":1,"etb_draw_count":1,"etb_draw_discard":true,"flying":true,"keywords":["flying"],"trigger":"enters_battlefield","trigger_effect":"draw_discard","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"DrawDiscardControllerEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class IcewindElemental translated into ManaLoom runtime scope xmage_creature_etb_draw_discard_cards_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('merfolk traders', 'Merfolk Traders', 'd98cfb952a222f31dbae77593bad4349', 'battle_rule_v1:9b76976677d2fe7bf777fd5cba120e55', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_draw_discard_cards_v1","discard_count":1,"draw_count":1,"draw_discard_order":"draw_then_discard","effect":"creature","etb_discard_count":1,"etb_draw_count":1,"etb_draw_discard":true,"trigger":"enters_battlefield","trigger_effect":"draw_discard","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"DrawDiscardControllerEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class MerfolkTraders translated into ManaLoom runtime scope xmage_creature_etb_draw_discard_cards_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('owl familiar', 'Owl Familiar', 'd8046b3557308357bd8cd0ab2fcb91f7', 'battle_rule_v1:d868cbde8fd80fcce770a888bf4c2729', '{"_keywords_are_self":true,"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_draw_discard_cards_v1","discard_count":1,"draw_count":1,"draw_discard_order":"draw_then_discard","effect":"creature","etb_discard_count":1,"etb_draw_count":1,"etb_draw_discard":true,"flying":true,"keywords":["flying"],"trigger":"enters_battlefield","trigger_effect":"draw_discard","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"DrawDiscardControllerEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class OwlFamiliar translated into ManaLoom runtime scope xmage_creature_etb_draw_discard_cards_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('quicksilver fisher', 'Quicksilver Fisher', 'd8046b3557308357bd8cd0ab2fcb91f7', 'battle_rule_v1:d868cbde8fd80fcce770a888bf4c2729', '{"_keywords_are_self":true,"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_draw_discard_cards_v1","discard_count":1,"draw_count":1,"draw_discard_order":"draw_then_discard","effect":"creature","etb_discard_count":1,"etb_draw_count":1,"etb_draw_discard":true,"flying":true,"keywords":["flying"],"trigger":"enters_battlefield","trigger_effect":"draw_discard","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"DrawDiscardControllerEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class QuicksilverFisher translated into ManaLoom runtime scope xmage_creature_etb_draw_discard_cards_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('screeching drake', 'Screeching Drake', 'd8046b3557308357bd8cd0ab2fcb91f7', 'battle_rule_v1:d868cbde8fd80fcce770a888bf4c2729', '{"_keywords_are_self":true,"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_draw_discard_cards_v1","discard_count":1,"draw_count":1,"draw_discard_order":"draw_then_discard","effect":"creature","etb_discard_count":1,"etb_draw_count":1,"etb_draw_discard":true,"flying":true,"keywords":["flying"],"trigger":"enters_battlefield","trigger_effect":"draw_discard","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"DrawDiscardControllerEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ScreechingDrake translated into ManaLoom runtime scope xmage_creature_etb_draw_discard_cards_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('sky-eel school', 'Sky-Eel School', 'd8046b3557308357bd8cd0ab2fcb91f7', 'battle_rule_v1:d868cbde8fd80fcce770a888bf4c2729', '{"_keywords_are_self":true,"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_draw_discard_cards_v1","discard_count":1,"draw_count":1,"draw_discard_order":"draw_then_discard","effect":"creature","etb_discard_count":1,"etb_draw_count":1,"etb_draw_discard":true,"flying":true,"keywords":["flying"],"trigger":"enters_battlefield","trigger_effect":"draw_discard","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"DrawDiscardControllerEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class SkyEelSchool translated into ManaLoom runtime scope xmage_creature_etb_draw_discard_cards_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('temur tawnyback', 'Temur Tawnyback', 'd98cfb952a222f31dbae77593bad4349', 'battle_rule_v1:9b76976677d2fe7bf777fd5cba120e55', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_draw_discard_cards_v1","discard_count":1,"draw_count":1,"draw_discard_order":"draw_then_discard","effect":"creature","etb_discard_count":1,"etb_draw_count":1,"etb_draw_discard":true,"trigger":"enters_battlefield","trigger_effect":"draw_discard","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"DrawDiscardControllerEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class TemurTawnyback translated into ManaLoom runtime scope xmage_creature_etb_draw_discard_cards_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('vodalian merchant', 'Vodalian Merchant', 'd98cfb952a222f31dbae77593bad4349', 'battle_rule_v1:9b76976677d2fe7bf777fd5cba120e55', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_draw_discard_cards_v1","discard_count":1,"draw_count":1,"draw_discard_order":"draw_then_discard","effect":"creature","etb_discard_count":1,"etb_draw_count":1,"etb_draw_discard":true,"trigger":"enters_battlefield","trigger_effect":"draw_discard","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"DrawDiscardControllerEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class VodalianMerchant translated into ManaLoom runtime scope xmage_creature_etb_draw_discard_cards_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
