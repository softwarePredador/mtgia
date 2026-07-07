WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('chill', 'Chill', 'f4ac8621285e1e52dd72499ccf64d9d4', 'battle_rule_v1:42e1803a0fa35bde5078216f000a8565', '{"ability_kind":"static","applies_to_spell_colors":["R"],"battle_model_scope":"xmage_static_generic_cost_increase_for_matching_spells_v1","cost_increase_amount_source":"fixed","cost_increase_applies_to":"spells_each_player_cast","cost_increase_filters":[{"applies_to_spell_colors":["R"]}],"cost_increase_generic":2,"effect":"static_cost_increase","instant":false,"permanent_type":"enchantment","sorcery":false,"static_effect":"generic_cost_increase_for_matching_spells","xmage_ability_class":"SimpleStaticAbility","xmage_effect_class":"SpellsCostIncreasingAllEffect"}'::jsonb, '{"category":"unknown","effect":"static_cost_increase"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Chill translated into ManaLoom runtime scope xmage_static_generic_cost_increase_for_matching_spells_v1. This row is package-ready only because the source signature is a narrow permanent static generic cost increase for matching spells with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('feroz''s ban', 'Feroz''s Ban', '13de41ee21897c15ba9c50254076dacd', 'battle_rule_v1:36c30b4595a5fd9bc7cad0939cc673ae', '{"ability_kind":"static","applies_to_card_types":["creature"],"battle_model_scope":"xmage_static_generic_cost_increase_for_matching_spells_v1","cost_increase_amount_source":"fixed","cost_increase_applies_to":"spells_each_player_cast","cost_increase_filters":[{"applies_to_card_types":["creature"]}],"cost_increase_generic":2,"effect":"static_cost_increase","instant":false,"permanent_type":"artifact","sorcery":false,"static_effect":"generic_cost_increase_for_matching_spells","xmage_ability_class":"SimpleStaticAbility","xmage_effect_class":"SpellsCostIncreasingAllEffect"}'::jsonb, '{"category":"unknown","effect":"static_cost_increase"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class FerozsBan translated into ManaLoom runtime scope xmage_static_generic_cost_increase_for_matching_spells_v1. This row is package-ready only because the source signature is a narrow permanent static generic cost increase for matching spells with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('geist-fueled scarecrow', 'Geist-Fueled Scarecrow', '8da7a7b4754f33c1803f4628748c2ee8', 'battle_rule_v1:bc0652215e0eb2196080ba602c733d06', '{"ability_kind":"static","applies_to_card_types":["creature"],"battle_model_scope":"xmage_static_generic_cost_increase_for_matching_spells_v1","cost_increase_amount_source":"fixed","cost_increase_applies_to":"spells_you_cast","cost_increase_filters":[{"applies_to_card_types":["creature"]}],"cost_increase_generic":1,"effect":"static_cost_increase","instant":false,"permanent_type":"creature","sorcery":false,"static_effect":"generic_cost_increase_for_matching_spells","xmage_ability_class":"SimpleStaticAbility","xmage_effect_class":"SpellsCostIncreasingAllEffect"}'::jsonb, '{"category":"unknown","effect":"static_cost_increase"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class GeistFueledScarecrow translated into ManaLoom runtime scope xmage_static_generic_cost_increase_for_matching_spells_v1. This row is package-ready only because the source signature is a narrow permanent static generic cost increase for matching spells with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('glowrider', 'Glowrider', '63532c8ee6deff218245c18a4e0232b9', 'battle_rule_v1:6d39ef37e00c1bfdf2999fe446aa7af2', '{"ability_kind":"static","battle_model_scope":"xmage_static_generic_cost_increase_for_matching_spells_v1","cost_increase_amount_source":"fixed","cost_increase_applies_to":"spells_each_player_cast","cost_increase_filters":[{"excluded_card_types":["creature"]}],"cost_increase_generic":1,"effect":"static_cost_increase","excluded_card_types":["creature"],"instant":false,"permanent_type":"creature","sorcery":false,"static_effect":"generic_cost_increase_for_matching_spells","xmage_ability_class":"SimpleStaticAbility","xmage_effect_class":"SpellsCostIncreasingAllEffect"}'::jsonb, '{"category":"unknown","effect":"static_cost_increase"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Glowrider translated into ManaLoom runtime scope xmage_static_generic_cost_increase_for_matching_spells_v1. This row is package-ready only because the source signature is a narrow permanent static generic cost increase for matching spells with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('high seas', 'High Seas', 'f1f40237cb6e55ff37a1554f94a9c69a', 'battle_rule_v1:568910bfb93935223202729c0d2df2bf', '{"ability_kind":"static","applies_to_card_types":["creature"],"applies_to_spell_colors":["R","G"],"battle_model_scope":"xmage_static_generic_cost_increase_for_matching_spells_v1","cost_increase_amount_source":"fixed","cost_increase_applies_to":"spells_each_player_cast","cost_increase_filters":[{"applies_to_card_types":["creature"],"applies_to_spell_colors":["R","G"]}],"cost_increase_generic":1,"effect":"static_cost_increase","instant":false,"permanent_type":"enchantment","sorcery":false,"static_effect":"generic_cost_increase_for_matching_spells","xmage_ability_class":"SimpleStaticAbility","xmage_effect_class":"SpellsCostIncreasingAllEffect"}'::jsonb, '{"category":"unknown","effect":"static_cost_increase"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class HighSeas translated into ManaLoom runtime scope xmage_static_generic_cost_increase_for_matching_spells_v1. This row is package-ready only because the source signature is a narrow permanent static generic cost increase for matching spells with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('irini sengir', 'Irini Sengir', '48331728eaaa585e546b3596488a0b67', 'battle_rule_v1:fa436e282020bbd4790d9ed1d32b2d8e', '{"ability_kind":"static","applies_to_card_types":["enchantment"],"applies_to_spell_colors":["W","G"],"battle_model_scope":"xmage_static_generic_cost_increase_for_matching_spells_v1","cost_increase_amount_source":"fixed","cost_increase_applies_to":"spells_each_player_cast","cost_increase_filters":[{"applies_to_card_types":["enchantment"],"applies_to_spell_colors":["W","G"]}],"cost_increase_generic":2,"effect":"static_cost_increase","instant":false,"permanent_type":"creature","sorcery":false,"static_effect":"generic_cost_increase_for_matching_spells","xmage_ability_class":"SimpleStaticAbility","xmage_effect_class":"SpellsCostIncreasingAllEffect"}'::jsonb, '{"category":"unknown","effect":"static_cost_increase"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class IriniSengir translated into ManaLoom runtime scope xmage_static_generic_cost_increase_for_matching_spells_v1. This row is package-ready only because the source signature is a narrow permanent static generic cost increase for matching spells with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('lodestone golem', 'Lodestone Golem', '10cfd50f769f63c64f5f61b74b425bf8', 'battle_rule_v1:f368a79346c5a6bd7107f0fa321560de', '{"ability_kind":"static","battle_model_scope":"xmage_static_generic_cost_increase_for_matching_spells_v1","cost_increase_amount_source":"fixed","cost_increase_applies_to":"spells_each_player_cast","cost_increase_filters":[{"excluded_card_types":["artifact"]}],"cost_increase_generic":1,"effect":"static_cost_increase","excluded_card_types":["artifact"],"instant":false,"permanent_type":"creature","sorcery":false,"static_effect":"generic_cost_increase_for_matching_spells","xmage_ability_class":"SimpleStaticAbility","xmage_effect_class":"SpellsCostIncreasingAllEffect"}'::jsonb, '{"category":"unknown","effect":"static_cost_increase"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class LodestoneGolem translated into ManaLoom runtime scope xmage_static_generic_cost_increase_for_matching_spells_v1. This row is package-ready only because the source signature is a narrow permanent static generic cost increase for matching spells with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('sphere of resistance', 'Sphere of Resistance', 'dc1787214f6dbc6529c1ebc4be32470b', 'battle_rule_v1:07d2256999fcb290d88cdeb0a37df913', '{"ability_kind":"static","battle_model_scope":"xmage_static_generic_cost_increase_for_matching_spells_v1","cost_increase_amount_source":"fixed","cost_increase_applies_to":"spells_each_player_cast","cost_increase_filters":[{}],"cost_increase_generic":1,"effect":"static_cost_increase","instant":false,"permanent_type":"artifact","sorcery":false,"static_effect":"generic_cost_increase_for_matching_spells","xmage_ability_class":"SimpleStaticAbility","xmage_effect_class":"SpellsCostIncreasingAllEffect"}'::jsonb, '{"category":"unknown","effect":"static_cost_increase"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class SphereOfResistance translated into ManaLoom runtime scope xmage_static_generic_cost_increase_for_matching_spells_v1. This row is package-ready only because the source signature is a narrow permanent static generic cost increase for matching spells with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('squeeze', 'Squeeze', 'acdb79860c5ae969d42f017f2f4888d1', 'battle_rule_v1:45a67d690ccb5a603257c768c9e1fc14', '{"ability_kind":"static","applies_to_card_types":["sorcery"],"battle_model_scope":"xmage_static_generic_cost_increase_for_matching_spells_v1","cost_increase_amount_source":"fixed","cost_increase_applies_to":"spells_each_player_cast","cost_increase_filters":[{"applies_to_card_types":["sorcery"]}],"cost_increase_generic":3,"effect":"static_cost_increase","instant":false,"permanent_type":"enchantment","sorcery":false,"static_effect":"generic_cost_increase_for_matching_spells","xmage_ability_class":"SimpleStaticAbility","xmage_effect_class":"SpellsCostIncreasingAllEffect"}'::jsonb, '{"category":"unknown","effect":"static_cost_increase"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Squeeze translated into ManaLoom runtime scope xmage_static_generic_cost_increase_for_matching_spells_v1. This row is package-ready only because the source signature is a narrow permanent static generic cost increase for matching spells with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('thorn of amethyst', 'Thorn of Amethyst', '63532c8ee6deff218245c18a4e0232b9', 'battle_rule_v1:7c7242062532b63919b249f9056eebc4', '{"ability_kind":"static","battle_model_scope":"xmage_static_generic_cost_increase_for_matching_spells_v1","cost_increase_amount_source":"fixed","cost_increase_applies_to":"spells_each_player_cast","cost_increase_filters":[{"excluded_card_types":["creature"]}],"cost_increase_generic":1,"effect":"static_cost_increase","excluded_card_types":["creature"],"instant":false,"permanent_type":"artifact","sorcery":false,"static_effect":"generic_cost_increase_for_matching_spells","xmage_ability_class":"SimpleStaticAbility","xmage_effect_class":"SpellsCostIncreasingAllEffect"}'::jsonb, '{"category":"unknown","effect":"static_cost_increase"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ThornOfAmethyst translated into ManaLoom runtime scope xmage_static_generic_cost_increase_for_matching_spells_v1. This row is package-ready only because the source signature is a narrow permanent static generic cost increase for matching spells with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('vryn wingmare', 'Vryn Wingmare', '4c2bb06ecbd7257be31483056c7502ef', 'battle_rule_v1:4353887075328c833b63293e78b34d32', '{"_keywords_are_self":true,"ability_kind":"static","battle_model_scope":"xmage_static_generic_cost_increase_for_matching_spells_v1","cost_increase_amount_source":"fixed","cost_increase_applies_to":"spells_each_player_cast","cost_increase_filters":[{"excluded_card_types":["creature"]}],"cost_increase_generic":1,"effect":"static_cost_increase","excluded_card_types":["creature"],"flying":true,"instant":false,"keywords":["flying"],"permanent_type":"creature","sorcery":false,"static_effect":"generic_cost_increase_for_matching_spells","xmage_ability_class":"SimpleStaticAbility","xmage_effect_class":"SpellsCostIncreasingAllEffect"}'::jsonb, '{"category":"unknown","effect":"static_cost_increase"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class VrynWingmare translated into ManaLoom runtime scope xmage_static_generic_cost_increase_for_matching_spells_v1. This row is package-ready only because the source signature is a narrow permanent static generic cost increase for matching spells with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
