WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('aerial maneuver', 'Aerial Maneuver', '221188eea4eb64a9e2984a9b2377c9d0', 'battle_rule_v1:56b71a4b25ae0b51c78fc93f659958bb', '{"battle_model_scope":"xmage_fixed_boost_and_keyword_target_creature_until_eot_spell_v1","duration":"until_end_of_turn","effect":"stat_modifier_until_eot","granted_keywords_until_eot":["flying","first_strike"],"instant":true,"power_boost":1,"power_delta":1,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"]},"target_controller":"any","toughness_boost":1,"toughness_delta":1,"xmage_ability_classes":["FirstStrikeAbility","FlyingAbility"],"xmage_effect_classes":["BoostTargetEffect","GainAbilityTargetEffect"]}'::jsonb, '{"category":"support","effect":"stat_modifier_until_eot","subtype":"temporary_pump","target":"creature","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class AerialManeuver translated into ManaLoom runtime scope xmage_fixed_boost_and_keyword_target_creature_until_eot_spell_v1. This row is package-ready only because the source signature is a narrow fixed target-creature boost plus until-end-of-turn keyword spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('daring leap', 'Daring Leap', '221188eea4eb64a9e2984a9b2377c9d0', 'battle_rule_v1:56b71a4b25ae0b51c78fc93f659958bb', '{"battle_model_scope":"xmage_fixed_boost_and_keyword_target_creature_until_eot_spell_v1","duration":"until_end_of_turn","effect":"stat_modifier_until_eot","granted_keywords_until_eot":["flying","first_strike"],"instant":true,"power_boost":1,"power_delta":1,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"]},"target_controller":"any","toughness_boost":1,"toughness_delta":1,"xmage_ability_classes":["FirstStrikeAbility","FlyingAbility"],"xmage_effect_classes":["BoostTargetEffect","GainAbilityTargetEffect"]}'::jsonb, '{"category":"support","effect":"stat_modifier_until_eot","subtype":"temporary_pump","target":"creature","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class DaringLeap translated into ManaLoom runtime scope xmage_fixed_boost_and_keyword_target_creature_until_eot_spell_v1. This row is package-ready only because the source signature is a narrow fixed target-creature boost plus until-end-of-turn keyword spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('fervent strike', 'Fervent Strike', 'f2aa1195e8d5b8d41743d91f98f9e26a', 'battle_rule_v1:3af1ff0cf902c4d7131169ce195d2108', '{"battle_model_scope":"xmage_fixed_boost_and_keyword_target_creature_until_eot_spell_v1","duration":"until_end_of_turn","effect":"stat_modifier_until_eot","granted_keywords_until_eot":["first_strike","haste"],"instant":true,"power_boost":1,"power_delta":1,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"]},"target_controller":"any","toughness_boost":0,"toughness_delta":0,"xmage_ability_classes":["FirstStrikeAbility","HasteAbility"],"xmage_effect_classes":["BoostTargetEffect","GainAbilityTargetEffect"]}'::jsonb, '{"category":"support","effect":"stat_modifier_until_eot","subtype":"temporary_pump","target":"creature","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class FerventStrike translated into ManaLoom runtime scope xmage_fixed_boost_and_keyword_target_creature_until_eot_spell_v1. This row is package-ready only because the source signature is a narrow fixed target-creature boost plus until-end-of-turn keyword spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('overprotect', 'Overprotect', '4753ce470c0bbcc0f2adcaed1988afff', 'battle_rule_v1:30b1e1c152d1848f17c5295ff0b4e05e', '{"battle_model_scope":"xmage_fixed_boost_and_keyword_target_creature_until_eot_spell_v1","duration":"until_end_of_turn","effect":"stat_modifier_until_eot","granted_keywords_until_eot":["trample","hexproof","indestructible"],"instant":true,"power_boost":3,"power_delta":3,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"]},"target_controller":"self","toughness_boost":3,"toughness_delta":3,"xmage_ability_classes":["HexproofAbility","IndestructibleAbility","TrampleAbility"],"xmage_effect_classes":["BoostTargetEffect","GainAbilityTargetEffect"]}'::jsonb, '{"category":"support","effect":"stat_modifier_until_eot","subtype":"temporary_pump","target":"creature","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Overprotect translated into ManaLoom runtime scope xmage_fixed_boost_and_keyword_target_creature_until_eot_spell_v1. This row is package-ready only because the source signature is a narrow fixed target-creature boost plus until-end-of-turn keyword spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('rig for war', 'Rig for War', '9de49f95911c9fd2dca3d5ea9b17ced0', 'battle_rule_v1:67b31a40bda8783bb93f9d93f1758518', '{"battle_model_scope":"xmage_fixed_boost_and_keyword_target_creature_until_eot_spell_v1","duration":"until_end_of_turn","effect":"stat_modifier_until_eot","granted_keywords_until_eot":["first_strike","reach"],"instant":true,"power_boost":3,"power_delta":3,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"]},"target_controller":"any","toughness_boost":0,"toughness_delta":0,"xmage_ability_classes":["FirstStrikeAbility","ReachAbility"],"xmage_effect_classes":["BoostTargetEffect","GainAbilityTargetEffect"]}'::jsonb, '{"category":"support","effect":"stat_modifier_until_eot","subtype":"temporary_pump","target":"creature","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class RigForWar translated into ManaLoom runtime scope xmage_fixed_boost_and_keyword_target_creature_until_eot_spell_v1. This row is package-ready only because the source signature is a narrow fixed target-creature boost plus until-end-of-turn keyword spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('rush of vitality', 'Rush of Vitality', 'ac77a1a9c3217cfb386007244f47e9c6', 'battle_rule_v1:b07fa8005b5622c941b96d27cd1046ba', '{"battle_model_scope":"xmage_fixed_boost_and_keyword_target_creature_until_eot_spell_v1","duration":"until_end_of_turn","effect":"stat_modifier_until_eot","granted_keywords_until_eot":["lifelink","indestructible"],"instant":true,"power_boost":1,"power_delta":1,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"]},"target_controller":"any","toughness_boost":0,"toughness_delta":0,"xmage_ability_classes":["IndestructibleAbility","LifelinkAbility"],"xmage_effect_classes":["BoostTargetEffect","GainAbilityTargetEffect"]}'::jsonb, '{"category":"support","effect":"stat_modifier_until_eot","subtype":"temporary_pump","target":"creature","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class RushOfVitality translated into ManaLoom runtime scope xmage_fixed_boost_and_keyword_target_creature_until_eot_spell_v1. This row is package-ready only because the source signature is a narrow fixed target-creature boost plus until-end-of-turn keyword spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('swift justice', 'Swift Justice', '721ece12befbf328b7835646a378e9cc', 'battle_rule_v1:6732b4c925bc1b1b1ff57114778f55cf', '{"battle_model_scope":"xmage_fixed_boost_and_keyword_target_creature_until_eot_spell_v1","duration":"until_end_of_turn","effect":"stat_modifier_until_eot","granted_keywords_until_eot":["first_strike","lifelink"],"instant":true,"power_boost":1,"power_delta":1,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"]},"target_controller":"any","toughness_boost":0,"toughness_delta":0,"xmage_ability_classes":["FirstStrikeAbility","LifelinkAbility"],"xmage_effect_classes":["BoostTargetEffect","GainAbilityTargetEffect"]}'::jsonb, '{"category":"support","effect":"stat_modifier_until_eot","subtype":"temporary_pump","target":"creature","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class SwiftJustice translated into ManaLoom runtime scope xmage_fixed_boost_and_keyword_target_creature_until_eot_spell_v1. This row is package-ready only because the source signature is a narrow fixed target-creature boost plus until-end-of-turn keyword spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('whirling strike', 'Whirling Strike', '54efde62150c83ccabecb99dd436534e', 'battle_rule_v1:6013fde232dfe15aea065b44428a448b', '{"battle_model_scope":"xmage_fixed_boost_and_keyword_target_creature_until_eot_spell_v1","duration":"until_end_of_turn","effect":"stat_modifier_until_eot","granted_keywords_until_eot":["first_strike","trample"],"instant":true,"power_boost":2,"power_delta":2,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"]},"target_controller":"any","toughness_boost":0,"toughness_delta":0,"xmage_ability_classes":["FirstStrikeAbility","TrampleAbility"],"xmage_effect_classes":["BoostTargetEffect","GainAbilityTargetEffect"]}'::jsonb, '{"category":"support","effect":"stat_modifier_until_eot","subtype":"temporary_pump","target":"creature","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class WhirlingStrike translated into ManaLoom runtime scope xmage_fixed_boost_and_keyword_target_creature_until_eot_spell_v1. This row is package-ready only because the source signature is a narrow fixed target-creature boost plus until-end-of-turn keyword spell with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
