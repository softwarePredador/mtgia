BEGIN;

CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit;

CREATE TABLE manaloom_deploy_audit.pg396_dies_damage_new_server_20260704_091330 AS
SELECT *
FROM public.card_battle_rules
WHERE normalized_name IN ('bogardan firefiend', 'careless celebrant', 'footlight fiend', 'goblin arsonist', 'mudbutton torchrunner', 'perilous myr', 'pitchburn devils', 'pyre spawn')
   OR normalized_name LIKE 'bogardan firefiend // %'
   OR normalized_name LIKE 'careless celebrant // %'
   OR normalized_name LIKE 'footlight fiend // %'
   OR normalized_name LIKE 'goblin arsonist // %'
   OR normalized_name LIKE 'mudbutton torchrunner // %'
   OR normalized_name LIKE 'perilous myr // %'
   OR normalized_name LIKE 'pitchburn devils // %'
   OR normalized_name LIKE 'pyre spawn // %';

DO $$
DECLARE
  v_missing jsonb;
BEGIN
  WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('bogardan firefiend', 'Bogardan Firefiend', 'd210b4897146ab01359623ef415616a5', 'battle_rule_v1:9c97a0bb3f8d95c6861678f7a210a696', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_dies_fixed_damage_target_v1","dies_damage_amount":2,"dies_damage_target":"creature","effect":"creature","target":"creature","target_constraints":{"card_types":["creature"]},"trigger":"dies","xmage_ability_class":"DiesSourceTriggeredAbility","xmage_effect_class":"DamageTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class BogardanFirefiend translated into ManaLoom runtime scope xmage_creature_dies_fixed_damage_target_v1. This row is package-ready only because the source signature is a narrow creature dies triggered fixed damage ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('careless celebrant', 'Careless Celebrant', '14b9501f0c035da8dbd3dfb8945a7b2f', 'battle_rule_v1:47dd9df12e72454256312ff74c57a219', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_dies_fixed_damage_target_v1","dies_damage_amount":2,"dies_damage_target":"creature_or_planeswalker","effect":"creature","target":"creature_or_planeswalker","target_constraints":{"card_types":["creature","planeswalker"]},"trigger":"dies","xmage_ability_class":"DiesSourceTriggeredAbility","xmage_effect_class":"DamageTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"creature_or_planeswalker"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class CarelessCelebrant translated into ManaLoom runtime scope xmage_creature_dies_fixed_damage_target_v1. This row is package-ready only because the source signature is a narrow creature dies triggered fixed damage ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('footlight fiend', 'Footlight Fiend', '849b98bfe418aa4fdad033045c561296', 'battle_rule_v1:e674fea2b801e52066c06b5504a1a242', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_dies_fixed_damage_target_v1","dies_damage_amount":1,"dies_damage_target":"any_target","effect":"creature","target":"any_target","target_constraints":{"scope":"any_target"},"trigger":"dies","xmage_ability_class":"DiesSourceTriggeredAbility","xmage_effect_class":"DamageTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"any_target"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class FootlightFiend translated into ManaLoom runtime scope xmage_creature_dies_fixed_damage_target_v1. This row is package-ready only because the source signature is a narrow creature dies triggered fixed damage ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('goblin arsonist', 'Goblin Arsonist', '68b46e8a49e3947f0a6b65b7aa924c04', 'battle_rule_v1:0f26849f10bf9e0357f6a7a23f392f75', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_dies_fixed_damage_target_v1","dies_damage_amount":1,"dies_damage_optional":true,"dies_damage_target":"any_target","effect":"creature","target":"any_target","target_constraints":{"scope":"any_target"},"trigger":"dies","xmage_ability_class":"DiesSourceTriggeredAbility","xmage_effect_class":"DamageTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"any_target"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class GoblinArsonist translated into ManaLoom runtime scope xmage_creature_dies_fixed_damage_target_v1. This row is package-ready only because the source signature is a narrow creature dies triggered fixed damage ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('mudbutton torchrunner', 'Mudbutton Torchrunner', '7fa459ff91be335e859f88b5b0c305ac', 'battle_rule_v1:5b89a7a55f519dfc8a4f39120ddda3a9', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_dies_fixed_damage_target_v1","dies_damage_amount":3,"dies_damage_target":"any_target","effect":"creature","target":"any_target","target_constraints":{"scope":"any_target"},"trigger":"dies","xmage_ability_class":"DiesSourceTriggeredAbility","xmage_effect_class":"DamageTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"any_target"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class MudbuttonTorchrunner translated into ManaLoom runtime scope xmage_creature_dies_fixed_damage_target_v1. This row is package-ready only because the source signature is a narrow creature dies triggered fixed damage ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('perilous myr', 'Perilous Myr', '54bcabf69140caa8b8f4b29ef191b4c0', 'battle_rule_v1:0cad1f375dbce251b5d86ecd298660a1', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_dies_fixed_damage_target_v1","dies_damage_amount":2,"dies_damage_target":"any_target","effect":"creature","target":"any_target","target_constraints":{"scope":"any_target"},"trigger":"dies","xmage_ability_class":"DiesSourceTriggeredAbility","xmage_effect_class":"DamageTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"any_target"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class PerilousMyr translated into ManaLoom runtime scope xmage_creature_dies_fixed_damage_target_v1. This row is package-ready only because the source signature is a narrow creature dies triggered fixed damage ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('pitchburn devils', 'Pitchburn Devils', '7fa459ff91be335e859f88b5b0c305ac', 'battle_rule_v1:5b89a7a55f519dfc8a4f39120ddda3a9', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_dies_fixed_damage_target_v1","dies_damage_amount":3,"dies_damage_target":"any_target","effect":"creature","target":"any_target","target_constraints":{"scope":"any_target"},"trigger":"dies","xmage_ability_class":"DiesSourceTriggeredAbility","xmage_effect_class":"DamageTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"any_target"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class PitchburnDevils translated into ManaLoom runtime scope xmage_creature_dies_fixed_damage_target_v1. This row is package-ready only because the source signature is a narrow creature dies triggered fixed damage ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('pyre spawn', 'Pyre Spawn', '7fa459ff91be335e859f88b5b0c305ac', 'battle_rule_v1:5b89a7a55f519dfc8a4f39120ddda3a9', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_dies_fixed_damage_target_v1","dies_damage_amount":3,"dies_damage_target":"any_target","effect":"creature","target":"any_target","target_constraints":{"scope":"any_target"},"trigger":"dies","xmage_ability_class":"DiesSourceTriggeredAbility","xmage_effect_class":"DamageTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"any_target"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class PyreSpawn translated into ManaLoom runtime scope xmage_creature_dies_fixed_damage_target_v1. This row is package-ready only because the source signature is a narrow creature dies triggered fixed damage ability with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
    ('bogardan firefiend', 'Bogardan Firefiend', 'd210b4897146ab01359623ef415616a5', 'battle_rule_v1:9c97a0bb3f8d95c6861678f7a210a696', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_dies_fixed_damage_target_v1","dies_damage_amount":2,"dies_damage_target":"creature","effect":"creature","target":"creature","target_constraints":{"card_types":["creature"]},"trigger":"dies","xmage_ability_class":"DiesSourceTriggeredAbility","xmage_effect_class":"DamageTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class BogardanFirefiend translated into ManaLoom runtime scope xmage_creature_dies_fixed_damage_target_v1. This row is package-ready only because the source signature is a narrow creature dies triggered fixed damage ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('careless celebrant', 'Careless Celebrant', '14b9501f0c035da8dbd3dfb8945a7b2f', 'battle_rule_v1:47dd9df12e72454256312ff74c57a219', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_dies_fixed_damage_target_v1","dies_damage_amount":2,"dies_damage_target":"creature_or_planeswalker","effect":"creature","target":"creature_or_planeswalker","target_constraints":{"card_types":["creature","planeswalker"]},"trigger":"dies","xmage_ability_class":"DiesSourceTriggeredAbility","xmage_effect_class":"DamageTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"creature_or_planeswalker"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class CarelessCelebrant translated into ManaLoom runtime scope xmage_creature_dies_fixed_damage_target_v1. This row is package-ready only because the source signature is a narrow creature dies triggered fixed damage ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('footlight fiend', 'Footlight Fiend', '849b98bfe418aa4fdad033045c561296', 'battle_rule_v1:e674fea2b801e52066c06b5504a1a242', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_dies_fixed_damage_target_v1","dies_damage_amount":1,"dies_damage_target":"any_target","effect":"creature","target":"any_target","target_constraints":{"scope":"any_target"},"trigger":"dies","xmage_ability_class":"DiesSourceTriggeredAbility","xmage_effect_class":"DamageTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"any_target"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class FootlightFiend translated into ManaLoom runtime scope xmage_creature_dies_fixed_damage_target_v1. This row is package-ready only because the source signature is a narrow creature dies triggered fixed damage ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('goblin arsonist', 'Goblin Arsonist', '68b46e8a49e3947f0a6b65b7aa924c04', 'battle_rule_v1:0f26849f10bf9e0357f6a7a23f392f75', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_dies_fixed_damage_target_v1","dies_damage_amount":1,"dies_damage_optional":true,"dies_damage_target":"any_target","effect":"creature","target":"any_target","target_constraints":{"scope":"any_target"},"trigger":"dies","xmage_ability_class":"DiesSourceTriggeredAbility","xmage_effect_class":"DamageTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"any_target"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class GoblinArsonist translated into ManaLoom runtime scope xmage_creature_dies_fixed_damage_target_v1. This row is package-ready only because the source signature is a narrow creature dies triggered fixed damage ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('mudbutton torchrunner', 'Mudbutton Torchrunner', '7fa459ff91be335e859f88b5b0c305ac', 'battle_rule_v1:5b89a7a55f519dfc8a4f39120ddda3a9', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_dies_fixed_damage_target_v1","dies_damage_amount":3,"dies_damage_target":"any_target","effect":"creature","target":"any_target","target_constraints":{"scope":"any_target"},"trigger":"dies","xmage_ability_class":"DiesSourceTriggeredAbility","xmage_effect_class":"DamageTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"any_target"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class MudbuttonTorchrunner translated into ManaLoom runtime scope xmage_creature_dies_fixed_damage_target_v1. This row is package-ready only because the source signature is a narrow creature dies triggered fixed damage ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('perilous myr', 'Perilous Myr', '54bcabf69140caa8b8f4b29ef191b4c0', 'battle_rule_v1:0cad1f375dbce251b5d86ecd298660a1', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_dies_fixed_damage_target_v1","dies_damage_amount":2,"dies_damage_target":"any_target","effect":"creature","target":"any_target","target_constraints":{"scope":"any_target"},"trigger":"dies","xmage_ability_class":"DiesSourceTriggeredAbility","xmage_effect_class":"DamageTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"any_target"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class PerilousMyr translated into ManaLoom runtime scope xmage_creature_dies_fixed_damage_target_v1. This row is package-ready only because the source signature is a narrow creature dies triggered fixed damage ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('pitchburn devils', 'Pitchburn Devils', '7fa459ff91be335e859f88b5b0c305ac', 'battle_rule_v1:5b89a7a55f519dfc8a4f39120ddda3a9', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_dies_fixed_damage_target_v1","dies_damage_amount":3,"dies_damage_target":"any_target","effect":"creature","target":"any_target","target_constraints":{"scope":"any_target"},"trigger":"dies","xmage_ability_class":"DiesSourceTriggeredAbility","xmage_effect_class":"DamageTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"any_target"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class PitchburnDevils translated into ManaLoom runtime scope xmage_creature_dies_fixed_damage_target_v1. This row is package-ready only because the source signature is a narrow creature dies triggered fixed damage ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('pyre spawn', 'Pyre Spawn', '7fa459ff91be335e859f88b5b0c305ac', 'battle_rule_v1:5b89a7a55f519dfc8a4f39120ddda3a9', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_dies_fixed_damage_target_v1","dies_damage_amount":3,"dies_damage_target":"any_target","effect":"creature","target":"any_target","target_constraints":{"scope":"any_target"},"trigger":"dies","xmage_ability_class":"DiesSourceTriggeredAbility","xmage_effect_class":"DamageTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"any_target"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class PyreSpawn translated into ManaLoom runtime scope xmage_creature_dies_fixed_damage_target_v1. This row is package-ready only because the source signature is a narrow creature dies triggered fixed damage ability with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
    ('bogardan firefiend', 'Bogardan Firefiend', 'd210b4897146ab01359623ef415616a5', 'battle_rule_v1:9c97a0bb3f8d95c6861678f7a210a696', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_dies_fixed_damage_target_v1","dies_damage_amount":2,"dies_damage_target":"creature","effect":"creature","target":"creature","target_constraints":{"card_types":["creature"]},"trigger":"dies","xmage_ability_class":"DiesSourceTriggeredAbility","xmage_effect_class":"DamageTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class BogardanFirefiend translated into ManaLoom runtime scope xmage_creature_dies_fixed_damage_target_v1. This row is package-ready only because the source signature is a narrow creature dies triggered fixed damage ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('careless celebrant', 'Careless Celebrant', '14b9501f0c035da8dbd3dfb8945a7b2f', 'battle_rule_v1:47dd9df12e72454256312ff74c57a219', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_dies_fixed_damage_target_v1","dies_damage_amount":2,"dies_damage_target":"creature_or_planeswalker","effect":"creature","target":"creature_or_planeswalker","target_constraints":{"card_types":["creature","planeswalker"]},"trigger":"dies","xmage_ability_class":"DiesSourceTriggeredAbility","xmage_effect_class":"DamageTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"creature_or_planeswalker"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class CarelessCelebrant translated into ManaLoom runtime scope xmage_creature_dies_fixed_damage_target_v1. This row is package-ready only because the source signature is a narrow creature dies triggered fixed damage ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('footlight fiend', 'Footlight Fiend', '849b98bfe418aa4fdad033045c561296', 'battle_rule_v1:e674fea2b801e52066c06b5504a1a242', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_dies_fixed_damage_target_v1","dies_damage_amount":1,"dies_damage_target":"any_target","effect":"creature","target":"any_target","target_constraints":{"scope":"any_target"},"trigger":"dies","xmage_ability_class":"DiesSourceTriggeredAbility","xmage_effect_class":"DamageTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"any_target"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class FootlightFiend translated into ManaLoom runtime scope xmage_creature_dies_fixed_damage_target_v1. This row is package-ready only because the source signature is a narrow creature dies triggered fixed damage ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('goblin arsonist', 'Goblin Arsonist', '68b46e8a49e3947f0a6b65b7aa924c04', 'battle_rule_v1:0f26849f10bf9e0357f6a7a23f392f75', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_dies_fixed_damage_target_v1","dies_damage_amount":1,"dies_damage_optional":true,"dies_damage_target":"any_target","effect":"creature","target":"any_target","target_constraints":{"scope":"any_target"},"trigger":"dies","xmage_ability_class":"DiesSourceTriggeredAbility","xmage_effect_class":"DamageTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"any_target"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class GoblinArsonist translated into ManaLoom runtime scope xmage_creature_dies_fixed_damage_target_v1. This row is package-ready only because the source signature is a narrow creature dies triggered fixed damage ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('mudbutton torchrunner', 'Mudbutton Torchrunner', '7fa459ff91be335e859f88b5b0c305ac', 'battle_rule_v1:5b89a7a55f519dfc8a4f39120ddda3a9', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_dies_fixed_damage_target_v1","dies_damage_amount":3,"dies_damage_target":"any_target","effect":"creature","target":"any_target","target_constraints":{"scope":"any_target"},"trigger":"dies","xmage_ability_class":"DiesSourceTriggeredAbility","xmage_effect_class":"DamageTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"any_target"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class MudbuttonTorchrunner translated into ManaLoom runtime scope xmage_creature_dies_fixed_damage_target_v1. This row is package-ready only because the source signature is a narrow creature dies triggered fixed damage ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('perilous myr', 'Perilous Myr', '54bcabf69140caa8b8f4b29ef191b4c0', 'battle_rule_v1:0cad1f375dbce251b5d86ecd298660a1', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_dies_fixed_damage_target_v1","dies_damage_amount":2,"dies_damage_target":"any_target","effect":"creature","target":"any_target","target_constraints":{"scope":"any_target"},"trigger":"dies","xmage_ability_class":"DiesSourceTriggeredAbility","xmage_effect_class":"DamageTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"any_target"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class PerilousMyr translated into ManaLoom runtime scope xmage_creature_dies_fixed_damage_target_v1. This row is package-ready only because the source signature is a narrow creature dies triggered fixed damage ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('pitchburn devils', 'Pitchburn Devils', '7fa459ff91be335e859f88b5b0c305ac', 'battle_rule_v1:5b89a7a55f519dfc8a4f39120ddda3a9', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_dies_fixed_damage_target_v1","dies_damage_amount":3,"dies_damage_target":"any_target","effect":"creature","target":"any_target","target_constraints":{"scope":"any_target"},"trigger":"dies","xmage_ability_class":"DiesSourceTriggeredAbility","xmage_effect_class":"DamageTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"any_target"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class PitchburnDevils translated into ManaLoom runtime scope xmage_creature_dies_fixed_damage_target_v1. This row is package-ready only because the source signature is a narrow creature dies triggered fixed damage ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('pyre spawn', 'Pyre Spawn', '7fa459ff91be335e859f88b5b0c305ac', 'battle_rule_v1:5b89a7a55f519dfc8a4f39120ddda3a9', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_dies_fixed_damage_target_v1","dies_damage_amount":3,"dies_damage_target":"any_target","effect":"creature","target":"any_target","target_constraints":{"scope":"any_target"},"trigger":"dies","xmage_ability_class":"DiesSourceTriggeredAbility","xmage_effect_class":"DamageTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"any_target"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class PyreSpawn translated into ManaLoom runtime scope xmage_creature_dies_fixed_damage_target_v1. This row is package-ready only because the source signature is a narrow creature dies triggered fixed damage ability with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
