WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('rise from the wreck', 'Rise from the Wreck', 'f165245a634ee3badf5399cc4920b6e4', 'battle_rule_v1:f5936a82bbc6efa77c6d178d3a659129', '{"battle_model_scope":"xmage_return_multiple_graveyard_cards_to_hand_spell_v1","destination":"hand","effect":"recursion","instant":false,"mode_selection":"all_components","recursion_components":[{"count":1,"destination":"hand","target":"creature","target_constraints":{"card_types":["creature"],"controller":"self","zone":"graveyard"},"target_controller":"self","up_to_count":true},{"count":1,"destination":"hand","target":"mount_card","target_constraints":{"controller":"self","subtypes":["mount"],"zone":"graveyard"},"target_controller":"self","up_to_count":true},{"count":1,"destination":"hand","target":"vehicle_card","target_constraints":{"controller":"self","subtypes":["vehicle"],"zone":"graveyard"},"target_controller":"self","up_to_count":true},{"count":1,"destination":"hand","target":"creature_no_abilities","target_constraints":{"card_types":["creature"],"controller":"self","requires_no_abilities":true,"zone":"graveyard"},"target_controller":"self","up_to_count":true}],"sorcery":true,"target_controller":"self","xmage_effect_class":"ReturnFromGraveyardToHandTargetEffect"}'::jsonb, '{"category":"engine","effect":"recursion"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class RiseFromTheWreck translated into ManaLoom runtime scope xmage_return_multiple_graveyard_cards_to_hand_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('rogues'' gallery', 'Rogues'' Gallery', '3add5a0e5d562d4387f08f67caab250f', 'battle_rule_v1:e99befa07d8ef3776682f24beddf5b4d', '{"battle_model_scope":"xmage_return_one_graveyard_creature_per_color_to_hand_spell_v1","destination":"hand","effect":"recursion","instant":false,"mode_selection":"all_components","recursion_components":[{"count":1,"destination":"hand","target":"white_creature","target_constraints":{"card_types":["creature"],"colors":["W"],"controller":"self","zone":"graveyard"},"target_controller":"self","up_to_count":true},{"count":1,"destination":"hand","target":"blue_creature","target_constraints":{"card_types":["creature"],"colors":["U"],"controller":"self","zone":"graveyard"},"target_controller":"self","up_to_count":true},{"count":1,"destination":"hand","target":"black_creature","target_constraints":{"card_types":["creature"],"colors":["B"],"controller":"self","zone":"graveyard"},"target_controller":"self","up_to_count":true},{"count":1,"destination":"hand","target":"red_creature","target_constraints":{"card_types":["creature"],"colors":["R"],"controller":"self","zone":"graveyard"},"target_controller":"self","up_to_count":true},{"count":1,"destination":"hand","target":"green_creature","target_constraints":{"card_types":["creature"],"colors":["G"],"controller":"self","zone":"graveyard"},"target_controller":"self","up_to_count":true}],"sorcery":true,"target_controller":"self","xmage_effect_class":"ReturnFromGraveyardToHandTargetEffect"}'::jsonb, '{"category":"engine","effect":"recursion"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class RoguesGallery translated into ManaLoom runtime scope xmage_return_one_graveyard_creature_per_color_to_hand_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
