BEGIN;

CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit;

CREATE TABLE manaloom_deploy_audit.pg386_draw_lose_life_spell_runtime_new_server_20260704_0 AS
SELECT *
FROM public.card_battle_rules
WHERE normalized_name IN ('ambition''s cost', 'ancient craving', 'blood pact', 'harrowing journey', 'night''s whisper', 'painful lesson', 'sign in blood', 'succumb to temptation')
   OR normalized_name LIKE 'ambition''s cost // %'
   OR normalized_name LIKE 'ancient craving // %'
   OR normalized_name LIKE 'blood pact // %'
   OR normalized_name LIKE 'harrowing journey // %'
   OR normalized_name LIKE 'night''s whisper // %'
   OR normalized_name LIKE 'painful lesson // %'
   OR normalized_name LIKE 'sign in blood // %'
   OR normalized_name LIKE 'succumb to temptation // %';

DO $$
DECLARE
  v_missing jsonb;
BEGIN
  WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('ambition''s cost', 'Ambition''s Cost', '2a807c1035d7b1ce49ba9281a02e946e', 'battle_rule_v1:3b2afd0214c6776da9b668598d824795', '{"battle_model_scope":"xmage_fixed_controller_draw_lose_life_spell_v1","count":3,"draw_count":3,"draw_lose_life_spell":true,"effect":"draw_cards","instant":false,"life_loss":3,"sorcery":true,"target_controller":"self","xmage_effect_classes":["DrawCardSourceControllerEffect","LoseLifeSourceControllerEffect"]}'::jsonb, '{"category":"draw","effect":"draw_cards"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class AmbitionsCost translated into ManaLoom runtime scope xmage_fixed_controller_draw_lose_life_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('ancient craving', 'Ancient Craving', '2a807c1035d7b1ce49ba9281a02e946e', 'battle_rule_v1:3b2afd0214c6776da9b668598d824795', '{"battle_model_scope":"xmage_fixed_controller_draw_lose_life_spell_v1","count":3,"draw_count":3,"draw_lose_life_spell":true,"effect":"draw_cards","instant":false,"life_loss":3,"sorcery":true,"target_controller":"self","xmage_effect_classes":["DrawCardSourceControllerEffect","LoseLifeSourceControllerEffect"]}'::jsonb, '{"category":"draw","effect":"draw_cards"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class AncientCraving translated into ManaLoom runtime scope xmage_fixed_controller_draw_lose_life_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('blood pact', 'Blood Pact', '0e1cca8ed574f916efa7634f28cd7de4', 'battle_rule_v1:e849896e6ab7822b604314a9842236f5', '{"battle_model_scope":"xmage_fixed_target_player_draw_lose_life_spell_v1","count":2,"draw_count":2,"draw_lose_life_spell":true,"effect":"draw_cards","instant":true,"life_loss":2,"sorcery":false,"target":"player","target_constraints":{"players":["any"]},"target_controller":"target_player","target_preference":"self","xmage_effect_classes":["DrawCardTargetEffect","LoseLifeTargetEffect"]}'::jsonb, '{"category":"draw","effect":"draw_cards","target":"player","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class BloodPact translated into ManaLoom runtime scope xmage_fixed_target_player_draw_lose_life_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('harrowing journey', 'Harrowing Journey', '1fee8ed9c8875ba33f2972741b6a3e25', 'battle_rule_v1:e42886e5607833d64538053de3d5de82', '{"battle_model_scope":"xmage_fixed_target_player_draw_lose_life_spell_v1","count":3,"draw_count":3,"draw_lose_life_spell":true,"effect":"draw_cards","instant":false,"life_loss":3,"sorcery":true,"target":"player","target_constraints":{"players":["any"]},"target_controller":"target_player","target_preference":"self","xmage_effect_classes":["DrawCardTargetEffect","LoseLifeTargetEffect"]}'::jsonb, '{"category":"draw","effect":"draw_cards","target":"player"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class HarrowingJourney translated into ManaLoom runtime scope xmage_fixed_target_player_draw_lose_life_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('night''s whisper', 'Night''s Whisper', '99f77dc3d03da6660ecb413593fe23e7', 'battle_rule_v1:4149f6570b19de0fc58fef7eb6736e40', '{"battle_model_scope":"xmage_fixed_controller_draw_lose_life_spell_v1","count":2,"draw_count":2,"draw_lose_life_spell":true,"effect":"draw_cards","instant":false,"life_loss":2,"sorcery":true,"target_controller":"self","xmage_effect_classes":["DrawCardSourceControllerEffect","LoseLifeSourceControllerEffect"]}'::jsonb, '{"category":"draw","effect":"draw_cards"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class NightsWhisper translated into ManaLoom runtime scope xmage_fixed_controller_draw_lose_life_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('painful lesson', 'Painful Lesson', '0e1cca8ed574f916efa7634f28cd7de4', 'battle_rule_v1:3b5e4090931830427bc375568e4786ed', '{"battle_model_scope":"xmage_fixed_target_player_draw_lose_life_spell_v1","count":2,"draw_count":2,"draw_lose_life_spell":true,"effect":"draw_cards","instant":false,"life_loss":2,"sorcery":true,"target":"player","target_constraints":{"players":["any"]},"target_controller":"target_player","target_preference":"self","xmage_effect_classes":["DrawCardTargetEffect","LoseLifeTargetEffect"]}'::jsonb, '{"category":"draw","effect":"draw_cards","target":"player"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class PainfulLesson translated into ManaLoom runtime scope xmage_fixed_target_player_draw_lose_life_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('sign in blood', 'Sign in Blood', '0e1cca8ed574f916efa7634f28cd7de4', 'battle_rule_v1:3b5e4090931830427bc375568e4786ed', '{"battle_model_scope":"xmage_fixed_target_player_draw_lose_life_spell_v1","count":2,"draw_count":2,"draw_lose_life_spell":true,"effect":"draw_cards","instant":false,"life_loss":2,"sorcery":true,"target":"player","target_constraints":{"players":["any"]},"target_controller":"target_player","target_preference":"self","xmage_effect_classes":["DrawCardTargetEffect","LoseLifeTargetEffect"]}'::jsonb, '{"category":"draw","effect":"draw_cards","target":"player"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class SignInBlood translated into ManaLoom runtime scope xmage_fixed_target_player_draw_lose_life_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('succumb to temptation', 'Succumb to Temptation', 'c0b258f641e17da5b9ffc3ea28cd6a10', 'battle_rule_v1:96b2d3623c4036f44092a07cd0feebbd', '{"battle_model_scope":"xmage_fixed_controller_draw_lose_life_spell_v1","count":2,"draw_count":2,"draw_lose_life_spell":true,"effect":"draw_cards","instant":true,"life_loss":2,"sorcery":false,"target_controller":"self","xmage_effect_classes":["DrawCardSourceControllerEffect","LoseLifeSourceControllerEffect"]}'::jsonb, '{"category":"draw","effect":"draw_cards","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class SuccumbToTemptation translated into ManaLoom runtime scope xmage_fixed_controller_draw_lose_life_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
    ('ambition''s cost', 'Ambition''s Cost', '2a807c1035d7b1ce49ba9281a02e946e', 'battle_rule_v1:3b2afd0214c6776da9b668598d824795', '{"battle_model_scope":"xmage_fixed_controller_draw_lose_life_spell_v1","count":3,"draw_count":3,"draw_lose_life_spell":true,"effect":"draw_cards","instant":false,"life_loss":3,"sorcery":true,"target_controller":"self","xmage_effect_classes":["DrawCardSourceControllerEffect","LoseLifeSourceControllerEffect"]}'::jsonb, '{"category":"draw","effect":"draw_cards"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class AmbitionsCost translated into ManaLoom runtime scope xmage_fixed_controller_draw_lose_life_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('ancient craving', 'Ancient Craving', '2a807c1035d7b1ce49ba9281a02e946e', 'battle_rule_v1:3b2afd0214c6776da9b668598d824795', '{"battle_model_scope":"xmage_fixed_controller_draw_lose_life_spell_v1","count":3,"draw_count":3,"draw_lose_life_spell":true,"effect":"draw_cards","instant":false,"life_loss":3,"sorcery":true,"target_controller":"self","xmage_effect_classes":["DrawCardSourceControllerEffect","LoseLifeSourceControllerEffect"]}'::jsonb, '{"category":"draw","effect":"draw_cards"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class AncientCraving translated into ManaLoom runtime scope xmage_fixed_controller_draw_lose_life_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('blood pact', 'Blood Pact', '0e1cca8ed574f916efa7634f28cd7de4', 'battle_rule_v1:e849896e6ab7822b604314a9842236f5', '{"battle_model_scope":"xmage_fixed_target_player_draw_lose_life_spell_v1","count":2,"draw_count":2,"draw_lose_life_spell":true,"effect":"draw_cards","instant":true,"life_loss":2,"sorcery":false,"target":"player","target_constraints":{"players":["any"]},"target_controller":"target_player","target_preference":"self","xmage_effect_classes":["DrawCardTargetEffect","LoseLifeTargetEffect"]}'::jsonb, '{"category":"draw","effect":"draw_cards","target":"player","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class BloodPact translated into ManaLoom runtime scope xmage_fixed_target_player_draw_lose_life_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('harrowing journey', 'Harrowing Journey', '1fee8ed9c8875ba33f2972741b6a3e25', 'battle_rule_v1:e42886e5607833d64538053de3d5de82', '{"battle_model_scope":"xmage_fixed_target_player_draw_lose_life_spell_v1","count":3,"draw_count":3,"draw_lose_life_spell":true,"effect":"draw_cards","instant":false,"life_loss":3,"sorcery":true,"target":"player","target_constraints":{"players":["any"]},"target_controller":"target_player","target_preference":"self","xmage_effect_classes":["DrawCardTargetEffect","LoseLifeTargetEffect"]}'::jsonb, '{"category":"draw","effect":"draw_cards","target":"player"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class HarrowingJourney translated into ManaLoom runtime scope xmage_fixed_target_player_draw_lose_life_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('night''s whisper', 'Night''s Whisper', '99f77dc3d03da6660ecb413593fe23e7', 'battle_rule_v1:4149f6570b19de0fc58fef7eb6736e40', '{"battle_model_scope":"xmage_fixed_controller_draw_lose_life_spell_v1","count":2,"draw_count":2,"draw_lose_life_spell":true,"effect":"draw_cards","instant":false,"life_loss":2,"sorcery":true,"target_controller":"self","xmage_effect_classes":["DrawCardSourceControllerEffect","LoseLifeSourceControllerEffect"]}'::jsonb, '{"category":"draw","effect":"draw_cards"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class NightsWhisper translated into ManaLoom runtime scope xmage_fixed_controller_draw_lose_life_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('painful lesson', 'Painful Lesson', '0e1cca8ed574f916efa7634f28cd7de4', 'battle_rule_v1:3b5e4090931830427bc375568e4786ed', '{"battle_model_scope":"xmage_fixed_target_player_draw_lose_life_spell_v1","count":2,"draw_count":2,"draw_lose_life_spell":true,"effect":"draw_cards","instant":false,"life_loss":2,"sorcery":true,"target":"player","target_constraints":{"players":["any"]},"target_controller":"target_player","target_preference":"self","xmage_effect_classes":["DrawCardTargetEffect","LoseLifeTargetEffect"]}'::jsonb, '{"category":"draw","effect":"draw_cards","target":"player"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class PainfulLesson translated into ManaLoom runtime scope xmage_fixed_target_player_draw_lose_life_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('sign in blood', 'Sign in Blood', '0e1cca8ed574f916efa7634f28cd7de4', 'battle_rule_v1:3b5e4090931830427bc375568e4786ed', '{"battle_model_scope":"xmage_fixed_target_player_draw_lose_life_spell_v1","count":2,"draw_count":2,"draw_lose_life_spell":true,"effect":"draw_cards","instant":false,"life_loss":2,"sorcery":true,"target":"player","target_constraints":{"players":["any"]},"target_controller":"target_player","target_preference":"self","xmage_effect_classes":["DrawCardTargetEffect","LoseLifeTargetEffect"]}'::jsonb, '{"category":"draw","effect":"draw_cards","target":"player"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class SignInBlood translated into ManaLoom runtime scope xmage_fixed_target_player_draw_lose_life_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('succumb to temptation', 'Succumb to Temptation', 'c0b258f641e17da5b9ffc3ea28cd6a10', 'battle_rule_v1:96b2d3623c4036f44092a07cd0feebbd', '{"battle_model_scope":"xmage_fixed_controller_draw_lose_life_spell_v1","count":2,"draw_count":2,"draw_lose_life_spell":true,"effect":"draw_cards","instant":true,"life_loss":2,"sorcery":false,"target_controller":"self","xmage_effect_classes":["DrawCardSourceControllerEffect","LoseLifeSourceControllerEffect"]}'::jsonb, '{"category":"draw","effect":"draw_cards","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class SuccumbToTemptation translated into ManaLoom runtime scope xmage_fixed_controller_draw_lose_life_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
    ('ambition''s cost', 'Ambition''s Cost', '2a807c1035d7b1ce49ba9281a02e946e', 'battle_rule_v1:3b2afd0214c6776da9b668598d824795', '{"battle_model_scope":"xmage_fixed_controller_draw_lose_life_spell_v1","count":3,"draw_count":3,"draw_lose_life_spell":true,"effect":"draw_cards","instant":false,"life_loss":3,"sorcery":true,"target_controller":"self","xmage_effect_classes":["DrawCardSourceControllerEffect","LoseLifeSourceControllerEffect"]}'::jsonb, '{"category":"draw","effect":"draw_cards"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class AmbitionsCost translated into ManaLoom runtime scope xmage_fixed_controller_draw_lose_life_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('ancient craving', 'Ancient Craving', '2a807c1035d7b1ce49ba9281a02e946e', 'battle_rule_v1:3b2afd0214c6776da9b668598d824795', '{"battle_model_scope":"xmage_fixed_controller_draw_lose_life_spell_v1","count":3,"draw_count":3,"draw_lose_life_spell":true,"effect":"draw_cards","instant":false,"life_loss":3,"sorcery":true,"target_controller":"self","xmage_effect_classes":["DrawCardSourceControllerEffect","LoseLifeSourceControllerEffect"]}'::jsonb, '{"category":"draw","effect":"draw_cards"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class AncientCraving translated into ManaLoom runtime scope xmage_fixed_controller_draw_lose_life_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('blood pact', 'Blood Pact', '0e1cca8ed574f916efa7634f28cd7de4', 'battle_rule_v1:e849896e6ab7822b604314a9842236f5', '{"battle_model_scope":"xmage_fixed_target_player_draw_lose_life_spell_v1","count":2,"draw_count":2,"draw_lose_life_spell":true,"effect":"draw_cards","instant":true,"life_loss":2,"sorcery":false,"target":"player","target_constraints":{"players":["any"]},"target_controller":"target_player","target_preference":"self","xmage_effect_classes":["DrawCardTargetEffect","LoseLifeTargetEffect"]}'::jsonb, '{"category":"draw","effect":"draw_cards","target":"player","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class BloodPact translated into ManaLoom runtime scope xmage_fixed_target_player_draw_lose_life_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('harrowing journey', 'Harrowing Journey', '1fee8ed9c8875ba33f2972741b6a3e25', 'battle_rule_v1:e42886e5607833d64538053de3d5de82', '{"battle_model_scope":"xmage_fixed_target_player_draw_lose_life_spell_v1","count":3,"draw_count":3,"draw_lose_life_spell":true,"effect":"draw_cards","instant":false,"life_loss":3,"sorcery":true,"target":"player","target_constraints":{"players":["any"]},"target_controller":"target_player","target_preference":"self","xmage_effect_classes":["DrawCardTargetEffect","LoseLifeTargetEffect"]}'::jsonb, '{"category":"draw","effect":"draw_cards","target":"player"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class HarrowingJourney translated into ManaLoom runtime scope xmage_fixed_target_player_draw_lose_life_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('night''s whisper', 'Night''s Whisper', '99f77dc3d03da6660ecb413593fe23e7', 'battle_rule_v1:4149f6570b19de0fc58fef7eb6736e40', '{"battle_model_scope":"xmage_fixed_controller_draw_lose_life_spell_v1","count":2,"draw_count":2,"draw_lose_life_spell":true,"effect":"draw_cards","instant":false,"life_loss":2,"sorcery":true,"target_controller":"self","xmage_effect_classes":["DrawCardSourceControllerEffect","LoseLifeSourceControllerEffect"]}'::jsonb, '{"category":"draw","effect":"draw_cards"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class NightsWhisper translated into ManaLoom runtime scope xmage_fixed_controller_draw_lose_life_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('painful lesson', 'Painful Lesson', '0e1cca8ed574f916efa7634f28cd7de4', 'battle_rule_v1:3b5e4090931830427bc375568e4786ed', '{"battle_model_scope":"xmage_fixed_target_player_draw_lose_life_spell_v1","count":2,"draw_count":2,"draw_lose_life_spell":true,"effect":"draw_cards","instant":false,"life_loss":2,"sorcery":true,"target":"player","target_constraints":{"players":["any"]},"target_controller":"target_player","target_preference":"self","xmage_effect_classes":["DrawCardTargetEffect","LoseLifeTargetEffect"]}'::jsonb, '{"category":"draw","effect":"draw_cards","target":"player"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class PainfulLesson translated into ManaLoom runtime scope xmage_fixed_target_player_draw_lose_life_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('sign in blood', 'Sign in Blood', '0e1cca8ed574f916efa7634f28cd7de4', 'battle_rule_v1:3b5e4090931830427bc375568e4786ed', '{"battle_model_scope":"xmage_fixed_target_player_draw_lose_life_spell_v1","count":2,"draw_count":2,"draw_lose_life_spell":true,"effect":"draw_cards","instant":false,"life_loss":2,"sorcery":true,"target":"player","target_constraints":{"players":["any"]},"target_controller":"target_player","target_preference":"self","xmage_effect_classes":["DrawCardTargetEffect","LoseLifeTargetEffect"]}'::jsonb, '{"category":"draw","effect":"draw_cards","target":"player"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class SignInBlood translated into ManaLoom runtime scope xmage_fixed_target_player_draw_lose_life_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('succumb to temptation', 'Succumb to Temptation', 'c0b258f641e17da5b9ffc3ea28cd6a10', 'battle_rule_v1:96b2d3623c4036f44092a07cd0feebbd', '{"battle_model_scope":"xmage_fixed_controller_draw_lose_life_spell_v1","count":2,"draw_count":2,"draw_lose_life_spell":true,"effect":"draw_cards","instant":true,"life_loss":2,"sorcery":false,"target_controller":"self","xmage_effect_classes":["DrawCardSourceControllerEffect","LoseLifeSourceControllerEffect"]}'::jsonb, '{"category":"draw","effect":"draw_cards","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class SuccumbToTemptation translated into ManaLoom runtime scope xmage_fixed_controller_draw_lose_life_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
