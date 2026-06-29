BEGIN;

CREATE TABLE IF NOT EXISTS public.pg252_manual_runtime_waiver_promotions_backup AS
SELECT now() AS backed_up_at, r.*
FROM public.card_battle_rules r
WHERE false;

INSERT INTO public.pg252_manual_runtime_waiver_promotions_backup
SELECT now() AS backed_up_at, r.*
FROM public.card_battle_rules r
WHERE r.normalized_name IN (
  SELECT normalized_name FROM (VALUES
    ('ancient copper dragon'), ('beacon of immortality'), ('invincible hymn'), ('planetarium of wan shi tong'), ('radiant performer'), ('rem karolus, stalwart slayer'), ('rune-tail, kitsune ascendant // rune-tail''s essence'), ('sawhorn nemesis'), ('screaming nemesis'), ('semblance anvil'), ('serra ascendant'), ('slickshot show-off'), ('stuffy doll'), ('taunt from the rampart'), ('the walls of ba sing se'), ('zirda, the dawnwaker')
  ) AS v(normalized_name)
)
AND NOT EXISTS (
  SELECT 1 FROM public.pg252_manual_runtime_waiver_promotions_backup b
  WHERE b.normalized_name = r.normalized_name
    AND b.logical_rule_key = r.logical_rule_key
);

DO $$
DECLARE
  v_missing text;
BEGIN
  WITH proposed(normalized_name, card_name, oracle_hash) AS (
    VALUES
      ('ancient copper dragon', 'Ancient Copper Dragon', '776a45094149ed3e1cc8c1a408fb6318'), ('beacon of immortality', 'Beacon of Immortality', '642c17cb019f4299d5af9954f812f8a6'), ('invincible hymn', 'Invincible Hymn', '1ef3fc195072cd1c0c2f7dd03fa875f6'), ('planetarium of wan shi tong', 'Planetarium of Wan Shi Tong', '67433ff9a3bb75652404373a2949a53a'), ('radiant performer', 'Radiant Performer', '893b8d4958e842209180034ee424d134'), ('rem karolus, stalwart slayer', 'Rem Karolus, Stalwart Slayer', '7d58da0feedf10778e5f0a84b724e08c'), ('rune-tail, kitsune ascendant // rune-tail''s essence', 'Rune-Tail, Kitsune Ascendant // Rune-Tail''s Essence', '41538153d9a8b81b8233170efee5f9da'), ('sawhorn nemesis', 'Sawhorn Nemesis', '93e3f5684069bf77d7219e17f3e04a6c'), ('screaming nemesis', 'Screaming Nemesis', '77190ec2e1e1dcb8b15429e5d53e68bd'), ('semblance anvil', 'Semblance Anvil', '32a67417a2ff0e86b36986f3d0973d8c'), ('serra ascendant', 'Serra Ascendant', 'a08a773363e4484f37512d57594b56eb'), ('slickshot show-off', 'Slickshot Show-Off', '24ce626e7e7957d8e01f615ea00d9d08'), ('stuffy doll', 'Stuffy Doll', 'b3404d9b844875e0e427a0eda8011c83'), ('taunt from the rampart', 'Taunt from the Rampart', '8edc08d877978569fe4b5bc7120bb771'), ('the walls of ba sing se', 'The Walls of Ba Sing Se', '3eda937f066b2e5ab8fff222caecafab'), ('zirda, the dawnwaker', 'Zirda, the Dawnwaker', '23860bc4072cc27137ba346b82b9f548')
  )
  SELECT string_agg(p.card_name, ', ' ORDER BY p.card_name) INTO v_missing
  FROM proposed p
  WHERE NOT EXISTS (
    SELECT 1 FROM public.cards c
    WHERE (lower(c.name) = p.normalized_name OR split_part(lower(c.name), ' // ', 1) = p.normalized_name)
      AND md5(coalesce(c.oracle_text, '')) = p.oracle_hash
  );
  IF v_missing IS NOT NULL THEN
    RAISE EXCEPTION 'PG252 abort: expected at least one Oracle-hash-matched cards row for every proposed card: %', v_missing;
  END IF;
