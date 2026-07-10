WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('aang''s defense', 'Aang''s Defense', '64cefc51cdab7c6274154d69adda89e2', 'battle_rule_v1:e7bf87a85c25e1f0b6d32db6efff30b5', '{"_composite_rule_components":[{"battle_model_scope":"xmage_fixed_boost_target_creature_until_eot_spell_v1","compose_on_resolution":true,"duration":"until_end_of_turn","effect":"stat_modifier_until_eot","power_boost":2,"power_delta":2,"target":"creature","target_constraints":{"card_types":["creature"],"combat_state":"blocking","controller_scope":"self"},"target_controller":"self","toughness_boost":2,"toughness_delta":2,"xmage_effect_class":"BoostTargetEffect"},{"battle_model_scope":"xmage_fixed_source_controller_draw_spell_v1","compose_on_resolution":true,"count":1,"effect":"draw_cards","xmage_effect_class":"DrawCardSourceControllerEffect"}],"battle_model_scope":"xmage_fixed_boost_target_creature_until_eot_draw_card_spell_v1","count":1,"draw_count":1,"effect":"composite_resolution","instant":true,"power_boost":2,"power_delta":2,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"],"combat_state":"blocking","controller_scope":"self"},"target_controller":"self","toughness_boost":2,"toughness_delta":2,"xmage_effect_classes":["BoostTargetEffect","DrawCardSourceControllerEffect"]}'::jsonb, '{"category":"draw","effect":"composite_resolution","target":"creature","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class AangsDefense translated into ManaLoom runtime scope xmage_fixed_boost_target_creature_until_eot_draw_card_spell_v1. This row is package-ready only because the source signature is a narrow fixed target-creature boost plus draw-card spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('gallantry', 'Gallantry', '9858f271a2639fe3e21469a90f5aa4d1', 'battle_rule_v1:73cba2a058674ea5d048304fb6b16cfb', '{"_composite_rule_components":[{"battle_model_scope":"xmage_fixed_boost_target_creature_until_eot_spell_v1","compose_on_resolution":true,"duration":"until_end_of_turn","effect":"stat_modifier_until_eot","power_boost":4,"power_delta":4,"target":"creature","target_constraints":{"card_types":["creature"],"combat_state":"blocking"},"target_controller":"any","toughness_boost":4,"toughness_delta":4,"xmage_effect_class":"BoostTargetEffect"},{"battle_model_scope":"xmage_fixed_source_controller_draw_spell_v1","compose_on_resolution":true,"count":1,"effect":"draw_cards","xmage_effect_class":"DrawCardSourceControllerEffect"}],"battle_model_scope":"xmage_fixed_boost_target_creature_until_eot_draw_card_spell_v1","count":1,"draw_count":1,"effect":"composite_resolution","instant":true,"power_boost":4,"power_delta":4,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"],"combat_state":"blocking"},"target_controller":"any","toughness_boost":4,"toughness_delta":4,"xmage_effect_classes":["BoostTargetEffect","DrawCardSourceControllerEffect"]}'::jsonb, '{"category":"draw","effect":"composite_resolution","target":"creature","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Gallantry translated into ManaLoom runtime scope xmage_fixed_boost_target_creature_until_eot_draw_card_spell_v1. This row is package-ready only because the source signature is a narrow fixed target-creature boost plus draw-card spell with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
