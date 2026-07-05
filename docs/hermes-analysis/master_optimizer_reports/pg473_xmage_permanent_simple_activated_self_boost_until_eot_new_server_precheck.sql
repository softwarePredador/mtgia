WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('foxfire oak', 'Foxfire Oak', 'f92e4e4511fd16e75e835a1f22dbdb96', 'battle_rule_v1:ced93a57e24cd5ee4b9cac99c146e48f', '{"_activated_rule_effects":[{"ability_kind":"activated","activated_effect":"self_stat_modifier_until_eot","activation_cost_colors":["R/G","R/G","R/G"],"activation_cost_generic":0,"activation_cost_mana":"{R/G}{R/G}{R/G}","activation_requires_sacrifice":false,"activation_requires_tap":false,"battle_model_scope":"xmage_permanent_simple_activated_self_boost_until_eot_v1","duration":"until_end_of_turn","effect":"stat_modifier_until_eot","power_boost":3,"power_delta":3,"target":"self","target_constraints":{"card_types":["creature"],"source":"self"},"target_controller":"self","toughness_boost":0,"toughness_delta":0,"xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"BoostSourceEffect"}],"ability_kind":"static_and_activated","activated_battle_model_scope":"xmage_permanent_simple_activated_self_boost_until_eot_v1","activated_effect":"self_stat_modifier_until_eot","activation_cost_colors":["R/G","R/G","R/G"],"activation_cost_generic":0,"activation_cost_mana":"{R/G}{R/G}{R/G}","activation_requires_sacrifice":false,"activation_requires_tap":false,"battle_model_scope":"xmage_permanent_simple_activated_self_boost_until_eot_v1","duration":"until_end_of_turn","effect":"creature","power_boost":3,"power_delta":3,"target":"self","target_constraints":{"card_types":["creature"],"source":"self"},"target_controller":"self","toughness_boost":0,"toughness_delta":0,"xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"BoostSourceEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class FoxfireOak translated into ManaLoom runtime scope xmage_permanent_simple_activated_self_boost_until_eot_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('frostburn weird', 'Frostburn Weird', '6631bcede98207ccff056d973ceebfbb', 'battle_rule_v1:bfb84f4b62429cb2c15f03c22f13c634', '{"_activated_rule_effects":[{"ability_kind":"activated","activated_effect":"self_stat_modifier_until_eot","activation_cost_colors":["U/R"],"activation_cost_generic":0,"activation_cost_mana":"{U/R}","activation_requires_sacrifice":false,"activation_requires_tap":false,"battle_model_scope":"xmage_permanent_simple_activated_self_boost_until_eot_v1","duration":"until_end_of_turn","effect":"stat_modifier_until_eot","power_boost":1,"power_delta":1,"target":"self","target_constraints":{"card_types":["creature"],"source":"self"},"target_controller":"self","toughness_boost":-1,"toughness_delta":-1,"xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"BoostSourceEffect"}],"ability_kind":"static_and_activated","activated_battle_model_scope":"xmage_permanent_simple_activated_self_boost_until_eot_v1","activated_effect":"self_stat_modifier_until_eot","activation_cost_colors":["U/R"],"activation_cost_generic":0,"activation_cost_mana":"{U/R}","activation_requires_sacrifice":false,"activation_requires_tap":false,"battle_model_scope":"xmage_permanent_simple_activated_self_boost_until_eot_v1","duration":"until_end_of_turn","effect":"creature","power_boost":1,"power_delta":1,"target":"self","target_constraints":{"card_types":["creature"],"source":"self"},"target_controller":"self","toughness_boost":-1,"toughness_delta":-1,"xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"BoostSourceEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class FrostburnWeird translated into ManaLoom runtime scope xmage_permanent_simple_activated_self_boost_until_eot_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('loch korrigan', 'Loch Korrigan', '06d2b27101f16017ea92aec1554a69c9', 'battle_rule_v1:0910f17fa438b6dd99c27d522d289385', '{"_activated_rule_effects":[{"ability_kind":"activated","activated_effect":"self_stat_modifier_until_eot","activation_cost_colors":["U/B"],"activation_cost_generic":0,"activation_cost_mana":"{U/B}","activation_requires_sacrifice":false,"activation_requires_tap":false,"battle_model_scope":"xmage_permanent_simple_activated_self_boost_until_eot_v1","duration":"until_end_of_turn","effect":"stat_modifier_until_eot","power_boost":1,"power_delta":1,"target":"self","target_constraints":{"card_types":["creature"],"source":"self"},"target_controller":"self","toughness_boost":1,"toughness_delta":1,"xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"BoostSourceEffect"}],"ability_kind":"static_and_activated","activated_battle_model_scope":"xmage_permanent_simple_activated_self_boost_until_eot_v1","activated_effect":"self_stat_modifier_until_eot","activation_cost_colors":["U/B"],"activation_cost_generic":0,"activation_cost_mana":"{U/B}","activation_requires_sacrifice":false,"activation_requires_tap":false,"battle_model_scope":"xmage_permanent_simple_activated_self_boost_until_eot_v1","duration":"until_end_of_turn","effect":"creature","power_boost":1,"power_delta":1,"target":"self","target_constraints":{"card_types":["creature"],"source":"self"},"target_controller":"self","toughness_boost":1,"toughness_delta":1,"xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"BoostSourceEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class LochKorrigan translated into ManaLoom runtime scope xmage_permanent_simple_activated_self_boost_until_eot_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('parapet watchers', 'Parapet Watchers', 'c4393a49dad4b6f0b5b699c2f21396a5', 'battle_rule_v1:d91c066b4f00ed65ba374802194ff1c8', '{"_activated_rule_effects":[{"ability_kind":"activated","activated_effect":"self_stat_modifier_until_eot","activation_cost_colors":["W/U"],"activation_cost_generic":0,"activation_cost_mana":"{W/U}","activation_requires_sacrifice":false,"activation_requires_tap":false,"battle_model_scope":"xmage_permanent_simple_activated_self_boost_until_eot_v1","duration":"until_end_of_turn","effect":"stat_modifier_until_eot","power_boost":0,"power_delta":0,"target":"self","target_constraints":{"card_types":["creature"],"source":"self"},"target_controller":"self","toughness_boost":1,"toughness_delta":1,"xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"BoostSourceEffect"}],"ability_kind":"static_and_activated","activated_battle_model_scope":"xmage_permanent_simple_activated_self_boost_until_eot_v1","activated_effect":"self_stat_modifier_until_eot","activation_cost_colors":["W/U"],"activation_cost_generic":0,"activation_cost_mana":"{W/U}","activation_requires_sacrifice":false,"activation_requires_tap":false,"battle_model_scope":"xmage_permanent_simple_activated_self_boost_until_eot_v1","duration":"until_end_of_turn","effect":"creature","power_boost":0,"power_delta":0,"target":"self","target_constraints":{"card_types":["creature"],"source":"self"},"target_controller":"self","toughness_boost":1,"toughness_delta":1,"xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"BoostSourceEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ParapetWatchers translated into ManaLoom runtime scope xmage_permanent_simple_activated_self_boost_until_eot_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
