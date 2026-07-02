WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('doomed necromancer', 'Doomed Necromancer', '16f413bd06f6099af1b5f2edc8376ef8', 'battle_rule_v1:69aa5c0d8ef05abc7839277c916ca703', '{"_activated_rule_effects":[{"ability_kind":"activated","activated_battle_model_scope":"xmage_permanent_simple_activated_graveyard_to_battlefield_v1","activated_effect":"recursion","activated_self_sacrifice_recursion":true,"activation_cost_colors":["B"],"activation_cost_generic":0,"activation_cost_mana":"{B}","activation_requires_sacrifice":true,"activation_requires_tap":true,"battle_model_scope":"xmage_permanent_simple_activated_graveyard_to_battlefield_v1","battlefield_controller":"self","count":1,"destination":"battlefield","effect":"recursion","graveyard_to_hand_destination":"battlefield","graveyard_to_hand_target":"creature","graveyard_to_hand_target_count":1,"target":"creature","target_constraints":{"card_types":["creature"],"controller":"self","zone":"graveyard"},"target_controller":"self","target_graveyard_controller":"self","xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"ReturnFromGraveyardToBattlefieldTargetEffect"}],"ability_kind":"static_and_activated","activated_battle_model_scope":"xmage_permanent_simple_activated_graveyard_to_battlefield_v1","activated_effect":"recursion","activated_self_sacrifice_recursion":true,"activation_cost_colors":["B"],"activation_cost_generic":0,"activation_cost_mana":"{B}","activation_requires_sacrifice":true,"activation_requires_tap":true,"battle_model_scope":"xmage_permanent_simple_activated_graveyard_to_battlefield_v1","battlefield_controller":"self","count":1,"destination":"battlefield","effect":"creature","graveyard_to_hand_activation_cost_colors":["B"],"graveyard_to_hand_activation_cost_generic":0,"graveyard_to_hand_activation_cost_mana":"{B}","graveyard_to_hand_activation_requires_sacrifice":true,"graveyard_to_hand_activation_requires_tap":true,"graveyard_to_hand_destination":"battlefield","graveyard_to_hand_target":"creature","graveyard_to_hand_target_count":1,"target":"creature","target_constraints":{"card_types":["creature"],"controller":"self","zone":"graveyard"},"target_controller":"self","target_graveyard_controller":"self","xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"ReturnFromGraveyardToBattlefieldTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class DoomedNecromancer translated into ManaLoom runtime scope xmage_permanent_simple_activated_graveyard_to_battlefield_v1. This row is package-ready only because the source signature is a narrow permanent with a simple activated graveyard-to-battlefield ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('protomatter powder', 'Protomatter Powder', '10ed15a25e1fe4d28f46da77df2dd0d9', 'battle_rule_v1:fff8c850b20d1a8c8f747263abc55491', '{"_activated_rule_effects":[{"ability_kind":"activated","activated_battle_model_scope":"xmage_permanent_simple_activated_graveyard_to_battlefield_v1","activated_effect":"recursion","activated_self_sacrifice_recursion":true,"activation_cost_colors":["W"],"activation_cost_generic":4,"activation_cost_mana":"{4}{W}","activation_requires_sacrifice":true,"activation_requires_tap":true,"battle_model_scope":"xmage_permanent_simple_activated_graveyard_to_battlefield_v1","battlefield_controller":"self","count":1,"destination":"battlefield","effect":"recursion","graveyard_to_hand_destination":"battlefield","graveyard_to_hand_target":"artifact","graveyard_to_hand_target_count":1,"target":"artifact","target_constraints":{"card_types":["artifact"],"controller":"self","zone":"graveyard"},"target_controller":"self","target_graveyard_controller":"self","xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"ReturnFromGraveyardToBattlefieldTargetEffect"}],"ability_kind":"static_and_activated","activated_battle_model_scope":"xmage_permanent_simple_activated_graveyard_to_battlefield_v1","activated_effect":"recursion","activated_self_sacrifice_recursion":true,"activation_cost_colors":["W"],"activation_cost_generic":4,"activation_cost_mana":"{4}{W}","activation_requires_sacrifice":true,"activation_requires_tap":true,"battle_model_scope":"xmage_permanent_simple_activated_graveyard_to_battlefield_v1","battlefield_controller":"self","count":1,"destination":"battlefield","effect":"artifact","graveyard_to_hand_activation_cost_colors":["W"],"graveyard_to_hand_activation_cost_generic":4,"graveyard_to_hand_activation_cost_mana":"{4}{W}","graveyard_to_hand_activation_requires_sacrifice":true,"graveyard_to_hand_activation_requires_tap":true,"graveyard_to_hand_destination":"battlefield","graveyard_to_hand_target":"artifact","graveyard_to_hand_target_count":1,"target":"artifact","target_constraints":{"card_types":["artifact"],"controller":"self","zone":"graveyard"},"target_controller":"self","target_graveyard_controller":"self","xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"ReturnFromGraveyardToBattlefieldTargetEffect"}'::jsonb, '{"category":"unknown","effect":"artifact","target":"artifact"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ProtomatterPowder translated into ManaLoom runtime scope xmage_permanent_simple_activated_graveyard_to_battlefield_v1. This row is package-ready only because the source signature is a narrow permanent with a simple activated graveyard-to-battlefield ability with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
  (SELECT count(*) FROM manaloom_deploy_audit.pg348_xmage_activated_graveyard_to_battlefield_wave_2026) AS backup_rows
FROM proposed p
LEFT JOIN rule_rows r
  ON r.normalized_name = p.normalized_name
 AND r.logical_rule_key = p.logical_rule_key
 AND r.oracle_hash = p.oracle_hash
GROUP BY p.card_name, p.normalized_name, p.logical_rule_key, p.oracle_hash
ORDER BY p.card_name;
