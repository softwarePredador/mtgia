BEGIN;

CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit;

CREATE TABLE IF NOT EXISTS manaloom_deploy_audit.pg577_etb_library_tutor_creatures_20260706_222420 AS
SELECT *
FROM public.card_battle_rules
WHERE normalized_name IN ('boggart harbinger', 'campus guide', 'compass gnome', 'faerie harbinger', 'flamekin harbinger', 'giant harbinger', 'giant ladybug', 'kithkin harbinger', 'loam larva', 'scampering surveyor', 'spider-bot')
   OR normalized_name LIKE 'boggart harbinger // %'
   OR normalized_name LIKE 'campus guide // %'
   OR normalized_name LIKE 'compass gnome // %'
   OR normalized_name LIKE 'faerie harbinger // %'
   OR normalized_name LIKE 'flamekin harbinger // %'
   OR normalized_name LIKE 'giant harbinger // %'
   OR normalized_name LIKE 'giant ladybug // %'
   OR normalized_name LIKE 'kithkin harbinger // %'
   OR normalized_name LIKE 'loam larva // %'
   OR normalized_name LIKE 'scampering surveyor // %'
   OR normalized_name LIKE 'spider-bot // %';

DO $$
DECLARE
  v_missing jsonb;
BEGIN
  WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('boggart harbinger', 'Boggart Harbinger', 'e5f0576f0172323b7e8798a69069199d', 'battle_rule_v1:8ac6a6877f0b44d0ae26c029bb8d1117', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_library_search_to_top_v1","count":1,"destination":"library_top","effect":"creature","etb_tutor_count":1,"etb_tutor_target":"any_to_top","target":"any_to_top","target_subtypes":["goblin"],"trigger":"enters_battlefield","trigger_effect":"library_tutor_to_top","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"SearchLibraryPutOnLibraryEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"any_to_top"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class BoggartHarbinger translated into ManaLoom runtime scope xmage_creature_etb_library_search_to_top_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('campus guide', 'Campus Guide', '26846e5bc0ddcbe7957a74e496d92122', 'battle_rule_v1:24ee2f2441cb28108d4b7aa8f39a71a1', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_library_search_to_top_v1","count":1,"destination":"library_top","effect":"creature","etb_tutor_count":1,"etb_tutor_target":"basic_land_to_top","target":"basic_land_to_top","trigger":"enters_battlefield","trigger_effect":"library_tutor_to_top","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"SearchLibraryPutOnLibraryEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"basic_land_to_top"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class CampusGuide translated into ManaLoom runtime scope xmage_creature_etb_library_search_to_top_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('compass gnome', 'Compass Gnome', '58fba482e97f4685625e59f26bd9f81b', 'battle_rule_v1:2b5adb3004f8226b1aa0087791143ecc', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_library_search_to_top_v1","count":1,"destination":"library_top","effect":"creature","etb_tutor_count":1,"etb_tutor_target":"basic_land_or_cave_to_top","target":"basic_land_or_cave_to_top","trigger":"enters_battlefield","trigger_effect":"library_tutor_to_top","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"SearchLibraryPutOnLibraryEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"basic_land_or_cave_to_top"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class CompassGnome translated into ManaLoom runtime scope xmage_creature_etb_library_search_to_top_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('faerie harbinger', 'Faerie Harbinger', '87cee14f7ca7688e6ac4672bc3c647f5', 'battle_rule_v1:81f3b3a7231902b0adcec03d32c1820c', '{"_keywords_are_self":true,"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_library_search_to_top_v1","count":1,"destination":"library_top","effect":"creature","etb_tutor_count":1,"etb_tutor_target":"any_to_top","flash":true,"flying":true,"keywords":["flash","flying"],"target":"any_to_top","target_subtypes":["faerie"],"trigger":"enters_battlefield","trigger_effect":"library_tutor_to_top","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"SearchLibraryPutOnLibraryEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"any_to_top"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class FaerieHarbinger translated into ManaLoom runtime scope xmage_creature_etb_library_search_to_top_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('flamekin harbinger', 'Flamekin Harbinger', '84183e5321971ca284ee29c5b8a26ef1', 'battle_rule_v1:c1678afe69fd7114cfa482cc934c3d4f', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_library_search_to_top_v1","count":1,"destination":"library_top","effect":"creature","etb_tutor_count":1,"etb_tutor_target":"any_to_top","target":"any_to_top","target_subtypes":["elemental"],"trigger":"enters_battlefield","trigger_effect":"library_tutor_to_top","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"SearchLibraryPutOnLibraryEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"any_to_top"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class FlamekinHarbinger translated into ManaLoom runtime scope xmage_creature_etb_library_search_to_top_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('giant harbinger', 'Giant Harbinger', 'af5745b1d22887f3db63255a170b92d5', 'battle_rule_v1:222a10f082bfc14fbeba7ccf10884f71', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_library_search_to_top_v1","count":1,"destination":"library_top","effect":"creature","etb_tutor_count":1,"etb_tutor_target":"any_to_top","target":"any_to_top","target_subtypes":["giant"],"trigger":"enters_battlefield","trigger_effect":"library_tutor_to_top","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"SearchLibraryPutOnLibraryEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"any_to_top"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class GiantHarbinger translated into ManaLoom runtime scope xmage_creature_etb_library_search_to_top_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('giant ladybug', 'Giant Ladybug', 'd343af3b0c3541b8852d86033512b64d', 'battle_rule_v1:126ee4675a65076a75dd82647a715d20', '{"_keywords_are_self":true,"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_library_search_to_top_v1","count":1,"destination":"library_top","effect":"creature","etb_tutor_count":1,"etb_tutor_target":"basic_land_to_top","keywords":["reach"],"reach":true,"target":"basic_land_to_top","trigger":"enters_battlefield","trigger_effect":"library_tutor_to_top","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"SearchLibraryPutOnLibraryEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"basic_land_to_top"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class GiantLadybug translated into ManaLoom runtime scope xmage_creature_etb_library_search_to_top_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('kithkin harbinger', 'Kithkin Harbinger', '9c4bf40f15566d622be1fb3b21a06592', 'battle_rule_v1:d6ecac707233523e08b819dc3628b6ac', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_library_search_to_top_v1","count":1,"destination":"library_top","effect":"creature","etb_tutor_count":1,"etb_tutor_target":"any_to_top","target":"any_to_top","target_subtypes":["kithkin"],"trigger":"enters_battlefield","trigger_effect":"library_tutor_to_top","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"SearchLibraryPutOnLibraryEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"any_to_top"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class KithkinHarbinger translated into ManaLoom runtime scope xmage_creature_etb_library_search_to_top_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('loam larva', 'Loam Larva', '26846e5bc0ddcbe7957a74e496d92122', 'battle_rule_v1:24ee2f2441cb28108d4b7aa8f39a71a1', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_library_search_to_top_v1","count":1,"destination":"library_top","effect":"creature","etb_tutor_count":1,"etb_tutor_target":"basic_land_to_top","target":"basic_land_to_top","trigger":"enters_battlefield","trigger_effect":"library_tutor_to_top","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"SearchLibraryPutOnLibraryEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"basic_land_to_top"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class LoamLarva translated into ManaLoom runtime scope xmage_creature_etb_library_search_to_top_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('scampering surveyor', 'Scampering Surveyor', 'c6ca72b3b7a3634ea5caa3d9b2c4c9a4', 'battle_rule_v1:ca664664ddad191cdf11a5036f2e92b7', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_library_search_to_battlefield_v1","count":1,"destination":"battlefield","effect":"creature","etb_tutor_count":1,"etb_tutor_target":"basic_land_or_cave_to_battlefield","target":"basic_land_or_cave_to_battlefield","trigger":"enters_battlefield","tutor_enters_tapped":true,"xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"SearchLibraryPutInPlayEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"basic_land_or_cave_to_battlefield"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ScamperingSurveyor translated into ManaLoom runtime scope xmage_creature_etb_library_search_to_battlefield_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('spider-bot', 'Spider-Bot', 'd343af3b0c3541b8852d86033512b64d', 'battle_rule_v1:126ee4675a65076a75dd82647a715d20', '{"_keywords_are_self":true,"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_library_search_to_top_v1","count":1,"destination":"library_top","effect":"creature","etb_tutor_count":1,"etb_tutor_target":"basic_land_to_top","keywords":["reach"],"reach":true,"target":"basic_land_to_top","trigger":"enters_battlefield","trigger_effect":"library_tutor_to_top","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"SearchLibraryPutOnLibraryEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"basic_land_to_top"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class SpiderBot translated into ManaLoom runtime scope xmage_creature_etb_library_search_to_top_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
    ('boggart harbinger', 'Boggart Harbinger', 'e5f0576f0172323b7e8798a69069199d', 'battle_rule_v1:8ac6a6877f0b44d0ae26c029bb8d1117', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_library_search_to_top_v1","count":1,"destination":"library_top","effect":"creature","etb_tutor_count":1,"etb_tutor_target":"any_to_top","target":"any_to_top","target_subtypes":["goblin"],"trigger":"enters_battlefield","trigger_effect":"library_tutor_to_top","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"SearchLibraryPutOnLibraryEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"any_to_top"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class BoggartHarbinger translated into ManaLoom runtime scope xmage_creature_etb_library_search_to_top_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('campus guide', 'Campus Guide', '26846e5bc0ddcbe7957a74e496d92122', 'battle_rule_v1:24ee2f2441cb28108d4b7aa8f39a71a1', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_library_search_to_top_v1","count":1,"destination":"library_top","effect":"creature","etb_tutor_count":1,"etb_tutor_target":"basic_land_to_top","target":"basic_land_to_top","trigger":"enters_battlefield","trigger_effect":"library_tutor_to_top","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"SearchLibraryPutOnLibraryEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"basic_land_to_top"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class CampusGuide translated into ManaLoom runtime scope xmage_creature_etb_library_search_to_top_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('compass gnome', 'Compass Gnome', '58fba482e97f4685625e59f26bd9f81b', 'battle_rule_v1:2b5adb3004f8226b1aa0087791143ecc', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_library_search_to_top_v1","count":1,"destination":"library_top","effect":"creature","etb_tutor_count":1,"etb_tutor_target":"basic_land_or_cave_to_top","target":"basic_land_or_cave_to_top","trigger":"enters_battlefield","trigger_effect":"library_tutor_to_top","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"SearchLibraryPutOnLibraryEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"basic_land_or_cave_to_top"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class CompassGnome translated into ManaLoom runtime scope xmage_creature_etb_library_search_to_top_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('faerie harbinger', 'Faerie Harbinger', '87cee14f7ca7688e6ac4672bc3c647f5', 'battle_rule_v1:81f3b3a7231902b0adcec03d32c1820c', '{"_keywords_are_self":true,"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_library_search_to_top_v1","count":1,"destination":"library_top","effect":"creature","etb_tutor_count":1,"etb_tutor_target":"any_to_top","flash":true,"flying":true,"keywords":["flash","flying"],"target":"any_to_top","target_subtypes":["faerie"],"trigger":"enters_battlefield","trigger_effect":"library_tutor_to_top","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"SearchLibraryPutOnLibraryEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"any_to_top"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class FaerieHarbinger translated into ManaLoom runtime scope xmage_creature_etb_library_search_to_top_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('flamekin harbinger', 'Flamekin Harbinger', '84183e5321971ca284ee29c5b8a26ef1', 'battle_rule_v1:c1678afe69fd7114cfa482cc934c3d4f', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_library_search_to_top_v1","count":1,"destination":"library_top","effect":"creature","etb_tutor_count":1,"etb_tutor_target":"any_to_top","target":"any_to_top","target_subtypes":["elemental"],"trigger":"enters_battlefield","trigger_effect":"library_tutor_to_top","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"SearchLibraryPutOnLibraryEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"any_to_top"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class FlamekinHarbinger translated into ManaLoom runtime scope xmage_creature_etb_library_search_to_top_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('giant harbinger', 'Giant Harbinger', 'af5745b1d22887f3db63255a170b92d5', 'battle_rule_v1:222a10f082bfc14fbeba7ccf10884f71', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_library_search_to_top_v1","count":1,"destination":"library_top","effect":"creature","etb_tutor_count":1,"etb_tutor_target":"any_to_top","target":"any_to_top","target_subtypes":["giant"],"trigger":"enters_battlefield","trigger_effect":"library_tutor_to_top","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"SearchLibraryPutOnLibraryEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"any_to_top"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class GiantHarbinger translated into ManaLoom runtime scope xmage_creature_etb_library_search_to_top_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('giant ladybug', 'Giant Ladybug', 'd343af3b0c3541b8852d86033512b64d', 'battle_rule_v1:126ee4675a65076a75dd82647a715d20', '{"_keywords_are_self":true,"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_library_search_to_top_v1","count":1,"destination":"library_top","effect":"creature","etb_tutor_count":1,"etb_tutor_target":"basic_land_to_top","keywords":["reach"],"reach":true,"target":"basic_land_to_top","trigger":"enters_battlefield","trigger_effect":"library_tutor_to_top","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"SearchLibraryPutOnLibraryEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"basic_land_to_top"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class GiantLadybug translated into ManaLoom runtime scope xmage_creature_etb_library_search_to_top_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('kithkin harbinger', 'Kithkin Harbinger', '9c4bf40f15566d622be1fb3b21a06592', 'battle_rule_v1:d6ecac707233523e08b819dc3628b6ac', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_library_search_to_top_v1","count":1,"destination":"library_top","effect":"creature","etb_tutor_count":1,"etb_tutor_target":"any_to_top","target":"any_to_top","target_subtypes":["kithkin"],"trigger":"enters_battlefield","trigger_effect":"library_tutor_to_top","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"SearchLibraryPutOnLibraryEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"any_to_top"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class KithkinHarbinger translated into ManaLoom runtime scope xmage_creature_etb_library_search_to_top_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('loam larva', 'Loam Larva', '26846e5bc0ddcbe7957a74e496d92122', 'battle_rule_v1:24ee2f2441cb28108d4b7aa8f39a71a1', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_library_search_to_top_v1","count":1,"destination":"library_top","effect":"creature","etb_tutor_count":1,"etb_tutor_target":"basic_land_to_top","target":"basic_land_to_top","trigger":"enters_battlefield","trigger_effect":"library_tutor_to_top","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"SearchLibraryPutOnLibraryEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"basic_land_to_top"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class LoamLarva translated into ManaLoom runtime scope xmage_creature_etb_library_search_to_top_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('scampering surveyor', 'Scampering Surveyor', 'c6ca72b3b7a3634ea5caa3d9b2c4c9a4', 'battle_rule_v1:ca664664ddad191cdf11a5036f2e92b7', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_library_search_to_battlefield_v1","count":1,"destination":"battlefield","effect":"creature","etb_tutor_count":1,"etb_tutor_target":"basic_land_or_cave_to_battlefield","target":"basic_land_or_cave_to_battlefield","trigger":"enters_battlefield","tutor_enters_tapped":true,"xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"SearchLibraryPutInPlayEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"basic_land_or_cave_to_battlefield"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ScamperingSurveyor translated into ManaLoom runtime scope xmage_creature_etb_library_search_to_battlefield_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('spider-bot', 'Spider-Bot', 'd343af3b0c3541b8852d86033512b64d', 'battle_rule_v1:126ee4675a65076a75dd82647a715d20', '{"_keywords_are_self":true,"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_library_search_to_top_v1","count":1,"destination":"library_top","effect":"creature","etb_tutor_count":1,"etb_tutor_target":"basic_land_to_top","keywords":["reach"],"reach":true,"target":"basic_land_to_top","trigger":"enters_battlefield","trigger_effect":"library_tutor_to_top","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"SearchLibraryPutOnLibraryEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"basic_land_to_top"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class SpiderBot translated into ManaLoom runtime scope xmage_creature_etb_library_search_to_top_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
    ('boggart harbinger', 'Boggart Harbinger', 'e5f0576f0172323b7e8798a69069199d', 'battle_rule_v1:8ac6a6877f0b44d0ae26c029bb8d1117', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_library_search_to_top_v1","count":1,"destination":"library_top","effect":"creature","etb_tutor_count":1,"etb_tutor_target":"any_to_top","target":"any_to_top","target_subtypes":["goblin"],"trigger":"enters_battlefield","trigger_effect":"library_tutor_to_top","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"SearchLibraryPutOnLibraryEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"any_to_top"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class BoggartHarbinger translated into ManaLoom runtime scope xmage_creature_etb_library_search_to_top_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('campus guide', 'Campus Guide', '26846e5bc0ddcbe7957a74e496d92122', 'battle_rule_v1:24ee2f2441cb28108d4b7aa8f39a71a1', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_library_search_to_top_v1","count":1,"destination":"library_top","effect":"creature","etb_tutor_count":1,"etb_tutor_target":"basic_land_to_top","target":"basic_land_to_top","trigger":"enters_battlefield","trigger_effect":"library_tutor_to_top","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"SearchLibraryPutOnLibraryEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"basic_land_to_top"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class CampusGuide translated into ManaLoom runtime scope xmage_creature_etb_library_search_to_top_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('compass gnome', 'Compass Gnome', '58fba482e97f4685625e59f26bd9f81b', 'battle_rule_v1:2b5adb3004f8226b1aa0087791143ecc', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_library_search_to_top_v1","count":1,"destination":"library_top","effect":"creature","etb_tutor_count":1,"etb_tutor_target":"basic_land_or_cave_to_top","target":"basic_land_or_cave_to_top","trigger":"enters_battlefield","trigger_effect":"library_tutor_to_top","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"SearchLibraryPutOnLibraryEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"basic_land_or_cave_to_top"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class CompassGnome translated into ManaLoom runtime scope xmage_creature_etb_library_search_to_top_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('faerie harbinger', 'Faerie Harbinger', '87cee14f7ca7688e6ac4672bc3c647f5', 'battle_rule_v1:81f3b3a7231902b0adcec03d32c1820c', '{"_keywords_are_self":true,"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_library_search_to_top_v1","count":1,"destination":"library_top","effect":"creature","etb_tutor_count":1,"etb_tutor_target":"any_to_top","flash":true,"flying":true,"keywords":["flash","flying"],"target":"any_to_top","target_subtypes":["faerie"],"trigger":"enters_battlefield","trigger_effect":"library_tutor_to_top","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"SearchLibraryPutOnLibraryEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"any_to_top"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class FaerieHarbinger translated into ManaLoom runtime scope xmage_creature_etb_library_search_to_top_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('flamekin harbinger', 'Flamekin Harbinger', '84183e5321971ca284ee29c5b8a26ef1', 'battle_rule_v1:c1678afe69fd7114cfa482cc934c3d4f', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_library_search_to_top_v1","count":1,"destination":"library_top","effect":"creature","etb_tutor_count":1,"etb_tutor_target":"any_to_top","target":"any_to_top","target_subtypes":["elemental"],"trigger":"enters_battlefield","trigger_effect":"library_tutor_to_top","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"SearchLibraryPutOnLibraryEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"any_to_top"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class FlamekinHarbinger translated into ManaLoom runtime scope xmage_creature_etb_library_search_to_top_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('giant harbinger', 'Giant Harbinger', 'af5745b1d22887f3db63255a170b92d5', 'battle_rule_v1:222a10f082bfc14fbeba7ccf10884f71', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_library_search_to_top_v1","count":1,"destination":"library_top","effect":"creature","etb_tutor_count":1,"etb_tutor_target":"any_to_top","target":"any_to_top","target_subtypes":["giant"],"trigger":"enters_battlefield","trigger_effect":"library_tutor_to_top","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"SearchLibraryPutOnLibraryEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"any_to_top"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class GiantHarbinger translated into ManaLoom runtime scope xmage_creature_etb_library_search_to_top_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('giant ladybug', 'Giant Ladybug', 'd343af3b0c3541b8852d86033512b64d', 'battle_rule_v1:126ee4675a65076a75dd82647a715d20', '{"_keywords_are_self":true,"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_library_search_to_top_v1","count":1,"destination":"library_top","effect":"creature","etb_tutor_count":1,"etb_tutor_target":"basic_land_to_top","keywords":["reach"],"reach":true,"target":"basic_land_to_top","trigger":"enters_battlefield","trigger_effect":"library_tutor_to_top","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"SearchLibraryPutOnLibraryEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"basic_land_to_top"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class GiantLadybug translated into ManaLoom runtime scope xmage_creature_etb_library_search_to_top_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('kithkin harbinger', 'Kithkin Harbinger', '9c4bf40f15566d622be1fb3b21a06592', 'battle_rule_v1:d6ecac707233523e08b819dc3628b6ac', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_library_search_to_top_v1","count":1,"destination":"library_top","effect":"creature","etb_tutor_count":1,"etb_tutor_target":"any_to_top","target":"any_to_top","target_subtypes":["kithkin"],"trigger":"enters_battlefield","trigger_effect":"library_tutor_to_top","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"SearchLibraryPutOnLibraryEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"any_to_top"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class KithkinHarbinger translated into ManaLoom runtime scope xmage_creature_etb_library_search_to_top_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('loam larva', 'Loam Larva', '26846e5bc0ddcbe7957a74e496d92122', 'battle_rule_v1:24ee2f2441cb28108d4b7aa8f39a71a1', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_library_search_to_top_v1","count":1,"destination":"library_top","effect":"creature","etb_tutor_count":1,"etb_tutor_target":"basic_land_to_top","target":"basic_land_to_top","trigger":"enters_battlefield","trigger_effect":"library_tutor_to_top","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"SearchLibraryPutOnLibraryEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"basic_land_to_top"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class LoamLarva translated into ManaLoom runtime scope xmage_creature_etb_library_search_to_top_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('scampering surveyor', 'Scampering Surveyor', 'c6ca72b3b7a3634ea5caa3d9b2c4c9a4', 'battle_rule_v1:ca664664ddad191cdf11a5036f2e92b7', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_library_search_to_battlefield_v1","count":1,"destination":"battlefield","effect":"creature","etb_tutor_count":1,"etb_tutor_target":"basic_land_or_cave_to_battlefield","target":"basic_land_or_cave_to_battlefield","trigger":"enters_battlefield","tutor_enters_tapped":true,"xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"SearchLibraryPutInPlayEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"basic_land_or_cave_to_battlefield"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ScamperingSurveyor translated into ManaLoom runtime scope xmage_creature_etb_library_search_to_battlefield_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('spider-bot', 'Spider-Bot', 'd343af3b0c3541b8852d86033512b64d', 'battle_rule_v1:126ee4675a65076a75dd82647a715d20', '{"_keywords_are_self":true,"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_library_search_to_top_v1","count":1,"destination":"library_top","effect":"creature","etb_tutor_count":1,"etb_tutor_target":"basic_land_to_top","keywords":["reach"],"reach":true,"target":"basic_land_to_top","trigger":"enters_battlefield","trigger_effect":"library_tutor_to_top","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"SearchLibraryPutOnLibraryEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"basic_land_to_top"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class SpiderBot translated into ManaLoom runtime scope xmage_creature_etb_library_search_to_top_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
