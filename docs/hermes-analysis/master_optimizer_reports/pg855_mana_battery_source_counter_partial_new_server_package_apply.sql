BEGIN;

CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit;

CREATE TABLE IF NOT EXISTS manaloom_deploy_audit.pg855_mana_battery_source_counter_partia_20260713_011956 AS
SELECT *
FROM public.card_battle_rules
WHERE normalized_name IN ('black mana battery', 'blue mana battery', 'green mana battery', 'red mana battery', 'white mana battery')
   OR normalized_name LIKE 'black mana battery // %'
   OR normalized_name LIKE 'blue mana battery // %'
   OR normalized_name LIKE 'green mana battery // %'
   OR normalized_name LIKE 'red mana battery // %'
   OR normalized_name LIKE 'white mana battery // %';

DO $$
DECLARE
  v_missing jsonb;
BEGIN
  WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('black mana battery', 'Black Mana Battery', 'b37ec304f2e251f0e3e54f417a8b8637', 'battle_rule_v1:64df04747d9d520dd6fa140a1609f998', '{"_runtime_partial":true,"_runtime_partial_batch_safe":true,"_runtime_partial_batch_safe_reason":"The DynamicManaAbility mana production is fully modeled by the fixed-color dynamic mana runtime/E2E scenario; auxiliary non-mana abilities remain explicitly unmodeled.","_runtime_partial_reason":"Only the XMage fixed-color DynamicManaAbility is executable in this rule; listed auxiliary ability/effect classes remain unmodeled.","ability_kind":"activated_mana","activation_requires_tap":true,"battle_model_scope":"xmage_fixed_color_dynamic_mana_source_permanent_v1","dynamic_mana_amount_source":"source_named_counter_count_plus_base","dynamic_mana_base_amount":1,"dynamic_mana_counter_type":"charge","effect":"ramp_permanent","is_mana_source":true,"mana_activation_remove_all_source_counters":true,"mana_activation_remove_counter_type":"charge","mana_activation_requires_tap":true,"mana_produced":1,"modeled_ability_subset":"mana_source_only","permanent_type":"artifact","produces":"B","source_mana_cost":"{4}","source_type_line":"Artifact","xmage_ability_classes":["DynamicManaAbility","SimpleActivatedAbility"],"xmage_auxiliary_ability_classes":["SimpleActivatedAbility"],"xmage_effect_classes":["AddCountersSourceEffect"],"xmage_mana_ability_classes":["DynamicManaAbility"],"xmage_unmodeled_auxiliary_ability_classes":["SimpleActivatedAbility"],"xmage_unmodeled_effect_classes":["AddCountersSourceEffect"]}'::jsonb, '{"category":"ramp","effect":"ramp_permanent"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class BlackManaBattery translated into ManaLoom runtime scope xmage_fixed_color_dynamic_mana_source_permanent_v1. This row is package-ready only because the source signature is a narrow activated mana-source permanent with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('blue mana battery', 'Blue Mana Battery', 'e78d2f67c17533885fad52d18af12b73', 'battle_rule_v1:8ba3f1a54df3d9a74ccb32b233cbce48', '{"_runtime_partial":true,"_runtime_partial_batch_safe":true,"_runtime_partial_batch_safe_reason":"The DynamicManaAbility mana production is fully modeled by the fixed-color dynamic mana runtime/E2E scenario; auxiliary non-mana abilities remain explicitly unmodeled.","_runtime_partial_reason":"Only the XMage fixed-color DynamicManaAbility is executable in this rule; listed auxiliary ability/effect classes remain unmodeled.","ability_kind":"activated_mana","activation_requires_tap":true,"battle_model_scope":"xmage_fixed_color_dynamic_mana_source_permanent_v1","dynamic_mana_amount_source":"source_named_counter_count_plus_base","dynamic_mana_base_amount":1,"dynamic_mana_counter_type":"charge","effect":"ramp_permanent","is_mana_source":true,"mana_activation_remove_all_source_counters":true,"mana_activation_remove_counter_type":"charge","mana_activation_requires_tap":true,"mana_produced":1,"modeled_ability_subset":"mana_source_only","permanent_type":"artifact","produces":"U","source_mana_cost":"{4}","source_type_line":"Artifact","xmage_ability_classes":["DynamicManaAbility","SimpleActivatedAbility"],"xmage_auxiliary_ability_classes":["SimpleActivatedAbility"],"xmage_effect_classes":["AddCountersSourceEffect"],"xmage_mana_ability_classes":["DynamicManaAbility"],"xmage_unmodeled_auxiliary_ability_classes":["SimpleActivatedAbility"],"xmage_unmodeled_effect_classes":["AddCountersSourceEffect"]}'::jsonb, '{"category":"ramp","effect":"ramp_permanent"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class BlueManaBattery translated into ManaLoom runtime scope xmage_fixed_color_dynamic_mana_source_permanent_v1. This row is package-ready only because the source signature is a narrow activated mana-source permanent with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('green mana battery', 'Green Mana Battery', '05a70d5bc68685c1b9f2c8307ab351bc', 'battle_rule_v1:1c28afa796f2fd90e1e452a7a9ea1d45', '{"_runtime_partial":true,"_runtime_partial_batch_safe":true,"_runtime_partial_batch_safe_reason":"The DynamicManaAbility mana production is fully modeled by the fixed-color dynamic mana runtime/E2E scenario; auxiliary non-mana abilities remain explicitly unmodeled.","_runtime_partial_reason":"Only the XMage fixed-color DynamicManaAbility is executable in this rule; listed auxiliary ability/effect classes remain unmodeled.","ability_kind":"activated_mana","activation_requires_tap":true,"battle_model_scope":"xmage_fixed_color_dynamic_mana_source_permanent_v1","dynamic_mana_amount_source":"source_named_counter_count_plus_base","dynamic_mana_base_amount":1,"dynamic_mana_counter_type":"charge","effect":"ramp_permanent","is_mana_source":true,"mana_activation_remove_all_source_counters":true,"mana_activation_remove_counter_type":"charge","mana_activation_requires_tap":true,"mana_produced":1,"modeled_ability_subset":"mana_source_only","permanent_type":"artifact","produces":"G","source_mana_cost":"{4}","source_type_line":"Artifact","xmage_ability_classes":["DynamicManaAbility","SimpleActivatedAbility"],"xmage_auxiliary_ability_classes":["SimpleActivatedAbility"],"xmage_effect_classes":["AddCountersSourceEffect"],"xmage_mana_ability_classes":["DynamicManaAbility"],"xmage_unmodeled_auxiliary_ability_classes":["SimpleActivatedAbility"],"xmage_unmodeled_effect_classes":["AddCountersSourceEffect"]}'::jsonb, '{"category":"ramp","effect":"ramp_permanent"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class GreenManaBattery translated into ManaLoom runtime scope xmage_fixed_color_dynamic_mana_source_permanent_v1. This row is package-ready only because the source signature is a narrow activated mana-source permanent with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('red mana battery', 'Red Mana Battery', '76717f51aba6605bb6f1e922101ced58', 'battle_rule_v1:6f22697fcde8a869fbcdd47b9d92469a', '{"_runtime_partial":true,"_runtime_partial_batch_safe":true,"_runtime_partial_batch_safe_reason":"The DynamicManaAbility mana production is fully modeled by the fixed-color dynamic mana runtime/E2E scenario; auxiliary non-mana abilities remain explicitly unmodeled.","_runtime_partial_reason":"Only the XMage fixed-color DynamicManaAbility is executable in this rule; listed auxiliary ability/effect classes remain unmodeled.","ability_kind":"activated_mana","activation_requires_tap":true,"battle_model_scope":"xmage_fixed_color_dynamic_mana_source_permanent_v1","dynamic_mana_amount_source":"source_named_counter_count_plus_base","dynamic_mana_base_amount":1,"dynamic_mana_counter_type":"charge","effect":"ramp_permanent","is_mana_source":true,"mana_activation_remove_all_source_counters":true,"mana_activation_remove_counter_type":"charge","mana_activation_requires_tap":true,"mana_produced":1,"modeled_ability_subset":"mana_source_only","permanent_type":"artifact","produces":"R","source_mana_cost":"{4}","source_type_line":"Artifact","xmage_ability_classes":["DynamicManaAbility","SimpleActivatedAbility"],"xmage_auxiliary_ability_classes":["SimpleActivatedAbility"],"xmage_effect_classes":["AddCountersSourceEffect"],"xmage_mana_ability_classes":["DynamicManaAbility"],"xmage_unmodeled_auxiliary_ability_classes":["SimpleActivatedAbility"],"xmage_unmodeled_effect_classes":["AddCountersSourceEffect"]}'::jsonb, '{"category":"ramp","effect":"ramp_permanent"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class RedManaBattery translated into ManaLoom runtime scope xmage_fixed_color_dynamic_mana_source_permanent_v1. This row is package-ready only because the source signature is a narrow activated mana-source permanent with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('white mana battery', 'White Mana Battery', '146ba7850ae9e62899e31511762192b8', 'battle_rule_v1:2c18af306e24412e483c1f377bc744f5', '{"_runtime_partial":true,"_runtime_partial_batch_safe":true,"_runtime_partial_batch_safe_reason":"The DynamicManaAbility mana production is fully modeled by the fixed-color dynamic mana runtime/E2E scenario; auxiliary non-mana abilities remain explicitly unmodeled.","_runtime_partial_reason":"Only the XMage fixed-color DynamicManaAbility is executable in this rule; listed auxiliary ability/effect classes remain unmodeled.","ability_kind":"activated_mana","activation_requires_tap":true,"battle_model_scope":"xmage_fixed_color_dynamic_mana_source_permanent_v1","dynamic_mana_amount_source":"source_named_counter_count_plus_base","dynamic_mana_base_amount":1,"dynamic_mana_counter_type":"charge","effect":"ramp_permanent","is_mana_source":true,"mana_activation_remove_all_source_counters":true,"mana_activation_remove_counter_type":"charge","mana_activation_requires_tap":true,"mana_produced":1,"modeled_ability_subset":"mana_source_only","permanent_type":"artifact","produces":"W","source_mana_cost":"{4}","source_type_line":"Artifact","xmage_ability_classes":["DynamicManaAbility","SimpleActivatedAbility"],"xmage_auxiliary_ability_classes":["SimpleActivatedAbility"],"xmage_effect_classes":["AddCountersSourceEffect"],"xmage_mana_ability_classes":["DynamicManaAbility"],"xmage_unmodeled_auxiliary_ability_classes":["SimpleActivatedAbility"],"xmage_unmodeled_effect_classes":["AddCountersSourceEffect"]}'::jsonb, '{"category":"ramp","effect":"ramp_permanent"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class WhiteManaBattery translated into ManaLoom runtime scope xmage_fixed_color_dynamic_mana_source_permanent_v1. This row is package-ready only because the source signature is a narrow activated mana-source permanent with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
    ('black mana battery', 'Black Mana Battery', 'b37ec304f2e251f0e3e54f417a8b8637', 'battle_rule_v1:64df04747d9d520dd6fa140a1609f998', '{"_runtime_partial":true,"_runtime_partial_batch_safe":true,"_runtime_partial_batch_safe_reason":"The DynamicManaAbility mana production is fully modeled by the fixed-color dynamic mana runtime/E2E scenario; auxiliary non-mana abilities remain explicitly unmodeled.","_runtime_partial_reason":"Only the XMage fixed-color DynamicManaAbility is executable in this rule; listed auxiliary ability/effect classes remain unmodeled.","ability_kind":"activated_mana","activation_requires_tap":true,"battle_model_scope":"xmage_fixed_color_dynamic_mana_source_permanent_v1","dynamic_mana_amount_source":"source_named_counter_count_plus_base","dynamic_mana_base_amount":1,"dynamic_mana_counter_type":"charge","effect":"ramp_permanent","is_mana_source":true,"mana_activation_remove_all_source_counters":true,"mana_activation_remove_counter_type":"charge","mana_activation_requires_tap":true,"mana_produced":1,"modeled_ability_subset":"mana_source_only","permanent_type":"artifact","produces":"B","source_mana_cost":"{4}","source_type_line":"Artifact","xmage_ability_classes":["DynamicManaAbility","SimpleActivatedAbility"],"xmage_auxiliary_ability_classes":["SimpleActivatedAbility"],"xmage_effect_classes":["AddCountersSourceEffect"],"xmage_mana_ability_classes":["DynamicManaAbility"],"xmage_unmodeled_auxiliary_ability_classes":["SimpleActivatedAbility"],"xmage_unmodeled_effect_classes":["AddCountersSourceEffect"]}'::jsonb, '{"category":"ramp","effect":"ramp_permanent"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class BlackManaBattery translated into ManaLoom runtime scope xmage_fixed_color_dynamic_mana_source_permanent_v1. This row is package-ready only because the source signature is a narrow activated mana-source permanent with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('blue mana battery', 'Blue Mana Battery', 'e78d2f67c17533885fad52d18af12b73', 'battle_rule_v1:8ba3f1a54df3d9a74ccb32b233cbce48', '{"_runtime_partial":true,"_runtime_partial_batch_safe":true,"_runtime_partial_batch_safe_reason":"The DynamicManaAbility mana production is fully modeled by the fixed-color dynamic mana runtime/E2E scenario; auxiliary non-mana abilities remain explicitly unmodeled.","_runtime_partial_reason":"Only the XMage fixed-color DynamicManaAbility is executable in this rule; listed auxiliary ability/effect classes remain unmodeled.","ability_kind":"activated_mana","activation_requires_tap":true,"battle_model_scope":"xmage_fixed_color_dynamic_mana_source_permanent_v1","dynamic_mana_amount_source":"source_named_counter_count_plus_base","dynamic_mana_base_amount":1,"dynamic_mana_counter_type":"charge","effect":"ramp_permanent","is_mana_source":true,"mana_activation_remove_all_source_counters":true,"mana_activation_remove_counter_type":"charge","mana_activation_requires_tap":true,"mana_produced":1,"modeled_ability_subset":"mana_source_only","permanent_type":"artifact","produces":"U","source_mana_cost":"{4}","source_type_line":"Artifact","xmage_ability_classes":["DynamicManaAbility","SimpleActivatedAbility"],"xmage_auxiliary_ability_classes":["SimpleActivatedAbility"],"xmage_effect_classes":["AddCountersSourceEffect"],"xmage_mana_ability_classes":["DynamicManaAbility"],"xmage_unmodeled_auxiliary_ability_classes":["SimpleActivatedAbility"],"xmage_unmodeled_effect_classes":["AddCountersSourceEffect"]}'::jsonb, '{"category":"ramp","effect":"ramp_permanent"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class BlueManaBattery translated into ManaLoom runtime scope xmage_fixed_color_dynamic_mana_source_permanent_v1. This row is package-ready only because the source signature is a narrow activated mana-source permanent with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('green mana battery', 'Green Mana Battery', '05a70d5bc68685c1b9f2c8307ab351bc', 'battle_rule_v1:1c28afa796f2fd90e1e452a7a9ea1d45', '{"_runtime_partial":true,"_runtime_partial_batch_safe":true,"_runtime_partial_batch_safe_reason":"The DynamicManaAbility mana production is fully modeled by the fixed-color dynamic mana runtime/E2E scenario; auxiliary non-mana abilities remain explicitly unmodeled.","_runtime_partial_reason":"Only the XMage fixed-color DynamicManaAbility is executable in this rule; listed auxiliary ability/effect classes remain unmodeled.","ability_kind":"activated_mana","activation_requires_tap":true,"battle_model_scope":"xmage_fixed_color_dynamic_mana_source_permanent_v1","dynamic_mana_amount_source":"source_named_counter_count_plus_base","dynamic_mana_base_amount":1,"dynamic_mana_counter_type":"charge","effect":"ramp_permanent","is_mana_source":true,"mana_activation_remove_all_source_counters":true,"mana_activation_remove_counter_type":"charge","mana_activation_requires_tap":true,"mana_produced":1,"modeled_ability_subset":"mana_source_only","permanent_type":"artifact","produces":"G","source_mana_cost":"{4}","source_type_line":"Artifact","xmage_ability_classes":["DynamicManaAbility","SimpleActivatedAbility"],"xmage_auxiliary_ability_classes":["SimpleActivatedAbility"],"xmage_effect_classes":["AddCountersSourceEffect"],"xmage_mana_ability_classes":["DynamicManaAbility"],"xmage_unmodeled_auxiliary_ability_classes":["SimpleActivatedAbility"],"xmage_unmodeled_effect_classes":["AddCountersSourceEffect"]}'::jsonb, '{"category":"ramp","effect":"ramp_permanent"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class GreenManaBattery translated into ManaLoom runtime scope xmage_fixed_color_dynamic_mana_source_permanent_v1. This row is package-ready only because the source signature is a narrow activated mana-source permanent with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('red mana battery', 'Red Mana Battery', '76717f51aba6605bb6f1e922101ced58', 'battle_rule_v1:6f22697fcde8a869fbcdd47b9d92469a', '{"_runtime_partial":true,"_runtime_partial_batch_safe":true,"_runtime_partial_batch_safe_reason":"The DynamicManaAbility mana production is fully modeled by the fixed-color dynamic mana runtime/E2E scenario; auxiliary non-mana abilities remain explicitly unmodeled.","_runtime_partial_reason":"Only the XMage fixed-color DynamicManaAbility is executable in this rule; listed auxiliary ability/effect classes remain unmodeled.","ability_kind":"activated_mana","activation_requires_tap":true,"battle_model_scope":"xmage_fixed_color_dynamic_mana_source_permanent_v1","dynamic_mana_amount_source":"source_named_counter_count_plus_base","dynamic_mana_base_amount":1,"dynamic_mana_counter_type":"charge","effect":"ramp_permanent","is_mana_source":true,"mana_activation_remove_all_source_counters":true,"mana_activation_remove_counter_type":"charge","mana_activation_requires_tap":true,"mana_produced":1,"modeled_ability_subset":"mana_source_only","permanent_type":"artifact","produces":"R","source_mana_cost":"{4}","source_type_line":"Artifact","xmage_ability_classes":["DynamicManaAbility","SimpleActivatedAbility"],"xmage_auxiliary_ability_classes":["SimpleActivatedAbility"],"xmage_effect_classes":["AddCountersSourceEffect"],"xmage_mana_ability_classes":["DynamicManaAbility"],"xmage_unmodeled_auxiliary_ability_classes":["SimpleActivatedAbility"],"xmage_unmodeled_effect_classes":["AddCountersSourceEffect"]}'::jsonb, '{"category":"ramp","effect":"ramp_permanent"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class RedManaBattery translated into ManaLoom runtime scope xmage_fixed_color_dynamic_mana_source_permanent_v1. This row is package-ready only because the source signature is a narrow activated mana-source permanent with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('white mana battery', 'White Mana Battery', '146ba7850ae9e62899e31511762192b8', 'battle_rule_v1:2c18af306e24412e483c1f377bc744f5', '{"_runtime_partial":true,"_runtime_partial_batch_safe":true,"_runtime_partial_batch_safe_reason":"The DynamicManaAbility mana production is fully modeled by the fixed-color dynamic mana runtime/E2E scenario; auxiliary non-mana abilities remain explicitly unmodeled.","_runtime_partial_reason":"Only the XMage fixed-color DynamicManaAbility is executable in this rule; listed auxiliary ability/effect classes remain unmodeled.","ability_kind":"activated_mana","activation_requires_tap":true,"battle_model_scope":"xmage_fixed_color_dynamic_mana_source_permanent_v1","dynamic_mana_amount_source":"source_named_counter_count_plus_base","dynamic_mana_base_amount":1,"dynamic_mana_counter_type":"charge","effect":"ramp_permanent","is_mana_source":true,"mana_activation_remove_all_source_counters":true,"mana_activation_remove_counter_type":"charge","mana_activation_requires_tap":true,"mana_produced":1,"modeled_ability_subset":"mana_source_only","permanent_type":"artifact","produces":"W","source_mana_cost":"{4}","source_type_line":"Artifact","xmage_ability_classes":["DynamicManaAbility","SimpleActivatedAbility"],"xmage_auxiliary_ability_classes":["SimpleActivatedAbility"],"xmage_effect_classes":["AddCountersSourceEffect"],"xmage_mana_ability_classes":["DynamicManaAbility"],"xmage_unmodeled_auxiliary_ability_classes":["SimpleActivatedAbility"],"xmage_unmodeled_effect_classes":["AddCountersSourceEffect"]}'::jsonb, '{"category":"ramp","effect":"ramp_permanent"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class WhiteManaBattery translated into ManaLoom runtime scope xmage_fixed_color_dynamic_mana_source_permanent_v1. This row is package-ready only because the source signature is a narrow activated mana-source permanent with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
    ('black mana battery', 'Black Mana Battery', 'b37ec304f2e251f0e3e54f417a8b8637', 'battle_rule_v1:64df04747d9d520dd6fa140a1609f998', '{"_runtime_partial":true,"_runtime_partial_batch_safe":true,"_runtime_partial_batch_safe_reason":"The DynamicManaAbility mana production is fully modeled by the fixed-color dynamic mana runtime/E2E scenario; auxiliary non-mana abilities remain explicitly unmodeled.","_runtime_partial_reason":"Only the XMage fixed-color DynamicManaAbility is executable in this rule; listed auxiliary ability/effect classes remain unmodeled.","ability_kind":"activated_mana","activation_requires_tap":true,"battle_model_scope":"xmage_fixed_color_dynamic_mana_source_permanent_v1","dynamic_mana_amount_source":"source_named_counter_count_plus_base","dynamic_mana_base_amount":1,"dynamic_mana_counter_type":"charge","effect":"ramp_permanent","is_mana_source":true,"mana_activation_remove_all_source_counters":true,"mana_activation_remove_counter_type":"charge","mana_activation_requires_tap":true,"mana_produced":1,"modeled_ability_subset":"mana_source_only","permanent_type":"artifact","produces":"B","source_mana_cost":"{4}","source_type_line":"Artifact","xmage_ability_classes":["DynamicManaAbility","SimpleActivatedAbility"],"xmage_auxiliary_ability_classes":["SimpleActivatedAbility"],"xmage_effect_classes":["AddCountersSourceEffect"],"xmage_mana_ability_classes":["DynamicManaAbility"],"xmage_unmodeled_auxiliary_ability_classes":["SimpleActivatedAbility"],"xmage_unmodeled_effect_classes":["AddCountersSourceEffect"]}'::jsonb, '{"category":"ramp","effect":"ramp_permanent"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class BlackManaBattery translated into ManaLoom runtime scope xmage_fixed_color_dynamic_mana_source_permanent_v1. This row is package-ready only because the source signature is a narrow activated mana-source permanent with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('blue mana battery', 'Blue Mana Battery', 'e78d2f67c17533885fad52d18af12b73', 'battle_rule_v1:8ba3f1a54df3d9a74ccb32b233cbce48', '{"_runtime_partial":true,"_runtime_partial_batch_safe":true,"_runtime_partial_batch_safe_reason":"The DynamicManaAbility mana production is fully modeled by the fixed-color dynamic mana runtime/E2E scenario; auxiliary non-mana abilities remain explicitly unmodeled.","_runtime_partial_reason":"Only the XMage fixed-color DynamicManaAbility is executable in this rule; listed auxiliary ability/effect classes remain unmodeled.","ability_kind":"activated_mana","activation_requires_tap":true,"battle_model_scope":"xmage_fixed_color_dynamic_mana_source_permanent_v1","dynamic_mana_amount_source":"source_named_counter_count_plus_base","dynamic_mana_base_amount":1,"dynamic_mana_counter_type":"charge","effect":"ramp_permanent","is_mana_source":true,"mana_activation_remove_all_source_counters":true,"mana_activation_remove_counter_type":"charge","mana_activation_requires_tap":true,"mana_produced":1,"modeled_ability_subset":"mana_source_only","permanent_type":"artifact","produces":"U","source_mana_cost":"{4}","source_type_line":"Artifact","xmage_ability_classes":["DynamicManaAbility","SimpleActivatedAbility"],"xmage_auxiliary_ability_classes":["SimpleActivatedAbility"],"xmage_effect_classes":["AddCountersSourceEffect"],"xmage_mana_ability_classes":["DynamicManaAbility"],"xmage_unmodeled_auxiliary_ability_classes":["SimpleActivatedAbility"],"xmage_unmodeled_effect_classes":["AddCountersSourceEffect"]}'::jsonb, '{"category":"ramp","effect":"ramp_permanent"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class BlueManaBattery translated into ManaLoom runtime scope xmage_fixed_color_dynamic_mana_source_permanent_v1. This row is package-ready only because the source signature is a narrow activated mana-source permanent with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('green mana battery', 'Green Mana Battery', '05a70d5bc68685c1b9f2c8307ab351bc', 'battle_rule_v1:1c28afa796f2fd90e1e452a7a9ea1d45', '{"_runtime_partial":true,"_runtime_partial_batch_safe":true,"_runtime_partial_batch_safe_reason":"The DynamicManaAbility mana production is fully modeled by the fixed-color dynamic mana runtime/E2E scenario; auxiliary non-mana abilities remain explicitly unmodeled.","_runtime_partial_reason":"Only the XMage fixed-color DynamicManaAbility is executable in this rule; listed auxiliary ability/effect classes remain unmodeled.","ability_kind":"activated_mana","activation_requires_tap":true,"battle_model_scope":"xmage_fixed_color_dynamic_mana_source_permanent_v1","dynamic_mana_amount_source":"source_named_counter_count_plus_base","dynamic_mana_base_amount":1,"dynamic_mana_counter_type":"charge","effect":"ramp_permanent","is_mana_source":true,"mana_activation_remove_all_source_counters":true,"mana_activation_remove_counter_type":"charge","mana_activation_requires_tap":true,"mana_produced":1,"modeled_ability_subset":"mana_source_only","permanent_type":"artifact","produces":"G","source_mana_cost":"{4}","source_type_line":"Artifact","xmage_ability_classes":["DynamicManaAbility","SimpleActivatedAbility"],"xmage_auxiliary_ability_classes":["SimpleActivatedAbility"],"xmage_effect_classes":["AddCountersSourceEffect"],"xmage_mana_ability_classes":["DynamicManaAbility"],"xmage_unmodeled_auxiliary_ability_classes":["SimpleActivatedAbility"],"xmage_unmodeled_effect_classes":["AddCountersSourceEffect"]}'::jsonb, '{"category":"ramp","effect":"ramp_permanent"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class GreenManaBattery translated into ManaLoom runtime scope xmage_fixed_color_dynamic_mana_source_permanent_v1. This row is package-ready only because the source signature is a narrow activated mana-source permanent with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('red mana battery', 'Red Mana Battery', '76717f51aba6605bb6f1e922101ced58', 'battle_rule_v1:6f22697fcde8a869fbcdd47b9d92469a', '{"_runtime_partial":true,"_runtime_partial_batch_safe":true,"_runtime_partial_batch_safe_reason":"The DynamicManaAbility mana production is fully modeled by the fixed-color dynamic mana runtime/E2E scenario; auxiliary non-mana abilities remain explicitly unmodeled.","_runtime_partial_reason":"Only the XMage fixed-color DynamicManaAbility is executable in this rule; listed auxiliary ability/effect classes remain unmodeled.","ability_kind":"activated_mana","activation_requires_tap":true,"battle_model_scope":"xmage_fixed_color_dynamic_mana_source_permanent_v1","dynamic_mana_amount_source":"source_named_counter_count_plus_base","dynamic_mana_base_amount":1,"dynamic_mana_counter_type":"charge","effect":"ramp_permanent","is_mana_source":true,"mana_activation_remove_all_source_counters":true,"mana_activation_remove_counter_type":"charge","mana_activation_requires_tap":true,"mana_produced":1,"modeled_ability_subset":"mana_source_only","permanent_type":"artifact","produces":"R","source_mana_cost":"{4}","source_type_line":"Artifact","xmage_ability_classes":["DynamicManaAbility","SimpleActivatedAbility"],"xmage_auxiliary_ability_classes":["SimpleActivatedAbility"],"xmage_effect_classes":["AddCountersSourceEffect"],"xmage_mana_ability_classes":["DynamicManaAbility"],"xmage_unmodeled_auxiliary_ability_classes":["SimpleActivatedAbility"],"xmage_unmodeled_effect_classes":["AddCountersSourceEffect"]}'::jsonb, '{"category":"ramp","effect":"ramp_permanent"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class RedManaBattery translated into ManaLoom runtime scope xmage_fixed_color_dynamic_mana_source_permanent_v1. This row is package-ready only because the source signature is a narrow activated mana-source permanent with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('white mana battery', 'White Mana Battery', '146ba7850ae9e62899e31511762192b8', 'battle_rule_v1:2c18af306e24412e483c1f377bc744f5', '{"_runtime_partial":true,"_runtime_partial_batch_safe":true,"_runtime_partial_batch_safe_reason":"The DynamicManaAbility mana production is fully modeled by the fixed-color dynamic mana runtime/E2E scenario; auxiliary non-mana abilities remain explicitly unmodeled.","_runtime_partial_reason":"Only the XMage fixed-color DynamicManaAbility is executable in this rule; listed auxiliary ability/effect classes remain unmodeled.","ability_kind":"activated_mana","activation_requires_tap":true,"battle_model_scope":"xmage_fixed_color_dynamic_mana_source_permanent_v1","dynamic_mana_amount_source":"source_named_counter_count_plus_base","dynamic_mana_base_amount":1,"dynamic_mana_counter_type":"charge","effect":"ramp_permanent","is_mana_source":true,"mana_activation_remove_all_source_counters":true,"mana_activation_remove_counter_type":"charge","mana_activation_requires_tap":true,"mana_produced":1,"modeled_ability_subset":"mana_source_only","permanent_type":"artifact","produces":"W","source_mana_cost":"{4}","source_type_line":"Artifact","xmage_ability_classes":["DynamicManaAbility","SimpleActivatedAbility"],"xmage_auxiliary_ability_classes":["SimpleActivatedAbility"],"xmage_effect_classes":["AddCountersSourceEffect"],"xmage_mana_ability_classes":["DynamicManaAbility"],"xmage_unmodeled_auxiliary_ability_classes":["SimpleActivatedAbility"],"xmage_unmodeled_effect_classes":["AddCountersSourceEffect"]}'::jsonb, '{"category":"ramp","effect":"ramp_permanent"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class WhiteManaBattery translated into ManaLoom runtime scope xmage_fixed_color_dynamic_mana_source_permanent_v1. This row is package-ready only because the source signature is a narrow activated mana-source permanent with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
