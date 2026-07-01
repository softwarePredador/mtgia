WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('ghoulcaller''s chant', 'Ghoulcaller''s Chant', '4535ec92f19844162f8fe290541ca60e', 'battle_rule_v1:ed71ecbf3fdf66b1cdb2d10aad9d3e65', '{"battle_model_scope":"xmage_return_choose_one_graveyard_cards_to_hand_spell_v1","destination":"hand","effect":"recursion","instant":false,"mode_selection":"choose_one","recursion_components":[{"count":1,"destination":"hand","target":"creature","target_constraints":{"card_types":["creature"],"controller":"self","zone":"graveyard"},"target_controller":"self"},{"count":2,"destination":"hand","target":"zombie_card","target_constraints":{"controller":"self","subtypes":["zombie"],"zone":"graveyard"},"target_controller":"self"}],"sorcery":true,"target_controller":"self","xmage_effect_class":"ReturnFromGraveyardToHandTargetEffect"}'::jsonb, '{"category":"engine","effect":"recursion"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class GhoulcallersChant translated into ManaLoom runtime scope xmage_return_choose_one_graveyard_cards_to_hand_spell_v1. This row is package-ready only because the source signature is a narrow instant/sorcery spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('march of the drowned', 'March of the Drowned', 'b4c57cf5a15caa2681270c5be311e823', 'battle_rule_v1:f0469a979771629fdf4c130ecd40d7ec', '{"battle_model_scope":"xmage_return_choose_one_graveyard_cards_to_hand_spell_v1","destination":"hand","effect":"recursion","instant":false,"mode_selection":"choose_one","recursion_components":[{"count":1,"destination":"hand","target":"creature","target_constraints":{"card_types":["creature"],"controller":"self","zone":"graveyard"},"target_controller":"self"},{"count":2,"destination":"hand","target":"pirate_card","target_constraints":{"controller":"self","subtypes":["pirate"],"zone":"graveyard"},"target_controller":"self"}],"sorcery":true,"target_controller":"self","xmage_effect_class":"ReturnFromGraveyardToHandTargetEffect"}'::jsonb, '{"category":"engine","effect":"recursion"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class MarchOfTheDrowned translated into ManaLoom runtime scope xmage_return_choose_one_graveyard_cards_to_hand_spell_v1. This row is package-ready only because the source signature is a narrow instant/sorcery spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('raise the draugr', 'Raise the Draugr', '73ce0d42ea21a297e8bd61883f32e49d', 'battle_rule_v1:198e31e470f83b580481d825befa6ba0', '{"battle_model_scope":"xmage_return_choose_one_graveyard_cards_to_hand_spell_v1","destination":"hand","effect":"recursion","instant":true,"mode_selection":"choose_one","recursion_components":[{"count":1,"destination":"hand","target":"creature","target_constraints":{"card_types":["creature"],"controller":"self","zone":"graveyard"},"target_controller":"self"},{"count":2,"destination":"hand","shared_subtype_group":"creature_type","target":"shared_creature_type","target_constraints":{"card_types":["creature"],"controller":"self","shared_subtype_group":"creature_type","zone":"graveyard"},"target_controller":"self"}],"sorcery":false,"target_controller":"self","xmage_effect_class":"ReturnFromGraveyardToHandTargetEffect"}'::jsonb, '{"category":"engine","effect":"recursion","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class RaiseTheDraugr translated into ManaLoom runtime scope xmage_return_choose_one_graveyard_cards_to_hand_spell_v1. This row is package-ready only because the source signature is a narrow instant/sorcery spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('return from extinction', 'Return from Extinction', '73ce0d42ea21a297e8bd61883f32e49d', 'battle_rule_v1:863ee7c378baeeb09ce204afdfa84d11', '{"battle_model_scope":"xmage_return_choose_one_graveyard_cards_to_hand_spell_v1","destination":"hand","effect":"recursion","instant":false,"mode_selection":"choose_one","recursion_components":[{"count":1,"destination":"hand","target":"creature","target_constraints":{"card_types":["creature"],"controller":"self","zone":"graveyard"},"target_controller":"self"},{"count":2,"destination":"hand","shared_subtype_group":"creature_type","target":"shared_creature_type","target_constraints":{"card_types":["creature"],"controller":"self","shared_subtype_group":"creature_type","zone":"graveyard"},"target_controller":"self"}],"sorcery":true,"target_controller":"self","xmage_effect_class":"ReturnFromGraveyardToHandTargetEffect"}'::jsonb, '{"category":"engine","effect":"recursion"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ReturnFromExtinction translated into ManaLoom runtime scope xmage_return_choose_one_graveyard_cards_to_hand_spell_v1. This row is package-ready only because the source signature is a narrow instant/sorcery spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('unbury', 'Unbury', '73ce0d42ea21a297e8bd61883f32e49d', 'battle_rule_v1:198e31e470f83b580481d825befa6ba0', '{"battle_model_scope":"xmage_return_choose_one_graveyard_cards_to_hand_spell_v1","destination":"hand","effect":"recursion","instant":true,"mode_selection":"choose_one","recursion_components":[{"count":1,"destination":"hand","target":"creature","target_constraints":{"card_types":["creature"],"controller":"self","zone":"graveyard"},"target_controller":"self"},{"count":2,"destination":"hand","shared_subtype_group":"creature_type","target":"shared_creature_type","target_constraints":{"card_types":["creature"],"controller":"self","shared_subtype_group":"creature_type","zone":"graveyard"},"target_controller":"self"}],"sorcery":false,"target_controller":"self","xmage_effect_class":"ReturnFromGraveyardToHandTargetEffect"}'::jsonb, '{"category":"engine","effect":"recursion","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Unbury translated into ManaLoom runtime scope xmage_return_choose_one_graveyard_cards_to_hand_spell_v1. This row is package-ready only because the source signature is a narrow instant/sorcery spell with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
  (SELECT count(*) FROM manaloom_deploy_audit.pg328_xmage_recursion_choose_one_wave_20260701_201656) AS backup_rows
FROM proposed p
LEFT JOIN rule_rows r
  ON r.normalized_name = p.normalized_name
 AND r.logical_rule_key = p.logical_rule_key
 AND r.oracle_hash = p.oracle_hash
GROUP BY p.card_name, p.normalized_name, p.logical_rule_key, p.oracle_hash
ORDER BY p.card_name;
