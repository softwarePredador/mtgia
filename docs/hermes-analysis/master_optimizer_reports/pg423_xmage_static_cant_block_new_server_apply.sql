BEGIN;

CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit;

CREATE TABLE IF NOT EXISTS manaloom_deploy_audit.pg423_xmage_static_cant_block_new_server_20260704_190640 AS
SELECT *
FROM public.card_battle_rules
WHERE normalized_name IN ('ashenmoor gouger', 'craven giant', 'craven knight', 'goblin raider', 'hulking cyclops', 'hulking goblin', 'hulking ogre', 'jungle lion', 'ogre taskmaster', 'scavenging scarab', 'spineless thug', 'yellow scarves troops', 'young wei recruits')
   OR normalized_name LIKE 'ashenmoor gouger // %'
   OR normalized_name LIKE 'craven giant // %'
   OR normalized_name LIKE 'craven knight // %'
   OR normalized_name LIKE 'goblin raider // %'
   OR normalized_name LIKE 'hulking cyclops // %'
   OR normalized_name LIKE 'hulking goblin // %'
   OR normalized_name LIKE 'hulking ogre // %'
   OR normalized_name LIKE 'jungle lion // %'
   OR normalized_name LIKE 'ogre taskmaster // %'
   OR normalized_name LIKE 'scavenging scarab // %'
   OR normalized_name LIKE 'spineless thug // %'
   OR normalized_name LIKE 'yellow scarves troops // %'
   OR normalized_name LIKE 'young wei recruits // %';

DO $$
DECLARE
  v_missing jsonb;
