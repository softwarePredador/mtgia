WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('advance scout', 'Advance Scout', '148a03732a37709ae78d4bac0c347a8f', 'battle_rule_v1:b8cc41f870a0cf26097717df50bf66e9', '{"_activated_rule_effects":[{"ability_kind":"activated","activated_effect":"target_keyword_until_eot","activation_cost_colors":["W"],"activation_cost_generic":0,"activation_cost_mana":"{W}","activation_requires_sacrifice":false,"activation_requires_tap":false,"battle_model_scope":"xmage_permanent_simple_activated_target_keyword_until_eot_v1","duration":"until_end_of_turn","effect":"stat_modifier_until_eot","granted_keywords_until_eot":["first_strike"],"power_delta":0,"target":"creature","target_constraints":{"card_types":["creature"]},"target_controller":"any","toughness_delta":0,"xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"GainAbilityTargetEffect","xmage_keyword_ability_class":"FirstStrikeAbility"}],"_keywords_are_self":true,"ability_kind":"static_and_activated","activated_battle_model_scope":"xmage_permanent_simple_activated_target_keyword_until_eot_v1","activated_effect":"target_keyword_until_eot","activation_cost_colors":["W"],"activation_cost_generic":0,"activation_cost_mana":"{W}","activation_requires_sacrifice":false,"activation_requires_tap":false,"battle_model_scope":"xmage_permanent_simple_activated_target_keyword_until_eot_v1","duration":"until_end_of_turn","effect":"creature","first_strike":true,"granted_keywords_until_eot":["first_strike"],"keywords":["first_strike"],"power_delta":0,"target":"creature","target_constraints":{"card_types":["creature"]},"target_controller":"any","toughness_delta":0,"xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"GainAbilityTargetEffect","xmage_keyword_ability_class":"FirstStrikeAbility"}'::jsonb, '{"category":"unknown","effect":"creature","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class AdvanceScout translated into ManaLoom runtime scope xmage_permanent_simple_activated_target_keyword_until_eot_v1. This row is package-ready only because the source signature is a narrow permanent simple activated target-creature keyword until end of turn with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('harmattan efreet', 'Harmattan Efreet', '80310c614004ebd42c3f1a3cddbfeb0b', 'battle_rule_v1:2cf7e89007b76b45977da2016ce49b04', '{"_activated_rule_effects":[{"ability_kind":"activated","activated_effect":"target_keyword_until_eot","activation_cost_colors":["U","U"],"activation_cost_generic":1,"activation_cost_mana":"{1}{U}{U}","activation_requires_sacrifice":false,"activation_requires_tap":false,"battle_model_scope":"xmage_permanent_simple_activated_target_keyword_until_eot_v1","duration":"until_end_of_turn","effect":"stat_modifier_until_eot","granted_keywords_until_eot":["flying"],"power_delta":0,"target":"creature","target_constraints":{"card_types":["creature"]},"target_controller":"any","toughness_delta":0,"xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"GainAbilityTargetEffect","xmage_keyword_ability_class":"FlyingAbility"}],"_keywords_are_self":true,"ability_kind":"static_and_activated","activated_battle_model_scope":"xmage_permanent_simple_activated_target_keyword_until_eot_v1","activated_effect":"target_keyword_until_eot","activation_cost_colors":["U","U"],"activation_cost_generic":1,"activation_cost_mana":"{1}{U}{U}","activation_requires_sacrifice":false,"activation_requires_tap":false,"battle_model_scope":"xmage_permanent_simple_activated_target_keyword_until_eot_v1","duration":"until_end_of_turn","effect":"creature","flying":true,"granted_keywords_until_eot":["flying"],"keywords":["flying"],"power_delta":0,"target":"creature","target_constraints":{"card_types":["creature"]},"target_controller":"any","toughness_delta":0,"xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"GainAbilityTargetEffect","xmage_keyword_ability_class":"FlyingAbility"}'::jsonb, '{"category":"unknown","effect":"creature","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class HarmattanEfreet translated into ManaLoom runtime scope xmage_permanent_simple_activated_target_keyword_until_eot_v1. This row is package-ready only because the source signature is a narrow permanent simple activated target-creature keyword until end of turn with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('pixie queen', 'Pixie Queen', 'd81188656267840c4a9d890bf8f1b62c', 'battle_rule_v1:92da53168ad3c7175c351d4bf984fa6c', '{"_activated_rule_effects":[{"ability_kind":"activated","activated_effect":"target_keyword_until_eot","activation_cost_colors":["G","G","G"],"activation_cost_generic":0,"activation_cost_mana":"{G}{G}{G}","activation_requires_sacrifice":false,"activation_requires_tap":true,"battle_model_scope":"xmage_permanent_simple_activated_target_keyword_until_eot_v1","duration":"until_end_of_turn","effect":"stat_modifier_until_eot","granted_keywords_until_eot":["flying"],"power_delta":0,"target":"creature","target_constraints":{"card_types":["creature"]},"target_controller":"any","toughness_delta":0,"xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"GainAbilityTargetEffect","xmage_keyword_ability_class":"FlyingAbility"}],"_keywords_are_self":true,"ability_kind":"static_and_activated","activated_battle_model_scope":"xmage_permanent_simple_activated_target_keyword_until_eot_v1","activated_effect":"target_keyword_until_eot","activation_cost_colors":["G","G","G"],"activation_cost_generic":0,"activation_cost_mana":"{G}{G}{G}","activation_requires_sacrifice":false,"activation_requires_tap":true,"battle_model_scope":"xmage_permanent_simple_activated_target_keyword_until_eot_v1","duration":"until_end_of_turn","effect":"creature","flying":true,"granted_keywords_until_eot":["flying"],"keywords":["flying"],"power_delta":0,"target":"creature","target_constraints":{"card_types":["creature"]},"target_controller":"any","toughness_delta":0,"xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"GainAbilityTargetEffect","xmage_keyword_ability_class":"FlyingAbility"}'::jsonb, '{"category":"unknown","effect":"creature","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class PixieQueen translated into ManaLoom runtime scope xmage_permanent_simple_activated_target_keyword_until_eot_v1. This row is package-ready only because the source signature is a narrow permanent simple activated target-creature keyword until end of turn with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('pseudodragon familiar', 'Pseudodragon Familiar', 'd5632d2c7d70261dfa6b0f1f6c5261c8', 'battle_rule_v1:bef17c67f4b265b08dc05b8a8f21e99f', '{"_activated_rule_effects":[{"ability_kind":"activated","activated_effect":"target_keyword_until_eot","activation_cost_colors":["U"],"activation_cost_generic":2,"activation_cost_mana":"{2}{U}","activation_requires_sacrifice":false,"activation_requires_tap":false,"battle_model_scope":"xmage_permanent_simple_activated_target_keyword_until_eot_v1","duration":"until_end_of_turn","effect":"stat_modifier_until_eot","granted_keywords_until_eot":["flying"],"power_delta":0,"target":"creature","target_constraints":{"card_types":["creature"]},"target_controller":"any","toughness_delta":0,"xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"GainAbilityTargetEffect","xmage_keyword_ability_class":"FlyingAbility"}],"_keywords_are_self":true,"ability_kind":"static_and_activated","activated_battle_model_scope":"xmage_permanent_simple_activated_target_keyword_until_eot_v1","activated_effect":"target_keyword_until_eot","activation_cost_colors":["U"],"activation_cost_generic":2,"activation_cost_mana":"{2}{U}","activation_requires_sacrifice":false,"activation_requires_tap":false,"battle_model_scope":"xmage_permanent_simple_activated_target_keyword_until_eot_v1","duration":"until_end_of_turn","effect":"creature","flying":true,"granted_keywords_until_eot":["flying"],"keywords":["flying"],"power_delta":0,"target":"creature","target_constraints":{"card_types":["creature"]},"target_controller":"any","toughness_delta":0,"xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"GainAbilityTargetEffect","xmage_keyword_ability_class":"FlyingAbility"}'::jsonb, '{"category":"unknown","effect":"creature","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class PseudodragonFamiliar translated into ManaLoom runtime scope xmage_permanent_simple_activated_target_keyword_until_eot_v1. This row is package-ready only because the source signature is a narrow permanent simple activated target-creature keyword until end of turn with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('wind dancer', 'Wind Dancer', 'f50ae434e6eddebfe53279e641bdaecc', 'battle_rule_v1:80758af47186a7fb0aba91d2480de042', '{"_activated_rule_effects":[{"ability_kind":"activated","activated_effect":"target_keyword_until_eot","activation_cost_colors":[],"activation_cost_generic":0,"activation_cost_mana":"{0}","activation_requires_sacrifice":false,"activation_requires_tap":true,"battle_model_scope":"xmage_permanent_simple_activated_target_keyword_until_eot_v1","duration":"until_end_of_turn","effect":"stat_modifier_until_eot","granted_keywords_until_eot":["flying"],"power_delta":0,"target":"creature","target_constraints":{"card_types":["creature"]},"target_controller":"any","toughness_delta":0,"xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"GainAbilityTargetEffect","xmage_keyword_ability_class":"FlyingAbility"}],"_keywords_are_self":true,"ability_kind":"static_and_activated","activated_battle_model_scope":"xmage_permanent_simple_activated_target_keyword_until_eot_v1","activated_effect":"target_keyword_until_eot","activation_cost_colors":[],"activation_cost_generic":0,"activation_cost_mana":"{0}","activation_requires_sacrifice":false,"activation_requires_tap":true,"battle_model_scope":"xmage_permanent_simple_activated_target_keyword_until_eot_v1","duration":"until_end_of_turn","effect":"creature","flying":true,"granted_keywords_until_eot":["flying"],"keywords":["flying"],"power_delta":0,"target":"creature","target_constraints":{"card_types":["creature"]},"target_controller":"any","toughness_delta":0,"xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"GainAbilityTargetEffect","xmage_keyword_ability_class":"FlyingAbility"}'::jsonb, '{"category":"unknown","effect":"creature","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class WindDancer translated into ManaLoom runtime scope xmage_permanent_simple_activated_target_keyword_until_eot_v1. This row is package-ready only because the source signature is a narrow permanent simple activated target-creature keyword until end of turn with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
