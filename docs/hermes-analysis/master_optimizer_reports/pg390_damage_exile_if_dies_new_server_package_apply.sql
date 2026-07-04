BEGIN;

CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit;

CREATE TABLE manaloom_deploy_audit.pg390_damage_exile_if_dies_new_server_package_20260704_0 AS
SELECT *
FROM public.card_battle_rules
WHERE normalized_name IN ('bot bashing time', 'elspeth''s smite', 'fanged flames', 'feed the flames', 'flame-blessed bolt', 'lava coil', 'magma spray', 'obliterating bolt', 'puncturing blow', 'reduce to ashes', 'scorching dragonfire', 'scorchmark')
   OR normalized_name LIKE 'bot bashing time // %'
   OR normalized_name LIKE 'elspeth''s smite // %'
   OR normalized_name LIKE 'fanged flames // %'
   OR normalized_name LIKE 'feed the flames // %'
   OR normalized_name LIKE 'flame-blessed bolt // %'
   OR normalized_name LIKE 'lava coil // %'
   OR normalized_name LIKE 'magma spray // %'
   OR normalized_name LIKE 'obliterating bolt // %'
   OR normalized_name LIKE 'puncturing blow // %'
   OR normalized_name LIKE 'reduce to ashes // %'
   OR normalized_name LIKE 'scorching dragonfire // %'
   OR normalized_name LIKE 'scorchmark // %';

DO $$
DECLARE
  v_missing jsonb;
