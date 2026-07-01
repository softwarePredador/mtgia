BEGIN;

CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit;

CREATE TABLE manaloom_deploy_audit.pg307_xmage_destroy_gain_life_spell_wave_20260701_131317 AS
SELECT *
FROM public.card_battle_rules
WHERE normalized_name IN ('appetite for the unnatural', 'cursebreak', 'drain the well', 'grapple with death', 'invoke the divine', 'lich''s caress', 'maw of the mire', 'natural end', 'ray of dissolution', 'sanctify', 'sephiroth''s intervention', 'solemn offering', 'springsage ritual')
   OR normalized_name LIKE 'appetite for the unnatural // %'
   OR normalized_name LIKE 'cursebreak // %'
   OR normalized_name LIKE 'drain the well // %'
   OR normalized_name LIKE 'grapple with death // %'
   OR normalized_name LIKE 'invoke the divine // %'
   OR normalized_name LIKE 'lich''s caress // %'
   OR normalized_name LIKE 'maw of the mire // %'
   OR normalized_name LIKE 'natural end // %'
   OR normalized_name LIKE 'ray of dissolution // %'
   OR normalized_name LIKE 'sanctify // %'
   OR normalized_name LIKE 'sephiroth''s intervention // %'
   OR normalized_name LIKE 'solemn offering // %'
   OR normalized_name LIKE 'springsage ritual // %';

DO $$
DECLARE
  v_missing jsonb;
