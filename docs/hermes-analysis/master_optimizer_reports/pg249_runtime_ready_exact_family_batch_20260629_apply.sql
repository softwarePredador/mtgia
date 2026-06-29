BEGIN;

CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit;

CREATE TABLE manaloom_deploy_audit.pg249_runtime_ready_exact_family_batch_20260629_143348 AS
SELECT *
FROM public.card_battle_rules
WHERE normalized_name IN ('verge rangers', 'firesong and sunspeaker', 'goliath daydreamer', 'boros reckoner', 'terror of the peaks', 'balefire liege', 'repercussion')
   OR normalized_name LIKE 'verge rangers // %'
   OR normalized_name LIKE 'firesong and sunspeaker // %'
   OR normalized_name LIKE 'goliath daydreamer // %'
   OR normalized_name LIKE 'boros reckoner // %'
   OR normalized_name LIKE 'terror of the peaks // %'
   OR normalized_name LIKE 'balefire liege // %'
   OR normalized_name LIKE 'repercussion // %';

DO $$
DECLARE
  v_missing jsonb;
BEGIN
  WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('verge rangers', 'Verge Rangers', '44aa2eeb2eeb517fb30478aec7cec42f', 'battle_rule_v1:9cbcc91673241a282f321ffb94963ca1', '{"ability_kind":"static","battle_model_scope":"look_top_library_play_lands_from_top_if_opponent_more_lands_v1","effect":"topdeck_play","keywords":["first_strike"],"look_top_library_any_time":true,"play_from_top_condition":"opponent_controls_more_lands","play_lands_from_top_library":true,"power":3,"toughness":3}'::jsonb, '{"category":"ramp","effect":"topdeck_play","subtype":"play_lands_from_library","timing":"static"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class VergeRangers mapped to family topdeck_play; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.', 'deprecate_nonmatching_rows'),
    ('firesong and sunspeaker', 'Firesong and Sunspeaker', '834cfb8f0f869e7e9b4bc5342ad63046', 'battle_rule_v1:f6858198cb699117df42e073abcee357', '{"ability_kind":"triggered","battle_model_scope":"red_instant_sorcery_lifelink_white_lifegain_damage_v1","effect":"creature","instant_sorcery_lifelink_colors":["R"],"instant_sorcery_spells_you_control_have_lifelink":true,"power":4,"target":"any_target","target_constraints":{"scope":"any_target"},"toughness":6,"trigger":"white_instant_sorcery_lifegain","trigger_effect":"damage_any_target","white_instant_sorcery_lifegain_trigger_damage":3}'::jsonb, '{"category":"burn_lifegain_engine","effect":"instant_sorcery_lifelink_lifegain_damage","subtype":"red_spell_lifelink_white_spell_lifegain_damage","timing":"static_and_triggered"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class FiresongAndSunspeaker mapped to family targeted_interaction; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.', 'deprecate_nonmatching_rows'),
    ('goliath daydreamer', 'Goliath Daydreamer', '715d2c178b304a7c5e6beed655883851', 'battle_rule_v1:65521ad249354a62c78b7c29ab866ecd', '{"ability_kind":"triggered","attack_free_cast_counter_type":"dream","attack_may_cast_owned_exiled_card_with_counter_without_paying_mana":true,"battle_model_scope":"instant_sorcery_from_hand_exile_dream_counter_attack_free_cast_v1","effect":"free_cast","exiled_counter_type":"dream","power":4,"spell_cast_from_hand_card_types":["instant","sorcery"],"spell_cast_from_hand_exile_instead_of_graveyard":true,"toughness":4,"trigger":"instant_sorcery_cast_from_hand_and_attack"}'::jsonb, '{"category":"combo_value","effect":"free_cast","subtype":"cast_without_paying_mana","timing":"triggered_or_resolution"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class GoliathDaydreamer mapped to family free_cast; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.', 'deprecate_nonmatching_rows'),
    ('boros reckoner', 'Boros Reckoner', '8cb6c980428b2501343f3f38dc686efb', 'battle_rule_v1:f344d0f95f1afcd03e9b0d840981aeef', '{"ability_kind":"triggered","activated_gain_first_strike_until_eot":true,"battle_model_scope":"source_dealt_damage_reflect_to_any_target_v1","damage_amount_source":"damage_dealt_to_source","effect":"creature","first_strike_activation_cost":"{R/W}","power":3,"source_damage_reflect_to_any_target":true,"target":"any_target","target_constraints":{"scope":"any_target"},"toughness":3,"trigger":"source_dealt_damage","trigger_effect":"damage_any_target"}'::jsonb, '{"category":"burn_engine","effect":"damage_reflection","subtype":"source_damaged_reflect_any_target","timing":"triggered"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class BorosReckoner mapped to family targeted_interaction; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.', 'deprecate_nonmatching_rows'),
    ('terror of the peaks', 'Terror of the Peaks', '90c007ac59cdd400f58e89c47d81440e', 'battle_rule_v1:ae8cab02963098960997301b3c227a80', '{"ability_kind":"triggered","battle_model_scope":"controlled_other_creature_enters_power_damage_any_target_v1","effect":"creature","flying":true,"opponent_spells_targeting_this_additional_life_cost":3,"power":5,"target":"any_target","target_constraints":{"scope":"any_target"},"toughness":4,"trigger":"creature_you_control_enters","trigger_another_creature_you_control_enters":true,"trigger_damage_amount_source":"entering_creature_power","trigger_effect":"damage_any_target"}'::jsonb, '{"category":"burn_engine","effect":"etb_power_damage","subtype":"controlled_creature_enters_power_damage_any_target","timing":"triggered"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class TerrorOfThePeaks mapped to family targeted_interaction; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.', 'deprecate_nonmatching_rows'),
    ('balefire liege', 'Balefire Liege', '467dd11263f2854e2d9fc487a127ced6', 'battle_rule_v1:23affc042720e62b237989441a5e1b0e', '{"ability_kind":"triggered","battle_model_scope":"red_spell_damage_white_spell_lifegain_static_creature_boost_v1","effect":"creature","power":2,"red_spell_trigger_damage":3,"red_spell_trigger_damage_target":"player_or_planeswalker","static_boost_other_red_creatures_you_control":{"power":1,"toughness":1},"static_boost_other_white_creatures_you_control":{"power":1,"toughness":1},"toughness":4,"trigger":"spell_cast","trigger_effect":"spell_color_damage_life","white_spell_trigger_gain_life":3}'::jsonb, '{"category":"burn_lifegain_engine","effect":"spell_color_damage_life","subtype":"red_spell_damage_white_spell_lifegain","timing":"static_and_triggered"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class BalefireLiege mapped to family targeted_interaction; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.', 'deprecate_nonmatching_rows'),
    ('repercussion', 'Repercussion', '8e1ed4f8063ab89dd8906878a6232862', 'battle_rule_v1:a6fe56dcf8e3e5f3ef4ae8d9ae83e73f', '{"ability_kind":"triggered","battle_model_scope":"creature_damage_controller_reflect_global_v1","damage_amount_source":"damage_dealt_to_creature","effect":"direct_damage","global_creature_damage_reflect_to_controller":true,"trigger":"creature_dealt_damage","trigger_effect":"damage_creature_controller"}'::jsonb, '{"category":"burn_engine","effect":"damage_reflection","subtype":"creature_damage_controller_reflect","timing":"triggered"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class Repercussion mapped to family targeted_interaction; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.', 'deprecate_nonmatching_rows')
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
    ('verge rangers', 'Verge Rangers', '44aa2eeb2eeb517fb30478aec7cec42f', 'battle_rule_v1:9cbcc91673241a282f321ffb94963ca1', '{"ability_kind":"static","battle_model_scope":"look_top_library_play_lands_from_top_if_opponent_more_lands_v1","effect":"topdeck_play","keywords":["first_strike"],"look_top_library_any_time":true,"play_from_top_condition":"opponent_controls_more_lands","play_lands_from_top_library":true,"power":3,"toughness":3}'::jsonb, '{"category":"ramp","effect":"topdeck_play","subtype":"play_lands_from_library","timing":"static"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class VergeRangers mapped to family topdeck_play; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.', 'deprecate_nonmatching_rows'),
    ('firesong and sunspeaker', 'Firesong and Sunspeaker', '834cfb8f0f869e7e9b4bc5342ad63046', 'battle_rule_v1:f6858198cb699117df42e073abcee357', '{"ability_kind":"triggered","battle_model_scope":"red_instant_sorcery_lifelink_white_lifegain_damage_v1","effect":"creature","instant_sorcery_lifelink_colors":["R"],"instant_sorcery_spells_you_control_have_lifelink":true,"power":4,"target":"any_target","target_constraints":{"scope":"any_target"},"toughness":6,"trigger":"white_instant_sorcery_lifegain","trigger_effect":"damage_any_target","white_instant_sorcery_lifegain_trigger_damage":3}'::jsonb, '{"category":"burn_lifegain_engine","effect":"instant_sorcery_lifelink_lifegain_damage","subtype":"red_spell_lifelink_white_spell_lifegain_damage","timing":"static_and_triggered"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class FiresongAndSunspeaker mapped to family targeted_interaction; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.', 'deprecate_nonmatching_rows'),
    ('goliath daydreamer', 'Goliath Daydreamer', '715d2c178b304a7c5e6beed655883851', 'battle_rule_v1:65521ad249354a62c78b7c29ab866ecd', '{"ability_kind":"triggered","attack_free_cast_counter_type":"dream","attack_may_cast_owned_exiled_card_with_counter_without_paying_mana":true,"battle_model_scope":"instant_sorcery_from_hand_exile_dream_counter_attack_free_cast_v1","effect":"free_cast","exiled_counter_type":"dream","power":4,"spell_cast_from_hand_card_types":["instant","sorcery"],"spell_cast_from_hand_exile_instead_of_graveyard":true,"toughness":4,"trigger":"instant_sorcery_cast_from_hand_and_attack"}'::jsonb, '{"category":"combo_value","effect":"free_cast","subtype":"cast_without_paying_mana","timing":"triggered_or_resolution"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class GoliathDaydreamer mapped to family free_cast; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.', 'deprecate_nonmatching_rows'),
    ('boros reckoner', 'Boros Reckoner', '8cb6c980428b2501343f3f38dc686efb', 'battle_rule_v1:f344d0f95f1afcd03e9b0d840981aeef', '{"ability_kind":"triggered","activated_gain_first_strike_until_eot":true,"battle_model_scope":"source_dealt_damage_reflect_to_any_target_v1","damage_amount_source":"damage_dealt_to_source","effect":"creature","first_strike_activation_cost":"{R/W}","power":3,"source_damage_reflect_to_any_target":true,"target":"any_target","target_constraints":{"scope":"any_target"},"toughness":3,"trigger":"source_dealt_damage","trigger_effect":"damage_any_target"}'::jsonb, '{"category":"burn_engine","effect":"damage_reflection","subtype":"source_damaged_reflect_any_target","timing":"triggered"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class BorosReckoner mapped to family targeted_interaction; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.', 'deprecate_nonmatching_rows'),
    ('terror of the peaks', 'Terror of the Peaks', '90c007ac59cdd400f58e89c47d81440e', 'battle_rule_v1:ae8cab02963098960997301b3c227a80', '{"ability_kind":"triggered","battle_model_scope":"controlled_other_creature_enters_power_damage_any_target_v1","effect":"creature","flying":true,"opponent_spells_targeting_this_additional_life_cost":3,"power":5,"target":"any_target","target_constraints":{"scope":"any_target"},"toughness":4,"trigger":"creature_you_control_enters","trigger_another_creature_you_control_enters":true,"trigger_damage_amount_source":"entering_creature_power","trigger_effect":"damage_any_target"}'::jsonb, '{"category":"burn_engine","effect":"etb_power_damage","subtype":"controlled_creature_enters_power_damage_any_target","timing":"triggered"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class TerrorOfThePeaks mapped to family targeted_interaction; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.', 'deprecate_nonmatching_rows'),
    ('balefire liege', 'Balefire Liege', '467dd11263f2854e2d9fc487a127ced6', 'battle_rule_v1:23affc042720e62b237989441a5e1b0e', '{"ability_kind":"triggered","battle_model_scope":"red_spell_damage_white_spell_lifegain_static_creature_boost_v1","effect":"creature","power":2,"red_spell_trigger_damage":3,"red_spell_trigger_damage_target":"player_or_planeswalker","static_boost_other_red_creatures_you_control":{"power":1,"toughness":1},"static_boost_other_white_creatures_you_control":{"power":1,"toughness":1},"toughness":4,"trigger":"spell_cast","trigger_effect":"spell_color_damage_life","white_spell_trigger_gain_life":3}'::jsonb, '{"category":"burn_lifegain_engine","effect":"spell_color_damage_life","subtype":"red_spell_damage_white_spell_lifegain","timing":"static_and_triggered"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class BalefireLiege mapped to family targeted_interaction; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.', 'deprecate_nonmatching_rows'),
    ('repercussion', 'Repercussion', '8e1ed4f8063ab89dd8906878a6232862', 'battle_rule_v1:a6fe56dcf8e3e5f3ef4ae8d9ae83e73f', '{"ability_kind":"triggered","battle_model_scope":"creature_damage_controller_reflect_global_v1","damage_amount_source":"damage_dealt_to_creature","effect":"direct_damage","global_creature_damage_reflect_to_controller":true,"trigger":"creature_dealt_damage","trigger_effect":"damage_creature_controller"}'::jsonb, '{"category":"burn_engine","effect":"damage_reflection","subtype":"creature_damage_controller_reflect","timing":"triggered"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class Repercussion mapped to family targeted_interaction; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.', 'deprecate_nonmatching_rows')
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
    ('verge rangers', 'Verge Rangers', '44aa2eeb2eeb517fb30478aec7cec42f', 'battle_rule_v1:9cbcc91673241a282f321ffb94963ca1', '{"ability_kind":"static","battle_model_scope":"look_top_library_play_lands_from_top_if_opponent_more_lands_v1","effect":"topdeck_play","keywords":["first_strike"],"look_top_library_any_time":true,"play_from_top_condition":"opponent_controls_more_lands","play_lands_from_top_library":true,"power":3,"toughness":3}'::jsonb, '{"category":"ramp","effect":"topdeck_play","subtype":"play_lands_from_library","timing":"static"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class VergeRangers mapped to family topdeck_play; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.', 'deprecate_nonmatching_rows'),
    ('firesong and sunspeaker', 'Firesong and Sunspeaker', '834cfb8f0f869e7e9b4bc5342ad63046', 'battle_rule_v1:f6858198cb699117df42e073abcee357', '{"ability_kind":"triggered","battle_model_scope":"red_instant_sorcery_lifelink_white_lifegain_damage_v1","effect":"creature","instant_sorcery_lifelink_colors":["R"],"instant_sorcery_spells_you_control_have_lifelink":true,"power":4,"target":"any_target","target_constraints":{"scope":"any_target"},"toughness":6,"trigger":"white_instant_sorcery_lifegain","trigger_effect":"damage_any_target","white_instant_sorcery_lifegain_trigger_damage":3}'::jsonb, '{"category":"burn_lifegain_engine","effect":"instant_sorcery_lifelink_lifegain_damage","subtype":"red_spell_lifelink_white_spell_lifegain_damage","timing":"static_and_triggered"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class FiresongAndSunspeaker mapped to family targeted_interaction; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.', 'deprecate_nonmatching_rows'),
    ('goliath daydreamer', 'Goliath Daydreamer', '715d2c178b304a7c5e6beed655883851', 'battle_rule_v1:65521ad249354a62c78b7c29ab866ecd', '{"ability_kind":"triggered","attack_free_cast_counter_type":"dream","attack_may_cast_owned_exiled_card_with_counter_without_paying_mana":true,"battle_model_scope":"instant_sorcery_from_hand_exile_dream_counter_attack_free_cast_v1","effect":"free_cast","exiled_counter_type":"dream","power":4,"spell_cast_from_hand_card_types":["instant","sorcery"],"spell_cast_from_hand_exile_instead_of_graveyard":true,"toughness":4,"trigger":"instant_sorcery_cast_from_hand_and_attack"}'::jsonb, '{"category":"combo_value","effect":"free_cast","subtype":"cast_without_paying_mana","timing":"triggered_or_resolution"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class GoliathDaydreamer mapped to family free_cast; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.', 'deprecate_nonmatching_rows'),
    ('boros reckoner', 'Boros Reckoner', '8cb6c980428b2501343f3f38dc686efb', 'battle_rule_v1:f344d0f95f1afcd03e9b0d840981aeef', '{"ability_kind":"triggered","activated_gain_first_strike_until_eot":true,"battle_model_scope":"source_dealt_damage_reflect_to_any_target_v1","damage_amount_source":"damage_dealt_to_source","effect":"creature","first_strike_activation_cost":"{R/W}","power":3,"source_damage_reflect_to_any_target":true,"target":"any_target","target_constraints":{"scope":"any_target"},"toughness":3,"trigger":"source_dealt_damage","trigger_effect":"damage_any_target"}'::jsonb, '{"category":"burn_engine","effect":"damage_reflection","subtype":"source_damaged_reflect_any_target","timing":"triggered"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class BorosReckoner mapped to family targeted_interaction; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.', 'deprecate_nonmatching_rows'),
    ('terror of the peaks', 'Terror of the Peaks', '90c007ac59cdd400f58e89c47d81440e', 'battle_rule_v1:ae8cab02963098960997301b3c227a80', '{"ability_kind":"triggered","battle_model_scope":"controlled_other_creature_enters_power_damage_any_target_v1","effect":"creature","flying":true,"opponent_spells_targeting_this_additional_life_cost":3,"power":5,"target":"any_target","target_constraints":{"scope":"any_target"},"toughness":4,"trigger":"creature_you_control_enters","trigger_another_creature_you_control_enters":true,"trigger_damage_amount_source":"entering_creature_power","trigger_effect":"damage_any_target"}'::jsonb, '{"category":"burn_engine","effect":"etb_power_damage","subtype":"controlled_creature_enters_power_damage_any_target","timing":"triggered"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class TerrorOfThePeaks mapped to family targeted_interaction; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.', 'deprecate_nonmatching_rows'),
    ('balefire liege', 'Balefire Liege', '467dd11263f2854e2d9fc487a127ced6', 'battle_rule_v1:23affc042720e62b237989441a5e1b0e', '{"ability_kind":"triggered","battle_model_scope":"red_spell_damage_white_spell_lifegain_static_creature_boost_v1","effect":"creature","power":2,"red_spell_trigger_damage":3,"red_spell_trigger_damage_target":"player_or_planeswalker","static_boost_other_red_creatures_you_control":{"power":1,"toughness":1},"static_boost_other_white_creatures_you_control":{"power":1,"toughness":1},"toughness":4,"trigger":"spell_cast","trigger_effect":"spell_color_damage_life","white_spell_trigger_gain_life":3}'::jsonb, '{"category":"burn_lifegain_engine","effect":"spell_color_damage_life","subtype":"red_spell_damage_white_spell_lifegain","timing":"static_and_triggered"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class BalefireLiege mapped to family targeted_interaction; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.', 'deprecate_nonmatching_rows'),
    ('repercussion', 'Repercussion', '8e1ed4f8063ab89dd8906878a6232862', 'battle_rule_v1:a6fe56dcf8e3e5f3ef4ae8d9ae83e73f', '{"ability_kind":"triggered","battle_model_scope":"creature_damage_controller_reflect_global_v1","damage_amount_source":"damage_dealt_to_creature","effect":"direct_damage","global_creature_damage_reflect_to_controller":true,"trigger":"creature_dealt_damage","trigger_effect":"damage_creature_controller"}'::jsonb, '{"category":"burn_engine","effect":"damage_reflection","subtype":"creature_damage_controller_reflect","timing":"triggered"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class Repercussion mapped to family targeted_interaction; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.', 'deprecate_nonmatching_rows')
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
