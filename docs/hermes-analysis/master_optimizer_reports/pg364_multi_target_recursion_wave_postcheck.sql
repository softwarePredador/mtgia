WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('rise from the wreck', 'Rise from the Wreck', 'f165245a634ee3badf5399cc4920b6e4', 'battle_rule_v1:f5936a82bbc6efa77c6d178d3a659129', '{"battle_model_scope":"xmage_return_multiple_graveyard_cards_to_hand_spell_v1","destination":"hand","effect":"recursion","instant":false,"mode_selection":"all_components","recursion_components":[{"count":1,"destination":"hand","target":"creature","target_constraints":{"card_types":["creature"],"controller":"self","zone":"graveyard"},"target_controller":"self","up_to_count":true},{"count":1,"destination":"hand","target":"mount_card","target_constraints":{"controller":"self","subtypes":["mount"],"zone":"graveyard"},"target_controller":"self","up_to_count":true},{"count":1,"destination":"hand","target":"vehicle_card","target_constraints":{"controller":"self","subtypes":["vehicle"],"zone":"graveyard"},"target_controller":"self","up_to_count":true},{"count":1,"destination":"hand","target":"creature_no_abilities","target_constraints":{"card_types":["creature"],"controller":"self","requires_no_abilities":true,"zone":"graveyard"},"target_controller":"self","up_to_count":true}],"sorcery":true,"target_controller":"self","xmage_effect_class":"ReturnFromGraveyardToHandTargetEffect"}'::jsonb, '{"category":"engine","effect":"recursion"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class RiseFromTheWreck translated into ManaLoom runtime scope xmage_return_multiple_graveyard_cards_to_hand_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('rogues'' gallery', 'Rogues'' Gallery', '3add5a0e5d562d4387f08f67caab250f', 'battle_rule_v1:e99befa07d8ef3776682f24beddf5b4d', '{"battle_model_scope":"xmage_return_one_graveyard_creature_per_color_to_hand_spell_v1","destination":"hand","effect":"recursion","instant":false,"mode_selection":"all_components","recursion_components":[{"count":1,"destination":"hand","target":"white_creature","target_constraints":{"card_types":["creature"],"colors":["W"],"controller":"self","zone":"graveyard"},"target_controller":"self","up_to_count":true},{"count":1,"destination":"hand","target":"blue_creature","target_constraints":{"card_types":["creature"],"colors":["U"],"controller":"self","zone":"graveyard"},"target_controller":"self","up_to_count":true},{"count":1,"destination":"hand","target":"black_creature","target_constraints":{"card_types":["creature"],"colors":["B"],"controller":"self","zone":"graveyard"},"target_controller":"self","up_to_count":true},{"count":1,"destination":"hand","target":"red_creature","target_constraints":{"card_types":["creature"],"colors":["R"],"controller":"self","zone":"graveyard"},"target_controller":"self","up_to_count":true},{"count":1,"destination":"hand","target":"green_creature","target_constraints":{"card_types":["creature"],"colors":["G"],"controller":"self","zone":"graveyard"},"target_controller":"self","up_to_count":true}],"sorcery":true,"target_controller":"self","xmage_effect_class":"ReturnFromGraveyardToHandTargetEffect"}'::jsonb, '{"category":"engine","effect":"recursion"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class RoguesGallery translated into ManaLoom runtime scope xmage_return_one_graveyard_creature_per_color_to_hand_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
  (SELECT count(*) FROM manaloom_deploy_audit.pg364_multi_target_recursion_wave_20260702_082426) AS backup_rows
FROM proposed p
LEFT JOIN rule_rows r
  ON r.normalized_name = p.normalized_name
 AND r.logical_rule_key = p.logical_rule_key
 AND r.oracle_hash = p.oracle_hash
GROUP BY p.card_name, p.normalized_name, p.logical_rule_key, p.oracle_hash
ORDER BY p.card_name;
