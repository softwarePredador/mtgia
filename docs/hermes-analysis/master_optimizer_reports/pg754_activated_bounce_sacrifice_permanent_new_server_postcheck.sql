WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('barrin, master wizard', 'Barrin, Master Wizard', '87e6d20a7dc1c9db036ec158b494f562', 'battle_rule_v1:85bf4045766f33d584b7be8dbf294cf3', '{"_activated_rule_effects":[{"ability_kind":"activated","activated_effect":"return_to_hand","activated_remove_effect":"remove_creature","activated_remove_target":"creature","activation_cost_colors":[],"activation_cost_generic":2,"activation_cost_mana":"{2}","activation_requires_sacrifice":false,"activation_requires_sacrifice_target":true,"activation_requires_tap":false,"activation_sacrifice_cost":{"constraints":{"card_types":["permanent"]},"count":1,"target_controller":"self"},"activation_sacrifice_target":"permanent","battle_model_scope":"xmage_permanent_simple_activated_return_to_hand_v1","destination":"hand","effect":"remove_creature","target":"creature","target_constraints":{"card_types":["creature"]},"target_controller":"any","xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"ReturnToHandTargetEffect"}],"ability_kind":"static_and_activated","activated_battle_model_scope":"xmage_permanent_simple_activated_return_to_hand_v1","activated_effect":"return_to_hand","activated_remove_effect":"remove_creature","activated_remove_target":"creature","activation_cost_colors":[],"activation_cost_generic":2,"activation_cost_mana":"{2}","activation_requires_sacrifice":false,"activation_requires_sacrifice_target":true,"activation_requires_tap":false,"activation_sacrifice_cost":{"constraints":{"card_types":["permanent"]},"count":1,"target_controller":"self"},"activation_sacrifice_target":"permanent","battle_model_scope":"xmage_permanent_simple_activated_return_to_hand_v1","destination":"hand","effect":"creature","target":"creature","target_constraints":{"card_types":["creature"]},"target_controller":"any","xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"ReturnToHandTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class BarrinMasterWizard translated into ManaLoom runtime scope xmage_permanent_simple_activated_return_to_hand_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('dispersing orb', 'Dispersing Orb', 'b32e7eb5686ddbb4b39c03a6eb238da9', 'battle_rule_v1:5227fd189d1975e288565bf858fb26ca', '{"_activated_rule_effects":[{"ability_kind":"activated","activated_effect":"return_to_hand","activated_remove_effect":"remove_permanent","activated_remove_target":"permanent","activation_cost_colors":["U"],"activation_cost_generic":3,"activation_cost_mana":"{3}{U}","activation_requires_sacrifice":false,"activation_requires_sacrifice_target":true,"activation_requires_tap":false,"activation_sacrifice_cost":{"constraints":{"card_types":["permanent"]},"count":1,"target_controller":"self"},"activation_sacrifice_target":"permanent","battle_model_scope":"xmage_permanent_simple_activated_return_to_hand_v1","destination":"hand","effect":"remove_permanent","target":"permanent","target_constraints":{"card_types":["permanent"]},"target_controller":"any","xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"ReturnToHandTargetEffect"}],"ability_kind":"static_and_activated","activated_battle_model_scope":"xmage_permanent_simple_activated_return_to_hand_v1","activated_effect":"return_to_hand","activated_remove_effect":"remove_permanent","activated_remove_target":"permanent","activation_cost_colors":["U"],"activation_cost_generic":3,"activation_cost_mana":"{3}{U}","activation_requires_sacrifice":false,"activation_requires_sacrifice_target":true,"activation_requires_tap":false,"activation_sacrifice_cost":{"constraints":{"card_types":["permanent"]},"count":1,"target_controller":"self"},"activation_sacrifice_target":"permanent","battle_model_scope":"xmage_permanent_simple_activated_return_to_hand_v1","destination":"hand","effect":"enchantment","target":"permanent","target_constraints":{"card_types":["permanent"]},"target_controller":"any","xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"ReturnToHandTargetEffect"}'::jsonb, '{"category":"unknown","effect":"enchantment","target":"permanent"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class DispersingOrb translated into ManaLoom runtime scope xmage_permanent_simple_activated_return_to_hand_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
  (SELECT count(*) FROM manaloom_deploy_audit.pg754_activated_bounce_sacrifice_permane_20260711_100844) AS backup_rows
FROM proposed p
LEFT JOIN rule_rows r
  ON r.normalized_name = p.normalized_name
 AND r.logical_rule_key = p.logical_rule_key
 AND r.oracle_hash = p.oracle_hash
GROUP BY p.card_name, p.normalized_name, p.logical_rule_key, p.oracle_hash
ORDER BY p.card_name;