BEGIN
  WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('bot bashing time', 'Bot Bashing Time', '67e437e3a8187ee229930b0ab1612a84', 'battle_rule_v1:a7da533e49853cbf8e4a5b43631bf2fc', '{"amount":6,"battle_model_scope":"xmage_fixed_damage_target_exile_if_dies_spell_v1","damage":6,"effect":"direct_damage","exile_if_dies_from_damage":true,"exile_if_dies_target":"creature","instant":false,"sorcery":true,"target":"creature","target_constraints":{"card_types":["creature"]},"xmage_effect_classes":["DamageTargetEffect","ExileTargetIfDiesEffect"]}'::jsonb, '{"category":"unknown","effect":"direct_damage","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class BotBashingTime translated into ManaLoom runtime scope xmage_fixed_damage_target_exile_if_dies_spell_v1. This row is package-ready only because the source signature is a narrow fixed damage spell with exile-if-dies replacement with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('elspeth''s smite', 'Elspeth''s Smite', '34755e1be497b61da78f77e5861b6822', 'battle_rule_v1:6a9e2c540e2ef67377d637edfb05cee1', '{"amount":3,"battle_model_scope":"xmage_fixed_damage_target_exile_if_dies_spell_v1","damage":3,"effect":"direct_damage","exile_if_dies_from_damage":true,"exile_if_dies_target":"creature","instant":true,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"],"combat_state":"attacking_or_blocking"},"xmage_effect_classes":["DamageTargetEffect","ExileTargetIfDiesEffect"]}'::jsonb, '{"category":"unknown","effect":"direct_damage","target":"creature","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ElspethsSmite translated into ManaLoom runtime scope xmage_fixed_damage_target_exile_if_dies_spell_v1. This row is package-ready only because the source signature is a narrow fixed damage spell with exile-if-dies replacement with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('fanged flames', 'Fanged Flames', 'cbdcc5f559e76ddb1fba7a8c49b95588', 'battle_rule_v1:0b23905863b021edd3a97ba78bfb32ca', '{"amount":4,"battle_model_scope":"xmage_fixed_damage_target_exile_if_dies_spell_v1","damage":4,"effect":"direct_damage","exile_if_dies_from_damage":true,"exile_if_dies_target":"creature_or_planeswalker","instant":false,"sorcery":true,"target":"creature_or_planeswalker","target_constraints":{"card_types":["creature","planeswalker"]},"xmage_effect_classes":["DamageTargetEffect","ExileTargetIfDiesEffect"]}'::jsonb, '{"category":"unknown","effect":"direct_damage","target":"creature_or_planeswalker"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class FangedFlames translated into ManaLoom runtime scope xmage_fixed_damage_target_exile_if_dies_spell_v1. This row is package-ready only because the source signature is a narrow fixed damage spell with exile-if-dies replacement with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('feed the flames', 'Feed the Flames', '71bae3916a02f627931b86fbc2bc7c26', 'battle_rule_v1:4f3ea4eabca25c95c2525886a0c65a9c', '{"amount":5,"battle_model_scope":"xmage_fixed_damage_target_exile_if_dies_spell_v1","damage":5,"effect":"direct_damage","exile_if_dies_from_damage":true,"exile_if_dies_target":"creature","instant":true,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"]},"xmage_effect_classes":["DamageTargetEffect","ExileTargetIfDiesEffect"]}'::jsonb, '{"category":"unknown","effect":"direct_damage","target":"creature","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class FeedTheFlames translated into ManaLoom runtime scope xmage_fixed_damage_target_exile_if_dies_spell_v1. This row is package-ready only because the source signature is a narrow fixed damage spell with exile-if-dies replacement with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('flame-blessed bolt', 'Flame-Blessed Bolt', '8c29d5792a7c71d3debe5d3f9e06bbde', 'battle_rule_v1:0260a8c11989a2b8375c4717dc6b3361', '{"amount":2,"battle_model_scope":"xmage_fixed_damage_target_exile_if_dies_spell_v1","damage":2,"effect":"direct_damage","exile_if_dies_from_damage":true,"exile_if_dies_target":"creature_or_planeswalker","instant":true,"sorcery":false,"target":"creature_or_planeswalker","target_constraints":{"card_types":["creature","planeswalker"]},"xmage_effect_classes":["DamageTargetEffect","ExileTargetIfDiesEffect"]}'::jsonb, '{"category":"unknown","effect":"direct_damage","target":"creature_or_planeswalker","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class FlameBlessedBolt translated into ManaLoom runtime scope xmage_fixed_damage_target_exile_if_dies_spell_v1. This row is package-ready only because the source signature is a narrow fixed damage spell with exile-if-dies replacement with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('lava coil', 'Lava Coil', 'b5658f51fc5b9f2a86c0302c7665a0c4', 'battle_rule_v1:00f072b0c13f2f6710f402ff7cf15fc8', '{"amount":4,"battle_model_scope":"xmage_fixed_damage_target_exile_if_dies_spell_v1","damage":4,"effect":"direct_damage","exile_if_dies_from_damage":true,"exile_if_dies_target":"creature","instant":false,"sorcery":true,"target":"creature","target_constraints":{"card_types":["creature"]},"xmage_effect_classes":["DamageTargetEffect","ExileTargetIfDiesEffect"]}'::jsonb, '{"category":"unknown","effect":"direct_damage","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class LavaCoil translated into ManaLoom runtime scope xmage_fixed_damage_target_exile_if_dies_spell_v1. This row is package-ready only because the source signature is a narrow fixed damage spell with exile-if-dies replacement with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('magma spray', 'Magma Spray', '76241ca8f5ff7d8bad5c0771650321d3', 'battle_rule_v1:001df6fe0862f863a88aa1fc27841a74', '{"amount":2,"battle_model_scope":"xmage_fixed_damage_target_exile_if_dies_spell_v1","damage":2,"effect":"direct_damage","exile_if_dies_from_damage":true,"exile_if_dies_target":"creature","instant":true,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"]},"xmage_effect_classes":["DamageTargetEffect","ExileTargetIfDiesEffect"]}'::jsonb, '{"category":"unknown","effect":"direct_damage","target":"creature","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class MagmaSpray translated into ManaLoom runtime scope xmage_fixed_damage_target_exile_if_dies_spell_v1. This row is package-ready only because the source signature is a narrow fixed damage spell with exile-if-dies replacement with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('obliterating bolt', 'Obliterating Bolt', '52fbf2ba566570f29f83416740b783f9', 'battle_rule_v1:0b23905863b021edd3a97ba78bfb32ca', '{"amount":4,"battle_model_scope":"xmage_fixed_damage_target_exile_if_dies_spell_v1","damage":4,"effect":"direct_damage","exile_if_dies_from_damage":true,"exile_if_dies_target":"creature_or_planeswalker","instant":false,"sorcery":true,"target":"creature_or_planeswalker","target_constraints":{"card_types":["creature","planeswalker"]},"xmage_effect_classes":["DamageTargetEffect","ExileTargetIfDiesEffect"]}'::jsonb, '{"category":"unknown","effect":"direct_damage","target":"creature_or_planeswalker"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ObliteratingBolt translated into ManaLoom runtime scope xmage_fixed_damage_target_exile_if_dies_spell_v1. This row is package-ready only because the source signature is a narrow fixed damage spell with exile-if-dies replacement with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('puncturing blow', 'Puncturing Blow', 'dbf801bc943efd39819ea09ff4897a36', 'battle_rule_v1:591bd8909ef06dcc4127e24b0d952e7d', '{"amount":5,"battle_model_scope":"xmage_fixed_damage_target_exile_if_dies_spell_v1","damage":5,"effect":"direct_damage","exile_if_dies_from_damage":true,"exile_if_dies_target":"creature","instant":false,"sorcery":true,"target":"creature","target_constraints":{"card_types":["creature"]},"xmage_effect_classes":["DamageTargetEffect","ExileTargetIfDiesEffect"]}'::jsonb, '{"category":"unknown","effect":"direct_damage","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class PuncturingBlow translated into ManaLoom runtime scope xmage_fixed_damage_target_exile_if_dies_spell_v1. This row is package-ready only because the source signature is a narrow fixed damage spell with exile-if-dies replacement with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('reduce to ashes', 'Reduce to Ashes', '53e679871c65ac7ce23f480a6cc58fe4', 'battle_rule_v1:591bd8909ef06dcc4127e24b0d952e7d', '{"amount":5,"battle_model_scope":"xmage_fixed_damage_target_exile_if_dies_spell_v1","damage":5,"effect":"direct_damage","exile_if_dies_from_damage":true,"exile_if_dies_target":"creature","instant":false,"sorcery":true,"target":"creature","target_constraints":{"card_types":["creature"]},"xmage_effect_classes":["DamageTargetEffect","ExileTargetIfDiesEffect"]}'::jsonb, '{"category":"unknown","effect":"direct_damage","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ReduceToAshes translated into ManaLoom runtime scope xmage_fixed_damage_target_exile_if_dies_spell_v1. This row is package-ready only because the source signature is a narrow fixed damage spell with exile-if-dies replacement with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('scorching dragonfire', 'Scorching Dragonfire', 'eb4b58cb260c7ed83fb61f407f095f88', 'battle_rule_v1:d8158e4630695dfb123c559adf5c6669', '{"amount":3,"battle_model_scope":"xmage_fixed_damage_target_exile_if_dies_spell_v1","damage":3,"effect":"direct_damage","exile_if_dies_from_damage":true,"exile_if_dies_target":"creature_or_planeswalker","instant":true,"sorcery":false,"target":"creature_or_planeswalker","target_constraints":{"card_types":["creature","planeswalker"]},"xmage_effect_classes":["DamageTargetEffect","ExileTargetIfDiesEffect"]}'::jsonb, '{"category":"unknown","effect":"direct_damage","target":"creature_or_planeswalker","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ScorchingDragonfire translated into ManaLoom runtime scope xmage_fixed_damage_target_exile_if_dies_spell_v1. This row is package-ready only because the source signature is a narrow fixed damage spell with exile-if-dies replacement with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('scorchmark', 'Scorchmark', '4e2b75865e1ef6c6a3a22a3e70cc4342', 'battle_rule_v1:001df6fe0862f863a88aa1fc27841a74', '{"amount":2,"battle_model_scope":"xmage_fixed_damage_target_exile_if_dies_spell_v1","damage":2,"effect":"direct_damage","exile_if_dies_from_damage":true,"exile_if_dies_target":"creature","instant":true,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"]},"xmage_effect_classes":["DamageTargetEffect","ExileTargetIfDiesEffect"]}'::jsonb, '{"category":"unknown","effect":"direct_damage","target":"creature","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Scorchmark translated into ManaLoom runtime scope xmage_fixed_damage_target_exile_if_dies_spell_v1. This row is package-ready only because the source signature is a narrow fixed damage spell with exile-if-dies replacement with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
    ('bot bashing time', 'Bot Bashing Time', '67e437e3a8187ee229930b0ab1612a84', 'battle_rule_v1:a7da533e49853cbf8e4a5b43631bf2fc', '{"amount":6,"battle_model_scope":"xmage_fixed_damage_target_exile_if_dies_spell_v1","damage":6,"effect":"direct_damage","exile_if_dies_from_damage":true,"exile_if_dies_target":"creature","instant":false,"sorcery":true,"target":"creature","target_constraints":{"card_types":["creature"]},"xmage_effect_classes":["DamageTargetEffect","ExileTargetIfDiesEffect"]}'::jsonb, '{"category":"unknown","effect":"direct_damage","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class BotBashingTime translated into ManaLoom runtime scope xmage_fixed_damage_target_exile_if_dies_spell_v1. This row is package-ready only because the source signature is a narrow fixed damage spell with exile-if-dies replacement with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('elspeth''s smite', 'Elspeth''s Smite', '34755e1be497b61da78f77e5861b6822', 'battle_rule_v1:6a9e2c540e2ef67377d637edfb05cee1', '{"amount":3,"battle_model_scope":"xmage_fixed_damage_target_exile_if_dies_spell_v1","damage":3,"effect":"direct_damage","exile_if_dies_from_damage":true,"exile_if_dies_target":"creature","instant":true,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"],"combat_state":"attacking_or_blocking"},"xmage_effect_classes":["DamageTargetEffect","ExileTargetIfDiesEffect"]}'::jsonb, '{"category":"unknown","effect":"direct_damage","target":"creature","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ElspethsSmite translated into ManaLoom runtime scope xmage_fixed_damage_target_exile_if_dies_spell_v1. This row is package-ready only because the source signature is a narrow fixed damage spell with exile-if-dies replacement with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('fanged flames', 'Fanged Flames', 'cbdcc5f559e76ddb1fba7a8c49b95588', 'battle_rule_v1:0b23905863b021edd3a97ba78bfb32ca', '{"amount":4,"battle_model_scope":"xmage_fixed_damage_target_exile_if_dies_spell_v1","damage":4,"effect":"direct_damage","exile_if_dies_from_damage":true,"exile_if_dies_target":"creature_or_planeswalker","instant":false,"sorcery":true,"target":"creature_or_planeswalker","target_constraints":{"card_types":["creature","planeswalker"]},"xmage_effect_classes":["DamageTargetEffect","ExileTargetIfDiesEffect"]}'::jsonb, '{"category":"unknown","effect":"direct_damage","target":"creature_or_planeswalker"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class FangedFlames translated into ManaLoom runtime scope xmage_fixed_damage_target_exile_if_dies_spell_v1. This row is package-ready only because the source signature is a narrow fixed damage spell with exile-if-dies replacement with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('feed the flames', 'Feed the Flames', '71bae3916a02f627931b86fbc2bc7c26', 'battle_rule_v1:4f3ea4eabca25c95c2525886a0c65a9c', '{"amount":5,"battle_model_scope":"xmage_fixed_damage_target_exile_if_dies_spell_v1","damage":5,"effect":"direct_damage","exile_if_dies_from_damage":true,"exile_if_dies_target":"creature","instant":true,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"]},"xmage_effect_classes":["DamageTargetEffect","ExileTargetIfDiesEffect"]}'::jsonb, '{"category":"unknown","effect":"direct_damage","target":"creature","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class FeedTheFlames translated into ManaLoom runtime scope xmage_fixed_damage_target_exile_if_dies_spell_v1. This row is package-ready only because the source signature is a narrow fixed damage spell with exile-if-dies replacement with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('flame-blessed bolt', 'Flame-Blessed Bolt', '8c29d5792a7c71d3debe5d3f9e06bbde', 'battle_rule_v1:0260a8c11989a2b8375c4717dc6b3361', '{"amount":2,"battle_model_scope":"xmage_fixed_damage_target_exile_if_dies_spell_v1","damage":2,"effect":"direct_damage","exile_if_dies_from_damage":true,"exile_if_dies_target":"creature_or_planeswalker","instant":true,"sorcery":false,"target":"creature_or_planeswalker","target_constraints":{"card_types":["creature","planeswalker"]},"xmage_effect_classes":["DamageTargetEffect","ExileTargetIfDiesEffect"]}'::jsonb, '{"category":"unknown","effect":"direct_damage","target":"creature_or_planeswalker","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class FlameBlessedBolt translated into ManaLoom runtime scope xmage_fixed_damage_target_exile_if_dies_spell_v1. This row is package-ready only because the source signature is a narrow fixed damage spell with exile-if-dies replacement with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('lava coil', 'Lava Coil', 'b5658f51fc5b9f2a86c0302c7665a0c4', 'battle_rule_v1:00f072b0c13f2f6710f402ff7cf15fc8', '{"amount":4,"battle_model_scope":"xmage_fixed_damage_target_exile_if_dies_spell_v1","damage":4,"effect":"direct_damage","exile_if_dies_from_damage":true,"exile_if_dies_target":"creature","instant":false,"sorcery":true,"target":"creature","target_constraints":{"card_types":["creature"]},"xmage_effect_classes":["DamageTargetEffect","ExileTargetIfDiesEffect"]}'::jsonb, '{"category":"unknown","effect":"direct_damage","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class LavaCoil translated into ManaLoom runtime scope xmage_fixed_damage_target_exile_if_dies_spell_v1. This row is package-ready only because the source signature is a narrow fixed damage spell with exile-if-dies replacement with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('magma spray', 'Magma Spray', '76241ca8f5ff7d8bad5c0771650321d3', 'battle_rule_v1:001df6fe0862f863a88aa1fc27841a74', '{"amount":2,"battle_model_scope":"xmage_fixed_damage_target_exile_if_dies_spell_v1","damage":2,"effect":"direct_damage","exile_if_dies_from_damage":true,"exile_if_dies_target":"creature","instant":true,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"]},"xmage_effect_classes":["DamageTargetEffect","ExileTargetIfDiesEffect"]}'::jsonb, '{"category":"unknown","effect":"direct_damage","target":"creature","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class MagmaSpray translated into ManaLoom runtime scope xmage_fixed_damage_target_exile_if_dies_spell_v1. This row is package-ready only because the source signature is a narrow fixed damage spell with exile-if-dies replacement with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('obliterating bolt', 'Obliterating Bolt', '52fbf2ba566570f29f83416740b783f9', 'battle_rule_v1:0b23905863b021edd3a97ba78bfb32ca', '{"amount":4,"battle_model_scope":"xmage_fixed_damage_target_exile_if_dies_spell_v1","damage":4,"effect":"direct_damage","exile_if_dies_from_damage":true,"exile_if_dies_target":"creature_or_planeswalker","instant":false,"sorcery":true,"target":"creature_or_planeswalker","target_constraints":{"card_types":["creature","planeswalker"]},"xmage_effect_classes":["DamageTargetEffect","ExileTargetIfDiesEffect"]}'::jsonb, '{"category":"unknown","effect":"direct_damage","target":"creature_or_planeswalker"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ObliteratingBolt translated into ManaLoom runtime scope xmage_fixed_damage_target_exile_if_dies_spell_v1. This row is package-ready only because the source signature is a narrow fixed damage spell with exile-if-dies replacement with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('puncturing blow', 'Puncturing Blow', 'dbf801bc943efd39819ea09ff4897a36', 'battle_rule_v1:591bd8909ef06dcc4127e24b0d952e7d', '{"amount":5,"battle_model_scope":"xmage_fixed_damage_target_exile_if_dies_spell_v1","damage":5,"effect":"direct_damage","exile_if_dies_from_damage":true,"exile_if_dies_target":"creature","instant":false,"sorcery":true,"target":"creature","target_constraints":{"card_types":["creature"]},"xmage_effect_classes":["DamageTargetEffect","ExileTargetIfDiesEffect"]}'::jsonb, '{"category":"unknown","effect":"direct_damage","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class PuncturingBlow translated into ManaLoom runtime scope xmage_fixed_damage_target_exile_if_dies_spell_v1. This row is package-ready only because the source signature is a narrow fixed damage spell with exile-if-dies replacement with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('reduce to ashes', 'Reduce to Ashes', '53e679871c65ac7ce23f480a6cc58fe4', 'battle_rule_v1:591bd8909ef06dcc4127e24b0d952e7d', '{"amount":5,"battle_model_scope":"xmage_fixed_damage_target_exile_if_dies_spell_v1","damage":5,"effect":"direct_damage","exile_if_dies_from_damage":true,"exile_if_dies_target":"creature","instant":false,"sorcery":true,"target":"creature","target_constraints":{"card_types":["creature"]},"xmage_effect_classes":["DamageTargetEffect","ExileTargetIfDiesEffect"]}'::jsonb, '{"category":"unknown","effect":"direct_damage","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ReduceToAshes translated into ManaLoom runtime scope xmage_fixed_damage_target_exile_if_dies_spell_v1. This row is package-ready only because the source signature is a narrow fixed damage spell with exile-if-dies replacement with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('scorching dragonfire', 'Scorching Dragonfire', 'eb4b58cb260c7ed83fb61f407f095f88', 'battle_rule_v1:d8158e4630695dfb123c559adf5c6669', '{"amount":3,"battle_model_scope":"xmage_fixed_damage_target_exile_if_dies_spell_v1","damage":3,"effect":"direct_damage","exile_if_dies_from_damage":true,"exile_if_dies_target":"creature_or_planeswalker","instant":true,"sorcery":false,"target":"creature_or_planeswalker","target_constraints":{"card_types":["creature","planeswalker"]},"xmage_effect_classes":["DamageTargetEffect","ExileTargetIfDiesEffect"]}'::jsonb, '{"category":"unknown","effect":"direct_damage","target":"creature_or_planeswalker","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ScorchingDragonfire translated into ManaLoom runtime scope xmage_fixed_damage_target_exile_if_dies_spell_v1. This row is package-ready only because the source signature is a narrow fixed damage spell with exile-if-dies replacement with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('scorchmark', 'Scorchmark', '4e2b75865e1ef6c6a3a22a3e70cc4342', 'battle_rule_v1:001df6fe0862f863a88aa1fc27841a74', '{"amount":2,"battle_model_scope":"xmage_fixed_damage_target_exile_if_dies_spell_v1","damage":2,"effect":"direct_damage","exile_if_dies_from_damage":true,"exile_if_dies_target":"creature","instant":true,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"]},"xmage_effect_classes":["DamageTargetEffect","ExileTargetIfDiesEffect"]}'::jsonb, '{"category":"unknown","effect":"direct_damage","target":"creature","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Scorchmark translated into ManaLoom runtime scope xmage_fixed_damage_target_exile_if_dies_spell_v1. This row is package-ready only because the source signature is a narrow fixed damage spell with exile-if-dies replacement with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
    ('bot bashing time', 'Bot Bashing Time', '67e437e3a8187ee229930b0ab1612a84', 'battle_rule_v1:a7da533e49853cbf8e4a5b43631bf2fc', '{"amount":6,"battle_model_scope":"xmage_fixed_damage_target_exile_if_dies_spell_v1","damage":6,"effect":"direct_damage","exile_if_dies_from_damage":true,"exile_if_dies_target":"creature","instant":false,"sorcery":true,"target":"creature","target_constraints":{"card_types":["creature"]},"xmage_effect_classes":["DamageTargetEffect","ExileTargetIfDiesEffect"]}'::jsonb, '{"category":"unknown","effect":"direct_damage","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class BotBashingTime translated into ManaLoom runtime scope xmage_fixed_damage_target_exile_if_dies_spell_v1. This row is package-ready only because the source signature is a narrow fixed damage spell with exile-if-dies replacement with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('elspeth''s smite', 'Elspeth''s Smite', '34755e1be497b61da78f77e5861b6822', 'battle_rule_v1:6a9e2c540e2ef67377d637edfb05cee1', '{"amount":3,"battle_model_scope":"xmage_fixed_damage_target_exile_if_dies_spell_v1","damage":3,"effect":"direct_damage","exile_if_dies_from_damage":true,"exile_if_dies_target":"creature","instant":true,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"],"combat_state":"attacking_or_blocking"},"xmage_effect_classes":["DamageTargetEffect","ExileTargetIfDiesEffect"]}'::jsonb, '{"category":"unknown","effect":"direct_damage","target":"creature","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ElspethsSmite translated into ManaLoom runtime scope xmage_fixed_damage_target_exile_if_dies_spell_v1. This row is package-ready only because the source signature is a narrow fixed damage spell with exile-if-dies replacement with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('fanged flames', 'Fanged Flames', 'cbdcc5f559e76ddb1fba7a8c49b95588', 'battle_rule_v1:0b23905863b021edd3a97ba78bfb32ca', '{"amount":4,"battle_model_scope":"xmage_fixed_damage_target_exile_if_dies_spell_v1","damage":4,"effect":"direct_damage","exile_if_dies_from_damage":true,"exile_if_dies_target":"creature_or_planeswalker","instant":false,"sorcery":true,"target":"creature_or_planeswalker","target_constraints":{"card_types":["creature","planeswalker"]},"xmage_effect_classes":["DamageTargetEffect","ExileTargetIfDiesEffect"]}'::jsonb, '{"category":"unknown","effect":"direct_damage","target":"creature_or_planeswalker"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class FangedFlames translated into ManaLoom runtime scope xmage_fixed_damage_target_exile_if_dies_spell_v1. This row is package-ready only because the source signature is a narrow fixed damage spell with exile-if-dies replacement with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('feed the flames', 'Feed the Flames', '71bae3916a02f627931b86fbc2bc7c26', 'battle_rule_v1:4f3ea4eabca25c95c2525886a0c65a9c', '{"amount":5,"battle_model_scope":"xmage_fixed_damage_target_exile_if_dies_spell_v1","damage":5,"effect":"direct_damage","exile_if_dies_from_damage":true,"exile_if_dies_target":"creature","instant":true,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"]},"xmage_effect_classes":["DamageTargetEffect","ExileTargetIfDiesEffect"]}'::jsonb, '{"category":"unknown","effect":"direct_damage","target":"creature","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class FeedTheFlames translated into ManaLoom runtime scope xmage_fixed_damage_target_exile_if_dies_spell_v1. This row is package-ready only because the source signature is a narrow fixed damage spell with exile-if-dies replacement with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('flame-blessed bolt', 'Flame-Blessed Bolt', '8c29d5792a7c71d3debe5d3f9e06bbde', 'battle_rule_v1:0260a8c11989a2b8375c4717dc6b3361', '{"amount":2,"battle_model_scope":"xmage_fixed_damage_target_exile_if_dies_spell_v1","damage":2,"effect":"direct_damage","exile_if_dies_from_damage":true,"exile_if_dies_target":"creature_or_planeswalker","instant":true,"sorcery":false,"target":"creature_or_planeswalker","target_constraints":{"card_types":["creature","planeswalker"]},"xmage_effect_classes":["DamageTargetEffect","ExileTargetIfDiesEffect"]}'::jsonb, '{"category":"unknown","effect":"direct_damage","target":"creature_or_planeswalker","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class FlameBlessedBolt translated into ManaLoom runtime scope xmage_fixed_damage_target_exile_if_dies_spell_v1. This row is package-ready only because the source signature is a narrow fixed damage spell with exile-if-dies replacement with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('lava coil', 'Lava Coil', 'b5658f51fc5b9f2a86c0302c7665a0c4', 'battle_rule_v1:00f072b0c13f2f6710f402ff7cf15fc8', '{"amount":4,"battle_model_scope":"xmage_fixed_damage_target_exile_if_dies_spell_v1","damage":4,"effect":"direct_damage","exile_if_dies_from_damage":true,"exile_if_dies_target":"creature","instant":false,"sorcery":true,"target":"creature","target_constraints":{"card_types":["creature"]},"xmage_effect_classes":["DamageTargetEffect","ExileTargetIfDiesEffect"]}'::jsonb, '{"category":"unknown","effect":"direct_damage","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class LavaCoil translated into ManaLoom runtime scope xmage_fixed_damage_target_exile_if_dies_spell_v1. This row is package-ready only because the source signature is a narrow fixed damage spell with exile-if-dies replacement with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('magma spray', 'Magma Spray', '76241ca8f5ff7d8bad5c0771650321d3', 'battle_rule_v1:001df6fe0862f863a88aa1fc27841a74', '{"amount":2,"battle_model_scope":"xmage_fixed_damage_target_exile_if_dies_spell_v1","damage":2,"effect":"direct_damage","exile_if_dies_from_damage":true,"exile_if_dies_target":"creature","instant":true,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"]},"xmage_effect_classes":["DamageTargetEffect","ExileTargetIfDiesEffect"]}'::jsonb, '{"category":"unknown","effect":"direct_damage","target":"creature","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class MagmaSpray translated into ManaLoom runtime scope xmage_fixed_damage_target_exile_if_dies_spell_v1. This row is package-ready only because the source signature is a narrow fixed damage spell with exile-if-dies replacement with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('obliterating bolt', 'Obliterating Bolt', '52fbf2ba566570f29f83416740b783f9', 'battle_rule_v1:0b23905863b021edd3a97ba78bfb32ca', '{"amount":4,"battle_model_scope":"xmage_fixed_damage_target_exile_if_dies_spell_v1","damage":4,"effect":"direct_damage","exile_if_dies_from_damage":true,"exile_if_dies_target":"creature_or_planeswalker","instant":false,"sorcery":true,"target":"creature_or_planeswalker","target_constraints":{"card_types":["creature","planeswalker"]},"xmage_effect_classes":["DamageTargetEffect","ExileTargetIfDiesEffect"]}'::jsonb, '{"category":"unknown","effect":"direct_damage","target":"creature_or_planeswalker"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ObliteratingBolt translated into ManaLoom runtime scope xmage_fixed_damage_target_exile_if_dies_spell_v1. This row is package-ready only because the source signature is a narrow fixed damage spell with exile-if-dies replacement with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('puncturing blow', 'Puncturing Blow', 'dbf801bc943efd39819ea09ff4897a36', 'battle_rule_v1:591bd8909ef06dcc4127e24b0d952e7d', '{"amount":5,"battle_model_scope":"xmage_fixed_damage_target_exile_if_dies_spell_v1","damage":5,"effect":"direct_damage","exile_if_dies_from_damage":true,"exile_if_dies_target":"creature","instant":false,"sorcery":true,"target":"creature","target_constraints":{"card_types":["creature"]},"xmage_effect_classes":["DamageTargetEffect","ExileTargetIfDiesEffect"]}'::jsonb, '{"category":"unknown","effect":"direct_damage","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class PuncturingBlow translated into ManaLoom runtime scope xmage_fixed_damage_target_exile_if_dies_spell_v1. This row is package-ready only because the source signature is a narrow fixed damage spell with exile-if-dies replacement with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('reduce to ashes', 'Reduce to Ashes', '53e679871c65ac7ce23f480a6cc58fe4', 'battle_rule_v1:591bd8909ef06dcc4127e24b0d952e7d', '{"amount":5,"battle_model_scope":"xmage_fixed_damage_target_exile_if_dies_spell_v1","damage":5,"effect":"direct_damage","exile_if_dies_from_damage":true,"exile_if_dies_target":"creature","instant":false,"sorcery":true,"target":"creature","target_constraints":{"card_types":["creature"]},"xmage_effect_classes":["DamageTargetEffect","ExileTargetIfDiesEffect"]}'::jsonb, '{"category":"unknown","effect":"direct_damage","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ReduceToAshes translated into ManaLoom runtime scope xmage_fixed_damage_target_exile_if_dies_spell_v1. This row is package-ready only because the source signature is a narrow fixed damage spell with exile-if-dies replacement with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('scorching dragonfire', 'Scorching Dragonfire', 'eb4b58cb260c7ed83fb61f407f095f88', 'battle_rule_v1:d8158e4630695dfb123c559adf5c6669', '{"amount":3,"battle_model_scope":"xmage_fixed_damage_target_exile_if_dies_spell_v1","damage":3,"effect":"direct_damage","exile_if_dies_from_damage":true,"exile_if_dies_target":"creature_or_planeswalker","instant":true,"sorcery":false,"target":"creature_or_planeswalker","target_constraints":{"card_types":["creature","planeswalker"]},"xmage_effect_classes":["DamageTargetEffect","ExileTargetIfDiesEffect"]}'::jsonb, '{"category":"unknown","effect":"direct_damage","target":"creature_or_planeswalker","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ScorchingDragonfire translated into ManaLoom runtime scope xmage_fixed_damage_target_exile_if_dies_spell_v1. This row is package-ready only because the source signature is a narrow fixed damage spell with exile-if-dies replacement with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('scorchmark', 'Scorchmark', '4e2b75865e1ef6c6a3a22a3e70cc4342', 'battle_rule_v1:001df6fe0862f863a88aa1fc27841a74', '{"amount":2,"battle_model_scope":"xmage_fixed_damage_target_exile_if_dies_spell_v1","damage":2,"effect":"direct_damage","exile_if_dies_from_damage":true,"exile_if_dies_target":"creature","instant":true,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"]},"xmage_effect_classes":["DamageTargetEffect","ExileTargetIfDiesEffect"]}'::jsonb, '{"category":"unknown","effect":"direct_damage","target":"creature","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Scorchmark translated into ManaLoom runtime scope xmage_fixed_damage_target_exile_if_dies_spell_v1. This row is package-ready only because the source signature is a narrow fixed damage spell with exile-if-dies replacement with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
