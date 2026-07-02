WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('reconstruct history', 'Reconstruct History', 'fef076b46b9660e2f9eb20dbce095b86', 'battle_rule_v1:5891f73a4c159c6a7e04ab4a73194bb2', '{"battle_model_scope":"xmage_return_multiple_graveyard_cards_to_hand_exile_self_spell_v1","destination":"hand","effect":"recursion","exiles_self":true,"instant":false,"mode_selection":"all_components","recursion_components":[{"count":1,"destination":"hand","target":"artifact","target_constraints":{"card_types":["artifact"],"controller":"self","zone":"graveyard"},"target_controller":"self","up_to_count":true},{"count":1,"destination":"hand","target":"enchantment","target_constraints":{"card_types":["enchantment"],"controller":"self","zone":"graveyard"},"target_controller":"self","up_to_count":true},{"count":1,"destination":"hand","target":"instant","target_constraints":{"card_types":["instant"],"controller":"self","zone":"graveyard"},"target_controller":"self","up_to_count":true},{"count":1,"destination":"hand","target":"sorcery","target_constraints":{"card_types":["sorcery"],"controller":"self","zone":"graveyard"},"target_controller":"self","up_to_count":true},{"count":1,"destination":"hand","target":"planeswalker","target_constraints":{"card_types":["planeswalker"],"controller":"self","zone":"graveyard"},"target_controller":"self","up_to_count":true}],"sorcery":true,"target_controller":"self","xmage_additional_effect_class":"ExileSpellEffect","xmage_effect_class":"ReturnFromGraveyardToHandTargetEffect"}'::jsonb, '{"category":"engine","effect":"recursion"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ReconstructHistory translated into ManaLoom runtime scope xmage_return_multiple_graveyard_cards_to_hand_exile_self_spell_v1. This row is package-ready only because the source signature is a narrow instant/sorcery spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('retrieve', 'Retrieve', '18bc4cc44ffd6382912e0c7fe24e7335', 'battle_rule_v1:3fb7ce15a27a11482bfeb0a35cc5e088', '{"battle_model_scope":"xmage_return_multiple_graveyard_cards_to_hand_exile_self_spell_v1","destination":"hand","effect":"recursion","exiles_self":true,"instant":false,"mode_selection":"all_components","recursion_components":[{"count":1,"destination":"hand","target":"creature","target_constraints":{"card_types":["creature"],"controller":"self","zone":"graveyard"},"target_controller":"self","up_to_count":true},{"count":1,"destination":"hand","target":"noncreature_permanent","target_constraints":{"card_types":["artifact","enchantment","planeswalker","battle","land"],"controller":"self","exclude_card_types":["creature"],"zone":"graveyard"},"target_controller":"self","up_to_count":true}],"sorcery":true,"target_controller":"self","xmage_additional_effect_class":"ExileSpellEffect","xmage_effect_class":"ReturnFromGraveyardToHandTargetEffect"}'::jsonb, '{"category":"engine","effect":"recursion"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Retrieve translated into ManaLoom runtime scope xmage_return_multiple_graveyard_cards_to_hand_exile_self_spell_v1. This row is package-ready only because the source signature is a narrow instant/sorcery spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('vivid revival', 'Vivid Revival', '9f4629b135cb2888979404fca4a71cea', 'battle_rule_v1:0eaec04572207c2751454d4b4793493b', '{"battle_model_scope":"xmage_return_target_graveyard_card_to_hand_spell_v1","count":3,"destination":"hand","effect":"recursion","exiles_self":true,"instant":false,"sorcery":true,"target":"multicolored_card","target_constraints":{"controller":"self","min_colors":2,"zone":"graveyard"},"target_controller":"self","up_to_count":true,"xmage_additional_effect_class":"ExileSpellEffect","xmage_effect_class":"ReturnFromGraveyardToHandTargetEffect"}'::jsonb, '{"category":"engine","effect":"recursion","target":"multicolored_card"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class VividRevival translated into ManaLoom runtime scope xmage_return_target_graveyard_card_to_hand_spell_v1. This row is package-ready only because the source signature is a narrow instant/sorcery spell with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
  (SELECT count(*) FROM manaloom_deploy_audit.pg342_xmage_recursion_exile_self_spell_wave_20260702_010) AS backup_rows
FROM proposed p
LEFT JOIN rule_rows r
  ON r.normalized_name = p.normalized_name
 AND r.logical_rule_key = p.logical_rule_key
 AND r.oracle_hash = p.oracle_hash
GROUP BY p.card_name, p.normalized_name, p.logical_rule_key, p.oracle_hash
ORDER BY p.card_name;
