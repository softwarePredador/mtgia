WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes) AS (
  VALUES
    ('mystic remora', 'Mystic Remora', '05eb27f7618511c39512cf5a6d93231d', 'battle_rule_v1:91908863a3c983e6d30a2ff99cf41fdb', '{"ability_kind":"triggered","battle_model_scope":"opponent_noncreature_spell_pay_four_draw_engine_with_cumulative_upkeep_v1","cumulative_upkeep_generic":1,"draw_on_enter":false,"effect":"draw_engine","tax":4,"trigger":"opponent_noncreature_spell"}'::jsonb, '{"category":"draw","effect":"draw_engine","timing":"static_or_activated"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class MysticRemora mapped to family draw_engine; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.'),
    ('rhystic study', 'Rhystic Study', 'f745d1b0ae8acc8c593efb5b3e36ae97', 'battle_rule_v1:79b27c9590580c68ac39779ee48644e9', '{"ability_kind":"triggered","battle_model_scope":"opponent_spell_pay_one_or_draw_engine_v1","draw_on_enter":false,"effect":"draw_engine","tax":1,"trigger":"opponent_spell"}'::jsonb, '{"category":"draw","effect":"draw_engine","timing":"static_or_activated"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class RhysticStudy mapped to family draw_engine; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.'),
    ('crop rotation', 'Crop Rotation', '67869230ccb8b4499893e14915ca8b14', 'battle_rule_v1:bdce68609ebf3349f35a5e81b6bb2e22', '{"ability_kind":"one_shot","battle_model_scope":"sacrifice_land_for_any_land_to_battlefield_untapped_v1","effect":"land_ramp","instant":true,"land_count":1,"land_enters_tapped":false,"lands_to_battlefield":1,"requires_sacrifice_land":true,"tutor_target":"land"}'::jsonb, '{"category":"manual_review","effect":"external_reference_required_manual_model"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class CropRotation mapped to family land_ramp; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.'),
    ('elvish reclaimer', 'Elvish Reclaimer', 'dfd0be9a38fadd0931f1c0f6f06aba74', 'battle_rule_v1:a702be88d777164eaa496746ae78bae2', '{"ability_kind":"activated","activation_cost_generic":2,"activation_requires_tap":true,"battle_model_scope":"activated_land_tutor_with_land_sacrifice_and_graveyard_growth_v1","effect":"creature","land_count":1,"land_enters_tapped":true,"land_tutor_activated":true,"lands_to_battlefield":1,"plus_two_two_if_three_lands_in_your_graveyard":true,"power":1,"requires_sacrifice_land":true,"toughness":2,"tutor_target":"land"}'::jsonb, '{"category":"board_presence","effect":"creature","timing":"battlefield"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class ElvishReclaimer mapped to family creature; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.')
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
