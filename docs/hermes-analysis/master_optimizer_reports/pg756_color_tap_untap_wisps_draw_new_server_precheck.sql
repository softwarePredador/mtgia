WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('cerulean wisps', 'Cerulean Wisps', 'a22692ce047d0fce1a8da5f13a5866d2', 'battle_rule_v1:e5609b3e5a362543a10712e8a39506cd', '{"_composite_rule_components":[{"battle_model_scope":"xmage_fixed_color_untap_target_creature_until_eot_draw_card_spell_v1","compose_on_resolution":true,"duration":"until_end_of_turn","effect":"stat_modifier_until_eot_untap_target","power_boost":0,"power_delta":0,"target":"creature","target_colors_until_eot":["U"],"target_constraints":{"card_types":["creature"]},"target_controller":"any","toughness_boost":0,"toughness_delta":0,"untap_target":true,"xmage_effect_classes":["BecomesColorTargetEffect","UntapTargetEffect"]},{"battle_model_scope":"xmage_fixed_source_controller_draw_spell_v1","compose_on_resolution":true,"count":1,"effect":"draw_cards","xmage_effect_class":"DrawCardSourceControllerEffect"}],"battle_model_scope":"xmage_fixed_color_untap_target_creature_until_eot_draw_card_spell_v1","count":1,"draw_count":1,"duration":"until_end_of_turn","effect":"composite_resolution","instant":true,"sorcery":false,"tap_target":false,"target":"creature","target_colors_until_eot":["U"],"target_constraints":{"card_types":["creature"]},"target_controller":"any","untap_target":true,"xmage_effect_classes":["BecomesColorTargetEffect","UntapTargetEffect","DrawCardSourceControllerEffect"]}'::jsonb, '{"category":"draw","effect":"composite_resolution","target":"creature","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class CeruleanWisps translated into ManaLoom runtime scope xmage_fixed_color_untap_target_creature_until_eot_draw_card_spell_v1. This row is package-ready only because the source signature is a narrow fixed target-creature color plus untap plus draw-card spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('niveous wisps', 'Niveous Wisps', 'd9d9df0786e7bae924dd76f7e96011de', 'battle_rule_v1:9d1889e17266414aa7a75f27ae012dae', '{"_composite_rule_components":[{"battle_model_scope":"xmage_tap_target_spell_v1","compose_on_resolution":true,"duration":"until_end_of_turn","effect":"tap_target","target":"creature","target_colors_until_eot":["W"],"target_constraints":{"card_types":["creature"]},"target_controller":"any","target_count":1,"xmage_effect_classes":["BecomesColorTargetEffect","TapTargetEffect"]},{"battle_model_scope":"xmage_fixed_source_controller_draw_spell_v1","compose_on_resolution":true,"count":1,"effect":"draw_cards","xmage_effect_class":"DrawCardSourceControllerEffect"}],"battle_model_scope":"xmage_fixed_color_tap_target_creature_until_eot_draw_card_spell_v1","count":1,"draw_count":1,"duration":"until_end_of_turn","effect":"composite_resolution","instant":true,"sorcery":false,"tap_target":true,"target":"creature","target_colors_until_eot":["W"],"target_constraints":{"card_types":["creature"]},"target_controller":"any","untap_target":false,"xmage_effect_classes":["BecomesColorTargetEffect","TapTargetEffect","DrawCardSourceControllerEffect"]}'::jsonb, '{"category":"draw","effect":"composite_resolution","target":"creature","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class NiveousWisps translated into ManaLoom runtime scope xmage_fixed_color_tap_target_creature_until_eot_draw_card_spell_v1. This row is package-ready only because the source signature is a narrow fixed target-creature color plus tap plus draw-card spell with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
