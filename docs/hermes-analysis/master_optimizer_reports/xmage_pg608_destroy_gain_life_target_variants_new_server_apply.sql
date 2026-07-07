BEGIN;

CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit;

CREATE TABLE IF NOT EXISTS manaloom_deploy_audit.pg608_destroy_gain_life_target_variants_20260707_100806 AS
SELECT *
FROM public.card_battle_rules
WHERE normalized_name IN ('aerial predation', 'dark offering', 'eriette''s lullaby', 'lucky offering', 'noxious grasp', 'poison arrow', 'radiant strike', 'silverstrike', 'surge of righteousness', 'triumphant surge')
   OR normalized_name LIKE 'aerial predation // %'
   OR normalized_name LIKE 'dark offering // %'
   OR normalized_name LIKE 'eriette''s lullaby // %'
   OR normalized_name LIKE 'lucky offering // %'
   OR normalized_name LIKE 'noxious grasp // %'
   OR normalized_name LIKE 'poison arrow // %'
   OR normalized_name LIKE 'radiant strike // %'
   OR normalized_name LIKE 'silverstrike // %'
   OR normalized_name LIKE 'surge of righteousness // %'
   OR normalized_name LIKE 'triumphant surge // %';

DO $$
DECLARE
  v_missing jsonb;
