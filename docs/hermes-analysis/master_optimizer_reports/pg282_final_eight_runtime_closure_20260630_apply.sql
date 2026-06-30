BEGIN;

CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit;

CREATE TABLE manaloom_deploy_audit.pg282_final_eight_runtime_closure_20260630_20260630_1558 AS
SELECT *
FROM public.card_battle_rules
WHERE normalized_name IN ('blood moon', 'karn, the great creator', 'chandra''s ignition', 'karn''s sylex', 'naktamun lorespinner // wheel of fortune', 'charmbreaker devils', 'ancient gold dragon', 'deathbellow war cry')
   OR normalized_name LIKE 'blood moon // %'
   OR normalized_name LIKE 'karn, the great creator // %'
   OR normalized_name LIKE 'chandra''s ignition // %'
   OR normalized_name LIKE 'karn''s sylex // %'
   OR normalized_name LIKE 'naktamun lorespinner // wheel of fortune // %'
   OR normalized_name LIKE 'charmbreaker devils // %'
   OR normalized_name LIKE 'ancient gold dragon // %'
   OR normalized_name LIKE 'deathbellow war cry // %';

DO $$
DECLARE
  v_missing jsonb;
BEGIN
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
  counts AS (
    SELECT
      p.card_name,
      p.normalized_name,
      p.oracle_hash,
      count(c.id) AS target_card_rows,
      min(c.id::text)::uuid AS canonical_card_id
    FROM proposed p
    LEFT JOIN public.cards c
      ON (
           lower(c.name) = p.normalized_name
           OR split_part(lower(c.name), ' // ', 1) = p.normalized_name
         )
     AND md5(coalesce(c.oracle_text, '')) = p.oracle_hash
    GROUP BY p.card_name, p.normalized_name, p.oracle_hash
  )
  SELECT jsonb_agg(counts ORDER BY card_name)
    INTO v_missing
  FROM counts
  WHERE target_card_rows < 1;

  IF v_missing IS NOT NULL THEN
    RAISE EXCEPTION 'XMage batch package abort: expected at least one Oracle-hash-matched card row for every proposed card: %', v_missing;
  END IF;
END $$;

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
deprecated AS (
  UPDATE public.card_battle_rules r
  SET
    review_status = 'deprecated',
    execution_status = 'disabled',
    updated_at = now(),
    notes = concat_ws(E'\n', nullif(r.notes, ''), 'XMage batch package: deprecated stale shadow before curated batch rule upsert.')
  FROM proposed p
  WHERE (
        r.normalized_name = p.normalized_name
        OR r.normalized_name LIKE p.normalized_name || ' // %'
      )
    AND p.shadow_handling <> 'preserve_existing_rows'
    AND r.logical_rule_key <> p.logical_rule_key
  RETURNING r.*
)
SELECT count(*) AS deprecated_shadow_rows FROM deprecated;

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
  JOIN public.cards c
    ON (
         lower(c.name) = p.normalized_name
         OR split_part(lower(c.name), ' // ', 1) = p.normalized_name
       )
   AND md5(coalesce(c.oracle_text, '')) = p.oracle_hash
),
canonical_target_cards AS (
  SELECT
    p.*,
    min(m.card_id::text)::uuid AS card_id,
    min(m.db_card_name) AS db_card_name
  FROM proposed p
  JOIN matched_cards m
    USING (normalized_name, card_name, oracle_hash)
  GROUP BY
    p.normalized_name,
    p.card_name,
    p.oracle_hash,
    p.logical_rule_key,
    p.effect_json,
    p.deck_role_json,
    p.source,
    p.confidence,
    p.review_status,
    p.execution_status,
    p.notes,
    p.shadow_handling
),
upserted AS (
  INSERT INTO public.card_battle_rules (
    normalized_name,
    card_id,
    card_name,
    effect_json,
    deck_role_json,
    source,
    confidence,
    review_status,
    rule_version,
    oracle_hash,
    notes,
    reviewed_by,
    reviewed_at,
    created_at,
    updated_at,
    last_seen_at,
    logical_rule_key,
    execution_status
  )
  SELECT
    normalized_name,
    card_id,
    db_card_name,
    effect_json,
    deck_role_json,
    source,
    confidence,
    review_status,
    2,
    oracle_hash,
    notes,
    'codex-xmage-batch',
    now(),
    now(),
    now(),
    now(),
    logical_rule_key,
    execution_status
  FROM canonical_target_cards
  ON CONFLICT (normalized_name, logical_rule_key) DO UPDATE
  SET
    card_id = EXCLUDED.card_id,
    card_name = EXCLUDED.card_name,
    effect_json = EXCLUDED.effect_json,
    deck_role_json = EXCLUDED.deck_role_json,
    source = EXCLUDED.source,
    confidence = EXCLUDED.confidence,
    review_status = EXCLUDED.review_status,
    rule_version = EXCLUDED.rule_version,
    oracle_hash = EXCLUDED.oracle_hash,
    notes = EXCLUDED.notes,
    reviewed_by = EXCLUDED.reviewed_by,
    reviewed_at = EXCLUDED.reviewed_at,
    updated_at = EXCLUDED.updated_at,
    last_seen_at = EXCLUDED.last_seen_at,
    execution_status = EXCLUDED.execution_status
  RETURNING *
)
SELECT count(*) AS upserted_rows FROM upserted;

COMMIT;
