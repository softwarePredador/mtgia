WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('free from flesh', 'Free from Flesh', 'fde893ade3ee82b79267944138f34f0c', 'battle_rule_v1:a6c8ca893db8e31b2651813767ae11ff', '{"_composite_rule_components":[{"battle_model_scope":"xmage_fixed_boost_target_creature_until_eot_spell_v1","compose_on_resolution":true,"duration":"until_end_of_turn","effect":"stat_modifier_until_eot","instant":true,"power_boost":2,"power_delta":2,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"]},"target_controller":"any","target_count":1,"target_count_max":1,"target_count_min":1,"toughness_boost":2,"toughness_delta":2,"up_to_count":false,"xmage_effect_class":"BoostTargetEffect"},{"battle_model_scope":"xmage_fixed_add_counters_target_creature_spell_v1","compose_on_resolution":true,"count":2,"counter_count":2,"counter_type":"oil","effect":"add_counters","instant":true,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"]},"target_controller":"any","target_count":1,"target_count_max":1,"target_count_min":1,"up_to_count":false,"xmage_effect_class":"AddCountersTargetEffect"}],"battle_model_scope":"xmage_fixed_boost_target_creature_until_eot_add_counter_spell_v1","count":2,"counter_count":2,"counter_type":"oil","effect":"composite_resolution","instant":true,"power_boost":2,"power_delta":2,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"]},"target_controller":"any","target_count":1,"target_count_max":1,"target_count_min":1,"toughness_boost":2,"toughness_delta":2,"up_to_count":false,"xmage_effect_classes":["BoostTargetEffect","AddCountersTargetEffect"]}'::jsonb, '{"category":"draw","effect":"composite_resolution","target":"creature","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class FreeFromFlesh translated into ManaLoom runtime scope xmage_fixed_boost_target_creature_until_eot_add_counter_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('fully grown', 'Fully Grown', '4d625f9e11506dcae0125d7b8a7b4f14', 'battle_rule_v1:bb1280eb2bb34751693a227336c0fe8a', '{"_composite_rule_components":[{"battle_model_scope":"xmage_fixed_boost_target_creature_until_eot_spell_v1","compose_on_resolution":true,"duration":"until_end_of_turn","effect":"stat_modifier_until_eot","instant":true,"power_boost":3,"power_delta":3,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"]},"target_controller":"any","target_count":1,"target_count_max":1,"target_count_min":1,"toughness_boost":3,"toughness_delta":3,"up_to_count":false,"xmage_effect_class":"BoostTargetEffect"},{"battle_model_scope":"xmage_fixed_add_counters_target_creature_spell_v1","compose_on_resolution":true,"count":1,"counter_count":1,"counter_type":"trample","effect":"add_counters","instant":true,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"]},"target_controller":"any","target_count":1,"target_count_max":1,"target_count_min":1,"up_to_count":false,"xmage_effect_class":"AddCountersTargetEffect"}],"battle_model_scope":"xmage_fixed_boost_target_creature_until_eot_add_counter_spell_v1","count":1,"counter_count":1,"counter_type":"trample","effect":"composite_resolution","instant":true,"power_boost":3,"power_delta":3,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"]},"target_controller":"any","target_count":1,"target_count_max":1,"target_count_min":1,"toughness_boost":3,"toughness_delta":3,"up_to_count":false,"xmage_effect_classes":["BoostTargetEffect","AddCountersTargetEffect"]}'::jsonb, '{"category":"draw","effect":"composite_resolution","target":"creature","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class FullyGrown translated into ManaLoom runtime scope xmage_fixed_boost_target_creature_until_eot_add_counter_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('heightened reflexes', 'Heightened Reflexes', '86595d84576bee126e2523a142f09e81', 'battle_rule_v1:1babdef80e17b624eb197357448811eb', '{"_composite_rule_components":[{"battle_model_scope":"xmage_fixed_boost_target_creature_until_eot_spell_v1","compose_on_resolution":true,"duration":"until_end_of_turn","effect":"stat_modifier_until_eot","instant":true,"power_boost":1,"power_delta":1,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"]},"target_controller":"any","target_count":1,"target_count_max":1,"target_count_min":1,"toughness_boost":0,"toughness_delta":0,"up_to_count":false,"xmage_effect_class":"BoostTargetEffect"},{"battle_model_scope":"xmage_fixed_add_counters_target_creature_spell_v1","compose_on_resolution":true,"count":1,"counter_count":1,"counter_type":"first_strike","effect":"add_counters","instant":true,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"]},"target_controller":"any","target_count":1,"target_count_max":1,"target_count_min":1,"up_to_count":false,"xmage_effect_class":"AddCountersTargetEffect"}],"battle_model_scope":"xmage_fixed_boost_target_creature_until_eot_add_counter_spell_v1","count":1,"counter_count":1,"counter_type":"first_strike","effect":"composite_resolution","instant":true,"power_boost":1,"power_delta":1,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"]},"target_controller":"any","target_count":1,"target_count_max":1,"target_count_min":1,"toughness_boost":0,"toughness_delta":0,"up_to_count":false,"xmage_effect_classes":["BoostTargetEffect","AddCountersTargetEffect"]}'::jsonb, '{"category":"draw","effect":"composite_resolution","target":"creature","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class HeightenedReflexes translated into ManaLoom runtime scope xmage_fixed_boost_target_creature_until_eot_add_counter_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('spontaneous flight', 'Spontaneous Flight', '560d5fded4189609f47d244ec7cb3bc0', 'battle_rule_v1:2948e42cbec41eac164ff370b1e6c6b8', '{"_composite_rule_components":[{"battle_model_scope":"xmage_fixed_boost_target_creature_until_eot_spell_v1","compose_on_resolution":true,"duration":"until_end_of_turn","effect":"stat_modifier_until_eot","instant":true,"power_boost":2,"power_delta":2,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"]},"target_controller":"any","target_count":1,"target_count_max":1,"target_count_min":1,"toughness_boost":2,"toughness_delta":2,"up_to_count":false,"xmage_effect_class":"BoostTargetEffect"},{"battle_model_scope":"xmage_fixed_add_counters_target_creature_spell_v1","compose_on_resolution":true,"count":1,"counter_count":1,"counter_type":"flying","effect":"add_counters","instant":true,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"]},"target_controller":"any","target_count":1,"target_count_max":1,"target_count_min":1,"up_to_count":false,"xmage_effect_class":"AddCountersTargetEffect"}],"battle_model_scope":"xmage_fixed_boost_target_creature_until_eot_add_counter_spell_v1","count":1,"counter_count":1,"counter_type":"flying","effect":"composite_resolution","instant":true,"power_boost":2,"power_delta":2,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"]},"target_controller":"any","target_count":1,"target_count_max":1,"target_count_min":1,"toughness_boost":2,"toughness_delta":2,"up_to_count":false,"xmage_effect_classes":["BoostTargetEffect","AddCountersTargetEffect"]}'::jsonb, '{"category":"draw","effect":"composite_resolution","target":"creature","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class SpontaneousFlight translated into ManaLoom runtime scope xmage_fixed_boost_target_creature_until_eot_add_counter_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
