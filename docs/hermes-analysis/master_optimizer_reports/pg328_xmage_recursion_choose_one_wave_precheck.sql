WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('ghoulcaller''s chant', 'Ghoulcaller''s Chant', '4535ec92f19844162f8fe290541ca60e', 'battle_rule_v1:ed71ecbf3fdf66b1cdb2d10aad9d3e65', '{"battle_model_scope":"xmage_return_choose_one_graveyard_cards_to_hand_spell_v1","destination":"hand","effect":"recursion","instant":false,"mode_selection":"choose_one","recursion_components":[{"count":1,"destination":"hand","target":"creature","target_constraints":{"card_types":["creature"],"controller":"self","zone":"graveyard"},"target_controller":"self"},{"count":2,"destination":"hand","target":"zombie_card","target_constraints":{"controller":"self","subtypes":["zombie"],"zone":"graveyard"},"target_controller":"self"}],"sorcery":true,"target_controller":"self","xmage_effect_class":"ReturnFromGraveyardToHandTargetEffect"}'::jsonb, '{"category":"engine","effect":"recursion"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class GhoulcallersChant translated into ManaLoom runtime scope xmage_return_choose_one_graveyard_cards_to_hand_spell_v1. This row is package-ready only because the source signature is a narrow instant/sorcery spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('march of the drowned', 'March of the Drowned', 'b4c57cf5a15caa2681270c5be311e823', 'battle_rule_v1:f0469a979771629fdf4c130ecd40d7ec', '{"battle_model_scope":"xmage_return_choose_one_graveyard_cards_to_hand_spell_v1","destination":"hand","effect":"recursion","instant":false,"mode_selection":"choose_one","recursion_components":[{"count":1,"destination":"hand","target":"creature","target_constraints":{"card_types":["creature"],"controller":"self","zone":"graveyard"},"target_controller":"self"},{"count":2,"destination":"hand","target":"pirate_card","target_constraints":{"controller":"self","subtypes":["pirate"],"zone":"graveyard"},"target_controller":"self"}],"sorcery":true,"target_controller":"self","xmage_effect_class":"ReturnFromGraveyardToHandTargetEffect"}'::jsonb, '{"category":"engine","effect":"recursion"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class MarchOfTheDrowned translated into ManaLoom runtime scope xmage_return_choose_one_graveyard_cards_to_hand_spell_v1. This row is package-ready only because the source signature is a narrow instant/sorcery spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('raise the draugr', 'Raise the Draugr', '73ce0d42ea21a297e8bd61883f32e49d', 'battle_rule_v1:198e31e470f83b580481d825befa6ba0', '{"battle_model_scope":"xmage_return_choose_one_graveyard_cards_to_hand_spell_v1","destination":"hand","effect":"recursion","instant":true,"mode_selection":"choose_one","recursion_components":[{"count":1,"destination":"hand","target":"creature","target_constraints":{"card_types":["creature"],"controller":"self","zone":"graveyard"},"target_controller":"self"},{"count":2,"destination":"hand","shared_subtype_group":"creature_type","target":"shared_creature_type","target_constraints":{"card_types":["creature"],"controller":"self","shared_subtype_group":"creature_type","zone":"graveyard"},"target_controller":"self"}],"sorcery":false,"target_controller":"self","xmage_effect_class":"ReturnFromGraveyardToHandTargetEffect"}'::jsonb, '{"category":"engine","effect":"recursion","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class RaiseTheDraugr translated into ManaLoom runtime scope xmage_return_choose_one_graveyard_cards_to_hand_spell_v1. This row is package-ready only because the source signature is a narrow instant/sorcery spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('return from extinction', 'Return from Extinction', '73ce0d42ea21a297e8bd61883f32e49d', 'battle_rule_v1:863ee7c378baeeb09ce204afdfa84d11', '{"battle_model_scope":"xmage_return_choose_one_graveyard_cards_to_hand_spell_v1","destination":"hand","effect":"recursion","instant":false,"mode_selection":"choose_one","recursion_components":[{"count":1,"destination":"hand","target":"creature","target_constraints":{"card_types":["creature"],"controller":"self","zone":"graveyard"},"target_controller":"self"},{"count":2,"destination":"hand","shared_subtype_group":"creature_type","target":"shared_creature_type","target_constraints":{"card_types":["creature"],"controller":"self","shared_subtype_group":"creature_type","zone":"graveyard"},"target_controller":"self"}],"sorcery":true,"target_controller":"self","xmage_effect_class":"ReturnFromGraveyardToHandTargetEffect"}'::jsonb, '{"category":"engine","effect":"recursion"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ReturnFromExtinction translated into ManaLoom runtime scope xmage_return_choose_one_graveyard_cards_to_hand_spell_v1. This row is package-ready only because the source signature is a narrow instant/sorcery spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('unbury', 'Unbury', '73ce0d42ea21a297e8bd61883f32e49d', 'battle_rule_v1:198e31e470f83b580481d825befa6ba0', '{"battle_model_scope":"xmage_return_choose_one_graveyard_cards_to_hand_spell_v1","destination":"hand","effect":"recursion","instant":true,"mode_selection":"choose_one","recursion_components":[{"count":1,"destination":"hand","target":"creature","target_constraints":{"card_types":["creature"],"controller":"self","zone":"graveyard"},"target_controller":"self"},{"count":2,"destination":"hand","shared_subtype_group":"creature_type","target":"shared_creature_type","target_constraints":{"card_types":["creature"],"controller":"self","shared_subtype_group":"creature_type","zone":"graveyard"},"target_controller":"self"}],"sorcery":false,"target_controller":"self","xmage_effect_class":"ReturnFromGraveyardToHandTargetEffect"}'::jsonb, '{"category":"engine","effect":"recursion","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Unbury translated into ManaLoom runtime scope xmage_return_choose_one_graveyard_cards_to_hand_spell_v1. This row is package-ready only because the source signature is a narrow instant/sorcery spell with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
