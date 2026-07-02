WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('othelm, sigardian outcast', 'Othelm, Sigardian Outcast', '892dac96b806675afaa11bc15c65e08c', 'battle_rule_v1:aeea4d9d5b81f866734a71f3d2e0450e', '{"_activated_rule_effects":[{"ability_kind":"activated","activated_battle_model_scope":"xmage_permanent_simple_activated_graveyard_to_battlefield_v1","activated_effect":"recursion","activation_cost_colors":[],"activation_cost_generic":2,"activation_cost_mana":"{2}","activation_requires_sacrifice":false,"activation_requires_tap":true,"battle_model_scope":"xmage_permanent_simple_activated_graveyard_to_battlefield_v1","battlefield_controller":"self","count":1,"destination":"battlefield","effect":"recursion","enters_tapped":true,"graveyard_from_battlefield_this_turn":true,"graveyard_to_hand_destination":"battlefield","graveyard_to_hand_target":"creature","graveyard_to_hand_target_count":1,"target":"creature","target_constraints":{"card_types":["creature"],"controller":"self","graveyard_from_battlefield_this_turn":true,"zone":"graveyard"},"target_controller":"self","target_graveyard_controller":"self","xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"ReturnFromGraveyardToBattlefieldTargetEffect"}],"ability_kind":"static_and_activated","activated_battle_model_scope":"xmage_permanent_simple_activated_graveyard_to_battlefield_v1","activated_effect":"recursion","activated_self_sacrifice_recursion":false,"activation_cost_colors":[],"activation_cost_generic":2,"activation_cost_mana":"{2}","activation_requires_sacrifice":false,"activation_requires_tap":true,"battle_model_scope":"xmage_permanent_simple_activated_graveyard_to_battlefield_v1","battlefield_controller":"self","count":1,"destination":"battlefield","effect":"creature","enters_tapped":true,"graveyard_from_battlefield_this_turn":true,"graveyard_to_hand_activation_cost_colors":[],"graveyard_to_hand_activation_cost_generic":2,"graveyard_to_hand_activation_cost_mana":"{2}","graveyard_to_hand_activation_requires_sacrifice":false,"graveyard_to_hand_activation_requires_tap":true,"graveyard_to_hand_destination":"battlefield","graveyard_to_hand_target":"creature","graveyard_to_hand_target_count":1,"target":"creature","target_constraints":{"card_types":["creature"],"controller":"self","graveyard_from_battlefield_this_turn":true,"zone":"graveyard"},"target_controller":"self","target_graveyard_controller":"self","xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"ReturnFromGraveyardToBattlefieldTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class OthelmSigardianOutcast translated into ManaLoom runtime scope xmage_permanent_simple_activated_graveyard_to_battlefield_v1. This row is package-ready only because the source signature is a narrow permanent with a simple activated graveyard-to-battlefield ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('ramosian revivalist', 'Ramosian Revivalist', 'ee63e43e30e9c420b425349ed602e643', 'battle_rule_v1:80246cb1bf856d9fbb94d600bd79b278', '{"_activated_rule_effects":[{"ability_kind":"activated","activated_battle_model_scope":"xmage_permanent_simple_activated_graveyard_to_battlefield_v1","activated_effect":"recursion","activation_cost_colors":[],"activation_cost_generic":6,"activation_cost_mana":"{6}","activation_requires_sacrifice":false,"activation_requires_tap":true,"battle_model_scope":"xmage_permanent_simple_activated_graveyard_to_battlefield_v1","battlefield_controller":"self","count":1,"destination":"battlefield","effect":"recursion","graveyard_to_hand_destination":"battlefield","graveyard_to_hand_mana_value_max":5,"graveyard_to_hand_target":"rebel_permanent","graveyard_to_hand_target_count":1,"recursion_mana_value_max":5,"target":"rebel_permanent","target_constraints":{"card_types":["artifact","creature","enchantment","planeswalker","battle","land"],"controller":"self","mana_value_max":5,"subtypes":["rebel"],"zone":"graveyard"},"target_controller":"self","target_graveyard_controller":"self","xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"ReturnFromGraveyardToBattlefieldTargetEffect"}],"ability_kind":"static_and_activated","activated_battle_model_scope":"xmage_permanent_simple_activated_graveyard_to_battlefield_v1","activated_effect":"recursion","activated_self_sacrifice_recursion":false,"activation_cost_colors":[],"activation_cost_generic":6,"activation_cost_mana":"{6}","activation_requires_sacrifice":false,"activation_requires_tap":true,"battle_model_scope":"xmage_permanent_simple_activated_graveyard_to_battlefield_v1","battlefield_controller":"self","count":1,"destination":"battlefield","effect":"creature","graveyard_to_hand_activation_cost_colors":[],"graveyard_to_hand_activation_cost_generic":6,"graveyard_to_hand_activation_cost_mana":"{6}","graveyard_to_hand_activation_requires_sacrifice":false,"graveyard_to_hand_activation_requires_tap":true,"graveyard_to_hand_destination":"battlefield","graveyard_to_hand_mana_value_max":5,"graveyard_to_hand_target":"rebel_permanent","graveyard_to_hand_target_count":1,"recursion_mana_value_max":5,"target":"rebel_permanent","target_constraints":{"card_types":["artifact","creature","enchantment","planeswalker","battle","land"],"controller":"self","mana_value_max":5,"subtypes":["rebel"],"zone":"graveyard"},"target_controller":"self","target_graveyard_controller":"self","xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"ReturnFromGraveyardToBattlefieldTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"rebel_permanent"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class RamosianRevivalist translated into ManaLoom runtime scope xmage_permanent_simple_activated_graveyard_to_battlefield_v1. This row is package-ready only because the source signature is a narrow permanent with a simple activated graveyard-to-battlefield ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('rise to glory', 'Rise to Glory', '16043bda3ddbf4b4db3790524911ec02', 'battle_rule_v1:b59b25c2465e54f30f187c5095904a74', '{"battle_model_scope":"xmage_return_one_or_both_graveyard_cards_to_battlefield_spell_v1","battlefield_controller":"self","destination":"battlefield","effect":"recursion","instant":false,"mode_selection":"one_or_both","recursion_components":[{"battlefield_controller":"self","count":1,"destination":"battlefield","target":"creature","target_constraints":{"card_types":["creature"],"controller":"self","zone":"graveyard"},"target_controller":"self","target_graveyard_controller":"self"},{"battlefield_controller":"self","count":1,"destination":"battlefield","target":"aura_card","target_constraints":{"controller":"self","subtypes":["aura"],"zone":"graveyard"},"target_controller":"self","target_graveyard_controller":"self"}],"sorcery":true,"target_controller":"self","target_graveyard_controller":"self","xmage_effect_class":"ReturnFromGraveyardToBattlefieldTargetEffect"}'::jsonb, '{"category":"engine","effect":"recursion"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class RiseToGlory translated into ManaLoom runtime scope xmage_return_one_or_both_graveyard_cards_to_battlefield_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('squirming emergence', 'Squirming Emergence', 'f098fbc9d600c3db40c9aecc256bded1', 'battle_rule_v1:4c3bbbeabd8eae3fbec132c57726c027', '{"battle_model_scope":"xmage_return_target_graveyard_card_to_battlefield_spell_v1","battlefield_controller":"self","count":1,"destination":"battlefield","effect":"recursion","instant":false,"sorcery":true,"target":"nonland_permanent","target_constraints":{"card_types":["artifact","creature","enchantment","planeswalker","battle"],"controller":"self","exclude_card_types":["land"],"mana_value_max_source":"graveyard_permanent_count","zone":"graveyard"},"target_controller":"self","target_graveyard_controller":"self","target_mana_value_max_from_graveyard_permanent_count":true,"xmage_effect_class":"ReturnFromGraveyardToBattlefieldTargetEffect"}'::jsonb, '{"category":"engine","effect":"recursion","target":"nonland_permanent"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class SquirmingEmergence translated into ManaLoom runtime scope xmage_return_target_graveyard_card_to_battlefield_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
