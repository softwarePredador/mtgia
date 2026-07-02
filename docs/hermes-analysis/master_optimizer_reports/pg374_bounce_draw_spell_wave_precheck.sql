WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('drag under', 'Drag Under', '6dd402431d3b7fb848824229d033614a', 'battle_rule_v1:f862445930f198fc3c6dc8a3d59362bb', '{"_composite_rule_components":[{"battle_model_scope":"xmage_return_target_to_hand_spell_v1","compose_on_resolution":true,"destination":"hand","effect":"remove_creature","target":"creature","target_constraints":{"card_types":["creature"]},"xmage_effect_class":"ReturnToHandTargetEffect"},{"battle_model_scope":"xmage_fixed_source_controller_draw_spell_v1","compose_on_resolution":true,"count":1,"effect":"draw_cards","xmage_effect_class":"DrawCardSourceControllerEffect"}],"battle_model_scope":"xmage_return_target_to_hand_and_draw_card_spell_v1","count":1,"destination":"hand","draw_count":1,"effect":"composite_resolution","instant":false,"sorcery":true,"target":"creature","target_constraints":{"card_types":["creature"]},"xmage_effect_classes":["ReturnToHandTargetEffect","DrawCardSourceControllerEffect"]}'::jsonb, '{"category":"draw","effect":"composite_resolution","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class DragUnder translated into ManaLoom runtime scope xmage_return_target_to_hand_and_draw_card_spell_v1. This row is package-ready only because the source signature is a narrow fixed return-target-to-hand plus draw-card spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('galestrike', 'Galestrike', 'e17ba3ddaf7febad91161213aad18a2a', 'battle_rule_v1:d6525baec4c35d68b522fb1fa2a96b9f', '{"_composite_rule_components":[{"battle_model_scope":"xmage_return_target_to_hand_spell_v1","compose_on_resolution":true,"destination":"hand","effect":"remove_creature","target":"creature","target_constraints":{"card_types":["creature"],"tapped_state":"tapped"},"xmage_effect_class":"ReturnToHandTargetEffect"},{"battle_model_scope":"xmage_fixed_source_controller_draw_spell_v1","compose_on_resolution":true,"count":1,"effect":"draw_cards","xmage_effect_class":"DrawCardSourceControllerEffect"}],"battle_model_scope":"xmage_return_target_to_hand_and_draw_card_spell_v1","count":1,"destination":"hand","draw_count":1,"effect":"composite_resolution","instant":true,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"],"tapped_state":"tapped"},"xmage_effect_classes":["ReturnToHandTargetEffect","DrawCardSourceControllerEffect"]}'::jsonb, '{"category":"draw","effect":"composite_resolution","target":"creature","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Galestrike translated into ManaLoom runtime scope xmage_return_target_to_hand_and_draw_card_spell_v1. This row is package-ready only because the source signature is a narrow fixed return-target-to-hand plus draw-card spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('leave in the dust', 'Leave in the Dust', 'e0aea105a62d82d27328b92b26231700', 'battle_rule_v1:1db4bbcee08be05bdcfcdbc8c3503ab1', '{"_composite_rule_components":[{"battle_model_scope":"xmage_return_target_to_hand_spell_v1","compose_on_resolution":true,"destination":"hand","effect":"remove_permanent","target":"nonland_permanent","target_constraints":{"card_types":["nonland_permanent"]},"xmage_effect_class":"ReturnToHandTargetEffect"},{"battle_model_scope":"xmage_fixed_source_controller_draw_spell_v1","compose_on_resolution":true,"count":1,"effect":"draw_cards","xmage_effect_class":"DrawCardSourceControllerEffect"}],"battle_model_scope":"xmage_return_target_to_hand_and_draw_card_spell_v1","count":1,"destination":"hand","draw_count":1,"effect":"composite_resolution","instant":true,"sorcery":false,"target":"nonland_permanent","target_constraints":{"card_types":["nonland_permanent"]},"xmage_effect_classes":["ReturnToHandTargetEffect","DrawCardSourceControllerEffect"]}'::jsonb, '{"category":"draw","effect":"composite_resolution","target":"nonland_permanent","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class LeaveInTheDust translated into ManaLoom runtime scope xmage_return_target_to_hand_and_draw_card_spell_v1. This row is package-ready only because the source signature is a narrow fixed return-target-to-hand plus draw-card spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('repulse', 'Repulse', '6dd402431d3b7fb848824229d033614a', 'battle_rule_v1:c26825e6148a1ceed1bb1f5236af63de', '{"_composite_rule_components":[{"battle_model_scope":"xmage_return_target_to_hand_spell_v1","compose_on_resolution":true,"destination":"hand","effect":"remove_creature","target":"creature","target_constraints":{"card_types":["creature"]},"xmage_effect_class":"ReturnToHandTargetEffect"},{"battle_model_scope":"xmage_fixed_source_controller_draw_spell_v1","compose_on_resolution":true,"count":1,"effect":"draw_cards","xmage_effect_class":"DrawCardSourceControllerEffect"}],"battle_model_scope":"xmage_return_target_to_hand_and_draw_card_spell_v1","count":1,"destination":"hand","draw_count":1,"effect":"composite_resolution","instant":true,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"]},"xmage_effect_classes":["ReturnToHandTargetEffect","DrawCardSourceControllerEffect"]}'::jsonb, '{"category":"draw","effect":"composite_resolution","target":"creature","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Repulse translated into ManaLoom runtime scope xmage_return_target_to_hand_and_draw_card_spell_v1. This row is package-ready only because the source signature is a narrow fixed return-target-to-hand plus draw-card spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('symbol of unsummoning', 'Symbol of Unsummoning', '6dd402431d3b7fb848824229d033614a', 'battle_rule_v1:f862445930f198fc3c6dc8a3d59362bb', '{"_composite_rule_components":[{"battle_model_scope":"xmage_return_target_to_hand_spell_v1","compose_on_resolution":true,"destination":"hand","effect":"remove_creature","target":"creature","target_constraints":{"card_types":["creature"]},"xmage_effect_class":"ReturnToHandTargetEffect"},{"battle_model_scope":"xmage_fixed_source_controller_draw_spell_v1","compose_on_resolution":true,"count":1,"effect":"draw_cards","xmage_effect_class":"DrawCardSourceControllerEffect"}],"battle_model_scope":"xmage_return_target_to_hand_and_draw_card_spell_v1","count":1,"destination":"hand","draw_count":1,"effect":"composite_resolution","instant":false,"sorcery":true,"target":"creature","target_constraints":{"card_types":["creature"]},"xmage_effect_classes":["ReturnToHandTargetEffect","DrawCardSourceControllerEffect"]}'::jsonb, '{"category":"draw","effect":"composite_resolution","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class SymbolOfUnsummoning translated into ManaLoom runtime scope xmage_return_target_to_hand_and_draw_card_spell_v1. This row is package-ready only because the source signature is a narrow fixed return-target-to-hand plus draw-card spell with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
