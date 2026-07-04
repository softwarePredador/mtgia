BEGIN;

CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit;

CREATE TABLE IF NOT EXISTS manaloom_deploy_audit.pg427_xmage_static_protection_card_types_new_server_2026 AS
SELECT *
FROM public.card_battle_rules
WHERE normalized_name IN ('angelic curator', 'azorius first-wing', 'beloved chaplain', 'commander eesha', 'horizon drake', 'nacatl savage', 'needlebug', 'tel-jilad chosen', 'tel-jilad outrider', 'yavimaya scion')
   OR normalized_name LIKE 'angelic curator // %'
   OR normalized_name LIKE 'azorius first-wing // %'
   OR normalized_name LIKE 'beloved chaplain // %'
   OR normalized_name LIKE 'commander eesha // %'
   OR normalized_name LIKE 'horizon drake // %'
   OR normalized_name LIKE 'nacatl savage // %'
   OR normalized_name LIKE 'needlebug // %'
   OR normalized_name LIKE 'tel-jilad chosen // %'
   OR normalized_name LIKE 'tel-jilad outrider // %'
   OR normalized_name LIKE 'yavimaya scion // %';

DO $$
DECLARE
  v_missing jsonb;
BEGIN
  WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('angelic curator', 'Angelic Curator', 'c6da5f0c4b2d68f5ca57f71674898e63', 'battle_rule_v1:b067ac2a5f8fe2f33fc1ea6586c92f68', '{"_keywords_are_self":true,"ability_kind":"static","battle_model_scope":"xmage_static_self_protection_from_card_types_creature_v1","effect":"creature","flying":true,"keywords":["flying"],"protection_from_card_types":["artifact"],"static_effect":"self_protection_from_card_types","target":"self","target_controller":"self","xmage_ability_class":"ProtectionAbility"}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class AngelicCurator translated into ManaLoom runtime scope xmage_static_self_protection_from_card_types_creature_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('azorius first-wing', 'Azorius First-Wing', '0bed20a30ce1893bce2a5f3525a3586d', 'battle_rule_v1:d1459b62eb8c5236cecc0803294e9c0a', '{"_keywords_are_self":true,"ability_kind":"static","battle_model_scope":"xmage_static_self_protection_from_card_types_creature_v1","effect":"creature","flying":true,"keywords":["flying"],"protection_from_card_types":["enchantment"],"static_effect":"self_protection_from_card_types","target":"self","target_controller":"self","xmage_ability_class":"ProtectionAbility"}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class AzoriusFirstWing translated into ManaLoom runtime scope xmage_static_self_protection_from_card_types_creature_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('beloved chaplain', 'Beloved Chaplain', '85465de2f7bb9355e2abee50bf175551', 'battle_rule_v1:219f2afb6ddef7cf8e3f05b9f56145b4', '{"ability_kind":"static","battle_model_scope":"xmage_static_self_protection_from_card_types_creature_v1","effect":"creature","protection_from_card_types":["creature"],"static_effect":"self_protection_from_card_types","target":"self","target_controller":"self","xmage_ability_class":"ProtectionAbility"}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class BelovedChaplain translated into ManaLoom runtime scope xmage_static_self_protection_from_card_types_creature_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('commander eesha', 'Commander Eesha', '8c397f94332b7738a90dffa5e34c1766', 'battle_rule_v1:cb4ddef26b3af5c6fae84cbcc063bcbd', '{"_keywords_are_self":true,"ability_kind":"static","battle_model_scope":"xmage_static_self_protection_from_card_types_creature_v1","effect":"creature","flying":true,"keywords":["flying"],"protection_from_card_types":["creature"],"static_effect":"self_protection_from_card_types","target":"self","target_controller":"self","xmage_ability_class":"ProtectionAbility"}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class CommanderEesha translated into ManaLoom runtime scope xmage_static_self_protection_from_card_types_creature_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('horizon drake', 'Horizon Drake', '483bc74a05388029147248b9fa3327e5', 'battle_rule_v1:8bad75f82fd0185f7d6515eae6a7ee75', '{"_keywords_are_self":true,"ability_kind":"static","battle_model_scope":"xmage_static_self_protection_from_card_types_creature_v1","effect":"creature","flying":true,"keywords":["flying"],"protection_from_card_types":["land"],"static_effect":"self_protection_from_card_types","target":"self","target_controller":"self","xmage_ability_class":"ProtectionAbility"}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class HorizonDrake translated into ManaLoom runtime scope xmage_static_self_protection_from_card_types_creature_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('nacatl savage', 'Nacatl Savage', 'c326b8227109ed7986576e4fc2fd8738', 'battle_rule_v1:64d5ec144e33bf5008c6ec840889e03d', '{"ability_kind":"static","battle_model_scope":"xmage_static_self_protection_from_card_types_creature_v1","effect":"creature","protection_from_card_types":["artifact"],"static_effect":"self_protection_from_card_types","target":"self","target_controller":"self","xmage_ability_class":"ProtectionAbility"}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class NacatlSavage translated into ManaLoom runtime scope xmage_static_self_protection_from_card_types_creature_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('needlebug', 'Needlebug', 'e6aa03762d0c8998b46747f47b554641', 'battle_rule_v1:813777fa7616859ba02a555d1232f605', '{"_keywords_are_self":true,"ability_kind":"static","battle_model_scope":"xmage_static_self_protection_from_card_types_creature_v1","effect":"creature","flash":true,"keywords":["flash"],"protection_from_card_types":["artifact"],"static_effect":"self_protection_from_card_types","target":"self","target_controller":"self","xmage_ability_class":"ProtectionAbility"}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Needlebug translated into ManaLoom runtime scope xmage_static_self_protection_from_card_types_creature_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('tel-jilad chosen', 'Tel-Jilad Chosen', 'c326b8227109ed7986576e4fc2fd8738', 'battle_rule_v1:64d5ec144e33bf5008c6ec840889e03d', '{"ability_kind":"static","battle_model_scope":"xmage_static_self_protection_from_card_types_creature_v1","effect":"creature","protection_from_card_types":["artifact"],"static_effect":"self_protection_from_card_types","target":"self","target_controller":"self","xmage_ability_class":"ProtectionAbility"}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class TelJiladChosen translated into ManaLoom runtime scope xmage_static_self_protection_from_card_types_creature_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('tel-jilad outrider', 'Tel-Jilad Outrider', 'c326b8227109ed7986576e4fc2fd8738', 'battle_rule_v1:64d5ec144e33bf5008c6ec840889e03d', '{"ability_kind":"static","battle_model_scope":"xmage_static_self_protection_from_card_types_creature_v1","effect":"creature","protection_from_card_types":["artifact"],"static_effect":"self_protection_from_card_types","target":"self","target_controller":"self","xmage_ability_class":"ProtectionAbility"}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class TelJiladOutrider translated into ManaLoom runtime scope xmage_static_self_protection_from_card_types_creature_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('yavimaya scion', 'Yavimaya Scion', 'c326b8227109ed7986576e4fc2fd8738', 'battle_rule_v1:64d5ec144e33bf5008c6ec840889e03d', '{"ability_kind":"static","battle_model_scope":"xmage_static_self_protection_from_card_types_creature_v1","effect":"creature","protection_from_card_types":["artifact"],"static_effect":"self_protection_from_card_types","target":"self","target_controller":"self","xmage_ability_class":"ProtectionAbility"}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class YavimayaScion translated into ManaLoom runtime scope xmage_static_self_protection_from_card_types_creature_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
    ('angelic curator', 'Angelic Curator', 'c6da5f0c4b2d68f5ca57f71674898e63', 'battle_rule_v1:b067ac2a5f8fe2f33fc1ea6586c92f68', '{"_keywords_are_self":true,"ability_kind":"static","battle_model_scope":"xmage_static_self_protection_from_card_types_creature_v1","effect":"creature","flying":true,"keywords":["flying"],"protection_from_card_types":["artifact"],"static_effect":"self_protection_from_card_types","target":"self","target_controller":"self","xmage_ability_class":"ProtectionAbility"}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class AngelicCurator translated into ManaLoom runtime scope xmage_static_self_protection_from_card_types_creature_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('azorius first-wing', 'Azorius First-Wing', '0bed20a30ce1893bce2a5f3525a3586d', 'battle_rule_v1:d1459b62eb8c5236cecc0803294e9c0a', '{"_keywords_are_self":true,"ability_kind":"static","battle_model_scope":"xmage_static_self_protection_from_card_types_creature_v1","effect":"creature","flying":true,"keywords":["flying"],"protection_from_card_types":["enchantment"],"static_effect":"self_protection_from_card_types","target":"self","target_controller":"self","xmage_ability_class":"ProtectionAbility"}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class AzoriusFirstWing translated into ManaLoom runtime scope xmage_static_self_protection_from_card_types_creature_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('beloved chaplain', 'Beloved Chaplain', '85465de2f7bb9355e2abee50bf175551', 'battle_rule_v1:219f2afb6ddef7cf8e3f05b9f56145b4', '{"ability_kind":"static","battle_model_scope":"xmage_static_self_protection_from_card_types_creature_v1","effect":"creature","protection_from_card_types":["creature"],"static_effect":"self_protection_from_card_types","target":"self","target_controller":"self","xmage_ability_class":"ProtectionAbility"}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class BelovedChaplain translated into ManaLoom runtime scope xmage_static_self_protection_from_card_types_creature_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('commander eesha', 'Commander Eesha', '8c397f94332b7738a90dffa5e34c1766', 'battle_rule_v1:cb4ddef26b3af5c6fae84cbcc063bcbd', '{"_keywords_are_self":true,"ability_kind":"static","battle_model_scope":"xmage_static_self_protection_from_card_types_creature_v1","effect":"creature","flying":true,"keywords":["flying"],"protection_from_card_types":["creature"],"static_effect":"self_protection_from_card_types","target":"self","target_controller":"self","xmage_ability_class":"ProtectionAbility"}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class CommanderEesha translated into ManaLoom runtime scope xmage_static_self_protection_from_card_types_creature_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('horizon drake', 'Horizon Drake', '483bc74a05388029147248b9fa3327e5', 'battle_rule_v1:8bad75f82fd0185f7d6515eae6a7ee75', '{"_keywords_are_self":true,"ability_kind":"static","battle_model_scope":"xmage_static_self_protection_from_card_types_creature_v1","effect":"creature","flying":true,"keywords":["flying"],"protection_from_card_types":["land"],"static_effect":"self_protection_from_card_types","target":"self","target_controller":"self","xmage_ability_class":"ProtectionAbility"}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class HorizonDrake translated into ManaLoom runtime scope xmage_static_self_protection_from_card_types_creature_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('nacatl savage', 'Nacatl Savage', 'c326b8227109ed7986576e4fc2fd8738', 'battle_rule_v1:64d5ec144e33bf5008c6ec840889e03d', '{"ability_kind":"static","battle_model_scope":"xmage_static_self_protection_from_card_types_creature_v1","effect":"creature","protection_from_card_types":["artifact"],"static_effect":"self_protection_from_card_types","target":"self","target_controller":"self","xmage_ability_class":"ProtectionAbility"}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class NacatlSavage translated into ManaLoom runtime scope xmage_static_self_protection_from_card_types_creature_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('needlebug', 'Needlebug', 'e6aa03762d0c8998b46747f47b554641', 'battle_rule_v1:813777fa7616859ba02a555d1232f605', '{"_keywords_are_self":true,"ability_kind":"static","battle_model_scope":"xmage_static_self_protection_from_card_types_creature_v1","effect":"creature","flash":true,"keywords":["flash"],"protection_from_card_types":["artifact"],"static_effect":"self_protection_from_card_types","target":"self","target_controller":"self","xmage_ability_class":"ProtectionAbility"}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Needlebug translated into ManaLoom runtime scope xmage_static_self_protection_from_card_types_creature_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('tel-jilad chosen', 'Tel-Jilad Chosen', 'c326b8227109ed7986576e4fc2fd8738', 'battle_rule_v1:64d5ec144e33bf5008c6ec840889e03d', '{"ability_kind":"static","battle_model_scope":"xmage_static_self_protection_from_card_types_creature_v1","effect":"creature","protection_from_card_types":["artifact"],"static_effect":"self_protection_from_card_types","target":"self","target_controller":"self","xmage_ability_class":"ProtectionAbility"}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class TelJiladChosen translated into ManaLoom runtime scope xmage_static_self_protection_from_card_types_creature_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('tel-jilad outrider', 'Tel-Jilad Outrider', 'c326b8227109ed7986576e4fc2fd8738', 'battle_rule_v1:64d5ec144e33bf5008c6ec840889e03d', '{"ability_kind":"static","battle_model_scope":"xmage_static_self_protection_from_card_types_creature_v1","effect":"creature","protection_from_card_types":["artifact"],"static_effect":"self_protection_from_card_types","target":"self","target_controller":"self","xmage_ability_class":"ProtectionAbility"}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class TelJiladOutrider translated into ManaLoom runtime scope xmage_static_self_protection_from_card_types_creature_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('yavimaya scion', 'Yavimaya Scion', 'c326b8227109ed7986576e4fc2fd8738', 'battle_rule_v1:64d5ec144e33bf5008c6ec840889e03d', '{"ability_kind":"static","battle_model_scope":"xmage_static_self_protection_from_card_types_creature_v1","effect":"creature","protection_from_card_types":["artifact"],"static_effect":"self_protection_from_card_types","target":"self","target_controller":"self","xmage_ability_class":"ProtectionAbility"}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class YavimayaScion translated into ManaLoom runtime scope xmage_static_self_protection_from_card_types_creature_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
    ('angelic curator', 'Angelic Curator', 'c6da5f0c4b2d68f5ca57f71674898e63', 'battle_rule_v1:b067ac2a5f8fe2f33fc1ea6586c92f68', '{"_keywords_are_self":true,"ability_kind":"static","battle_model_scope":"xmage_static_self_protection_from_card_types_creature_v1","effect":"creature","flying":true,"keywords":["flying"],"protection_from_card_types":["artifact"],"static_effect":"self_protection_from_card_types","target":"self","target_controller":"self","xmage_ability_class":"ProtectionAbility"}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class AngelicCurator translated into ManaLoom runtime scope xmage_static_self_protection_from_card_types_creature_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('azorius first-wing', 'Azorius First-Wing', '0bed20a30ce1893bce2a5f3525a3586d', 'battle_rule_v1:d1459b62eb8c5236cecc0803294e9c0a', '{"_keywords_are_self":true,"ability_kind":"static","battle_model_scope":"xmage_static_self_protection_from_card_types_creature_v1","effect":"creature","flying":true,"keywords":["flying"],"protection_from_card_types":["enchantment"],"static_effect":"self_protection_from_card_types","target":"self","target_controller":"self","xmage_ability_class":"ProtectionAbility"}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class AzoriusFirstWing translated into ManaLoom runtime scope xmage_static_self_protection_from_card_types_creature_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('beloved chaplain', 'Beloved Chaplain', '85465de2f7bb9355e2abee50bf175551', 'battle_rule_v1:219f2afb6ddef7cf8e3f05b9f56145b4', '{"ability_kind":"static","battle_model_scope":"xmage_static_self_protection_from_card_types_creature_v1","effect":"creature","protection_from_card_types":["creature"],"static_effect":"self_protection_from_card_types","target":"self","target_controller":"self","xmage_ability_class":"ProtectionAbility"}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class BelovedChaplain translated into ManaLoom runtime scope xmage_static_self_protection_from_card_types_creature_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('commander eesha', 'Commander Eesha', '8c397f94332b7738a90dffa5e34c1766', 'battle_rule_v1:cb4ddef26b3af5c6fae84cbcc063bcbd', '{"_keywords_are_self":true,"ability_kind":"static","battle_model_scope":"xmage_static_self_protection_from_card_types_creature_v1","effect":"creature","flying":true,"keywords":["flying"],"protection_from_card_types":["creature"],"static_effect":"self_protection_from_card_types","target":"self","target_controller":"self","xmage_ability_class":"ProtectionAbility"}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class CommanderEesha translated into ManaLoom runtime scope xmage_static_self_protection_from_card_types_creature_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('horizon drake', 'Horizon Drake', '483bc74a05388029147248b9fa3327e5', 'battle_rule_v1:8bad75f82fd0185f7d6515eae6a7ee75', '{"_keywords_are_self":true,"ability_kind":"static","battle_model_scope":"xmage_static_self_protection_from_card_types_creature_v1","effect":"creature","flying":true,"keywords":["flying"],"protection_from_card_types":["land"],"static_effect":"self_protection_from_card_types","target":"self","target_controller":"self","xmage_ability_class":"ProtectionAbility"}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class HorizonDrake translated into ManaLoom runtime scope xmage_static_self_protection_from_card_types_creature_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('nacatl savage', 'Nacatl Savage', 'c326b8227109ed7986576e4fc2fd8738', 'battle_rule_v1:64d5ec144e33bf5008c6ec840889e03d', '{"ability_kind":"static","battle_model_scope":"xmage_static_self_protection_from_card_types_creature_v1","effect":"creature","protection_from_card_types":["artifact"],"static_effect":"self_protection_from_card_types","target":"self","target_controller":"self","xmage_ability_class":"ProtectionAbility"}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class NacatlSavage translated into ManaLoom runtime scope xmage_static_self_protection_from_card_types_creature_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('needlebug', 'Needlebug', 'e6aa03762d0c8998b46747f47b554641', 'battle_rule_v1:813777fa7616859ba02a555d1232f605', '{"_keywords_are_self":true,"ability_kind":"static","battle_model_scope":"xmage_static_self_protection_from_card_types_creature_v1","effect":"creature","flash":true,"keywords":["flash"],"protection_from_card_types":["artifact"],"static_effect":"self_protection_from_card_types","target":"self","target_controller":"self","xmage_ability_class":"ProtectionAbility"}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Needlebug translated into ManaLoom runtime scope xmage_static_self_protection_from_card_types_creature_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('tel-jilad chosen', 'Tel-Jilad Chosen', 'c326b8227109ed7986576e4fc2fd8738', 'battle_rule_v1:64d5ec144e33bf5008c6ec840889e03d', '{"ability_kind":"static","battle_model_scope":"xmage_static_self_protection_from_card_types_creature_v1","effect":"creature","protection_from_card_types":["artifact"],"static_effect":"self_protection_from_card_types","target":"self","target_controller":"self","xmage_ability_class":"ProtectionAbility"}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class TelJiladChosen translated into ManaLoom runtime scope xmage_static_self_protection_from_card_types_creature_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('tel-jilad outrider', 'Tel-Jilad Outrider', 'c326b8227109ed7986576e4fc2fd8738', 'battle_rule_v1:64d5ec144e33bf5008c6ec840889e03d', '{"ability_kind":"static","battle_model_scope":"xmage_static_self_protection_from_card_types_creature_v1","effect":"creature","protection_from_card_types":["artifact"],"static_effect":"self_protection_from_card_types","target":"self","target_controller":"self","xmage_ability_class":"ProtectionAbility"}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class TelJiladOutrider translated into ManaLoom runtime scope xmage_static_self_protection_from_card_types_creature_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('yavimaya scion', 'Yavimaya Scion', 'c326b8227109ed7986576e4fc2fd8738', 'battle_rule_v1:64d5ec144e33bf5008c6ec840889e03d', '{"ability_kind":"static","battle_model_scope":"xmage_static_self_protection_from_card_types_creature_v1","effect":"creature","protection_from_card_types":["artifact"],"static_effect":"self_protection_from_card_types","target":"self","target_controller":"self","xmage_ability_class":"ProtectionAbility"}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class YavimayaScion translated into ManaLoom runtime scope xmage_static_self_protection_from_card_types_creature_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
