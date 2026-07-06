WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('forbidden alchemy', 'Forbidden Alchemy', '4800d22353040527a3f8a9ddaaa3529f', 'battle_rule_v1:e285a4ed5ba76a8a0a9def976a43b0a0', '{"battle_model_scope":"xmage_look_library_pick_to_hand_rest_graveyard_spell_v1","count":1,"destination":"hand","effect":"dig_to_hand","instant":true,"look_count":4,"max_count":1,"pick_all_matching":false,"pick_count":1,"pick_target":"any_card","pick_up_to_count":false,"rest_destination":"graveyard","reveal":false,"sorcery":false,"target":"any_card","target_constraints":{"controller":"self","scope":"any_card","zone":"library"},"xmage_effect_class":"LookLibraryAndPickControllerEffect"}'::jsonb, '{"category":"draw","effect":"dig_to_hand","target":"any_card","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ForbiddenAlchemy translated into ManaLoom runtime scope xmage_look_library_pick_to_hand_rest_graveyard_spell_v1. This row is package-ready only because the source signature is a narrow fixed look-at-library pick-to-hand spell with rest in graveyard with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('nagging thoughts', 'Nagging Thoughts', 'd750ade2afb400a96ed4d09a6de448ed', 'battle_rule_v1:0c0c6b5f5d6ac1b30757c2c3d4794c24', '{"battle_model_scope":"xmage_look_library_pick_to_hand_rest_graveyard_spell_v1","count":1,"destination":"hand","effect":"dig_to_hand","instant":false,"look_count":2,"max_count":1,"pick_all_matching":false,"pick_count":1,"pick_target":"any_card","pick_up_to_count":false,"rest_destination":"graveyard","reveal":false,"sorcery":true,"target":"any_card","target_constraints":{"controller":"self","scope":"any_card","zone":"library"},"xmage_effect_class":"LookLibraryAndPickControllerEffect"}'::jsonb, '{"category":"draw","effect":"dig_to_hand","target":"any_card"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class NaggingThoughts translated into ManaLoom runtime scope xmage_look_library_pick_to_hand_rest_graveyard_spell_v1. This row is package-ready only because the source signature is a narrow fixed look-at-library pick-to-hand spell with rest in graveyard with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('resentful revelation', 'Resentful Revelation', 'c0c873de2a6cb009f2bb3f0e304d6805', 'battle_rule_v1:818eec9a981f612634bc818b78997e22', '{"battle_model_scope":"xmage_look_library_pick_to_hand_rest_graveyard_spell_v1","count":1,"destination":"hand","effect":"dig_to_hand","instant":false,"look_count":3,"max_count":1,"pick_all_matching":false,"pick_count":1,"pick_target":"any_card","pick_up_to_count":false,"rest_destination":"graveyard","reveal":false,"sorcery":true,"target":"any_card","target_constraints":{"controller":"self","scope":"any_card","zone":"library"},"xmage_effect_class":"LookLibraryAndPickControllerEffect"}'::jsonb, '{"category":"draw","effect":"dig_to_hand","target":"any_card"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ResentfulRevelation translated into ManaLoom runtime scope xmage_look_library_pick_to_hand_rest_graveyard_spell_v1. This row is package-ready only because the source signature is a narrow fixed look-at-library pick-to-hand spell with rest in graveyard with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('tapping at the window', 'Tapping at the Window', 'c85b98ff679c3eac0187834661613f50', 'battle_rule_v1:f81c5a7e4a1474b2f585b16efca99840', '{"battle_model_scope":"xmage_look_library_pick_to_hand_rest_graveyard_spell_v1","count":1,"destination":"hand","effect":"dig_to_hand","instant":false,"look_count":3,"max_count":1,"pick_all_matching":false,"pick_count":1,"pick_target":"creature","pick_up_to_count":true,"rest_destination":"graveyard","reveal":true,"sorcery":true,"target":"creature","target_constraints":{"card_types":["creature"],"controller":"self","zone":"library"},"xmage_effect_class":"LookLibraryAndPickControllerEffect"}'::jsonb, '{"category":"draw","effect":"dig_to_hand","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class TappingAtTheWindow translated into ManaLoom runtime scope xmage_look_library_pick_to_hand_rest_graveyard_spell_v1. This row is package-ready only because the source signature is a narrow fixed look-at-library pick-to-hand spell with rest in graveyard with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
