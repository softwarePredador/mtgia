BEGIN;

CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit;

CREATE TABLE manaloom_deploy_audit.pg368_graveyard_exile_spell_wave_20260702_094901 AS
SELECT *
FROM public.card_battle_rules
WHERE normalized_name IN ('coffin purge', 'decompose', 'fade from memory', 'purify the grave', 'rapid decay', 'rats'' feast', 'scarab feast')
   OR normalized_name LIKE 'coffin purge // %'
   OR normalized_name LIKE 'decompose // %'
   OR normalized_name LIKE 'fade from memory // %'
   OR normalized_name LIKE 'purify the grave // %'
   OR normalized_name LIKE 'rapid decay // %'
   OR normalized_name LIKE 'rats'' feast // %'
   OR normalized_name LIKE 'scarab feast // %';

DO $$
DECLARE
  v_missing jsonb;
BEGIN
  WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('coffin purge', 'Coffin Purge', 'b8c13734632e6aa5f94766f94c7b0663', 'battle_rule_v1:329f79a646d66432a7ba41e0c0f4a0f1', '{"battle_model_scope":"xmage_exile_target_graveyard_card_spell_v1","count":1,"destination":"exile","effect":"graveyard_exile","flashback_cost":"{B}","flashback_status":"runtime_executor_v1","graveyard_exile_destination":"exile","graveyard_exile_single_graveyard":false,"graveyard_exile_target":"any_card","graveyard_exile_target_count":1,"instant":true,"sorcery":false,"target":"any_card","target_constraints":{"controller":"any","scope":"any_card","zone":"graveyard"},"target_controller":"any","xmage_auxiliary_ability_classes":["FlashbackAbility"],"xmage_effect_class":"ExileTargetEffect"}'::jsonb, '{"category":"removal","effect":"graveyard_exile","subtype":"graveyard_hate","target":"any_card","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class CoffinPurge translated into ManaLoom runtime scope xmage_exile_target_graveyard_card_spell_v1. This row is package-ready only because the source signature is a narrow exile target graveyard card spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('decompose', 'Decompose', '574498b9832411fc894cdafd0a1459eb', 'battle_rule_v1:42fb18be92bf3dd4236e16a53e22e7ab', '{"battle_model_scope":"xmage_exile_target_graveyard_card_spell_v1","count":3,"destination":"exile","effect":"graveyard_exile","graveyard_exile_destination":"exile","graveyard_exile_single_graveyard":true,"graveyard_exile_target":"any_card","graveyard_exile_target_count":3,"graveyard_exile_up_to_count":true,"instant":false,"sorcery":true,"target":"any_card","target_constraints":{"controller":"any","scope":"any_card","zone":"graveyard"},"target_controller":"any","up_to_count":true,"xmage_effect_class":"ExileTargetEffect"}'::jsonb, '{"category":"removal","effect":"graveyard_exile","subtype":"graveyard_hate","target":"any_card"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Decompose translated into ManaLoom runtime scope xmage_exile_target_graveyard_card_spell_v1. This row is package-ready only because the source signature is a narrow exile target graveyard card spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('fade from memory', 'Fade from Memory', 'd849e131a7d83a356c5a209eacecc9ed', 'battle_rule_v1:615cff671d9dde0bc0af79898851acda', '{"battle_model_scope":"xmage_exile_target_graveyard_card_spell_v1","count":1,"cycling_cost":"{B}","cycling_status":"runtime_executor_v1","destination":"exile","effect":"graveyard_exile","graveyard_exile_destination":"exile","graveyard_exile_single_graveyard":false,"graveyard_exile_target":"any_card","graveyard_exile_target_count":1,"instant":true,"sorcery":false,"target":"any_card","target_constraints":{"controller":"any","scope":"any_card","zone":"graveyard"},"target_controller":"any","xmage_auxiliary_ability_classes":["CyclingAbility"],"xmage_effect_class":"ExileTargetEffect"}'::jsonb, '{"category":"removal","effect":"graveyard_exile","subtype":"graveyard_hate","target":"any_card","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class FadeFromMemory translated into ManaLoom runtime scope xmage_exile_target_graveyard_card_spell_v1. This row is package-ready only because the source signature is a narrow exile target graveyard card spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('purify the grave', 'Purify the Grave', 'e7643d7c704fb3390c6f6cc2cbef811b', 'battle_rule_v1:72dfb24ccd0d65f221c49bbc343f94f8', '{"battle_model_scope":"xmage_exile_target_graveyard_card_spell_v1","count":1,"destination":"exile","effect":"graveyard_exile","flashback_cost":"{W}","flashback_status":"runtime_executor_v1","graveyard_exile_destination":"exile","graveyard_exile_single_graveyard":false,"graveyard_exile_target":"any_card","graveyard_exile_target_count":1,"instant":true,"sorcery":false,"target":"any_card","target_constraints":{"controller":"any","scope":"any_card","zone":"graveyard"},"target_controller":"any","xmage_auxiliary_ability_classes":["FlashbackAbility"],"xmage_effect_class":"ExileTargetEffect"}'::jsonb, '{"category":"removal","effect":"graveyard_exile","subtype":"graveyard_hate","target":"any_card","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class PurifyTheGrave translated into ManaLoom runtime scope xmage_exile_target_graveyard_card_spell_v1. This row is package-ready only because the source signature is a narrow exile target graveyard card spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('rapid decay', 'Rapid Decay', '236d5189bf9ad6285f7eeb432514426c', 'battle_rule_v1:b92371161b491e6dacb50588a98be1ad', '{"battle_model_scope":"xmage_exile_target_graveyard_card_spell_v1","count":3,"cycling_cost":"{2}","cycling_status":"runtime_executor_v1","destination":"exile","effect":"graveyard_exile","graveyard_exile_destination":"exile","graveyard_exile_single_graveyard":true,"graveyard_exile_target":"any_card","graveyard_exile_target_count":3,"graveyard_exile_up_to_count":true,"instant":true,"sorcery":false,"target":"any_card","target_constraints":{"controller":"any","scope":"any_card","zone":"graveyard"},"target_controller":"any","up_to_count":true,"xmage_auxiliary_ability_classes":["CyclingAbility"],"xmage_effect_class":"ExileTargetEffect"}'::jsonb, '{"category":"removal","effect":"graveyard_exile","subtype":"graveyard_hate","target":"any_card","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class RapidDecay translated into ManaLoom runtime scope xmage_exile_target_graveyard_card_spell_v1. This row is package-ready only because the source signature is a narrow exile target graveyard card spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('rats'' feast', 'Rats'' Feast', '676bd982b2fdb904153179fd14904fc8', 'battle_rule_v1:a3272655216713a20cc870b7a484c55d', '{"battle_model_scope":"xmage_exile_target_graveyard_card_spell_v1","count":1,"destination":"exile","effect":"graveyard_exile","graveyard_exile_destination":"exile","graveyard_exile_single_graveyard":true,"graveyard_exile_target":"any_card","graveyard_exile_target_count":1,"graveyard_exile_target_count_from_x":true,"instant":false,"sorcery":true,"target":"any_card","target_constraints":{"controller":"any","scope":"any_card","zone":"graveyard"},"target_controller":"any","target_count_from_x":true,"xmage_effect_class":"ExileTargetEffect"}'::jsonb, '{"category":"removal","effect":"graveyard_exile","subtype":"graveyard_hate","target":"any_card"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class RatsFeast translated into ManaLoom runtime scope xmage_exile_target_graveyard_card_spell_v1. This row is package-ready only because the source signature is a narrow exile target graveyard card spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('scarab feast', 'Scarab Feast', '5bbe7a0b8d550e9b403c2bf4827aa320', 'battle_rule_v1:cfe9f926e6666c66b6e564d000906d3f', '{"battle_model_scope":"xmage_exile_target_graveyard_card_spell_v1","count":3,"cycling_cost":"{B}","cycling_status":"runtime_executor_v1","destination":"exile","effect":"graveyard_exile","graveyard_exile_destination":"exile","graveyard_exile_single_graveyard":true,"graveyard_exile_target":"any_card","graveyard_exile_target_count":3,"graveyard_exile_up_to_count":true,"instant":true,"sorcery":false,"target":"any_card","target_constraints":{"controller":"any","scope":"any_card","zone":"graveyard"},"target_controller":"any","up_to_count":true,"xmage_auxiliary_ability_classes":["CyclingAbility"],"xmage_effect_class":"ExileTargetEffect"}'::jsonb, '{"category":"removal","effect":"graveyard_exile","subtype":"graveyard_hate","target":"any_card","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ScarabFeast translated into ManaLoom runtime scope xmage_exile_target_graveyard_card_spell_v1. This row is package-ready only because the source signature is a narrow exile target graveyard card spell with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
    ('coffin purge', 'Coffin Purge', 'b8c13734632e6aa5f94766f94c7b0663', 'battle_rule_v1:329f79a646d66432a7ba41e0c0f4a0f1', '{"battle_model_scope":"xmage_exile_target_graveyard_card_spell_v1","count":1,"destination":"exile","effect":"graveyard_exile","flashback_cost":"{B}","flashback_status":"runtime_executor_v1","graveyard_exile_destination":"exile","graveyard_exile_single_graveyard":false,"graveyard_exile_target":"any_card","graveyard_exile_target_count":1,"instant":true,"sorcery":false,"target":"any_card","target_constraints":{"controller":"any","scope":"any_card","zone":"graveyard"},"target_controller":"any","xmage_auxiliary_ability_classes":["FlashbackAbility"],"xmage_effect_class":"ExileTargetEffect"}'::jsonb, '{"category":"removal","effect":"graveyard_exile","subtype":"graveyard_hate","target":"any_card","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class CoffinPurge translated into ManaLoom runtime scope xmage_exile_target_graveyard_card_spell_v1. This row is package-ready only because the source signature is a narrow exile target graveyard card spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('decompose', 'Decompose', '574498b9832411fc894cdafd0a1459eb', 'battle_rule_v1:42fb18be92bf3dd4236e16a53e22e7ab', '{"battle_model_scope":"xmage_exile_target_graveyard_card_spell_v1","count":3,"destination":"exile","effect":"graveyard_exile","graveyard_exile_destination":"exile","graveyard_exile_single_graveyard":true,"graveyard_exile_target":"any_card","graveyard_exile_target_count":3,"graveyard_exile_up_to_count":true,"instant":false,"sorcery":true,"target":"any_card","target_constraints":{"controller":"any","scope":"any_card","zone":"graveyard"},"target_controller":"any","up_to_count":true,"xmage_effect_class":"ExileTargetEffect"}'::jsonb, '{"category":"removal","effect":"graveyard_exile","subtype":"graveyard_hate","target":"any_card"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Decompose translated into ManaLoom runtime scope xmage_exile_target_graveyard_card_spell_v1. This row is package-ready only because the source signature is a narrow exile target graveyard card spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('fade from memory', 'Fade from Memory', 'd849e131a7d83a356c5a209eacecc9ed', 'battle_rule_v1:615cff671d9dde0bc0af79898851acda', '{"battle_model_scope":"xmage_exile_target_graveyard_card_spell_v1","count":1,"cycling_cost":"{B}","cycling_status":"runtime_executor_v1","destination":"exile","effect":"graveyard_exile","graveyard_exile_destination":"exile","graveyard_exile_single_graveyard":false,"graveyard_exile_target":"any_card","graveyard_exile_target_count":1,"instant":true,"sorcery":false,"target":"any_card","target_constraints":{"controller":"any","scope":"any_card","zone":"graveyard"},"target_controller":"any","xmage_auxiliary_ability_classes":["CyclingAbility"],"xmage_effect_class":"ExileTargetEffect"}'::jsonb, '{"category":"removal","effect":"graveyard_exile","subtype":"graveyard_hate","target":"any_card","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class FadeFromMemory translated into ManaLoom runtime scope xmage_exile_target_graveyard_card_spell_v1. This row is package-ready only because the source signature is a narrow exile target graveyard card spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('purify the grave', 'Purify the Grave', 'e7643d7c704fb3390c6f6cc2cbef811b', 'battle_rule_v1:72dfb24ccd0d65f221c49bbc343f94f8', '{"battle_model_scope":"xmage_exile_target_graveyard_card_spell_v1","count":1,"destination":"exile","effect":"graveyard_exile","flashback_cost":"{W}","flashback_status":"runtime_executor_v1","graveyard_exile_destination":"exile","graveyard_exile_single_graveyard":false,"graveyard_exile_target":"any_card","graveyard_exile_target_count":1,"instant":true,"sorcery":false,"target":"any_card","target_constraints":{"controller":"any","scope":"any_card","zone":"graveyard"},"target_controller":"any","xmage_auxiliary_ability_classes":["FlashbackAbility"],"xmage_effect_class":"ExileTargetEffect"}'::jsonb, '{"category":"removal","effect":"graveyard_exile","subtype":"graveyard_hate","target":"any_card","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class PurifyTheGrave translated into ManaLoom runtime scope xmage_exile_target_graveyard_card_spell_v1. This row is package-ready only because the source signature is a narrow exile target graveyard card spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('rapid decay', 'Rapid Decay', '236d5189bf9ad6285f7eeb432514426c', 'battle_rule_v1:b92371161b491e6dacb50588a98be1ad', '{"battle_model_scope":"xmage_exile_target_graveyard_card_spell_v1","count":3,"cycling_cost":"{2}","cycling_status":"runtime_executor_v1","destination":"exile","effect":"graveyard_exile","graveyard_exile_destination":"exile","graveyard_exile_single_graveyard":true,"graveyard_exile_target":"any_card","graveyard_exile_target_count":3,"graveyard_exile_up_to_count":true,"instant":true,"sorcery":false,"target":"any_card","target_constraints":{"controller":"any","scope":"any_card","zone":"graveyard"},"target_controller":"any","up_to_count":true,"xmage_auxiliary_ability_classes":["CyclingAbility"],"xmage_effect_class":"ExileTargetEffect"}'::jsonb, '{"category":"removal","effect":"graveyard_exile","subtype":"graveyard_hate","target":"any_card","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class RapidDecay translated into ManaLoom runtime scope xmage_exile_target_graveyard_card_spell_v1. This row is package-ready only because the source signature is a narrow exile target graveyard card spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('rats'' feast', 'Rats'' Feast', '676bd982b2fdb904153179fd14904fc8', 'battle_rule_v1:a3272655216713a20cc870b7a484c55d', '{"battle_model_scope":"xmage_exile_target_graveyard_card_spell_v1","count":1,"destination":"exile","effect":"graveyard_exile","graveyard_exile_destination":"exile","graveyard_exile_single_graveyard":true,"graveyard_exile_target":"any_card","graveyard_exile_target_count":1,"graveyard_exile_target_count_from_x":true,"instant":false,"sorcery":true,"target":"any_card","target_constraints":{"controller":"any","scope":"any_card","zone":"graveyard"},"target_controller":"any","target_count_from_x":true,"xmage_effect_class":"ExileTargetEffect"}'::jsonb, '{"category":"removal","effect":"graveyard_exile","subtype":"graveyard_hate","target":"any_card"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class RatsFeast translated into ManaLoom runtime scope xmage_exile_target_graveyard_card_spell_v1. This row is package-ready only because the source signature is a narrow exile target graveyard card spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('scarab feast', 'Scarab Feast', '5bbe7a0b8d550e9b403c2bf4827aa320', 'battle_rule_v1:cfe9f926e6666c66b6e564d000906d3f', '{"battle_model_scope":"xmage_exile_target_graveyard_card_spell_v1","count":3,"cycling_cost":"{B}","cycling_status":"runtime_executor_v1","destination":"exile","effect":"graveyard_exile","graveyard_exile_destination":"exile","graveyard_exile_single_graveyard":true,"graveyard_exile_target":"any_card","graveyard_exile_target_count":3,"graveyard_exile_up_to_count":true,"instant":true,"sorcery":false,"target":"any_card","target_constraints":{"controller":"any","scope":"any_card","zone":"graveyard"},"target_controller":"any","up_to_count":true,"xmage_auxiliary_ability_classes":["CyclingAbility"],"xmage_effect_class":"ExileTargetEffect"}'::jsonb, '{"category":"removal","effect":"graveyard_exile","subtype":"graveyard_hate","target":"any_card","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ScarabFeast translated into ManaLoom runtime scope xmage_exile_target_graveyard_card_spell_v1. This row is package-ready only because the source signature is a narrow exile target graveyard card spell with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
    ('coffin purge', 'Coffin Purge', 'b8c13734632e6aa5f94766f94c7b0663', 'battle_rule_v1:329f79a646d66432a7ba41e0c0f4a0f1', '{"battle_model_scope":"xmage_exile_target_graveyard_card_spell_v1","count":1,"destination":"exile","effect":"graveyard_exile","flashback_cost":"{B}","flashback_status":"runtime_executor_v1","graveyard_exile_destination":"exile","graveyard_exile_single_graveyard":false,"graveyard_exile_target":"any_card","graveyard_exile_target_count":1,"instant":true,"sorcery":false,"target":"any_card","target_constraints":{"controller":"any","scope":"any_card","zone":"graveyard"},"target_controller":"any","xmage_auxiliary_ability_classes":["FlashbackAbility"],"xmage_effect_class":"ExileTargetEffect"}'::jsonb, '{"category":"removal","effect":"graveyard_exile","subtype":"graveyard_hate","target":"any_card","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class CoffinPurge translated into ManaLoom runtime scope xmage_exile_target_graveyard_card_spell_v1. This row is package-ready only because the source signature is a narrow exile target graveyard card spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('decompose', 'Decompose', '574498b9832411fc894cdafd0a1459eb', 'battle_rule_v1:42fb18be92bf3dd4236e16a53e22e7ab', '{"battle_model_scope":"xmage_exile_target_graveyard_card_spell_v1","count":3,"destination":"exile","effect":"graveyard_exile","graveyard_exile_destination":"exile","graveyard_exile_single_graveyard":true,"graveyard_exile_target":"any_card","graveyard_exile_target_count":3,"graveyard_exile_up_to_count":true,"instant":false,"sorcery":true,"target":"any_card","target_constraints":{"controller":"any","scope":"any_card","zone":"graveyard"},"target_controller":"any","up_to_count":true,"xmage_effect_class":"ExileTargetEffect"}'::jsonb, '{"category":"removal","effect":"graveyard_exile","subtype":"graveyard_hate","target":"any_card"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Decompose translated into ManaLoom runtime scope xmage_exile_target_graveyard_card_spell_v1. This row is package-ready only because the source signature is a narrow exile target graveyard card spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('fade from memory', 'Fade from Memory', 'd849e131a7d83a356c5a209eacecc9ed', 'battle_rule_v1:615cff671d9dde0bc0af79898851acda', '{"battle_model_scope":"xmage_exile_target_graveyard_card_spell_v1","count":1,"cycling_cost":"{B}","cycling_status":"runtime_executor_v1","destination":"exile","effect":"graveyard_exile","graveyard_exile_destination":"exile","graveyard_exile_single_graveyard":false,"graveyard_exile_target":"any_card","graveyard_exile_target_count":1,"instant":true,"sorcery":false,"target":"any_card","target_constraints":{"controller":"any","scope":"any_card","zone":"graveyard"},"target_controller":"any","xmage_auxiliary_ability_classes":["CyclingAbility"],"xmage_effect_class":"ExileTargetEffect"}'::jsonb, '{"category":"removal","effect":"graveyard_exile","subtype":"graveyard_hate","target":"any_card","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class FadeFromMemory translated into ManaLoom runtime scope xmage_exile_target_graveyard_card_spell_v1. This row is package-ready only because the source signature is a narrow exile target graveyard card spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('purify the grave', 'Purify the Grave', 'e7643d7c704fb3390c6f6cc2cbef811b', 'battle_rule_v1:72dfb24ccd0d65f221c49bbc343f94f8', '{"battle_model_scope":"xmage_exile_target_graveyard_card_spell_v1","count":1,"destination":"exile","effect":"graveyard_exile","flashback_cost":"{W}","flashback_status":"runtime_executor_v1","graveyard_exile_destination":"exile","graveyard_exile_single_graveyard":false,"graveyard_exile_target":"any_card","graveyard_exile_target_count":1,"instant":true,"sorcery":false,"target":"any_card","target_constraints":{"controller":"any","scope":"any_card","zone":"graveyard"},"target_controller":"any","xmage_auxiliary_ability_classes":["FlashbackAbility"],"xmage_effect_class":"ExileTargetEffect"}'::jsonb, '{"category":"removal","effect":"graveyard_exile","subtype":"graveyard_hate","target":"any_card","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class PurifyTheGrave translated into ManaLoom runtime scope xmage_exile_target_graveyard_card_spell_v1. This row is package-ready only because the source signature is a narrow exile target graveyard card spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('rapid decay', 'Rapid Decay', '236d5189bf9ad6285f7eeb432514426c', 'battle_rule_v1:b92371161b491e6dacb50588a98be1ad', '{"battle_model_scope":"xmage_exile_target_graveyard_card_spell_v1","count":3,"cycling_cost":"{2}","cycling_status":"runtime_executor_v1","destination":"exile","effect":"graveyard_exile","graveyard_exile_destination":"exile","graveyard_exile_single_graveyard":true,"graveyard_exile_target":"any_card","graveyard_exile_target_count":3,"graveyard_exile_up_to_count":true,"instant":true,"sorcery":false,"target":"any_card","target_constraints":{"controller":"any","scope":"any_card","zone":"graveyard"},"target_controller":"any","up_to_count":true,"xmage_auxiliary_ability_classes":["CyclingAbility"],"xmage_effect_class":"ExileTargetEffect"}'::jsonb, '{"category":"removal","effect":"graveyard_exile","subtype":"graveyard_hate","target":"any_card","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class RapidDecay translated into ManaLoom runtime scope xmage_exile_target_graveyard_card_spell_v1. This row is package-ready only because the source signature is a narrow exile target graveyard card spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('rats'' feast', 'Rats'' Feast', '676bd982b2fdb904153179fd14904fc8', 'battle_rule_v1:a3272655216713a20cc870b7a484c55d', '{"battle_model_scope":"xmage_exile_target_graveyard_card_spell_v1","count":1,"destination":"exile","effect":"graveyard_exile","graveyard_exile_destination":"exile","graveyard_exile_single_graveyard":true,"graveyard_exile_target":"any_card","graveyard_exile_target_count":1,"graveyard_exile_target_count_from_x":true,"instant":false,"sorcery":true,"target":"any_card","target_constraints":{"controller":"any","scope":"any_card","zone":"graveyard"},"target_controller":"any","target_count_from_x":true,"xmage_effect_class":"ExileTargetEffect"}'::jsonb, '{"category":"removal","effect":"graveyard_exile","subtype":"graveyard_hate","target":"any_card"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class RatsFeast translated into ManaLoom runtime scope xmage_exile_target_graveyard_card_spell_v1. This row is package-ready only because the source signature is a narrow exile target graveyard card spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('scarab feast', 'Scarab Feast', '5bbe7a0b8d550e9b403c2bf4827aa320', 'battle_rule_v1:cfe9f926e6666c66b6e564d000906d3f', '{"battle_model_scope":"xmage_exile_target_graveyard_card_spell_v1","count":3,"cycling_cost":"{B}","cycling_status":"runtime_executor_v1","destination":"exile","effect":"graveyard_exile","graveyard_exile_destination":"exile","graveyard_exile_single_graveyard":true,"graveyard_exile_target":"any_card","graveyard_exile_target_count":3,"graveyard_exile_up_to_count":true,"instant":true,"sorcery":false,"target":"any_card","target_constraints":{"controller":"any","scope":"any_card","zone":"graveyard"},"target_controller":"any","up_to_count":true,"xmage_auxiliary_ability_classes":["CyclingAbility"],"xmage_effect_class":"ExileTargetEffect"}'::jsonb, '{"category":"removal","effect":"graveyard_exile","subtype":"graveyard_hate","target":"any_card","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ScarabFeast translated into ManaLoom runtime scope xmage_exile_target_graveyard_card_spell_v1. This row is package-ready only because the source signature is a narrow exile target graveyard card spell with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
