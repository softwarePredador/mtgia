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
  LEFT JOIN public.cards c
    ON (
         lower(c.name) = p.normalized_name
         OR split_part(lower(c.name), ' // ', 1) = p.normalized_name
       )
   AND md5(coalesce(c.oracle_text, '')) = p.oracle_hash
),
target_cards AS (
  SELECT
    normalized_name,
    card_name,
    oracle_hash,
    count(card_id) AS target_card_rows,
    min(card_id::text)::uuid AS canonical_card_id,
    min(db_card_name) AS canonical_card_name
  FROM matched_cards
  GROUP BY normalized_name, card_name, oracle_hash
),
rule_rows AS (
  SELECT p.normalized_name, count(r.*) AS existing_rule_rows
  FROM proposed p
  LEFT JOIN public.card_battle_rules r
    ON (
         r.normalized_name = p.normalized_name
         OR r.normalized_name LIKE p.normalized_name || ' // %'
       )
  GROUP BY p.normalized_name
),
expected_rows AS (
  SELECT p.normalized_name, count(r.*) AS expected_rule_rows_before
  FROM proposed p
  LEFT JOIN public.card_battle_rules r
    ON (
         r.normalized_name = p.normalized_name
         OR r.normalized_name LIKE p.normalized_name || ' // %'
       )
   AND r.logical_rule_key = p.logical_rule_key
  GROUP BY p.normalized_name
),
shadow_rows AS (
  SELECT p.normalized_name, count(r.*) AS would_deprecate_shadow_rows
  FROM proposed p
  LEFT JOIN public.card_battle_rules r
    ON (
         r.normalized_name = p.normalized_name
         OR r.normalized_name LIKE p.normalized_name || ' // %'
       )
   AND r.logical_rule_key <> p.logical_rule_key
   AND r.review_status NOT IN ('deprecated', 'rejected')
   AND r.execution_status <> 'disabled'
  GROUP BY p.normalized_name
)
SELECT
  p.card_name,
  p.normalized_name,
  p.oracle_hash,
  p.logical_rule_key,
  p.shadow_handling,
  tc.target_card_rows,
  tc.canonical_card_id,
  rr.existing_rule_rows,
  er.expected_rule_rows_before,
  sr.would_deprecate_shadow_rows
FROM proposed p
JOIN target_cards tc USING (normalized_name, card_name, oracle_hash)
JOIN rule_rows rr USING (normalized_name)
JOIN expected_rows er USING (normalized_name)
JOIN shadow_rows sr USING (normalized_name)
ORDER BY p.card_name;
