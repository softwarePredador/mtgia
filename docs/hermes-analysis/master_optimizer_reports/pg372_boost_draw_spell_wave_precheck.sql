WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('afflict', 'Afflict', 'cbbd4f66bac4dff77b8c264fbc917727', 'battle_rule_v1:1d127e90ecf3de2f9467b1d609a04e56', '{"_composite_rule_components":[{"battle_model_scope":"xmage_fixed_boost_target_creature_until_eot_spell_v1","compose_on_resolution":true,"duration":"until_end_of_turn","effect":"stat_modifier_until_eot","power_boost":-1,"power_delta":-1,"target":"creature","target_constraints":{"card_types":["creature"]},"target_controller":"any","toughness_boost":-1,"toughness_delta":-1,"xmage_effect_class":"BoostTargetEffect"},{"battle_model_scope":"xmage_fixed_source_controller_draw_spell_v1","compose_on_resolution":true,"count":1,"effect":"draw_cards","xmage_effect_class":"DrawCardSourceControllerEffect"}],"battle_model_scope":"xmage_fixed_boost_target_creature_until_eot_draw_card_spell_v1","count":1,"draw_count":1,"effect":"composite_resolution","instant":true,"power_boost":-1,"power_delta":-1,"sorcery":false,"toughness_boost":-1,"toughness_delta":-1,"xmage_effect_classes":["BoostTargetEffect","DrawCardSourceControllerEffect"]}'::jsonb, '{"category":"draw","effect":"composite_resolution","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Afflict translated into ManaLoom runtime scope xmage_fixed_boost_target_creature_until_eot_draw_card_spell_v1. This row is package-ready only because the source signature is a narrow fixed target-creature boost plus draw-card spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('aggressive urge', 'Aggressive Urge', '689ddcf5b96963dafc6c6eebca23248e', 'battle_rule_v1:50d76fa80bfffae06d7570b3894cec0e', '{"_composite_rule_components":[{"battle_model_scope":"xmage_fixed_boost_target_creature_until_eot_spell_v1","compose_on_resolution":true,"duration":"until_end_of_turn","effect":"stat_modifier_until_eot","power_boost":1,"power_delta":1,"target":"creature","target_constraints":{"card_types":["creature"]},"target_controller":"any","toughness_boost":1,"toughness_delta":1,"xmage_effect_class":"BoostTargetEffect"},{"battle_model_scope":"xmage_fixed_source_controller_draw_spell_v1","compose_on_resolution":true,"count":1,"effect":"draw_cards","xmage_effect_class":"DrawCardSourceControllerEffect"}],"battle_model_scope":"xmage_fixed_boost_target_creature_until_eot_draw_card_spell_v1","count":1,"draw_count":1,"effect":"composite_resolution","instant":true,"power_boost":1,"power_delta":1,"sorcery":false,"toughness_boost":1,"toughness_delta":1,"xmage_effect_classes":["BoostTargetEffect","DrawCardSourceControllerEffect"]}'::jsonb, '{"category":"draw","effect":"composite_resolution","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class AggressiveUrge translated into ManaLoom runtime scope xmage_fixed_boost_target_creature_until_eot_draw_card_spell_v1. This row is package-ready only because the source signature is a narrow fixed target-creature boost plus draw-card spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('befuddle', 'Befuddle', '51762dddef01d1e2c3d89133073cbcc2', 'battle_rule_v1:ae7cb661641c2688dc26049f2952d09c', '{"_composite_rule_components":[{"battle_model_scope":"xmage_fixed_boost_target_creature_until_eot_spell_v1","compose_on_resolution":true,"duration":"until_end_of_turn","effect":"stat_modifier_until_eot","power_boost":-4,"power_delta":-4,"target":"creature","target_constraints":{"card_types":["creature"]},"target_controller":"any","toughness_boost":0,"toughness_delta":0,"xmage_effect_class":"BoostTargetEffect"},{"battle_model_scope":"xmage_fixed_source_controller_draw_spell_v1","compose_on_resolution":true,"count":1,"effect":"draw_cards","xmage_effect_class":"DrawCardSourceControllerEffect"}],"battle_model_scope":"xmage_fixed_boost_target_creature_until_eot_draw_card_spell_v1","count":1,"draw_count":1,"effect":"composite_resolution","instant":true,"power_boost":-4,"power_delta":-4,"sorcery":false,"toughness_boost":0,"toughness_delta":0,"xmage_effect_classes":["BoostTargetEffect","DrawCardSourceControllerEffect"]}'::jsonb, '{"category":"draw","effect":"composite_resolution","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Befuddle translated into ManaLoom runtime scope xmage_fixed_boost_target_creature_until_eot_draw_card_spell_v1. This row is package-ready only because the source signature is a narrow fixed target-creature boost plus draw-card spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('bewilder', 'Bewilder', '5ccbe79bcfb37ca4c7fd69b65aaa806e', 'battle_rule_v1:0b313835edf8058c09f667e60863f9ba', '{"_composite_rule_components":[{"battle_model_scope":"xmage_fixed_boost_target_creature_until_eot_spell_v1","compose_on_resolution":true,"duration":"until_end_of_turn","effect":"stat_modifier_until_eot","power_boost":-3,"power_delta":-3,"target":"creature","target_constraints":{"card_types":["creature"]},"target_controller":"any","toughness_boost":0,"toughness_delta":0,"xmage_effect_class":"BoostTargetEffect"},{"battle_model_scope":"xmage_fixed_source_controller_draw_spell_v1","compose_on_resolution":true,"count":1,"effect":"draw_cards","xmage_effect_class":"DrawCardSourceControllerEffect"}],"battle_model_scope":"xmage_fixed_boost_target_creature_until_eot_draw_card_spell_v1","count":1,"draw_count":1,"effect":"composite_resolution","instant":true,"power_boost":-3,"power_delta":-3,"sorcery":false,"toughness_boost":0,"toughness_delta":0,"xmage_effect_classes":["BoostTargetEffect","DrawCardSourceControllerEffect"]}'::jsonb, '{"category":"draw","effect":"composite_resolution","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Bewilder translated into ManaLoom runtime scope xmage_fixed_boost_target_creature_until_eot_draw_card_spell_v1. This row is package-ready only because the source signature is a narrow fixed target-creature boost plus draw-card spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('defiant strike', 'Defiant Strike', 'e2b69f7acef22951f3c01660041a309b', 'battle_rule_v1:84d2425bf0c293e7ac4bb17139b06db0', '{"_composite_rule_components":[{"battle_model_scope":"xmage_fixed_boost_target_creature_until_eot_spell_v1","compose_on_resolution":true,"duration":"until_end_of_turn","effect":"stat_modifier_until_eot","power_boost":1,"power_delta":1,"target":"creature","target_constraints":{"card_types":["creature"]},"target_controller":"any","toughness_boost":0,"toughness_delta":0,"xmage_effect_class":"BoostTargetEffect"},{"battle_model_scope":"xmage_fixed_source_controller_draw_spell_v1","compose_on_resolution":true,"count":1,"effect":"draw_cards","xmage_effect_class":"DrawCardSourceControllerEffect"}],"battle_model_scope":"xmage_fixed_boost_target_creature_until_eot_draw_card_spell_v1","count":1,"draw_count":1,"effect":"composite_resolution","instant":true,"power_boost":1,"power_delta":1,"sorcery":false,"toughness_boost":0,"toughness_delta":0,"xmage_effect_classes":["BoostTargetEffect","DrawCardSourceControllerEffect"]}'::jsonb, '{"category":"draw","effect":"composite_resolution","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class DefiantStrike translated into ManaLoom runtime scope xmage_fixed_boost_target_creature_until_eot_draw_card_spell_v1. This row is package-ready only because the source signature is a narrow fixed target-creature boost plus draw-card spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('fleeting distraction', 'Fleeting Distraction', '239c5ee6b2d37c972b3e57dd273cc43c', 'battle_rule_v1:65893665beae156031fae8a33825a054', '{"_composite_rule_components":[{"battle_model_scope":"xmage_fixed_boost_target_creature_until_eot_spell_v1","compose_on_resolution":true,"duration":"until_end_of_turn","effect":"stat_modifier_until_eot","power_boost":-1,"power_delta":-1,"target":"creature","target_constraints":{"card_types":["creature"]},"target_controller":"any","toughness_boost":0,"toughness_delta":0,"xmage_effect_class":"BoostTargetEffect"},{"battle_model_scope":"xmage_fixed_source_controller_draw_spell_v1","compose_on_resolution":true,"count":1,"effect":"draw_cards","xmage_effect_class":"DrawCardSourceControllerEffect"}],"battle_model_scope":"xmage_fixed_boost_target_creature_until_eot_draw_card_spell_v1","count":1,"draw_count":1,"effect":"composite_resolution","instant":true,"power_boost":-1,"power_delta":-1,"sorcery":false,"toughness_boost":0,"toughness_delta":0,"xmage_effect_classes":["BoostTargetEffect","DrawCardSourceControllerEffect"]}'::jsonb, '{"category":"draw","effect":"composite_resolution","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class FleetingDistraction translated into ManaLoom runtime scope xmage_fixed_boost_target_creature_until_eot_draw_card_spell_v1. This row is package-ready only because the source signature is a narrow fixed target-creature boost plus draw-card spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('rebellious strike', 'Rebellious Strike', 'b34983578b1e2174c1f78bcc9c340d80', 'battle_rule_v1:09d6c6f8cd65219d9b3ed2432dc8fd3a', '{"_composite_rule_components":[{"battle_model_scope":"xmage_fixed_boost_target_creature_until_eot_spell_v1","compose_on_resolution":true,"duration":"until_end_of_turn","effect":"stat_modifier_until_eot","power_boost":3,"power_delta":3,"target":"creature","target_constraints":{"card_types":["creature"]},"target_controller":"any","toughness_boost":0,"toughness_delta":0,"xmage_effect_class":"BoostTargetEffect"},{"battle_model_scope":"xmage_fixed_source_controller_draw_spell_v1","compose_on_resolution":true,"count":1,"effect":"draw_cards","xmage_effect_class":"DrawCardSourceControllerEffect"}],"battle_model_scope":"xmage_fixed_boost_target_creature_until_eot_draw_card_spell_v1","count":1,"draw_count":1,"effect":"composite_resolution","instant":true,"power_boost":3,"power_delta":3,"sorcery":false,"toughness_boost":0,"toughness_delta":0,"xmage_effect_classes":["BoostTargetEffect","DrawCardSourceControllerEffect"]}'::jsonb, '{"category":"draw","effect":"composite_resolution","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class RebelliousStrike translated into ManaLoom runtime scope xmage_fixed_boost_target_creature_until_eot_draw_card_spell_v1. This row is package-ready only because the source signature is a narrow fixed target-creature boost plus draw-card spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('shocking grasp', 'Shocking Grasp', 'cb7fe1a17713ee1953faf64d25ed0c98', 'battle_rule_v1:102d6f47bb28c3662d5e5a4a0463f660', '{"_composite_rule_components":[{"battle_model_scope":"xmage_fixed_boost_target_creature_until_eot_spell_v1","compose_on_resolution":true,"duration":"until_end_of_turn","effect":"stat_modifier_until_eot","power_boost":-2,"power_delta":-2,"target":"creature","target_constraints":{"card_types":["creature"]},"target_controller":"any","toughness_boost":0,"toughness_delta":0,"xmage_effect_class":"BoostTargetEffect"},{"battle_model_scope":"xmage_fixed_source_controller_draw_spell_v1","compose_on_resolution":true,"count":1,"effect":"draw_cards","xmage_effect_class":"DrawCardSourceControllerEffect"}],"battle_model_scope":"xmage_fixed_boost_target_creature_until_eot_draw_card_spell_v1","count":1,"draw_count":1,"effect":"composite_resolution","instant":true,"power_boost":-2,"power_delta":-2,"sorcery":false,"toughness_boost":0,"toughness_delta":0,"xmage_effect_classes":["BoostTargetEffect","DrawCardSourceControllerEffect"]}'::jsonb, '{"category":"draw","effect":"composite_resolution","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ShockingGrasp translated into ManaLoom runtime scope xmage_fixed_boost_target_creature_until_eot_draw_card_spell_v1. This row is package-ready only because the source signature is a narrow fixed target-creature boost plus draw-card spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('sudden strength', 'Sudden Strength', 'c45bd01776db602f966b795217b0b9f7', 'battle_rule_v1:9c9625f24619f505cce987d8dd110123', '{"_composite_rule_components":[{"battle_model_scope":"xmage_fixed_boost_target_creature_until_eot_spell_v1","compose_on_resolution":true,"duration":"until_end_of_turn","effect":"stat_modifier_until_eot","power_boost":3,"power_delta":3,"target":"creature","target_constraints":{"card_types":["creature"]},"target_controller":"any","toughness_boost":3,"toughness_delta":3,"xmage_effect_class":"BoostTargetEffect"},{"battle_model_scope":"xmage_fixed_source_controller_draw_spell_v1","compose_on_resolution":true,"count":1,"effect":"draw_cards","xmage_effect_class":"DrawCardSourceControllerEffect"}],"battle_model_scope":"xmage_fixed_boost_target_creature_until_eot_draw_card_spell_v1","count":1,"draw_count":1,"effect":"composite_resolution","instant":true,"power_boost":3,"power_delta":3,"sorcery":false,"toughness_boost":3,"toughness_delta":3,"xmage_effect_classes":["BoostTargetEffect","DrawCardSourceControllerEffect"]}'::jsonb, '{"category":"draw","effect":"composite_resolution","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class SuddenStrength translated into ManaLoom runtime scope xmage_fixed_boost_target_creature_until_eot_draw_card_spell_v1. This row is package-ready only because the source signature is a narrow fixed target-creature boost plus draw-card spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('sugar rush', 'Sugar Rush', 'b34983578b1e2174c1f78bcc9c340d80', 'battle_rule_v1:09d6c6f8cd65219d9b3ed2432dc8fd3a', '{"_composite_rule_components":[{"battle_model_scope":"xmage_fixed_boost_target_creature_until_eot_spell_v1","compose_on_resolution":true,"duration":"until_end_of_turn","effect":"stat_modifier_until_eot","power_boost":3,"power_delta":3,"target":"creature","target_constraints":{"card_types":["creature"]},"target_controller":"any","toughness_boost":0,"toughness_delta":0,"xmage_effect_class":"BoostTargetEffect"},{"battle_model_scope":"xmage_fixed_source_controller_draw_spell_v1","compose_on_resolution":true,"count":1,"effect":"draw_cards","xmage_effect_class":"DrawCardSourceControllerEffect"}],"battle_model_scope":"xmage_fixed_boost_target_creature_until_eot_draw_card_spell_v1","count":1,"draw_count":1,"effect":"composite_resolution","instant":true,"power_boost":3,"power_delta":3,"sorcery":false,"toughness_boost":0,"toughness_delta":0,"xmage_effect_classes":["BoostTargetEffect","DrawCardSourceControllerEffect"]}'::jsonb, '{"category":"draw","effect":"composite_resolution","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class SugarRush translated into ManaLoom runtime scope xmage_fixed_boost_target_creature_until_eot_draw_card_spell_v1. This row is package-ready only because the source signature is a narrow fixed target-creature boost plus draw-card spell with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
