WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('eternal taskmaster', 'Eternal Taskmaster', '2d79b92556e0ed8ab221480fa5fd873d', 'battle_rule_v1:4022dff702a96dc4ab9837e68a1f30e0', '{"ability_kind":"triggered","attack_recursion_count":1,"attack_recursion_destination":"hand","attack_recursion_target":"creature","attack_recursion_trigger_cost_colors":["B"],"attack_recursion_trigger_cost_generic":2,"attack_recursion_trigger_cost_mana":"{2}{B}","attack_trigger_graveyard_recursion":true,"battle_model_scope":"xmage_permanent_attack_return_graveyard_card_to_hand_v1","effect":"creature","enters_tapped":true,"instant":false,"sorcery":false,"target_constraints":{"card_types":["creature"],"controller":"self","zone":"graveyard"},"trigger":"attack","xmage_ability_class":"AttacksTriggeredAbility","xmage_effect_class":"ReturnFromGraveyardToHandTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class EternalTaskmaster translated into ManaLoom runtime scope xmage_permanent_attack_return_graveyard_card_to_hand_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('pillardrop warden', 'Pillardrop Warden', 'c32f8c92a5a3cd47b3cd510867bbf5c5', 'battle_rule_v1:decee249f26e77cc845acd6db9ba629a', '{"_activated_rule_effects":[{"ability_kind":"activated","activated_effect":"recursion","activated_self_sacrifice_recursion":true,"activation_cost_colors":[],"activation_cost_generic":2,"activation_cost_mana":"{2}","activation_discard_count":0,"activation_discard_target":null,"activation_requires_sacrifice":true,"activation_requires_tap":true,"activation_timing":"sorcery","battle_model_scope":"xmage_permanent_simple_activated_graveyard_to_hand_v1","count":1,"destination":"hand","effect":"recursion","graveyard_to_hand_destination":"hand","graveyard_to_hand_target":"instant_or_sorcery","graveyard_to_hand_target_count":1,"target":"instant_or_sorcery","target_constraints":{"card_types":["instant","sorcery"],"controller":"self","zone":"graveyard"},"target_controller":"self","xmage_ability_class":"ActivateAsSorceryActivatedAbility","xmage_effect_class":"ReturnFromGraveyardToHandTargetEffect"}],"_keywords_are_self":true,"ability_kind":"static_and_activated","activated_battle_model_scope":"xmage_permanent_simple_activated_graveyard_to_hand_v1","activated_effect":"recursion","activated_self_sacrifice_recursion":true,"activation_cost_colors":[],"activation_cost_generic":2,"activation_cost_mana":"{2}","activation_discard_count":0,"activation_discard_target":null,"activation_requires_sacrifice":true,"activation_requires_tap":true,"activation_timing":"sorcery","battle_model_scope":"xmage_permanent_simple_activated_graveyard_to_hand_v1","effect":"creature","graveyard_to_hand_activation_cost_colors":[],"graveyard_to_hand_activation_cost_generic":2,"graveyard_to_hand_activation_cost_mana":"{2}","graveyard_to_hand_activation_discard_count":0,"graveyard_to_hand_activation_discard_target":null,"graveyard_to_hand_activation_requires_sacrifice":true,"graveyard_to_hand_activation_requires_tap":true,"graveyard_to_hand_activation_timing":"sorcery","graveyard_to_hand_destination":"hand","graveyard_to_hand_target":"instant_or_sorcery","graveyard_to_hand_target_count":1,"keywords":["reach"],"reach":true,"target":"instant_or_sorcery","target_constraints":{"card_types":["instant","sorcery"],"controller":"self","zone":"graveyard"},"target_controller":"self","xmage_ability_class":"ActivateAsSorceryActivatedAbility","xmage_effect_class":"ReturnFromGraveyardToHandTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"instant_or_sorcery"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class PillardropWarden translated into ManaLoom runtime scope xmage_permanent_simple_activated_graveyard_to_hand_v1. This row is package-ready only because the source signature is a narrow permanent with a simple activated graveyard-to-hand ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('the unspeakable', 'The Unspeakable', 'b1b6b05b9d4aea8f3ac0379433f54829', 'battle_rule_v1:2725808803ad0a91360ce43429ab4063', '{"_keywords_are_self":true,"ability_kind":"triggered","battle_model_scope":"xmage_creature_combat_damage_return_graveyard_card_to_hand_v1","combat_damage_player_graveyard_recursion":true,"combat_damage_recursion_count":1,"combat_damage_recursion_destination":"hand","combat_damage_recursion_target":"arcane_card","effect":"creature","flying":true,"instant":false,"keywords":["flying","trample"],"sorcery":false,"target_constraints":{"controller":"self","subtypes":["arcane"],"zone":"graveyard"},"trample":true,"trigger":"combat_damage_to_player","xmage_ability_class":"DealsCombatDamageToAPlayerTriggeredAbility","xmage_effect_class":"ReturnFromGraveyardToHandTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class TheUnspeakable translated into ManaLoom runtime scope xmage_creature_combat_damage_return_graveyard_card_to_hand_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
