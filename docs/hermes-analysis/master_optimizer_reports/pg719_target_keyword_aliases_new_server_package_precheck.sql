WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('breach', 'Breach', '224c0d53fa8be85465b652ca0159f3d3', 'battle_rule_v1:1a80a59bfe60d19ce999c58d8ac0625d', '{"battle_model_scope":"xmage_fixed_boost_and_keyword_target_creature_until_eot_spell_v1","duration":"until_end_of_turn","effect":"stat_modifier_until_eot","granted_keywords_until_eot":["fear"],"instant":true,"power_boost":2,"power_delta":2,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"]},"target_controller":"any","toughness_boost":0,"toughness_delta":0,"xmage_ability_classes":["FearAbility"],"xmage_effect_classes":["BoostTargetEffect","GainAbilityTargetEffect"]}'::jsonb, '{"category":"support","effect":"stat_modifier_until_eot","subtype":"temporary_pump","target":"creature","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Breach translated into ManaLoom runtime scope xmage_fixed_boost_and_keyword_target_creature_until_eot_spell_v1. This row is package-ready only because the source signature is a narrow fixed target-creature boost plus until-end-of-turn keyword spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('hooded kavu', 'Hooded Kavu', '50d94303fbeddf742c7ad88d483140dd', 'battle_rule_v1:5f8dd5e86f63f36f1155e92d6949b87b', '{"_activated_rule_effects":[{"ability_kind":"activated","activated_effect":"self_keyword_until_eot","activation_cost_colors":["B"],"activation_cost_generic":0,"activation_cost_mana":"{B}","activation_requires_sacrifice":false,"activation_requires_tap":false,"battle_model_scope":"xmage_permanent_simple_activated_self_keyword_until_eot_v1","duration":"until_end_of_turn","effect":"stat_modifier_until_eot","granted_keywords_until_eot":["fear"],"power_delta":0,"target":"self","target_constraints":{"card_types":["creature"],"source":"self"},"target_controller":"self","toughness_delta":0,"xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"GainAbilitySourceEffect","xmage_keyword_ability_class":"FearAbility"}],"ability_kind":"static_and_activated","activated_battle_model_scope":"xmage_permanent_simple_activated_self_keyword_until_eot_v1","activated_effect":"self_keyword_until_eot","activation_cost_colors":["B"],"activation_cost_generic":0,"activation_cost_mana":"{B}","activation_requires_sacrifice":false,"activation_requires_tap":false,"battle_model_scope":"xmage_permanent_simple_activated_self_keyword_until_eot_v1","duration":"until_end_of_turn","effect":"creature","granted_keywords_until_eot":["fear"],"power_delta":0,"target":"self","target_constraints":{"card_types":["creature"],"source":"self"},"target_controller":"self","toughness_delta":0,"xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"GainAbilitySourceEffect","xmage_keyword_ability_class":"FearAbility"}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class HoodedKavu translated into ManaLoom runtime scope xmage_permanent_simple_activated_self_keyword_until_eot_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('shriek of dread', 'Shriek of Dread', '9b96055cb88f677761b150c4b7d5a167', 'battle_rule_v1:8d46159e8ae2f9b5ee8b04b9f0b2db80', '{"battle_model_scope":"xmage_fixed_keyword_target_creature_until_eot_spell_v1","duration":"until_end_of_turn","effect":"stat_modifier_until_eot","granted_keywords_until_eot":["fear"],"instant":true,"power_boost":0,"power_delta":0,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"]},"target_controller":"any","toughness_boost":0,"toughness_delta":0,"xmage_ability_classes":["FearAbility"],"xmage_effect_class":"GainAbilityTargetEffect"}'::jsonb, '{"category":"support","effect":"stat_modifier_until_eot","subtype":"temporary_pump","target":"creature","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ShriekOfDread translated into ManaLoom runtime scope xmage_fixed_keyword_target_creature_until_eot_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('withstand death', 'Withstand Death', '7cf7b1aef30648b3a79cba54d4c8f659', 'battle_rule_v1:64b2eb6d72830a72e6188d12589b5e97', '{"battle_model_scope":"xmage_fixed_keyword_target_creature_until_eot_spell_v1","duration":"until_end_of_turn","effect":"stat_modifier_until_eot","granted_keywords_until_eot":["indestructible"],"instant":true,"power_boost":0,"power_delta":0,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"]},"target_controller":"any","toughness_boost":0,"toughness_delta":0,"xmage_ability_classes":["IndestructibleAbility"],"xmage_effect_class":"GainAbilityTargetEffect"}'::jsonb, '{"category":"support","effect":"stat_modifier_until_eot","subtype":"temporary_pump","target":"creature","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class WithstandDeath translated into ManaLoom runtime scope xmage_fixed_keyword_target_creature_until_eot_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
