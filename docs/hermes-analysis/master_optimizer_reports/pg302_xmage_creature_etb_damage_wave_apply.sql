BEGIN;

CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit;

CREATE TABLE manaloom_deploy_audit.pg302_xmage_creature_etb_damage_wave_20260701_114851 AS
SELECT *
FROM public.card_battle_rules
WHERE normalized_name IN ('akoum boulderfoot', 'blisterstick shaman', 'corrupt eunuchs', 'fire imp', 'flametongue kavu', 'goblin commando', 'skeleton archer', 'sparkmage apprentice')
   OR normalized_name LIKE 'akoum boulderfoot // %'
   OR normalized_name LIKE 'blisterstick shaman // %'
   OR normalized_name LIKE 'corrupt eunuchs // %'
   OR normalized_name LIKE 'fire imp // %'
   OR normalized_name LIKE 'flametongue kavu // %'
   OR normalized_name LIKE 'goblin commando // %'
   OR normalized_name LIKE 'skeleton archer // %'
   OR normalized_name LIKE 'sparkmage apprentice // %';

DO $$
DECLARE
  v_missing jsonb;
BEGIN
  WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('akoum boulderfoot', 'Akoum Boulderfoot', '45281fde9e9ca072507cc0f3396ef1f8', 'battle_rule_v1:10ed26189f39de99d282a85334cead7d', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_fixed_damage_target_v1","effect":"creature","etb_damage_amount":1,"etb_damage_target":"any_target","target":"any_target","target_constraints":{"scope":"any_target"},"trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"DamageTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"any_target"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class AkoumBoulderfoot translated into ManaLoom runtime scope xmage_creature_etb_fixed_damage_target_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('blisterstick shaman', 'Blisterstick Shaman', '45281fde9e9ca072507cc0f3396ef1f8', 'battle_rule_v1:10ed26189f39de99d282a85334cead7d', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_fixed_damage_target_v1","effect":"creature","etb_damage_amount":1,"etb_damage_target":"any_target","target":"any_target","target_constraints":{"scope":"any_target"},"trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"DamageTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"any_target"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class BlisterstickShaman translated into ManaLoom runtime scope xmage_creature_etb_fixed_damage_target_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('corrupt eunuchs', 'Corrupt Eunuchs', '6cb7c3a573c3fc76d7a0275462aba0e4', 'battle_rule_v1:0ec21fb7926cc051327c2aef53549b01', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_fixed_damage_target_v1","effect":"creature","etb_damage_amount":2,"etb_damage_target":"creature","target":"creature","target_constraints":{"card_types":["creature"]},"trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"DamageTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class CorruptEunuchs translated into ManaLoom runtime scope xmage_creature_etb_fixed_damage_target_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('fire imp', 'Fire Imp', '6cb7c3a573c3fc76d7a0275462aba0e4', 'battle_rule_v1:0ec21fb7926cc051327c2aef53549b01', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_fixed_damage_target_v1","effect":"creature","etb_damage_amount":2,"etb_damage_target":"creature","target":"creature","target_constraints":{"card_types":["creature"]},"trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"DamageTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class FireImp translated into ManaLoom runtime scope xmage_creature_etb_fixed_damage_target_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('flametongue kavu', 'Flametongue Kavu', 'f158afdf97fc5a10935820ec11da373b', 'battle_rule_v1:22463a20fe885e7421278c4535de33b3', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_fixed_damage_target_v1","effect":"creature","etb_damage_amount":4,"etb_damage_target":"creature","target":"creature","target_constraints":{"card_types":["creature"]},"trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"DamageTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class FlametongueKavu translated into ManaLoom runtime scope xmage_creature_etb_fixed_damage_target_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('goblin commando', 'Goblin Commando', '6cb7c3a573c3fc76d7a0275462aba0e4', 'battle_rule_v1:0ec21fb7926cc051327c2aef53549b01', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_fixed_damage_target_v1","effect":"creature","etb_damage_amount":2,"etb_damage_target":"creature","target":"creature","target_constraints":{"card_types":["creature"]},"trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"DamageTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class GoblinCommando translated into ManaLoom runtime scope xmage_creature_etb_fixed_damage_target_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('skeleton archer', 'Skeleton Archer', '45281fde9e9ca072507cc0f3396ef1f8', 'battle_rule_v1:10ed26189f39de99d282a85334cead7d', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_fixed_damage_target_v1","effect":"creature","etb_damage_amount":1,"etb_damage_target":"any_target","target":"any_target","target_constraints":{"scope":"any_target"},"trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"DamageTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"any_target"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class SkeletonArcher translated into ManaLoom runtime scope xmage_creature_etb_fixed_damage_target_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('sparkmage apprentice', 'Sparkmage Apprentice', '45281fde9e9ca072507cc0f3396ef1f8', 'battle_rule_v1:10ed26189f39de99d282a85334cead7d', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_fixed_damage_target_v1","effect":"creature","etb_damage_amount":1,"etb_damage_target":"any_target","target":"any_target","target_constraints":{"scope":"any_target"},"trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"DamageTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"any_target"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class SparkmageApprentice translated into ManaLoom runtime scope xmage_creature_etb_fixed_damage_target_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
    ('akoum boulderfoot', 'Akoum Boulderfoot', '45281fde9e9ca072507cc0f3396ef1f8', 'battle_rule_v1:10ed26189f39de99d282a85334cead7d', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_fixed_damage_target_v1","effect":"creature","etb_damage_amount":1,"etb_damage_target":"any_target","target":"any_target","target_constraints":{"scope":"any_target"},"trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"DamageTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"any_target"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class AkoumBoulderfoot translated into ManaLoom runtime scope xmage_creature_etb_fixed_damage_target_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('blisterstick shaman', 'Blisterstick Shaman', '45281fde9e9ca072507cc0f3396ef1f8', 'battle_rule_v1:10ed26189f39de99d282a85334cead7d', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_fixed_damage_target_v1","effect":"creature","etb_damage_amount":1,"etb_damage_target":"any_target","target":"any_target","target_constraints":{"scope":"any_target"},"trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"DamageTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"any_target"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class BlisterstickShaman translated into ManaLoom runtime scope xmage_creature_etb_fixed_damage_target_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('corrupt eunuchs', 'Corrupt Eunuchs', '6cb7c3a573c3fc76d7a0275462aba0e4', 'battle_rule_v1:0ec21fb7926cc051327c2aef53549b01', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_fixed_damage_target_v1","effect":"creature","etb_damage_amount":2,"etb_damage_target":"creature","target":"creature","target_constraints":{"card_types":["creature"]},"trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"DamageTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class CorruptEunuchs translated into ManaLoom runtime scope xmage_creature_etb_fixed_damage_target_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('fire imp', 'Fire Imp', '6cb7c3a573c3fc76d7a0275462aba0e4', 'battle_rule_v1:0ec21fb7926cc051327c2aef53549b01', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_fixed_damage_target_v1","effect":"creature","etb_damage_amount":2,"etb_damage_target":"creature","target":"creature","target_constraints":{"card_types":["creature"]},"trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"DamageTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class FireImp translated into ManaLoom runtime scope xmage_creature_etb_fixed_damage_target_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('flametongue kavu', 'Flametongue Kavu', 'f158afdf97fc5a10935820ec11da373b', 'battle_rule_v1:22463a20fe885e7421278c4535de33b3', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_fixed_damage_target_v1","effect":"creature","etb_damage_amount":4,"etb_damage_target":"creature","target":"creature","target_constraints":{"card_types":["creature"]},"trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"DamageTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class FlametongueKavu translated into ManaLoom runtime scope xmage_creature_etb_fixed_damage_target_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('goblin commando', 'Goblin Commando', '6cb7c3a573c3fc76d7a0275462aba0e4', 'battle_rule_v1:0ec21fb7926cc051327c2aef53549b01', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_fixed_damage_target_v1","effect":"creature","etb_damage_amount":2,"etb_damage_target":"creature","target":"creature","target_constraints":{"card_types":["creature"]},"trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"DamageTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class GoblinCommando translated into ManaLoom runtime scope xmage_creature_etb_fixed_damage_target_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('skeleton archer', 'Skeleton Archer', '45281fde9e9ca072507cc0f3396ef1f8', 'battle_rule_v1:10ed26189f39de99d282a85334cead7d', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_fixed_damage_target_v1","effect":"creature","etb_damage_amount":1,"etb_damage_target":"any_target","target":"any_target","target_constraints":{"scope":"any_target"},"trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"DamageTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"any_target"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class SkeletonArcher translated into ManaLoom runtime scope xmage_creature_etb_fixed_damage_target_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('sparkmage apprentice', 'Sparkmage Apprentice', '45281fde9e9ca072507cc0f3396ef1f8', 'battle_rule_v1:10ed26189f39de99d282a85334cead7d', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_fixed_damage_target_v1","effect":"creature","etb_damage_amount":1,"etb_damage_target":"any_target","target":"any_target","target_constraints":{"scope":"any_target"},"trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"DamageTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"any_target"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class SparkmageApprentice translated into ManaLoom runtime scope xmage_creature_etb_fixed_damage_target_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
    ('akoum boulderfoot', 'Akoum Boulderfoot', '45281fde9e9ca072507cc0f3396ef1f8', 'battle_rule_v1:10ed26189f39de99d282a85334cead7d', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_fixed_damage_target_v1","effect":"creature","etb_damage_amount":1,"etb_damage_target":"any_target","target":"any_target","target_constraints":{"scope":"any_target"},"trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"DamageTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"any_target"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class AkoumBoulderfoot translated into ManaLoom runtime scope xmage_creature_etb_fixed_damage_target_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('blisterstick shaman', 'Blisterstick Shaman', '45281fde9e9ca072507cc0f3396ef1f8', 'battle_rule_v1:10ed26189f39de99d282a85334cead7d', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_fixed_damage_target_v1","effect":"creature","etb_damage_amount":1,"etb_damage_target":"any_target","target":"any_target","target_constraints":{"scope":"any_target"},"trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"DamageTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"any_target"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class BlisterstickShaman translated into ManaLoom runtime scope xmage_creature_etb_fixed_damage_target_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('corrupt eunuchs', 'Corrupt Eunuchs', '6cb7c3a573c3fc76d7a0275462aba0e4', 'battle_rule_v1:0ec21fb7926cc051327c2aef53549b01', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_fixed_damage_target_v1","effect":"creature","etb_damage_amount":2,"etb_damage_target":"creature","target":"creature","target_constraints":{"card_types":["creature"]},"trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"DamageTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class CorruptEunuchs translated into ManaLoom runtime scope xmage_creature_etb_fixed_damage_target_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('fire imp', 'Fire Imp', '6cb7c3a573c3fc76d7a0275462aba0e4', 'battle_rule_v1:0ec21fb7926cc051327c2aef53549b01', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_fixed_damage_target_v1","effect":"creature","etb_damage_amount":2,"etb_damage_target":"creature","target":"creature","target_constraints":{"card_types":["creature"]},"trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"DamageTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class FireImp translated into ManaLoom runtime scope xmage_creature_etb_fixed_damage_target_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('flametongue kavu', 'Flametongue Kavu', 'f158afdf97fc5a10935820ec11da373b', 'battle_rule_v1:22463a20fe885e7421278c4535de33b3', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_fixed_damage_target_v1","effect":"creature","etb_damage_amount":4,"etb_damage_target":"creature","target":"creature","target_constraints":{"card_types":["creature"]},"trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"DamageTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class FlametongueKavu translated into ManaLoom runtime scope xmage_creature_etb_fixed_damage_target_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('goblin commando', 'Goblin Commando', '6cb7c3a573c3fc76d7a0275462aba0e4', 'battle_rule_v1:0ec21fb7926cc051327c2aef53549b01', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_fixed_damage_target_v1","effect":"creature","etb_damage_amount":2,"etb_damage_target":"creature","target":"creature","target_constraints":{"card_types":["creature"]},"trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"DamageTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class GoblinCommando translated into ManaLoom runtime scope xmage_creature_etb_fixed_damage_target_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('skeleton archer', 'Skeleton Archer', '45281fde9e9ca072507cc0f3396ef1f8', 'battle_rule_v1:10ed26189f39de99d282a85334cead7d', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_fixed_damage_target_v1","effect":"creature","etb_damage_amount":1,"etb_damage_target":"any_target","target":"any_target","target_constraints":{"scope":"any_target"},"trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"DamageTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"any_target"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class SkeletonArcher translated into ManaLoom runtime scope xmage_creature_etb_fixed_damage_target_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('sparkmage apprentice', 'Sparkmage Apprentice', '45281fde9e9ca072507cc0f3396ef1f8', 'battle_rule_v1:10ed26189f39de99d282a85334cead7d', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_fixed_damage_target_v1","effect":"creature","etb_damage_amount":1,"etb_damage_target":"any_target","target":"any_target","target_constraints":{"scope":"any_target"},"trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"DamageTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"any_target"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class SparkmageApprentice translated into ManaLoom runtime scope xmage_creature_etb_fixed_damage_target_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