BEGIN
  WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('appetite for the unnatural', 'Appetite for the Unnatural', 'ff2701341e046cdb32db1fd2d24193f3', 'battle_rule_v1:f25f7f032c8935a2725f03e806412108', '{"battle_model_scope":"xmage_destroy_target_and_controller_gain_life_spell_v1","controller_gains_life":2,"destination":"graveyard","effect":"remove_permanent","instant":true,"sorcery":false,"target":"artifact_or_enchantment","target_constraints":{"card_types":["artifact","enchantment"]},"xmage_effect_classes":["DestroyTargetEffect","GainLifeEffect"]}'::jsonb, '{"category":"removal","effect":"remove_permanent","target":"artifact_or_enchantment","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class AppetiteForTheUnnatural translated into ManaLoom runtime scope xmage_destroy_target_and_controller_gain_life_spell_v1. This row is package-ready only because the source signature is a narrow fixed destroy-target plus controller life-gain spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('cursebreak', 'Cursebreak', 'e8b18bd9c5e41964bd056a95a9599ba6', 'battle_rule_v1:eac90831bff0a6d7d8cc7f79c84dc684', '{"battle_model_scope":"xmage_destroy_target_and_controller_gain_life_spell_v1","controller_gains_life":2,"destination":"graveyard","effect":"remove_permanent","instant":true,"sorcery":false,"target":"enchantment","target_constraints":{"card_types":["enchantment"]},"xmage_effect_classes":["DestroyTargetEffect","GainLifeEffect"]}'::jsonb, '{"category":"removal","effect":"remove_permanent","target":"enchantment","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Cursebreak translated into ManaLoom runtime scope xmage_destroy_target_and_controller_gain_life_spell_v1. This row is package-ready only because the source signature is a narrow fixed destroy-target plus controller life-gain spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('drain the well', 'Drain the Well', 'a83cde4e874b76b73ec6952b980c5a5d', 'battle_rule_v1:8c113d532b53977905ddd6205d20b76b', '{"battle_model_scope":"xmage_destroy_target_and_controller_gain_life_spell_v1","controller_gains_life":2,"destination":"graveyard","effect":"remove_permanent","instant":false,"sorcery":true,"target":"land","target_constraints":{"card_types":["land"]},"xmage_effect_classes":["DestroyTargetEffect","GainLifeEffect"]}'::jsonb, '{"category":"removal","effect":"remove_permanent","target":"land"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class DrainTheWell translated into ManaLoom runtime scope xmage_destroy_target_and_controller_gain_life_spell_v1. This row is package-ready only because the source signature is a narrow fixed destroy-target plus controller life-gain spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('grapple with death', 'Grapple with Death', '2b0b7a6ae97fc371def1be151b9f5a9f', 'battle_rule_v1:5ae5bf64faa291c0d09c85d28201a2c2', '{"battle_model_scope":"xmage_destroy_target_and_controller_gain_life_spell_v1","controller_gains_life":1,"destination":"graveyard","effect":"remove_permanent","instant":false,"sorcery":true,"target":"artifact_or_creature","target_constraints":{"card_types":["artifact","creature"]},"xmage_effect_classes":["DestroyTargetEffect","GainLifeEffect"]}'::jsonb, '{"category":"removal","effect":"remove_permanent","target":"artifact_or_creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class GrappleWithDeath translated into ManaLoom runtime scope xmage_destroy_target_and_controller_gain_life_spell_v1. This row is package-ready only because the source signature is a narrow fixed destroy-target plus controller life-gain spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('invoke the divine', 'Invoke the Divine', '1a2e40995c4f7d6463ae7b5ce96cbfe5', 'battle_rule_v1:5d06c51d4005a36bd990d87851d9383c', '{"battle_model_scope":"xmage_destroy_target_and_controller_gain_life_spell_v1","controller_gains_life":4,"destination":"graveyard","effect":"remove_permanent","instant":true,"sorcery":false,"target":"artifact_or_enchantment","target_constraints":{"card_types":["artifact","enchantment"]},"xmage_effect_classes":["DestroyTargetEffect","GainLifeEffect"]}'::jsonb, '{"category":"removal","effect":"remove_permanent","target":"artifact_or_enchantment","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class InvokeTheDivine translated into ManaLoom runtime scope xmage_destroy_target_and_controller_gain_life_spell_v1. This row is package-ready only because the source signature is a narrow fixed destroy-target plus controller life-gain spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('lich''s caress', 'Lich''s Caress', '1f0834667ff74af400f80cd6af6f6f50', 'battle_rule_v1:2151b4f927db86b6035cda9e8968a760', '{"battle_model_scope":"xmage_destroy_target_and_controller_gain_life_spell_v1","controller_gains_life":3,"destination":"graveyard","effect":"remove_creature","instant":false,"sorcery":true,"target":"creature","target_constraints":{"card_types":["creature"]},"xmage_effect_classes":["DestroyTargetEffect","GainLifeEffect"]}'::jsonb, '{"category":"removal","effect":"remove_creature","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class LichsCaress translated into ManaLoom runtime scope xmage_destroy_target_and_controller_gain_life_spell_v1. This row is package-ready only because the source signature is a narrow fixed destroy-target plus controller life-gain spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('maw of the mire', 'Maw of the Mire', 'af7b53f165c85d1baa6e0670e600763d', 'battle_rule_v1:30ecba357ba66148eab77d3cd4e5e9a6', '{"battle_model_scope":"xmage_destroy_target_and_controller_gain_life_spell_v1","controller_gains_life":4,"destination":"graveyard","effect":"remove_permanent","instant":false,"sorcery":true,"target":"land","target_constraints":{"card_types":["land"]},"xmage_effect_classes":["DestroyTargetEffect","GainLifeEffect"]}'::jsonb, '{"category":"removal","effect":"remove_permanent","target":"land"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class MawOfTheMire translated into ManaLoom runtime scope xmage_destroy_target_and_controller_gain_life_spell_v1. This row is package-ready only because the source signature is a narrow fixed destroy-target plus controller life-gain spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('natural end', 'Natural End', 'e2ec7d476fb36a631e6ead5c573d45a2', 'battle_rule_v1:1497fb65812c46c78c5b669ff4989524', '{"battle_model_scope":"xmage_destroy_target_and_controller_gain_life_spell_v1","controller_gains_life":3,"destination":"graveyard","effect":"remove_permanent","instant":true,"sorcery":false,"target":"artifact_or_enchantment","target_constraints":{"card_types":["artifact","enchantment"]},"xmage_effect_classes":["DestroyTargetEffect","GainLifeEffect"]}'::jsonb, '{"category":"removal","effect":"remove_permanent","target":"artifact_or_enchantment","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class NaturalEnd translated into ManaLoom runtime scope xmage_destroy_target_and_controller_gain_life_spell_v1. This row is package-ready only because the source signature is a narrow fixed destroy-target plus controller life-gain spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('ray of dissolution', 'Ray of Dissolution', '3595f82ef93062fd242ae9dc886164c8', 'battle_rule_v1:762898b040728ef22fc560e8c079ec0d', '{"battle_model_scope":"xmage_destroy_target_and_controller_gain_life_spell_v1","controller_gains_life":3,"destination":"graveyard","effect":"remove_permanent","instant":true,"sorcery":false,"target":"enchantment","target_constraints":{"card_types":["enchantment"]},"xmage_effect_classes":["DestroyTargetEffect","GainLifeEffect"]}'::jsonb, '{"category":"removal","effect":"remove_permanent","target":"enchantment","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class RayOfDissolution translated into ManaLoom runtime scope xmage_destroy_target_and_controller_gain_life_spell_v1. This row is package-ready only because the source signature is a narrow fixed destroy-target plus controller life-gain spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('sanctify', 'Sanctify', 'e2ec7d476fb36a631e6ead5c573d45a2', 'battle_rule_v1:2bf2d3a044f5bd1745cbac8a72622f30', '{"battle_model_scope":"xmage_destroy_target_and_controller_gain_life_spell_v1","controller_gains_life":3,"destination":"graveyard","effect":"remove_permanent","instant":false,"sorcery":true,"target":"artifact_or_enchantment","target_constraints":{"card_types":["artifact","enchantment"]},"xmage_effect_classes":["DestroyTargetEffect","GainLifeEffect"]}'::jsonb, '{"category":"removal","effect":"remove_permanent","target":"artifact_or_enchantment"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Sanctify translated into ManaLoom runtime scope xmage_destroy_target_and_controller_gain_life_spell_v1. This row is package-ready only because the source signature is a narrow fixed destroy-target plus controller life-gain spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('sephiroth''s intervention', 'Sephiroth''s Intervention', '2dffcc424019a833cb2851580aa3694b', 'battle_rule_v1:eeb274765267ef2873eb0b196c027df8', '{"battle_model_scope":"xmage_destroy_target_and_controller_gain_life_spell_v1","controller_gains_life":2,"destination":"graveyard","effect":"remove_creature","instant":true,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"]},"xmage_effect_classes":["DestroyTargetEffect","GainLifeEffect"]}'::jsonb, '{"category":"removal","effect":"remove_creature","target":"creature","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class SephirothsIntervention translated into ManaLoom runtime scope xmage_destroy_target_and_controller_gain_life_spell_v1. This row is package-ready only because the source signature is a narrow fixed destroy-target plus controller life-gain spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('solemn offering', 'Solemn Offering', '1a2e40995c4f7d6463ae7b5ce96cbfe5', 'battle_rule_v1:a3ed89e31c22fb41043599139d0632cd', '{"battle_model_scope":"xmage_destroy_target_and_controller_gain_life_spell_v1","controller_gains_life":4,"destination":"graveyard","effect":"remove_permanent","instant":false,"sorcery":true,"target":"artifact_or_enchantment","target_constraints":{"card_types":["artifact","enchantment"]},"xmage_effect_classes":["DestroyTargetEffect","GainLifeEffect"]}'::jsonb, '{"category":"removal","effect":"remove_permanent","target":"artifact_or_enchantment"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class SolemnOffering translated into ManaLoom runtime scope xmage_destroy_target_and_controller_gain_life_spell_v1. This row is package-ready only because the source signature is a narrow fixed destroy-target plus controller life-gain spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('springsage ritual', 'Springsage Ritual', '1a2e40995c4f7d6463ae7b5ce96cbfe5', 'battle_rule_v1:5d06c51d4005a36bd990d87851d9383c', '{"battle_model_scope":"xmage_destroy_target_and_controller_gain_life_spell_v1","controller_gains_life":4,"destination":"graveyard","effect":"remove_permanent","instant":true,"sorcery":false,"target":"artifact_or_enchantment","target_constraints":{"card_types":["artifact","enchantment"]},"xmage_effect_classes":["DestroyTargetEffect","GainLifeEffect"]}'::jsonb, '{"category":"removal","effect":"remove_permanent","target":"artifact_or_enchantment","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class SpringsageRitual translated into ManaLoom runtime scope xmage_destroy_target_and_controller_gain_life_spell_v1. This row is package-ready only because the source signature is a narrow fixed destroy-target plus controller life-gain spell with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
    ('appetite for the unnatural', 'Appetite for the Unnatural', 'ff2701341e046cdb32db1fd2d24193f3', 'battle_rule_v1:f25f7f032c8935a2725f03e806412108', '{"battle_model_scope":"xmage_destroy_target_and_controller_gain_life_spell_v1","controller_gains_life":2,"destination":"graveyard","effect":"remove_permanent","instant":true,"sorcery":false,"target":"artifact_or_enchantment","target_constraints":{"card_types":["artifact","enchantment"]},"xmage_effect_classes":["DestroyTargetEffect","GainLifeEffect"]}'::jsonb, '{"category":"removal","effect":"remove_permanent","target":"artifact_or_enchantment","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class AppetiteForTheUnnatural translated into ManaLoom runtime scope xmage_destroy_target_and_controller_gain_life_spell_v1. This row is package-ready only because the source signature is a narrow fixed destroy-target plus controller life-gain spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('cursebreak', 'Cursebreak', 'e8b18bd9c5e41964bd056a95a9599ba6', 'battle_rule_v1:eac90831bff0a6d7d8cc7f79c84dc684', '{"battle_model_scope":"xmage_destroy_target_and_controller_gain_life_spell_v1","controller_gains_life":2,"destination":"graveyard","effect":"remove_permanent","instant":true,"sorcery":false,"target":"enchantment","target_constraints":{"card_types":["enchantment"]},"xmage_effect_classes":["DestroyTargetEffect","GainLifeEffect"]}'::jsonb, '{"category":"removal","effect":"remove_permanent","target":"enchantment","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Cursebreak translated into ManaLoom runtime scope xmage_destroy_target_and_controller_gain_life_spell_v1. This row is package-ready only because the source signature is a narrow fixed destroy-target plus controller life-gain spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('drain the well', 'Drain the Well', 'a83cde4e874b76b73ec6952b980c5a5d', 'battle_rule_v1:8c113d532b53977905ddd6205d20b76b', '{"battle_model_scope":"xmage_destroy_target_and_controller_gain_life_spell_v1","controller_gains_life":2,"destination":"graveyard","effect":"remove_permanent","instant":false,"sorcery":true,"target":"land","target_constraints":{"card_types":["land"]},"xmage_effect_classes":["DestroyTargetEffect","GainLifeEffect"]}'::jsonb, '{"category":"removal","effect":"remove_permanent","target":"land"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class DrainTheWell translated into ManaLoom runtime scope xmage_destroy_target_and_controller_gain_life_spell_v1. This row is package-ready only because the source signature is a narrow fixed destroy-target plus controller life-gain spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('grapple with death', 'Grapple with Death', '2b0b7a6ae97fc371def1be151b9f5a9f', 'battle_rule_v1:5ae5bf64faa291c0d09c85d28201a2c2', '{"battle_model_scope":"xmage_destroy_target_and_controller_gain_life_spell_v1","controller_gains_life":1,"destination":"graveyard","effect":"remove_permanent","instant":false,"sorcery":true,"target":"artifact_or_creature","target_constraints":{"card_types":["artifact","creature"]},"xmage_effect_classes":["DestroyTargetEffect","GainLifeEffect"]}'::jsonb, '{"category":"removal","effect":"remove_permanent","target":"artifact_or_creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class GrappleWithDeath translated into ManaLoom runtime scope xmage_destroy_target_and_controller_gain_life_spell_v1. This row is package-ready only because the source signature is a narrow fixed destroy-target plus controller life-gain spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('invoke the divine', 'Invoke the Divine', '1a2e40995c4f7d6463ae7b5ce96cbfe5', 'battle_rule_v1:5d06c51d4005a36bd990d87851d9383c', '{"battle_model_scope":"xmage_destroy_target_and_controller_gain_life_spell_v1","controller_gains_life":4,"destination":"graveyard","effect":"remove_permanent","instant":true,"sorcery":false,"target":"artifact_or_enchantment","target_constraints":{"card_types":["artifact","enchantment"]},"xmage_effect_classes":["DestroyTargetEffect","GainLifeEffect"]}'::jsonb, '{"category":"removal","effect":"remove_permanent","target":"artifact_or_enchantment","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class InvokeTheDivine translated into ManaLoom runtime scope xmage_destroy_target_and_controller_gain_life_spell_v1. This row is package-ready only because the source signature is a narrow fixed destroy-target plus controller life-gain spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('lich''s caress', 'Lich''s Caress', '1f0834667ff74af400f80cd6af6f6f50', 'battle_rule_v1:2151b4f927db86b6035cda9e8968a760', '{"battle_model_scope":"xmage_destroy_target_and_controller_gain_life_spell_v1","controller_gains_life":3,"destination":"graveyard","effect":"remove_creature","instant":false,"sorcery":true,"target":"creature","target_constraints":{"card_types":["creature"]},"xmage_effect_classes":["DestroyTargetEffect","GainLifeEffect"]}'::jsonb, '{"category":"removal","effect":"remove_creature","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class LichsCaress translated into ManaLoom runtime scope xmage_destroy_target_and_controller_gain_life_spell_v1. This row is package-ready only because the source signature is a narrow fixed destroy-target plus controller life-gain spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('maw of the mire', 'Maw of the Mire', 'af7b53f165c85d1baa6e0670e600763d', 'battle_rule_v1:30ecba357ba66148eab77d3cd4e5e9a6', '{"battle_model_scope":"xmage_destroy_target_and_controller_gain_life_spell_v1","controller_gains_life":4,"destination":"graveyard","effect":"remove_permanent","instant":false,"sorcery":true,"target":"land","target_constraints":{"card_types":["land"]},"xmage_effect_classes":["DestroyTargetEffect","GainLifeEffect"]}'::jsonb, '{"category":"removal","effect":"remove_permanent","target":"land"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class MawOfTheMire translated into ManaLoom runtime scope xmage_destroy_target_and_controller_gain_life_spell_v1. This row is package-ready only because the source signature is a narrow fixed destroy-target plus controller life-gain spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('natural end', 'Natural End', 'e2ec7d476fb36a631e6ead5c573d45a2', 'battle_rule_v1:1497fb65812c46c78c5b669ff4989524', '{"battle_model_scope":"xmage_destroy_target_and_controller_gain_life_spell_v1","controller_gains_life":3,"destination":"graveyard","effect":"remove_permanent","instant":true,"sorcery":false,"target":"artifact_or_enchantment","target_constraints":{"card_types":["artifact","enchantment"]},"xmage_effect_classes":["DestroyTargetEffect","GainLifeEffect"]}'::jsonb, '{"category":"removal","effect":"remove_permanent","target":"artifact_or_enchantment","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class NaturalEnd translated into ManaLoom runtime scope xmage_destroy_target_and_controller_gain_life_spell_v1. This row is package-ready only because the source signature is a narrow fixed destroy-target plus controller life-gain spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('ray of dissolution', 'Ray of Dissolution', '3595f82ef93062fd242ae9dc886164c8', 'battle_rule_v1:762898b040728ef22fc560e8c079ec0d', '{"battle_model_scope":"xmage_destroy_target_and_controller_gain_life_spell_v1","controller_gains_life":3,"destination":"graveyard","effect":"remove_permanent","instant":true,"sorcery":false,"target":"enchantment","target_constraints":{"card_types":["enchantment"]},"xmage_effect_classes":["DestroyTargetEffect","GainLifeEffect"]}'::jsonb, '{"category":"removal","effect":"remove_permanent","target":"enchantment","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class RayOfDissolution translated into ManaLoom runtime scope xmage_destroy_target_and_controller_gain_life_spell_v1. This row is package-ready only because the source signature is a narrow fixed destroy-target plus controller life-gain spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('sanctify', 'Sanctify', 'e2ec7d476fb36a631e6ead5c573d45a2', 'battle_rule_v1:2bf2d3a044f5bd1745cbac8a72622f30', '{"battle_model_scope":"xmage_destroy_target_and_controller_gain_life_spell_v1","controller_gains_life":3,"destination":"graveyard","effect":"remove_permanent","instant":false,"sorcery":true,"target":"artifact_or_enchantment","target_constraints":{"card_types":["artifact","enchantment"]},"xmage_effect_classes":["DestroyTargetEffect","GainLifeEffect"]}'::jsonb, '{"category":"removal","effect":"remove_permanent","target":"artifact_or_enchantment"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Sanctify translated into ManaLoom runtime scope xmage_destroy_target_and_controller_gain_life_spell_v1. This row is package-ready only because the source signature is a narrow fixed destroy-target plus controller life-gain spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('sephiroth''s intervention', 'Sephiroth''s Intervention', '2dffcc424019a833cb2851580aa3694b', 'battle_rule_v1:eeb274765267ef2873eb0b196c027df8', '{"battle_model_scope":"xmage_destroy_target_and_controller_gain_life_spell_v1","controller_gains_life":2,"destination":"graveyard","effect":"remove_creature","instant":true,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"]},"xmage_effect_classes":["DestroyTargetEffect","GainLifeEffect"]}'::jsonb, '{"category":"removal","effect":"remove_creature","target":"creature","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class SephirothsIntervention translated into ManaLoom runtime scope xmage_destroy_target_and_controller_gain_life_spell_v1. This row is package-ready only because the source signature is a narrow fixed destroy-target plus controller life-gain spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('solemn offering', 'Solemn Offering', '1a2e40995c4f7d6463ae7b5ce96cbfe5', 'battle_rule_v1:a3ed89e31c22fb41043599139d0632cd', '{"battle_model_scope":"xmage_destroy_target_and_controller_gain_life_spell_v1","controller_gains_life":4,"destination":"graveyard","effect":"remove_permanent","instant":false,"sorcery":true,"target":"artifact_or_enchantment","target_constraints":{"card_types":["artifact","enchantment"]},"xmage_effect_classes":["DestroyTargetEffect","GainLifeEffect"]}'::jsonb, '{"category":"removal","effect":"remove_permanent","target":"artifact_or_enchantment"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class SolemnOffering translated into ManaLoom runtime scope xmage_destroy_target_and_controller_gain_life_spell_v1. This row is package-ready only because the source signature is a narrow fixed destroy-target plus controller life-gain spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('springsage ritual', 'Springsage Ritual', '1a2e40995c4f7d6463ae7b5ce96cbfe5', 'battle_rule_v1:5d06c51d4005a36bd990d87851d9383c', '{"battle_model_scope":"xmage_destroy_target_and_controller_gain_life_spell_v1","controller_gains_life":4,"destination":"graveyard","effect":"remove_permanent","instant":true,"sorcery":false,"target":"artifact_or_enchantment","target_constraints":{"card_types":["artifact","enchantment"]},"xmage_effect_classes":["DestroyTargetEffect","GainLifeEffect"]}'::jsonb, '{"category":"removal","effect":"remove_permanent","target":"artifact_or_enchantment","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class SpringsageRitual translated into ManaLoom runtime scope xmage_destroy_target_and_controller_gain_life_spell_v1. This row is package-ready only because the source signature is a narrow fixed destroy-target plus controller life-gain spell with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
    ('appetite for the unnatural', 'Appetite for the Unnatural', 'ff2701341e046cdb32db1fd2d24193f3', 'battle_rule_v1:f25f7f032c8935a2725f03e806412108', '{"battle_model_scope":"xmage_destroy_target_and_controller_gain_life_spell_v1","controller_gains_life":2,"destination":"graveyard","effect":"remove_permanent","instant":true,"sorcery":false,"target":"artifact_or_enchantment","target_constraints":{"card_types":["artifact","enchantment"]},"xmage_effect_classes":["DestroyTargetEffect","GainLifeEffect"]}'::jsonb, '{"category":"removal","effect":"remove_permanent","target":"artifact_or_enchantment","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class AppetiteForTheUnnatural translated into ManaLoom runtime scope xmage_destroy_target_and_controller_gain_life_spell_v1. This row is package-ready only because the source signature is a narrow fixed destroy-target plus controller life-gain spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('cursebreak', 'Cursebreak', 'e8b18bd9c5e41964bd056a95a9599ba6', 'battle_rule_v1:eac90831bff0a6d7d8cc7f79c84dc684', '{"battle_model_scope":"xmage_destroy_target_and_controller_gain_life_spell_v1","controller_gains_life":2,"destination":"graveyard","effect":"remove_permanent","instant":true,"sorcery":false,"target":"enchantment","target_constraints":{"card_types":["enchantment"]},"xmage_effect_classes":["DestroyTargetEffect","GainLifeEffect"]}'::jsonb, '{"category":"removal","effect":"remove_permanent","target":"enchantment","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Cursebreak translated into ManaLoom runtime scope xmage_destroy_target_and_controller_gain_life_spell_v1. This row is package-ready only because the source signature is a narrow fixed destroy-target plus controller life-gain spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('drain the well', 'Drain the Well', 'a83cde4e874b76b73ec6952b980c5a5d', 'battle_rule_v1:8c113d532b53977905ddd6205d20b76b', '{"battle_model_scope":"xmage_destroy_target_and_controller_gain_life_spell_v1","controller_gains_life":2,"destination":"graveyard","effect":"remove_permanent","instant":false,"sorcery":true,"target":"land","target_constraints":{"card_types":["land"]},"xmage_effect_classes":["DestroyTargetEffect","GainLifeEffect"]}'::jsonb, '{"category":"removal","effect":"remove_permanent","target":"land"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class DrainTheWell translated into ManaLoom runtime scope xmage_destroy_target_and_controller_gain_life_spell_v1. This row is package-ready only because the source signature is a narrow fixed destroy-target plus controller life-gain spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('grapple with death', 'Grapple with Death', '2b0b7a6ae97fc371def1be151b9f5a9f', 'battle_rule_v1:5ae5bf64faa291c0d09c85d28201a2c2', '{"battle_model_scope":"xmage_destroy_target_and_controller_gain_life_spell_v1","controller_gains_life":1,"destination":"graveyard","effect":"remove_permanent","instant":false,"sorcery":true,"target":"artifact_or_creature","target_constraints":{"card_types":["artifact","creature"]},"xmage_effect_classes":["DestroyTargetEffect","GainLifeEffect"]}'::jsonb, '{"category":"removal","effect":"remove_permanent","target":"artifact_or_creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class GrappleWithDeath translated into ManaLoom runtime scope xmage_destroy_target_and_controller_gain_life_spell_v1. This row is package-ready only because the source signature is a narrow fixed destroy-target plus controller life-gain spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('invoke the divine', 'Invoke the Divine', '1a2e40995c4f7d6463ae7b5ce96cbfe5', 'battle_rule_v1:5d06c51d4005a36bd990d87851d9383c', '{"battle_model_scope":"xmage_destroy_target_and_controller_gain_life_spell_v1","controller_gains_life":4,"destination":"graveyard","effect":"remove_permanent","instant":true,"sorcery":false,"target":"artifact_or_enchantment","target_constraints":{"card_types":["artifact","enchantment"]},"xmage_effect_classes":["DestroyTargetEffect","GainLifeEffect"]}'::jsonb, '{"category":"removal","effect":"remove_permanent","target":"artifact_or_enchantment","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class InvokeTheDivine translated into ManaLoom runtime scope xmage_destroy_target_and_controller_gain_life_spell_v1. This row is package-ready only because the source signature is a narrow fixed destroy-target plus controller life-gain spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('lich''s caress', 'Lich''s Caress', '1f0834667ff74af400f80cd6af6f6f50', 'battle_rule_v1:2151b4f927db86b6035cda9e8968a760', '{"battle_model_scope":"xmage_destroy_target_and_controller_gain_life_spell_v1","controller_gains_life":3,"destination":"graveyard","effect":"remove_creature","instant":false,"sorcery":true,"target":"creature","target_constraints":{"card_types":["creature"]},"xmage_effect_classes":["DestroyTargetEffect","GainLifeEffect"]}'::jsonb, '{"category":"removal","effect":"remove_creature","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class LichsCaress translated into ManaLoom runtime scope xmage_destroy_target_and_controller_gain_life_spell_v1. This row is package-ready only because the source signature is a narrow fixed destroy-target plus controller life-gain spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('maw of the mire', 'Maw of the Mire', 'af7b53f165c85d1baa6e0670e600763d', 'battle_rule_v1:30ecba357ba66148eab77d3cd4e5e9a6', '{"battle_model_scope":"xmage_destroy_target_and_controller_gain_life_spell_v1","controller_gains_life":4,"destination":"graveyard","effect":"remove_permanent","instant":false,"sorcery":true,"target":"land","target_constraints":{"card_types":["land"]},"xmage_effect_classes":["DestroyTargetEffect","GainLifeEffect"]}'::jsonb, '{"category":"removal","effect":"remove_permanent","target":"land"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class MawOfTheMire translated into ManaLoom runtime scope xmage_destroy_target_and_controller_gain_life_spell_v1. This row is package-ready only because the source signature is a narrow fixed destroy-target plus controller life-gain spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('natural end', 'Natural End', 'e2ec7d476fb36a631e6ead5c573d45a2', 'battle_rule_v1:1497fb65812c46c78c5b669ff4989524', '{"battle_model_scope":"xmage_destroy_target_and_controller_gain_life_spell_v1","controller_gains_life":3,"destination":"graveyard","effect":"remove_permanent","instant":true,"sorcery":false,"target":"artifact_or_enchantment","target_constraints":{"card_types":["artifact","enchantment"]},"xmage_effect_classes":["DestroyTargetEffect","GainLifeEffect"]}'::jsonb, '{"category":"removal","effect":"remove_permanent","target":"artifact_or_enchantment","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class NaturalEnd translated into ManaLoom runtime scope xmage_destroy_target_and_controller_gain_life_spell_v1. This row is package-ready only because the source signature is a narrow fixed destroy-target plus controller life-gain spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('ray of dissolution', 'Ray of Dissolution', '3595f82ef93062fd242ae9dc886164c8', 'battle_rule_v1:762898b040728ef22fc560e8c079ec0d', '{"battle_model_scope":"xmage_destroy_target_and_controller_gain_life_spell_v1","controller_gains_life":3,"destination":"graveyard","effect":"remove_permanent","instant":true,"sorcery":false,"target":"enchantment","target_constraints":{"card_types":["enchantment"]},"xmage_effect_classes":["DestroyTargetEffect","GainLifeEffect"]}'::jsonb, '{"category":"removal","effect":"remove_permanent","target":"enchantment","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class RayOfDissolution translated into ManaLoom runtime scope xmage_destroy_target_and_controller_gain_life_spell_v1. This row is package-ready only because the source signature is a narrow fixed destroy-target plus controller life-gain spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('sanctify', 'Sanctify', 'e2ec7d476fb36a631e6ead5c573d45a2', 'battle_rule_v1:2bf2d3a044f5bd1745cbac8a72622f30', '{"battle_model_scope":"xmage_destroy_target_and_controller_gain_life_spell_v1","controller_gains_life":3,"destination":"graveyard","effect":"remove_permanent","instant":false,"sorcery":true,"target":"artifact_or_enchantment","target_constraints":{"card_types":["artifact","enchantment"]},"xmage_effect_classes":["DestroyTargetEffect","GainLifeEffect"]}'::jsonb, '{"category":"removal","effect":"remove_permanent","target":"artifact_or_enchantment"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Sanctify translated into ManaLoom runtime scope xmage_destroy_target_and_controller_gain_life_spell_v1. This row is package-ready only because the source signature is a narrow fixed destroy-target plus controller life-gain spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('sephiroth''s intervention', 'Sephiroth''s Intervention', '2dffcc424019a833cb2851580aa3694b', 'battle_rule_v1:eeb274765267ef2873eb0b196c027df8', '{"battle_model_scope":"xmage_destroy_target_and_controller_gain_life_spell_v1","controller_gains_life":2,"destination":"graveyard","effect":"remove_creature","instant":true,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"]},"xmage_effect_classes":["DestroyTargetEffect","GainLifeEffect"]}'::jsonb, '{"category":"removal","effect":"remove_creature","target":"creature","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class SephirothsIntervention translated into ManaLoom runtime scope xmage_destroy_target_and_controller_gain_life_spell_v1. This row is package-ready only because the source signature is a narrow fixed destroy-target plus controller life-gain spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('solemn offering', 'Solemn Offering', '1a2e40995c4f7d6463ae7b5ce96cbfe5', 'battle_rule_v1:a3ed89e31c22fb41043599139d0632cd', '{"battle_model_scope":"xmage_destroy_target_and_controller_gain_life_spell_v1","controller_gains_life":4,"destination":"graveyard","effect":"remove_permanent","instant":false,"sorcery":true,"target":"artifact_or_enchantment","target_constraints":{"card_types":["artifact","enchantment"]},"xmage_effect_classes":["DestroyTargetEffect","GainLifeEffect"]}'::jsonb, '{"category":"removal","effect":"remove_permanent","target":"artifact_or_enchantment"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class SolemnOffering translated into ManaLoom runtime scope xmage_destroy_target_and_controller_gain_life_spell_v1. This row is package-ready only because the source signature is a narrow fixed destroy-target plus controller life-gain spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('springsage ritual', 'Springsage Ritual', '1a2e40995c4f7d6463ae7b5ce96cbfe5', 'battle_rule_v1:5d06c51d4005a36bd990d87851d9383c', '{"battle_model_scope":"xmage_destroy_target_and_controller_gain_life_spell_v1","controller_gains_life":4,"destination":"graveyard","effect":"remove_permanent","instant":true,"sorcery":false,"target":"artifact_or_enchantment","target_constraints":{"card_types":["artifact","enchantment"]},"xmage_effect_classes":["DestroyTargetEffect","GainLifeEffect"]}'::jsonb, '{"category":"removal","effect":"remove_permanent","target":"artifact_or_enchantment","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class SpringsageRitual translated into ManaLoom runtime scope xmage_destroy_target_and_controller_gain_life_spell_v1. This row is package-ready only because the source signature is a narrow fixed destroy-target plus controller life-gain spell with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
