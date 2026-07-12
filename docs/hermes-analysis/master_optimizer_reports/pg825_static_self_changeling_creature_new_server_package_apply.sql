BEGIN;

CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit;

CREATE TABLE IF NOT EXISTS manaloom_deploy_audit.pg825_pg825_static_self_changeling_creat_20260712_102059 AS
SELECT *
FROM public.card_battle_rules
WHERE normalized_name IN ('avian changeling', 'changeling sentinel', 'chitinous graspling', 'game-trail changeling', 'gangly stompling', 'impostor of the sixth pride', 'mischievous sneakling', 'mistform ultimus', 'prideful feastling', 'universal automaton', 'venomous changeling', 'woodland changeling')
   OR normalized_name LIKE 'avian changeling // %'
   OR normalized_name LIKE 'changeling sentinel // %'
   OR normalized_name LIKE 'chitinous graspling // %'
   OR normalized_name LIKE 'game-trail changeling // %'
   OR normalized_name LIKE 'gangly stompling // %'
   OR normalized_name LIKE 'impostor of the sixth pride // %'
   OR normalized_name LIKE 'mischievous sneakling // %'
   OR normalized_name LIKE 'mistform ultimus // %'
   OR normalized_name LIKE 'prideful feastling // %'
   OR normalized_name LIKE 'universal automaton // %'
   OR normalized_name LIKE 'venomous changeling // %'
   OR normalized_name LIKE 'woodland changeling // %';

DO $$
DECLARE
  v_missing jsonb;
