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
