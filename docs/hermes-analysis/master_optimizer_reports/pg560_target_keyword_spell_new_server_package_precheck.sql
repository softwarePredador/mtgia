WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('alesha''s legacy', 'Alesha''s Legacy', '44ab417eb2baba0b3f2656837a23f3fe', 'battle_rule_v1:86ddbb4414847a4263d461473c72a882', '{"battle_model_scope":"xmage_fixed_keyword_target_creature_until_eot_spell_v1","duration":"until_end_of_turn","effect":"stat_modifier_until_eot","granted_keywords_until_eot":["deathtouch","indestructible"],"instant":true,"power_boost":0,"power_delta":0,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"]},"target_controller":"self","toughness_boost":0,"toughness_delta":0,"xmage_ability_classes":["DeathtouchAbility","IndestructibleAbility"],"xmage_effect_class":"GainAbilityTargetEffect"}'::jsonb, '{"category":"support","effect":"stat_modifier_until_eot","subtype":"temporary_pump","target":"creature","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class AleshasLegacy translated into ManaLoom runtime scope xmage_fixed_keyword_target_creature_until_eot_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('assault strobe', 'Assault Strobe', '3becb38db1b3dcd8a0306eddd402ed13', 'battle_rule_v1:19a7bc7320a3d5f9fe2138f567b9f336', '{"battle_model_scope":"xmage_fixed_keyword_target_creature_until_eot_spell_v1","duration":"until_end_of_turn","effect":"stat_modifier_until_eot","granted_keywords_until_eot":["double_strike"],"instant":false,"power_boost":0,"power_delta":0,"sorcery":true,"target":"creature","target_constraints":{"card_types":["creature"]},"target_controller":"any","toughness_boost":0,"toughness_delta":0,"xmage_ability_classes":["DoubleStrikeAbility"],"xmage_effect_class":"GainAbilityTargetEffect"}'::jsonb, '{"category":"support","effect":"stat_modifier_until_eot","subtype":"temporary_pump","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class AssaultStrobe translated into ManaLoom runtime scope xmage_fixed_keyword_target_creature_until_eot_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('battle-rage blessing', 'Battle-Rage Blessing', '5738b136f3a8c1bc122429dee47d55c3', 'battle_rule_v1:eba43c09036c5996f18ebb89e91080bb', '{"battle_model_scope":"xmage_fixed_keyword_target_creature_until_eot_spell_v1","duration":"until_end_of_turn","effect":"stat_modifier_until_eot","granted_keywords_until_eot":["deathtouch","indestructible"],"instant":true,"power_boost":0,"power_delta":0,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"]},"target_controller":"any","toughness_boost":0,"toughness_delta":0,"xmage_ability_classes":["DeathtouchAbility","IndestructibleAbility"],"xmage_effect_class":"GainAbilityTargetEffect"}'::jsonb, '{"category":"support","effect":"stat_modifier_until_eot","subtype":"temporary_pump","target":"creature","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class BattleRageBlessing translated into ManaLoom runtime scope xmage_fixed_keyword_target_creature_until_eot_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('double cleave', 'Double Cleave', '3becb38db1b3dcd8a0306eddd402ed13', 'battle_rule_v1:8bf9be1f48750780ffd5a7059ae47e75', '{"battle_model_scope":"xmage_fixed_keyword_target_creature_until_eot_spell_v1","duration":"until_end_of_turn","effect":"stat_modifier_until_eot","granted_keywords_until_eot":["double_strike"],"instant":true,"power_boost":0,"power_delta":0,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"]},"target_controller":"any","toughness_boost":0,"toughness_delta":0,"xmage_ability_classes":["DoubleStrikeAbility"],"xmage_effect_class":"GainAbilityTargetEffect"}'::jsonb, '{"category":"support","effect":"stat_modifier_until_eot","subtype":"temporary_pump","target":"creature","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class DoubleCleave translated into ManaLoom runtime scope xmage_fixed_keyword_target_creature_until_eot_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('horrid vigor', 'Horrid Vigor', '16f72812647b7b6ebd06602a3e8415fe', 'battle_rule_v1:eba43c09036c5996f18ebb89e91080bb', '{"battle_model_scope":"xmage_fixed_keyword_target_creature_until_eot_spell_v1","duration":"until_end_of_turn","effect":"stat_modifier_until_eot","granted_keywords_until_eot":["deathtouch","indestructible"],"instant":true,"power_boost":0,"power_delta":0,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"]},"target_controller":"any","toughness_boost":0,"toughness_delta":0,"xmage_ability_classes":["DeathtouchAbility","IndestructibleAbility"],"xmage_effect_class":"GainAbilityTargetEffect"}'::jsonb, '{"category":"support","effect":"stat_modifier_until_eot","subtype":"temporary_pump","target":"creature","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class HorridVigor translated into ManaLoom runtime scope xmage_fixed_keyword_target_creature_until_eot_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('jump', 'Jump', 'ae63312ccd991825d03f1229015c8d36', 'battle_rule_v1:8edc824d3b408970c2be21310425c6c8', '{"battle_model_scope":"xmage_fixed_keyword_target_creature_until_eot_spell_v1","duration":"until_end_of_turn","effect":"stat_modifier_until_eot","granted_keywords_until_eot":["flying"],"instant":true,"power_boost":0,"power_delta":0,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"]},"target_controller":"any","toughness_boost":0,"toughness_delta":0,"xmage_ability_classes":["FlyingAbility"],"xmage_effect_class":"GainAbilityTargetEffect"}'::jsonb, '{"category":"support","effect":"stat_modifier_until_eot","subtype":"temporary_pump","target":"creature","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Jump translated into ManaLoom runtime scope xmage_fixed_keyword_target_creature_until_eot_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('offer immortality', 'Offer Immortality', '5738b136f3a8c1bc122429dee47d55c3', 'battle_rule_v1:eba43c09036c5996f18ebb89e91080bb', '{"battle_model_scope":"xmage_fixed_keyword_target_creature_until_eot_spell_v1","duration":"until_end_of_turn","effect":"stat_modifier_until_eot","granted_keywords_until_eot":["deathtouch","indestructible"],"instant":true,"power_boost":0,"power_delta":0,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"]},"target_controller":"any","toughness_boost":0,"toughness_delta":0,"xmage_ability_classes":["DeathtouchAbility","IndestructibleAbility"],"xmage_effect_class":"GainAbilityTargetEffect"}'::jsonb, '{"category":"support","effect":"stat_modifier_until_eot","subtype":"temporary_pump","target":"creature","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class OfferImmortality translated into ManaLoom runtime scope xmage_fixed_keyword_target_creature_until_eot_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('serpent''s gift', 'Serpent''s Gift', '01593088748dd471d3846b334c388118', 'battle_rule_v1:d8dcdb430502bd2b37d661018bd32aa9', '{"battle_model_scope":"xmage_fixed_keyword_target_creature_until_eot_spell_v1","duration":"until_end_of_turn","effect":"stat_modifier_until_eot","granted_keywords_until_eot":["deathtouch"],"instant":true,"power_boost":0,"power_delta":0,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"]},"target_controller":"any","toughness_boost":0,"toughness_delta":0,"xmage_ability_classes":["DeathtouchAbility"],"xmage_effect_class":"GainAbilityTargetEffect"}'::jsonb, '{"category":"support","effect":"stat_modifier_until_eot","subtype":"temporary_pump","target":"creature","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class SerpentsGift translated into ManaLoom runtime scope xmage_fixed_keyword_target_creature_until_eot_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('ticked off', 'Ticked Off', '3becb38db1b3dcd8a0306eddd402ed13', 'battle_rule_v1:19a7bc7320a3d5f9fe2138f567b9f336', '{"battle_model_scope":"xmage_fixed_keyword_target_creature_until_eot_spell_v1","duration":"until_end_of_turn","effect":"stat_modifier_until_eot","granted_keywords_until_eot":["double_strike"],"instant":false,"power_boost":0,"power_delta":0,"sorcery":true,"target":"creature","target_constraints":{"card_types":["creature"]},"target_controller":"any","toughness_boost":0,"toughness_delta":0,"xmage_ability_classes":["DoubleStrikeAbility"],"xmage_effect_class":"GainAbilityTargetEffect"}'::jsonb, '{"category":"support","effect":"stat_modifier_until_eot","subtype":"temporary_pump","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class TickedOff translated into ManaLoom runtime scope xmage_fixed_keyword_target_creature_until_eot_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('unnatural speed', 'Unnatural Speed', '763d6a49451a4cdbf02081795e2be17a', 'battle_rule_v1:ddd9fa2026191b67377e3d53084771fc', '{"battle_model_scope":"xmage_fixed_keyword_target_creature_until_eot_spell_v1","duration":"until_end_of_turn","effect":"stat_modifier_until_eot","granted_keywords_until_eot":["haste"],"instant":true,"power_boost":0,"power_delta":0,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"]},"target_controller":"any","toughness_boost":0,"toughness_delta":0,"xmage_ability_classes":["HasteAbility"],"xmage_effect_class":"GainAbilityTargetEffect"}'::jsonb, '{"category":"support","effect":"stat_modifier_until_eot","subtype":"temporary_pump","target":"creature","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class UnnaturalSpeed translated into ManaLoom runtime scope xmage_fixed_keyword_target_creature_until_eot_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
