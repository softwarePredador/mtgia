WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('hana kami', 'Hana Kami', '8611a25874ac2a52c45bcdabda208bf9', 'battle_rule_v1:42fe7c13f0150f5f2563678a7512c43d', '{"_activated_rule_effects":[{"ability_kind":"activated","activated_effect":"recursion","activated_self_sacrifice_recursion":true,"activation_cost_colors":["G"],"activation_cost_generic":1,"activation_cost_mana":"{1}{G}","activation_discard_count":0,"activation_discard_target":null,"activation_requires_sacrifice":true,"activation_requires_tap":false,"battle_model_scope":"xmage_permanent_simple_activated_graveyard_to_hand_v1","count":1,"destination":"hand","effect":"recursion","graveyard_to_hand_destination":"hand","graveyard_to_hand_target":"arcane_card","graveyard_to_hand_target_count":1,"target":"arcane_card","target_constraints":{"controller":"self","subtypes":["arcane"],"zone":"graveyard"},"target_controller":"self","xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"ReturnFromGraveyardToHandTargetEffect"}],"ability_kind":"static_and_activated","activated_battle_model_scope":"xmage_permanent_simple_activated_graveyard_to_hand_v1","activated_effect":"recursion","activated_self_sacrifice_recursion":true,"activation_cost_colors":["G"],"activation_cost_generic":1,"activation_cost_mana":"{1}{G}","activation_discard_count":0,"activation_discard_target":null,"activation_requires_sacrifice":true,"activation_requires_tap":false,"battle_model_scope":"xmage_permanent_simple_activated_graveyard_to_hand_v1","effect":"creature","graveyard_to_hand_activation_cost_colors":["G"],"graveyard_to_hand_activation_cost_generic":1,"graveyard_to_hand_activation_cost_mana":"{1}{G}","graveyard_to_hand_activation_discard_count":0,"graveyard_to_hand_activation_discard_target":null,"graveyard_to_hand_activation_requires_sacrifice":true,"graveyard_to_hand_activation_requires_tap":false,"graveyard_to_hand_destination":"hand","graveyard_to_hand_target":"arcane_card","graveyard_to_hand_target_count":1,"target":"arcane_card","target_constraints":{"controller":"self","subtypes":["arcane"],"zone":"graveyard"},"target_controller":"self","xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"ReturnFromGraveyardToHandTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"arcane_card"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class HanaKami translated into ManaLoom runtime scope xmage_permanent_simple_activated_graveyard_to_hand_v1. This row is package-ready only because the source signature is a narrow permanent with a simple activated graveyard-to-hand ability with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
  (SELECT count(*) FROM manaloom_deploy_audit.pg402_arcane_self_sacrifice_recursion_new_server_2026070) AS backup_rows
FROM proposed p
LEFT JOIN rule_rows r
  ON r.normalized_name = p.normalized_name
 AND r.logical_rule_key = p.logical_rule_key
 AND r.oracle_hash = p.oracle_hash
GROUP BY p.card_name, p.normalized_name, p.logical_rule_key, p.oracle_hash
ORDER BY p.card_name;
