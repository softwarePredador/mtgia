BEGIN;

CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit;

CREATE TABLE IF NOT EXISTS manaloom_deploy_audit.pg419_xmage_static_cant_be_blocked_new_server_20260704_1 AS
SELECT *
FROM public.card_battle_rules
WHERE normalized_name IN ('covert operative', 'jhessian infiltrator', 'latch seeker', 'metathran soldier', 'mist-cloaked herald', 'phantom ninja', 'phantom warrior', 'slither blade', 'talas warrior', 'tidal kraken', 'triton shorestalker')
   OR normalized_name LIKE 'covert operative // %'
   OR normalized_name LIKE 'jhessian infiltrator // %'
   OR normalized_name LIKE 'latch seeker // %'
   OR normalized_name LIKE 'metathran soldier // %'
   OR normalized_name LIKE 'mist-cloaked herald // %'
   OR normalized_name LIKE 'phantom ninja // %'
   OR normalized_name LIKE 'phantom warrior // %'
   OR normalized_name LIKE 'slither blade // %'
   OR normalized_name LIKE 'talas warrior // %'
   OR normalized_name LIKE 'tidal kraken // %'
   OR normalized_name LIKE 'triton shorestalker // %';

DO $$
DECLARE
  v_missing jsonb;
BEGIN
  WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('covert operative', 'Covert Operative', '1d299ad4e79ae8813f9b6d3cfca85754', 'battle_rule_v1:64d421fc72d2c17b726ec9a68c4e0039', '{"ability_kind":"static","battle_model_scope":"xmage_static_self_cant_be_blocked_creature_v1","cannot_be_blocked":true,"cant_be_blocked":true,"effect":"creature","static_effect":"self_cant_be_blocked","target":"self","target_controller":"self","unblockable":true,"xmage_ability_class":"CantBeBlockedSourceAbility"}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class CovertOperative translated into ManaLoom runtime scope xmage_static_self_cant_be_blocked_creature_v1. This row is package-ready only because the source signature is a narrow creature static self can''t-be-blocked evasion with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('jhessian infiltrator', 'Jhessian Infiltrator', '1d299ad4e79ae8813f9b6d3cfca85754', 'battle_rule_v1:64d421fc72d2c17b726ec9a68c4e0039', '{"ability_kind":"static","battle_model_scope":"xmage_static_self_cant_be_blocked_creature_v1","cannot_be_blocked":true,"cant_be_blocked":true,"effect":"creature","static_effect":"self_cant_be_blocked","target":"self","target_controller":"self","unblockable":true,"xmage_ability_class":"CantBeBlockedSourceAbility"}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class JhessianInfiltrator translated into ManaLoom runtime scope xmage_static_self_cant_be_blocked_creature_v1. This row is package-ready only because the source signature is a narrow creature static self can''t-be-blocked evasion with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('latch seeker', 'Latch Seeker', '1d299ad4e79ae8813f9b6d3cfca85754', 'battle_rule_v1:64d421fc72d2c17b726ec9a68c4e0039', '{"ability_kind":"static","battle_model_scope":"xmage_static_self_cant_be_blocked_creature_v1","cannot_be_blocked":true,"cant_be_blocked":true,"effect":"creature","static_effect":"self_cant_be_blocked","target":"self","target_controller":"self","unblockable":true,"xmage_ability_class":"CantBeBlockedSourceAbility"}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class LatchSeeker translated into ManaLoom runtime scope xmage_static_self_cant_be_blocked_creature_v1. This row is package-ready only because the source signature is a narrow creature static self can''t-be-blocked evasion with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('metathran soldier', 'Metathran Soldier', '1d299ad4e79ae8813f9b6d3cfca85754', 'battle_rule_v1:64d421fc72d2c17b726ec9a68c4e0039', '{"ability_kind":"static","battle_model_scope":"xmage_static_self_cant_be_blocked_creature_v1","cannot_be_blocked":true,"cant_be_blocked":true,"effect":"creature","static_effect":"self_cant_be_blocked","target":"self","target_controller":"self","unblockable":true,"xmage_ability_class":"CantBeBlockedSourceAbility"}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class MetathranSoldier translated into ManaLoom runtime scope xmage_static_self_cant_be_blocked_creature_v1. This row is package-ready only because the source signature is a narrow creature static self can''t-be-blocked evasion with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('mist-cloaked herald', 'Mist-Cloaked Herald', '1d299ad4e79ae8813f9b6d3cfca85754', 'battle_rule_v1:64d421fc72d2c17b726ec9a68c4e0039', '{"ability_kind":"static","battle_model_scope":"xmage_static_self_cant_be_blocked_creature_v1","cannot_be_blocked":true,"cant_be_blocked":true,"effect":"creature","static_effect":"self_cant_be_blocked","target":"self","target_controller":"self","unblockable":true,"xmage_ability_class":"CantBeBlockedSourceAbility"}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class MistCloakedHerald translated into ManaLoom runtime scope xmage_static_self_cant_be_blocked_creature_v1. This row is package-ready only because the source signature is a narrow creature static self can''t-be-blocked evasion with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('phantom ninja', 'Phantom Ninja', '1d299ad4e79ae8813f9b6d3cfca85754', 'battle_rule_v1:64d421fc72d2c17b726ec9a68c4e0039', '{"ability_kind":"static","battle_model_scope":"xmage_static_self_cant_be_blocked_creature_v1","cannot_be_blocked":true,"cant_be_blocked":true,"effect":"creature","static_effect":"self_cant_be_blocked","target":"self","target_controller":"self","unblockable":true,"xmage_ability_class":"CantBeBlockedSourceAbility"}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class PhantomNinja translated into ManaLoom runtime scope xmage_static_self_cant_be_blocked_creature_v1. This row is package-ready only because the source signature is a narrow creature static self can''t-be-blocked evasion with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('phantom warrior', 'Phantom Warrior', '1d299ad4e79ae8813f9b6d3cfca85754', 'battle_rule_v1:64d421fc72d2c17b726ec9a68c4e0039', '{"ability_kind":"static","battle_model_scope":"xmage_static_self_cant_be_blocked_creature_v1","cannot_be_blocked":true,"cant_be_blocked":true,"effect":"creature","static_effect":"self_cant_be_blocked","target":"self","target_controller":"self","unblockable":true,"xmage_ability_class":"CantBeBlockedSourceAbility"}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class PhantomWarrior translated into ManaLoom runtime scope xmage_static_self_cant_be_blocked_creature_v1. This row is package-ready only because the source signature is a narrow creature static self can''t-be-blocked evasion with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('slither blade', 'Slither Blade', '1d299ad4e79ae8813f9b6d3cfca85754', 'battle_rule_v1:64d421fc72d2c17b726ec9a68c4e0039', '{"ability_kind":"static","battle_model_scope":"xmage_static_self_cant_be_blocked_creature_v1","cannot_be_blocked":true,"cant_be_blocked":true,"effect":"creature","static_effect":"self_cant_be_blocked","target":"self","target_controller":"self","unblockable":true,"xmage_ability_class":"CantBeBlockedSourceAbility"}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class SlitherBlade translated into ManaLoom runtime scope xmage_static_self_cant_be_blocked_creature_v1. This row is package-ready only because the source signature is a narrow creature static self can''t-be-blocked evasion with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('talas warrior', 'Talas Warrior', '1d299ad4e79ae8813f9b6d3cfca85754', 'battle_rule_v1:64d421fc72d2c17b726ec9a68c4e0039', '{"ability_kind":"static","battle_model_scope":"xmage_static_self_cant_be_blocked_creature_v1","cannot_be_blocked":true,"cant_be_blocked":true,"effect":"creature","static_effect":"self_cant_be_blocked","target":"self","target_controller":"self","unblockable":true,"xmage_ability_class":"CantBeBlockedSourceAbility"}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class TalasWarrior translated into ManaLoom runtime scope xmage_static_self_cant_be_blocked_creature_v1. This row is package-ready only because the source signature is a narrow creature static self can''t-be-blocked evasion with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('tidal kraken', 'Tidal Kraken', '1d299ad4e79ae8813f9b6d3cfca85754', 'battle_rule_v1:64d421fc72d2c17b726ec9a68c4e0039', '{"ability_kind":"static","battle_model_scope":"xmage_static_self_cant_be_blocked_creature_v1","cannot_be_blocked":true,"cant_be_blocked":true,"effect":"creature","static_effect":"self_cant_be_blocked","target":"self","target_controller":"self","unblockable":true,"xmage_ability_class":"CantBeBlockedSourceAbility"}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class TidalKraken translated into ManaLoom runtime scope xmage_static_self_cant_be_blocked_creature_v1. This row is package-ready only because the source signature is a narrow creature static self can''t-be-blocked evasion with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('triton shorestalker', 'Triton Shorestalker', '1d299ad4e79ae8813f9b6d3cfca85754', 'battle_rule_v1:64d421fc72d2c17b726ec9a68c4e0039', '{"ability_kind":"static","battle_model_scope":"xmage_static_self_cant_be_blocked_creature_v1","cannot_be_blocked":true,"cant_be_blocked":true,"effect":"creature","static_effect":"self_cant_be_blocked","target":"self","target_controller":"self","unblockable":true,"xmage_ability_class":"CantBeBlockedSourceAbility"}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class TritonShorestalker translated into ManaLoom runtime scope xmage_static_self_cant_be_blocked_creature_v1. This row is package-ready only because the source signature is a narrow creature static self can''t-be-blocked evasion with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
    ('covert operative', 'Covert Operative', '1d299ad4e79ae8813f9b6d3cfca85754', 'battle_rule_v1:64d421fc72d2c17b726ec9a68c4e0039', '{"ability_kind":"static","battle_model_scope":"xmage_static_self_cant_be_blocked_creature_v1","cannot_be_blocked":true,"cant_be_blocked":true,"effect":"creature","static_effect":"self_cant_be_blocked","target":"self","target_controller":"self","unblockable":true,"xmage_ability_class":"CantBeBlockedSourceAbility"}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class CovertOperative translated into ManaLoom runtime scope xmage_static_self_cant_be_blocked_creature_v1. This row is package-ready only because the source signature is a narrow creature static self can''t-be-blocked evasion with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('jhessian infiltrator', 'Jhessian Infiltrator', '1d299ad4e79ae8813f9b6d3cfca85754', 'battle_rule_v1:64d421fc72d2c17b726ec9a68c4e0039', '{"ability_kind":"static","battle_model_scope":"xmage_static_self_cant_be_blocked_creature_v1","cannot_be_blocked":true,"cant_be_blocked":true,"effect":"creature","static_effect":"self_cant_be_blocked","target":"self","target_controller":"self","unblockable":true,"xmage_ability_class":"CantBeBlockedSourceAbility"}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class JhessianInfiltrator translated into ManaLoom runtime scope xmage_static_self_cant_be_blocked_creature_v1. This row is package-ready only because the source signature is a narrow creature static self can''t-be-blocked evasion with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('latch seeker', 'Latch Seeker', '1d299ad4e79ae8813f9b6d3cfca85754', 'battle_rule_v1:64d421fc72d2c17b726ec9a68c4e0039', '{"ability_kind":"static","battle_model_scope":"xmage_static_self_cant_be_blocked_creature_v1","cannot_be_blocked":true,"cant_be_blocked":true,"effect":"creature","static_effect":"self_cant_be_blocked","target":"self","target_controller":"self","unblockable":true,"xmage_ability_class":"CantBeBlockedSourceAbility"}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class LatchSeeker translated into ManaLoom runtime scope xmage_static_self_cant_be_blocked_creature_v1. This row is package-ready only because the source signature is a narrow creature static self can''t-be-blocked evasion with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('metathran soldier', 'Metathran Soldier', '1d299ad4e79ae8813f9b6d3cfca85754', 'battle_rule_v1:64d421fc72d2c17b726ec9a68c4e0039', '{"ability_kind":"static","battle_model_scope":"xmage_static_self_cant_be_blocked_creature_v1","cannot_be_blocked":true,"cant_be_blocked":true,"effect":"creature","static_effect":"self_cant_be_blocked","target":"self","target_controller":"self","unblockable":true,"xmage_ability_class":"CantBeBlockedSourceAbility"}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class MetathranSoldier translated into ManaLoom runtime scope xmage_static_self_cant_be_blocked_creature_v1. This row is package-ready only because the source signature is a narrow creature static self can''t-be-blocked evasion with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('mist-cloaked herald', 'Mist-Cloaked Herald', '1d299ad4e79ae8813f9b6d3cfca85754', 'battle_rule_v1:64d421fc72d2c17b726ec9a68c4e0039', '{"ability_kind":"static","battle_model_scope":"xmage_static_self_cant_be_blocked_creature_v1","cannot_be_blocked":true,"cant_be_blocked":true,"effect":"creature","static_effect":"self_cant_be_blocked","target":"self","target_controller":"self","unblockable":true,"xmage_ability_class":"CantBeBlockedSourceAbility"}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class MistCloakedHerald translated into ManaLoom runtime scope xmage_static_self_cant_be_blocked_creature_v1. This row is package-ready only because the source signature is a narrow creature static self can''t-be-blocked evasion with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('phantom ninja', 'Phantom Ninja', '1d299ad4e79ae8813f9b6d3cfca85754', 'battle_rule_v1:64d421fc72d2c17b726ec9a68c4e0039', '{"ability_kind":"static","battle_model_scope":"xmage_static_self_cant_be_blocked_creature_v1","cannot_be_blocked":true,"cant_be_blocked":true,"effect":"creature","static_effect":"self_cant_be_blocked","target":"self","target_controller":"self","unblockable":true,"xmage_ability_class":"CantBeBlockedSourceAbility"}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class PhantomNinja translated into ManaLoom runtime scope xmage_static_self_cant_be_blocked_creature_v1. This row is package-ready only because the source signature is a narrow creature static self can''t-be-blocked evasion with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('phantom warrior', 'Phantom Warrior', '1d299ad4e79ae8813f9b6d3cfca85754', 'battle_rule_v1:64d421fc72d2c17b726ec9a68c4e0039', '{"ability_kind":"static","battle_model_scope":"xmage_static_self_cant_be_blocked_creature_v1","cannot_be_blocked":true,"cant_be_blocked":true,"effect":"creature","static_effect":"self_cant_be_blocked","target":"self","target_controller":"self","unblockable":true,"xmage_ability_class":"CantBeBlockedSourceAbility"}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class PhantomWarrior translated into ManaLoom runtime scope xmage_static_self_cant_be_blocked_creature_v1. This row is package-ready only because the source signature is a narrow creature static self can''t-be-blocked evasion with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('slither blade', 'Slither Blade', '1d299ad4e79ae8813f9b6d3cfca85754', 'battle_rule_v1:64d421fc72d2c17b726ec9a68c4e0039', '{"ability_kind":"static","battle_model_scope":"xmage_static_self_cant_be_blocked_creature_v1","cannot_be_blocked":true,"cant_be_blocked":true,"effect":"creature","static_effect":"self_cant_be_blocked","target":"self","target_controller":"self","unblockable":true,"xmage_ability_class":"CantBeBlockedSourceAbility"}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class SlitherBlade translated into ManaLoom runtime scope xmage_static_self_cant_be_blocked_creature_v1. This row is package-ready only because the source signature is a narrow creature static self can''t-be-blocked evasion with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('talas warrior', 'Talas Warrior', '1d299ad4e79ae8813f9b6d3cfca85754', 'battle_rule_v1:64d421fc72d2c17b726ec9a68c4e0039', '{"ability_kind":"static","battle_model_scope":"xmage_static_self_cant_be_blocked_creature_v1","cannot_be_blocked":true,"cant_be_blocked":true,"effect":"creature","static_effect":"self_cant_be_blocked","target":"self","target_controller":"self","unblockable":true,"xmage_ability_class":"CantBeBlockedSourceAbility"}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class TalasWarrior translated into ManaLoom runtime scope xmage_static_self_cant_be_blocked_creature_v1. This row is package-ready only because the source signature is a narrow creature static self can''t-be-blocked evasion with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('tidal kraken', 'Tidal Kraken', '1d299ad4e79ae8813f9b6d3cfca85754', 'battle_rule_v1:64d421fc72d2c17b726ec9a68c4e0039', '{"ability_kind":"static","battle_model_scope":"xmage_static_self_cant_be_blocked_creature_v1","cannot_be_blocked":true,"cant_be_blocked":true,"effect":"creature","static_effect":"self_cant_be_blocked","target":"self","target_controller":"self","unblockable":true,"xmage_ability_class":"CantBeBlockedSourceAbility"}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class TidalKraken translated into ManaLoom runtime scope xmage_static_self_cant_be_blocked_creature_v1. This row is package-ready only because the source signature is a narrow creature static self can''t-be-blocked evasion with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('triton shorestalker', 'Triton Shorestalker', '1d299ad4e79ae8813f9b6d3cfca85754', 'battle_rule_v1:64d421fc72d2c17b726ec9a68c4e0039', '{"ability_kind":"static","battle_model_scope":"xmage_static_self_cant_be_blocked_creature_v1","cannot_be_blocked":true,"cant_be_blocked":true,"effect":"creature","static_effect":"self_cant_be_blocked","target":"self","target_controller":"self","unblockable":true,"xmage_ability_class":"CantBeBlockedSourceAbility"}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class TritonShorestalker translated into ManaLoom runtime scope xmage_static_self_cant_be_blocked_creature_v1. This row is package-ready only because the source signature is a narrow creature static self can''t-be-blocked evasion with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
    ('covert operative', 'Covert Operative', '1d299ad4e79ae8813f9b6d3cfca85754', 'battle_rule_v1:64d421fc72d2c17b726ec9a68c4e0039', '{"ability_kind":"static","battle_model_scope":"xmage_static_self_cant_be_blocked_creature_v1","cannot_be_blocked":true,"cant_be_blocked":true,"effect":"creature","static_effect":"self_cant_be_blocked","target":"self","target_controller":"self","unblockable":true,"xmage_ability_class":"CantBeBlockedSourceAbility"}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class CovertOperative translated into ManaLoom runtime scope xmage_static_self_cant_be_blocked_creature_v1. This row is package-ready only because the source signature is a narrow creature static self can''t-be-blocked evasion with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('jhessian infiltrator', 'Jhessian Infiltrator', '1d299ad4e79ae8813f9b6d3cfca85754', 'battle_rule_v1:64d421fc72d2c17b726ec9a68c4e0039', '{"ability_kind":"static","battle_model_scope":"xmage_static_self_cant_be_blocked_creature_v1","cannot_be_blocked":true,"cant_be_blocked":true,"effect":"creature","static_effect":"self_cant_be_blocked","target":"self","target_controller":"self","unblockable":true,"xmage_ability_class":"CantBeBlockedSourceAbility"}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class JhessianInfiltrator translated into ManaLoom runtime scope xmage_static_self_cant_be_blocked_creature_v1. This row is package-ready only because the source signature is a narrow creature static self can''t-be-blocked evasion with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('latch seeker', 'Latch Seeker', '1d299ad4e79ae8813f9b6d3cfca85754', 'battle_rule_v1:64d421fc72d2c17b726ec9a68c4e0039', '{"ability_kind":"static","battle_model_scope":"xmage_static_self_cant_be_blocked_creature_v1","cannot_be_blocked":true,"cant_be_blocked":true,"effect":"creature","static_effect":"self_cant_be_blocked","target":"self","target_controller":"self","unblockable":true,"xmage_ability_class":"CantBeBlockedSourceAbility"}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class LatchSeeker translated into ManaLoom runtime scope xmage_static_self_cant_be_blocked_creature_v1. This row is package-ready only because the source signature is a narrow creature static self can''t-be-blocked evasion with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('metathran soldier', 'Metathran Soldier', '1d299ad4e79ae8813f9b6d3cfca85754', 'battle_rule_v1:64d421fc72d2c17b726ec9a68c4e0039', '{"ability_kind":"static","battle_model_scope":"xmage_static_self_cant_be_blocked_creature_v1","cannot_be_blocked":true,"cant_be_blocked":true,"effect":"creature","static_effect":"self_cant_be_blocked","target":"self","target_controller":"self","unblockable":true,"xmage_ability_class":"CantBeBlockedSourceAbility"}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class MetathranSoldier translated into ManaLoom runtime scope xmage_static_self_cant_be_blocked_creature_v1. This row is package-ready only because the source signature is a narrow creature static self can''t-be-blocked evasion with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('mist-cloaked herald', 'Mist-Cloaked Herald', '1d299ad4e79ae8813f9b6d3cfca85754', 'battle_rule_v1:64d421fc72d2c17b726ec9a68c4e0039', '{"ability_kind":"static","battle_model_scope":"xmage_static_self_cant_be_blocked_creature_v1","cannot_be_blocked":true,"cant_be_blocked":true,"effect":"creature","static_effect":"self_cant_be_blocked","target":"self","target_controller":"self","unblockable":true,"xmage_ability_class":"CantBeBlockedSourceAbility"}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class MistCloakedHerald translated into ManaLoom runtime scope xmage_static_self_cant_be_blocked_creature_v1. This row is package-ready only because the source signature is a narrow creature static self can''t-be-blocked evasion with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('phantom ninja', 'Phantom Ninja', '1d299ad4e79ae8813f9b6d3cfca85754', 'battle_rule_v1:64d421fc72d2c17b726ec9a68c4e0039', '{"ability_kind":"static","battle_model_scope":"xmage_static_self_cant_be_blocked_creature_v1","cannot_be_blocked":true,"cant_be_blocked":true,"effect":"creature","static_effect":"self_cant_be_blocked","target":"self","target_controller":"self","unblockable":true,"xmage_ability_class":"CantBeBlockedSourceAbility"}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class PhantomNinja translated into ManaLoom runtime scope xmage_static_self_cant_be_blocked_creature_v1. This row is package-ready only because the source signature is a narrow creature static self can''t-be-blocked evasion with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('phantom warrior', 'Phantom Warrior', '1d299ad4e79ae8813f9b6d3cfca85754', 'battle_rule_v1:64d421fc72d2c17b726ec9a68c4e0039', '{"ability_kind":"static","battle_model_scope":"xmage_static_self_cant_be_blocked_creature_v1","cannot_be_blocked":true,"cant_be_blocked":true,"effect":"creature","static_effect":"self_cant_be_blocked","target":"self","target_controller":"self","unblockable":true,"xmage_ability_class":"CantBeBlockedSourceAbility"}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class PhantomWarrior translated into ManaLoom runtime scope xmage_static_self_cant_be_blocked_creature_v1. This row is package-ready only because the source signature is a narrow creature static self can''t-be-blocked evasion with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('slither blade', 'Slither Blade', '1d299ad4e79ae8813f9b6d3cfca85754', 'battle_rule_v1:64d421fc72d2c17b726ec9a68c4e0039', '{"ability_kind":"static","battle_model_scope":"xmage_static_self_cant_be_blocked_creature_v1","cannot_be_blocked":true,"cant_be_blocked":true,"effect":"creature","static_effect":"self_cant_be_blocked","target":"self","target_controller":"self","unblockable":true,"xmage_ability_class":"CantBeBlockedSourceAbility"}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class SlitherBlade translated into ManaLoom runtime scope xmage_static_self_cant_be_blocked_creature_v1. This row is package-ready only because the source signature is a narrow creature static self can''t-be-blocked evasion with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('talas warrior', 'Talas Warrior', '1d299ad4e79ae8813f9b6d3cfca85754', 'battle_rule_v1:64d421fc72d2c17b726ec9a68c4e0039', '{"ability_kind":"static","battle_model_scope":"xmage_static_self_cant_be_blocked_creature_v1","cannot_be_blocked":true,"cant_be_blocked":true,"effect":"creature","static_effect":"self_cant_be_blocked","target":"self","target_controller":"self","unblockable":true,"xmage_ability_class":"CantBeBlockedSourceAbility"}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class TalasWarrior translated into ManaLoom runtime scope xmage_static_self_cant_be_blocked_creature_v1. This row is package-ready only because the source signature is a narrow creature static self can''t-be-blocked evasion with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('tidal kraken', 'Tidal Kraken', '1d299ad4e79ae8813f9b6d3cfca85754', 'battle_rule_v1:64d421fc72d2c17b726ec9a68c4e0039', '{"ability_kind":"static","battle_model_scope":"xmage_static_self_cant_be_blocked_creature_v1","cannot_be_blocked":true,"cant_be_blocked":true,"effect":"creature","static_effect":"self_cant_be_blocked","target":"self","target_controller":"self","unblockable":true,"xmage_ability_class":"CantBeBlockedSourceAbility"}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class TidalKraken translated into ManaLoom runtime scope xmage_static_self_cant_be_blocked_creature_v1. This row is package-ready only because the source signature is a narrow creature static self can''t-be-blocked evasion with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('triton shorestalker', 'Triton Shorestalker', '1d299ad4e79ae8813f9b6d3cfca85754', 'battle_rule_v1:64d421fc72d2c17b726ec9a68c4e0039', '{"ability_kind":"static","battle_model_scope":"xmage_static_self_cant_be_blocked_creature_v1","cannot_be_blocked":true,"cant_be_blocked":true,"effect":"creature","static_effect":"self_cant_be_blocked","target":"self","target_controller":"self","unblockable":true,"xmage_ability_class":"CantBeBlockedSourceAbility"}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class TritonShorestalker translated into ManaLoom runtime scope xmage_static_self_cant_be_blocked_creature_v1. This row is package-ready only because the source signature is a narrow creature static self can''t-be-blocked evasion with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
