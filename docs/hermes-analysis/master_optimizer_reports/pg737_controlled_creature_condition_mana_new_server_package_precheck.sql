WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('ilysian caryatid', 'Ilysian Caryatid', '38bdfde44fc92b2697d1939332bcf207', 'battle_rule_v1:f7bf9957a984ed49743b2184f4d94e68', '{"ability_kind":"activated_mana","activation_requires_tap":true,"battle_model_scope":"xmage_controlled_creature_condition_conditional_mana_source_permanent_v1","conditional_mana_controlled_creature_power_gte":4,"conditional_mana_modes":[{"color":"W","mode":"controlled_creature_power_gte","restriction":"any_spell","status":"runtime_executor_v1"},{"color":"U","mode":"controlled_creature_power_gte","restriction":"any_spell","status":"runtime_executor_v1"},{"color":"B","mode":"controlled_creature_power_gte","restriction":"any_spell","status":"runtime_executor_v1"},{"color":"R","mode":"controlled_creature_power_gte","restriction":"any_spell","status":"runtime_executor_v1"},{"color":"G","mode":"controlled_creature_power_gte","restriction":"any_spell","status":"runtime_executor_v1"}],"conditional_mana_modes_status":"runtime_executor_v1","conditional_mana_produced_when_condition_met":2,"conditional_mana_same_color_choice":true,"effect":"ramp_permanent","is_mana_source":true,"mana_activation_requires_tap":true,"mana_produced":1,"permanent_type":"creature","produces":"WUBRG","source_mana_cost":"{1}{G}","source_type_line":"Creature \u2014 Plant","xmage_ability_classes":["SimpleManaAbility"],"xmage_effect_classes":["AddManaOfAnyColorEffect","ConditionalManaEffect"],"xmage_mana_ability_classes":["SimpleManaAbility"]}'::jsonb, '{"category":"ramp","effect":"ramp_permanent"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class IlysianCaryatid translated into ManaLoom runtime scope xmage_controlled_creature_condition_conditional_mana_source_permanent_v1. This row is package-ready only because the source signature is a narrow activated mana-source permanent with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('leafkin druid', 'Leafkin Druid', 'f4f34beee7cb633d257735bb4e516104', 'battle_rule_v1:50ff722ab7e4ef327443b24ad10cfd68', '{"ability_kind":"activated_mana","activation_requires_tap":true,"battle_model_scope":"xmage_controlled_creature_condition_conditional_mana_source_permanent_v1","conditional_mana_controlled_creature_count_gte":4,"conditional_mana_produced_when_condition_met":2,"effect":"ramp_permanent","is_mana_source":true,"mana_activation_requires_tap":true,"mana_produced":1,"permanent_type":"creature","produced_mana_symbols":["G","G"],"produces":"G","source_mana_cost":"{1}{G}","source_type_line":"Creature \u2014 Elemental Druid","xmage_ability_classes":["SimpleManaAbility"],"xmage_effect_classes":["BasicManaEffect","ConditionalManaEffect"],"xmage_mana_ability_classes":["SimpleManaAbility"]}'::jsonb, '{"category":"ramp","effect":"ramp_permanent"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class LeafkinDruid translated into ManaLoom runtime scope xmage_controlled_creature_condition_conditional_mana_source_permanent_v1. This row is package-ready only because the source signature is a narrow activated mana-source permanent with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('raucous audience', 'Raucous Audience', '280a0375aa62b8b4018d4ebb02f8439e', 'battle_rule_v1:26d851707d7fc9eb84ba09ee75d9937a', '{"ability_kind":"activated_mana","activation_requires_tap":true,"battle_model_scope":"xmage_controlled_creature_condition_conditional_mana_source_permanent_v1","conditional_mana_controlled_creature_power_gte":4,"conditional_mana_produced_when_condition_met":2,"effect":"ramp_permanent","is_mana_source":true,"mana_activation_requires_tap":true,"mana_produced":1,"permanent_type":"creature","produced_mana_symbols":["G","G"],"produces":"G","source_mana_cost":"{1}{G}","source_type_line":"Creature \u2014 Human Citizen","xmage_ability_classes":["SimpleManaAbility"],"xmage_effect_classes":["BasicManaEffect","ConditionalManaEffect"],"xmage_mana_ability_classes":["SimpleManaAbility"]}'::jsonb, '{"category":"ramp","effect":"ramp_permanent"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class RaucousAudience translated into ManaLoom runtime scope xmage_controlled_creature_condition_conditional_mana_source_permanent_v1. This row is package-ready only because the source signature is a narrow activated mana-source permanent with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
