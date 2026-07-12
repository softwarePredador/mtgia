WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('horrifying revelation', 'Horrifying Revelation', '71078f24d81cecdc3fe4f318677a92ac', 'battle_rule_v1:c24adcab7800c426dfd2242e9d6b6e48', '{"_composite_rule_components":[{"battle_model_scope":"xmage_fixed_target_player_discard_spell_v1","compose_on_resolution":true,"count":1,"discard_count":1,"effect":"target_player_discard","target":"player","target_constraints":{"players":["any"]},"target_controller":"target_player","target_player_discard":true,"target_player_scope":"any","target_preference":"opponent","xmage_effect_class":"DiscardTargetEffect"},{"battle_model_scope":"xmage_fixed_target_player_mill_spell_v1","compose_on_resolution":true,"count":1,"effect":"mill_cards","mill_count":1,"target":"player","target_constraints":{"players":["any"]},"target_controller":"target_player","target_from_previous_discard":true,"target_player_mill":true,"target_player_scope":"any","target_preference":"previous_discard_target","xmage_effect_class":"MillCardsTargetEffect"}],"battle_model_scope":"xmage_fixed_target_player_discard_mill_spell_v1","count":1,"discard_count":1,"effect":"composite_resolution","instant":false,"mill_count":1,"resolution_order":"discard_then_mill","sorcery":true,"target":"player","target_constraints":{"players":["any"]},"target_controller":"target_player","target_player_discard":true,"target_player_mill":true,"target_player_scope":"any","target_preference":"opponent","xmage_effect_classes":["DiscardTargetEffect","MillCardsTargetEffect"]}'::jsonb, '{"category":"draw","effect":"composite_resolution","target":"player"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class HorrifyingRevelation translated into ManaLoom runtime scope xmage_fixed_target_player_discard_mill_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