BEGIN
  WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('aerial predation', 'Aerial Predation', 'b2cb8ff88a5f9cb91c99b46c96d78950', 'battle_rule_v1:0e5ac29c17b71bb4879d5d16832f3bca', '{"battle_model_scope":"xmage_destroy_target_and_controller_gain_life_spell_v1","controller_gains_life":2,"destination":"graveyard","effect":"remove_creature","instant":true,"sorcery":false,"target":"flying_creature","target_constraints":{"card_types":["creature"],"required_keywords":["flying"]},"xmage_effect_classes":["DestroyTargetEffect","GainLifeEffect"]}'::jsonb, '{"category":"removal","effect":"remove_creature","target":"flying_creature","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class AerialPredation translated into ManaLoom runtime scope xmage_destroy_target_and_controller_gain_life_spell_v1. This row is package-ready only because the source signature is a narrow fixed destroy-target plus controller life-gain spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('dark offering', 'Dark Offering', '143098df19af20647c9bbc2d7874e72d', 'battle_rule_v1:86330155927d6b3e3f3ba2428cea1c0d', '{"battle_model_scope":"xmage_destroy_target_and_controller_gain_life_spell_v1","controller_gains_life":3,"destination":"graveyard","effect":"remove_creature","instant":false,"sorcery":true,"target":"nonblack_creature","target_constraints":{"card_types":["creature"],"exclude_colors":["B"]},"xmage_effect_classes":["DestroyTargetEffect","GainLifeEffect"]}'::jsonb, '{"category":"removal","effect":"remove_creature","target":"nonblack_creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class DarkOffering translated into ManaLoom runtime scope xmage_destroy_target_and_controller_gain_life_spell_v1. This row is package-ready only because the source signature is a narrow fixed destroy-target plus controller life-gain spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('eriette''s lullaby', 'Eriette''s Lullaby', 'b0c3d7e7072c72605ff87885e8d45ad0', 'battle_rule_v1:7f42d43c8c797438b78b67efb326202f', '{"battle_model_scope":"xmage_destroy_target_and_controller_gain_life_spell_v1","controller_gains_life":2,"destination":"graveyard","effect":"remove_creature","instant":false,"sorcery":true,"target":"tapped_creature","target_constraints":{"card_types":["creature"],"tapped_state":"tapped"},"xmage_effect_classes":["DestroyTargetEffect","GainLifeEffect"]}'::jsonb, '{"category":"removal","effect":"remove_creature","target":"tapped_creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class EriettesLullaby translated into ManaLoom runtime scope xmage_destroy_target_and_controller_gain_life_spell_v1. This row is package-ready only because the source signature is a narrow fixed destroy-target plus controller life-gain spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('lucky offering', 'Lucky Offering', '10b3966d679592b0097e6d74dda6d1c3', 'battle_rule_v1:982867e310f7149aa3336071e323549f', '{"battle_model_scope":"xmage_destroy_target_and_controller_gain_life_spell_v1","controller_gains_life":3,"destination":"graveyard","effect":"remove_permanent","instant":false,"sorcery":true,"target":"artifact_mana_value_3_or_less","target_constraints":{"card_types":["artifact"],"mana_value_max":3},"xmage_effect_classes":["DestroyTargetEffect","GainLifeEffect"]}'::jsonb, '{"category":"removal","effect":"remove_permanent","target":"artifact_mana_value_3_or_less"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class LuckyOffering translated into ManaLoom runtime scope xmage_destroy_target_and_controller_gain_life_spell_v1. This row is package-ready only because the source signature is a narrow fixed destroy-target plus controller life-gain spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('noxious grasp', 'Noxious Grasp', 'a81be47c02993bee84732bd8e9005446', 'battle_rule_v1:76fa402d8900912bcb88ff88721efef4', '{"battle_model_scope":"xmage_destroy_target_and_controller_gain_life_spell_v1","controller_gains_life":1,"destination":"graveyard","effect":"remove_permanent","instant":true,"sorcery":false,"target":"green_or_white_creature_or_planeswalker","target_constraints":{"card_types":["creature","planeswalker"],"target_colors":["G","W"]},"xmage_effect_classes":["DestroyTargetEffect","GainLifeEffect"]}'::jsonb, '{"category":"removal","effect":"remove_permanent","target":"green_or_white_creature_or_planeswalker","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class NoxiousGrasp translated into ManaLoom runtime scope xmage_destroy_target_and_controller_gain_life_spell_v1. This row is package-ready only because the source signature is a narrow fixed destroy-target plus controller life-gain spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('poison arrow', 'Poison Arrow', '143098df19af20647c9bbc2d7874e72d', 'battle_rule_v1:86330155927d6b3e3f3ba2428cea1c0d', '{"battle_model_scope":"xmage_destroy_target_and_controller_gain_life_spell_v1","controller_gains_life":3,"destination":"graveyard","effect":"remove_creature","instant":false,"sorcery":true,"target":"nonblack_creature","target_constraints":{"card_types":["creature"],"exclude_colors":["B"]},"xmage_effect_classes":["DestroyTargetEffect","GainLifeEffect"]}'::jsonb, '{"category":"removal","effect":"remove_creature","target":"nonblack_creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class PoisonArrow translated into ManaLoom runtime scope xmage_destroy_target_and_controller_gain_life_spell_v1. This row is package-ready only because the source signature is a narrow fixed destroy-target plus controller life-gain spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('radiant strike', 'Radiant Strike', '9d1548b9f503a2c3f65bd4856d5b62ea', 'battle_rule_v1:a6b67b3d134b165eeb74b148c3016b36', '{"battle_model_scope":"xmage_destroy_target_and_controller_gain_life_spell_v1","controller_gains_life":3,"destination":"graveyard","effect":"remove_permanent","instant":true,"sorcery":false,"target":"artifact_or_tapped_creature","target_constraints":{"any_of":[{"card_types":["artifact"]},{"card_types":["creature"],"tapped_state":"tapped"}]},"xmage_effect_classes":["DestroyTargetEffect","GainLifeEffect"]}'::jsonb, '{"category":"removal","effect":"remove_permanent","target":"artifact_or_tapped_creature","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class RadiantStrike translated into ManaLoom runtime scope xmage_destroy_target_and_controller_gain_life_spell_v1. This row is package-ready only because the source signature is a narrow fixed destroy-target plus controller life-gain spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('silverstrike', 'Silverstrike', 'd25187a9dd4e987f960cba8a3453f2c8', 'battle_rule_v1:7af59986d8d36daf76a83874661b1b31', '{"battle_model_scope":"xmage_destroy_target_and_controller_gain_life_spell_v1","controller_gains_life":3,"destination":"graveyard","effect":"remove_creature","instant":true,"sorcery":false,"target":"attacking_creature","target_constraints":{"card_types":["creature"],"combat_state":"attacking"},"xmage_effect_classes":["DestroyTargetEffect","GainLifeEffect"]}'::jsonb, '{"category":"removal","effect":"remove_creature","target":"attacking_creature","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Silverstrike translated into ManaLoom runtime scope xmage_destroy_target_and_controller_gain_life_spell_v1. This row is package-ready only because the source signature is a narrow fixed destroy-target plus controller life-gain spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('surge of righteousness', 'Surge of Righteousness', '3924868b9e82affd8785ea508e7406be', 'battle_rule_v1:30063fd54671ccd84a8107ebb7b854cf', '{"battle_model_scope":"xmage_destroy_target_and_controller_gain_life_spell_v1","controller_gains_life":2,"destination":"graveyard","effect":"remove_creature","instant":true,"sorcery":false,"target":"black_or_red_attacking_or_blocking_creature","target_constraints":{"card_types":["creature"],"combat_state":"attacking_or_blocking","target_colors":["B","R"]},"xmage_effect_classes":["DestroyTargetEffect","GainLifeEffect"]}'::jsonb, '{"category":"removal","effect":"remove_creature","target":"black_or_red_attacking_or_blocking_creature","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class SurgeOfRighteousness translated into ManaLoom runtime scope xmage_destroy_target_and_controller_gain_life_spell_v1. This row is package-ready only because the source signature is a narrow fixed destroy-target plus controller life-gain spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('triumphant surge', 'Triumphant Surge', '3d72bcd72bed0ee2e1e98de87f9a60d8', 'battle_rule_v1:e7f6166f5bccea52b3b5bc6235ac68d2', '{"battle_model_scope":"xmage_destroy_target_and_controller_gain_life_spell_v1","controller_gains_life":3,"destination":"graveyard","effect":"remove_creature","instant":true,"sorcery":false,"target":"creature_power_4_or_greater","target_constraints":{"card_types":["creature"],"power_min":4},"xmage_effect_classes":["DestroyTargetEffect","GainLifeEffect"]}'::jsonb, '{"category":"removal","effect":"remove_creature","target":"creature_power_4_or_greater","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class TriumphantSurge translated into ManaLoom runtime scope xmage_destroy_target_and_controller_gain_life_spell_v1. This row is package-ready only because the source signature is a narrow fixed destroy-target plus controller life-gain spell with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
    ('aerial predation', 'Aerial Predation', 'b2cb8ff88a5f9cb91c99b46c96d78950', 'battle_rule_v1:0e5ac29c17b71bb4879d5d16832f3bca', '{"battle_model_scope":"xmage_destroy_target_and_controller_gain_life_spell_v1","controller_gains_life":2,"destination":"graveyard","effect":"remove_creature","instant":true,"sorcery":false,"target":"flying_creature","target_constraints":{"card_types":["creature"],"required_keywords":["flying"]},"xmage_effect_classes":["DestroyTargetEffect","GainLifeEffect"]}'::jsonb, '{"category":"removal","effect":"remove_creature","target":"flying_creature","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class AerialPredation translated into ManaLoom runtime scope xmage_destroy_target_and_controller_gain_life_spell_v1. This row is package-ready only because the source signature is a narrow fixed destroy-target plus controller life-gain spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('dark offering', 'Dark Offering', '143098df19af20647c9bbc2d7874e72d', 'battle_rule_v1:86330155927d6b3e3f3ba2428cea1c0d', '{"battle_model_scope":"xmage_destroy_target_and_controller_gain_life_spell_v1","controller_gains_life":3,"destination":"graveyard","effect":"remove_creature","instant":false,"sorcery":true,"target":"nonblack_creature","target_constraints":{"card_types":["creature"],"exclude_colors":["B"]},"xmage_effect_classes":["DestroyTargetEffect","GainLifeEffect"]}'::jsonb, '{"category":"removal","effect":"remove_creature","target":"nonblack_creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class DarkOffering translated into ManaLoom runtime scope xmage_destroy_target_and_controller_gain_life_spell_v1. This row is package-ready only because the source signature is a narrow fixed destroy-target plus controller life-gain spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('eriette''s lullaby', 'Eriette''s Lullaby', 'b0c3d7e7072c72605ff87885e8d45ad0', 'battle_rule_v1:7f42d43c8c797438b78b67efb326202f', '{"battle_model_scope":"xmage_destroy_target_and_controller_gain_life_spell_v1","controller_gains_life":2,"destination":"graveyard","effect":"remove_creature","instant":false,"sorcery":true,"target":"tapped_creature","target_constraints":{"card_types":["creature"],"tapped_state":"tapped"},"xmage_effect_classes":["DestroyTargetEffect","GainLifeEffect"]}'::jsonb, '{"category":"removal","effect":"remove_creature","target":"tapped_creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class EriettesLullaby translated into ManaLoom runtime scope xmage_destroy_target_and_controller_gain_life_spell_v1. This row is package-ready only because the source signature is a narrow fixed destroy-target plus controller life-gain spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('lucky offering', 'Lucky Offering', '10b3966d679592b0097e6d74dda6d1c3', 'battle_rule_v1:982867e310f7149aa3336071e323549f', '{"battle_model_scope":"xmage_destroy_target_and_controller_gain_life_spell_v1","controller_gains_life":3,"destination":"graveyard","effect":"remove_permanent","instant":false,"sorcery":true,"target":"artifact_mana_value_3_or_less","target_constraints":{"card_types":["artifact"],"mana_value_max":3},"xmage_effect_classes":["DestroyTargetEffect","GainLifeEffect"]}'::jsonb, '{"category":"removal","effect":"remove_permanent","target":"artifact_mana_value_3_or_less"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class LuckyOffering translated into ManaLoom runtime scope xmage_destroy_target_and_controller_gain_life_spell_v1. This row is package-ready only because the source signature is a narrow fixed destroy-target plus controller life-gain spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('noxious grasp', 'Noxious Grasp', 'a81be47c02993bee84732bd8e9005446', 'battle_rule_v1:76fa402d8900912bcb88ff88721efef4', '{"battle_model_scope":"xmage_destroy_target_and_controller_gain_life_spell_v1","controller_gains_life":1,"destination":"graveyard","effect":"remove_permanent","instant":true,"sorcery":false,"target":"green_or_white_creature_or_planeswalker","target_constraints":{"card_types":["creature","planeswalker"],"target_colors":["G","W"]},"xmage_effect_classes":["DestroyTargetEffect","GainLifeEffect"]}'::jsonb, '{"category":"removal","effect":"remove_permanent","target":"green_or_white_creature_or_planeswalker","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class NoxiousGrasp translated into ManaLoom runtime scope xmage_destroy_target_and_controller_gain_life_spell_v1. This row is package-ready only because the source signature is a narrow fixed destroy-target plus controller life-gain spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('poison arrow', 'Poison Arrow', '143098df19af20647c9bbc2d7874e72d', 'battle_rule_v1:86330155927d6b3e3f3ba2428cea1c0d', '{"battle_model_scope":"xmage_destroy_target_and_controller_gain_life_spell_v1","controller_gains_life":3,"destination":"graveyard","effect":"remove_creature","instant":false,"sorcery":true,"target":"nonblack_creature","target_constraints":{"card_types":["creature"],"exclude_colors":["B"]},"xmage_effect_classes":["DestroyTargetEffect","GainLifeEffect"]}'::jsonb, '{"category":"removal","effect":"remove_creature","target":"nonblack_creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class PoisonArrow translated into ManaLoom runtime scope xmage_destroy_target_and_controller_gain_life_spell_v1. This row is package-ready only because the source signature is a narrow fixed destroy-target plus controller life-gain spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('radiant strike', 'Radiant Strike', '9d1548b9f503a2c3f65bd4856d5b62ea', 'battle_rule_v1:a6b67b3d134b165eeb74b148c3016b36', '{"battle_model_scope":"xmage_destroy_target_and_controller_gain_life_spell_v1","controller_gains_life":3,"destination":"graveyard","effect":"remove_permanent","instant":true,"sorcery":false,"target":"artifact_or_tapped_creature","target_constraints":{"any_of":[{"card_types":["artifact"]},{"card_types":["creature"],"tapped_state":"tapped"}]},"xmage_effect_classes":["DestroyTargetEffect","GainLifeEffect"]}'::jsonb, '{"category":"removal","effect":"remove_permanent","target":"artifact_or_tapped_creature","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class RadiantStrike translated into ManaLoom runtime scope xmage_destroy_target_and_controller_gain_life_spell_v1. This row is package-ready only because the source signature is a narrow fixed destroy-target plus controller life-gain spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('silverstrike', 'Silverstrike', 'd25187a9dd4e987f960cba8a3453f2c8', 'battle_rule_v1:7af59986d8d36daf76a83874661b1b31', '{"battle_model_scope":"xmage_destroy_target_and_controller_gain_life_spell_v1","controller_gains_life":3,"destination":"graveyard","effect":"remove_creature","instant":true,"sorcery":false,"target":"attacking_creature","target_constraints":{"card_types":["creature"],"combat_state":"attacking"},"xmage_effect_classes":["DestroyTargetEffect","GainLifeEffect"]}'::jsonb, '{"category":"removal","effect":"remove_creature","target":"attacking_creature","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Silverstrike translated into ManaLoom runtime scope xmage_destroy_target_and_controller_gain_life_spell_v1. This row is package-ready only because the source signature is a narrow fixed destroy-target plus controller life-gain spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('surge of righteousness', 'Surge of Righteousness', '3924868b9e82affd8785ea508e7406be', 'battle_rule_v1:30063fd54671ccd84a8107ebb7b854cf', '{"battle_model_scope":"xmage_destroy_target_and_controller_gain_life_spell_v1","controller_gains_life":2,"destination":"graveyard","effect":"remove_creature","instant":true,"sorcery":false,"target":"black_or_red_attacking_or_blocking_creature","target_constraints":{"card_types":["creature"],"combat_state":"attacking_or_blocking","target_colors":["B","R"]},"xmage_effect_classes":["DestroyTargetEffect","GainLifeEffect"]}'::jsonb, '{"category":"removal","effect":"remove_creature","target":"black_or_red_attacking_or_blocking_creature","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class SurgeOfRighteousness translated into ManaLoom runtime scope xmage_destroy_target_and_controller_gain_life_spell_v1. This row is package-ready only because the source signature is a narrow fixed destroy-target plus controller life-gain spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('triumphant surge', 'Triumphant Surge', '3d72bcd72bed0ee2e1e98de87f9a60d8', 'battle_rule_v1:e7f6166f5bccea52b3b5bc6235ac68d2', '{"battle_model_scope":"xmage_destroy_target_and_controller_gain_life_spell_v1","controller_gains_life":3,"destination":"graveyard","effect":"remove_creature","instant":true,"sorcery":false,"target":"creature_power_4_or_greater","target_constraints":{"card_types":["creature"],"power_min":4},"xmage_effect_classes":["DestroyTargetEffect","GainLifeEffect"]}'::jsonb, '{"category":"removal","effect":"remove_creature","target":"creature_power_4_or_greater","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class TriumphantSurge translated into ManaLoom runtime scope xmage_destroy_target_and_controller_gain_life_spell_v1. This row is package-ready only because the source signature is a narrow fixed destroy-target plus controller life-gain spell with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
    ('aerial predation', 'Aerial Predation', 'b2cb8ff88a5f9cb91c99b46c96d78950', 'battle_rule_v1:0e5ac29c17b71bb4879d5d16832f3bca', '{"battle_model_scope":"xmage_destroy_target_and_controller_gain_life_spell_v1","controller_gains_life":2,"destination":"graveyard","effect":"remove_creature","instant":true,"sorcery":false,"target":"flying_creature","target_constraints":{"card_types":["creature"],"required_keywords":["flying"]},"xmage_effect_classes":["DestroyTargetEffect","GainLifeEffect"]}'::jsonb, '{"category":"removal","effect":"remove_creature","target":"flying_creature","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class AerialPredation translated into ManaLoom runtime scope xmage_destroy_target_and_controller_gain_life_spell_v1. This row is package-ready only because the source signature is a narrow fixed destroy-target plus controller life-gain spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('dark offering', 'Dark Offering', '143098df19af20647c9bbc2d7874e72d', 'battle_rule_v1:86330155927d6b3e3f3ba2428cea1c0d', '{"battle_model_scope":"xmage_destroy_target_and_controller_gain_life_spell_v1","controller_gains_life":3,"destination":"graveyard","effect":"remove_creature","instant":false,"sorcery":true,"target":"nonblack_creature","target_constraints":{"card_types":["creature"],"exclude_colors":["B"]},"xmage_effect_classes":["DestroyTargetEffect","GainLifeEffect"]}'::jsonb, '{"category":"removal","effect":"remove_creature","target":"nonblack_creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class DarkOffering translated into ManaLoom runtime scope xmage_destroy_target_and_controller_gain_life_spell_v1. This row is package-ready only because the source signature is a narrow fixed destroy-target plus controller life-gain spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('eriette''s lullaby', 'Eriette''s Lullaby', 'b0c3d7e7072c72605ff87885e8d45ad0', 'battle_rule_v1:7f42d43c8c797438b78b67efb326202f', '{"battle_model_scope":"xmage_destroy_target_and_controller_gain_life_spell_v1","controller_gains_life":2,"destination":"graveyard","effect":"remove_creature","instant":false,"sorcery":true,"target":"tapped_creature","target_constraints":{"card_types":["creature"],"tapped_state":"tapped"},"xmage_effect_classes":["DestroyTargetEffect","GainLifeEffect"]}'::jsonb, '{"category":"removal","effect":"remove_creature","target":"tapped_creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class EriettesLullaby translated into ManaLoom runtime scope xmage_destroy_target_and_controller_gain_life_spell_v1. This row is package-ready only because the source signature is a narrow fixed destroy-target plus controller life-gain spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('lucky offering', 'Lucky Offering', '10b3966d679592b0097e6d74dda6d1c3', 'battle_rule_v1:982867e310f7149aa3336071e323549f', '{"battle_model_scope":"xmage_destroy_target_and_controller_gain_life_spell_v1","controller_gains_life":3,"destination":"graveyard","effect":"remove_permanent","instant":false,"sorcery":true,"target":"artifact_mana_value_3_or_less","target_constraints":{"card_types":["artifact"],"mana_value_max":3},"xmage_effect_classes":["DestroyTargetEffect","GainLifeEffect"]}'::jsonb, '{"category":"removal","effect":"remove_permanent","target":"artifact_mana_value_3_or_less"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class LuckyOffering translated into ManaLoom runtime scope xmage_destroy_target_and_controller_gain_life_spell_v1. This row is package-ready only because the source signature is a narrow fixed destroy-target plus controller life-gain spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('noxious grasp', 'Noxious Grasp', 'a81be47c02993bee84732bd8e9005446', 'battle_rule_v1:76fa402d8900912bcb88ff88721efef4', '{"battle_model_scope":"xmage_destroy_target_and_controller_gain_life_spell_v1","controller_gains_life":1,"destination":"graveyard","effect":"remove_permanent","instant":true,"sorcery":false,"target":"green_or_white_creature_or_planeswalker","target_constraints":{"card_types":["creature","planeswalker"],"target_colors":["G","W"]},"xmage_effect_classes":["DestroyTargetEffect","GainLifeEffect"]}'::jsonb, '{"category":"removal","effect":"remove_permanent","target":"green_or_white_creature_or_planeswalker","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class NoxiousGrasp translated into ManaLoom runtime scope xmage_destroy_target_and_controller_gain_life_spell_v1. This row is package-ready only because the source signature is a narrow fixed destroy-target plus controller life-gain spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('poison arrow', 'Poison Arrow', '143098df19af20647c9bbc2d7874e72d', 'battle_rule_v1:86330155927d6b3e3f3ba2428cea1c0d', '{"battle_model_scope":"xmage_destroy_target_and_controller_gain_life_spell_v1","controller_gains_life":3,"destination":"graveyard","effect":"remove_creature","instant":false,"sorcery":true,"target":"nonblack_creature","target_constraints":{"card_types":["creature"],"exclude_colors":["B"]},"xmage_effect_classes":["DestroyTargetEffect","GainLifeEffect"]}'::jsonb, '{"category":"removal","effect":"remove_creature","target":"nonblack_creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class PoisonArrow translated into ManaLoom runtime scope xmage_destroy_target_and_controller_gain_life_spell_v1. This row is package-ready only because the source signature is a narrow fixed destroy-target plus controller life-gain spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('radiant strike', 'Radiant Strike', '9d1548b9f503a2c3f65bd4856d5b62ea', 'battle_rule_v1:a6b67b3d134b165eeb74b148c3016b36', '{"battle_model_scope":"xmage_destroy_target_and_controller_gain_life_spell_v1","controller_gains_life":3,"destination":"graveyard","effect":"remove_permanent","instant":true,"sorcery":false,"target":"artifact_or_tapped_creature","target_constraints":{"any_of":[{"card_types":["artifact"]},{"card_types":["creature"],"tapped_state":"tapped"}]},"xmage_effect_classes":["DestroyTargetEffect","GainLifeEffect"]}'::jsonb, '{"category":"removal","effect":"remove_permanent","target":"artifact_or_tapped_creature","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class RadiantStrike translated into ManaLoom runtime scope xmage_destroy_target_and_controller_gain_life_spell_v1. This row is package-ready only because the source signature is a narrow fixed destroy-target plus controller life-gain spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('silverstrike', 'Silverstrike', 'd25187a9dd4e987f960cba8a3453f2c8', 'battle_rule_v1:7af59986d8d36daf76a83874661b1b31', '{"battle_model_scope":"xmage_destroy_target_and_controller_gain_life_spell_v1","controller_gains_life":3,"destination":"graveyard","effect":"remove_creature","instant":true,"sorcery":false,"target":"attacking_creature","target_constraints":{"card_types":["creature"],"combat_state":"attacking"},"xmage_effect_classes":["DestroyTargetEffect","GainLifeEffect"]}'::jsonb, '{"category":"removal","effect":"remove_creature","target":"attacking_creature","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Silverstrike translated into ManaLoom runtime scope xmage_destroy_target_and_controller_gain_life_spell_v1. This row is package-ready only because the source signature is a narrow fixed destroy-target plus controller life-gain spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('surge of righteousness', 'Surge of Righteousness', '3924868b9e82affd8785ea508e7406be', 'battle_rule_v1:30063fd54671ccd84a8107ebb7b854cf', '{"battle_model_scope":"xmage_destroy_target_and_controller_gain_life_spell_v1","controller_gains_life":2,"destination":"graveyard","effect":"remove_creature","instant":true,"sorcery":false,"target":"black_or_red_attacking_or_blocking_creature","target_constraints":{"card_types":["creature"],"combat_state":"attacking_or_blocking","target_colors":["B","R"]},"xmage_effect_classes":["DestroyTargetEffect","GainLifeEffect"]}'::jsonb, '{"category":"removal","effect":"remove_creature","target":"black_or_red_attacking_or_blocking_creature","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class SurgeOfRighteousness translated into ManaLoom runtime scope xmage_destroy_target_and_controller_gain_life_spell_v1. This row is package-ready only because the source signature is a narrow fixed destroy-target plus controller life-gain spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('triumphant surge', 'Triumphant Surge', '3d72bcd72bed0ee2e1e98de87f9a60d8', 'battle_rule_v1:e7f6166f5bccea52b3b5bc6235ac68d2', '{"battle_model_scope":"xmage_destroy_target_and_controller_gain_life_spell_v1","controller_gains_life":3,"destination":"graveyard","effect":"remove_creature","instant":true,"sorcery":false,"target":"creature_power_4_or_greater","target_constraints":{"card_types":["creature"],"power_min":4},"xmage_effect_classes":["DestroyTargetEffect","GainLifeEffect"]}'::jsonb, '{"category":"removal","effect":"remove_creature","target":"creature_power_4_or_greater","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class TriumphantSurge translated into ManaLoom runtime scope xmage_destroy_target_and_controller_gain_life_spell_v1. This row is package-ready only because the source signature is a narrow fixed destroy-target plus controller life-gain spell with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
