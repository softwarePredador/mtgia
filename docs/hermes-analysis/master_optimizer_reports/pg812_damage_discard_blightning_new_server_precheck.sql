WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('blightning', 'Blightning', '704b9b3861bd442e46bd3b1cf947982e', 'battle_rule_v1:64f43dbbf5748cf4727c28d30fdfa916', '{"_composite_rule_components":[{"amount":3,"battle_model_scope":"xmage_fixed_damage_target_spell_v1","compose_on_resolution":true,"damage":3,"effect":"direct_damage","target":"player_or_planeswalker","target_constraints":{"scope":"player_or_planeswalker"},"xmage_effect_class":"DamageTargetEffect"},{"battle_model_scope":"xmage_fixed_target_player_discard_spell_v1","compose_on_resolution":true,"count":2,"discard_count":2,"discard_random":false,"effect":"target_player_discard","target":"player","target_constraints":{"players":["any"]},"target_controller":"target_player","target_from_previous_damage":true,"target_player_discard":true,"target_preference":"previous_damage_target_controller","xmage_effect_class":"DiscardTargetEffect"}],"amount":3,"battle_model_scope":"xmage_fixed_damage_target_then_same_player_discard_spell_v1","damage":3,"discard_count":2,"discard_random":false,"effect":"composite_resolution","instant":false,"resolution_order":"damage_then_same_player_discard","sorcery":true,"target":"player_or_planeswalker","target_constraints":{"scope":"player_or_planeswalker"},"target_player_discard":true,"xmage_effect_classes":["BlightningEffect","DamageTargetEffect","DiscardTargetEffect","OneShotEffect"]}'::jsonb, '{"category":"removal","effect":"composite_resolution","subtype":"damage_discard","target":"player_or_planeswalker"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Blightning translated into ManaLoom runtime scope xmage_fixed_damage_target_then_same_player_discard_spell_v1. This row is package-ready only because the source signature is a narrow fixed damage spell with same damaged player/controller discard with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
