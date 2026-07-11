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
