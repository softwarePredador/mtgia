BEGIN;

CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit;

CREATE TABLE manaloom_deploy_audit.pg399_draw_self_cost_reduction_target_draw_new_server_20 AS
SELECT *
FROM public.card_battle_rules
WHERE normalized_name IN ('distorted curiosity', 'draconic lore', 'into the story', 'of one mind', 'overflowing insight', 'pearl of wisdom', 'scour the laboratory', 'winged words')
   OR normalized_name LIKE 'distorted curiosity // %'
   OR normalized_name LIKE 'draconic lore // %'
   OR normalized_name LIKE 'into the story // %'
   OR normalized_name LIKE 'of one mind // %'
   OR normalized_name LIKE 'overflowing insight // %'
   OR normalized_name LIKE 'pearl of wisdom // %'
   OR normalized_name LIKE 'scour the laboratory // %'
   OR normalized_name LIKE 'winged words // %';

DO $$
DECLARE
  v_missing jsonb;
BEGIN
  WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('distorted curiosity', 'Distorted Curiosity', '96125603ad98c8ef33157389b9d59b62', 'battle_rule_v1:72bb59188e2df380602ed08f4ee5b827', '{"battle_model_scope":"xmage_fixed_source_controller_draw_spell_self_cost_reduction_v1","cost_reduction_amount_source":"fixed","cost_reduction_applies_to":"this_spell","cost_reduction_condition":"opponent_poison_counters_at_least","cost_reduction_generic":2,"cost_reduction_opponent_poison_counters_min":3,"count":2,"draw_count":2,"effect":"draw_cards","instant":false,"sorcery":true,"xmage_effect_classes":["DrawCardSourceControllerEffect","SpellCostReductionSourceEffect"]}'::jsonb, '{"category":"draw","effect":"draw_cards"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class DistortedCuriosity translated into ManaLoom runtime scope xmage_fixed_source_controller_draw_spell_self_cost_reduction_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('draconic lore', 'Draconic Lore', 'd784b8e5790077cba8973240f5308d82', 'battle_rule_v1:551a3b4152b9cd2bca57277a77c3badf', '{"battle_model_scope":"xmage_fixed_source_controller_draw_spell_self_cost_reduction_v1","cost_reduction_amount_source":"fixed","cost_reduction_applies_to":"this_spell","cost_reduction_condition":"control_subtype","cost_reduction_generic":2,"cost_reduction_required_subtype":"dragon","count":3,"draw_count":3,"effect":"draw_cards","instant":true,"sorcery":false,"xmage_effect_classes":["DrawCardSourceControllerEffect","SpellCostReductionSourceEffect"]}'::jsonb, '{"category":"draw","effect":"draw_cards","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class DraconicLore translated into ManaLoom runtime scope xmage_fixed_source_controller_draw_spell_self_cost_reduction_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('into the story', 'Into the Story', '787c2d6c52861f77978fd3b030799117', 'battle_rule_v1:7b86830fddab9090f6dba403cd83f0cc', '{"battle_model_scope":"xmage_fixed_source_controller_draw_spell_self_cost_reduction_v1","cost_reduction_amount_source":"fixed","cost_reduction_applies_to":"this_spell","cost_reduction_condition":"opponent_graveyard_cards_at_least","cost_reduction_generic":3,"cost_reduction_opponent_graveyard_cards_min":7,"count":4,"draw_count":4,"effect":"draw_cards","instant":true,"sorcery":false,"xmage_effect_classes":["DrawCardSourceControllerEffect","SpellCostReductionSourceEffect"]}'::jsonb, '{"category":"draw","effect":"draw_cards","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class IntoTheStory translated into ManaLoom runtime scope xmage_fixed_source_controller_draw_spell_self_cost_reduction_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('of one mind', 'Of One Mind', 'bb572f4c4e508141df09f5da47bfbf80', 'battle_rule_v1:3ed1545be6ac150e060339d3f48b6046', '{"battle_model_scope":"xmage_fixed_source_controller_draw_spell_self_cost_reduction_v1","cost_reduction_amount_source":"fixed","cost_reduction_applies_to":"this_spell","cost_reduction_condition":"control_human_and_nonhuman_creature","cost_reduction_generic":2,"count":2,"draw_count":2,"effect":"draw_cards","instant":false,"sorcery":true,"xmage_effect_classes":["DrawCardSourceControllerEffect","SpellCostReductionSourceEffect"]}'::jsonb, '{"category":"draw","effect":"draw_cards"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class OfOneMind translated into ManaLoom runtime scope xmage_fixed_source_controller_draw_spell_self_cost_reduction_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('overflowing insight', 'Overflowing Insight', '4cc7bb709182a575326945bd43982048', 'battle_rule_v1:c878698b39e28187811f320886f31235', '{"battle_model_scope":"xmage_fixed_target_player_draw_spell_v1","count":7,"draw_count":7,"effect":"draw_cards","instant":false,"sorcery":true,"target":"player","target_constraints":{"players":["any"]},"target_controller":"target_player","target_player_draw":true,"target_preference":"self","xmage_effect_class":"DrawCardTargetEffect"}'::jsonb, '{"category":"draw","effect":"draw_cards","target":"player"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class OverflowingInsight translated into ManaLoom runtime scope xmage_fixed_target_player_draw_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('pearl of wisdom', 'Pearl of Wisdom', '37e7cbe4070b00405cdfa36e31691483', 'battle_rule_v1:849932e4bd730d18b792e48b51206cac', '{"battle_model_scope":"xmage_fixed_source_controller_draw_spell_self_cost_reduction_v1","cost_reduction_amount_source":"fixed","cost_reduction_applies_to":"this_spell","cost_reduction_condition":"control_subtype","cost_reduction_generic":1,"cost_reduction_required_subtype":"otter","count":2,"draw_count":2,"effect":"draw_cards","instant":false,"sorcery":true,"xmage_effect_classes":["DrawCardSourceControllerEffect","SpellCostReductionSourceEffect"]}'::jsonb, '{"category":"draw","effect":"draw_cards"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class PearlOfWisdom translated into ManaLoom runtime scope xmage_fixed_source_controller_draw_spell_self_cost_reduction_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('scour the laboratory', 'Scour the Laboratory', 'a9dc24ac34e23e7ee0c1b9715a510dc0', 'battle_rule_v1:f8a458643963c242d23d2ca55cded5cb', '{"battle_model_scope":"xmage_fixed_source_controller_draw_spell_self_cost_reduction_v1","cost_reduction_amount_source":"fixed","cost_reduction_applies_to":"this_spell","cost_reduction_condition":"delirium","cost_reduction_generic":2,"cost_reduction_graveyard_card_types_min":4,"count":3,"draw_count":3,"effect":"draw_cards","instant":true,"sorcery":false,"xmage_effect_classes":["DrawCardSourceControllerEffect","SpellCostReductionSourceEffect"]}'::jsonb, '{"category":"draw","effect":"draw_cards","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ScourTheLaboratory translated into ManaLoom runtime scope xmage_fixed_source_controller_draw_spell_self_cost_reduction_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('winged words', 'Winged Words', '8f9b430fe2bee3d386c04f85799806a5', 'battle_rule_v1:1b0b5f6d4f1ab34821f2b3b326e6c684', '{"battle_model_scope":"xmage_fixed_source_controller_draw_spell_self_cost_reduction_v1","cost_reduction_amount_source":"fixed","cost_reduction_applies_to":"this_spell","cost_reduction_condition":"control_creature_with_keyword","cost_reduction_generic":1,"cost_reduction_required_keyword":"flying","count":2,"draw_count":2,"effect":"draw_cards","instant":false,"sorcery":true,"xmage_effect_classes":["DrawCardSourceControllerEffect","SpellCostReductionSourceEffect"]}'::jsonb, '{"category":"draw","effect":"draw_cards"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class WingedWords translated into ManaLoom runtime scope xmage_fixed_source_controller_draw_spell_self_cost_reduction_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
    ('distorted curiosity', 'Distorted Curiosity', '96125603ad98c8ef33157389b9d59b62', 'battle_rule_v1:72bb59188e2df380602ed08f4ee5b827', '{"battle_model_scope":"xmage_fixed_source_controller_draw_spell_self_cost_reduction_v1","cost_reduction_amount_source":"fixed","cost_reduction_applies_to":"this_spell","cost_reduction_condition":"opponent_poison_counters_at_least","cost_reduction_generic":2,"cost_reduction_opponent_poison_counters_min":3,"count":2,"draw_count":2,"effect":"draw_cards","instant":false,"sorcery":true,"xmage_effect_classes":["DrawCardSourceControllerEffect","SpellCostReductionSourceEffect"]}'::jsonb, '{"category":"draw","effect":"draw_cards"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class DistortedCuriosity translated into ManaLoom runtime scope xmage_fixed_source_controller_draw_spell_self_cost_reduction_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('draconic lore', 'Draconic Lore', 'd784b8e5790077cba8973240f5308d82', 'battle_rule_v1:551a3b4152b9cd2bca57277a77c3badf', '{"battle_model_scope":"xmage_fixed_source_controller_draw_spell_self_cost_reduction_v1","cost_reduction_amount_source":"fixed","cost_reduction_applies_to":"this_spell","cost_reduction_condition":"control_subtype","cost_reduction_generic":2,"cost_reduction_required_subtype":"dragon","count":3,"draw_count":3,"effect":"draw_cards","instant":true,"sorcery":false,"xmage_effect_classes":["DrawCardSourceControllerEffect","SpellCostReductionSourceEffect"]}'::jsonb, '{"category":"draw","effect":"draw_cards","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class DraconicLore translated into ManaLoom runtime scope xmage_fixed_source_controller_draw_spell_self_cost_reduction_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('into the story', 'Into the Story', '787c2d6c52861f77978fd3b030799117', 'battle_rule_v1:7b86830fddab9090f6dba403cd83f0cc', '{"battle_model_scope":"xmage_fixed_source_controller_draw_spell_self_cost_reduction_v1","cost_reduction_amount_source":"fixed","cost_reduction_applies_to":"this_spell","cost_reduction_condition":"opponent_graveyard_cards_at_least","cost_reduction_generic":3,"cost_reduction_opponent_graveyard_cards_min":7,"count":4,"draw_count":4,"effect":"draw_cards","instant":true,"sorcery":false,"xmage_effect_classes":["DrawCardSourceControllerEffect","SpellCostReductionSourceEffect"]}'::jsonb, '{"category":"draw","effect":"draw_cards","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class IntoTheStory translated into ManaLoom runtime scope xmage_fixed_source_controller_draw_spell_self_cost_reduction_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('of one mind', 'Of One Mind', 'bb572f4c4e508141df09f5da47bfbf80', 'battle_rule_v1:3ed1545be6ac150e060339d3f48b6046', '{"battle_model_scope":"xmage_fixed_source_controller_draw_spell_self_cost_reduction_v1","cost_reduction_amount_source":"fixed","cost_reduction_applies_to":"this_spell","cost_reduction_condition":"control_human_and_nonhuman_creature","cost_reduction_generic":2,"count":2,"draw_count":2,"effect":"draw_cards","instant":false,"sorcery":true,"xmage_effect_classes":["DrawCardSourceControllerEffect","SpellCostReductionSourceEffect"]}'::jsonb, '{"category":"draw","effect":"draw_cards"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class OfOneMind translated into ManaLoom runtime scope xmage_fixed_source_controller_draw_spell_self_cost_reduction_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('overflowing insight', 'Overflowing Insight', '4cc7bb709182a575326945bd43982048', 'battle_rule_v1:c878698b39e28187811f320886f31235', '{"battle_model_scope":"xmage_fixed_target_player_draw_spell_v1","count":7,"draw_count":7,"effect":"draw_cards","instant":false,"sorcery":true,"target":"player","target_constraints":{"players":["any"]},"target_controller":"target_player","target_player_draw":true,"target_preference":"self","xmage_effect_class":"DrawCardTargetEffect"}'::jsonb, '{"category":"draw","effect":"draw_cards","target":"player"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class OverflowingInsight translated into ManaLoom runtime scope xmage_fixed_target_player_draw_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('pearl of wisdom', 'Pearl of Wisdom', '37e7cbe4070b00405cdfa36e31691483', 'battle_rule_v1:849932e4bd730d18b792e48b51206cac', '{"battle_model_scope":"xmage_fixed_source_controller_draw_spell_self_cost_reduction_v1","cost_reduction_amount_source":"fixed","cost_reduction_applies_to":"this_spell","cost_reduction_condition":"control_subtype","cost_reduction_generic":1,"cost_reduction_required_subtype":"otter","count":2,"draw_count":2,"effect":"draw_cards","instant":false,"sorcery":true,"xmage_effect_classes":["DrawCardSourceControllerEffect","SpellCostReductionSourceEffect"]}'::jsonb, '{"category":"draw","effect":"draw_cards"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class PearlOfWisdom translated into ManaLoom runtime scope xmage_fixed_source_controller_draw_spell_self_cost_reduction_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('scour the laboratory', 'Scour the Laboratory', 'a9dc24ac34e23e7ee0c1b9715a510dc0', 'battle_rule_v1:f8a458643963c242d23d2ca55cded5cb', '{"battle_model_scope":"xmage_fixed_source_controller_draw_spell_self_cost_reduction_v1","cost_reduction_amount_source":"fixed","cost_reduction_applies_to":"this_spell","cost_reduction_condition":"delirium","cost_reduction_generic":2,"cost_reduction_graveyard_card_types_min":4,"count":3,"draw_count":3,"effect":"draw_cards","instant":true,"sorcery":false,"xmage_effect_classes":["DrawCardSourceControllerEffect","SpellCostReductionSourceEffect"]}'::jsonb, '{"category":"draw","effect":"draw_cards","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ScourTheLaboratory translated into ManaLoom runtime scope xmage_fixed_source_controller_draw_spell_self_cost_reduction_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('winged words', 'Winged Words', '8f9b430fe2bee3d386c04f85799806a5', 'battle_rule_v1:1b0b5f6d4f1ab34821f2b3b326e6c684', '{"battle_model_scope":"xmage_fixed_source_controller_draw_spell_self_cost_reduction_v1","cost_reduction_amount_source":"fixed","cost_reduction_applies_to":"this_spell","cost_reduction_condition":"control_creature_with_keyword","cost_reduction_generic":1,"cost_reduction_required_keyword":"flying","count":2,"draw_count":2,"effect":"draw_cards","instant":false,"sorcery":true,"xmage_effect_classes":["DrawCardSourceControllerEffect","SpellCostReductionSourceEffect"]}'::jsonb, '{"category":"draw","effect":"draw_cards"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class WingedWords translated into ManaLoom runtime scope xmage_fixed_source_controller_draw_spell_self_cost_reduction_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
    ('distorted curiosity', 'Distorted Curiosity', '96125603ad98c8ef33157389b9d59b62', 'battle_rule_v1:72bb59188e2df380602ed08f4ee5b827', '{"battle_model_scope":"xmage_fixed_source_controller_draw_spell_self_cost_reduction_v1","cost_reduction_amount_source":"fixed","cost_reduction_applies_to":"this_spell","cost_reduction_condition":"opponent_poison_counters_at_least","cost_reduction_generic":2,"cost_reduction_opponent_poison_counters_min":3,"count":2,"draw_count":2,"effect":"draw_cards","instant":false,"sorcery":true,"xmage_effect_classes":["DrawCardSourceControllerEffect","SpellCostReductionSourceEffect"]}'::jsonb, '{"category":"draw","effect":"draw_cards"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class DistortedCuriosity translated into ManaLoom runtime scope xmage_fixed_source_controller_draw_spell_self_cost_reduction_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('draconic lore', 'Draconic Lore', 'd784b8e5790077cba8973240f5308d82', 'battle_rule_v1:551a3b4152b9cd2bca57277a77c3badf', '{"battle_model_scope":"xmage_fixed_source_controller_draw_spell_self_cost_reduction_v1","cost_reduction_amount_source":"fixed","cost_reduction_applies_to":"this_spell","cost_reduction_condition":"control_subtype","cost_reduction_generic":2,"cost_reduction_required_subtype":"dragon","count":3,"draw_count":3,"effect":"draw_cards","instant":true,"sorcery":false,"xmage_effect_classes":["DrawCardSourceControllerEffect","SpellCostReductionSourceEffect"]}'::jsonb, '{"category":"draw","effect":"draw_cards","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class DraconicLore translated into ManaLoom runtime scope xmage_fixed_source_controller_draw_spell_self_cost_reduction_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('into the story', 'Into the Story', '787c2d6c52861f77978fd3b030799117', 'battle_rule_v1:7b86830fddab9090f6dba403cd83f0cc', '{"battle_model_scope":"xmage_fixed_source_controller_draw_spell_self_cost_reduction_v1","cost_reduction_amount_source":"fixed","cost_reduction_applies_to":"this_spell","cost_reduction_condition":"opponent_graveyard_cards_at_least","cost_reduction_generic":3,"cost_reduction_opponent_graveyard_cards_min":7,"count":4,"draw_count":4,"effect":"draw_cards","instant":true,"sorcery":false,"xmage_effect_classes":["DrawCardSourceControllerEffect","SpellCostReductionSourceEffect"]}'::jsonb, '{"category":"draw","effect":"draw_cards","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class IntoTheStory translated into ManaLoom runtime scope xmage_fixed_source_controller_draw_spell_self_cost_reduction_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('of one mind', 'Of One Mind', 'bb572f4c4e508141df09f5da47bfbf80', 'battle_rule_v1:3ed1545be6ac150e060339d3f48b6046', '{"battle_model_scope":"xmage_fixed_source_controller_draw_spell_self_cost_reduction_v1","cost_reduction_amount_source":"fixed","cost_reduction_applies_to":"this_spell","cost_reduction_condition":"control_human_and_nonhuman_creature","cost_reduction_generic":2,"count":2,"draw_count":2,"effect":"draw_cards","instant":false,"sorcery":true,"xmage_effect_classes":["DrawCardSourceControllerEffect","SpellCostReductionSourceEffect"]}'::jsonb, '{"category":"draw","effect":"draw_cards"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class OfOneMind translated into ManaLoom runtime scope xmage_fixed_source_controller_draw_spell_self_cost_reduction_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('overflowing insight', 'Overflowing Insight', '4cc7bb709182a575326945bd43982048', 'battle_rule_v1:c878698b39e28187811f320886f31235', '{"battle_model_scope":"xmage_fixed_target_player_draw_spell_v1","count":7,"draw_count":7,"effect":"draw_cards","instant":false,"sorcery":true,"target":"player","target_constraints":{"players":["any"]},"target_controller":"target_player","target_player_draw":true,"target_preference":"self","xmage_effect_class":"DrawCardTargetEffect"}'::jsonb, '{"category":"draw","effect":"draw_cards","target":"player"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class OverflowingInsight translated into ManaLoom runtime scope xmage_fixed_target_player_draw_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('pearl of wisdom', 'Pearl of Wisdom', '37e7cbe4070b00405cdfa36e31691483', 'battle_rule_v1:849932e4bd730d18b792e48b51206cac', '{"battle_model_scope":"xmage_fixed_source_controller_draw_spell_self_cost_reduction_v1","cost_reduction_amount_source":"fixed","cost_reduction_applies_to":"this_spell","cost_reduction_condition":"control_subtype","cost_reduction_generic":1,"cost_reduction_required_subtype":"otter","count":2,"draw_count":2,"effect":"draw_cards","instant":false,"sorcery":true,"xmage_effect_classes":["DrawCardSourceControllerEffect","SpellCostReductionSourceEffect"]}'::jsonb, '{"category":"draw","effect":"draw_cards"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class PearlOfWisdom translated into ManaLoom runtime scope xmage_fixed_source_controller_draw_spell_self_cost_reduction_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('scour the laboratory', 'Scour the Laboratory', 'a9dc24ac34e23e7ee0c1b9715a510dc0', 'battle_rule_v1:f8a458643963c242d23d2ca55cded5cb', '{"battle_model_scope":"xmage_fixed_source_controller_draw_spell_self_cost_reduction_v1","cost_reduction_amount_source":"fixed","cost_reduction_applies_to":"this_spell","cost_reduction_condition":"delirium","cost_reduction_generic":2,"cost_reduction_graveyard_card_types_min":4,"count":3,"draw_count":3,"effect":"draw_cards","instant":true,"sorcery":false,"xmage_effect_classes":["DrawCardSourceControllerEffect","SpellCostReductionSourceEffect"]}'::jsonb, '{"category":"draw","effect":"draw_cards","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ScourTheLaboratory translated into ManaLoom runtime scope xmage_fixed_source_controller_draw_spell_self_cost_reduction_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('winged words', 'Winged Words', '8f9b430fe2bee3d386c04f85799806a5', 'battle_rule_v1:1b0b5f6d4f1ab34821f2b3b326e6c684', '{"battle_model_scope":"xmage_fixed_source_controller_draw_spell_self_cost_reduction_v1","cost_reduction_amount_source":"fixed","cost_reduction_applies_to":"this_spell","cost_reduction_condition":"control_creature_with_keyword","cost_reduction_generic":1,"cost_reduction_required_keyword":"flying","count":2,"draw_count":2,"effect":"draw_cards","instant":false,"sorcery":true,"xmage_effect_classes":["DrawCardSourceControllerEffect","SpellCostReductionSourceEffect"]}'::jsonb, '{"category":"draw","effect":"draw_cards"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class WingedWords translated into ManaLoom runtime scope xmage_fixed_source_controller_draw_spell_self_cost_reduction_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
