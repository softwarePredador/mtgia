BEGIN;

CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit;

CREATE TABLE IF NOT EXISTS manaloom_deploy_audit.pg551_etb_scry_static_keyword_new_server_20260706_050009 AS
SELECT *
FROM public.card_battle_rules
WHERE normalized_name IN ('augury owl', 'cloudreader sphinx', 'faerie seer', 'glider kids', 'grey havens navigator', 'horizon scholar', 'senate griffin', 'silver raven', 'thaumaturge''s familiar', 'wall of runes', 'willow-wind')
   OR normalized_name LIKE 'augury owl // %'
   OR normalized_name LIKE 'cloudreader sphinx // %'
   OR normalized_name LIKE 'faerie seer // %'
   OR normalized_name LIKE 'glider kids // %'
   OR normalized_name LIKE 'grey havens navigator // %'
   OR normalized_name LIKE 'horizon scholar // %'
   OR normalized_name LIKE 'senate griffin // %'
   OR normalized_name LIKE 'silver raven // %'
   OR normalized_name LIKE 'thaumaturge''s familiar // %'
   OR normalized_name LIKE 'wall of runes // %'
   OR normalized_name LIKE 'willow-wind // %';

DO $$
DECLARE
  v_missing jsonb;
BEGIN
  WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('augury owl', 'Augury Owl', 'b7c450e1cc1c7574009f6120b406d00f', 'battle_rule_v1:575ffe521a678ebd6048179921e143c4', '{"_keywords_are_self":true,"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_scry_v1","effect":"creature","etb_scry_count":3,"etb_trigger_effect":"scry","flying":true,"keywords":["flying"],"scry_count":3,"trigger":"enters_battlefield","trigger_effect":"scry","trigger_scry_count":3,"xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"ScryEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class AuguryOwl translated into ManaLoom runtime scope xmage_creature_etb_scry_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('cloudreader sphinx', 'Cloudreader Sphinx', '68d074a48c8f785d82b12014eb8b3f41', 'battle_rule_v1:8c424968cc1906699fad2ba5866d5ef7', '{"_keywords_are_self":true,"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_scry_v1","effect":"creature","etb_scry_count":2,"etb_trigger_effect":"scry","flying":true,"keywords":["flying"],"scry_count":2,"trigger":"enters_battlefield","trigger_effect":"scry","trigger_scry_count":2,"xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"ScryEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class CloudreaderSphinx translated into ManaLoom runtime scope xmage_creature_etb_scry_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('faerie seer', 'Faerie Seer', '68d074a48c8f785d82b12014eb8b3f41', 'battle_rule_v1:8c424968cc1906699fad2ba5866d5ef7', '{"_keywords_are_self":true,"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_scry_v1","effect":"creature","etb_scry_count":2,"etb_trigger_effect":"scry","flying":true,"keywords":["flying"],"scry_count":2,"trigger":"enters_battlefield","trigger_effect":"scry","trigger_scry_count":2,"xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"ScryEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class FaerieSeer translated into ManaLoom runtime scope xmage_creature_etb_scry_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('glider kids', 'Glider Kids', 'ad26d1495915babc0e86243a49761178', 'battle_rule_v1:83bb17942e6f86ca784d1785783c02f8', '{"_keywords_are_self":true,"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_scry_v1","effect":"creature","etb_scry_count":1,"etb_trigger_effect":"scry","flying":true,"keywords":["flying"],"scry_count":1,"trigger":"enters_battlefield","trigger_effect":"scry","trigger_scry_count":1,"xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"ScryEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class GliderKids translated into ManaLoom runtime scope xmage_creature_etb_scry_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('grey havens navigator', 'Grey Havens Navigator', '3446d3cb3c4454d8bcaef4afb24a03aa', 'battle_rule_v1:13d75d87933e5b87f6584ce7d870f88b', '{"_keywords_are_self":true,"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_scry_v1","effect":"creature","etb_scry_count":1,"etb_trigger_effect":"scry","flash":true,"keywords":["flash"],"scry_count":1,"trigger":"enters_battlefield","trigger_effect":"scry","trigger_scry_count":1,"xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"ScryEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class GreyHavensNavigator translated into ManaLoom runtime scope xmage_creature_etb_scry_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('horizon scholar', 'Horizon Scholar', '68d074a48c8f785d82b12014eb8b3f41', 'battle_rule_v1:8c424968cc1906699fad2ba5866d5ef7', '{"_keywords_are_self":true,"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_scry_v1","effect":"creature","etb_scry_count":2,"etb_trigger_effect":"scry","flying":true,"keywords":["flying"],"scry_count":2,"trigger":"enters_battlefield","trigger_effect":"scry","trigger_scry_count":2,"xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"ScryEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class HorizonScholar translated into ManaLoom runtime scope xmage_creature_etb_scry_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('senate griffin', 'Senate Griffin', '6d564a66429df23676e0a2d72d667473', 'battle_rule_v1:83bb17942e6f86ca784d1785783c02f8', '{"_keywords_are_self":true,"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_scry_v1","effect":"creature","etb_scry_count":1,"etb_trigger_effect":"scry","flying":true,"keywords":["flying"],"scry_count":1,"trigger":"enters_battlefield","trigger_effect":"scry","trigger_scry_count":1,"xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"ScryEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class SenateGriffin translated into ManaLoom runtime scope xmage_creature_etb_scry_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('silver raven', 'Silver Raven', 'd70888b658f8ccdbcf9730d995915e7b', 'battle_rule_v1:83bb17942e6f86ca784d1785783c02f8', '{"_keywords_are_self":true,"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_scry_v1","effect":"creature","etb_scry_count":1,"etb_trigger_effect":"scry","flying":true,"keywords":["flying"],"scry_count":1,"trigger":"enters_battlefield","trigger_effect":"scry","trigger_scry_count":1,"xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"ScryEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class SilverRaven translated into ManaLoom runtime scope xmage_creature_etb_scry_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('thaumaturge''s familiar', 'Thaumaturge''s Familiar', '6d564a66429df23676e0a2d72d667473', 'battle_rule_v1:83bb17942e6f86ca784d1785783c02f8', '{"_keywords_are_self":true,"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_scry_v1","effect":"creature","etb_scry_count":1,"etb_trigger_effect":"scry","flying":true,"keywords":["flying"],"scry_count":1,"trigger":"enters_battlefield","trigger_effect":"scry","trigger_scry_count":1,"xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"ScryEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ThaumaturgesFamiliar translated into ManaLoom runtime scope xmage_creature_etb_scry_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('wall of runes', 'Wall of Runes', 'd3d9386b475168e08a8a86ad8f75d8a2', 'battle_rule_v1:f02e41ac1bd0430218b795975f29fb9d', '{"_keywords_are_self":true,"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_scry_v1","defender":true,"effect":"creature","etb_scry_count":1,"etb_trigger_effect":"scry","keywords":["defender"],"scry_count":1,"trigger":"enters_battlefield","trigger_effect":"scry","trigger_scry_count":1,"xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"ScryEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class WallOfRunes translated into ManaLoom runtime scope xmage_creature_etb_scry_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('willow-wind', 'Willow-Wind', 'e50f14b80485abf7b731a36129db45f4', 'battle_rule_v1:8c424968cc1906699fad2ba5866d5ef7', '{"_keywords_are_self":true,"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_scry_v1","effect":"creature","etb_scry_count":2,"etb_trigger_effect":"scry","flying":true,"keywords":["flying"],"scry_count":2,"trigger":"enters_battlefield","trigger_effect":"scry","trigger_scry_count":2,"xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"ScryEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class WillowWind translated into ManaLoom runtime scope xmage_creature_etb_scry_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
    ('augury owl', 'Augury Owl', 'b7c450e1cc1c7574009f6120b406d00f', 'battle_rule_v1:575ffe521a678ebd6048179921e143c4', '{"_keywords_are_self":true,"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_scry_v1","effect":"creature","etb_scry_count":3,"etb_trigger_effect":"scry","flying":true,"keywords":["flying"],"scry_count":3,"trigger":"enters_battlefield","trigger_effect":"scry","trigger_scry_count":3,"xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"ScryEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class AuguryOwl translated into ManaLoom runtime scope xmage_creature_etb_scry_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('cloudreader sphinx', 'Cloudreader Sphinx', '68d074a48c8f785d82b12014eb8b3f41', 'battle_rule_v1:8c424968cc1906699fad2ba5866d5ef7', '{"_keywords_are_self":true,"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_scry_v1","effect":"creature","etb_scry_count":2,"etb_trigger_effect":"scry","flying":true,"keywords":["flying"],"scry_count":2,"trigger":"enters_battlefield","trigger_effect":"scry","trigger_scry_count":2,"xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"ScryEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class CloudreaderSphinx translated into ManaLoom runtime scope xmage_creature_etb_scry_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('faerie seer', 'Faerie Seer', '68d074a48c8f785d82b12014eb8b3f41', 'battle_rule_v1:8c424968cc1906699fad2ba5866d5ef7', '{"_keywords_are_self":true,"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_scry_v1","effect":"creature","etb_scry_count":2,"etb_trigger_effect":"scry","flying":true,"keywords":["flying"],"scry_count":2,"trigger":"enters_battlefield","trigger_effect":"scry","trigger_scry_count":2,"xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"ScryEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class FaerieSeer translated into ManaLoom runtime scope xmage_creature_etb_scry_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('glider kids', 'Glider Kids', 'ad26d1495915babc0e86243a49761178', 'battle_rule_v1:83bb17942e6f86ca784d1785783c02f8', '{"_keywords_are_self":true,"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_scry_v1","effect":"creature","etb_scry_count":1,"etb_trigger_effect":"scry","flying":true,"keywords":["flying"],"scry_count":1,"trigger":"enters_battlefield","trigger_effect":"scry","trigger_scry_count":1,"xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"ScryEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class GliderKids translated into ManaLoom runtime scope xmage_creature_etb_scry_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('grey havens navigator', 'Grey Havens Navigator', '3446d3cb3c4454d8bcaef4afb24a03aa', 'battle_rule_v1:13d75d87933e5b87f6584ce7d870f88b', '{"_keywords_are_self":true,"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_scry_v1","effect":"creature","etb_scry_count":1,"etb_trigger_effect":"scry","flash":true,"keywords":["flash"],"scry_count":1,"trigger":"enters_battlefield","trigger_effect":"scry","trigger_scry_count":1,"xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"ScryEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class GreyHavensNavigator translated into ManaLoom runtime scope xmage_creature_etb_scry_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('horizon scholar', 'Horizon Scholar', '68d074a48c8f785d82b12014eb8b3f41', 'battle_rule_v1:8c424968cc1906699fad2ba5866d5ef7', '{"_keywords_are_self":true,"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_scry_v1","effect":"creature","etb_scry_count":2,"etb_trigger_effect":"scry","flying":true,"keywords":["flying"],"scry_count":2,"trigger":"enters_battlefield","trigger_effect":"scry","trigger_scry_count":2,"xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"ScryEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class HorizonScholar translated into ManaLoom runtime scope xmage_creature_etb_scry_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('senate griffin', 'Senate Griffin', '6d564a66429df23676e0a2d72d667473', 'battle_rule_v1:83bb17942e6f86ca784d1785783c02f8', '{"_keywords_are_self":true,"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_scry_v1","effect":"creature","etb_scry_count":1,"etb_trigger_effect":"scry","flying":true,"keywords":["flying"],"scry_count":1,"trigger":"enters_battlefield","trigger_effect":"scry","trigger_scry_count":1,"xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"ScryEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class SenateGriffin translated into ManaLoom runtime scope xmage_creature_etb_scry_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('silver raven', 'Silver Raven', 'd70888b658f8ccdbcf9730d995915e7b', 'battle_rule_v1:83bb17942e6f86ca784d1785783c02f8', '{"_keywords_are_self":true,"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_scry_v1","effect":"creature","etb_scry_count":1,"etb_trigger_effect":"scry","flying":true,"keywords":["flying"],"scry_count":1,"trigger":"enters_battlefield","trigger_effect":"scry","trigger_scry_count":1,"xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"ScryEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class SilverRaven translated into ManaLoom runtime scope xmage_creature_etb_scry_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('thaumaturge''s familiar', 'Thaumaturge''s Familiar', '6d564a66429df23676e0a2d72d667473', 'battle_rule_v1:83bb17942e6f86ca784d1785783c02f8', '{"_keywords_are_self":true,"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_scry_v1","effect":"creature","etb_scry_count":1,"etb_trigger_effect":"scry","flying":true,"keywords":["flying"],"scry_count":1,"trigger":"enters_battlefield","trigger_effect":"scry","trigger_scry_count":1,"xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"ScryEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ThaumaturgesFamiliar translated into ManaLoom runtime scope xmage_creature_etb_scry_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('wall of runes', 'Wall of Runes', 'd3d9386b475168e08a8a86ad8f75d8a2', 'battle_rule_v1:f02e41ac1bd0430218b795975f29fb9d', '{"_keywords_are_self":true,"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_scry_v1","defender":true,"effect":"creature","etb_scry_count":1,"etb_trigger_effect":"scry","keywords":["defender"],"scry_count":1,"trigger":"enters_battlefield","trigger_effect":"scry","trigger_scry_count":1,"xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"ScryEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class WallOfRunes translated into ManaLoom runtime scope xmage_creature_etb_scry_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('willow-wind', 'Willow-Wind', 'e50f14b80485abf7b731a36129db45f4', 'battle_rule_v1:8c424968cc1906699fad2ba5866d5ef7', '{"_keywords_are_self":true,"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_scry_v1","effect":"creature","etb_scry_count":2,"etb_trigger_effect":"scry","flying":true,"keywords":["flying"],"scry_count":2,"trigger":"enters_battlefield","trigger_effect":"scry","trigger_scry_count":2,"xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"ScryEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class WillowWind translated into ManaLoom runtime scope xmage_creature_etb_scry_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
    ('augury owl', 'Augury Owl', 'b7c450e1cc1c7574009f6120b406d00f', 'battle_rule_v1:575ffe521a678ebd6048179921e143c4', '{"_keywords_are_self":true,"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_scry_v1","effect":"creature","etb_scry_count":3,"etb_trigger_effect":"scry","flying":true,"keywords":["flying"],"scry_count":3,"trigger":"enters_battlefield","trigger_effect":"scry","trigger_scry_count":3,"xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"ScryEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class AuguryOwl translated into ManaLoom runtime scope xmage_creature_etb_scry_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('cloudreader sphinx', 'Cloudreader Sphinx', '68d074a48c8f785d82b12014eb8b3f41', 'battle_rule_v1:8c424968cc1906699fad2ba5866d5ef7', '{"_keywords_are_self":true,"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_scry_v1","effect":"creature","etb_scry_count":2,"etb_trigger_effect":"scry","flying":true,"keywords":["flying"],"scry_count":2,"trigger":"enters_battlefield","trigger_effect":"scry","trigger_scry_count":2,"xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"ScryEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class CloudreaderSphinx translated into ManaLoom runtime scope xmage_creature_etb_scry_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('faerie seer', 'Faerie Seer', '68d074a48c8f785d82b12014eb8b3f41', 'battle_rule_v1:8c424968cc1906699fad2ba5866d5ef7', '{"_keywords_are_self":true,"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_scry_v1","effect":"creature","etb_scry_count":2,"etb_trigger_effect":"scry","flying":true,"keywords":["flying"],"scry_count":2,"trigger":"enters_battlefield","trigger_effect":"scry","trigger_scry_count":2,"xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"ScryEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class FaerieSeer translated into ManaLoom runtime scope xmage_creature_etb_scry_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('glider kids', 'Glider Kids', 'ad26d1495915babc0e86243a49761178', 'battle_rule_v1:83bb17942e6f86ca784d1785783c02f8', '{"_keywords_are_self":true,"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_scry_v1","effect":"creature","etb_scry_count":1,"etb_trigger_effect":"scry","flying":true,"keywords":["flying"],"scry_count":1,"trigger":"enters_battlefield","trigger_effect":"scry","trigger_scry_count":1,"xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"ScryEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class GliderKids translated into ManaLoom runtime scope xmage_creature_etb_scry_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('grey havens navigator', 'Grey Havens Navigator', '3446d3cb3c4454d8bcaef4afb24a03aa', 'battle_rule_v1:13d75d87933e5b87f6584ce7d870f88b', '{"_keywords_are_self":true,"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_scry_v1","effect":"creature","etb_scry_count":1,"etb_trigger_effect":"scry","flash":true,"keywords":["flash"],"scry_count":1,"trigger":"enters_battlefield","trigger_effect":"scry","trigger_scry_count":1,"xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"ScryEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class GreyHavensNavigator translated into ManaLoom runtime scope xmage_creature_etb_scry_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('horizon scholar', 'Horizon Scholar', '68d074a48c8f785d82b12014eb8b3f41', 'battle_rule_v1:8c424968cc1906699fad2ba5866d5ef7', '{"_keywords_are_self":true,"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_scry_v1","effect":"creature","etb_scry_count":2,"etb_trigger_effect":"scry","flying":true,"keywords":["flying"],"scry_count":2,"trigger":"enters_battlefield","trigger_effect":"scry","trigger_scry_count":2,"xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"ScryEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class HorizonScholar translated into ManaLoom runtime scope xmage_creature_etb_scry_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('senate griffin', 'Senate Griffin', '6d564a66429df23676e0a2d72d667473', 'battle_rule_v1:83bb17942e6f86ca784d1785783c02f8', '{"_keywords_are_self":true,"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_scry_v1","effect":"creature","etb_scry_count":1,"etb_trigger_effect":"scry","flying":true,"keywords":["flying"],"scry_count":1,"trigger":"enters_battlefield","trigger_effect":"scry","trigger_scry_count":1,"xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"ScryEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class SenateGriffin translated into ManaLoom runtime scope xmage_creature_etb_scry_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('silver raven', 'Silver Raven', 'd70888b658f8ccdbcf9730d995915e7b', 'battle_rule_v1:83bb17942e6f86ca784d1785783c02f8', '{"_keywords_are_self":true,"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_scry_v1","effect":"creature","etb_scry_count":1,"etb_trigger_effect":"scry","flying":true,"keywords":["flying"],"scry_count":1,"trigger":"enters_battlefield","trigger_effect":"scry","trigger_scry_count":1,"xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"ScryEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class SilverRaven translated into ManaLoom runtime scope xmage_creature_etb_scry_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('thaumaturge''s familiar', 'Thaumaturge''s Familiar', '6d564a66429df23676e0a2d72d667473', 'battle_rule_v1:83bb17942e6f86ca784d1785783c02f8', '{"_keywords_are_self":true,"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_scry_v1","effect":"creature","etb_scry_count":1,"etb_trigger_effect":"scry","flying":true,"keywords":["flying"],"scry_count":1,"trigger":"enters_battlefield","trigger_effect":"scry","trigger_scry_count":1,"xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"ScryEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ThaumaturgesFamiliar translated into ManaLoom runtime scope xmage_creature_etb_scry_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('wall of runes', 'Wall of Runes', 'd3d9386b475168e08a8a86ad8f75d8a2', 'battle_rule_v1:f02e41ac1bd0430218b795975f29fb9d', '{"_keywords_are_self":true,"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_scry_v1","defender":true,"effect":"creature","etb_scry_count":1,"etb_trigger_effect":"scry","keywords":["defender"],"scry_count":1,"trigger":"enters_battlefield","trigger_effect":"scry","trigger_scry_count":1,"xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"ScryEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class WallOfRunes translated into ManaLoom runtime scope xmage_creature_etb_scry_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('willow-wind', 'Willow-Wind', 'e50f14b80485abf7b731a36129db45f4', 'battle_rule_v1:8c424968cc1906699fad2ba5866d5ef7', '{"_keywords_are_self":true,"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_scry_v1","effect":"creature","etb_scry_count":2,"etb_trigger_effect":"scry","flying":true,"keywords":["flying"],"scry_count":2,"trigger":"enters_battlefield","trigger_effect":"scry","trigger_scry_count":2,"xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"ScryEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class WillowWind translated into ManaLoom runtime scope xmage_creature_etb_scry_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
