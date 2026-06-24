WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes) AS (
  VALUES
    ('into the flood maw', 'Into the Flood Maw', '933b432b00f3ba798aa68a96ae301199', 'battle_rule_v1:cab6dca71d1d5e86c85ef5f8089f1648', '{"ability_kind":"one_shot","battle_model_scope":"gift_bounce_opponent_creature_or_nonland_v1","effect":"bounce","gift_promised_target":"opponent_nonland_permanent","gift_tapped_fish":true,"instant":true,"target":"opponent_creature"}'::jsonb, '{"category":"interaction","effect":"targeted_interaction","timing":"resolution"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class IntoTheFloodMaw mapped to family targeted_interaction; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.'),
    ('snap', 'Snap', '2b6f112205366b8884ae4af9cb129827', 'battle_rule_v1:98961b0f9243bcc73308c30365ad835c', '{"ability_kind":"one_shot","battle_model_scope":"return_target_creature_then_untap_up_to_two_lands_v1","effect":"bounce","instant":true,"target":"creature","untap_lands_count":2}'::jsonb, '{"category":"interaction","effect":"targeted_interaction","timing":"resolution"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class Snap mapped to family targeted_interaction; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.'),
    ('walking ballista', 'Walking Ballista', 'fe0669ba2732ea2399168950556378ec', 'battle_rule_v1:cc7e65cfa812dc06a42f853773180ca1', '{"ability_kind":"activated","activated_generic_four_add_plus_one_counter":1,"activated_remove_plus_one_counter_damage_any_target":1,"battle_model_scope":"x_etb_counters_add_counter_or_remove_counter_ping_v1","effect":"creature","enters_with_x_plus_one_counters":true,"power":0,"toughness":0}'::jsonb, '{"category":"manual_review","effect":"external_reference_required_manual_model"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class WalkingBallista mapped to family manual_model; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.'),
    ('everflowing chalice', 'Everflowing Chalice', '2916ac287962232283ac7b1dbe684b7d', 'battle_rule_v1:b1b7f5c96002524c469ae4efa7f7bf71', '{"ability_kind":"one_shot","battle_model_scope":"multikicker_charge_counter_mana_rock_v1","effect":"artifact","etb_charge_counters_per_kick":true,"multikicker_cost":"{2}","tap_add_colorless_per_charge_counter":true}'::jsonb, '{"category":"manual_review","effect":"external_reference_required_manual_model"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class EverflowingChalice mapped to family manual_model; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.'),
    ('manamorphose', 'Manamorphose', 'b503154ebcc4ece0544e5b2aa6c9c63c', 'battle_rule_v1:92f71fffeac9247368bb3fa7518ba19c', '{"ability_kind":"one_shot","add_mana_any_combination":2,"battle_model_scope":"add_two_mana_any_combination_then_draw_v1","count":1,"effect":"draw_cards","instant":true}'::jsonb, '{"category":"interaction","effect":"targeted_interaction","timing":"resolution"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class Manamorphose mapped to family targeted_interaction; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.'),
    ('tinder wall', 'Tinder Wall', 'e604ec678cf1ef5437418b9a5f1f3888', 'battle_rule_v1:af96afc668607664ff18de6e8c51a1b0', '{"ability_kind":"activated","battle_model_scope":"defender_sacrifice_for_rr_or_blocking_damage_v1","defender":true,"effect":"creature","power":0,"red_sacrifice_damage_blocking_creature":2,"sacrifice_for_red_mana":2,"toughness":3}'::jsonb, '{"category":"manual_review","effect":"external_reference_required_manual_model"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class TinderWall mapped to family manual_model; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.')
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
    ON lower(c.name) = p.normalized_name
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
    ON r.normalized_name = p.normalized_name
  GROUP BY p.normalized_name
),
expected_rows AS (
  SELECT p.normalized_name, count(r.*) AS expected_rule_rows_before
  FROM proposed p
  LEFT JOIN public.card_battle_rules r
    ON r.normalized_name = p.normalized_name
   AND r.logical_rule_key = p.logical_rule_key
  GROUP BY p.normalized_name
),
shadow_rows AS (
  SELECT p.normalized_name, count(r.*) AS would_deprecate_shadow_rows
  FROM proposed p
  LEFT JOIN public.card_battle_rules r
    ON r.normalized_name = p.normalized_name
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
