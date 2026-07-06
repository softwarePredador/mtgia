WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('fledgling imp', 'Fledgling Imp', '52923bdf36f4fb6eabffbecf6ddf4b66', 'battle_rule_v1:daa15499def4831e63caae638eaf067a', '{"_activated_rule_effects":[{"ability_kind":"activated","activated_effect":"self_keyword_until_eot","activation_cost_colors":["B"],"activation_cost_generic":0,"activation_cost_mana":"{B}","activation_discard_count":1,"activation_discard_target":"any_card","activation_requires_discard_card":true,"activation_requires_sacrifice":false,"activation_requires_tap":false,"battle_model_scope":"xmage_permanent_simple_activated_self_keyword_until_eot_v1","duration":"until_end_of_turn","effect":"stat_modifier_until_eot","granted_keywords_until_eot":["flying"],"power_delta":0,"target":"self","target_constraints":{"card_types":["creature"],"source":"self"},"target_controller":"self","toughness_delta":0,"xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"GainAbilitySourceEffect","xmage_keyword_ability_class":"FlyingAbility"}],"ability_kind":"static_and_activated","activated_battle_model_scope":"xmage_permanent_simple_activated_self_keyword_until_eot_v1","activated_effect":"self_keyword_until_eot","activation_cost_colors":["B"],"activation_cost_generic":0,"activation_cost_mana":"{B}","activation_discard_count":1,"activation_discard_target":"any_card","activation_requires_discard_card":true,"activation_requires_sacrifice":false,"activation_requires_tap":false,"battle_model_scope":"xmage_permanent_simple_activated_self_keyword_until_eot_v1","duration":"until_end_of_turn","effect":"creature","granted_keywords_until_eot":["flying"],"power_delta":0,"target":"self","target_constraints":{"card_types":["creature"],"source":"self"},"target_controller":"self","toughness_delta":0,"xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"GainAbilitySourceEffect","xmage_keyword_ability_class":"FlyingAbility"}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class FledglingImp translated into ManaLoom runtime scope xmage_permanent_simple_activated_self_keyword_until_eot_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('insatiable souleater', 'Insatiable Souleater', 'b4305043e3a76f4cb960c54a6d8eef33', 'battle_rule_v1:b4a7c68f795f60e117ee654782b79d57', '{"_activated_rule_effects":[{"ability_kind":"activated","activated_effect":"self_keyword_until_eot","activation_cost_colors":["G/P"],"activation_cost_generic":0,"activation_cost_mana":"{G/P}","activation_requires_sacrifice":false,"activation_requires_tap":false,"battle_model_scope":"xmage_permanent_simple_activated_self_keyword_until_eot_v1","duration":"until_end_of_turn","effect":"stat_modifier_until_eot","granted_keywords_until_eot":["trample"],"power_delta":0,"target":"self","target_constraints":{"card_types":["creature"],"source":"self"},"target_controller":"self","toughness_delta":0,"xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"GainAbilitySourceEffect","xmage_keyword_ability_class":"TrampleAbility"}],"ability_kind":"static_and_activated","activated_battle_model_scope":"xmage_permanent_simple_activated_self_keyword_until_eot_v1","activated_effect":"self_keyword_until_eot","activation_cost_colors":["G/P"],"activation_cost_generic":0,"activation_cost_mana":"{G/P}","activation_requires_sacrifice":false,"activation_requires_tap":false,"battle_model_scope":"xmage_permanent_simple_activated_self_keyword_until_eot_v1","duration":"until_end_of_turn","effect":"creature","granted_keywords_until_eot":["trample"],"power_delta":0,"target":"self","target_constraints":{"card_types":["creature"],"source":"self"},"target_controller":"self","toughness_delta":0,"xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"GainAbilitySourceEffect","xmage_keyword_ability_class":"TrampleAbility"}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class InsatiableSouleater translated into ManaLoom runtime scope xmage_permanent_simple_activated_self_keyword_until_eot_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('olivia''s dragoon', 'Olivia''s Dragoon', '5da6a0ad3acfad925957bfe679f2ecd9', 'battle_rule_v1:164923f1580f3b634945a67e46500b02', '{"_activated_rule_effects":[{"ability_kind":"activated","activated_effect":"self_keyword_until_eot","activation_cost_colors":[],"activation_cost_generic":0,"activation_cost_mana":"{0}","activation_discard_count":1,"activation_discard_target":"any_card","activation_requires_discard_card":true,"activation_requires_sacrifice":false,"activation_requires_tap":false,"battle_model_scope":"xmage_permanent_simple_activated_self_keyword_until_eot_v1","duration":"until_end_of_turn","effect":"stat_modifier_until_eot","granted_keywords_until_eot":["flying"],"power_delta":0,"target":"self","target_constraints":{"card_types":["creature"],"source":"self"},"target_controller":"self","toughness_delta":0,"xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"GainAbilitySourceEffect","xmage_keyword_ability_class":"FlyingAbility"}],"ability_kind":"static_and_activated","activated_battle_model_scope":"xmage_permanent_simple_activated_self_keyword_until_eot_v1","activated_effect":"self_keyword_until_eot","activation_cost_colors":[],"activation_cost_generic":0,"activation_cost_mana":"{0}","activation_discard_count":1,"activation_discard_target":"any_card","activation_requires_discard_card":true,"activation_requires_sacrifice":false,"activation_requires_tap":false,"battle_model_scope":"xmage_permanent_simple_activated_self_keyword_until_eot_v1","duration":"until_end_of_turn","effect":"creature","granted_keywords_until_eot":["flying"],"power_delta":0,"target":"self","target_constraints":{"card_types":["creature"],"source":"self"},"target_controller":"self","toughness_delta":0,"xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"GainAbilitySourceEffect","xmage_keyword_ability_class":"FlyingAbility"}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class OliviasDragoon translated into ManaLoom runtime scope xmage_permanent_simple_activated_self_keyword_until_eot_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('patrol hound', 'Patrol Hound', 'a467b144152ba539299c6d7dd3223a98', 'battle_rule_v1:892ac00e937d0158f852010008300506', '{"_activated_rule_effects":[{"ability_kind":"activated","activated_effect":"self_keyword_until_eot","activation_cost_colors":[],"activation_cost_generic":0,"activation_cost_mana":"{0}","activation_discard_count":1,"activation_discard_target":"any_card","activation_requires_discard_card":true,"activation_requires_sacrifice":false,"activation_requires_tap":false,"battle_model_scope":"xmage_permanent_simple_activated_self_keyword_until_eot_v1","duration":"until_end_of_turn","effect":"stat_modifier_until_eot","granted_keywords_until_eot":["first_strike"],"power_delta":0,"target":"self","target_constraints":{"card_types":["creature"],"source":"self"},"target_controller":"self","toughness_delta":0,"xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"GainAbilitySourceEffect","xmage_keyword_ability_class":"FirstStrikeAbility"}],"ability_kind":"static_and_activated","activated_battle_model_scope":"xmage_permanent_simple_activated_self_keyword_until_eot_v1","activated_effect":"self_keyword_until_eot","activation_cost_colors":[],"activation_cost_generic":0,"activation_cost_mana":"{0}","activation_discard_count":1,"activation_discard_target":"any_card","activation_requires_discard_card":true,"activation_requires_sacrifice":false,"activation_requires_tap":false,"battle_model_scope":"xmage_permanent_simple_activated_self_keyword_until_eot_v1","duration":"until_end_of_turn","effect":"creature","granted_keywords_until_eot":["first_strike"],"power_delta":0,"target":"self","target_constraints":{"card_types":["creature"],"source":"self"},"target_controller":"self","toughness_delta":0,"xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"GainAbilitySourceEffect","xmage_keyword_ability_class":"FirstStrikeAbility"}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class PatrolHound translated into ManaLoom runtime scope xmage_permanent_simple_activated_self_keyword_until_eot_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('shadowcloak vampire', 'Shadowcloak Vampire', '8856f3575f27df6ef4122fae6d4fe680', 'battle_rule_v1:5146b23b2bc449f8552c513145fd83a8', '{"_activated_rule_effects":[{"ability_kind":"activated","activated_effect":"self_keyword_until_eot","activation_cost_colors":[],"activation_cost_generic":0,"activation_cost_mana":"{0}","activation_life_cost":2,"activation_requires_sacrifice":false,"activation_requires_tap":false,"battle_model_scope":"xmage_permanent_simple_activated_self_keyword_until_eot_v1","duration":"until_end_of_turn","effect":"stat_modifier_until_eot","granted_keywords_until_eot":["flying"],"power_delta":0,"target":"self","target_constraints":{"card_types":["creature"],"source":"self"},"target_controller":"self","toughness_delta":0,"xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"GainAbilitySourceEffect","xmage_keyword_ability_class":"FlyingAbility"}],"ability_kind":"static_and_activated","activated_battle_model_scope":"xmage_permanent_simple_activated_self_keyword_until_eot_v1","activated_effect":"self_keyword_until_eot","activation_cost_colors":[],"activation_cost_generic":0,"activation_cost_mana":"{0}","activation_life_cost":2,"activation_requires_sacrifice":false,"activation_requires_tap":false,"battle_model_scope":"xmage_permanent_simple_activated_self_keyword_until_eot_v1","duration":"until_end_of_turn","effect":"creature","granted_keywords_until_eot":["flying"],"power_delta":0,"target":"self","target_constraints":{"card_types":["creature"],"source":"self"},"target_controller":"self","toughness_delta":0,"xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"GainAbilitySourceEffect","xmage_keyword_ability_class":"FlyingAbility"}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ShadowcloakVampire translated into ManaLoom runtime scope xmage_permanent_simple_activated_self_keyword_until_eot_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
