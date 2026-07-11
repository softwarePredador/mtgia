WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('amateur auteur', 'Amateur Auteur', '59054373999f52f5c61e900b2cd126f0', 'battle_rule_v1:8d785cce5e96ace9d9bd08d0200e672f', '{"_activated_rule_effects":[{"ability_kind":"activated","activated_effect":"destroy_target","activated_remove_effect":"remove_permanent","activated_remove_target":"enchantment","activated_self_sacrifice_destroy":true,"activation_cost_colors":[],"activation_cost_generic":0,"activation_cost_mana":"{0}","activation_requires_sacrifice":true,"activation_requires_tap":false,"battle_model_scope":"xmage_permanent_simple_activated_destroy_target_v1","destination":"graveyard","effect":"remove_permanent","target":"enchantment","target_constraints":{"card_types":["enchantment"]},"xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"DestroyTargetEffect"}],"ability_kind":"static_and_activated","activated_battle_model_scope":"xmage_permanent_simple_activated_destroy_target_v1","activated_effect":"destroy_target","activated_remove_effect":"remove_permanent","activated_remove_target":"enchantment","activated_self_sacrifice_destroy":true,"activation_cost_colors":[],"activation_cost_generic":0,"activation_cost_mana":"{0}","activation_requires_sacrifice":true,"activation_requires_tap":false,"battle_model_scope":"xmage_permanent_simple_activated_destroy_target_v1","destination":"graveyard","effect":"creature","target":"enchantment","target_constraints":{"card_types":["enchantment"]},"xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"DestroyTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"enchantment"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class AmateurAuteur translated into ManaLoom runtime scope xmage_permanent_simple_activated_destroy_target_v1. This row is package-ready only because the source signature is a narrow permanent with a simple activated destroy-target ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('ancestral recall', 'Ancestral Recall', '83d71dab676df6b86902b5381ad8cc92', 'battle_rule_v1:141cd982f73e0b3a973a4bce1890445d', '{"battle_model_scope":"xmage_fixed_target_player_draw_spell_v1","count":3,"draw_count":3,"effect":"draw_cards","instant":true,"sorcery":false,"target":"player","target_constraints":{"players":["any"]},"target_controller":"target_player","target_player_draw":true,"target_preference":"self","xmage_effect_class":"DrawCardTargetEffect"}'::jsonb, '{"category":"draw","effect":"draw_cards","target":"player","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class AncestralRecall translated into ManaLoom runtime scope xmage_fixed_target_player_draw_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('black lotus', 'Black Lotus', 'b0b878fdf89aa25c023d7399b6c2fac0', 'battle_rule_v1:43cd816256f393d3f97342d769039fb8', '{"ability_kind":"activated_mana","activation_requires_sacrifice":true,"activation_requires_tap":true,"battle_model_scope":"xmage_self_sacrifice_mana_source_permanent_v1","effect":"ramp_permanent","is_mana_source":true,"mana_activation_requires_sacrifice":true,"mana_activation_requires_tap":true,"mana_produced":3,"mana_source_contextual_only":true,"permanent_type":"artifact","produces":"WUBRG","xmage_ability_class":"SimpleManaAbility","xmage_auxiliary_ability_classes":[],"xmage_cost_class":"SacrificeSourceCost","xmage_effect_classes":["AddManaOfAnyColorEffect"],"xmage_mana_ability_classes":["SimpleManaAbility"],"xmage_unmodeled_effect_classes":[]}'::jsonb, '{"category":"ramp","effect":"ramp_permanent"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class BlackLotus translated into ManaLoom runtime scope xmage_self_sacrifice_mana_source_permanent_v1. This row is package-ready only because the source signature is a narrow activated mana-source permanent with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('cleanse', 'Cleanse', '2e699cf4d90365b8ee29dfc2aff58ecc', 'battle_rule_v1:4b94ae19282510e921d46fedf7762dd2', '{"battle_model_scope":"xmage_destroy_all_matching_permanents_spell_v1","destination":"graveyard","destroy_card_types":["creature"],"destroy_required_colors":["B"],"effect":"board_wipe","instant":false,"sorcery":true,"xmage_effect_class":"DestroyAllEffect"}'::jsonb, '{"category":"wipe","effect":"board_wipe"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Cleanse translated into ManaLoom runtime scope xmage_destroy_all_matching_permanents_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('crusade', 'Crusade', '151277fd19b46ecec3edb0f4cbd47368', 'battle_rule_v1:746c98920a32abbb9d471b241e0580fc', '{"ability_kind":"static","battle_model_scope":"xmage_static_global_power_toughness_boost_v1","creature_filter":{"colors":["W"]},"effect":"static_global_power_toughness_boost","permanent_type":"enchantment","static_applies_to":"w_creatures","static_controller_scope":"all","static_effect":"global_power_toughness_boost","static_exclude_source":false,"static_power_bonus":1,"static_toughness_bonus":1,"target":"w_creatures","target_constraints":{"card_types":["creature"],"colors":["W"],"controller":"all","creature_filter":{"colors":["W"]}},"target_controller":"all","xmage_ability_class":"SimpleStaticAbility","xmage_effect_class":"BoostAllEffect"}'::jsonb, '{"category":"support","effect":"static_global_power_toughness_boost","subtype":"static_global_pump","target":"w_creatures"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Crusade translated into ManaLoom runtime scope xmage_static_global_power_toughness_boost_v1. This row is package-ready only because the source signature is a narrow permanent static global/opponent/filtered creature power/toughness boost with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('nimble pilferer', 'Nimble Pilferer', 'bf2c44e6fc09515648b91b1bb4ec3f5f', 'battle_rule_v1:c8861f554480ae68baa034a71de2fcae', '{"_keywords_are_self":true,"battle_model_scope":"xmage_static_self_combat_keyword_creature_v1","effect":"creature","flash":true,"keywords":["flash"],"xmage_ability_classes":["FlashAbility"]}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class NimblePilferer translated into ManaLoom runtime scope xmage_static_self_combat_keyword_creature_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('novellamental', 'Novellamental', 'ed0499a5deb12978780e059f84a5380f', 'battle_rule_v1:589e1344f2d78874998e014b0e0fba74', '{"_keywords_are_self":true,"ability_kind":"static","battle_model_scope":"xmage_static_flying_can_block_only_flying_creature_v1","block_restriction":"creatures_with_flying_only","can_block_only_flying":true,"effect":"creature","flying":true,"keywords":["flying"],"static_effect":"self_flying_can_block_only_flying","target":"self","target_controller":"self","xmage_ability_classes":["CanBlockOnlyFlyingAbility","FlyingAbility"]}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Novellamental translated into ManaLoom runtime scope xmage_static_flying_can_block_only_flying_creature_v1. This row is package-ready only because the source signature is a narrow creature static flying with block-only-flying restriction with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('pradesh gypsies', 'Pradesh Gypsies', '93ddfbda004227c7526afd00f431b7a3', 'battle_rule_v1:6f621a8ad6e7186e43cc357e46204b36', '{"_activated_rule_effects":[{"ability_kind":"activated","activated_effect":"target_stat_modifier_until_eot","activation_cost_colors":["G"],"activation_cost_generic":1,"activation_cost_mana":"{1}{G}","activation_requires_sacrifice":false,"activation_requires_tap":true,"battle_model_scope":"xmage_permanent_simple_activated_target_boost_until_eot_v1","duration":"until_end_of_turn","effect":"stat_modifier_until_eot","power_boost":-2,"power_delta":-2,"target":"creature","target_constraints":{"card_types":["creature"]},"target_controller":"any","toughness_boost":0,"toughness_delta":0,"xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"BoostTargetEffect"}],"ability_kind":"static_and_activated","activated_battle_model_scope":"xmage_permanent_simple_activated_target_boost_until_eot_v1","activated_effect":"target_stat_modifier_until_eot","activation_cost_colors":["G"],"activation_cost_generic":1,"activation_cost_mana":"{1}{G}","activation_requires_sacrifice":false,"activation_requires_tap":true,"battle_model_scope":"xmage_permanent_simple_activated_target_boost_until_eot_v1","duration":"until_end_of_turn","effect":"creature","power_boost":-2,"power_delta":-2,"target":"creature","target_constraints":{"card_types":["creature"]},"target_controller":"any","toughness_boost":0,"toughness_delta":0,"xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"BoostTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class PradeshGypsies translated into ManaLoom runtime scope xmage_permanent_simple_activated_target_boost_until_eot_v1. This row is package-ready only because the source signature is a narrow permanent simple activated target-creature boost until end of turn with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('river''s favor', 'River''s Favor', '9a99bde90b3ed7a7adcc8c692b79d76d', 'battle_rule_v1:d4f3411b0359a3d169fdf85657fe4fc6', '{"ability_kind":"aura_static","aura":true,"battle_model_scope":"xmage_aura_static_power_toughness_attachment_v1","effect":"aura_static_attachment","enchant_target":"creature","enchant_target_controller":"any","instant":false,"power_boost":1,"sorcery":false,"static_power_bonus":1,"static_toughness_bonus":1,"target":"creature","target_constraints":{"card_types":["creature"],"zone":"battlefield"},"toughness_boost":1,"xmage_ability_classes":["EnchantAbility","SimpleStaticAbility"],"xmage_effect_classes":["AttachEffect","BoostEnchantedEffect"]}'::jsonb, '{"category":"support","effect":"aura_static_attachment","subtype":"aura_static_pump","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class RiversFavor translated into ManaLoom runtime scope xmage_aura_static_power_toughness_attachment_v1. This row is package-ready only because the source signature is a narrow fixed Aura attachment with static enchanted-creature power/toughness modifier with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('timmy, power gamer', 'Timmy, Power Gamer', 'ddc3ddc06ca111214153a30a7e9f5d5f', 'battle_rule_v1:241d0ed7bce5667076125ac03235241e', '{"_activated_rule_effects":[{"ability_kind":"activated","activated_effect":"put_from_hand_onto_battlefield","activation_cost_colors":[],"activation_cost_generic":4,"activation_cost_mana":"{4}","activation_requires_sacrifice":false,"activation_requires_tap":false,"battle_model_scope":"xmage_permanent_simple_activated_put_hand_card_onto_battlefield_v1","count":1,"destination":"battlefield","effect":"put_from_hand_onto_battlefield","optional":true,"put_from_hand_target":"creature_card","target":"creature_card","target_constraints":{"card_types":["creature"],"controller":"self","zone":"hand"},"xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"PutCardFromHandOntoBattlefieldEffect"}],"ability_kind":"static_and_activated","activated_battle_model_scope":"xmage_permanent_simple_activated_put_hand_card_onto_battlefield_v1","activated_effect":"put_from_hand_onto_battlefield","activation_cost_colors":[],"activation_cost_generic":4,"activation_cost_mana":"{4}","activation_requires_sacrifice":false,"activation_requires_tap":false,"battle_model_scope":"xmage_permanent_simple_activated_put_hand_card_onto_battlefield_v1","count":1,"destination":"battlefield","effect":"creature","instant":false,"optional":true,"put_from_hand_target":"creature_card","sorcery":false,"target":"creature_card","target_constraints":{"card_types":["creature"],"controller":"self","zone":"hand"},"xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"PutCardFromHandOntoBattlefieldEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"creature_card"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class TimmyPowerGamer translated into ManaLoom runtime scope xmage_permanent_simple_activated_put_hand_card_onto_battlefield_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
