WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('accursed spirit', 'Accursed Spirit', '633a92d23666fcc688d202accc59ee81', 'battle_rule_v1:8aae0cea4c421be2af1aecb5bc498c53', '{"_keywords_are_self":true,"battle_model_scope":"xmage_static_self_combat_keyword_creature_v1","effect":"creature","intimidate":true,"keywords":["intimidate"],"xmage_ability_classes":["IntimidateAbility"]}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class AccursedSpirit translated into ManaLoom runtime scope xmage_static_self_combat_keyword_creature_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('bladetusk boar', 'Bladetusk Boar', '633a92d23666fcc688d202accc59ee81', 'battle_rule_v1:8aae0cea4c421be2af1aecb5bc498c53', '{"_keywords_are_self":true,"battle_model_scope":"xmage_static_self_combat_keyword_creature_v1","effect":"creature","intimidate":true,"keywords":["intimidate"],"xmage_ability_classes":["IntimidateAbility"]}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class BladetuskBoar translated into ManaLoom runtime scope xmage_static_self_combat_keyword_creature_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('crowd of cinders', 'Crowd of Cinders', 'bbbf07724630e2d9eed139d281366503', 'battle_rule_v1:b3b048bb0db50f65deaf08dd55ba8163', '{"_keywords_are_self":true,"ability_kind":"static","battle_model_scope":"xmage_static_source_power_toughness_equal_count_v1","battlefield_count_card_types":["permanent"],"battlefield_count_required_colors":["B"],"battlefield_count_scope":"controller_battlefield","dynamic_power_equals_count":true,"dynamic_toughness_equals_count":true,"effect":"creature","fear":true,"keywords":["fear"],"stat_modifier_amount_source":"battlefield_permanent_count","static_effect":"source_power_toughness_equal_count","static_power_toughness_base":0,"static_power_toughness_count_multiplier":1,"static_power_toughness_source":"battlefield_permanent_count","target":"self","target_controller":"self","xmage_ability_class":"SimpleStaticAbility","xmage_effect_class":"SetBasePowerToughnessSourceEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class CrowdOfCinders translated into ManaLoom runtime scope xmage_static_source_power_toughness_equal_count_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('dross prowler', 'Dross Prowler', '15faa2ca2927fe40f2021280ea0de932', 'battle_rule_v1:dcb1b5b7cadffa276560e4ed8ac4b96c', '{"_keywords_are_self":true,"battle_model_scope":"xmage_static_self_combat_keyword_creature_v1","effect":"creature","fear":true,"keywords":["fear"],"xmage_ability_classes":["FearAbility"]}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class DrossProwler translated into ManaLoom runtime scope xmage_static_self_combat_keyword_creature_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('gluttonous zombie', 'Gluttonous Zombie', '15faa2ca2927fe40f2021280ea0de932', 'battle_rule_v1:dcb1b5b7cadffa276560e4ed8ac4b96c', '{"_keywords_are_self":true,"battle_model_scope":"xmage_static_self_combat_keyword_creature_v1","effect":"creature","fear":true,"keywords":["fear"],"xmage_ability_classes":["FearAbility"]}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class GluttonousZombie translated into ManaLoom runtime scope xmage_static_self_combat_keyword_creature_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('highborn ghoul', 'Highborn Ghoul', '633a92d23666fcc688d202accc59ee81', 'battle_rule_v1:8aae0cea4c421be2af1aecb5bc498c53', '{"_keywords_are_self":true,"battle_model_scope":"xmage_static_self_combat_keyword_creature_v1","effect":"creature","intimidate":true,"keywords":["intimidate"],"xmage_ability_classes":["IntimidateAbility"]}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class HighbornGhoul translated into ManaLoom runtime scope xmage_static_self_combat_keyword_creature_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('krenko''s enforcer', 'Krenko''s Enforcer', '633a92d23666fcc688d202accc59ee81', 'battle_rule_v1:8aae0cea4c421be2af1aecb5bc498c53', '{"_keywords_are_self":true,"battle_model_scope":"xmage_static_self_combat_keyword_creature_v1","effect":"creature","intimidate":true,"keywords":["intimidate"],"xmage_ability_classes":["IntimidateAbility"]}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class KrenkosEnforcer translated into ManaLoom runtime scope xmage_static_self_combat_keyword_creature_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('prickly boggart', 'Prickly Boggart', '15faa2ca2927fe40f2021280ea0de932', 'battle_rule_v1:dcb1b5b7cadffa276560e4ed8ac4b96c', '{"_keywords_are_self":true,"battle_model_scope":"xmage_static_self_combat_keyword_creature_v1","effect":"creature","fear":true,"keywords":["fear"],"xmage_ability_classes":["FearAbility"]}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class PricklyBoggart translated into ManaLoom runtime scope xmage_static_self_combat_keyword_creature_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('razortooth rats', 'Razortooth Rats', '15faa2ca2927fe40f2021280ea0de932', 'battle_rule_v1:dcb1b5b7cadffa276560e4ed8ac4b96c', '{"_keywords_are_self":true,"battle_model_scope":"xmage_static_self_combat_keyword_creature_v1","effect":"creature","fear":true,"keywords":["fear"],"xmage_ability_classes":["FearAbility"]}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class RazortoothRats translated into ManaLoom runtime scope xmage_static_self_combat_keyword_creature_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('severed legion', 'Severed Legion', '15faa2ca2927fe40f2021280ea0de932', 'battle_rule_v1:dcb1b5b7cadffa276560e4ed8ac4b96c', '{"_keywords_are_self":true,"battle_model_scope":"xmage_static_self_combat_keyword_creature_v1","effect":"creature","fear":true,"keywords":["fear"],"xmage_ability_classes":["FearAbility"]}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class SeveredLegion translated into ManaLoom runtime scope xmage_static_self_combat_keyword_creature_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('shadowmage infiltrator', 'Shadowmage Infiltrator', '5b0b5f2bb475d519669519aa8ee38e55', 'battle_rule_v1:cdad8122d8a012a52adcc8634cac4f91', '{"_keywords_are_self":true,"ability_kind":"triggered","battle_model_scope":"xmage_creature_combat_damage_draw_cards_v1","combat_damage_draw_count":1,"combat_damage_draw_optional":true,"combat_damage_player_draw":true,"draw_count":1,"effect":"creature","fear":true,"keywords":["fear"],"trigger":"combat_damage_to_player","trigger_effect":"draw_cards","xmage_ability_class":"DealsCombatDamageToAPlayerTriggeredAbility","xmage_effect_class":"DrawCardSourceControllerEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ShadowmageInfiltrator translated into ManaLoom runtime scope xmage_creature_combat_damage_draw_cards_v1. This row is package-ready only because the source signature is a narrow creature combat-damage-to-player triggered fixed draw ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('spectral rider', 'Spectral Rider', '633a92d23666fcc688d202accc59ee81', 'battle_rule_v1:8aae0cea4c421be2af1aecb5bc498c53', '{"_keywords_are_self":true,"battle_model_scope":"xmage_static_self_combat_keyword_creature_v1","effect":"creature","intimidate":true,"keywords":["intimidate"],"xmage_ability_classes":["IntimidateAbility"]}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class SpectralRider translated into ManaLoom runtime scope xmage_static_self_combat_keyword_creature_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('squirming mass', 'Squirming Mass', '15faa2ca2927fe40f2021280ea0de932', 'battle_rule_v1:dcb1b5b7cadffa276560e4ed8ac4b96c', '{"_keywords_are_self":true,"battle_model_scope":"xmage_static_self_combat_keyword_creature_v1","effect":"creature","fear":true,"keywords":["fear"],"xmage_ability_classes":["FearAbility"]}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class SquirmingMass translated into ManaLoom runtime scope xmage_static_self_combat_keyword_creature_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('undercity shade', 'Undercity Shade', 'b7429a8ccc4ddcd865bda66804825074', 'battle_rule_v1:a96ae8fcb8a3215364caf7b3665fedf9', '{"_activated_rule_effects":[{"ability_kind":"activated","activated_effect":"self_stat_modifier_until_eot","activation_cost_colors":["B"],"activation_cost_generic":0,"activation_cost_mana":"{B}","activation_requires_sacrifice":false,"activation_requires_tap":false,"battle_model_scope":"xmage_permanent_simple_activated_self_boost_until_eot_v1","duration":"until_end_of_turn","effect":"stat_modifier_until_eot","power_boost":1,"power_delta":1,"target":"self","target_constraints":{"card_types":["creature"],"source":"self"},"target_controller":"self","toughness_boost":1,"toughness_delta":1,"xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"BoostSourceEffect"}],"_keywords_are_self":true,"ability_kind":"static_and_activated","activated_battle_model_scope":"xmage_permanent_simple_activated_self_boost_until_eot_v1","activated_effect":"self_stat_modifier_until_eot","activation_cost_colors":["B"],"activation_cost_generic":0,"activation_cost_mana":"{B}","activation_requires_sacrifice":false,"activation_requires_tap":false,"battle_model_scope":"xmage_permanent_simple_activated_self_boost_until_eot_v1","duration":"until_end_of_turn","effect":"creature","fear":true,"keywords":["fear"],"power_boost":1,"power_delta":1,"target":"self","target_constraints":{"card_types":["creature"],"source":"self"},"target_controller":"self","toughness_boost":1,"toughness_delta":1,"xmage_ability_class":"SimpleActivatedAbility","xmage_auxiliary_static_keywords":["fear"],"xmage_effect_class":"BoostSourceEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class UndercityShade translated into ManaLoom runtime scope xmage_permanent_simple_activated_self_boost_until_eot_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('woebearer', 'Woebearer', '77e677dd903722bd734c63841e23d9e3', 'battle_rule_v1:ae0219d282abfda7fb2d6ee13d3dda1d', '{"_keywords_are_self":true,"ability_kind":"triggered","battle_model_scope":"xmage_creature_combat_damage_return_graveyard_card_to_hand_v1","combat_damage_player_graveyard_recursion":true,"combat_damage_recursion_count":1,"combat_damage_recursion_destination":"hand","combat_damage_recursion_target":"creature","effect":"creature","fear":true,"instant":false,"keywords":["fear"],"sorcery":false,"target_constraints":{"card_types":["creature"],"controller":"self","zone":"graveyard"},"trigger":"combat_damage_to_player","xmage_ability_class":"DealsCombatDamageToAPlayerTriggeredAbility","xmage_effect_class":"ReturnFromGraveyardToHandTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Woebearer translated into ManaLoom runtime scope xmage_creature_combat_damage_return_graveyard_card_to_hand_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
