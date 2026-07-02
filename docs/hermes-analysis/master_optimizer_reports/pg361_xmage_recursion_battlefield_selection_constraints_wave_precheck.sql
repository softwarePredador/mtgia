WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('behold the sinister six!', 'Behold the Sinister Six!', '22d23fc917885e5b22cb7b60c483756c', 'battle_rule_v1:990d3d8901fc9239d0089e0ac86bef62', '{"battle_model_scope":"xmage_return_target_graveyard_card_to_battlefield_spell_v1","battlefield_controller":"self","count":6,"destination":"battlefield","effect":"recursion","instant":false,"requires_different_names":true,"sorcery":true,"target":"creature","target_constraints":{"card_types":["creature"],"controller":"self","requires_different_names":true,"zone":"graveyard"},"target_controller":"self","target_graveyard_controller":"self","up_to_count":true,"xmage_effect_class":"ReturnFromGraveyardToBattlefieldTargetEffect"}'::jsonb, '{"category":"engine","effect":"recursion","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class BeholdTheSinisterSix translated into ManaLoom runtime scope xmage_return_target_graveyard_card_to_battlefield_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('brought back', 'Brought Back', 'af75ed7190647cd5a685e3dd34dfd3c9', 'battle_rule_v1:e054b75a3b97cc92a917e8bdecbee82c', '{"battle_model_scope":"xmage_return_target_graveyard_card_to_battlefield_spell_v1","battlefield_controller":"self","count":2,"destination":"battlefield","effect":"recursion","enters_tapped":true,"graveyard_from_battlefield_this_turn":true,"instant":true,"sorcery":false,"target":"permanent","target_constraints":{"card_types":["artifact","creature","enchantment","planeswalker","battle","land"],"controller":"self","graveyard_from_battlefield_this_turn":true,"zone":"graveyard"},"target_controller":"self","target_graveyard_controller":"self","up_to_count":true,"xmage_effect_class":"ReturnFromGraveyardToBattlefieldTargetEffect"}'::jsonb, '{"category":"engine","effect":"recursion","target":"permanent","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class BroughtBack translated into ManaLoom runtime scope xmage_return_target_graveyard_card_to_battlefield_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('continue?', 'Continue?', '6b2ab191a364b742c0e4c8d4d2957106', 'battle_rule_v1:96c134fe95bf5a8397b9f1bcd8bbc1ef', '{"battle_model_scope":"xmage_return_target_graveyard_card_to_battlefield_spell_v1","battlefield_controller":"self","count":4,"destination":"battlefield","effect":"recursion","graveyard_from_battlefield_this_turn":true,"instant":true,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"],"controller":"self","graveyard_from_battlefield_this_turn":true,"zone":"graveyard"},"target_controller":"self","target_graveyard_controller":"self","up_to_count":true,"xmage_effect_class":"ReturnFromGraveyardToBattlefieldTargetEffect"}'::jsonb, '{"category":"engine","effect":"recursion","target":"creature","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Continue translated into ManaLoom runtime scope xmage_return_target_graveyard_card_to_battlefield_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('grim return', 'Grim Return', 'cd84ad9ab549a29a67cbe1b5dae6cf75', 'battle_rule_v1:fb8c63570b73aab5f5069a1232f18e84', '{"battle_model_scope":"xmage_return_target_graveyard_card_to_battlefield_spell_v1","battlefield_controller":"self","count":1,"destination":"battlefield","effect":"recursion","graveyard_from_battlefield_this_turn":true,"instant":true,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"],"controller":"any_player","graveyard_from_battlefield_this_turn":true,"zone":"graveyard"},"target_controller":"any_player","target_graveyard_controller":"any_player","xmage_effect_class":"ReturnFromGraveyardToBattlefieldTargetEffect"}'::jsonb, '{"category":"engine","effect":"recursion","target":"creature","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class GrimReturn translated into ManaLoom runtime scope xmage_return_target_graveyard_card_to_battlefield_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('march from the tomb', 'March from the Tomb', '23140e7a4f665d8e3e6015e1103ec5b0', 'battle_rule_v1:feb5bdcf4ab012abd1490b3a8611f448', '{"battle_model_scope":"xmage_return_target_graveyard_card_to_battlefield_spell_v1","battlefield_controller":"self","count":99,"destination":"battlefield","effect":"recursion","instant":false,"recursion_total_mana_value_max":8,"sorcery":true,"target":"ally_creature","target_constraints":{"card_types":["creature"],"controller":"self","subtypes":["ally"],"total_mana_value_max":8,"zone":"graveyard"},"target_controller":"self","target_graveyard_controller":"self","up_to_count":true,"xmage_effect_class":"ReturnFromGraveyardToBattlefieldTargetEffect"}'::jsonb, '{"category":"engine","effect":"recursion","target":"ally_creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class MarchFromTheTomb translated into ManaLoom runtime scope xmage_return_target_graveyard_card_to_battlefield_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('patch up', 'Patch Up', 'c999a9d7c9e85a1656c3fe8f2dc5fc8f', 'battle_rule_v1:77e5f68e27a575e492b33361b92091fa', '{"battle_model_scope":"xmage_return_target_graveyard_card_to_battlefield_spell_v1","battlefield_controller":"self","count":3,"destination":"battlefield","effect":"recursion","instant":false,"recursion_total_mana_value_max":3,"sorcery":true,"target":"creature","target_constraints":{"card_types":["creature"],"controller":"self","total_mana_value_max":3,"zone":"graveyard"},"target_controller":"self","target_graveyard_controller":"self","up_to_count":true,"xmage_effect_class":"ReturnFromGraveyardToBattlefieldTargetEffect"}'::jsonb, '{"category":"engine","effect":"recursion","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class PatchUp translated into ManaLoom runtime scope xmage_return_target_graveyard_card_to_battlefield_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
