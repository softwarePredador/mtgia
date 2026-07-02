WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('kraul swarm', 'Kraul Swarm', 'ce6487ec0c9390b671f943218a3d91d4', 'battle_rule_v1:78623fce867f2ee487ca4e676e1ee24c', '{"_keywords_are_self":true,"ability_kind":"graveyard_activated","activated_battle_model_scope":"xmage_graveyard_simple_activated_self_return_to_hand_v1","activated_effect":"recursion","activation_additional_cost":"discard_cards","activation_cost_colors":["B"],"activation_cost_generic":2,"activation_cost_mana":"{2}{B}","activation_discard_count":1,"activation_discard_target":"creature_card","battle_model_scope":"xmage_graveyard_simple_activated_self_return_to_hand_v1","destination":"hand","effect":"creature","graveyard_self_return_activation_cost_colors":["B"],"graveyard_self_return_activation_cost_generic":2,"graveyard_self_return_activation_cost_mana":"{2}{B}","graveyard_self_return_activation_discard_count":1,"graveyard_self_return_activation_discard_target":"creature_card","graveyard_self_return_destination":"hand","graveyard_self_return_to_hand":true,"keywords":["flying"],"source_zone":"graveyard","target":"self","target_controller":"self","xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"ReturnSourceFromGraveyardToHandEffect"}'::jsonb, '{"category":"engine","effect":"creature","subtype":"recursive_threat","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class KraulSwarm translated into ManaLoom runtime scope xmage_graveyard_simple_activated_self_return_to_hand_v1. This row is package-ready only because the source signature is a narrow graveyard simple activated self-return-to-hand ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('summoned dromedary', 'Summoned Dromedary', '13fc3d6984775175dc610ecae995640a', 'battle_rule_v1:7ba166ab2496e64c7384c93e91d03e44', '{"_keywords_are_self":true,"ability_kind":"graveyard_activated","activated_battle_model_scope":"xmage_graveyard_simple_activated_self_return_to_hand_v1","activated_effect":"recursion","activation_cost_colors":["W"],"activation_cost_generic":1,"activation_cost_mana":"{1}{W}","activation_timing":"sorcery","battle_model_scope":"xmage_graveyard_simple_activated_self_return_to_hand_v1","destination":"hand","effect":"creature","graveyard_self_return_activation_cost_colors":["W"],"graveyard_self_return_activation_cost_generic":1,"graveyard_self_return_activation_cost_mana":"{1}{W}","graveyard_self_return_destination":"hand","graveyard_self_return_to_hand":true,"keywords":["vigilance"],"source_zone":"graveyard","target":"self","target_controller":"self","xmage_ability_class":"ActivateAsSorceryActivatedAbility","xmage_effect_class":"ReturnSourceFromGraveyardToHandEffect"}'::jsonb, '{"category":"engine","effect":"creature","subtype":"recursive_threat","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class SummonedDromedary translated into ManaLoom runtime scope xmage_graveyard_simple_activated_self_return_to_hand_v1. This row is package-ready only because the source signature is a narrow graveyard simple activated self-return-to-hand ability with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
  (SELECT count(*) FROM manaloom_deploy_audit.pg351_xmage_graveyard_self_return_hand_discard_creature_) AS backup_rows
FROM proposed p
LEFT JOIN rule_rows r
  ON r.normalized_name = p.normalized_name
 AND r.logical_rule_key = p.logical_rule_key
 AND r.oracle_hash = p.oracle_hash
GROUP BY p.card_name, p.normalized_name, p.logical_rule_key, p.oracle_hash
ORDER BY p.card_name;