BEGIN
  WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('avian changeling', 'Avian Changeling', '68cf84718d6d7a5d009832629b2108ed', 'battle_rule_v1:83542f8d2dae501a3324c53615cf8244', '{"_keywords_are_self":true,"all_creature_types":true,"battle_model_scope":"xmage_static_self_changeling_creature_v1","changeling":true,"creature_type_marker":"all","effect":"creature","flying":true,"keywords":["changeling","flying"],"universal_creature_subtypes":true,"xmage_ability_classes":["ChangelingAbility","FlyingAbility"]}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class AvianChangeling translated into ManaLoom runtime scope xmage_static_self_changeling_creature_v1. This row is package-ready only because the source signature is a narrow creature/card static Changeling all-creature-types identity with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('changeling sentinel', 'Changeling Sentinel', 'b5cbbabd9f4ab5f634662ef31d4b146f', 'battle_rule_v1:f2e9ae6238da485ed448793e165b4779', '{"_keywords_are_self":true,"all_creature_types":true,"battle_model_scope":"xmage_static_self_changeling_creature_v1","changeling":true,"creature_type_marker":"all","effect":"creature","keywords":["changeling","vigilance"],"universal_creature_subtypes":true,"vigilance":true,"xmage_ability_classes":["ChangelingAbility","VigilanceAbility"]}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ChangelingSentinel translated into ManaLoom runtime scope xmage_static_self_changeling_creature_v1. This row is package-ready only because the source signature is a narrow creature/card static Changeling all-creature-types identity with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('chitinous graspling', 'Chitinous Graspling', '2230a4de4d4c3ccca938a5f823b5b7dc', 'battle_rule_v1:660713cce8044d6d0aa51c0bb16531d1', '{"_keywords_are_self":true,"all_creature_types":true,"battle_model_scope":"xmage_static_self_changeling_creature_v1","changeling":true,"creature_type_marker":"all","effect":"creature","keywords":["changeling","reach"],"reach":true,"universal_creature_subtypes":true,"xmage_ability_classes":["ChangelingAbility","ReachAbility"]}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ChitinousGraspling translated into ManaLoom runtime scope xmage_static_self_changeling_creature_v1. This row is package-ready only because the source signature is a narrow creature/card static Changeling all-creature-types identity with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('game-trail changeling', 'Game-Trail Changeling', '701a95b442d40f666617eb8c4f4fa527', 'battle_rule_v1:aafbcbb6d1866de262843aaedd5b285c', '{"_keywords_are_self":true,"all_creature_types":true,"battle_model_scope":"xmage_static_self_changeling_creature_v1","changeling":true,"creature_type_marker":"all","effect":"creature","keywords":["changeling","trample"],"trample":true,"universal_creature_subtypes":true,"xmage_ability_classes":["ChangelingAbility","TrampleAbility"]}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class GameTrailChangeling translated into ManaLoom runtime scope xmage_static_self_changeling_creature_v1. This row is package-ready only because the source signature is a narrow creature/card static Changeling all-creature-types identity with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('gangly stompling', 'Gangly Stompling', '701a95b442d40f666617eb8c4f4fa527', 'battle_rule_v1:aafbcbb6d1866de262843aaedd5b285c', '{"_keywords_are_self":true,"all_creature_types":true,"battle_model_scope":"xmage_static_self_changeling_creature_v1","changeling":true,"creature_type_marker":"all","effect":"creature","keywords":["changeling","trample"],"trample":true,"universal_creature_subtypes":true,"xmage_ability_classes":["ChangelingAbility","TrampleAbility"]}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class GanglyStompling translated into ManaLoom runtime scope xmage_static_self_changeling_creature_v1. This row is package-ready only because the source signature is a narrow creature/card static Changeling all-creature-types identity with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('impostor of the sixth pride', 'Impostor of the Sixth Pride', '82d610c1441606511006fcc92c4f41c0', 'battle_rule_v1:ca0c2ace39cdb1764a769a653b0bb9db', '{"_keywords_are_self":true,"all_creature_types":true,"battle_model_scope":"xmage_static_self_changeling_creature_v1","changeling":true,"creature_type_marker":"all","effect":"creature","keywords":["changeling"],"universal_creature_subtypes":true,"xmage_ability_classes":["ChangelingAbility"]}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ImpostorOfTheSixthPride translated into ManaLoom runtime scope xmage_static_self_changeling_creature_v1. This row is package-ready only because the source signature is a narrow creature/card static Changeling all-creature-types identity with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('mischievous sneakling', 'Mischievous Sneakling', '857fb2d72f55670ab64f14608ef73080', 'battle_rule_v1:3a1bb6d724952e1dc187befea51f2ccf', '{"_keywords_are_self":true,"all_creature_types":true,"battle_model_scope":"xmage_static_self_changeling_creature_v1","changeling":true,"creature_type_marker":"all","effect":"creature","flash":true,"keywords":["changeling","flash"],"universal_creature_subtypes":true,"xmage_ability_classes":["ChangelingAbility","FlashAbility"]}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class MischievousSneakling translated into ManaLoom runtime scope xmage_static_self_changeling_creature_v1. This row is package-ready only because the source signature is a narrow creature/card static Changeling all-creature-types identity with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('mistform ultimus', 'Mistform Ultimus', '60a2a39453aae611561902d11b316135', 'battle_rule_v1:ca0c2ace39cdb1764a769a653b0bb9db', '{"_keywords_are_self":true,"all_creature_types":true,"battle_model_scope":"xmage_static_self_changeling_creature_v1","changeling":true,"creature_type_marker":"all","effect":"creature","keywords":["changeling"],"universal_creature_subtypes":true,"xmage_ability_classes":["ChangelingAbility"]}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class MistformUltimus translated into ManaLoom runtime scope xmage_static_self_changeling_creature_v1. This row is package-ready only because the source signature is a narrow creature/card static Changeling all-creature-types identity with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('prideful feastling', 'Prideful Feastling', '71505afde7f0ea8b73844d02d01b2a5e', 'battle_rule_v1:76c93329a2a18c3003e9739318d46fcb', '{"_keywords_are_self":true,"all_creature_types":true,"battle_model_scope":"xmage_static_self_changeling_creature_v1","changeling":true,"creature_type_marker":"all","effect":"creature","keywords":["changeling","lifelink"],"lifelink":true,"universal_creature_subtypes":true,"xmage_ability_classes":["ChangelingAbility","LifelinkAbility"]}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class PridefulFeastling translated into ManaLoom runtime scope xmage_static_self_changeling_creature_v1. This row is package-ready only because the source signature is a narrow creature/card static Changeling all-creature-types identity with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('universal automaton', 'Universal Automaton', '82d610c1441606511006fcc92c4f41c0', 'battle_rule_v1:ca0c2ace39cdb1764a769a653b0bb9db', '{"_keywords_are_self":true,"all_creature_types":true,"battle_model_scope":"xmage_static_self_changeling_creature_v1","changeling":true,"creature_type_marker":"all","effect":"creature","keywords":["changeling"],"universal_creature_subtypes":true,"xmage_ability_classes":["ChangelingAbility"]}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class UniversalAutomaton translated into ManaLoom runtime scope xmage_static_self_changeling_creature_v1. This row is package-ready only because the source signature is a narrow creature/card static Changeling all-creature-types identity with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('venomous changeling', 'Venomous Changeling', 'ea03d68af92ddcc34ece55868ad5dfb5', 'battle_rule_v1:d7e8802b9d7894c8d31d749a3b6925fe', '{"_keywords_are_self":true,"all_creature_types":true,"battle_model_scope":"xmage_static_self_changeling_creature_v1","changeling":true,"creature_type_marker":"all","deathtouch":true,"effect":"creature","keywords":["changeling","deathtouch"],"universal_creature_subtypes":true,"xmage_ability_classes":["ChangelingAbility","DeathtouchAbility"]}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class VenomousChangeling translated into ManaLoom runtime scope xmage_static_self_changeling_creature_v1. This row is package-ready only because the source signature is a narrow creature/card static Changeling all-creature-types identity with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('woodland changeling', 'Woodland Changeling', '82d610c1441606511006fcc92c4f41c0', 'battle_rule_v1:ca0c2ace39cdb1764a769a653b0bb9db', '{"_keywords_are_self":true,"all_creature_types":true,"battle_model_scope":"xmage_static_self_changeling_creature_v1","changeling":true,"creature_type_marker":"all","effect":"creature","keywords":["changeling"],"universal_creature_subtypes":true,"xmage_ability_classes":["ChangelingAbility"]}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class WoodlandChangeling translated into ManaLoom runtime scope xmage_static_self_changeling_creature_v1. This row is package-ready only because the source signature is a narrow creature/card static Changeling all-creature-types identity with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
    ('avian changeling', 'Avian Changeling', '68cf84718d6d7a5d009832629b2108ed', 'battle_rule_v1:83542f8d2dae501a3324c53615cf8244', '{"_keywords_are_self":true,"all_creature_types":true,"battle_model_scope":"xmage_static_self_changeling_creature_v1","changeling":true,"creature_type_marker":"all","effect":"creature","flying":true,"keywords":["changeling","flying"],"universal_creature_subtypes":true,"xmage_ability_classes":["ChangelingAbility","FlyingAbility"]}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class AvianChangeling translated into ManaLoom runtime scope xmage_static_self_changeling_creature_v1. This row is package-ready only because the source signature is a narrow creature/card static Changeling all-creature-types identity with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('changeling sentinel', 'Changeling Sentinel', 'b5cbbabd9f4ab5f634662ef31d4b146f', 'battle_rule_v1:f2e9ae6238da485ed448793e165b4779', '{"_keywords_are_self":true,"all_creature_types":true,"battle_model_scope":"xmage_static_self_changeling_creature_v1","changeling":true,"creature_type_marker":"all","effect":"creature","keywords":["changeling","vigilance"],"universal_creature_subtypes":true,"vigilance":true,"xmage_ability_classes":["ChangelingAbility","VigilanceAbility"]}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ChangelingSentinel translated into ManaLoom runtime scope xmage_static_self_changeling_creature_v1. This row is package-ready only because the source signature is a narrow creature/card static Changeling all-creature-types identity with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('chitinous graspling', 'Chitinous Graspling', '2230a4de4d4c3ccca938a5f823b5b7dc', 'battle_rule_v1:660713cce8044d6d0aa51c0bb16531d1', '{"_keywords_are_self":true,"all_creature_types":true,"battle_model_scope":"xmage_static_self_changeling_creature_v1","changeling":true,"creature_type_marker":"all","effect":"creature","keywords":["changeling","reach"],"reach":true,"universal_creature_subtypes":true,"xmage_ability_classes":["ChangelingAbility","ReachAbility"]}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ChitinousGraspling translated into ManaLoom runtime scope xmage_static_self_changeling_creature_v1. This row is package-ready only because the source signature is a narrow creature/card static Changeling all-creature-types identity with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('game-trail changeling', 'Game-Trail Changeling', '701a95b442d40f666617eb8c4f4fa527', 'battle_rule_v1:aafbcbb6d1866de262843aaedd5b285c', '{"_keywords_are_self":true,"all_creature_types":true,"battle_model_scope":"xmage_static_self_changeling_creature_v1","changeling":true,"creature_type_marker":"all","effect":"creature","keywords":["changeling","trample"],"trample":true,"universal_creature_subtypes":true,"xmage_ability_classes":["ChangelingAbility","TrampleAbility"]}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class GameTrailChangeling translated into ManaLoom runtime scope xmage_static_self_changeling_creature_v1. This row is package-ready only because the source signature is a narrow creature/card static Changeling all-creature-types identity with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('gangly stompling', 'Gangly Stompling', '701a95b442d40f666617eb8c4f4fa527', 'battle_rule_v1:aafbcbb6d1866de262843aaedd5b285c', '{"_keywords_are_self":true,"all_creature_types":true,"battle_model_scope":"xmage_static_self_changeling_creature_v1","changeling":true,"creature_type_marker":"all","effect":"creature","keywords":["changeling","trample"],"trample":true,"universal_creature_subtypes":true,"xmage_ability_classes":["ChangelingAbility","TrampleAbility"]}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class GanglyStompling translated into ManaLoom runtime scope xmage_static_self_changeling_creature_v1. This row is package-ready only because the source signature is a narrow creature/card static Changeling all-creature-types identity with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('impostor of the sixth pride', 'Impostor of the Sixth Pride', '82d610c1441606511006fcc92c4f41c0', 'battle_rule_v1:ca0c2ace39cdb1764a769a653b0bb9db', '{"_keywords_are_self":true,"all_creature_types":true,"battle_model_scope":"xmage_static_self_changeling_creature_v1","changeling":true,"creature_type_marker":"all","effect":"creature","keywords":["changeling"],"universal_creature_subtypes":true,"xmage_ability_classes":["ChangelingAbility"]}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ImpostorOfTheSixthPride translated into ManaLoom runtime scope xmage_static_self_changeling_creature_v1. This row is package-ready only because the source signature is a narrow creature/card static Changeling all-creature-types identity with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('mischievous sneakling', 'Mischievous Sneakling', '857fb2d72f55670ab64f14608ef73080', 'battle_rule_v1:3a1bb6d724952e1dc187befea51f2ccf', '{"_keywords_are_self":true,"all_creature_types":true,"battle_model_scope":"xmage_static_self_changeling_creature_v1","changeling":true,"creature_type_marker":"all","effect":"creature","flash":true,"keywords":["changeling","flash"],"universal_creature_subtypes":true,"xmage_ability_classes":["ChangelingAbility","FlashAbility"]}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class MischievousSneakling translated into ManaLoom runtime scope xmage_static_self_changeling_creature_v1. This row is package-ready only because the source signature is a narrow creature/card static Changeling all-creature-types identity with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('mistform ultimus', 'Mistform Ultimus', '60a2a39453aae611561902d11b316135', 'battle_rule_v1:ca0c2ace39cdb1764a769a653b0bb9db', '{"_keywords_are_self":true,"all_creature_types":true,"battle_model_scope":"xmage_static_self_changeling_creature_v1","changeling":true,"creature_type_marker":"all","effect":"creature","keywords":["changeling"],"universal_creature_subtypes":true,"xmage_ability_classes":["ChangelingAbility"]}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class MistformUltimus translated into ManaLoom runtime scope xmage_static_self_changeling_creature_v1. This row is package-ready only because the source signature is a narrow creature/card static Changeling all-creature-types identity with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('prideful feastling', 'Prideful Feastling', '71505afde7f0ea8b73844d02d01b2a5e', 'battle_rule_v1:76c93329a2a18c3003e9739318d46fcb', '{"_keywords_are_self":true,"all_creature_types":true,"battle_model_scope":"xmage_static_self_changeling_creature_v1","changeling":true,"creature_type_marker":"all","effect":"creature","keywords":["changeling","lifelink"],"lifelink":true,"universal_creature_subtypes":true,"xmage_ability_classes":["ChangelingAbility","LifelinkAbility"]}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class PridefulFeastling translated into ManaLoom runtime scope xmage_static_self_changeling_creature_v1. This row is package-ready only because the source signature is a narrow creature/card static Changeling all-creature-types identity with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('universal automaton', 'Universal Automaton', '82d610c1441606511006fcc92c4f41c0', 'battle_rule_v1:ca0c2ace39cdb1764a769a653b0bb9db', '{"_keywords_are_self":true,"all_creature_types":true,"battle_model_scope":"xmage_static_self_changeling_creature_v1","changeling":true,"creature_type_marker":"all","effect":"creature","keywords":["changeling"],"universal_creature_subtypes":true,"xmage_ability_classes":["ChangelingAbility"]}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class UniversalAutomaton translated into ManaLoom runtime scope xmage_static_self_changeling_creature_v1. This row is package-ready only because the source signature is a narrow creature/card static Changeling all-creature-types identity with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('venomous changeling', 'Venomous Changeling', 'ea03d68af92ddcc34ece55868ad5dfb5', 'battle_rule_v1:d7e8802b9d7894c8d31d749a3b6925fe', '{"_keywords_are_self":true,"all_creature_types":true,"battle_model_scope":"xmage_static_self_changeling_creature_v1","changeling":true,"creature_type_marker":"all","deathtouch":true,"effect":"creature","keywords":["changeling","deathtouch"],"universal_creature_subtypes":true,"xmage_ability_classes":["ChangelingAbility","DeathtouchAbility"]}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class VenomousChangeling translated into ManaLoom runtime scope xmage_static_self_changeling_creature_v1. This row is package-ready only because the source signature is a narrow creature/card static Changeling all-creature-types identity with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('woodland changeling', 'Woodland Changeling', '82d610c1441606511006fcc92c4f41c0', 'battle_rule_v1:ca0c2ace39cdb1764a769a653b0bb9db', '{"_keywords_are_self":true,"all_creature_types":true,"battle_model_scope":"xmage_static_self_changeling_creature_v1","changeling":true,"creature_type_marker":"all","effect":"creature","keywords":["changeling"],"universal_creature_subtypes":true,"xmage_ability_classes":["ChangelingAbility"]}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class WoodlandChangeling translated into ManaLoom runtime scope xmage_static_self_changeling_creature_v1. This row is package-ready only because the source signature is a narrow creature/card static Changeling all-creature-types identity with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
    ('avian changeling', 'Avian Changeling', '68cf84718d6d7a5d009832629b2108ed', 'battle_rule_v1:83542f8d2dae501a3324c53615cf8244', '{"_keywords_are_self":true,"all_creature_types":true,"battle_model_scope":"xmage_static_self_changeling_creature_v1","changeling":true,"creature_type_marker":"all","effect":"creature","flying":true,"keywords":["changeling","flying"],"universal_creature_subtypes":true,"xmage_ability_classes":["ChangelingAbility","FlyingAbility"]}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class AvianChangeling translated into ManaLoom runtime scope xmage_static_self_changeling_creature_v1. This row is package-ready only because the source signature is a narrow creature/card static Changeling all-creature-types identity with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('changeling sentinel', 'Changeling Sentinel', 'b5cbbabd9f4ab5f634662ef31d4b146f', 'battle_rule_v1:f2e9ae6238da485ed448793e165b4779', '{"_keywords_are_self":true,"all_creature_types":true,"battle_model_scope":"xmage_static_self_changeling_creature_v1","changeling":true,"creature_type_marker":"all","effect":"creature","keywords":["changeling","vigilance"],"universal_creature_subtypes":true,"vigilance":true,"xmage_ability_classes":["ChangelingAbility","VigilanceAbility"]}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ChangelingSentinel translated into ManaLoom runtime scope xmage_static_self_changeling_creature_v1. This row is package-ready only because the source signature is a narrow creature/card static Changeling all-creature-types identity with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('chitinous graspling', 'Chitinous Graspling', '2230a4de4d4c3ccca938a5f823b5b7dc', 'battle_rule_v1:660713cce8044d6d0aa51c0bb16531d1', '{"_keywords_are_self":true,"all_creature_types":true,"battle_model_scope":"xmage_static_self_changeling_creature_v1","changeling":true,"creature_type_marker":"all","effect":"creature","keywords":["changeling","reach"],"reach":true,"universal_creature_subtypes":true,"xmage_ability_classes":["ChangelingAbility","ReachAbility"]}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ChitinousGraspling translated into ManaLoom runtime scope xmage_static_self_changeling_creature_v1. This row is package-ready only because the source signature is a narrow creature/card static Changeling all-creature-types identity with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('game-trail changeling', 'Game-Trail Changeling', '701a95b442d40f666617eb8c4f4fa527', 'battle_rule_v1:aafbcbb6d1866de262843aaedd5b285c', '{"_keywords_are_self":true,"all_creature_types":true,"battle_model_scope":"xmage_static_self_changeling_creature_v1","changeling":true,"creature_type_marker":"all","effect":"creature","keywords":["changeling","trample"],"trample":true,"universal_creature_subtypes":true,"xmage_ability_classes":["ChangelingAbility","TrampleAbility"]}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class GameTrailChangeling translated into ManaLoom runtime scope xmage_static_self_changeling_creature_v1. This row is package-ready only because the source signature is a narrow creature/card static Changeling all-creature-types identity with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('gangly stompling', 'Gangly Stompling', '701a95b442d40f666617eb8c4f4fa527', 'battle_rule_v1:aafbcbb6d1866de262843aaedd5b285c', '{"_keywords_are_self":true,"all_creature_types":true,"battle_model_scope":"xmage_static_self_changeling_creature_v1","changeling":true,"creature_type_marker":"all","effect":"creature","keywords":["changeling","trample"],"trample":true,"universal_creature_subtypes":true,"xmage_ability_classes":["ChangelingAbility","TrampleAbility"]}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class GanglyStompling translated into ManaLoom runtime scope xmage_static_self_changeling_creature_v1. This row is package-ready only because the source signature is a narrow creature/card static Changeling all-creature-types identity with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('impostor of the sixth pride', 'Impostor of the Sixth Pride', '82d610c1441606511006fcc92c4f41c0', 'battle_rule_v1:ca0c2ace39cdb1764a769a653b0bb9db', '{"_keywords_are_self":true,"all_creature_types":true,"battle_model_scope":"xmage_static_self_changeling_creature_v1","changeling":true,"creature_type_marker":"all","effect":"creature","keywords":["changeling"],"universal_creature_subtypes":true,"xmage_ability_classes":["ChangelingAbility"]}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ImpostorOfTheSixthPride translated into ManaLoom runtime scope xmage_static_self_changeling_creature_v1. This row is package-ready only because the source signature is a narrow creature/card static Changeling all-creature-types identity with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('mischievous sneakling', 'Mischievous Sneakling', '857fb2d72f55670ab64f14608ef73080', 'battle_rule_v1:3a1bb6d724952e1dc187befea51f2ccf', '{"_keywords_are_self":true,"all_creature_types":true,"battle_model_scope":"xmage_static_self_changeling_creature_v1","changeling":true,"creature_type_marker":"all","effect":"creature","flash":true,"keywords":["changeling","flash"],"universal_creature_subtypes":true,"xmage_ability_classes":["ChangelingAbility","FlashAbility"]}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class MischievousSneakling translated into ManaLoom runtime scope xmage_static_self_changeling_creature_v1. This row is package-ready only because the source signature is a narrow creature/card static Changeling all-creature-types identity with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('mistform ultimus', 'Mistform Ultimus', '60a2a39453aae611561902d11b316135', 'battle_rule_v1:ca0c2ace39cdb1764a769a653b0bb9db', '{"_keywords_are_self":true,"all_creature_types":true,"battle_model_scope":"xmage_static_self_changeling_creature_v1","changeling":true,"creature_type_marker":"all","effect":"creature","keywords":["changeling"],"universal_creature_subtypes":true,"xmage_ability_classes":["ChangelingAbility"]}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class MistformUltimus translated into ManaLoom runtime scope xmage_static_self_changeling_creature_v1. This row is package-ready only because the source signature is a narrow creature/card static Changeling all-creature-types identity with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('prideful feastling', 'Prideful Feastling', '71505afde7f0ea8b73844d02d01b2a5e', 'battle_rule_v1:76c93329a2a18c3003e9739318d46fcb', '{"_keywords_are_self":true,"all_creature_types":true,"battle_model_scope":"xmage_static_self_changeling_creature_v1","changeling":true,"creature_type_marker":"all","effect":"creature","keywords":["changeling","lifelink"],"lifelink":true,"universal_creature_subtypes":true,"xmage_ability_classes":["ChangelingAbility","LifelinkAbility"]}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class PridefulFeastling translated into ManaLoom runtime scope xmage_static_self_changeling_creature_v1. This row is package-ready only because the source signature is a narrow creature/card static Changeling all-creature-types identity with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('universal automaton', 'Universal Automaton', '82d610c1441606511006fcc92c4f41c0', 'battle_rule_v1:ca0c2ace39cdb1764a769a653b0bb9db', '{"_keywords_are_self":true,"all_creature_types":true,"battle_model_scope":"xmage_static_self_changeling_creature_v1","changeling":true,"creature_type_marker":"all","effect":"creature","keywords":["changeling"],"universal_creature_subtypes":true,"xmage_ability_classes":["ChangelingAbility"]}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class UniversalAutomaton translated into ManaLoom runtime scope xmage_static_self_changeling_creature_v1. This row is package-ready only because the source signature is a narrow creature/card static Changeling all-creature-types identity with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('venomous changeling', 'Venomous Changeling', 'ea03d68af92ddcc34ece55868ad5dfb5', 'battle_rule_v1:d7e8802b9d7894c8d31d749a3b6925fe', '{"_keywords_are_self":true,"all_creature_types":true,"battle_model_scope":"xmage_static_self_changeling_creature_v1","changeling":true,"creature_type_marker":"all","deathtouch":true,"effect":"creature","keywords":["changeling","deathtouch"],"universal_creature_subtypes":true,"xmage_ability_classes":["ChangelingAbility","DeathtouchAbility"]}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class VenomousChangeling translated into ManaLoom runtime scope xmage_static_self_changeling_creature_v1. This row is package-ready only because the source signature is a narrow creature/card static Changeling all-creature-types identity with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('woodland changeling', 'Woodland Changeling', '82d610c1441606511006fcc92c4f41c0', 'battle_rule_v1:ca0c2ace39cdb1764a769a653b0bb9db', '{"_keywords_are_self":true,"all_creature_types":true,"battle_model_scope":"xmage_static_self_changeling_creature_v1","changeling":true,"creature_type_marker":"all","effect":"creature","keywords":["changeling"],"universal_creature_subtypes":true,"xmage_ability_classes":["ChangelingAbility"]}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class WoodlandChangeling translated into ManaLoom runtime scope xmage_static_self_changeling_creature_v1. This row is package-ready only because the source signature is a narrow creature/card static Changeling all-creature-types identity with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
