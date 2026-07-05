BEGIN;

CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit;

CREATE TABLE IF NOT EXISTS manaloom_deploy_audit.pg508_xmage_pg508_etb_destroy_residual_n_20260705_131908 AS
SELECT *
FROM public.card_battle_rules
WHERE normalized_name IN ('armaggon, future shark', 'final-sting faerie', 'gilt-leaf winnower', 'kraul whipcracker', 'lurking deadeye', 'nekrataal', 'ogre gatecrasher', 'stingerfling spider')
   OR normalized_name LIKE 'armaggon, future shark // %'
   OR normalized_name LIKE 'final-sting faerie // %'
   OR normalized_name LIKE 'gilt-leaf winnower // %'
   OR normalized_name LIKE 'kraul whipcracker // %'
   OR normalized_name LIKE 'lurking deadeye // %'
   OR normalized_name LIKE 'nekrataal // %'
   OR normalized_name LIKE 'ogre gatecrasher // %'
   OR normalized_name LIKE 'stingerfling spider // %';

DO $$
DECLARE
  v_missing jsonb;
BEGIN
  WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('armaggon, future shark', 'Armaggon, Future Shark', '42d0563f848525d5b48b5a965e737a82', 'battle_rule_v1:f96dc72f401683ff611868a4b8f983e4', '{"_keywords_are_self":true,"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_destroy_target_v1","destination":"graveyard","effect":"creature","etb_remove_effect":"remove_creature","etb_remove_target":"creature","flash":true,"keywords":["flash"],"max_targets":3,"target_constraints":{"card_types":["creature"]},"trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"DestroyTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ArmaggonFutureShark translated into ManaLoom runtime scope xmage_creature_etb_destroy_target_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('final-sting faerie', 'Final-Sting Faerie', '42d0d972b96570dadafcd049776cc4bd', 'battle_rule_v1:2c266d73b60612c1698b37380e2569bd', '{"_keywords_are_self":true,"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_destroy_target_v1","destination":"graveyard","effect":"creature","etb_remove_effect":"remove_creature","etb_remove_target":"creature","flying":true,"keywords":["flying"],"target_constraints":{"card_types":["creature"],"damaged_this_turn":true},"trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"DestroyTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class FinalStingFaerie translated into ManaLoom runtime scope xmage_creature_etb_destroy_target_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('gilt-leaf winnower', 'Gilt-Leaf Winnower', '2b700e8000d83ff1a3b5123f7a94a539', 'battle_rule_v1:c9a712d3ef34819b410ce03a92e5e520', '{"_keywords_are_self":true,"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_destroy_target_v1","destination":"graveyard","effect":"creature","etb_remove_effect":"remove_creature","etb_remove_target":"creature","keywords":["menace"],"menace":true,"target_constraints":{"card_types":["creature"],"exclude_subtypes":["elf"],"power_toughness_not_equal":true},"trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"DestroyTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class GiltLeafWinnower translated into ManaLoom runtime scope xmage_creature_etb_destroy_target_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('kraul whipcracker', 'Kraul Whipcracker', '3f8818b7b6a2340e8240ae3f68e81f4e', 'battle_rule_v1:dd9bbbfafb8d905d6c63ad502a4b3705', '{"_keywords_are_self":true,"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_destroy_target_v1","destination":"graveyard","effect":"creature","etb_remove_effect":"remove_permanent","etb_remove_target":"permanent","keywords":["reach"],"reach":true,"target_constraints":{"card_types":["permanent"],"controller_scope":"opponent","token":true},"target_controller":"opponent","trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"DestroyTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class KraulWhipcracker translated into ManaLoom runtime scope xmage_creature_etb_destroy_target_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('lurking deadeye', 'Lurking Deadeye', 'bf55cf78c4c69fd8dcd2e76d855f0e85', 'battle_rule_v1:88a7268178877454ebebb8065e85ffdb', '{"_keywords_are_self":true,"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_destroy_target_v1","destination":"graveyard","effect":"creature","etb_remove_effect":"remove_creature","etb_remove_target":"creature","flash":true,"keywords":["flash"],"target_constraints":{"card_types":["creature"],"damaged_this_turn":true},"trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"DestroyTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class LurkingDeadeye translated into ManaLoom runtime scope xmage_creature_etb_destroy_target_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('nekrataal', 'Nekrataal', '390a3a6d4a8e535f7740f8956122e094', 'battle_rule_v1:37c237dafb6102dd303e7e6032f5aa26', '{"_keywords_are_self":true,"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_destroy_target_v1","destination":"graveyard","effect":"creature","etb_remove_effect":"remove_creature","etb_remove_target":"creature","first_strike":true,"keywords":["first_strike"],"target_constraints":{"card_types":["creature"],"exclude_card_types":["artifact"],"exclude_colors":["B"]},"trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"DestroyTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Nekrataal translated into ManaLoom runtime scope xmage_creature_etb_destroy_target_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('ogre gatecrasher', 'Ogre Gatecrasher', 'f0b9214dea59196b599d4a824f349a79', 'battle_rule_v1:42db1519409feeb45390c07a693f6f60', '{"_keywords_are_self":true,"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_destroy_target_v1","defender":true,"destination":"graveyard","effect":"creature","etb_remove_effect":"remove_creature","etb_remove_target":"creature","keywords":["defender"],"target_constraints":{"card_types":["creature"],"required_keywords":["defender"]},"trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"DestroyTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class OgreGatecrasher translated into ManaLoom runtime scope xmage_creature_etb_destroy_target_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('stingerfling spider', 'Stingerfling Spider', '2bd99d3e075e935e742104ca6e55dddd', 'battle_rule_v1:0dd5fc990d260f811c5aac9dc86150c7', '{"_keywords_are_self":true,"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_destroy_target_v1","destination":"graveyard","effect":"creature","etb_remove_effect":"remove_creature","etb_remove_target":"creature","keywords":["reach"],"reach":true,"target_constraints":{"card_types":["creature"],"required_keywords":["flying"]},"trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"DestroyTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class StingerflingSpider translated into ManaLoom runtime scope xmage_creature_etb_destroy_target_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
    ('armaggon, future shark', 'Armaggon, Future Shark', '42d0563f848525d5b48b5a965e737a82', 'battle_rule_v1:f96dc72f401683ff611868a4b8f983e4', '{"_keywords_are_self":true,"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_destroy_target_v1","destination":"graveyard","effect":"creature","etb_remove_effect":"remove_creature","etb_remove_target":"creature","flash":true,"keywords":["flash"],"max_targets":3,"target_constraints":{"card_types":["creature"]},"trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"DestroyTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ArmaggonFutureShark translated into ManaLoom runtime scope xmage_creature_etb_destroy_target_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('final-sting faerie', 'Final-Sting Faerie', '42d0d972b96570dadafcd049776cc4bd', 'battle_rule_v1:2c266d73b60612c1698b37380e2569bd', '{"_keywords_are_self":true,"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_destroy_target_v1","destination":"graveyard","effect":"creature","etb_remove_effect":"remove_creature","etb_remove_target":"creature","flying":true,"keywords":["flying"],"target_constraints":{"card_types":["creature"],"damaged_this_turn":true},"trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"DestroyTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class FinalStingFaerie translated into ManaLoom runtime scope xmage_creature_etb_destroy_target_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('gilt-leaf winnower', 'Gilt-Leaf Winnower', '2b700e8000d83ff1a3b5123f7a94a539', 'battle_rule_v1:c9a712d3ef34819b410ce03a92e5e520', '{"_keywords_are_self":true,"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_destroy_target_v1","destination":"graveyard","effect":"creature","etb_remove_effect":"remove_creature","etb_remove_target":"creature","keywords":["menace"],"menace":true,"target_constraints":{"card_types":["creature"],"exclude_subtypes":["elf"],"power_toughness_not_equal":true},"trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"DestroyTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class GiltLeafWinnower translated into ManaLoom runtime scope xmage_creature_etb_destroy_target_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('kraul whipcracker', 'Kraul Whipcracker', '3f8818b7b6a2340e8240ae3f68e81f4e', 'battle_rule_v1:dd9bbbfafb8d905d6c63ad502a4b3705', '{"_keywords_are_self":true,"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_destroy_target_v1","destination":"graveyard","effect":"creature","etb_remove_effect":"remove_permanent","etb_remove_target":"permanent","keywords":["reach"],"reach":true,"target_constraints":{"card_types":["permanent"],"controller_scope":"opponent","token":true},"target_controller":"opponent","trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"DestroyTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class KraulWhipcracker translated into ManaLoom runtime scope xmage_creature_etb_destroy_target_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('lurking deadeye', 'Lurking Deadeye', 'bf55cf78c4c69fd8dcd2e76d855f0e85', 'battle_rule_v1:88a7268178877454ebebb8065e85ffdb', '{"_keywords_are_self":true,"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_destroy_target_v1","destination":"graveyard","effect":"creature","etb_remove_effect":"remove_creature","etb_remove_target":"creature","flash":true,"keywords":["flash"],"target_constraints":{"card_types":["creature"],"damaged_this_turn":true},"trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"DestroyTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class LurkingDeadeye translated into ManaLoom runtime scope xmage_creature_etb_destroy_target_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('nekrataal', 'Nekrataal', '390a3a6d4a8e535f7740f8956122e094', 'battle_rule_v1:37c237dafb6102dd303e7e6032f5aa26', '{"_keywords_are_self":true,"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_destroy_target_v1","destination":"graveyard","effect":"creature","etb_remove_effect":"remove_creature","etb_remove_target":"creature","first_strike":true,"keywords":["first_strike"],"target_constraints":{"card_types":["creature"],"exclude_card_types":["artifact"],"exclude_colors":["B"]},"trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"DestroyTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Nekrataal translated into ManaLoom runtime scope xmage_creature_etb_destroy_target_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('ogre gatecrasher', 'Ogre Gatecrasher', 'f0b9214dea59196b599d4a824f349a79', 'battle_rule_v1:42db1519409feeb45390c07a693f6f60', '{"_keywords_are_self":true,"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_destroy_target_v1","defender":true,"destination":"graveyard","effect":"creature","etb_remove_effect":"remove_creature","etb_remove_target":"creature","keywords":["defender"],"target_constraints":{"card_types":["creature"],"required_keywords":["defender"]},"trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"DestroyTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class OgreGatecrasher translated into ManaLoom runtime scope xmage_creature_etb_destroy_target_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('stingerfling spider', 'Stingerfling Spider', '2bd99d3e075e935e742104ca6e55dddd', 'battle_rule_v1:0dd5fc990d260f811c5aac9dc86150c7', '{"_keywords_are_self":true,"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_destroy_target_v1","destination":"graveyard","effect":"creature","etb_remove_effect":"remove_creature","etb_remove_target":"creature","keywords":["reach"],"reach":true,"target_constraints":{"card_types":["creature"],"required_keywords":["flying"]},"trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"DestroyTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class StingerflingSpider translated into ManaLoom runtime scope xmage_creature_etb_destroy_target_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
    ('armaggon, future shark', 'Armaggon, Future Shark', '42d0563f848525d5b48b5a965e737a82', 'battle_rule_v1:f96dc72f401683ff611868a4b8f983e4', '{"_keywords_are_self":true,"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_destroy_target_v1","destination":"graveyard","effect":"creature","etb_remove_effect":"remove_creature","etb_remove_target":"creature","flash":true,"keywords":["flash"],"max_targets":3,"target_constraints":{"card_types":["creature"]},"trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"DestroyTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ArmaggonFutureShark translated into ManaLoom runtime scope xmage_creature_etb_destroy_target_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('final-sting faerie', 'Final-Sting Faerie', '42d0d972b96570dadafcd049776cc4bd', 'battle_rule_v1:2c266d73b60612c1698b37380e2569bd', '{"_keywords_are_self":true,"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_destroy_target_v1","destination":"graveyard","effect":"creature","etb_remove_effect":"remove_creature","etb_remove_target":"creature","flying":true,"keywords":["flying"],"target_constraints":{"card_types":["creature"],"damaged_this_turn":true},"trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"DestroyTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class FinalStingFaerie translated into ManaLoom runtime scope xmage_creature_etb_destroy_target_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('gilt-leaf winnower', 'Gilt-Leaf Winnower', '2b700e8000d83ff1a3b5123f7a94a539', 'battle_rule_v1:c9a712d3ef34819b410ce03a92e5e520', '{"_keywords_are_self":true,"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_destroy_target_v1","destination":"graveyard","effect":"creature","etb_remove_effect":"remove_creature","etb_remove_target":"creature","keywords":["menace"],"menace":true,"target_constraints":{"card_types":["creature"],"exclude_subtypes":["elf"],"power_toughness_not_equal":true},"trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"DestroyTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class GiltLeafWinnower translated into ManaLoom runtime scope xmage_creature_etb_destroy_target_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('kraul whipcracker', 'Kraul Whipcracker', '3f8818b7b6a2340e8240ae3f68e81f4e', 'battle_rule_v1:dd9bbbfafb8d905d6c63ad502a4b3705', '{"_keywords_are_self":true,"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_destroy_target_v1","destination":"graveyard","effect":"creature","etb_remove_effect":"remove_permanent","etb_remove_target":"permanent","keywords":["reach"],"reach":true,"target_constraints":{"card_types":["permanent"],"controller_scope":"opponent","token":true},"target_controller":"opponent","trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"DestroyTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class KraulWhipcracker translated into ManaLoom runtime scope xmage_creature_etb_destroy_target_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('lurking deadeye', 'Lurking Deadeye', 'bf55cf78c4c69fd8dcd2e76d855f0e85', 'battle_rule_v1:88a7268178877454ebebb8065e85ffdb', '{"_keywords_are_self":true,"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_destroy_target_v1","destination":"graveyard","effect":"creature","etb_remove_effect":"remove_creature","etb_remove_target":"creature","flash":true,"keywords":["flash"],"target_constraints":{"card_types":["creature"],"damaged_this_turn":true},"trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"DestroyTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class LurkingDeadeye translated into ManaLoom runtime scope xmage_creature_etb_destroy_target_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('nekrataal', 'Nekrataal', '390a3a6d4a8e535f7740f8956122e094', 'battle_rule_v1:37c237dafb6102dd303e7e6032f5aa26', '{"_keywords_are_self":true,"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_destroy_target_v1","destination":"graveyard","effect":"creature","etb_remove_effect":"remove_creature","etb_remove_target":"creature","first_strike":true,"keywords":["first_strike"],"target_constraints":{"card_types":["creature"],"exclude_card_types":["artifact"],"exclude_colors":["B"]},"trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"DestroyTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Nekrataal translated into ManaLoom runtime scope xmage_creature_etb_destroy_target_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('ogre gatecrasher', 'Ogre Gatecrasher', 'f0b9214dea59196b599d4a824f349a79', 'battle_rule_v1:42db1519409feeb45390c07a693f6f60', '{"_keywords_are_self":true,"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_destroy_target_v1","defender":true,"destination":"graveyard","effect":"creature","etb_remove_effect":"remove_creature","etb_remove_target":"creature","keywords":["defender"],"target_constraints":{"card_types":["creature"],"required_keywords":["defender"]},"trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"DestroyTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class OgreGatecrasher translated into ManaLoom runtime scope xmage_creature_etb_destroy_target_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('stingerfling spider', 'Stingerfling Spider', '2bd99d3e075e935e742104ca6e55dddd', 'battle_rule_v1:0dd5fc990d260f811c5aac9dc86150c7', '{"_keywords_are_self":true,"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_destroy_target_v1","destination":"graveyard","effect":"creature","etb_remove_effect":"remove_creature","etb_remove_target":"creature","keywords":["reach"],"reach":true,"target_constraints":{"card_types":["creature"],"required_keywords":["flying"]},"trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"DestroyTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class StingerflingSpider translated into ManaLoom runtime scope xmage_creature_etb_destroy_target_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
