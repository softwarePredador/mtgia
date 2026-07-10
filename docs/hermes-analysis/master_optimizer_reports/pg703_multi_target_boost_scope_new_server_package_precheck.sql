WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('dauntless onslaught', 'Dauntless Onslaught', 'b25037b66b47c2746777fca994bbd047', 'battle_rule_v1:2833a7f6bfdb677cd0d3f0a26cc5cc6e', '{"battle_model_scope":"xmage_fixed_boost_target_creature_until_eot_spell_v1","duration":"until_end_of_turn","effect":"stat_modifier_until_eot","instant":true,"power_boost":2,"power_delta":2,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"]},"target_controller":"any","target_count":2,"target_count_max":2,"target_count_min":0,"toughness_boost":2,"toughness_delta":2,"up_to_count":true,"xmage_effect_class":"BoostTargetEffect"}'::jsonb, '{"category":"support","effect":"stat_modifier_until_eot","subtype":"temporary_pump","target":"creature","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class DauntlessOnslaught translated into ManaLoom runtime scope xmage_fixed_boost_target_creature_until_eot_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('hearts on fire', 'Hearts on Fire', '95679abe60fdb5c15a1ddf3b711c0dfc', 'battle_rule_v1:d588e7158b14dfec37cf73bd0ec5a7e8', '{"battle_model_scope":"xmage_fixed_boost_target_creature_until_eot_spell_v1","duration":"until_end_of_turn","effect":"stat_modifier_until_eot","instant":true,"power_boost":2,"power_delta":2,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"]},"target_controller":"any","target_count":2,"target_count_max":2,"target_count_min":1,"toughness_boost":1,"toughness_delta":1,"up_to_count":true,"xmage_effect_class":"BoostTargetEffect"}'::jsonb, '{"category":"support","effect":"stat_modifier_until_eot","subtype":"temporary_pump","target":"creature","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class HeartsOnFire translated into ManaLoom runtime scope xmage_fixed_boost_target_creature_until_eot_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('mischief and mayhem', 'Mischief and Mayhem', 'dc7da00dadc9a5d5c2ddb477a35f1985', 'battle_rule_v1:9df4b1214f52a2f3cc04a1b09fd9850d', '{"battle_model_scope":"xmage_fixed_boost_target_creature_until_eot_spell_v1","duration":"until_end_of_turn","effect":"stat_modifier_until_eot","instant":false,"power_boost":4,"power_delta":4,"sorcery":true,"target":"creature","target_constraints":{"card_types":["creature"]},"target_controller":"any","target_count":2,"target_count_max":2,"target_count_min":0,"toughness_boost":4,"toughness_delta":4,"up_to_count":true,"xmage_effect_class":"BoostTargetEffect"}'::jsonb, '{"category":"support","effect":"stat_modifier_until_eot","subtype":"temporary_pump","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class MischiefAndMayhem translated into ManaLoom runtime scope xmage_fixed_boost_target_creature_until_eot_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('nahiri''s stoneblades', 'Nahiri''s Stoneblades', '7b1fa83ffeda7fba0b3f63f028916559', 'battle_rule_v1:2f81c811687ee235821a0248d8e3e5b5', '{"battle_model_scope":"xmage_fixed_boost_target_creature_until_eot_spell_v1","duration":"until_end_of_turn","effect":"stat_modifier_until_eot","instant":true,"power_boost":2,"power_delta":2,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"]},"target_controller":"any","target_count":2,"target_count_max":2,"target_count_min":0,"toughness_boost":0,"toughness_delta":0,"up_to_count":true,"xmage_effect_class":"BoostTargetEffect"}'::jsonb, '{"category":"support","effect":"stat_modifier_until_eot","subtype":"temporary_pump","target":"creature","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class NahirisStoneblades translated into ManaLoom runtime scope xmage_fixed_boost_target_creature_until_eot_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('sick and tired', 'Sick and Tired', 'b6c3e113eb33fa162891fc31678a71b0', 'battle_rule_v1:c8493813d11edd236b1ba95205a08489', '{"battle_model_scope":"xmage_fixed_boost_target_creature_until_eot_spell_v1","duration":"until_end_of_turn","effect":"stat_modifier_until_eot","instant":true,"power_boost":-1,"power_delta":-1,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"]},"target_controller":"any","target_count":2,"target_count_max":2,"target_count_min":2,"toughness_boost":-1,"toughness_delta":-1,"up_to_count":false,"xmage_effect_class":"BoostTargetEffect"}'::jsonb, '{"category":"removal","effect":"stat_modifier_until_eot","subtype":"temporary_debuff","target":"creature","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class SickAndTired translated into ManaLoom runtime scope xmage_fixed_boost_target_creature_until_eot_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('symbiosis', 'Symbiosis', '8a7990bc274aafbd6d9ea4ab8c5d4be6', 'battle_rule_v1:0f4076c66f0ce555911e06dfb18b0fcc', '{"battle_model_scope":"xmage_fixed_boost_target_creature_until_eot_spell_v1","duration":"until_end_of_turn","effect":"stat_modifier_until_eot","instant":true,"power_boost":2,"power_delta":2,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"]},"target_controller":"any","target_count":2,"target_count_max":2,"target_count_min":2,"toughness_boost":2,"toughness_delta":2,"up_to_count":false,"xmage_effect_class":"BoostTargetEffect"}'::jsonb, '{"category":"support","effect":"stat_modifier_until_eot","subtype":"temporary_pump","target":"creature","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Symbiosis translated into ManaLoom runtime scope xmage_fixed_boost_target_creature_until_eot_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('windborne charge', 'Windborne Charge', 'c2c0cfb8033dadc8e9ae44225f033808', 'battle_rule_v1:eab89b66d1672720d20f40cbd7bc7387', '{"battle_model_scope":"xmage_fixed_boost_and_keyword_target_creature_until_eot_spell_v1","duration":"until_end_of_turn","effect":"stat_modifier_until_eot","granted_keywords_until_eot":["flying"],"instant":false,"power_boost":2,"power_delta":2,"sorcery":true,"target":"creature","target_constraints":{"card_types":["creature"]},"target_controller":"self","target_count":2,"target_count_max":2,"target_count_min":2,"toughness_boost":2,"toughness_delta":2,"up_to_count":false,"xmage_ability_classes":["FlyingAbility"],"xmage_effect_classes":["BoostTargetEffect","GainAbilityTargetEffect"]}'::jsonb, '{"category":"support","effect":"stat_modifier_until_eot","subtype":"temporary_pump","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class WindborneCharge translated into ManaLoom runtime scope xmage_fixed_boost_and_keyword_target_creature_until_eot_spell_v1. This row is package-ready only because the source signature is a narrow fixed target-creature boost plus until-end-of-turn keyword spell with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
