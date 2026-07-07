WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('alabaster leech', 'Alabaster Leech', 'e7c2a0c4c950ed0738e080350a345bbd', 'battle_rule_v1:88b395d0c0c7cc5123797b48455a9e88', '{"ability_kind":"static","applies_to_spell_colors":["W"],"battle_model_scope":"xmage_static_generic_cost_increase_for_matching_spells_v1","cost_increase_amount_source":"fixed","cost_increase_applies_to":"spells_you_cast","cost_increase_color_symbols":["W"],"cost_increase_filters":[{"applies_to_spell_colors":["W"]}],"cost_increase_generic":0,"effect":"static_cost_increase","instant":false,"permanent_type":"creature","sorcery":false,"static_effect":"generic_cost_increase_for_matching_spells","xmage_ability_class":"SimpleStaticAbility","xmage_effect_class":"SpellsCostIncreasingAllEffect"}'::jsonb, '{"category":"unknown","effect":"static_cost_increase"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class AlabasterLeech translated into ManaLoom runtime scope xmage_static_generic_cost_increase_for_matching_spells_v1. This row is package-ready only because the source signature is a narrow permanent static generic cost increase for matching spells with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('derelor', 'Derelor', '8d9ecea248b1e7283cc48f6f9b74b4a4', 'battle_rule_v1:05af1d08c9819263e1ed091468c92619', '{"ability_kind":"static","applies_to_spell_colors":["B"],"battle_model_scope":"xmage_static_generic_cost_increase_for_matching_spells_v1","cost_increase_amount_source":"fixed","cost_increase_applies_to":"spells_you_cast","cost_increase_color_symbols":["B"],"cost_increase_filters":[{"applies_to_spell_colors":["B"]}],"cost_increase_generic":0,"effect":"static_cost_increase","instant":false,"permanent_type":"creature","sorcery":false,"static_effect":"generic_cost_increase_for_matching_spells","xmage_ability_class":"SimpleStaticAbility","xmage_effect_class":"SpellsCostIncreasingAllEffect"}'::jsonb, '{"category":"unknown","effect":"static_cost_increase"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Derelor translated into ManaLoom runtime scope xmage_static_generic_cost_increase_for_matching_spells_v1. This row is package-ready only because the source signature is a narrow permanent static generic cost increase for matching spells with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('jade leech', 'Jade Leech', '9b99eebb5e5009ee76776dbf6c3ce49c', 'battle_rule_v1:0e4f00561c6818cd4f49abd7255f4335', '{"ability_kind":"static","applies_to_spell_colors":["G"],"battle_model_scope":"xmage_static_generic_cost_increase_for_matching_spells_v1","cost_increase_amount_source":"fixed","cost_increase_applies_to":"spells_you_cast","cost_increase_color_symbols":["G"],"cost_increase_filters":[{"applies_to_spell_colors":["G"]}],"cost_increase_generic":0,"effect":"static_cost_increase","instant":false,"permanent_type":"creature","sorcery":false,"static_effect":"generic_cost_increase_for_matching_spells","xmage_ability_class":"SimpleStaticAbility","xmage_effect_class":"SpellsCostIncreasingAllEffect"}'::jsonb, '{"category":"unknown","effect":"static_cost_increase"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class JadeLeech translated into ManaLoom runtime scope xmage_static_generic_cost_increase_for_matching_spells_v1. This row is package-ready only because the source signature is a narrow permanent static generic cost increase for matching spells with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('ruby leech', 'Ruby Leech', 'afdea65ad826903da25f776e75e6b34d', 'battle_rule_v1:07e39974d21d191bcbb64924b6757a73', '{"_keywords_are_self":true,"ability_kind":"static","applies_to_spell_colors":["R"],"battle_model_scope":"xmage_static_generic_cost_increase_for_matching_spells_v1","cost_increase_amount_source":"fixed","cost_increase_applies_to":"spells_you_cast","cost_increase_color_symbols":["R"],"cost_increase_filters":[{"applies_to_spell_colors":["R"]}],"cost_increase_generic":0,"effect":"static_cost_increase","first_strike":true,"instant":false,"keywords":["first_strike"],"permanent_type":"creature","sorcery":false,"static_effect":"generic_cost_increase_for_matching_spells","xmage_ability_class":"SimpleStaticAbility","xmage_effect_class":"SpellsCostIncreasingAllEffect"}'::jsonb, '{"category":"unknown","effect":"static_cost_increase"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class RubyLeech translated into ManaLoom runtime scope xmage_static_generic_cost_increase_for_matching_spells_v1. This row is package-ready only because the source signature is a narrow permanent static generic cost increase for matching spells with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('sapphire leech', 'Sapphire Leech', 'fbe7a4420e2cf5ced99e5fd22fc2bf31', 'battle_rule_v1:0092745eb49d15a69bd8afafd8165d7f', '{"_keywords_are_self":true,"ability_kind":"static","applies_to_spell_colors":["U"],"battle_model_scope":"xmage_static_generic_cost_increase_for_matching_spells_v1","cost_increase_amount_source":"fixed","cost_increase_applies_to":"spells_you_cast","cost_increase_color_symbols":["U"],"cost_increase_filters":[{"applies_to_spell_colors":["U"]}],"cost_increase_generic":0,"effect":"static_cost_increase","flying":true,"instant":false,"keywords":["flying"],"permanent_type":"creature","sorcery":false,"static_effect":"generic_cost_increase_for_matching_spells","xmage_ability_class":"SimpleStaticAbility","xmage_effect_class":"SpellsCostIncreasingAllEffect"}'::jsonb, '{"category":"unknown","effect":"static_cost_increase"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class SapphireLeech translated into ManaLoom runtime scope xmage_static_generic_cost_increase_for_matching_spells_v1. This row is package-ready only because the source signature is a narrow permanent static generic cost increase for matching spells with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
