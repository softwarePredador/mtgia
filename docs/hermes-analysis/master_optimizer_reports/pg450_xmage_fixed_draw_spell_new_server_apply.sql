BEGIN;

CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit;

CREATE TABLE IF NOT EXISTS manaloom_deploy_audit.pg450_xmage_fixed_draw_spell_new_server_20260704_233122 AS
SELECT *
FROM public.card_battle_rules
WHERE normalized_name IN ('altar''s reap', 'blood divination', 'corrupted conviction', 'costly plunder', 'eviscerator''s insight', 'magmatic insight', 'morbid curiosity', 'skulltap', 'tormenting voice', 'village rites', 'vivisection', 'wild guess')
   OR normalized_name LIKE 'altar''s reap // %'
   OR normalized_name LIKE 'blood divination // %'
   OR normalized_name LIKE 'corrupted conviction // %'
   OR normalized_name LIKE 'costly plunder // %'
   OR normalized_name LIKE 'eviscerator''s insight // %'
   OR normalized_name LIKE 'magmatic insight // %'
   OR normalized_name LIKE 'morbid curiosity // %'
   OR normalized_name LIKE 'skulltap // %'
   OR normalized_name LIKE 'tormenting voice // %'
   OR normalized_name LIKE 'village rites // %'
   OR normalized_name LIKE 'vivisection // %'
   OR normalized_name LIKE 'wild guess // %';

DO $$
DECLARE
  v_missing jsonb;
