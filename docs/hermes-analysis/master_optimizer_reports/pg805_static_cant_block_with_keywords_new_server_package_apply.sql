BEGIN;

CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit;

CREATE TABLE IF NOT EXISTS manaloom_deploy_audit.pg805_static_cant_block_with_keywords_ne_20260712_040435 AS
SELECT *
FROM public.card_battle_rules
WHERE normalized_name IN ('aesthir glider', 'daggerclaw imp', 'goblin glider', 'iron-barb hellion', 'kyren glider', 'nezumi cutthroat', 'nightshade stinger', 'vampire interloper')
   OR normalized_name LIKE 'aesthir glider // %'
   OR normalized_name LIKE 'daggerclaw imp // %'
   OR normalized_name LIKE 'goblin glider // %'
   OR normalized_name LIKE 'iron-barb hellion // %'
   OR normalized_name LIKE 'kyren glider // %'
   OR normalized_name LIKE 'nezumi cutthroat // %'
   OR normalized_name LIKE 'nightshade stinger // %'
   OR normalized_name LIKE 'vampire interloper // %';

DO $$
DECLARE
  v_missing jsonb;
BEGIN
  WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('aesthir glider', 'Aesthir Glider', '4893eefbd4bc76a7b9d1e891a37d70be', 'battle_rule_v1:8b80cbc5dee879a560224daf9172f1d0', '{"_keywords_are_self":true,"ability_kind":"static","battle_model_scope":"xmage_static_self_cant_block_creature_v1","cannot_block":true,"cant_block":true,"effect":"creature","flying":true,"keywords":["flying"],"static_cant_block":true,"static_effect":"self_cant_block","target":"self","target_controller":"self","xmage_ability_class":"CantBlockAbility","xmage_ability_classes":["CantBlockAbility","FlyingAbility"]}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class AesthirGlider translated into ManaLoom runtime scope xmage_static_self_cant_block_creature_v1. This row is package-ready only because the source signature is a narrow creature static self can''t-block restriction with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('daggerclaw imp', 'Daggerclaw Imp', '4893eefbd4bc76a7b9d1e891a37d70be', 'battle_rule_v1:8b80cbc5dee879a560224daf9172f1d0', '{"_keywords_are_self":true,"ability_kind":"static","battle_model_scope":"xmage_static_self_cant_block_creature_v1","cannot_block":true,"cant_block":true,"effect":"creature","flying":true,"keywords":["flying"],"static_cant_block":true,"static_effect":"self_cant_block","target":"self","target_controller":"self","xmage_ability_class":"CantBlockAbility","xmage_ability_classes":["CantBlockAbility","FlyingAbility"]}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class DaggerclawImp translated into ManaLoom runtime scope xmage_static_self_cant_block_creature_v1. This row is package-ready only because the source signature is a narrow creature static self can''t-block restriction with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('goblin glider', 'Goblin Glider', '4893eefbd4bc76a7b9d1e891a37d70be', 'battle_rule_v1:8b80cbc5dee879a560224daf9172f1d0', '{"_keywords_are_self":true,"ability_kind":"static","battle_model_scope":"xmage_static_self_cant_block_creature_v1","cannot_block":true,"cant_block":true,"effect":"creature","flying":true,"keywords":["flying"],"static_cant_block":true,"static_effect":"self_cant_block","target":"self","target_controller":"self","xmage_ability_class":"CantBlockAbility","xmage_ability_classes":["CantBlockAbility","FlyingAbility"]}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class GoblinGlider translated into ManaLoom runtime scope xmage_static_self_cant_block_creature_v1. This row is package-ready only because the source signature is a narrow creature static self can''t-block restriction with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('iron-barb hellion', 'Iron-Barb Hellion', '2befb1427bdc8b017a18f5f51eeaaa71', 'battle_rule_v1:e38b28bd3c0984bc6c252aa8b1594fa7', '{"_keywords_are_self":true,"ability_kind":"static","battle_model_scope":"xmage_static_self_cant_block_creature_v1","cannot_block":true,"cant_block":true,"effect":"creature","haste":true,"keywords":["haste"],"static_cant_block":true,"static_effect":"self_cant_block","target":"self","target_controller":"self","xmage_ability_class":"CantBlockAbility","xmage_ability_classes":["CantBlockAbility","HasteAbility"]}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class IronBarbHellion translated into ManaLoom runtime scope xmage_static_self_cant_block_creature_v1. This row is package-ready only because the source signature is a narrow creature static self can''t-block restriction with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('kyren glider', 'Kyren Glider', '4893eefbd4bc76a7b9d1e891a37d70be', 'battle_rule_v1:8b80cbc5dee879a560224daf9172f1d0', '{"_keywords_are_self":true,"ability_kind":"static","battle_model_scope":"xmage_static_self_cant_block_creature_v1","cannot_block":true,"cant_block":true,"effect":"creature","flying":true,"keywords":["flying"],"static_cant_block":true,"static_effect":"self_cant_block","target":"self","target_controller":"self","xmage_ability_class":"CantBlockAbility","xmage_ability_classes":["CantBlockAbility","FlyingAbility"]}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class KyrenGlider translated into ManaLoom runtime scope xmage_static_self_cant_block_creature_v1. This row is package-ready only because the source signature is a narrow creature static self can''t-block restriction with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('nezumi cutthroat', 'Nezumi Cutthroat', '50f19cc3f7bb41d61e0eb0b7c2838df9', 'battle_rule_v1:c7b91b48e780f212a286c4011ac31b5b', '{"_keywords_are_self":true,"ability_kind":"static","battle_model_scope":"xmage_static_self_cant_block_creature_v1","cannot_block":true,"cant_block":true,"effect":"creature","fear":true,"keywords":["fear"],"static_cant_block":true,"static_effect":"self_cant_block","target":"self","target_controller":"self","xmage_ability_class":"CantBlockAbility","xmage_ability_classes":["CantBlockAbility","FearAbility"]}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class NezumiCutthroat translated into ManaLoom runtime scope xmage_static_self_cant_block_creature_v1. This row is package-ready only because the source signature is a narrow creature static self can''t-block restriction with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('nightshade stinger', 'Nightshade Stinger', '4893eefbd4bc76a7b9d1e891a37d70be', 'battle_rule_v1:8b80cbc5dee879a560224daf9172f1d0', '{"_keywords_are_self":true,"ability_kind":"static","battle_model_scope":"xmage_static_self_cant_block_creature_v1","cannot_block":true,"cant_block":true,"effect":"creature","flying":true,"keywords":["flying"],"static_cant_block":true,"static_effect":"self_cant_block","target":"self","target_controller":"self","xmage_ability_class":"CantBlockAbility","xmage_ability_classes":["CantBlockAbility","FlyingAbility"]}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class NightshadeStinger translated into ManaLoom runtime scope xmage_static_self_cant_block_creature_v1. This row is package-ready only because the source signature is a narrow creature static self can''t-block restriction with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('vampire interloper', 'Vampire Interloper', '4893eefbd4bc76a7b9d1e891a37d70be', 'battle_rule_v1:8b80cbc5dee879a560224daf9172f1d0', '{"_keywords_are_self":true,"ability_kind":"static","battle_model_scope":"xmage_static_self_cant_block_creature_v1","cannot_block":true,"cant_block":true,"effect":"creature","flying":true,"keywords":["flying"],"static_cant_block":true,"static_effect":"self_cant_block","target":"self","target_controller":"self","xmage_ability_class":"CantBlockAbility","xmage_ability_classes":["CantBlockAbility","FlyingAbility"]}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class VampireInterloper translated into ManaLoom runtime scope xmage_static_self_cant_block_creature_v1. This row is package-ready only because the source signature is a narrow creature static self can''t-block restriction with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
    ('aesthir glider', 'Aesthir Glider', '4893eefbd4bc76a7b9d1e891a37d70be', 'battle_rule_v1:8b80cbc5dee879a560224daf9172f1d0', '{"_keywords_are_self":true,"ability_kind":"static","battle_model_scope":"xmage_static_self_cant_block_creature_v1","cannot_block":true,"cant_block":true,"effect":"creature","flying":true,"keywords":["flying"],"static_cant_block":true,"static_effect":"self_cant_block","target":"self","target_controller":"self","xmage_ability_class":"CantBlockAbility","xmage_ability_classes":["CantBlockAbility","FlyingAbility"]}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class AesthirGlider translated into ManaLoom runtime scope xmage_static_self_cant_block_creature_v1. This row is package-ready only because the source signature is a narrow creature static self can''t-block restriction with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('daggerclaw imp', 'Daggerclaw Imp', '4893eefbd4bc76a7b9d1e891a37d70be', 'battle_rule_v1:8b80cbc5dee879a560224daf9172f1d0', '{"_keywords_are_self":true,"ability_kind":"static","battle_model_scope":"xmage_static_self_cant_block_creature_v1","cannot_block":true,"cant_block":true,"effect":"creature","flying":true,"keywords":["flying"],"static_cant_block":true,"static_effect":"self_cant_block","target":"self","target_controller":"self","xmage_ability_class":"CantBlockAbility","xmage_ability_classes":["CantBlockAbility","FlyingAbility"]}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class DaggerclawImp translated into ManaLoom runtime scope xmage_static_self_cant_block_creature_v1. This row is package-ready only because the source signature is a narrow creature static self can''t-block restriction with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('goblin glider', 'Goblin Glider', '4893eefbd4bc76a7b9d1e891a37d70be', 'battle_rule_v1:8b80cbc5dee879a560224daf9172f1d0', '{"_keywords_are_self":true,"ability_kind":"static","battle_model_scope":"xmage_static_self_cant_block_creature_v1","cannot_block":true,"cant_block":true,"effect":"creature","flying":true,"keywords":["flying"],"static_cant_block":true,"static_effect":"self_cant_block","target":"self","target_controller":"self","xmage_ability_class":"CantBlockAbility","xmage_ability_classes":["CantBlockAbility","FlyingAbility"]}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class GoblinGlider translated into ManaLoom runtime scope xmage_static_self_cant_block_creature_v1. This row is package-ready only because the source signature is a narrow creature static self can''t-block restriction with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('iron-barb hellion', 'Iron-Barb Hellion', '2befb1427bdc8b017a18f5f51eeaaa71', 'battle_rule_v1:e38b28bd3c0984bc6c252aa8b1594fa7', '{"_keywords_are_self":true,"ability_kind":"static","battle_model_scope":"xmage_static_self_cant_block_creature_v1","cannot_block":true,"cant_block":true,"effect":"creature","haste":true,"keywords":["haste"],"static_cant_block":true,"static_effect":"self_cant_block","target":"self","target_controller":"self","xmage_ability_class":"CantBlockAbility","xmage_ability_classes":["CantBlockAbility","HasteAbility"]}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class IronBarbHellion translated into ManaLoom runtime scope xmage_static_self_cant_block_creature_v1. This row is package-ready only because the source signature is a narrow creature static self can''t-block restriction with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('kyren glider', 'Kyren Glider', '4893eefbd4bc76a7b9d1e891a37d70be', 'battle_rule_v1:8b80cbc5dee879a560224daf9172f1d0', '{"_keywords_are_self":true,"ability_kind":"static","battle_model_scope":"xmage_static_self_cant_block_creature_v1","cannot_block":true,"cant_block":true,"effect":"creature","flying":true,"keywords":["flying"],"static_cant_block":true,"static_effect":"self_cant_block","target":"self","target_controller":"self","xmage_ability_class":"CantBlockAbility","xmage_ability_classes":["CantBlockAbility","FlyingAbility"]}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class KyrenGlider translated into ManaLoom runtime scope xmage_static_self_cant_block_creature_v1. This row is package-ready only because the source signature is a narrow creature static self can''t-block restriction with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('nezumi cutthroat', 'Nezumi Cutthroat', '50f19cc3f7bb41d61e0eb0b7c2838df9', 'battle_rule_v1:c7b91b48e780f212a286c4011ac31b5b', '{"_keywords_are_self":true,"ability_kind":"static","battle_model_scope":"xmage_static_self_cant_block_creature_v1","cannot_block":true,"cant_block":true,"effect":"creature","fear":true,"keywords":["fear"],"static_cant_block":true,"static_effect":"self_cant_block","target":"self","target_controller":"self","xmage_ability_class":"CantBlockAbility","xmage_ability_classes":["CantBlockAbility","FearAbility"]}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class NezumiCutthroat translated into ManaLoom runtime scope xmage_static_self_cant_block_creature_v1. This row is package-ready only because the source signature is a narrow creature static self can''t-block restriction with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('nightshade stinger', 'Nightshade Stinger', '4893eefbd4bc76a7b9d1e891a37d70be', 'battle_rule_v1:8b80cbc5dee879a560224daf9172f1d0', '{"_keywords_are_self":true,"ability_kind":"static","battle_model_scope":"xmage_static_self_cant_block_creature_v1","cannot_block":true,"cant_block":true,"effect":"creature","flying":true,"keywords":["flying"],"static_cant_block":true,"static_effect":"self_cant_block","target":"self","target_controller":"self","xmage_ability_class":"CantBlockAbility","xmage_ability_classes":["CantBlockAbility","FlyingAbility"]}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class NightshadeStinger translated into ManaLoom runtime scope xmage_static_self_cant_block_creature_v1. This row is package-ready only because the source signature is a narrow creature static self can''t-block restriction with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('vampire interloper', 'Vampire Interloper', '4893eefbd4bc76a7b9d1e891a37d70be', 'battle_rule_v1:8b80cbc5dee879a560224daf9172f1d0', '{"_keywords_are_self":true,"ability_kind":"static","battle_model_scope":"xmage_static_self_cant_block_creature_v1","cannot_block":true,"cant_block":true,"effect":"creature","flying":true,"keywords":["flying"],"static_cant_block":true,"static_effect":"self_cant_block","target":"self","target_controller":"self","xmage_ability_class":"CantBlockAbility","xmage_ability_classes":["CantBlockAbility","FlyingAbility"]}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class VampireInterloper translated into ManaLoom runtime scope xmage_static_self_cant_block_creature_v1. This row is package-ready only because the source signature is a narrow creature static self can''t-block restriction with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
    ('aesthir glider', 'Aesthir Glider', '4893eefbd4bc76a7b9d1e891a37d70be', 'battle_rule_v1:8b80cbc5dee879a560224daf9172f1d0', '{"_keywords_are_self":true,"ability_kind":"static","battle_model_scope":"xmage_static_self_cant_block_creature_v1","cannot_block":true,"cant_block":true,"effect":"creature","flying":true,"keywords":["flying"],"static_cant_block":true,"static_effect":"self_cant_block","target":"self","target_controller":"self","xmage_ability_class":"CantBlockAbility","xmage_ability_classes":["CantBlockAbility","FlyingAbility"]}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class AesthirGlider translated into ManaLoom runtime scope xmage_static_self_cant_block_creature_v1. This row is package-ready only because the source signature is a narrow creature static self can''t-block restriction with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('daggerclaw imp', 'Daggerclaw Imp', '4893eefbd4bc76a7b9d1e891a37d70be', 'battle_rule_v1:8b80cbc5dee879a560224daf9172f1d0', '{"_keywords_are_self":true,"ability_kind":"static","battle_model_scope":"xmage_static_self_cant_block_creature_v1","cannot_block":true,"cant_block":true,"effect":"creature","flying":true,"keywords":["flying"],"static_cant_block":true,"static_effect":"self_cant_block","target":"self","target_controller":"self","xmage_ability_class":"CantBlockAbility","xmage_ability_classes":["CantBlockAbility","FlyingAbility"]}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class DaggerclawImp translated into ManaLoom runtime scope xmage_static_self_cant_block_creature_v1. This row is package-ready only because the source signature is a narrow creature static self can''t-block restriction with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('goblin glider', 'Goblin Glider', '4893eefbd4bc76a7b9d1e891a37d70be', 'battle_rule_v1:8b80cbc5dee879a560224daf9172f1d0', '{"_keywords_are_self":true,"ability_kind":"static","battle_model_scope":"xmage_static_self_cant_block_creature_v1","cannot_block":true,"cant_block":true,"effect":"creature","flying":true,"keywords":["flying"],"static_cant_block":true,"static_effect":"self_cant_block","target":"self","target_controller":"self","xmage_ability_class":"CantBlockAbility","xmage_ability_classes":["CantBlockAbility","FlyingAbility"]}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class GoblinGlider translated into ManaLoom runtime scope xmage_static_self_cant_block_creature_v1. This row is package-ready only because the source signature is a narrow creature static self can''t-block restriction with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('iron-barb hellion', 'Iron-Barb Hellion', '2befb1427bdc8b017a18f5f51eeaaa71', 'battle_rule_v1:e38b28bd3c0984bc6c252aa8b1594fa7', '{"_keywords_are_self":true,"ability_kind":"static","battle_model_scope":"xmage_static_self_cant_block_creature_v1","cannot_block":true,"cant_block":true,"effect":"creature","haste":true,"keywords":["haste"],"static_cant_block":true,"static_effect":"self_cant_block","target":"self","target_controller":"self","xmage_ability_class":"CantBlockAbility","xmage_ability_classes":["CantBlockAbility","HasteAbility"]}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class IronBarbHellion translated into ManaLoom runtime scope xmage_static_self_cant_block_creature_v1. This row is package-ready only because the source signature is a narrow creature static self can''t-block restriction with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('kyren glider', 'Kyren Glider', '4893eefbd4bc76a7b9d1e891a37d70be', 'battle_rule_v1:8b80cbc5dee879a560224daf9172f1d0', '{"_keywords_are_self":true,"ability_kind":"static","battle_model_scope":"xmage_static_self_cant_block_creature_v1","cannot_block":true,"cant_block":true,"effect":"creature","flying":true,"keywords":["flying"],"static_cant_block":true,"static_effect":"self_cant_block","target":"self","target_controller":"self","xmage_ability_class":"CantBlockAbility","xmage_ability_classes":["CantBlockAbility","FlyingAbility"]}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class KyrenGlider translated into ManaLoom runtime scope xmage_static_self_cant_block_creature_v1. This row is package-ready only because the source signature is a narrow creature static self can''t-block restriction with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('nezumi cutthroat', 'Nezumi Cutthroat', '50f19cc3f7bb41d61e0eb0b7c2838df9', 'battle_rule_v1:c7b91b48e780f212a286c4011ac31b5b', '{"_keywords_are_self":true,"ability_kind":"static","battle_model_scope":"xmage_static_self_cant_block_creature_v1","cannot_block":true,"cant_block":true,"effect":"creature","fear":true,"keywords":["fear"],"static_cant_block":true,"static_effect":"self_cant_block","target":"self","target_controller":"self","xmage_ability_class":"CantBlockAbility","xmage_ability_classes":["CantBlockAbility","FearAbility"]}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class NezumiCutthroat translated into ManaLoom runtime scope xmage_static_self_cant_block_creature_v1. This row is package-ready only because the source signature is a narrow creature static self can''t-block restriction with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('nightshade stinger', 'Nightshade Stinger', '4893eefbd4bc76a7b9d1e891a37d70be', 'battle_rule_v1:8b80cbc5dee879a560224daf9172f1d0', '{"_keywords_are_self":true,"ability_kind":"static","battle_model_scope":"xmage_static_self_cant_block_creature_v1","cannot_block":true,"cant_block":true,"effect":"creature","flying":true,"keywords":["flying"],"static_cant_block":true,"static_effect":"self_cant_block","target":"self","target_controller":"self","xmage_ability_class":"CantBlockAbility","xmage_ability_classes":["CantBlockAbility","FlyingAbility"]}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class NightshadeStinger translated into ManaLoom runtime scope xmage_static_self_cant_block_creature_v1. This row is package-ready only because the source signature is a narrow creature static self can''t-block restriction with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('vampire interloper', 'Vampire Interloper', '4893eefbd4bc76a7b9d1e891a37d70be', 'battle_rule_v1:8b80cbc5dee879a560224daf9172f1d0', '{"_keywords_are_self":true,"ability_kind":"static","battle_model_scope":"xmage_static_self_cant_block_creature_v1","cannot_block":true,"cant_block":true,"effect":"creature","flying":true,"keywords":["flying"],"static_cant_block":true,"static_effect":"self_cant_block","target":"self","target_controller":"self","xmage_ability_class":"CantBlockAbility","xmage_ability_classes":["CantBlockAbility","FlyingAbility"]}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class VampireInterloper translated into ManaLoom runtime scope xmage_static_self_cant_block_creature_v1. This row is package-ready only because the source signature is a narrow creature static self can''t-block restriction with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
