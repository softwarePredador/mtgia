WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('tortured existence', 'Tortured Existence', '6f6d8640e8e53168b50e7e8d709c05a8', 'battle_rule_v1:05299740e91bdbe1ada273d07f09c035', '{"_activated_rule_effects":[{"ability_kind":"activated","activated_effect":"recursion","activation_additional_cost":"discard_cards","activation_cost_colors":["B"],"activation_cost_generic":0,"activation_cost_mana":"{B}","activation_discard_count":1,"activation_discard_target":"creature_card","activation_requires_sacrifice":false,"activation_requires_tap":false,"battle_model_scope":"xmage_permanent_simple_activated_graveyard_to_hand_v1","count":1,"destination":"hand","effect":"recursion","graveyard_to_hand_destination":"hand","graveyard_to_hand_target":"creature","graveyard_to_hand_target_count":1,"target":"creature","target_constraints":{"card_types":["creature"],"controller":"self","zone":"graveyard"},"target_controller":"self","xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"ReturnFromGraveyardToHandTargetEffect"}],"ability_kind":"static_and_activated","activated_battle_model_scope":"xmage_permanent_simple_activated_graveyard_to_hand_v1","activated_effect":"recursion","activation_additional_cost":"discard_cards","activation_cost_colors":["B"],"activation_cost_generic":0,"activation_cost_mana":"{B}","activation_discard_count":1,"activation_discard_target":"creature_card","activation_requires_sacrifice":false,"activation_requires_tap":false,"battle_model_scope":"xmage_permanent_simple_activated_graveyard_to_hand_v1","effect":"enchantment","graveyard_to_hand_activation_cost_colors":["B"],"graveyard_to_hand_activation_cost_generic":0,"graveyard_to_hand_activation_cost_mana":"{B}","graveyard_to_hand_activation_discard_count":1,"graveyard_to_hand_activation_discard_target":"creature_card","graveyard_to_hand_activation_requires_sacrifice":false,"graveyard_to_hand_activation_requires_tap":false,"graveyard_to_hand_destination":"hand","graveyard_to_hand_target":"creature","graveyard_to_hand_target_count":1,"target":"creature","target_constraints":{"card_types":["creature"],"controller":"self","zone":"graveyard"},"target_controller":"self","xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"ReturnFromGraveyardToHandTargetEffect"}'::jsonb, '{"category":"unknown","effect":"enchantment","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class TorturedExistence translated into ManaLoom runtime scope xmage_permanent_simple_activated_graveyard_to_hand_v1. This row is package-ready only because the source signature is a narrow permanent with a simple activated graveyard-to-hand ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('undertaker', 'Undertaker', 'ad9d898ad783bd2752c50eebbda36ed2', 'battle_rule_v1:1aa5ea7c3bab32dc4ada45f1127c8022', '{"_activated_rule_effects":[{"ability_kind":"activated","activated_effect":"recursion","activation_additional_cost":"discard_cards","activation_cost_colors":["B"],"activation_cost_generic":0,"activation_cost_mana":"{B}","activation_discard_count":1,"activation_discard_target":"any_card","activation_requires_sacrifice":false,"activation_requires_tap":true,"battle_model_scope":"xmage_permanent_simple_activated_graveyard_to_hand_v1","count":1,"destination":"hand","effect":"recursion","graveyard_to_hand_destination":"hand","graveyard_to_hand_target":"creature","graveyard_to_hand_target_count":1,"target":"creature","target_constraints":{"card_types":["creature"],"controller":"self","zone":"graveyard"},"target_controller":"self","xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"ReturnFromGraveyardToHandTargetEffect"}],"ability_kind":"static_and_activated","activated_battle_model_scope":"xmage_permanent_simple_activated_graveyard_to_hand_v1","activated_effect":"recursion","activation_additional_cost":"discard_cards","activation_cost_colors":["B"],"activation_cost_generic":0,"activation_cost_mana":"{B}","activation_discard_count":1,"activation_discard_target":"any_card","activation_requires_sacrifice":false,"activation_requires_tap":true,"battle_model_scope":"xmage_permanent_simple_activated_graveyard_to_hand_v1","effect":"creature","graveyard_to_hand_activation_cost_colors":["B"],"graveyard_to_hand_activation_cost_generic":0,"graveyard_to_hand_activation_cost_mana":"{B}","graveyard_to_hand_activation_discard_count":1,"graveyard_to_hand_activation_discard_target":"any_card","graveyard_to_hand_activation_requires_sacrifice":false,"graveyard_to_hand_activation_requires_tap":true,"graveyard_to_hand_destination":"hand","graveyard_to_hand_target":"creature","graveyard_to_hand_target_count":1,"target":"creature","target_constraints":{"card_types":["creature"],"controller":"self","zone":"graveyard"},"target_controller":"self","xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"ReturnFromGraveyardToHandTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Undertaker translated into ManaLoom runtime scope xmage_permanent_simple_activated_graveyard_to_hand_v1. This row is package-ready only because the source signature is a narrow permanent with a simple activated graveyard-to-hand ability with focused runtime coverage.', 'deprecate_nonmatching_rows')
),
rule_rows AS (
  SELECT
    r.normalized_name,
    r.logical_rule_key,
    r.oracle_hash,
    r.review_status,
    r.execution_status
  FROM proposed p
  LEFT JOIN public.card_battle_rules r
    ON (
         r.normalized_name = p.normalized_name
         OR r.normalized_name LIKE p.normalized_name || ' // %'
       )
   AND r.logical_rule_key = p.logical_rule_key
)
SELECT
  p.card_name,
  p.normalized_name,
  p.logical_rule_key,
  count(r.*) FILTER (WHERE r.logical_rule_key = p.logical_rule_key) AS promoted_rule_rows,
  count(r.*) FILTER (WHERE r.review_status = 'verified' AND r.execution_status = 'auto') AS promoted_verified_auto_rows,
  count(r.*) FILTER (WHERE r.oracle_hash = p.oracle_hash) AS promoted_oracle_hash_rows,
  (SELECT count(*) FROM manaloom_deploy_audit.pg353_xmage_permanent_activated_graveyard_to_hand_discar) AS backup_rows
FROM proposed p
LEFT JOIN rule_rows r
  ON r.normalized_name = p.normalized_name
 AND r.logical_rule_key = p.logical_rule_key
 AND r.oracle_hash = p.oracle_hash
GROUP BY p.card_name, p.normalized_name, p.logical_rule_key, p.oracle_hash
ORDER BY p.card_name;
