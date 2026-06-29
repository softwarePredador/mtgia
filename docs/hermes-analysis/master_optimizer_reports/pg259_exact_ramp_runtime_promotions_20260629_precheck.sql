WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('bridgeworks battle', 'Bridgeworks Battle', 'f72144e1e19b68db322a7e3652728a9b', 'battle_rule_v1:d822fc4ce8a0850a7ee20dcee168e8f3', '{"ability_kind":"one_shot","battle_model_scope":"mdfc_green_land_pay_three_life_spell_fight_annotation_v1","effect":"ramp_permanent","land_side_add_mana":"G","land_side_pay_three_life_else_tapped":true,"mdfc_land_face":{"effect":"land","mana_produced":1,"may_pay_life_to_enter_untapped":3,"name":"Tanglespan Bridgeworks","produces":"G","type_line":"Land"},"nonmana_abilities_require_separate_scope":true,"nonmana_abilities_status":"spell_face_annotation_only","spell_face_effect":"target_creature_you_control_plus_two_fight_up_to_one_opponent_creature","spell_face_status":"annotation_only"}'::jsonb, '{"category":"manual_review","effect":"external_reference_required_manual_model"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class BridgeworksBattle mapped to family ramp_permanent; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.', 'deprecate_nonmatching_rows'),
    ('hydroelectric specimen', 'Hydroelectric Specimen', 'cf4c27ee44a0aa04dad441569e4c9203', 'battle_rule_v1:88c8f7a7f18d2171c1d200c61f47e6d4', '{"ability_kind":"triggered","battle_model_scope":"mdfc_blue_land_pay_three_life_flash_redirect_creature_annotation_v1","creature_face_power":1,"creature_face_status":"annotation_only","creature_face_toughness":4,"effect":"ramp_permanent","etb_change_single_target_instant_or_sorcery_to_self":true,"flash":true,"land_side_add_mana":"U","land_side_pay_three_life_else_tapped":true,"mdfc_land_face":{"effect":"land","mana_produced":1,"may_pay_life_to_enter_untapped":3,"name":"Hydroelectric Laboratory","produces":"U","type_line":"Land"},"nonmana_abilities_require_separate_scope":true,"nonmana_abilities_status":"creature_face_annotation_only"}'::jsonb, '{"category":"manual_review","effect":"external_reference_required_manual_model"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class HydroelectricSpecimen mapped to family ramp_permanent; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.', 'deprecate_nonmatching_rows'),
    ('selvala, heart of the wilds', 'Selvala, Heart of the Wilds', '9c71b7f70bb08d537b64303144885181', 'battle_rule_v1:1ee83f01d2315d8468be5462667233ad', '{"ability_kind":"triggered","activation_mana_cost":"{G}","activation_requires_tap":true,"another_creature_enters_greatest_power_controller_may_draw":true,"another_creature_enters_greatest_power_draw_status":"annotation_only","battle_model_scope":"greatest_power_any_color_mana_dork_etb_draw_annotation_v1","effect":"ramp_permanent","is_creature_permanent":true,"is_mana_source":true,"mana_produced_from_greatest_power_controlled_creatures":true,"permanent_type":"creature","power":2,"produces":"WUBRG","toughness":3}'::jsonb, '{"category":"manual_review","effect":"external_reference_required_manual_model"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class SelvalaHeartOfTheWilds mapped to family ramp_permanent; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.', 'deprecate_nonmatching_rows'),
    ('devoted druid', 'Devoted Druid', '7b80b28703e24676671fb1a5bcaea2a9', 'battle_rule_v1:67f97b25cf58b747257151dada64b9e4', '{"ability_kind":"activated","activated_put_minus_one_counter_untap_self":true,"activated_put_minus_one_counter_untap_self_status":"annotation_only","activation_requires_tap":true,"battle_model_scope":"green_mana_dork_minus_counter_self_untap_v1","effect":"ramp_permanent","is_creature_permanent":true,"is_mana_source":true,"mana_produced":1,"permanent_type":"creature","power":0,"produces":"G","toughness":2}'::jsonb, '{"category":"manual_review","effect":"external_reference_required_manual_model"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class DevotedDruid mapped to family ramp_permanent; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.', 'deprecate_nonmatching_rows'),
    ('birgi, god of storytelling', 'Birgi, God of Storytelling', '5f1ed696a63cd668fd46a2fe9971a54e', 'battle_rule_v1:c21762e62b990dbb474be0b5764d71a7', '{"ability_kind":"triggered","back_face_harnfel_discard_exile_two_play_this_turn":true,"back_face_status":"annotation_only","battle_model_scope":"spell_cast_red_mana_trigger_boast_harnfel_annotation_v1","boast_twice_each_turn":true,"boast_twice_status":"annotation_only","effect":"ramp_engine","is_creature_permanent":true,"mana_persists_steps":true,"power":3,"produces":"R","spell_cast_add_mana":1,"spell_cast_mana_color":"R","toughness":3,"trigger":"spell_cast"}'::jsonb, '{"category":"ramp","effect":"ramp_engine","timing":"triggered"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class BirgiGodOfStorytelling mapped to family ramp_engine; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.', 'deprecate_nonmatching_rows'),
    ('fractured powerstone', 'Fractured Powerstone', '1a17758be0a06960a735f9c6a44d98a4', 'battle_rule_v1:0e90c515e59dff042e41f45158c63e97', '{"ability_kind":"activated","activated_roll_planar_die":true,"activated_roll_planar_die_status":"annotation_only","activation_requires_tap":true,"battle_model_scope":"colorless_mana_rock_planar_die_annotation_v1","effect":"ramp_permanent","is_mana_source":true,"mana_produced":1,"permanent_type":"artifact","produces":"C"}'::jsonb, '{"category":"manual_review","effect":"external_reference_required_manual_model"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class FracturedPowerstone mapped to family ramp_permanent; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.', 'deprecate_nonmatching_rows'),
    ('incubation druid', 'Incubation Druid', '5bb72caef291ea420e5de42a141665ab', 'battle_rule_v1:de0ac6ce79a7fff3d4b1f65e91e73d0d', '{"ability_kind":"one_shot","activation_requires_tap":true,"adapt_cost":"{3}{G}{G}","adapt_counters":3,"adapt_status":"annotation_only","battle_model_scope":"land_type_mana_dork_plus_counter_triples_adapt_v1","effect":"ramp_permanent","is_creature_permanent":true,"is_mana_source":true,"mana_colors_from_controlled_lands":true,"mana_produced":1,"mana_produced_if_plus_one_counter":3,"permanent_type":"creature","power":0,"produces":"WUBRGC","toughness":2}'::jsonb, '{"category":"manual_review","effect":"external_reference_required_manual_model"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class IncubationDruid mapped to family ramp_permanent; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.', 'deprecate_nonmatching_rows'),
    ('delighted halfling', 'Delighted Halfling', 'bbc192c8c0bea94ccfeecf8ebeca107b', 'battle_rule_v1:3f0dd0a85440805f77ce47815c44214a', '{"ability_kind":"static","activation_requires_tap":true,"battle_model_scope":"colorless_or_legendary_any_color_uncounterable_mana_dork_v1","conditional_mana_modes":[{"color":"C","mode":"colorless","restriction":"any_spell","status":"runtime_executor_v1"},{"color":"W","mode":"legendary_spell_uncounterable","restriction":"legendary_spell","status":"runtime_executor_v1"},{"color":"U","mode":"legendary_spell_uncounterable","restriction":"legendary_spell","status":"runtime_executor_v1"},{"color":"B","mode":"legendary_spell_uncounterable","restriction":"legendary_spell","status":"runtime_executor_v1"},{"color":"R","mode":"legendary_spell_uncounterable","restriction":"legendary_spell","status":"runtime_executor_v1"},{"color":"G","mode":"legendary_spell_uncounterable","restriction":"legendary_spell","status":"runtime_executor_v1"}],"conditional_mana_modes_status":"runtime_executor_v1","effect":"ramp_permanent","is_creature_permanent":true,"is_mana_source":true,"legendary_mana_spent_spell_cant_be_countered":true,"legendary_mana_uncounterable_status":"annotation_only","mana_produced":1,"permanent_type":"creature","power":1,"produces":"C","toughness":2}'::jsonb, '{"category":"manual_review","effect":"external_reference_required_manual_model"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class DelightedHalfling mapped to family ramp_permanent; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.', 'deprecate_nonmatching_rows')
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
