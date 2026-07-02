WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('doomed necromancer', 'Doomed Necromancer', '16f413bd06f6099af1b5f2edc8376ef8', 'battle_rule_v1:69aa5c0d8ef05abc7839277c916ca703', '{"_activated_rule_effects":[{"ability_kind":"activated","activated_battle_model_scope":"xmage_permanent_simple_activated_graveyard_to_battlefield_v1","activated_effect":"recursion","activated_self_sacrifice_recursion":true,"activation_cost_colors":["B"],"activation_cost_generic":0,"activation_cost_mana":"{B}","activation_requires_sacrifice":true,"activation_requires_tap":true,"battle_model_scope":"xmage_permanent_simple_activated_graveyard_to_battlefield_v1","battlefield_controller":"self","count":1,"destination":"battlefield","effect":"recursion","graveyard_to_hand_destination":"battlefield","graveyard_to_hand_target":"creature","graveyard_to_hand_target_count":1,"target":"creature","target_constraints":{"card_types":["creature"],"controller":"self","zone":"graveyard"},"target_controller":"self","target_graveyard_controller":"self","xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"ReturnFromGraveyardToBattlefieldTargetEffect"}],"ability_kind":"static_and_activated","activated_battle_model_scope":"xmage_permanent_simple_activated_graveyard_to_battlefield_v1","activated_effect":"recursion","activated_self_sacrifice_recursion":true,"activation_cost_colors":["B"],"activation_cost_generic":0,"activation_cost_mana":"{B}","activation_requires_sacrifice":true,"activation_requires_tap":true,"battle_model_scope":"xmage_permanent_simple_activated_graveyard_to_battlefield_v1","battlefield_controller":"self","count":1,"destination":"battlefield","effect":"creature","graveyard_to_hand_activation_cost_colors":["B"],"graveyard_to_hand_activation_cost_generic":0,"graveyard_to_hand_activation_cost_mana":"{B}","graveyard_to_hand_activation_requires_sacrifice":true,"graveyard_to_hand_activation_requires_tap":true,"graveyard_to_hand_destination":"battlefield","graveyard_to_hand_target":"creature","graveyard_to_hand_target_count":1,"target":"creature","target_constraints":{"card_types":["creature"],"controller":"self","zone":"graveyard"},"target_controller":"self","target_graveyard_controller":"self","xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"ReturnFromGraveyardToBattlefieldTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class DoomedNecromancer translated into ManaLoom runtime scope xmage_permanent_simple_activated_graveyard_to_battlefield_v1. This row is package-ready only because the source signature is a narrow permanent with a simple activated graveyard-to-battlefield ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('protomatter powder', 'Protomatter Powder', '10ed15a25e1fe4d28f46da77df2dd0d9', 'battle_rule_v1:fff8c850b20d1a8c8f747263abc55491', '{"_activated_rule_effects":[{"ability_kind":"activated","activated_battle_model_scope":"xmage_permanent_simple_activated_graveyard_to_battlefield_v1","activated_effect":"recursion","activated_self_sacrifice_recursion":true,"activation_cost_colors":["W"],"activation_cost_generic":4,"activation_cost_mana":"{4}{W}","activation_requires_sacrifice":true,"activation_requires_tap":true,"battle_model_scope":"xmage_permanent_simple_activated_graveyard_to_battlefield_v1","battlefield_controller":"self","count":1,"destination":"battlefield","effect":"recursion","graveyard_to_hand_destination":"battlefield","graveyard_to_hand_target":"artifact","graveyard_to_hand_target_count":1,"target":"artifact","target_constraints":{"card_types":["artifact"],"controller":"self","zone":"graveyard"},"target_controller":"self","target_graveyard_controller":"self","xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"ReturnFromGraveyardToBattlefieldTargetEffect"}],"ability_kind":"static_and_activated","activated_battle_model_scope":"xmage_permanent_simple_activated_graveyard_to_battlefield_v1","activated_effect":"recursion","activated_self_sacrifice_recursion":true,"activation_cost_colors":["W"],"activation_cost_generic":4,"activation_cost_mana":"{4}{W}","activation_requires_sacrifice":true,"activation_requires_tap":true,"battle_model_scope":"xmage_permanent_simple_activated_graveyard_to_battlefield_v1","battlefield_controller":"self","count":1,"destination":"battlefield","effect":"artifact","graveyard_to_hand_activation_cost_colors":["W"],"graveyard_to_hand_activation_cost_generic":4,"graveyard_to_hand_activation_cost_mana":"{4}{W}","graveyard_to_hand_activation_requires_sacrifice":true,"graveyard_to_hand_activation_requires_tap":true,"graveyard_to_hand_destination":"battlefield","graveyard_to_hand_target":"artifact","graveyard_to_hand_target_count":1,"target":"artifact","target_constraints":{"card_types":["artifact"],"controller":"self","zone":"graveyard"},"target_controller":"self","target_graveyard_controller":"self","xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"ReturnFromGraveyardToBattlefieldTargetEffect"}'::jsonb, '{"category":"unknown","effect":"artifact","target":"artifact"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ProtomatterPowder translated into ManaLoom runtime scope xmage_permanent_simple_activated_graveyard_to_battlefield_v1. This row is package-ready only because the source signature is a narrow permanent with a simple activated graveyard-to-battlefield ability with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
