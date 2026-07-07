WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('need for speed', 'Need for Speed', '21118790c7f783fc315a70093f1f9211', 'battle_rule_v1:8d3778bc24beaf21b2df8efdd6a7ae12', '{"_activated_rule_effects":[{"ability_kind":"activated","activated_effect":"target_keyword_until_eot","activation_cost_colors":[],"activation_cost_generic":0,"activation_cost_mana":"{0}","activation_requires_sacrifice":false,"activation_requires_sacrifice_target":true,"activation_requires_tap":false,"activation_sacrifice_target":"land","battle_model_scope":"xmage_permanent_simple_activated_target_keyword_until_eot_v1","duration":"until_end_of_turn","effect":"stat_modifier_until_eot","granted_keywords_until_eot":["haste"],"power_delta":0,"target":"creature","target_constraints":{"card_types":["creature"]},"target_controller":"any","toughness_delta":0,"xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"GainAbilityTargetEffect","xmage_keyword_ability_class":"HasteAbility"}],"ability_kind":"static_and_activated","activated_battle_model_scope":"xmage_permanent_simple_activated_target_keyword_until_eot_v1","activated_effect":"target_keyword_until_eot","activation_cost_colors":[],"activation_cost_generic":0,"activation_cost_mana":"{0}","activation_requires_sacrifice":false,"activation_requires_sacrifice_target":true,"activation_requires_tap":false,"activation_sacrifice_target":"land","battle_model_scope":"xmage_permanent_simple_activated_target_keyword_until_eot_v1","duration":"until_end_of_turn","effect":"enchantment","granted_keywords_until_eot":["haste"],"power_delta":0,"target":"creature","target_constraints":{"card_types":["creature"]},"target_controller":"any","toughness_delta":0,"xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"GainAbilityTargetEffect","xmage_keyword_ability_class":"HasteAbility"}'::jsonb, '{"category":"unknown","effect":"enchantment","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class NeedForSpeed translated into ManaLoom runtime scope xmage_permanent_simple_activated_target_keyword_until_eot_v1. This row is package-ready only because the source signature is a narrow permanent simple activated target-creature keyword until end of turn with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('selfless savior', 'Selfless Savior', '791dcd14252bbbcc229c9b551c2ffc55', 'battle_rule_v1:0ba5a40f8461aca65c44184ea3c6e6b9', '{"_activated_rule_effects":[{"ability_kind":"activated","activated_effect":"target_keyword_until_eot","activation_cost_colors":[],"activation_cost_generic":0,"activation_cost_mana":"{0}","activation_requires_sacrifice":true,"activation_requires_tap":false,"battle_model_scope":"xmage_permanent_simple_activated_target_keyword_until_eot_v1","duration":"until_end_of_turn","effect":"stat_modifier_until_eot","granted_keywords_until_eot":["indestructible"],"power_delta":0,"target":"creature","target_constraints":{"card_types":["creature"],"exclude_source":true},"target_controller":"self","toughness_delta":0,"xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"GainAbilityTargetEffect","xmage_keyword_ability_class":"IndestructibleAbility"}],"ability_kind":"static_and_activated","activated_battle_model_scope":"xmage_permanent_simple_activated_target_keyword_until_eot_v1","activated_effect":"target_keyword_until_eot","activation_cost_colors":[],"activation_cost_generic":0,"activation_cost_mana":"{0}","activation_requires_sacrifice":true,"activation_requires_tap":false,"battle_model_scope":"xmage_permanent_simple_activated_target_keyword_until_eot_v1","duration":"until_end_of_turn","effect":"creature","granted_keywords_until_eot":["indestructible"],"power_delta":0,"target":"creature","target_constraints":{"card_types":["creature"],"exclude_source":true},"target_controller":"self","toughness_delta":0,"xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"GainAbilityTargetEffect","xmage_keyword_ability_class":"IndestructibleAbility"}'::jsonb, '{"category":"unknown","effect":"creature","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class SelflessSavior translated into ManaLoom runtime scope xmage_permanent_simple_activated_target_keyword_until_eot_v1. This row is package-ready only because the source signature is a narrow permanent simple activated target-creature keyword until end of turn with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('slobad, goblin tinkerer', 'Slobad, Goblin Tinkerer', 'a4aaf5f6c815fac2ba5a20bca4f9f859', 'battle_rule_v1:972bbc1b17f2eeb41d47b665441c2d34', '{"_activated_rule_effects":[{"ability_kind":"activated","activated_effect":"target_keyword_until_eot","activation_cost_colors":[],"activation_cost_generic":0,"activation_cost_mana":"{0}","activation_requires_sacrifice":false,"activation_requires_sacrifice_target":true,"activation_requires_tap":false,"activation_sacrifice_target":"artifact","battle_model_scope":"xmage_permanent_simple_activated_target_keyword_until_eot_v1","duration":"until_end_of_turn","effect":"stat_modifier_until_eot","granted_keywords_until_eot":["indestructible"],"power_delta":0,"target":"artifact","target_constraints":{"card_types":["artifact"]},"target_controller":"any","toughness_delta":0,"xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"GainAbilityTargetEffect","xmage_keyword_ability_class":"IndestructibleAbility"}],"ability_kind":"static_and_activated","activated_battle_model_scope":"xmage_permanent_simple_activated_target_keyword_until_eot_v1","activated_effect":"target_keyword_until_eot","activation_cost_colors":[],"activation_cost_generic":0,"activation_cost_mana":"{0}","activation_requires_sacrifice":false,"activation_requires_sacrifice_target":true,"activation_requires_tap":false,"activation_sacrifice_target":"artifact","battle_model_scope":"xmage_permanent_simple_activated_target_keyword_until_eot_v1","duration":"until_end_of_turn","effect":"creature","granted_keywords_until_eot":["indestructible"],"power_delta":0,"target":"artifact","target_constraints":{"card_types":["artifact"]},"target_controller":"any","toughness_delta":0,"xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"GainAbilityTargetEffect","xmage_keyword_ability_class":"IndestructibleAbility"}'::jsonb, '{"category":"unknown","effect":"creature","target":"artifact"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class SlobadGoblinTinkerer translated into ManaLoom runtime scope xmage_permanent_simple_activated_target_keyword_until_eot_v1. This row is package-ready only because the source signature is a narrow permanent simple activated target-creature keyword until end of turn with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('torch courier', 'Torch Courier', 'c55fbd0145c74143cacc79f7d230ae86', 'battle_rule_v1:e0e5aba2caf68cd499de1a6984bb9c0e', '{"_activated_rule_effects":[{"ability_kind":"activated","activated_effect":"target_keyword_until_eot","activation_cost_colors":[],"activation_cost_generic":0,"activation_cost_mana":"{0}","activation_requires_sacrifice":true,"activation_requires_tap":false,"battle_model_scope":"xmage_permanent_simple_activated_target_keyword_until_eot_v1","duration":"until_end_of_turn","effect":"stat_modifier_until_eot","granted_keywords_until_eot":["haste"],"power_delta":0,"target":"creature","target_constraints":{"card_types":["creature"],"exclude_source":true},"target_controller":"any","toughness_delta":0,"xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"GainAbilityTargetEffect","xmage_keyword_ability_class":"HasteAbility"}],"_keywords_are_self":true,"ability_kind":"static_and_activated","activated_battle_model_scope":"xmage_permanent_simple_activated_target_keyword_until_eot_v1","activated_effect":"target_keyword_until_eot","activation_cost_colors":[],"activation_cost_generic":0,"activation_cost_mana":"{0}","activation_requires_sacrifice":true,"activation_requires_tap":false,"battle_model_scope":"xmage_permanent_simple_activated_target_keyword_until_eot_v1","duration":"until_end_of_turn","effect":"creature","granted_keywords_until_eot":["haste"],"haste":true,"keywords":["haste"],"power_delta":0,"target":"creature","target_constraints":{"card_types":["creature"],"exclude_source":true},"target_controller":"any","toughness_delta":0,"xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"GainAbilityTargetEffect","xmage_keyword_ability_class":"HasteAbility"}'::jsonb, '{"category":"unknown","effect":"creature","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class TorchCourier translated into ManaLoom runtime scope xmage_permanent_simple_activated_target_keyword_until_eot_v1. This row is package-ready only because the source signature is a narrow permanent simple activated target-creature keyword until end of turn with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('vial of poison', 'Vial of Poison', 'b54a117f2490816b8e3756470053af11', 'battle_rule_v1:ed2515b77291a88a4aa6e423cdc63305', '{"_activated_rule_effects":[{"ability_kind":"activated","activated_effect":"target_keyword_until_eot","activation_cost_colors":[],"activation_cost_generic":1,"activation_cost_mana":"{1}","activation_requires_sacrifice":true,"activation_requires_tap":false,"battle_model_scope":"xmage_permanent_simple_activated_target_keyword_until_eot_v1","duration":"until_end_of_turn","effect":"stat_modifier_until_eot","granted_keywords_until_eot":["deathtouch"],"power_delta":0,"target":"creature","target_constraints":{"card_types":["creature"]},"target_controller":"any","toughness_delta":0,"xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"GainAbilityTargetEffect","xmage_keyword_ability_class":"DeathtouchAbility"}],"ability_kind":"static_and_activated","activated_battle_model_scope":"xmage_permanent_simple_activated_target_keyword_until_eot_v1","activated_effect":"target_keyword_until_eot","activation_cost_colors":[],"activation_cost_generic":1,"activation_cost_mana":"{1}","activation_requires_sacrifice":true,"activation_requires_tap":false,"battle_model_scope":"xmage_permanent_simple_activated_target_keyword_until_eot_v1","duration":"until_end_of_turn","effect":"artifact","granted_keywords_until_eot":["deathtouch"],"power_delta":0,"target":"creature","target_constraints":{"card_types":["creature"]},"target_controller":"any","toughness_delta":0,"xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"GainAbilityTargetEffect","xmage_keyword_ability_class":"DeathtouchAbility"}'::jsonb, '{"category":"unknown","effect":"artifact","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class VialOfPoison translated into ManaLoom runtime scope xmage_permanent_simple_activated_target_keyword_until_eot_v1. This row is package-ready only because the source signature is a narrow permanent simple activated target-creature keyword until end of turn with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