BEGIN
  WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('altar''s reap', 'Altar''s Reap', '4ae4120d3d74dc3a1b72f930e1d4fdb0', 'battle_rule_v1:4cd51293e000d79e1389268f7a442ea2', '{"additional_cost":"sacrifice_creature","battle_model_scope":"xmage_fixed_source_controller_draw_spell_v1","count":2,"effect":"draw_cards","instant":true,"requires_sacrifice_creature":true,"sorcery":false,"xmage_additional_cost_class":"SacrificeTargetCost","xmage_additional_cost_target":"creature","xmage_effect_class":"DrawCardSourceControllerEffect"}'::jsonb, '{"category":"draw","effect":"draw_cards","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class AltarsReap translated into ManaLoom runtime scope xmage_fixed_source_controller_draw_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('blood divination', 'Blood Divination', '673d2e5b32cae23064c95c517a0027eb', 'battle_rule_v1:a6eaaf5e281f76100c9bffdc779e9608', '{"additional_cost":"sacrifice_creature","battle_model_scope":"xmage_fixed_source_controller_draw_spell_v1","count":3,"effect":"draw_cards","instant":false,"requires_sacrifice_creature":true,"sorcery":true,"xmage_additional_cost_class":"SacrificeTargetCost","xmage_additional_cost_target":"creature","xmage_effect_class":"DrawCardSourceControllerEffect"}'::jsonb, '{"category":"draw","effect":"draw_cards"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class BloodDivination translated into ManaLoom runtime scope xmage_fixed_source_controller_draw_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('corrupted conviction', 'Corrupted Conviction', '4ae4120d3d74dc3a1b72f930e1d4fdb0', 'battle_rule_v1:4cd51293e000d79e1389268f7a442ea2', '{"additional_cost":"sacrifice_creature","battle_model_scope":"xmage_fixed_source_controller_draw_spell_v1","count":2,"effect":"draw_cards","instant":true,"requires_sacrifice_creature":true,"sorcery":false,"xmage_additional_cost_class":"SacrificeTargetCost","xmage_additional_cost_target":"creature","xmage_effect_class":"DrawCardSourceControllerEffect"}'::jsonb, '{"category":"draw","effect":"draw_cards","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class CorruptedConviction translated into ManaLoom runtime scope xmage_fixed_source_controller_draw_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('costly plunder', 'Costly Plunder', '84da77cf84c1f1e0dd6871f3694d69e6', 'battle_rule_v1:e2ae9a881c3814ca8cb290d9c51f3747', '{"additional_cost":"sacrifice_artifact_or_creature","battle_model_scope":"xmage_fixed_source_controller_draw_spell_v1","count":2,"effect":"draw_cards","instant":true,"requires_sacrifice_artifact_or_creature":true,"sorcery":false,"xmage_additional_cost_class":"SacrificeTargetCost","xmage_additional_cost_target":"artifact_or_creature","xmage_effect_class":"DrawCardSourceControllerEffect"}'::jsonb, '{"category":"draw","effect":"draw_cards","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class CostlyPlunder translated into ManaLoom runtime scope xmage_fixed_source_controller_draw_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('eviscerator''s insight', 'Eviscerator''s Insight', 'ca7da5d236140d33d01189b3510dcdeb', 'battle_rule_v1:e2ae9a881c3814ca8cb290d9c51f3747', '{"additional_cost":"sacrifice_artifact_or_creature","battle_model_scope":"xmage_fixed_source_controller_draw_spell_v1","count":2,"effect":"draw_cards","instant":true,"requires_sacrifice_artifact_or_creature":true,"sorcery":false,"xmage_additional_cost_class":"SacrificeTargetCost","xmage_additional_cost_target":"artifact_or_creature","xmage_effect_class":"DrawCardSourceControllerEffect"}'::jsonb, '{"category":"draw","effect":"draw_cards","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class EvisceratorsInsight translated into ManaLoom runtime scope xmage_fixed_source_controller_draw_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('magmatic insight', 'Magmatic Insight', '473bae0f7df2ba37e68718cd5ccc7f2f', 'battle_rule_v1:675d4fcd2437904067cdc1f4b111a5c2', '{"additional_cost":"discard_land","battle_model_scope":"xmage_fixed_source_controller_draw_spell_v1","count":2,"effect":"draw_cards","instant":false,"requires_discard_land":true,"sorcery":true,"xmage_additional_cost_class":"DiscardTargetCost","xmage_additional_cost_target":"land","xmage_effect_class":"DrawCardSourceControllerEffect"}'::jsonb, '{"category":"draw","effect":"draw_cards"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class MagmaticInsight translated into ManaLoom runtime scope xmage_fixed_source_controller_draw_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('morbid curiosity', 'Morbid Curiosity', '914abef9d9dc0dfeb33d5d64c8c01ecd', 'battle_rule_v1:859624352dbbdcf775e576fe8623cacb', '{"additional_cost":"sacrifice_artifact_or_creature","battle_model_scope":"xmage_fixed_source_controller_draw_spell_v1","count":1,"effect":"draw_cards","instant":false,"requires_sacrifice_artifact_or_creature":true,"sorcery":true,"xmage_additional_cost_class":"SacrificeTargetCost","xmage_additional_cost_target":"artifact_or_creature","xmage_effect_class":"DrawCardSourceControllerEffect"}'::jsonb, '{"category":"draw","effect":"draw_cards"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class MorbidCuriosity translated into ManaLoom runtime scope xmage_fixed_source_controller_draw_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('skulltap', 'Skulltap', '4ae4120d3d74dc3a1b72f930e1d4fdb0', 'battle_rule_v1:0581d3a32ff3d5c6aab372ecc4732b66', '{"additional_cost":"sacrifice_creature","battle_model_scope":"xmage_fixed_source_controller_draw_spell_v1","count":2,"effect":"draw_cards","instant":false,"requires_sacrifice_creature":true,"sorcery":true,"xmage_additional_cost_class":"SacrificeTargetCost","xmage_additional_cost_target":"creature","xmage_effect_class":"DrawCardSourceControllerEffect"}'::jsonb, '{"category":"draw","effect":"draw_cards"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Skulltap translated into ManaLoom runtime scope xmage_fixed_source_controller_draw_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('tormenting voice', 'Tormenting Voice', '82c625909b3e6d29d4fa95e933cfc80e', 'battle_rule_v1:ea8f354cc237e842e7ffa5a03390d09f', '{"additional_cost":"discard_card","battle_model_scope":"xmage_fixed_source_controller_draw_spell_v1","count":2,"effect":"draw_cards","instant":false,"requires_discard_card":true,"sorcery":true,"xmage_additional_cost_class":"DiscardCardCost","xmage_additional_cost_target":"card","xmage_effect_class":"DrawCardSourceControllerEffect"}'::jsonb, '{"category":"draw","effect":"draw_cards"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class TormentingVoice translated into ManaLoom runtime scope xmage_fixed_source_controller_draw_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('village rites', 'Village Rites', '4ae4120d3d74dc3a1b72f930e1d4fdb0', 'battle_rule_v1:4cd51293e000d79e1389268f7a442ea2', '{"additional_cost":"sacrifice_creature","battle_model_scope":"xmage_fixed_source_controller_draw_spell_v1","count":2,"effect":"draw_cards","instant":true,"requires_sacrifice_creature":true,"sorcery":false,"xmage_additional_cost_class":"SacrificeTargetCost","xmage_additional_cost_target":"creature","xmage_effect_class":"DrawCardSourceControllerEffect"}'::jsonb, '{"category":"draw","effect":"draw_cards","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class VillageRites translated into ManaLoom runtime scope xmage_fixed_source_controller_draw_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('vivisection', 'Vivisection', '673d2e5b32cae23064c95c517a0027eb', 'battle_rule_v1:a6eaaf5e281f76100c9bffdc779e9608', '{"additional_cost":"sacrifice_creature","battle_model_scope":"xmage_fixed_source_controller_draw_spell_v1","count":3,"effect":"draw_cards","instant":false,"requires_sacrifice_creature":true,"sorcery":true,"xmage_additional_cost_class":"SacrificeTargetCost","xmage_additional_cost_target":"creature","xmage_effect_class":"DrawCardSourceControllerEffect"}'::jsonb, '{"category":"draw","effect":"draw_cards"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Vivisection translated into ManaLoom runtime scope xmage_fixed_source_controller_draw_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('wild guess', 'Wild Guess', '82c625909b3e6d29d4fa95e933cfc80e', 'battle_rule_v1:ea8f354cc237e842e7ffa5a03390d09f', '{"additional_cost":"discard_card","battle_model_scope":"xmage_fixed_source_controller_draw_spell_v1","count":2,"effect":"draw_cards","instant":false,"requires_discard_card":true,"sorcery":true,"xmage_additional_cost_class":"DiscardCardCost","xmage_additional_cost_target":"card","xmage_effect_class":"DrawCardSourceControllerEffect"}'::jsonb, '{"category":"draw","effect":"draw_cards"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class WildGuess translated into ManaLoom runtime scope xmage_fixed_source_controller_draw_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
    ('altar''s reap', 'Altar''s Reap', '4ae4120d3d74dc3a1b72f930e1d4fdb0', 'battle_rule_v1:4cd51293e000d79e1389268f7a442ea2', '{"additional_cost":"sacrifice_creature","battle_model_scope":"xmage_fixed_source_controller_draw_spell_v1","count":2,"effect":"draw_cards","instant":true,"requires_sacrifice_creature":true,"sorcery":false,"xmage_additional_cost_class":"SacrificeTargetCost","xmage_additional_cost_target":"creature","xmage_effect_class":"DrawCardSourceControllerEffect"}'::jsonb, '{"category":"draw","effect":"draw_cards","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class AltarsReap translated into ManaLoom runtime scope xmage_fixed_source_controller_draw_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('blood divination', 'Blood Divination', '673d2e5b32cae23064c95c517a0027eb', 'battle_rule_v1:a6eaaf5e281f76100c9bffdc779e9608', '{"additional_cost":"sacrifice_creature","battle_model_scope":"xmage_fixed_source_controller_draw_spell_v1","count":3,"effect":"draw_cards","instant":false,"requires_sacrifice_creature":true,"sorcery":true,"xmage_additional_cost_class":"SacrificeTargetCost","xmage_additional_cost_target":"creature","xmage_effect_class":"DrawCardSourceControllerEffect"}'::jsonb, '{"category":"draw","effect":"draw_cards"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class BloodDivination translated into ManaLoom runtime scope xmage_fixed_source_controller_draw_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('corrupted conviction', 'Corrupted Conviction', '4ae4120d3d74dc3a1b72f930e1d4fdb0', 'battle_rule_v1:4cd51293e000d79e1389268f7a442ea2', '{"additional_cost":"sacrifice_creature","battle_model_scope":"xmage_fixed_source_controller_draw_spell_v1","count":2,"effect":"draw_cards","instant":true,"requires_sacrifice_creature":true,"sorcery":false,"xmage_additional_cost_class":"SacrificeTargetCost","xmage_additional_cost_target":"creature","xmage_effect_class":"DrawCardSourceControllerEffect"}'::jsonb, '{"category":"draw","effect":"draw_cards","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class CorruptedConviction translated into ManaLoom runtime scope xmage_fixed_source_controller_draw_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('costly plunder', 'Costly Plunder', '84da77cf84c1f1e0dd6871f3694d69e6', 'battle_rule_v1:e2ae9a881c3814ca8cb290d9c51f3747', '{"additional_cost":"sacrifice_artifact_or_creature","battle_model_scope":"xmage_fixed_source_controller_draw_spell_v1","count":2,"effect":"draw_cards","instant":true,"requires_sacrifice_artifact_or_creature":true,"sorcery":false,"xmage_additional_cost_class":"SacrificeTargetCost","xmage_additional_cost_target":"artifact_or_creature","xmage_effect_class":"DrawCardSourceControllerEffect"}'::jsonb, '{"category":"draw","effect":"draw_cards","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class CostlyPlunder translated into ManaLoom runtime scope xmage_fixed_source_controller_draw_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('eviscerator''s insight', 'Eviscerator''s Insight', 'ca7da5d236140d33d01189b3510dcdeb', 'battle_rule_v1:e2ae9a881c3814ca8cb290d9c51f3747', '{"additional_cost":"sacrifice_artifact_or_creature","battle_model_scope":"xmage_fixed_source_controller_draw_spell_v1","count":2,"effect":"draw_cards","instant":true,"requires_sacrifice_artifact_or_creature":true,"sorcery":false,"xmage_additional_cost_class":"SacrificeTargetCost","xmage_additional_cost_target":"artifact_or_creature","xmage_effect_class":"DrawCardSourceControllerEffect"}'::jsonb, '{"category":"draw","effect":"draw_cards","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class EvisceratorsInsight translated into ManaLoom runtime scope xmage_fixed_source_controller_draw_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('magmatic insight', 'Magmatic Insight', '473bae0f7df2ba37e68718cd5ccc7f2f', 'battle_rule_v1:675d4fcd2437904067cdc1f4b111a5c2', '{"additional_cost":"discard_land","battle_model_scope":"xmage_fixed_source_controller_draw_spell_v1","count":2,"effect":"draw_cards","instant":false,"requires_discard_land":true,"sorcery":true,"xmage_additional_cost_class":"DiscardTargetCost","xmage_additional_cost_target":"land","xmage_effect_class":"DrawCardSourceControllerEffect"}'::jsonb, '{"category":"draw","effect":"draw_cards"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class MagmaticInsight translated into ManaLoom runtime scope xmage_fixed_source_controller_draw_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('morbid curiosity', 'Morbid Curiosity', '914abef9d9dc0dfeb33d5d64c8c01ecd', 'battle_rule_v1:859624352dbbdcf775e576fe8623cacb', '{"additional_cost":"sacrifice_artifact_or_creature","battle_model_scope":"xmage_fixed_source_controller_draw_spell_v1","count":1,"effect":"draw_cards","instant":false,"requires_sacrifice_artifact_or_creature":true,"sorcery":true,"xmage_additional_cost_class":"SacrificeTargetCost","xmage_additional_cost_target":"artifact_or_creature","xmage_effect_class":"DrawCardSourceControllerEffect"}'::jsonb, '{"category":"draw","effect":"draw_cards"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class MorbidCuriosity translated into ManaLoom runtime scope xmage_fixed_source_controller_draw_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('skulltap', 'Skulltap', '4ae4120d3d74dc3a1b72f930e1d4fdb0', 'battle_rule_v1:0581d3a32ff3d5c6aab372ecc4732b66', '{"additional_cost":"sacrifice_creature","battle_model_scope":"xmage_fixed_source_controller_draw_spell_v1","count":2,"effect":"draw_cards","instant":false,"requires_sacrifice_creature":true,"sorcery":true,"xmage_additional_cost_class":"SacrificeTargetCost","xmage_additional_cost_target":"creature","xmage_effect_class":"DrawCardSourceControllerEffect"}'::jsonb, '{"category":"draw","effect":"draw_cards"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Skulltap translated into ManaLoom runtime scope xmage_fixed_source_controller_draw_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('tormenting voice', 'Tormenting Voice', '82c625909b3e6d29d4fa95e933cfc80e', 'battle_rule_v1:ea8f354cc237e842e7ffa5a03390d09f', '{"additional_cost":"discard_card","battle_model_scope":"xmage_fixed_source_controller_draw_spell_v1","count":2,"effect":"draw_cards","instant":false,"requires_discard_card":true,"sorcery":true,"xmage_additional_cost_class":"DiscardCardCost","xmage_additional_cost_target":"card","xmage_effect_class":"DrawCardSourceControllerEffect"}'::jsonb, '{"category":"draw","effect":"draw_cards"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class TormentingVoice translated into ManaLoom runtime scope xmage_fixed_source_controller_draw_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('village rites', 'Village Rites', '4ae4120d3d74dc3a1b72f930e1d4fdb0', 'battle_rule_v1:4cd51293e000d79e1389268f7a442ea2', '{"additional_cost":"sacrifice_creature","battle_model_scope":"xmage_fixed_source_controller_draw_spell_v1","count":2,"effect":"draw_cards","instant":true,"requires_sacrifice_creature":true,"sorcery":false,"xmage_additional_cost_class":"SacrificeTargetCost","xmage_additional_cost_target":"creature","xmage_effect_class":"DrawCardSourceControllerEffect"}'::jsonb, '{"category":"draw","effect":"draw_cards","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class VillageRites translated into ManaLoom runtime scope xmage_fixed_source_controller_draw_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('vivisection', 'Vivisection', '673d2e5b32cae23064c95c517a0027eb', 'battle_rule_v1:a6eaaf5e281f76100c9bffdc779e9608', '{"additional_cost":"sacrifice_creature","battle_model_scope":"xmage_fixed_source_controller_draw_spell_v1","count":3,"effect":"draw_cards","instant":false,"requires_sacrifice_creature":true,"sorcery":true,"xmage_additional_cost_class":"SacrificeTargetCost","xmage_additional_cost_target":"creature","xmage_effect_class":"DrawCardSourceControllerEffect"}'::jsonb, '{"category":"draw","effect":"draw_cards"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Vivisection translated into ManaLoom runtime scope xmage_fixed_source_controller_draw_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('wild guess', 'Wild Guess', '82c625909b3e6d29d4fa95e933cfc80e', 'battle_rule_v1:ea8f354cc237e842e7ffa5a03390d09f', '{"additional_cost":"discard_card","battle_model_scope":"xmage_fixed_source_controller_draw_spell_v1","count":2,"effect":"draw_cards","instant":false,"requires_discard_card":true,"sorcery":true,"xmage_additional_cost_class":"DiscardCardCost","xmage_additional_cost_target":"card","xmage_effect_class":"DrawCardSourceControllerEffect"}'::jsonb, '{"category":"draw","effect":"draw_cards"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class WildGuess translated into ManaLoom runtime scope xmage_fixed_source_controller_draw_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
    ('altar''s reap', 'Altar''s Reap', '4ae4120d3d74dc3a1b72f930e1d4fdb0', 'battle_rule_v1:4cd51293e000d79e1389268f7a442ea2', '{"additional_cost":"sacrifice_creature","battle_model_scope":"xmage_fixed_source_controller_draw_spell_v1","count":2,"effect":"draw_cards","instant":true,"requires_sacrifice_creature":true,"sorcery":false,"xmage_additional_cost_class":"SacrificeTargetCost","xmage_additional_cost_target":"creature","xmage_effect_class":"DrawCardSourceControllerEffect"}'::jsonb, '{"category":"draw","effect":"draw_cards","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class AltarsReap translated into ManaLoom runtime scope xmage_fixed_source_controller_draw_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('blood divination', 'Blood Divination', '673d2e5b32cae23064c95c517a0027eb', 'battle_rule_v1:a6eaaf5e281f76100c9bffdc779e9608', '{"additional_cost":"sacrifice_creature","battle_model_scope":"xmage_fixed_source_controller_draw_spell_v1","count":3,"effect":"draw_cards","instant":false,"requires_sacrifice_creature":true,"sorcery":true,"xmage_additional_cost_class":"SacrificeTargetCost","xmage_additional_cost_target":"creature","xmage_effect_class":"DrawCardSourceControllerEffect"}'::jsonb, '{"category":"draw","effect":"draw_cards"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class BloodDivination translated into ManaLoom runtime scope xmage_fixed_source_controller_draw_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('corrupted conviction', 'Corrupted Conviction', '4ae4120d3d74dc3a1b72f930e1d4fdb0', 'battle_rule_v1:4cd51293e000d79e1389268f7a442ea2', '{"additional_cost":"sacrifice_creature","battle_model_scope":"xmage_fixed_source_controller_draw_spell_v1","count":2,"effect":"draw_cards","instant":true,"requires_sacrifice_creature":true,"sorcery":false,"xmage_additional_cost_class":"SacrificeTargetCost","xmage_additional_cost_target":"creature","xmage_effect_class":"DrawCardSourceControllerEffect"}'::jsonb, '{"category":"draw","effect":"draw_cards","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class CorruptedConviction translated into ManaLoom runtime scope xmage_fixed_source_controller_draw_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('costly plunder', 'Costly Plunder', '84da77cf84c1f1e0dd6871f3694d69e6', 'battle_rule_v1:e2ae9a881c3814ca8cb290d9c51f3747', '{"additional_cost":"sacrifice_artifact_or_creature","battle_model_scope":"xmage_fixed_source_controller_draw_spell_v1","count":2,"effect":"draw_cards","instant":true,"requires_sacrifice_artifact_or_creature":true,"sorcery":false,"xmage_additional_cost_class":"SacrificeTargetCost","xmage_additional_cost_target":"artifact_or_creature","xmage_effect_class":"DrawCardSourceControllerEffect"}'::jsonb, '{"category":"draw","effect":"draw_cards","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class CostlyPlunder translated into ManaLoom runtime scope xmage_fixed_source_controller_draw_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('eviscerator''s insight', 'Eviscerator''s Insight', 'ca7da5d236140d33d01189b3510dcdeb', 'battle_rule_v1:e2ae9a881c3814ca8cb290d9c51f3747', '{"additional_cost":"sacrifice_artifact_or_creature","battle_model_scope":"xmage_fixed_source_controller_draw_spell_v1","count":2,"effect":"draw_cards","instant":true,"requires_sacrifice_artifact_or_creature":true,"sorcery":false,"xmage_additional_cost_class":"SacrificeTargetCost","xmage_additional_cost_target":"artifact_or_creature","xmage_effect_class":"DrawCardSourceControllerEffect"}'::jsonb, '{"category":"draw","effect":"draw_cards","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class EvisceratorsInsight translated into ManaLoom runtime scope xmage_fixed_source_controller_draw_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('magmatic insight', 'Magmatic Insight', '473bae0f7df2ba37e68718cd5ccc7f2f', 'battle_rule_v1:675d4fcd2437904067cdc1f4b111a5c2', '{"additional_cost":"discard_land","battle_model_scope":"xmage_fixed_source_controller_draw_spell_v1","count":2,"effect":"draw_cards","instant":false,"requires_discard_land":true,"sorcery":true,"xmage_additional_cost_class":"DiscardTargetCost","xmage_additional_cost_target":"land","xmage_effect_class":"DrawCardSourceControllerEffect"}'::jsonb, '{"category":"draw","effect":"draw_cards"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class MagmaticInsight translated into ManaLoom runtime scope xmage_fixed_source_controller_draw_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('morbid curiosity', 'Morbid Curiosity', '914abef9d9dc0dfeb33d5d64c8c01ecd', 'battle_rule_v1:859624352dbbdcf775e576fe8623cacb', '{"additional_cost":"sacrifice_artifact_or_creature","battle_model_scope":"xmage_fixed_source_controller_draw_spell_v1","count":1,"effect":"draw_cards","instant":false,"requires_sacrifice_artifact_or_creature":true,"sorcery":true,"xmage_additional_cost_class":"SacrificeTargetCost","xmage_additional_cost_target":"artifact_or_creature","xmage_effect_class":"DrawCardSourceControllerEffect"}'::jsonb, '{"category":"draw","effect":"draw_cards"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class MorbidCuriosity translated into ManaLoom runtime scope xmage_fixed_source_controller_draw_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('skulltap', 'Skulltap', '4ae4120d3d74dc3a1b72f930e1d4fdb0', 'battle_rule_v1:0581d3a32ff3d5c6aab372ecc4732b66', '{"additional_cost":"sacrifice_creature","battle_model_scope":"xmage_fixed_source_controller_draw_spell_v1","count":2,"effect":"draw_cards","instant":false,"requires_sacrifice_creature":true,"sorcery":true,"xmage_additional_cost_class":"SacrificeTargetCost","xmage_additional_cost_target":"creature","xmage_effect_class":"DrawCardSourceControllerEffect"}'::jsonb, '{"category":"draw","effect":"draw_cards"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Skulltap translated into ManaLoom runtime scope xmage_fixed_source_controller_draw_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('tormenting voice', 'Tormenting Voice', '82c625909b3e6d29d4fa95e933cfc80e', 'battle_rule_v1:ea8f354cc237e842e7ffa5a03390d09f', '{"additional_cost":"discard_card","battle_model_scope":"xmage_fixed_source_controller_draw_spell_v1","count":2,"effect":"draw_cards","instant":false,"requires_discard_card":true,"sorcery":true,"xmage_additional_cost_class":"DiscardCardCost","xmage_additional_cost_target":"card","xmage_effect_class":"DrawCardSourceControllerEffect"}'::jsonb, '{"category":"draw","effect":"draw_cards"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class TormentingVoice translated into ManaLoom runtime scope xmage_fixed_source_controller_draw_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('village rites', 'Village Rites', '4ae4120d3d74dc3a1b72f930e1d4fdb0', 'battle_rule_v1:4cd51293e000d79e1389268f7a442ea2', '{"additional_cost":"sacrifice_creature","battle_model_scope":"xmage_fixed_source_controller_draw_spell_v1","count":2,"effect":"draw_cards","instant":true,"requires_sacrifice_creature":true,"sorcery":false,"xmage_additional_cost_class":"SacrificeTargetCost","xmage_additional_cost_target":"creature","xmage_effect_class":"DrawCardSourceControllerEffect"}'::jsonb, '{"category":"draw","effect":"draw_cards","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class VillageRites translated into ManaLoom runtime scope xmage_fixed_source_controller_draw_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('vivisection', 'Vivisection', '673d2e5b32cae23064c95c517a0027eb', 'battle_rule_v1:a6eaaf5e281f76100c9bffdc779e9608', '{"additional_cost":"sacrifice_creature","battle_model_scope":"xmage_fixed_source_controller_draw_spell_v1","count":3,"effect":"draw_cards","instant":false,"requires_sacrifice_creature":true,"sorcery":true,"xmage_additional_cost_class":"SacrificeTargetCost","xmage_additional_cost_target":"creature","xmage_effect_class":"DrawCardSourceControllerEffect"}'::jsonb, '{"category":"draw","effect":"draw_cards"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Vivisection translated into ManaLoom runtime scope xmage_fixed_source_controller_draw_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('wild guess', 'Wild Guess', '82c625909b3e6d29d4fa95e933cfc80e', 'battle_rule_v1:ea8f354cc237e842e7ffa5a03390d09f', '{"additional_cost":"discard_card","battle_model_scope":"xmage_fixed_source_controller_draw_spell_v1","count":2,"effect":"draw_cards","instant":false,"requires_discard_card":true,"sorcery":true,"xmage_additional_cost_class":"DiscardCardCost","xmage_additional_cost_target":"card","xmage_effect_class":"DrawCardSourceControllerEffect"}'::jsonb, '{"category":"draw","effect":"draw_cards"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class WildGuess translated into ManaLoom runtime scope xmage_fixed_source_controller_draw_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
