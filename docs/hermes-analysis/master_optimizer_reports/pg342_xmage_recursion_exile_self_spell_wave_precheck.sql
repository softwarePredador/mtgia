WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('reconstruct history', 'Reconstruct History', 'fef076b46b9660e2f9eb20dbce095b86', 'battle_rule_v1:5891f73a4c159c6a7e04ab4a73194bb2', '{"battle_model_scope":"xmage_return_multiple_graveyard_cards_to_hand_exile_self_spell_v1","destination":"hand","effect":"recursion","exiles_self":true,"instant":false,"mode_selection":"all_components","recursion_components":[{"count":1,"destination":"hand","target":"artifact","target_constraints":{"card_types":["artifact"],"controller":"self","zone":"graveyard"},"target_controller":"self","up_to_count":true},{"count":1,"destination":"hand","target":"enchantment","target_constraints":{"card_types":["enchantment"],"controller":"self","zone":"graveyard"},"target_controller":"self","up_to_count":true},{"count":1,"destination":"hand","target":"instant","target_constraints":{"card_types":["instant"],"controller":"self","zone":"graveyard"},"target_controller":"self","up_to_count":true},{"count":1,"destination":"hand","target":"sorcery","target_constraints":{"card_types":["sorcery"],"controller":"self","zone":"graveyard"},"target_controller":"self","up_to_count":true},{"count":1,"destination":"hand","target":"planeswalker","target_constraints":{"card_types":["planeswalker"],"controller":"self","zone":"graveyard"},"target_controller":"self","up_to_count":true}],"sorcery":true,"target_controller":"self","xmage_additional_effect_class":"ExileSpellEffect","xmage_effect_class":"ReturnFromGraveyardToHandTargetEffect"}'::jsonb, '{"category":"engine","effect":"recursion"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ReconstructHistory translated into ManaLoom runtime scope xmage_return_multiple_graveyard_cards_to_hand_exile_self_spell_v1. This row is package-ready only because the source signature is a narrow instant/sorcery spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('retrieve', 'Retrieve', '18bc4cc44ffd6382912e0c7fe24e7335', 'battle_rule_v1:3fb7ce15a27a11482bfeb0a35cc5e088', '{"battle_model_scope":"xmage_return_multiple_graveyard_cards_to_hand_exile_self_spell_v1","destination":"hand","effect":"recursion","exiles_self":true,"instant":false,"mode_selection":"all_components","recursion_components":[{"count":1,"destination":"hand","target":"creature","target_constraints":{"card_types":["creature"],"controller":"self","zone":"graveyard"},"target_controller":"self","up_to_count":true},{"count":1,"destination":"hand","target":"noncreature_permanent","target_constraints":{"card_types":["artifact","enchantment","planeswalker","battle","land"],"controller":"self","exclude_card_types":["creature"],"zone":"graveyard"},"target_controller":"self","up_to_count":true}],"sorcery":true,"target_controller":"self","xmage_additional_effect_class":"ExileSpellEffect","xmage_effect_class":"ReturnFromGraveyardToHandTargetEffect"}'::jsonb, '{"category":"engine","effect":"recursion"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Retrieve translated into ManaLoom runtime scope xmage_return_multiple_graveyard_cards_to_hand_exile_self_spell_v1. This row is package-ready only because the source signature is a narrow instant/sorcery spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('vivid revival', 'Vivid Revival', '9f4629b135cb2888979404fca4a71cea', 'battle_rule_v1:0eaec04572207c2751454d4b4793493b', '{"battle_model_scope":"xmage_return_target_graveyard_card_to_hand_spell_v1","count":3,"destination":"hand","effect":"recursion","exiles_self":true,"instant":false,"sorcery":true,"target":"multicolored_card","target_constraints":{"controller":"self","min_colors":2,"zone":"graveyard"},"target_controller":"self","up_to_count":true,"xmage_additional_effect_class":"ExileSpellEffect","xmage_effect_class":"ReturnFromGraveyardToHandTargetEffect"}'::jsonb, '{"category":"engine","effect":"recursion","target":"multicolored_card"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class VividRevival translated into ManaLoom runtime scope xmage_return_target_graveyard_card_to_hand_spell_v1. This row is package-ready only because the source signature is a narrow instant/sorcery spell with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
