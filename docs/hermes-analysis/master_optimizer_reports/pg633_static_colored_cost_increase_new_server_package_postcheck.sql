WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('alabaster leech', 'Alabaster Leech', 'e7c2a0c4c950ed0738e080350a345bbd', 'battle_rule_v1:88b395d0c0c7cc5123797b48455a9e88', '{"ability_kind":"static","applies_to_spell_colors":["W"],"battle_model_scope":"xmage_static_generic_cost_increase_for_matching_spells_v1","cost_increase_amount_source":"fixed","cost_increase_applies_to":"spells_you_cast","cost_increase_color_symbols":["W"],"cost_increase_filters":[{"applies_to_spell_colors":["W"]}],"cost_increase_generic":0,"effect":"static_cost_increase","instant":false,"permanent_type":"creature","sorcery":false,"static_effect":"generic_cost_increase_for_matching_spells","xmage_ability_class":"SimpleStaticAbility","xmage_effect_class":"SpellsCostIncreasingAllEffect"}'::jsonb, '{"category":"unknown","effect":"static_cost_increase"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class AlabasterLeech translated into ManaLoom runtime scope xmage_static_generic_cost_increase_for_matching_spells_v1. This row is package-ready only because the source signature is a narrow permanent static generic cost increase for matching spells with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('derelor', 'Derelor', '8d9ecea248b1e7283cc48f6f9b74b4a4', 'battle_rule_v1:05af1d08c9819263e1ed091468c92619', '{"ability_kind":"static","applies_to_spell_colors":["B"],"battle_model_scope":"xmage_static_generic_cost_increase_for_matching_spells_v1","cost_increase_amount_source":"fixed","cost_increase_applies_to":"spells_you_cast","cost_increase_color_symbols":["B"],"cost_increase_filters":[{"applies_to_spell_colors":["B"]}],"cost_increase_generic":0,"effect":"static_cost_increase","instant":false,"permanent_type":"creature","sorcery":false,"static_effect":"generic_cost_increase_for_matching_spells","xmage_ability_class":"SimpleStaticAbility","xmage_effect_class":"SpellsCostIncreasingAllEffect"}'::jsonb, '{"category":"unknown","effect":"static_cost_increase"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Derelor translated into ManaLoom runtime scope xmage_static_generic_cost_increase_for_matching_spells_v1. This row is package-ready only because the source signature is a narrow permanent static generic cost increase for matching spells with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('jade leech', 'Jade Leech', '9b99eebb5e5009ee76776dbf6c3ce49c', 'battle_rule_v1:0e4f00561c6818cd4f49abd7255f4335', '{"ability_kind":"static","applies_to_spell_colors":["G"],"battle_model_scope":"xmage_static_generic_cost_increase_for_matching_spells_v1","cost_increase_amount_source":"fixed","cost_increase_applies_to":"spells_you_cast","cost_increase_color_symbols":["G"],"cost_increase_filters":[{"applies_to_spell_colors":["G"]}],"cost_increase_generic":0,"effect":"static_cost_increase","instant":false,"permanent_type":"creature","sorcery":false,"static_effect":"generic_cost_increase_for_matching_spells","xmage_ability_class":"SimpleStaticAbility","xmage_effect_class":"SpellsCostIncreasingAllEffect"}'::jsonb, '{"category":"unknown","effect":"static_cost_increase"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class JadeLeech translated into ManaLoom runtime scope xmage_static_generic_cost_increase_for_matching_spells_v1. This row is package-ready only because the source signature is a narrow permanent static generic cost increase for matching spells with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('ruby leech', 'Ruby Leech', 'afdea65ad826903da25f776e75e6b34d', 'battle_rule_v1:07e39974d21d191bcbb64924b6757a73', '{"_keywords_are_self":true,"ability_kind":"static","applies_to_spell_colors":["R"],"battle_model_scope":"xmage_static_generic_cost_increase_for_matching_spells_v1","cost_increase_amount_source":"fixed","cost_increase_applies_to":"spells_you_cast","cost_increase_color_symbols":["R"],"cost_increase_filters":[{"applies_to_spell_colors":["R"]}],"cost_increase_generic":0,"effect":"static_cost_increase","first_strike":true,"instant":false,"keywords":["first_strike"],"permanent_type":"creature","sorcery":false,"static_effect":"generic_cost_increase_for_matching_spells","xmage_ability_class":"SimpleStaticAbility","xmage_effect_class":"SpellsCostIncreasingAllEffect"}'::jsonb, '{"category":"unknown","effect":"static_cost_increase"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class RubyLeech translated into ManaLoom runtime scope xmage_static_generic_cost_increase_for_matching_spells_v1. This row is package-ready only because the source signature is a narrow permanent static generic cost increase for matching spells with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('sapphire leech', 'Sapphire Leech', 'fbe7a4420e2cf5ced99e5fd22fc2bf31', 'battle_rule_v1:0092745eb49d15a69bd8afafd8165d7f', '{"_keywords_are_self":true,"ability_kind":"static","applies_to_spell_colors":["U"],"battle_model_scope":"xmage_static_generic_cost_increase_for_matching_spells_v1","cost_increase_amount_source":"fixed","cost_increase_applies_to":"spells_you_cast","cost_increase_color_symbols":["U"],"cost_increase_filters":[{"applies_to_spell_colors":["U"]}],"cost_increase_generic":0,"effect":"static_cost_increase","flying":true,"instant":false,"keywords":["flying"],"permanent_type":"creature","sorcery":false,"static_effect":"generic_cost_increase_for_matching_spells","xmage_ability_class":"SimpleStaticAbility","xmage_effect_class":"SpellsCostIncreasingAllEffect"}'::jsonb, '{"category":"unknown","effect":"static_cost_increase"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class SapphireLeech translated into ManaLoom runtime scope xmage_static_generic_cost_increase_for_matching_spells_v1. This row is package-ready only because the source signature is a narrow permanent static generic cost increase for matching spells with focused runtime coverage.', 'deprecate_nonmatching_rows')
),
rule_rows AS (
  SELECT
    r.normalized_name,
    r.logical_rule_key,
    r.oracle_hash,
    r.review_status,
    r.execution_status
  FROM proposed p
  LEFT JOIN public.card_battle_rules r
    ON (
         r.normalized_name = p.normalized_name
         OR r.normalized_name LIKE p.normalized_name || ' // %'
       )
   AND r.logical_rule_key = p.logical_rule_key
)
SELECT
  p.card_name,
  p.normalized_name,
  p.logical_rule_key,
  count(r.*) FILTER (WHERE r.logical_rule_key = p.logical_rule_key) AS promoted_rule_rows,
  count(r.*) FILTER (WHERE r.review_status = 'verified' AND r.execution_status = 'auto') AS promoted_verified_auto_rows,
  count(r.*) FILTER (WHERE r.oracle_hash = p.oracle_hash) AS promoted_oracle_hash_rows,
  (SELECT count(*) FROM manaloom_deploy_audit.pg633_static_colored_cost_increase_new_s_20260707_192935) AS backup_rows
FROM proposed p
LEFT JOIN rule_rows r
  ON r.normalized_name = p.normalized_name
 AND r.logical_rule_key = p.logical_rule_key
 AND r.oracle_hash = p.oracle_hash
GROUP BY p.card_name, p.normalized_name, p.logical_rule_key, p.oracle_hash
ORDER BY p.card_name;