BEGIN
  WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('ashenmoor gouger', 'Ashenmoor Gouger', '8019586c29deff0d4a5543ee4d4f2726', 'battle_rule_v1:6ee53f88921f55a8efb9dafc5a3b235b', '{"ability_kind":"static","battle_model_scope":"xmage_static_self_cant_block_creature_v1","cannot_block":true,"cant_block":true,"effect":"creature","static_cant_block":true,"static_effect":"self_cant_block","target":"self","target_controller":"self","xmage_ability_class":"CantBlockAbility"}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class AshenmoorGouger translated into ManaLoom runtime scope xmage_static_self_cant_block_creature_v1. This row is package-ready only because the source signature is a narrow creature static self can''t-block restriction with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('craven giant', 'Craven Giant', '8019586c29deff0d4a5543ee4d4f2726', 'battle_rule_v1:6ee53f88921f55a8efb9dafc5a3b235b', '{"ability_kind":"static","battle_model_scope":"xmage_static_self_cant_block_creature_v1","cannot_block":true,"cant_block":true,"effect":"creature","static_cant_block":true,"static_effect":"self_cant_block","target":"self","target_controller":"self","xmage_ability_class":"CantBlockAbility"}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class CravenGiant translated into ManaLoom runtime scope xmage_static_self_cant_block_creature_v1. This row is package-ready only because the source signature is a narrow creature static self can''t-block restriction with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('craven knight', 'Craven Knight', '8019586c29deff0d4a5543ee4d4f2726', 'battle_rule_v1:6ee53f88921f55a8efb9dafc5a3b235b', '{"ability_kind":"static","battle_model_scope":"xmage_static_self_cant_block_creature_v1","cannot_block":true,"cant_block":true,"effect":"creature","static_cant_block":true,"static_effect":"self_cant_block","target":"self","target_controller":"self","xmage_ability_class":"CantBlockAbility"}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class CravenKnight translated into ManaLoom runtime scope xmage_static_self_cant_block_creature_v1. This row is package-ready only because the source signature is a narrow creature static self can''t-block restriction with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('goblin raider', 'Goblin Raider', '8019586c29deff0d4a5543ee4d4f2726', 'battle_rule_v1:6ee53f88921f55a8efb9dafc5a3b235b', '{"ability_kind":"static","battle_model_scope":"xmage_static_self_cant_block_creature_v1","cannot_block":true,"cant_block":true,"effect":"creature","static_cant_block":true,"static_effect":"self_cant_block","target":"self","target_controller":"self","xmage_ability_class":"CantBlockAbility"}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class GoblinRaider translated into ManaLoom runtime scope xmage_static_self_cant_block_creature_v1. This row is package-ready only because the source signature is a narrow creature static self can''t-block restriction with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('hulking cyclops', 'Hulking Cyclops', '8019586c29deff0d4a5543ee4d4f2726', 'battle_rule_v1:6ee53f88921f55a8efb9dafc5a3b235b', '{"ability_kind":"static","battle_model_scope":"xmage_static_self_cant_block_creature_v1","cannot_block":true,"cant_block":true,"effect":"creature","static_cant_block":true,"static_effect":"self_cant_block","target":"self","target_controller":"self","xmage_ability_class":"CantBlockAbility"}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class HulkingCyclops translated into ManaLoom runtime scope xmage_static_self_cant_block_creature_v1. This row is package-ready only because the source signature is a narrow creature static self can''t-block restriction with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('hulking goblin', 'Hulking Goblin', '8019586c29deff0d4a5543ee4d4f2726', 'battle_rule_v1:6ee53f88921f55a8efb9dafc5a3b235b', '{"ability_kind":"static","battle_model_scope":"xmage_static_self_cant_block_creature_v1","cannot_block":true,"cant_block":true,"effect":"creature","static_cant_block":true,"static_effect":"self_cant_block","target":"self","target_controller":"self","xmage_ability_class":"CantBlockAbility"}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class HulkingGoblin translated into ManaLoom runtime scope xmage_static_self_cant_block_creature_v1. This row is package-ready only because the source signature is a narrow creature static self can''t-block restriction with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('hulking ogre', 'Hulking Ogre', '8019586c29deff0d4a5543ee4d4f2726', 'battle_rule_v1:6ee53f88921f55a8efb9dafc5a3b235b', '{"ability_kind":"static","battle_model_scope":"xmage_static_self_cant_block_creature_v1","cannot_block":true,"cant_block":true,"effect":"creature","static_cant_block":true,"static_effect":"self_cant_block","target":"self","target_controller":"self","xmage_ability_class":"CantBlockAbility"}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class HulkingOgre translated into ManaLoom runtime scope xmage_static_self_cant_block_creature_v1. This row is package-ready only because the source signature is a narrow creature static self can''t-block restriction with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('jungle lion', 'Jungle Lion', '8019586c29deff0d4a5543ee4d4f2726', 'battle_rule_v1:6ee53f88921f55a8efb9dafc5a3b235b', '{"ability_kind":"static","battle_model_scope":"xmage_static_self_cant_block_creature_v1","cannot_block":true,"cant_block":true,"effect":"creature","static_cant_block":true,"static_effect":"self_cant_block","target":"self","target_controller":"self","xmage_ability_class":"CantBlockAbility"}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class JungleLion translated into ManaLoom runtime scope xmage_static_self_cant_block_creature_v1. This row is package-ready only because the source signature is a narrow creature static self can''t-block restriction with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('ogre taskmaster', 'Ogre Taskmaster', '8019586c29deff0d4a5543ee4d4f2726', 'battle_rule_v1:6ee53f88921f55a8efb9dafc5a3b235b', '{"ability_kind":"static","battle_model_scope":"xmage_static_self_cant_block_creature_v1","cannot_block":true,"cant_block":true,"effect":"creature","static_cant_block":true,"static_effect":"self_cant_block","target":"self","target_controller":"self","xmage_ability_class":"CantBlockAbility"}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class OgreTaskmaster translated into ManaLoom runtime scope xmage_static_self_cant_block_creature_v1. This row is package-ready only because the source signature is a narrow creature static self can''t-block restriction with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('scavenging scarab', 'Scavenging Scarab', '8019586c29deff0d4a5543ee4d4f2726', 'battle_rule_v1:6ee53f88921f55a8efb9dafc5a3b235b', '{"ability_kind":"static","battle_model_scope":"xmage_static_self_cant_block_creature_v1","cannot_block":true,"cant_block":true,"effect":"creature","static_cant_block":true,"static_effect":"self_cant_block","target":"self","target_controller":"self","xmage_ability_class":"CantBlockAbility"}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ScavengingScarab translated into ManaLoom runtime scope xmage_static_self_cant_block_creature_v1. This row is package-ready only because the source signature is a narrow creature static self can''t-block restriction with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('spineless thug', 'Spineless Thug', '8019586c29deff0d4a5543ee4d4f2726', 'battle_rule_v1:6ee53f88921f55a8efb9dafc5a3b235b', '{"ability_kind":"static","battle_model_scope":"xmage_static_self_cant_block_creature_v1","cannot_block":true,"cant_block":true,"effect":"creature","static_cant_block":true,"static_effect":"self_cant_block","target":"self","target_controller":"self","xmage_ability_class":"CantBlockAbility"}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class SpinelessThug translated into ManaLoom runtime scope xmage_static_self_cant_block_creature_v1. This row is package-ready only because the source signature is a narrow creature static self can''t-block restriction with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('yellow scarves troops', 'Yellow Scarves Troops', '8019586c29deff0d4a5543ee4d4f2726', 'battle_rule_v1:6ee53f88921f55a8efb9dafc5a3b235b', '{"ability_kind":"static","battle_model_scope":"xmage_static_self_cant_block_creature_v1","cannot_block":true,"cant_block":true,"effect":"creature","static_cant_block":true,"static_effect":"self_cant_block","target":"self","target_controller":"self","xmage_ability_class":"CantBlockAbility"}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class YellowScarvesTroops translated into ManaLoom runtime scope xmage_static_self_cant_block_creature_v1. This row is package-ready only because the source signature is a narrow creature static self can''t-block restriction with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('young wei recruits', 'Young Wei Recruits', '8019586c29deff0d4a5543ee4d4f2726', 'battle_rule_v1:6ee53f88921f55a8efb9dafc5a3b235b', '{"ability_kind":"static","battle_model_scope":"xmage_static_self_cant_block_creature_v1","cannot_block":true,"cant_block":true,"effect":"creature","static_cant_block":true,"static_effect":"self_cant_block","target":"self","target_controller":"self","xmage_ability_class":"CantBlockAbility"}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class YoungWeiRecruits translated into ManaLoom runtime scope xmage_static_self_cant_block_creature_v1. This row is package-ready only because the source signature is a narrow creature static self can''t-block restriction with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
    ('ashenmoor gouger', 'Ashenmoor Gouger', '8019586c29deff0d4a5543ee4d4f2726', 'battle_rule_v1:6ee53f88921f55a8efb9dafc5a3b235b', '{"ability_kind":"static","battle_model_scope":"xmage_static_self_cant_block_creature_v1","cannot_block":true,"cant_block":true,"effect":"creature","static_cant_block":true,"static_effect":"self_cant_block","target":"self","target_controller":"self","xmage_ability_class":"CantBlockAbility"}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class AshenmoorGouger translated into ManaLoom runtime scope xmage_static_self_cant_block_creature_v1. This row is package-ready only because the source signature is a narrow creature static self can''t-block restriction with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('craven giant', 'Craven Giant', '8019586c29deff0d4a5543ee4d4f2726', 'battle_rule_v1:6ee53f88921f55a8efb9dafc5a3b235b', '{"ability_kind":"static","battle_model_scope":"xmage_static_self_cant_block_creature_v1","cannot_block":true,"cant_block":true,"effect":"creature","static_cant_block":true,"static_effect":"self_cant_block","target":"self","target_controller":"self","xmage_ability_class":"CantBlockAbility"}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class CravenGiant translated into ManaLoom runtime scope xmage_static_self_cant_block_creature_v1. This row is package-ready only because the source signature is a narrow creature static self can''t-block restriction with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('craven knight', 'Craven Knight', '8019586c29deff0d4a5543ee4d4f2726', 'battle_rule_v1:6ee53f88921f55a8efb9dafc5a3b235b', '{"ability_kind":"static","battle_model_scope":"xmage_static_self_cant_block_creature_v1","cannot_block":true,"cant_block":true,"effect":"creature","static_cant_block":true,"static_effect":"self_cant_block","target":"self","target_controller":"self","xmage_ability_class":"CantBlockAbility"}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class CravenKnight translated into ManaLoom runtime scope xmage_static_self_cant_block_creature_v1. This row is package-ready only because the source signature is a narrow creature static self can''t-block restriction with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('goblin raider', 'Goblin Raider', '8019586c29deff0d4a5543ee4d4f2726', 'battle_rule_v1:6ee53f88921f55a8efb9dafc5a3b235b', '{"ability_kind":"static","battle_model_scope":"xmage_static_self_cant_block_creature_v1","cannot_block":true,"cant_block":true,"effect":"creature","static_cant_block":true,"static_effect":"self_cant_block","target":"self","target_controller":"self","xmage_ability_class":"CantBlockAbility"}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class GoblinRaider translated into ManaLoom runtime scope xmage_static_self_cant_block_creature_v1. This row is package-ready only because the source signature is a narrow creature static self can''t-block restriction with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('hulking cyclops', 'Hulking Cyclops', '8019586c29deff0d4a5543ee4d4f2726', 'battle_rule_v1:6ee53f88921f55a8efb9dafc5a3b235b', '{"ability_kind":"static","battle_model_scope":"xmage_static_self_cant_block_creature_v1","cannot_block":true,"cant_block":true,"effect":"creature","static_cant_block":true,"static_effect":"self_cant_block","target":"self","target_controller":"self","xmage_ability_class":"CantBlockAbility"}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class HulkingCyclops translated into ManaLoom runtime scope xmage_static_self_cant_block_creature_v1. This row is package-ready only because the source signature is a narrow creature static self can''t-block restriction with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('hulking goblin', 'Hulking Goblin', '8019586c29deff0d4a5543ee4d4f2726', 'battle_rule_v1:6ee53f88921f55a8efb9dafc5a3b235b', '{"ability_kind":"static","battle_model_scope":"xmage_static_self_cant_block_creature_v1","cannot_block":true,"cant_block":true,"effect":"creature","static_cant_block":true,"static_effect":"self_cant_block","target":"self","target_controller":"self","xmage_ability_class":"CantBlockAbility"}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class HulkingGoblin translated into ManaLoom runtime scope xmage_static_self_cant_block_creature_v1. This row is package-ready only because the source signature is a narrow creature static self can''t-block restriction with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('hulking ogre', 'Hulking Ogre', '8019586c29deff0d4a5543ee4d4f2726', 'battle_rule_v1:6ee53f88921f55a8efb9dafc5a3b235b', '{"ability_kind":"static","battle_model_scope":"xmage_static_self_cant_block_creature_v1","cannot_block":true,"cant_block":true,"effect":"creature","static_cant_block":true,"static_effect":"self_cant_block","target":"self","target_controller":"self","xmage_ability_class":"CantBlockAbility"}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class HulkingOgre translated into ManaLoom runtime scope xmage_static_self_cant_block_creature_v1. This row is package-ready only because the source signature is a narrow creature static self can''t-block restriction with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('jungle lion', 'Jungle Lion', '8019586c29deff0d4a5543ee4d4f2726', 'battle_rule_v1:6ee53f88921f55a8efb9dafc5a3b235b', '{"ability_kind":"static","battle_model_scope":"xmage_static_self_cant_block_creature_v1","cannot_block":true,"cant_block":true,"effect":"creature","static_cant_block":true,"static_effect":"self_cant_block","target":"self","target_controller":"self","xmage_ability_class":"CantBlockAbility"}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class JungleLion translated into ManaLoom runtime scope xmage_static_self_cant_block_creature_v1. This row is package-ready only because the source signature is a narrow creature static self can''t-block restriction with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('ogre taskmaster', 'Ogre Taskmaster', '8019586c29deff0d4a5543ee4d4f2726', 'battle_rule_v1:6ee53f88921f55a8efb9dafc5a3b235b', '{"ability_kind":"static","battle_model_scope":"xmage_static_self_cant_block_creature_v1","cannot_block":true,"cant_block":true,"effect":"creature","static_cant_block":true,"static_effect":"self_cant_block","target":"self","target_controller":"self","xmage_ability_class":"CantBlockAbility"}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class OgreTaskmaster translated into ManaLoom runtime scope xmage_static_self_cant_block_creature_v1. This row is package-ready only because the source signature is a narrow creature static self can''t-block restriction with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('scavenging scarab', 'Scavenging Scarab', '8019586c29deff0d4a5543ee4d4f2726', 'battle_rule_v1:6ee53f88921f55a8efb9dafc5a3b235b', '{"ability_kind":"static","battle_model_scope":"xmage_static_self_cant_block_creature_v1","cannot_block":true,"cant_block":true,"effect":"creature","static_cant_block":true,"static_effect":"self_cant_block","target":"self","target_controller":"self","xmage_ability_class":"CantBlockAbility"}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ScavengingScarab translated into ManaLoom runtime scope xmage_static_self_cant_block_creature_v1. This row is package-ready only because the source signature is a narrow creature static self can''t-block restriction with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('spineless thug', 'Spineless Thug', '8019586c29deff0d4a5543ee4d4f2726', 'battle_rule_v1:6ee53f88921f55a8efb9dafc5a3b235b', '{"ability_kind":"static","battle_model_scope":"xmage_static_self_cant_block_creature_v1","cannot_block":true,"cant_block":true,"effect":"creature","static_cant_block":true,"static_effect":"self_cant_block","target":"self","target_controller":"self","xmage_ability_class":"CantBlockAbility"}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class SpinelessThug translated into ManaLoom runtime scope xmage_static_self_cant_block_creature_v1. This row is package-ready only because the source signature is a narrow creature static self can''t-block restriction with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('yellow scarves troops', 'Yellow Scarves Troops', '8019586c29deff0d4a5543ee4d4f2726', 'battle_rule_v1:6ee53f88921f55a8efb9dafc5a3b235b', '{"ability_kind":"static","battle_model_scope":"xmage_static_self_cant_block_creature_v1","cannot_block":true,"cant_block":true,"effect":"creature","static_cant_block":true,"static_effect":"self_cant_block","target":"self","target_controller":"self","xmage_ability_class":"CantBlockAbility"}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class YellowScarvesTroops translated into ManaLoom runtime scope xmage_static_self_cant_block_creature_v1. This row is package-ready only because the source signature is a narrow creature static self can''t-block restriction with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('young wei recruits', 'Young Wei Recruits', '8019586c29deff0d4a5543ee4d4f2726', 'battle_rule_v1:6ee53f88921f55a8efb9dafc5a3b235b', '{"ability_kind":"static","battle_model_scope":"xmage_static_self_cant_block_creature_v1","cannot_block":true,"cant_block":true,"effect":"creature","static_cant_block":true,"static_effect":"self_cant_block","target":"self","target_controller":"self","xmage_ability_class":"CantBlockAbility"}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class YoungWeiRecruits translated into ManaLoom runtime scope xmage_static_self_cant_block_creature_v1. This row is package-ready only because the source signature is a narrow creature static self can''t-block restriction with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
    ('ashenmoor gouger', 'Ashenmoor Gouger', '8019586c29deff0d4a5543ee4d4f2726', 'battle_rule_v1:6ee53f88921f55a8efb9dafc5a3b235b', '{"ability_kind":"static","battle_model_scope":"xmage_static_self_cant_block_creature_v1","cannot_block":true,"cant_block":true,"effect":"creature","static_cant_block":true,"static_effect":"self_cant_block","target":"self","target_controller":"self","xmage_ability_class":"CantBlockAbility"}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class AshenmoorGouger translated into ManaLoom runtime scope xmage_static_self_cant_block_creature_v1. This row is package-ready only because the source signature is a narrow creature static self can''t-block restriction with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('craven giant', 'Craven Giant', '8019586c29deff0d4a5543ee4d4f2726', 'battle_rule_v1:6ee53f88921f55a8efb9dafc5a3b235b', '{"ability_kind":"static","battle_model_scope":"xmage_static_self_cant_block_creature_v1","cannot_block":true,"cant_block":true,"effect":"creature","static_cant_block":true,"static_effect":"self_cant_block","target":"self","target_controller":"self","xmage_ability_class":"CantBlockAbility"}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class CravenGiant translated into ManaLoom runtime scope xmage_static_self_cant_block_creature_v1. This row is package-ready only because the source signature is a narrow creature static self can''t-block restriction with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('craven knight', 'Craven Knight', '8019586c29deff0d4a5543ee4d4f2726', 'battle_rule_v1:6ee53f88921f55a8efb9dafc5a3b235b', '{"ability_kind":"static","battle_model_scope":"xmage_static_self_cant_block_creature_v1","cannot_block":true,"cant_block":true,"effect":"creature","static_cant_block":true,"static_effect":"self_cant_block","target":"self","target_controller":"self","xmage_ability_class":"CantBlockAbility"}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class CravenKnight translated into ManaLoom runtime scope xmage_static_self_cant_block_creature_v1. This row is package-ready only because the source signature is a narrow creature static self can''t-block restriction with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('goblin raider', 'Goblin Raider', '8019586c29deff0d4a5543ee4d4f2726', 'battle_rule_v1:6ee53f88921f55a8efb9dafc5a3b235b', '{"ability_kind":"static","battle_model_scope":"xmage_static_self_cant_block_creature_v1","cannot_block":true,"cant_block":true,"effect":"creature","static_cant_block":true,"static_effect":"self_cant_block","target":"self","target_controller":"self","xmage_ability_class":"CantBlockAbility"}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class GoblinRaider translated into ManaLoom runtime scope xmage_static_self_cant_block_creature_v1. This row is package-ready only because the source signature is a narrow creature static self can''t-block restriction with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('hulking cyclops', 'Hulking Cyclops', '8019586c29deff0d4a5543ee4d4f2726', 'battle_rule_v1:6ee53f88921f55a8efb9dafc5a3b235b', '{"ability_kind":"static","battle_model_scope":"xmage_static_self_cant_block_creature_v1","cannot_block":true,"cant_block":true,"effect":"creature","static_cant_block":true,"static_effect":"self_cant_block","target":"self","target_controller":"self","xmage_ability_class":"CantBlockAbility"}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class HulkingCyclops translated into ManaLoom runtime scope xmage_static_self_cant_block_creature_v1. This row is package-ready only because the source signature is a narrow creature static self can''t-block restriction with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('hulking goblin', 'Hulking Goblin', '8019586c29deff0d4a5543ee4d4f2726', 'battle_rule_v1:6ee53f88921f55a8efb9dafc5a3b235b', '{"ability_kind":"static","battle_model_scope":"xmage_static_self_cant_block_creature_v1","cannot_block":true,"cant_block":true,"effect":"creature","static_cant_block":true,"static_effect":"self_cant_block","target":"self","target_controller":"self","xmage_ability_class":"CantBlockAbility"}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class HulkingGoblin translated into ManaLoom runtime scope xmage_static_self_cant_block_creature_v1. This row is package-ready only because the source signature is a narrow creature static self can''t-block restriction with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('hulking ogre', 'Hulking Ogre', '8019586c29deff0d4a5543ee4d4f2726', 'battle_rule_v1:6ee53f88921f55a8efb9dafc5a3b235b', '{"ability_kind":"static","battle_model_scope":"xmage_static_self_cant_block_creature_v1","cannot_block":true,"cant_block":true,"effect":"creature","static_cant_block":true,"static_effect":"self_cant_block","target":"self","target_controller":"self","xmage_ability_class":"CantBlockAbility"}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class HulkingOgre translated into ManaLoom runtime scope xmage_static_self_cant_block_creature_v1. This row is package-ready only because the source signature is a narrow creature static self can''t-block restriction with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('jungle lion', 'Jungle Lion', '8019586c29deff0d4a5543ee4d4f2726', 'battle_rule_v1:6ee53f88921f55a8efb9dafc5a3b235b', '{"ability_kind":"static","battle_model_scope":"xmage_static_self_cant_block_creature_v1","cannot_block":true,"cant_block":true,"effect":"creature","static_cant_block":true,"static_effect":"self_cant_block","target":"self","target_controller":"self","xmage_ability_class":"CantBlockAbility"}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class JungleLion translated into ManaLoom runtime scope xmage_static_self_cant_block_creature_v1. This row is package-ready only because the source signature is a narrow creature static self can''t-block restriction with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('ogre taskmaster', 'Ogre Taskmaster', '8019586c29deff0d4a5543ee4d4f2726', 'battle_rule_v1:6ee53f88921f55a8efb9dafc5a3b235b', '{"ability_kind":"static","battle_model_scope":"xmage_static_self_cant_block_creature_v1","cannot_block":true,"cant_block":true,"effect":"creature","static_cant_block":true,"static_effect":"self_cant_block","target":"self","target_controller":"self","xmage_ability_class":"CantBlockAbility"}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class OgreTaskmaster translated into ManaLoom runtime scope xmage_static_self_cant_block_creature_v1. This row is package-ready only because the source signature is a narrow creature static self can''t-block restriction with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('scavenging scarab', 'Scavenging Scarab', '8019586c29deff0d4a5543ee4d4f2726', 'battle_rule_v1:6ee53f88921f55a8efb9dafc5a3b235b', '{"ability_kind":"static","battle_model_scope":"xmage_static_self_cant_block_creature_v1","cannot_block":true,"cant_block":true,"effect":"creature","static_cant_block":true,"static_effect":"self_cant_block","target":"self","target_controller":"self","xmage_ability_class":"CantBlockAbility"}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ScavengingScarab translated into ManaLoom runtime scope xmage_static_self_cant_block_creature_v1. This row is package-ready only because the source signature is a narrow creature static self can''t-block restriction with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('spineless thug', 'Spineless Thug', '8019586c29deff0d4a5543ee4d4f2726', 'battle_rule_v1:6ee53f88921f55a8efb9dafc5a3b235b', '{"ability_kind":"static","battle_model_scope":"xmage_static_self_cant_block_creature_v1","cannot_block":true,"cant_block":true,"effect":"creature","static_cant_block":true,"static_effect":"self_cant_block","target":"self","target_controller":"self","xmage_ability_class":"CantBlockAbility"}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class SpinelessThug translated into ManaLoom runtime scope xmage_static_self_cant_block_creature_v1. This row is package-ready only because the source signature is a narrow creature static self can''t-block restriction with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('yellow scarves troops', 'Yellow Scarves Troops', '8019586c29deff0d4a5543ee4d4f2726', 'battle_rule_v1:6ee53f88921f55a8efb9dafc5a3b235b', '{"ability_kind":"static","battle_model_scope":"xmage_static_self_cant_block_creature_v1","cannot_block":true,"cant_block":true,"effect":"creature","static_cant_block":true,"static_effect":"self_cant_block","target":"self","target_controller":"self","xmage_ability_class":"CantBlockAbility"}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class YellowScarvesTroops translated into ManaLoom runtime scope xmage_static_self_cant_block_creature_v1. This row is package-ready only because the source signature is a narrow creature static self can''t-block restriction with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('young wei recruits', 'Young Wei Recruits', '8019586c29deff0d4a5543ee4d4f2726', 'battle_rule_v1:6ee53f88921f55a8efb9dafc5a3b235b', '{"ability_kind":"static","battle_model_scope":"xmage_static_self_cant_block_creature_v1","cannot_block":true,"cant_block":true,"effect":"creature","static_cant_block":true,"static_effect":"self_cant_block","target":"self","target_controller":"self","xmage_ability_class":"CantBlockAbility"}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class YoungWeiRecruits translated into ManaLoom runtime scope xmage_static_self_cant_block_creature_v1. This row is package-ready only because the source signature is a narrow creature static self can''t-block restriction with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