END $$;

WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('ancient copper dragon', 'Ancient Copper Dragon', '776a45094149ed3e1cc8c1a408fb6318', 'battle_rule_v1:e2ac43c9f6e03e11e9fab994a5c15258', '{"ability_kind":"triggered","battle_model_scope":"source_combat_damage_player_roll_d20_create_treasure_equal_result_v1","cmc":6.0,"die_sides":20,"effect":"ramp_engine","flying":true,"is_creature_permanent":true,"mana_cost":"{4}{R}{R}","power":6,"subtypes":["Elder","Dragon"],"toughness":5,"treasure_count_source":"d20_result","trigger":"combat_damage_to_player","trigger_source_deals_combat_damage_to_player":true}'::jsonb, '{"category":"ramp","effect":"ramp_engine"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'PG252: promoted tested manual runtime waiver for Ancient Copper Dragon; source is existing ManaLoom focused runtime test plus local XMage/manual rule mapping.', 'deprecate_nonmatching_rows'),
    ('beacon of immortality', 'Beacon of Immortality', '642c17cb019f4299d5af9954f812f8a6', 'battle_rule_v1:655c7da1b9d381d24b94b64487226598', '{"ability_kind":"one_shot","battle_model_scope":"double_target_player_life_total_shuffle_self_v1","cmc":6.0,"double_target_player_life_total":true,"effect":"life_total_change","instant":true,"shuffle_self_into_library_on_resolution":true,"target":"player","target_preference":"self"}'::jsonb, '{"category":"unknown","effect":"life_total_change","target":"player","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'PG252: promoted tested manual runtime waiver for Beacon of Immortality; source is existing ManaLoom focused runtime test plus local XMage/manual rule mapping.', 'deprecate_nonmatching_rows'),
    ('invincible hymn', 'Invincible Hymn', '1ef3fc195072cd1c0c2f7dd03fa875f6', 'battle_rule_v1:de6504fa068c924a1bad5f1ada35a026', '{"ability_kind":"one_shot","battle_model_scope":"controller_life_total_becomes_library_size_v1","cmc":8.0,"effect":"life_total_change","life_total_becomes_library_size":true,"sorcery":true,"target":"self"}'::jsonb, '{"category":"unknown","effect":"life_total_change","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'PG252: promoted tested manual runtime waiver for Invincible Hymn; source is existing ManaLoom focused runtime test plus local XMage/manual rule mapping.', 'deprecate_nonmatching_rows'),
    ('planetarium of wan shi tong', 'Planetarium of Wan Shi Tong', '67433ff9a3bb75652404373a2949a53a', 'battle_rule_v1:a2082ebdf6e7e169b97eccecbb22b36a', '{"ability_kind":"activated_and_triggered","activated_scry_count":2,"activation_cost_generic":1,"activation_requires_tap":true,"battle_model_scope":"scry_or_surveil_once_turn_top_library_free_cast_v1","cast_top_card_without_paying_mana":true,"cmc":6.0,"effect":"topdeck_manipulation","legendary":true,"scry_or_surveil_top_library_free_cast_once_each_turn":true,"trigger":"scry_or_surveil","trigger_once_each_turn":true}'::jsonb, '{"category":"draw","effect":"topdeck_manipulation"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'PG252: promoted tested manual runtime waiver for Planetarium of Wan Shi Tong; source is existing ManaLoom focused runtime test plus local XMage/manual rule mapping.', 'deprecate_nonmatching_rows'),
    ('radiant performer', 'Radiant Performer', '893b8d4958e842209180034ee424d134', 'battle_rule_v1:fa12ce53b0a0c4b963f4071b4fde2c9b', '{"_runtime_partial":true,"_runtime_partial_reason":"ManaLoom stack executor copies a spell target, but not abilities or one-copy-per-legal-target fanout yet.","ability_kind":"flash_creature_etb_stack_copy_partial","battle_model_scope":"flash_creature_etb_copy_stack_spell_partial_metadata_v1","cmc":5.0,"colors":["R"],"copy_for_each_other_legal_permanent_or_player_target":true,"copy_target_stack_object":true,"copy_target_stack_object_single_permanent_or_player_target_only":true,"effect":"copy_spell","etb_copy_spell":true,"etb_if_cast_from_hand":true,"flash":true,"mana_cost":"{3}{R}{R}","power":2,"subtypes":["Human","Wizard"],"supports_copy_for_each_other_target":false,"supports_stack_ability_copy":false,"supports_stack_spell_copy":true,"target":"spell_or_ability_on_stack_single_permanent_or_player_target","target_constraints":{"target_count":1,"target_kind":"permanent_or_player","zone":"stack"},"toughness":2,"type_line":"Creature - Human Wizard"}'::jsonb, '{"category":"engine","effect":"copy_spell","target":"spell_or_ability_on_stack_single_permanent_or_player_target"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'PG252: promoted tested manual runtime waiver for Radiant Performer; source is existing ManaLoom focused runtime test plus local XMage/manual rule mapping.', 'deprecate_nonmatching_rows'),
    ('rem karolus, stalwart slayer', 'Rem Karolus, Stalwart Slayer', '7d58da0feedf10778e5f0a84b724e08c', 'battle_rule_v1:1a987670b594e446e4b1a122214e549e', '{"ability_kind":"static_replacement","battle_model_scope":"spell_damage_to_opponents_plus_one_prevent_own_nonself_v1","cmc":3.0,"colors":["R","W"],"damage_bonus":1,"damage_modifier_duration":"while_on_battlefield","damage_modifier_source_kind":"spell","damage_modifier_targets":["opponents","opponent_permanents"],"effect":"creature","flying":true,"haste":true,"mana_cost":"{1}{R}{W}","power":2,"prevent_spell_damage_to_you_and_permanents_you_control":true,"spell_damage_to_opponents_and_permanents_they_control_bonus":1,"subtypes":["Human","Knight"],"toughness":3,"type_line":"Legendary Creature - Human Knight"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'PG252: promoted tested manual runtime waiver for Rem Karolus, Stalwart Slayer; source is existing ManaLoom focused runtime test plus local XMage/manual rule mapping.', 'deprecate_nonmatching_rows'),
    ('rune-tail, kitsune ascendant // rune-tail''s essence', 'Rune-Tail, Kitsune Ascendant // Rune-Tail''s Essence', '41538153d9a8b81b8233170efee5f9da', 'battle_rule_v1:ac1ab7b07d9e4a4cb5ce455bc50ccb7e', '{"ability_kind":"state_triggered_static_replacement","battle_model_scope":"life_30_flip_prevent_all_damage_to_controlled_creatures_v1","cmc":3.0,"colors":["W"],"effect":"creature","flipped_name":"Rune-Tail''s Essence","flipped_type_line":"Legendary Enchantment","flips_at_life_total_threshold":true,"life_total_threshold":30,"mana_cost":"{2}{W}","power":2,"prevent_all_damage_to_controlled_creatures":true,"prevent_damage_target_scope":"controlled_creatures","subtypes":["Fox","Monk"],"toughness":2,"type_line":"Legendary Creature - Fox Monk"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'PG252: promoted tested manual runtime waiver for Rune-Tail, Kitsune Ascendant // Rune-Tail''s Essence; source is existing ManaLoom focused runtime test plus local XMage/manual rule mapping.', 'deprecate_nonmatching_rows'),
    ('sawhorn nemesis', 'Sawhorn Nemesis', '93e3f5684069bf77d7219e17f3e04a6c', 'battle_rule_v1:93e3f5684069bf77d7219e17f3e04a6c:sawhorn_nemesis_runtime_v1', '{"ability_kind":"static_replacement","as_enters_choose_player":true,"battle_model_scope":"chosen_player_or_permanents_they_control_damage_doubled_v1","cmc":4.0,"colors":["R"],"damage_modifier_applies_to":"chosen_player_or_permanents_they_control","damage_modifier_duration":"while_on_battlefield","damage_modifier_targets":["chosen_player","chosen_player_permanents"],"damage_multiplier":2,"effect":"creature","mana_cost":"{3}{R}","power":2,"subtypes":["Dinosaur"],"toughness":4,"type_line":"Creature - Dinosaur"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'PG252: promoted tested manual runtime waiver for Sawhorn Nemesis; source is existing ManaLoom focused runtime test plus local XMage/manual rule mapping.', 'deprecate_nonmatching_rows'),
    ('screaming nemesis', 'Screaming Nemesis', '77190ec2e1e1dcb8b15429e5d53e68bd', 'battle_rule_v1:77190ec2e1e1dcb8b15429e5d53e68bd:screaming_nemesis_runtime_v1', '{"ability_kind":"triggered","battle_model_scope":"source_dealt_damage_reflect_to_any_other_target_player_hit_cant_gain_life_v1","cmc":3.0,"colors":["R"],"damage_amount_source":"damage_dealt_to_source","effect":"creature","haste":true,"mana_cost":"{2}{R}","player_hit_cant_gain_life_rest_of_game":true,"power":3,"source_damage_reflect_to_any_target":true,"subtypes":["Spirit"],"toughness":3,"trigger":"source_dealt_damage","trigger_effect":"damage_any_target","type_line":"Creature - Spirit"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'PG252: promoted tested manual runtime waiver for Screaming Nemesis; source is existing ManaLoom focused runtime test plus local XMage/manual rule mapping.', 'deprecate_nonmatching_rows'),
    ('semblance anvil', 'Semblance Anvil', '32a67417a2ff0e86b36986f3d0973d8c', 'battle_rule_v1:ac1ab7b07d9e4a4cb5ce455bc50ccb7e', '{"ability_kind":"static","battle_model_scope":"imprint_nonland_card_reduce_spells_sharing_card_type_v1","cmc":3.0,"cost_reduction_applies_to":"spells_you_cast_sharing_imprinted_card_type","cost_reduction_generic":2,"effect":"static_cost_reduction","imprint_selection":"nonland_card_from_hand","requires_imprint_nonland_card":true}'::jsonb, '{"category":"support","effect":"static_cost_reduction"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'PG252: promoted tested manual runtime waiver for Semblance Anvil; source is existing ManaLoom focused runtime test plus local XMage/manual rule mapping.', 'deprecate_nonmatching_rows'),
    ('serra ascendant', 'Serra Ascendant', 'a08a773363e4484f37512d57594b56eb', 'battle_rule_v1:c3124030acfa1668606aca59dbbb7e2e', '{"ability_kind":"static","base_power":1,"base_toughness":1,"battle_model_scope":"controller_life_total_30_plus_self_plus_5_5_flying_static_v1","cmc":1.0,"colors":["W"],"effect":"creature","life_total_threshold":30,"life_total_threshold_grants":["flying"],"life_total_threshold_power_bonus":5,"life_total_threshold_toughness_bonus":5,"lifelink":true,"mana_cost":"{W}","power":1,"subtypes":["Human","Monk"],"toughness":1,"type_line":"Creature - Human Monk"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'PG252: promoted tested manual runtime waiver for Serra Ascendant; source is existing ManaLoom focused runtime test plus local XMage/manual rule mapping.', 'deprecate_nonmatching_rows'),
    ('slickshot show-off', 'Slickshot Show-Off', '24ce626e7e7957d8e01f615ea00d9d08', 'battle_rule_v1:9fd2ff72170533330fc8ba9165bd99b4', '{"ability_kind":"triggered_and_alternate_casting","battle_model_scope":"noncreature_spell_cast_boost_source_plus_2_0_until_eot_plot_v1","cmc":2.0,"colors":["R"],"effect":"creature","flying":true,"haste":true,"mana_cost":"{1}{R}","plot":true,"plot_cost":"{1}{R}","plot_status":"metadata_only_cast_from_exile_timing_not_selected_by_ai","power":1,"subtypes":["Bird","Wizard"],"toughness":2,"trigger":"noncreature_spell_cast","trigger_effect":"boost_source_until_eot","trigger_power_bonus_until_eot":2,"trigger_toughness_bonus_until_eot":0,"type_line":"Creature - Bird Wizard"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'PG252: promoted tested manual runtime waiver for Slickshot Show-Off; source is existing ManaLoom focused runtime test plus local XMage/manual rule mapping.', 'deprecate_nonmatching_rows'),
    ('stuffy doll', 'Stuffy Doll', 'b3404d9b844875e0e427a0eda8011c83', 'battle_rule_v1:e7b60d9805dbf2701195f627c6ca1600', '{"ability_kind":"static_triggered_and_activated","activated_self_damage_to_source":1,"activation_requires_tap":true,"artifact":true,"as_enters_choose_player":true,"battle_model_scope":"source_dealt_damage_reflect_to_chosen_player_self_damage_indestructible_v1","cmc":5.0,"damage_amount_source":"damage_dealt_to_source","effect":"creature","indestructible":true,"mana_cost":"{5}","power":0,"source_damage_reflect_to_chosen_player":true,"subtypes":["Construct"],"toughness":1,"trigger":"source_dealt_damage","trigger_effect":"damage_any_target","type_line":"Artifact Creature - Construct"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'PG252: promoted tested manual runtime waiver for Stuffy Doll; source is existing ManaLoom focused runtime test plus local XMage/manual rule mapping.', 'deprecate_nonmatching_rows'),
    ('taunt from the rampart', 'Taunt from the Rampart', '8edc08d877978569fe4b5bc7120bb771', 'battle_rule_v1:16e15ea414a18410acd151d43276651c', '{"ability_kind":"one_shot","affected_creatures_cant_block_until_your_next_turn":true,"battle_model_scope":"goad_all_opponents_creatures_cant_block_until_your_next_turn_v1","cmc":5.0,"duration":"until_your_next_turn","effect":"goad_opponents_creatures_cant_block","goad_all_opponents_creatures":true,"target_constraints":{"card_types":["creature"],"controller_scope":"opponent"}}'::jsonb, '{"category":"wincon","effect":"goad_opponents_creatures_cant_block"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'PG252: promoted tested manual runtime waiver for Taunt from the Rampart; source is existing ManaLoom focused runtime test plus local XMage/manual rule mapping.', 'deprecate_nonmatching_rows'),
    ('the walls of ba sing se', 'The Walls of Ba Sing Se', '3eda937f066b2e5ab8fff222caecafab', 'battle_rule_v1:1e5bcf3b45fcae347879976d74d2ef84', '{"ability_kind":"static","artifact":true,"battle_model_scope":"other_permanents_you_control_have_indestructible_static_v1","cmc":8.0,"defender":true,"effect":"creature","legendary":true,"mana_cost":"{8}","other_permanents_you_control_have_indestructible":true,"power":0,"static_grant_scope":"other_permanents_you_control","static_grants":["indestructible"],"subtypes":["Wall"],"toughness":30,"type_line":"Legendary Artifact Creature - Wall"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'PG252: promoted tested manual runtime waiver for The Walls of Ba Sing Se; source is existing ManaLoom focused runtime test plus local XMage/manual rule mapping.', 'deprecate_nonmatching_rows'),
    ('zirda, the dawnwaker', 'Zirda, the Dawnwaker', '23860bc4072cc27137ba346b82b9f548', 'battle_rule_v1:45c3e1db1be4f2f97a3337ce3de8f767', '{"ability_kind":"static_and_activated","activated_ability_cost":"{1}, {T}","activated_ability_effect":"cant_block_target_creature_until_eot","activated_ability_target":"target_creature","battle_model_scope":"static_activated_ability_cost_reduction_variant_v1","cmc":3.0,"colors":["R","W"],"companion_condition":"each_permanent_card_in_starting_deck_has_activated_ability","cost_reduction_applies_to":"activated_abilities_you_activate","cost_reduction_excludes_mana_abilities":true,"cost_reduction_generic":2,"cost_reduction_minimum_total_mana":1,"effect":"static_cost_reduction","is_creature_permanent":true,"legendary":true,"mana_cost":"{1}{R/W}{R/W}","power":3,"subtypes":["Elemental","Fox"],"toughness":3,"type_line":"Legendary Creature - Elemental Fox"}'::jsonb, '{"category":"support","effect":"static_cost_reduction"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'PG252: promoted tested manual runtime waiver for Zirda, the Dawnwaker; source is existing ManaLoom focused runtime test plus local XMage/manual rule mapping.', 'deprecate_nonmatching_rows')
), missing AS (
  SELECT p.card_name
  FROM proposed p
  WHERE NOT EXISTS (
    SELECT 1 FROM public.cards c
    WHERE (lower(c.name) = p.normalized_name OR split_part(lower(c.name), ' // ', 1) = p.normalized_name)
      AND md5(coalesce(c.oracle_text, '')) = p.oracle_hash
  )
), deprecated AS (
  UPDATE public.card_battle_rules r
  SET review_status = 'deprecated',
      execution_status = 'disabled',
      updated_at = now(),
      notes = concat_ws(E'\n', nullif(r.notes, ''), 'PG252: disabled stale shadow before curated tested manual-runtime waiver promotion.')
  FROM proposed p
  WHERE r.normalized_name = p.normalized_name
    AND p.shadow_handling = 'deprecate_nonmatching_rows'
    AND r.logical_rule_key <> p.logical_rule_key
    AND (r.review_status <> 'deprecated' OR r.execution_status <> 'disabled')
  RETURNING r.*
), target_cards AS (
  SELECT DISTINCT ON (p.normalized_name) p.normalized_name, c.id, c.name
  FROM proposed p
  JOIN public.cards c
    ON (lower(c.name) = p.normalized_name OR split_part(lower(c.name), ' // ', 1) = p.normalized_name)
   AND md5(coalesce(c.oracle_text, '')) = p.oracle_hash
  ORDER BY p.normalized_name, c.name
), upserted AS (
  INSERT INTO public.card_battle_rules (
    normalized_name, logical_rule_key, card_id, card_name, effect_json, deck_role_json,
    source, confidence, review_status, execution_status, rule_version, oracle_hash,
    notes, reviewed_by, reviewed_at, created_at, updated_at, last_seen_at
  )
  SELECT p.normalized_name, p.logical_rule_key, tc.id, tc.name, p.effect_json, p.deck_role_json,
         p.source, p.confidence, p.review_status, p.execution_status, 1, p.oracle_hash,
         p.notes, 'codex-pg252', now(), now(), now(), now()
  FROM proposed p
  JOIN target_cards tc ON tc.normalized_name = p.normalized_name
  ON CONFLICT (normalized_name, logical_rule_key) DO UPDATE
  SET card_id = EXCLUDED.card_id,
      card_name = EXCLUDED.card_name,
      effect_json = EXCLUDED.effect_json,
      deck_role_json = EXCLUDED.deck_role_json,
      source = EXCLUDED.source,
      confidence = EXCLUDED.confidence,
      review_status = EXCLUDED.review_status,
      execution_status = EXCLUDED.execution_status,
      rule_version = EXCLUDED.rule_version,
      oracle_hash = EXCLUDED.oracle_hash,
      notes = EXCLUDED.notes,
      reviewed_by = EXCLUDED.reviewed_by,
      reviewed_at = EXCLUDED.reviewed_at,
      updated_at = now(),
      last_seen_at = now()
  RETURNING *
)
SELECT (SELECT count(*) FROM deprecated) AS deprecated_rows,
       (SELECT count(*) FROM upserted) AS upserted_rows;

COMMIT;
