BEGIN;

CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit;

CREATE TABLE IF NOT EXISTS manaloom_deploy_audit.pg789_dynamic_any_one_color_mana_new_ser_20260711_213604 AS
SELECT *
FROM public.card_battle_rules
WHERE normalized_name IN ('deathbloom ritualist', 'harabaz druid', 'rofellos, llanowar emissary', 'sanctum weaver', 'wirewood channeler')
   OR normalized_name LIKE 'deathbloom ritualist // %'
   OR normalized_name LIKE 'harabaz druid // %'
   OR normalized_name LIKE 'rofellos, llanowar emissary // %'
   OR normalized_name LIKE 'sanctum weaver // %'
   OR normalized_name LIKE 'wirewood channeler // %';

DO $$
DECLARE
  v_missing jsonb;
BEGIN
  WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('deathbloom ritualist', 'Deathbloom Ritualist', '8a5249aef983e3235c990a97c9169293', 'battle_rule_v1:c3c830d26aaa38045f5151c377c12fd6', '{"ability_kind":"activated_mana","activation_requires_tap":true,"battle_model_scope":"xmage_dynamic_any_one_color_mana_source_permanent_v1","conditional_mana_modes":[{"color":"W","mode":"dynamic_any_one_color","restriction":"any_spell","status":"runtime_executor_v1"},{"color":"U","mode":"dynamic_any_one_color","restriction":"any_spell","status":"runtime_executor_v1"},{"color":"B","mode":"dynamic_any_one_color","restriction":"any_spell","status":"runtime_executor_v1"},{"color":"R","mode":"dynamic_any_one_color","restriction":"any_spell","status":"runtime_executor_v1"},{"color":"G","mode":"dynamic_any_one_color","restriction":"any_spell","status":"runtime_executor_v1"}],"conditional_mana_modes_status":"runtime_executor_v1","conditional_mana_same_color_choice":true,"dynamic_mana_amount_source":"controller_graveyard_card_count","dynamic_mana_graveyard_count_card_types":["creature"],"effect":"ramp_permanent","is_mana_source":true,"mana_activation_requires_tap":true,"mana_produced":1,"permanent_type":"creature","produced_mana_symbols":["W","U","B","R","G"],"produces":"WUBRG","source_mana_cost":"{3}{B}{G}","source_type_line":"Creature \u2014 Elf Warlock","xmage_ability_classes":["DynamicManaAbility"],"xmage_effect_classes":[],"xmage_mana_ability_classes":["DynamicManaAbility"]}'::jsonb, '{"category":"ramp","effect":"ramp_permanent"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class DeathbloomRitualist translated into ManaLoom runtime scope xmage_dynamic_any_one_color_mana_source_permanent_v1. This row is package-ready only because the source signature is a narrow activated mana-source permanent with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('harabaz druid', 'Harabaz Druid', 'f3509b8b9ed320ebed17ec3859b9a9ff', 'battle_rule_v1:94df4f1c832e023dc696f81c8a1d9c55', '{"ability_kind":"activated_mana","activation_requires_tap":true,"battle_model_scope":"xmage_dynamic_any_one_color_mana_source_permanent_v1","conditional_mana_modes":[{"color":"W","mode":"dynamic_any_one_color","restriction":"any_spell","status":"runtime_executor_v1"},{"color":"U","mode":"dynamic_any_one_color","restriction":"any_spell","status":"runtime_executor_v1"},{"color":"B","mode":"dynamic_any_one_color","restriction":"any_spell","status":"runtime_executor_v1"},{"color":"R","mode":"dynamic_any_one_color","restriction":"any_spell","status":"runtime_executor_v1"},{"color":"G","mode":"dynamic_any_one_color","restriction":"any_spell","status":"runtime_executor_v1"}],"conditional_mana_modes_status":"runtime_executor_v1","conditional_mana_same_color_choice":true,"dynamic_mana_amount_source":"battlefield_permanent_count","dynamic_mana_battlefield_count_scope":"controller_battlefield","dynamic_mana_battlefield_count_subtypes":["ally"],"effect":"ramp_permanent","is_mana_source":true,"mana_activation_requires_tap":true,"mana_produced":1,"permanent_type":"creature","produced_mana_symbols":["W","U","B","R","G"],"produces":"WUBRG","source_mana_cost":"{1}{G}","source_type_line":"Creature \u2014 Human Druid Ally","xmage_ability_classes":["DynamicManaAbility"],"xmage_effect_classes":[],"xmage_mana_ability_classes":["DynamicManaAbility"]}'::jsonb, '{"category":"ramp","effect":"ramp_permanent"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class HarabazDruid translated into ManaLoom runtime scope xmage_dynamic_any_one_color_mana_source_permanent_v1. This row is package-ready only because the source signature is a narrow activated mana-source permanent with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('rofellos, llanowar emissary', 'Rofellos, Llanowar Emissary', 'bdda3e64f40d4536858c64d402e53b64', 'battle_rule_v1:aa27c44d930aa4bca4a83b9a922168cc', '{"ability_kind":"activated_mana","activation_requires_tap":true,"battle_model_scope":"xmage_fixed_color_dynamic_mana_source_permanent_v1","dynamic_mana_amount_source":"battlefield_permanent_count","dynamic_mana_battlefield_count_scope":"controller_battlefield","dynamic_mana_battlefield_count_subtypes":["forest"],"effect":"ramp_permanent","is_mana_source":true,"mana_activation_requires_tap":true,"mana_produced":1,"permanent_type":"creature","produces":"G","source_mana_cost":"{G}{G}","source_type_line":"Legendary Creature \u2014 Elf Druid","xmage_ability_classes":["DynamicManaAbility"],"xmage_effect_classes":[],"xmage_mana_ability_classes":["DynamicManaAbility"]}'::jsonb, '{"category":"ramp","effect":"ramp_permanent"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class RofellosLlanowarEmissary translated into ManaLoom runtime scope xmage_fixed_color_dynamic_mana_source_permanent_v1. This row is package-ready only because the source signature is a narrow activated mana-source permanent with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('sanctum weaver', 'Sanctum Weaver', 'df87f16786d06beacbd06792150badd0', 'battle_rule_v1:cb35e21fdc1379c0e4119463632091ff', '{"ability_kind":"activated_mana","activation_requires_tap":true,"battle_model_scope":"xmage_dynamic_any_one_color_mana_source_permanent_v1","conditional_mana_modes":[{"color":"W","mode":"dynamic_any_one_color","restriction":"any_spell","status":"runtime_executor_v1"},{"color":"U","mode":"dynamic_any_one_color","restriction":"any_spell","status":"runtime_executor_v1"},{"color":"B","mode":"dynamic_any_one_color","restriction":"any_spell","status":"runtime_executor_v1"},{"color":"R","mode":"dynamic_any_one_color","restriction":"any_spell","status":"runtime_executor_v1"},{"color":"G","mode":"dynamic_any_one_color","restriction":"any_spell","status":"runtime_executor_v1"}],"conditional_mana_modes_status":"runtime_executor_v1","conditional_mana_same_color_choice":true,"dynamic_mana_amount_source":"battlefield_permanent_count","dynamic_mana_battlefield_count_card_types":["enchantment"],"dynamic_mana_battlefield_count_scope":"controller_battlefield","effect":"ramp_permanent","is_mana_source":true,"mana_activation_requires_tap":true,"mana_produced":1,"permanent_type":"creature","produced_mana_symbols":["W","U","B","R","G"],"produces":"WUBRG","source_mana_cost":"{1}{G}","source_type_line":"Enchantment Creature \u2014 Dryad","xmage_ability_classes":["DynamicManaAbility"],"xmage_effect_classes":[],"xmage_mana_ability_classes":["DynamicManaAbility"]}'::jsonb, '{"category":"ramp","effect":"ramp_permanent"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class SanctumWeaver translated into ManaLoom runtime scope xmage_dynamic_any_one_color_mana_source_permanent_v1. This row is package-ready only because the source signature is a narrow activated mana-source permanent with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('wirewood channeler', 'Wirewood Channeler', 'ab4fdad8a41b0165055aaab6ecb26fc2', 'battle_rule_v1:28b837fc536bf116268b7ce17c9e6f93', '{"ability_kind":"activated_mana","activation_requires_tap":true,"battle_model_scope":"xmage_dynamic_any_one_color_mana_source_permanent_v1","conditional_mana_modes":[{"color":"W","mode":"dynamic_any_one_color","restriction":"any_spell","status":"runtime_executor_v1"},{"color":"U","mode":"dynamic_any_one_color","restriction":"any_spell","status":"runtime_executor_v1"},{"color":"B","mode":"dynamic_any_one_color","restriction":"any_spell","status":"runtime_executor_v1"},{"color":"R","mode":"dynamic_any_one_color","restriction":"any_spell","status":"runtime_executor_v1"},{"color":"G","mode":"dynamic_any_one_color","restriction":"any_spell","status":"runtime_executor_v1"}],"conditional_mana_modes_status":"runtime_executor_v1","conditional_mana_same_color_choice":true,"dynamic_mana_amount_source":"battlefield_permanent_count","dynamic_mana_battlefield_count_scope":"all_battlefield","dynamic_mana_battlefield_count_subtypes":["elf"],"effect":"ramp_permanent","is_mana_source":true,"mana_activation_requires_tap":true,"mana_produced":1,"permanent_type":"creature","produced_mana_symbols":["W","U","B","R","G"],"produces":"WUBRG","source_mana_cost":"{3}{G}","source_type_line":"Creature \u2014 Elf Druid","xmage_ability_classes":["DynamicManaAbility"],"xmage_effect_classes":[],"xmage_mana_ability_classes":["DynamicManaAbility"]}'::jsonb, '{"category":"ramp","effect":"ramp_permanent"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class WirewoodChanneler translated into ManaLoom runtime scope xmage_dynamic_any_one_color_mana_source_permanent_v1. This row is package-ready only because the source signature is a narrow activated mana-source permanent with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
    ('deathbloom ritualist', 'Deathbloom Ritualist', '8a5249aef983e3235c990a97c9169293', 'battle_rule_v1:c3c830d26aaa38045f5151c377c12fd6', '{"ability_kind":"activated_mana","activation_requires_tap":true,"battle_model_scope":"xmage_dynamic_any_one_color_mana_source_permanent_v1","conditional_mana_modes":[{"color":"W","mode":"dynamic_any_one_color","restriction":"any_spell","status":"runtime_executor_v1"},{"color":"U","mode":"dynamic_any_one_color","restriction":"any_spell","status":"runtime_executor_v1"},{"color":"B","mode":"dynamic_any_one_color","restriction":"any_spell","status":"runtime_executor_v1"},{"color":"R","mode":"dynamic_any_one_color","restriction":"any_spell","status":"runtime_executor_v1"},{"color":"G","mode":"dynamic_any_one_color","restriction":"any_spell","status":"runtime_executor_v1"}],"conditional_mana_modes_status":"runtime_executor_v1","conditional_mana_same_color_choice":true,"dynamic_mana_amount_source":"controller_graveyard_card_count","dynamic_mana_graveyard_count_card_types":["creature"],"effect":"ramp_permanent","is_mana_source":true,"mana_activation_requires_tap":true,"mana_produced":1,"permanent_type":"creature","produced_mana_symbols":["W","U","B","R","G"],"produces":"WUBRG","source_mana_cost":"{3}{B}{G}","source_type_line":"Creature \u2014 Elf Warlock","xmage_ability_classes":["DynamicManaAbility"],"xmage_effect_classes":[],"xmage_mana_ability_classes":["DynamicManaAbility"]}'::jsonb, '{"category":"ramp","effect":"ramp_permanent"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class DeathbloomRitualist translated into ManaLoom runtime scope xmage_dynamic_any_one_color_mana_source_permanent_v1. This row is package-ready only because the source signature is a narrow activated mana-source permanent with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('harabaz druid', 'Harabaz Druid', 'f3509b8b9ed320ebed17ec3859b9a9ff', 'battle_rule_v1:94df4f1c832e023dc696f81c8a1d9c55', '{"ability_kind":"activated_mana","activation_requires_tap":true,"battle_model_scope":"xmage_dynamic_any_one_color_mana_source_permanent_v1","conditional_mana_modes":[{"color":"W","mode":"dynamic_any_one_color","restriction":"any_spell","status":"runtime_executor_v1"},{"color":"U","mode":"dynamic_any_one_color","restriction":"any_spell","status":"runtime_executor_v1"},{"color":"B","mode":"dynamic_any_one_color","restriction":"any_spell","status":"runtime_executor_v1"},{"color":"R","mode":"dynamic_any_one_color","restriction":"any_spell","status":"runtime_executor_v1"},{"color":"G","mode":"dynamic_any_one_color","restriction":"any_spell","status":"runtime_executor_v1"}],"conditional_mana_modes_status":"runtime_executor_v1","conditional_mana_same_color_choice":true,"dynamic_mana_amount_source":"battlefield_permanent_count","dynamic_mana_battlefield_count_scope":"controller_battlefield","dynamic_mana_battlefield_count_subtypes":["ally"],"effect":"ramp_permanent","is_mana_source":true,"mana_activation_requires_tap":true,"mana_produced":1,"permanent_type":"creature","produced_mana_symbols":["W","U","B","R","G"],"produces":"WUBRG","source_mana_cost":"{1}{G}","source_type_line":"Creature \u2014 Human Druid Ally","xmage_ability_classes":["DynamicManaAbility"],"xmage_effect_classes":[],"xmage_mana_ability_classes":["DynamicManaAbility"]}'::jsonb, '{"category":"ramp","effect":"ramp_permanent"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class HarabazDruid translated into ManaLoom runtime scope xmage_dynamic_any_one_color_mana_source_permanent_v1. This row is package-ready only because the source signature is a narrow activated mana-source permanent with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('rofellos, llanowar emissary', 'Rofellos, Llanowar Emissary', 'bdda3e64f40d4536858c64d402e53b64', 'battle_rule_v1:aa27c44d930aa4bca4a83b9a922168cc', '{"ability_kind":"activated_mana","activation_requires_tap":true,"battle_model_scope":"xmage_fixed_color_dynamic_mana_source_permanent_v1","dynamic_mana_amount_source":"battlefield_permanent_count","dynamic_mana_battlefield_count_scope":"controller_battlefield","dynamic_mana_battlefield_count_subtypes":["forest"],"effect":"ramp_permanent","is_mana_source":true,"mana_activation_requires_tap":true,"mana_produced":1,"permanent_type":"creature","produces":"G","source_mana_cost":"{G}{G}","source_type_line":"Legendary Creature \u2014 Elf Druid","xmage_ability_classes":["DynamicManaAbility"],"xmage_effect_classes":[],"xmage_mana_ability_classes":["DynamicManaAbility"]}'::jsonb, '{"category":"ramp","effect":"ramp_permanent"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class RofellosLlanowarEmissary translated into ManaLoom runtime scope xmage_fixed_color_dynamic_mana_source_permanent_v1. This row is package-ready only because the source signature is a narrow activated mana-source permanent with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('sanctum weaver', 'Sanctum Weaver', 'df87f16786d06beacbd06792150badd0', 'battle_rule_v1:cb35e21fdc1379c0e4119463632091ff', '{"ability_kind":"activated_mana","activation_requires_tap":true,"battle_model_scope":"xmage_dynamic_any_one_color_mana_source_permanent_v1","conditional_mana_modes":[{"color":"W","mode":"dynamic_any_one_color","restriction":"any_spell","status":"runtime_executor_v1"},{"color":"U","mode":"dynamic_any_one_color","restriction":"any_spell","status":"runtime_executor_v1"},{"color":"B","mode":"dynamic_any_one_color","restriction":"any_spell","status":"runtime_executor_v1"},{"color":"R","mode":"dynamic_any_one_color","restriction":"any_spell","status":"runtime_executor_v1"},{"color":"G","mode":"dynamic_any_one_color","restriction":"any_spell","status":"runtime_executor_v1"}],"conditional_mana_modes_status":"runtime_executor_v1","conditional_mana_same_color_choice":true,"dynamic_mana_amount_source":"battlefield_permanent_count","dynamic_mana_battlefield_count_card_types":["enchantment"],"dynamic_mana_battlefield_count_scope":"controller_battlefield","effect":"ramp_permanent","is_mana_source":true,"mana_activation_requires_tap":true,"mana_produced":1,"permanent_type":"creature","produced_mana_symbols":["W","U","B","R","G"],"produces":"WUBRG","source_mana_cost":"{1}{G}","source_type_line":"Enchantment Creature \u2014 Dryad","xmage_ability_classes":["DynamicManaAbility"],"xmage_effect_classes":[],"xmage_mana_ability_classes":["DynamicManaAbility"]}'::jsonb, '{"category":"ramp","effect":"ramp_permanent"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class SanctumWeaver translated into ManaLoom runtime scope xmage_dynamic_any_one_color_mana_source_permanent_v1. This row is package-ready only because the source signature is a narrow activated mana-source permanent with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('wirewood channeler', 'Wirewood Channeler', 'ab4fdad8a41b0165055aaab6ecb26fc2', 'battle_rule_v1:28b837fc536bf116268b7ce17c9e6f93', '{"ability_kind":"activated_mana","activation_requires_tap":true,"battle_model_scope":"xmage_dynamic_any_one_color_mana_source_permanent_v1","conditional_mana_modes":[{"color":"W","mode":"dynamic_any_one_color","restriction":"any_spell","status":"runtime_executor_v1"},{"color":"U","mode":"dynamic_any_one_color","restriction":"any_spell","status":"runtime_executor_v1"},{"color":"B","mode":"dynamic_any_one_color","restriction":"any_spell","status":"runtime_executor_v1"},{"color":"R","mode":"dynamic_any_one_color","restriction":"any_spell","status":"runtime_executor_v1"},{"color":"G","mode":"dynamic_any_one_color","restriction":"any_spell","status":"runtime_executor_v1"}],"conditional_mana_modes_status":"runtime_executor_v1","conditional_mana_same_color_choice":true,"dynamic_mana_amount_source":"battlefield_permanent_count","dynamic_mana_battlefield_count_scope":"all_battlefield","dynamic_mana_battlefield_count_subtypes":["elf"],"effect":"ramp_permanent","is_mana_source":true,"mana_activation_requires_tap":true,"mana_produced":1,"permanent_type":"creature","produced_mana_symbols":["W","U","B","R","G"],"produces":"WUBRG","source_mana_cost":"{3}{G}","source_type_line":"Creature \u2014 Elf Druid","xmage_ability_classes":["DynamicManaAbility"],"xmage_effect_classes":[],"xmage_mana_ability_classes":["DynamicManaAbility"]}'::jsonb, '{"category":"ramp","effect":"ramp_permanent"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class WirewoodChanneler translated into ManaLoom runtime scope xmage_dynamic_any_one_color_mana_source_permanent_v1. This row is package-ready only because the source signature is a narrow activated mana-source permanent with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
    ('deathbloom ritualist', 'Deathbloom Ritualist', '8a5249aef983e3235c990a97c9169293', 'battle_rule_v1:c3c830d26aaa38045f5151c377c12fd6', '{"ability_kind":"activated_mana","activation_requires_tap":true,"battle_model_scope":"xmage_dynamic_any_one_color_mana_source_permanent_v1","conditional_mana_modes":[{"color":"W","mode":"dynamic_any_one_color","restriction":"any_spell","status":"runtime_executor_v1"},{"color":"U","mode":"dynamic_any_one_color","restriction":"any_spell","status":"runtime_executor_v1"},{"color":"B","mode":"dynamic_any_one_color","restriction":"any_spell","status":"runtime_executor_v1"},{"color":"R","mode":"dynamic_any_one_color","restriction":"any_spell","status":"runtime_executor_v1"},{"color":"G","mode":"dynamic_any_one_color","restriction":"any_spell","status":"runtime_executor_v1"}],"conditional_mana_modes_status":"runtime_executor_v1","conditional_mana_same_color_choice":true,"dynamic_mana_amount_source":"controller_graveyard_card_count","dynamic_mana_graveyard_count_card_types":["creature"],"effect":"ramp_permanent","is_mana_source":true,"mana_activation_requires_tap":true,"mana_produced":1,"permanent_type":"creature","produced_mana_symbols":["W","U","B","R","G"],"produces":"WUBRG","source_mana_cost":"{3}{B}{G}","source_type_line":"Creature \u2014 Elf Warlock","xmage_ability_classes":["DynamicManaAbility"],"xmage_effect_classes":[],"xmage_mana_ability_classes":["DynamicManaAbility"]}'::jsonb, '{"category":"ramp","effect":"ramp_permanent"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class DeathbloomRitualist translated into ManaLoom runtime scope xmage_dynamic_any_one_color_mana_source_permanent_v1. This row is package-ready only because the source signature is a narrow activated mana-source permanent with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('harabaz druid', 'Harabaz Druid', 'f3509b8b9ed320ebed17ec3859b9a9ff', 'battle_rule_v1:94df4f1c832e023dc696f81c8a1d9c55', '{"ability_kind":"activated_mana","activation_requires_tap":true,"battle_model_scope":"xmage_dynamic_any_one_color_mana_source_permanent_v1","conditional_mana_modes":[{"color":"W","mode":"dynamic_any_one_color","restriction":"any_spell","status":"runtime_executor_v1"},{"color":"U","mode":"dynamic_any_one_color","restriction":"any_spell","status":"runtime_executor_v1"},{"color":"B","mode":"dynamic_any_one_color","restriction":"any_spell","status":"runtime_executor_v1"},{"color":"R","mode":"dynamic_any_one_color","restriction":"any_spell","status":"runtime_executor_v1"},{"color":"G","mode":"dynamic_any_one_color","restriction":"any_spell","status":"runtime_executor_v1"}],"conditional_mana_modes_status":"runtime_executor_v1","conditional_mana_same_color_choice":true,"dynamic_mana_amount_source":"battlefield_permanent_count","dynamic_mana_battlefield_count_scope":"controller_battlefield","dynamic_mana_battlefield_count_subtypes":["ally"],"effect":"ramp_permanent","is_mana_source":true,"mana_activation_requires_tap":true,"mana_produced":1,"permanent_type":"creature","produced_mana_symbols":["W","U","B","R","G"],"produces":"WUBRG","source_mana_cost":"{1}{G}","source_type_line":"Creature \u2014 Human Druid Ally","xmage_ability_classes":["DynamicManaAbility"],"xmage_effect_classes":[],"xmage_mana_ability_classes":["DynamicManaAbility"]}'::jsonb, '{"category":"ramp","effect":"ramp_permanent"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class HarabazDruid translated into ManaLoom runtime scope xmage_dynamic_any_one_color_mana_source_permanent_v1. This row is package-ready only because the source signature is a narrow activated mana-source permanent with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('rofellos, llanowar emissary', 'Rofellos, Llanowar Emissary', 'bdda3e64f40d4536858c64d402e53b64', 'battle_rule_v1:aa27c44d930aa4bca4a83b9a922168cc', '{"ability_kind":"activated_mana","activation_requires_tap":true,"battle_model_scope":"xmage_fixed_color_dynamic_mana_source_permanent_v1","dynamic_mana_amount_source":"battlefield_permanent_count","dynamic_mana_battlefield_count_scope":"controller_battlefield","dynamic_mana_battlefield_count_subtypes":["forest"],"effect":"ramp_permanent","is_mana_source":true,"mana_activation_requires_tap":true,"mana_produced":1,"permanent_type":"creature","produces":"G","source_mana_cost":"{G}{G}","source_type_line":"Legendary Creature \u2014 Elf Druid","xmage_ability_classes":["DynamicManaAbility"],"xmage_effect_classes":[],"xmage_mana_ability_classes":["DynamicManaAbility"]}'::jsonb, '{"category":"ramp","effect":"ramp_permanent"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class RofellosLlanowarEmissary translated into ManaLoom runtime scope xmage_fixed_color_dynamic_mana_source_permanent_v1. This row is package-ready only because the source signature is a narrow activated mana-source permanent with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('sanctum weaver', 'Sanctum Weaver', 'df87f16786d06beacbd06792150badd0', 'battle_rule_v1:cb35e21fdc1379c0e4119463632091ff', '{"ability_kind":"activated_mana","activation_requires_tap":true,"battle_model_scope":"xmage_dynamic_any_one_color_mana_source_permanent_v1","conditional_mana_modes":[{"color":"W","mode":"dynamic_any_one_color","restriction":"any_spell","status":"runtime_executor_v1"},{"color":"U","mode":"dynamic_any_one_color","restriction":"any_spell","status":"runtime_executor_v1"},{"color":"B","mode":"dynamic_any_one_color","restriction":"any_spell","status":"runtime_executor_v1"},{"color":"R","mode":"dynamic_any_one_color","restriction":"any_spell","status":"runtime_executor_v1"},{"color":"G","mode":"dynamic_any_one_color","restriction":"any_spell","status":"runtime_executor_v1"}],"conditional_mana_modes_status":"runtime_executor_v1","conditional_mana_same_color_choice":true,"dynamic_mana_amount_source":"battlefield_permanent_count","dynamic_mana_battlefield_count_card_types":["enchantment"],"dynamic_mana_battlefield_count_scope":"controller_battlefield","effect":"ramp_permanent","is_mana_source":true,"mana_activation_requires_tap":true,"mana_produced":1,"permanent_type":"creature","produced_mana_symbols":["W","U","B","R","G"],"produces":"WUBRG","source_mana_cost":"{1}{G}","source_type_line":"Enchantment Creature \u2014 Dryad","xmage_ability_classes":["DynamicManaAbility"],"xmage_effect_classes":[],"xmage_mana_ability_classes":["DynamicManaAbility"]}'::jsonb, '{"category":"ramp","effect":"ramp_permanent"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class SanctumWeaver translated into ManaLoom runtime scope xmage_dynamic_any_one_color_mana_source_permanent_v1. This row is package-ready only because the source signature is a narrow activated mana-source permanent with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('wirewood channeler', 'Wirewood Channeler', 'ab4fdad8a41b0165055aaab6ecb26fc2', 'battle_rule_v1:28b837fc536bf116268b7ce17c9e6f93', '{"ability_kind":"activated_mana","activation_requires_tap":true,"battle_model_scope":"xmage_dynamic_any_one_color_mana_source_permanent_v1","conditional_mana_modes":[{"color":"W","mode":"dynamic_any_one_color","restriction":"any_spell","status":"runtime_executor_v1"},{"color":"U","mode":"dynamic_any_one_color","restriction":"any_spell","status":"runtime_executor_v1"},{"color":"B","mode":"dynamic_any_one_color","restriction":"any_spell","status":"runtime_executor_v1"},{"color":"R","mode":"dynamic_any_one_color","restriction":"any_spell","status":"runtime_executor_v1"},{"color":"G","mode":"dynamic_any_one_color","restriction":"any_spell","status":"runtime_executor_v1"}],"conditional_mana_modes_status":"runtime_executor_v1","conditional_mana_same_color_choice":true,"dynamic_mana_amount_source":"battlefield_permanent_count","dynamic_mana_battlefield_count_scope":"all_battlefield","dynamic_mana_battlefield_count_subtypes":["elf"],"effect":"ramp_permanent","is_mana_source":true,"mana_activation_requires_tap":true,"mana_produced":1,"permanent_type":"creature","produced_mana_symbols":["W","U","B","R","G"],"produces":"WUBRG","source_mana_cost":"{3}{G}","source_type_line":"Creature \u2014 Elf Druid","xmage_ability_classes":["DynamicManaAbility"],"xmage_effect_classes":[],"xmage_mana_ability_classes":["DynamicManaAbility"]}'::jsonb, '{"category":"ramp","effect":"ramp_permanent"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class WirewoodChanneler translated into ManaLoom runtime scope xmage_dynamic_any_one_color_mana_source_permanent_v1. This row is package-ready only because the source signature is a narrow activated mana-source permanent with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
