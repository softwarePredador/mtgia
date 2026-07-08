WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('bewildering blizzard', 'Bewildering Blizzard', 'e3919b8158fa4ca767ebc87280c1b444', 'battle_rule_v1:20b9a31934f0273e2c7c04e71556d751', '{"_composite_rule_components":[{"battle_model_scope":"xmage_fixed_source_controller_draw_spell_v1","compose_on_resolution":true,"count":3,"effect":"draw_cards","xmage_effect_class":"DrawCardSourceControllerEffect"},{"battle_model_scope":"xmage_fixed_boost_all_or_opponents_creatures_until_eot_spell_v1","compose_on_resolution":true,"duration":"until_end_of_turn","effect":"global_stat_modifier_until_eot","power_boost":-3,"power_delta":-3,"target":"opponents_creatures","target_constraints":{"card_types":["creature"],"controller":"opponents"},"target_controller":"opponents","toughness_boost":0,"toughness_delta":0,"xmage_effect_class":"BoostAllEffect"}],"battle_model_scope":"xmage_fixed_boost_all_or_opponents_creatures_until_eot_draw_card_spell_v1","count":3,"draw_count":3,"effect":"composite_resolution","instant":true,"power_boost":-3,"power_delta":-3,"resolution_order":"draw_then_boost","sorcery":false,"target":"opponents_creatures","target_constraints":{"card_types":["creature"],"controller":"opponents"},"target_controller":"opponents","toughness_boost":0,"toughness_delta":0,"xmage_effect_classes":["BoostAllEffect","DrawCardSourceControllerEffect"]}'::jsonb, '{"category":"draw","effect":"composite_resolution","target":"opponents_creatures","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class BewilderingBlizzard translated into ManaLoom runtime scope xmage_fixed_boost_all_or_opponents_creatures_until_eot_draw_card_spell_v1. This row is package-ready only because the source signature is a narrow fixed all/opponents/filtered-creature boost plus draw-card spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('blinding spray', 'Blinding Spray', '6d5bb5f069b8abded312db6dce1fa30a', 'battle_rule_v1:dc28e66e63622544aa582d3021171e9a', '{"_composite_rule_components":[{"battle_model_scope":"xmage_fixed_boost_all_or_opponents_creatures_until_eot_spell_v1","compose_on_resolution":true,"duration":"until_end_of_turn","effect":"global_stat_modifier_until_eot","power_boost":-4,"power_delta":-4,"target":"opponents_creatures","target_constraints":{"card_types":["creature"],"controller":"opponents"},"target_controller":"opponents","toughness_boost":0,"toughness_delta":0,"xmage_effect_class":"BoostAllEffect"},{"battle_model_scope":"xmage_fixed_source_controller_draw_spell_v1","compose_on_resolution":true,"count":1,"effect":"draw_cards","xmage_effect_class":"DrawCardSourceControllerEffect"}],"battle_model_scope":"xmage_fixed_boost_all_or_opponents_creatures_until_eot_draw_card_spell_v1","count":1,"draw_count":1,"effect":"composite_resolution","instant":true,"power_boost":-4,"power_delta":-4,"resolution_order":"boost_then_draw","sorcery":false,"target":"opponents_creatures","target_constraints":{"card_types":["creature"],"controller":"opponents"},"target_controller":"opponents","toughness_boost":0,"toughness_delta":0,"xmage_effect_classes":["BoostAllEffect","DrawCardSourceControllerEffect"]}'::jsonb, '{"category":"draw","effect":"composite_resolution","target":"opponents_creatures","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class BlindingSpray translated into ManaLoom runtime scope xmage_fixed_boost_all_or_opponents_creatures_until_eot_draw_card_spell_v1. This row is package-ready only because the source signature is a narrow fixed all/opponents/filtered-creature boost plus draw-card spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('hydrolash', 'Hydrolash', '3a690e555ed48a9dc42db087954023f2', 'battle_rule_v1:c31ef85a2a29d1a155ad6938c698a707', '{"_composite_rule_components":[{"battle_model_scope":"xmage_fixed_boost_filtered_creatures_until_eot_spell_v1","compose_on_resolution":true,"creature_filter":{"combat_state":"attacking"},"duration":"until_end_of_turn","effect":"global_stat_modifier_until_eot","power_boost":-2,"power_delta":-2,"target":"attacking_creatures","target_constraints":{"card_types":["creature"],"creature_filter":{"combat_state":"attacking"}},"target_controller":"all","toughness_boost":0,"toughness_delta":0,"xmage_effect_class":"BoostAllEffect"},{"battle_model_scope":"xmage_fixed_source_controller_draw_spell_v1","compose_on_resolution":true,"count":1,"effect":"draw_cards","xmage_effect_class":"DrawCardSourceControllerEffect"}],"battle_model_scope":"xmage_fixed_boost_all_or_opponents_creatures_until_eot_draw_card_spell_v1","count":1,"creature_filter":{"combat_state":"attacking"},"draw_count":1,"effect":"composite_resolution","instant":true,"power_boost":-2,"power_delta":-2,"resolution_order":"boost_then_draw","sorcery":false,"target":"attacking_creatures","target_constraints":{"card_types":["creature"],"creature_filter":{"combat_state":"attacking"}},"target_controller":"all","toughness_boost":0,"toughness_delta":0,"xmage_effect_classes":["BoostAllEffect","DrawCardSourceControllerEffect"]}'::jsonb, '{"category":"draw","effect":"composite_resolution","target":"attacking_creatures","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Hydrolash translated into ManaLoom runtime scope xmage_fixed_boost_all_or_opponents_creatures_until_eot_draw_card_spell_v1. This row is package-ready only because the source signature is a narrow fixed all/opponents/filtered-creature boost plus draw-card spell with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
