WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('blood moon', 'Blood Moon', 'f9b52f264dbb36074c8c151ad47331cb', 'battle_rule_v1:544a658a2c0bc182ebfeb88ace95dc64', '{"ability_kind":"static","affected_lands":"nonbasic","battle_model_scope":"nonbasic_lands_are_mountains_static_v1","cmc":3.0,"colors":["R"],"effect":"passive","land_type_replacement":"nonbasic_lands_are_mountains","mana_cost":"{2}{R}","resulting_basic_land_type":"mountain","static_rule_restriction":true,"suppresses_non_mountain_land_abilities":true,"type_line":"Enchantment"}'::jsonb, '{"category":"meta_pressure_answers","effect":"passive","subtype":"nonbasic_land_lock","timing":"static"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'Final-eight Lorehold runtime closure: exact XMage-derived scope nonbasic_lands_are_mountains_static_v1; focused runtime test test_lorehold_runtime_gap_final_eight.py passed before package generation.', 'deprecate_nonmatching_rows'),
    ('karn, the great creator', 'Karn, the Great Creator', 'a4fd549768b5cfea5234949fafd74bb2', 'battle_rule_v1:3f1aee80d7b0907758d8bc481ff354dd', '{"ability_kind":"static_and_loyalty","battle_model_scope":"opponent_artifact_activation_lock_planeswalker_wish_v1","cmc":4.0,"colors":[],"effect":"planeswalker","mana_cost":"{4}","minus_two_artifact_wish_or_exile_to_hand":true,"opponent_artifact_activated_abilities_cant_be_activated":true,"permanent_type":"planeswalker","plus_one_animates_noncreature_artifact_until_next_turn":true,"starting_loyalty":5,"type_line":"Legendary Planeswalker - Karn"}'::jsonb, '{"category":"interaction","effect":"planeswalker","subtype":"artifact_activation_lock_and_wish","timing":"static_and_loyalty"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'Final-eight Lorehold runtime closure: exact XMage-derived scope opponent_artifact_activation_lock_planeswalker_wish_v1; focused runtime test test_lorehold_runtime_gap_final_eight.py passed before package generation.', 'deprecate_nonmatching_rows'),
    ('chandra''s ignition', 'Chandra''s Ignition', '92b36154e7e9f9a2fd8abd64d5f9c032', 'battle_rule_v1:927b4d7b6092717afd3999ce110288c7', '{"ability_kind":"one_shot","battle_model_scope":"target_controlled_creature_power_damage_each_other_creature_each_opponent_v1","cmc":5.0,"colors":["R"],"damage_amount_source":"target_creature_power","damage_each_opponent":true,"damage_each_other_creature":true,"damage_source":"target_creature","effect":"sweeper_damage","mana_cost":"{3}{R}{R}","sorcery":true,"target":"controlled_creature","type_line":"Sorcery"}'::jsonb, '{"category":"wipe","effect":"sweeper_damage","subtype":"controlled_creature_power_sweeper","target":"controlled_creature","timing":"sorcery"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'Final-eight Lorehold runtime closure: exact XMage-derived scope target_controlled_creature_power_damage_each_other_creature_each_opponent_v1; focused runtime test test_lorehold_runtime_gap_final_eight.py passed before package generation.', 'deprecate_nonmatching_rows'),
    ('karn''s sylex', 'Karn''s Sylex', '52e66b340c048462a512fb6874942f98', 'battle_rule_v1:234a67623cf5f551456e5af380b7e464', '{"ability_kind":"static_and_activated","activated_destroy_nonland_permanents_mana_value_x_or_less":true,"activation_exiles_source":true,"activation_only_as_sorcery":true,"activation_requires_tap":true,"artifact":true,"battle_model_scope":"legendary_artifact_tapped_life_payment_lock_x_tap_exile_destroy_nonland_mv_lte_x_v1","cmc":3.0,"colors":[],"effect":"passive","enters_battlefield_tapped":true,"legendary":true,"mana_cost":"{3}","players_cant_pay_life_to_cast_spells_or_nonmana_abilities":true,"type_line":"Legendary Artifact"}'::jsonb, '{"category":"wipe","effect":"passive","subtype":"x_value_nonland_permanent_wipe_and_life_payment_lock","timing":"static_and_activated"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'Final-eight Lorehold runtime closure: exact XMage-derived scope legendary_artifact_tapped_life_payment_lock_x_tap_exile_destroy_nonland_mv_lte_x_v1; focused runtime test test_lorehold_runtime_gap_final_eight.py passed before package generation.', 'deprecate_nonmatching_rows'),
    ('naktamun lorespinner // wheel of fortune', 'Naktamun Lorespinner // Wheel of Fortune', '17a8d82c246b858c8e7b5b3866515485', 'battle_rule_v1:dde68502ffffad4ca85e2200c71ef578', '{"ability_kind":"prepare_spell","battle_model_scope":"prepare_upkeep_any_player_one_or_fewer_hand_wheel_face_v1","cmc":3.0,"colors":["R"],"effect":"creature","is_creature_permanent":true,"mana_cost":"{2}{R}","power":3,"prepared_spell_face":{"discard_draw_model":"each_player_discard_hand_draw_seven_v1","draw_count":7,"effect":"draw_cards","mana_cost":"{2}{R}","name":"Wheel of Fortune","sorcery":true,"wheel_like":true},"subtypes":["Jackal","Wizard"],"toughness":3,"type_line":"Creature - Jackal Wizard","upkeep_prepare_if_any_player_hand_size_lte":1}'::jsonb, '{"category":"draw","effect":"creature","subtype":"upkeep_prepare_wheel_face","timing":"upkeep_and_sorcery"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'Final-eight Lorehold runtime closure: exact XMage-derived scope prepare_upkeep_any_player_one_or_fewer_hand_wheel_face_v1; focused runtime test test_lorehold_runtime_gap_final_eight.py passed before package generation.', 'deprecate_nonmatching_rows'),
    ('charmbreaker devils', 'Charmbreaker Devils', '84e84ddacde81b208e8b5cd06b87e10e', 'battle_rule_v1:7cd637dd06467a81cf10a2e2f6563857', '{"ability_kind":"triggered","battle_model_scope":"upkeep_random_instant_sorcery_graveyard_to_hand_instant_sorcery_cast_plus4_v1","cmc":6.0,"colors":["R"],"effect":"creature","is_creature_permanent":true,"mana_cost":"{5}{R}","power":4,"subtypes":["Devil"],"toughness":4,"trigger":"instant_sorcery_cast","trigger_effect":"boost_source_until_eot","trigger_power_bonus_until_eot":4,"trigger_toughness_bonus_until_eot":0,"type_line":"Creature - Devil","upkeep_return_random_instant_sorcery_from_graveyard_to_hand":true}'::jsonb, '{"category":"engine","effect":"creature","subtype":"graveyard_spell_recursion_and_cast_pump","timing":"upkeep_and_spell_cast"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'Final-eight Lorehold runtime closure: exact XMage-derived scope upkeep_random_instant_sorcery_graveyard_to_hand_instant_sorcery_cast_plus4_v1; focused runtime test test_lorehold_runtime_gap_final_eight.py passed before package generation.', 'deprecate_nonmatching_rows'),
    ('ancient gold dragon', 'Ancient Gold Dragon', '4ee7da13b4db1902895c7523fb04fdd2', 'battle_rule_v1:487b66416c2c3eeedf8ddcc215de21e2', '{"ability_kind":"triggered","battle_model_scope":"source_combat_damage_player_roll_d20_create_faerie_dragon_tokens_equal_result_v1","cmc":7.0,"colors":["W"],"die_sides":20,"effect":"token_maker","flying":true,"is_creature_permanent":true,"mana_cost":"{5}{W}{W}","power":7,"subtypes":["Elder","Dragon"],"token_colors":["U"],"token_count_source":"d20_result","token_flying":true,"token_name":"Faerie Dragon Token","token_power":1,"token_subtype":"Faerie Dragon","token_toughness":1,"toughness":10,"trigger":"combat_damage_to_player","trigger_source_deals_combat_damage_to_player":true,"type_line":"Creature - Elder Dragon"}'::jsonb, '{"category":"wincon","effect":"token_maker","subtype":"combat_damage_d20_faerie_dragon_tokens","timing":"combat_damage_trigger"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'Final-eight Lorehold runtime closure: exact XMage-derived scope source_combat_damage_player_roll_d20_create_faerie_dragon_tokens_equal_result_v1; focused runtime test test_lorehold_runtime_gap_final_eight.py passed before package generation.', 'deprecate_nonmatching_rows'),
    ('deathbellow war cry', 'Deathbellow War Cry', 'eecf73eadb40281bfa698aeaa1ca6294', 'battle_rule_v1:5c5d2824b29526e5fac573ed337ca7f4', '{"ability_kind":"one_shot","battle_model_scope":"up_to_four_different_name_minotaur_creatures_to_battlefield_v1","cmc":8.0,"colors":["R"],"effect":"tutor","mana_cost":"{5}{R}{R}{R}","max_targets":4,"min_targets":0,"requires_different_names":true,"shuffle_after_tutor":true,"sorcery":true,"target":"minotaur_creatures_to_battlefield","target_card_types":["creature"],"target_subtypes":["minotaur"],"tutor_destination":"battlefield","type_line":"Sorcery"}'::jsonb, '{"category":"tutor","effect":"tutor","subtype":"minotaur_creatures_to_battlefield","target":"minotaur_creatures_to_battlefield","timing":"sorcery"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'Final-eight Lorehold runtime closure: exact XMage-derived scope up_to_four_different_name_minotaur_creatures_to_battlefield_v1; focused runtime test test_lorehold_runtime_gap_final_eight.py passed before package generation.', 'deprecate_nonmatching_rows')
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
