WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('bind', 'Bind', '411b586d3d4f0d5a307e81bcc05388be', 'battle_rule_v1:880274ce7e5acbdff6b6bac0b95165e0', '{"_composite_rule_components":[{"battle_model_scope":"xmage_counter_target_spell_v1","effect":"counter","target":"activated_ability","target_constraints":{"stack_object":"activated_ability","zone":"stack"},"xmage_effect_class":"CounterTargetEffect"},{"battle_model_scope":"xmage_fixed_source_controller_draw_spell_v1","compose_on_resolution":true,"count":1,"effect":"draw_cards","xmage_effect_class":"DrawCardSourceControllerEffect"}],"battle_model_scope":"xmage_counter_target_and_draw_card_spell_v1","count":1,"draw_count":1,"draw_on_counter":1,"effect":"counter","instant":true,"sorcery":false,"target":"activated_ability","target_constraints":{"stack_object":"activated_ability","zone":"stack"},"xmage_effect_classes":["CounterTargetEffect","DrawCardSourceControllerEffect"]}'::jsonb, '{"category":"protection","effect":"counter","target":"activated_ability","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Bind translated into ManaLoom runtime scope xmage_counter_target_and_draw_card_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('bind // liberate', 'Bind // Liberate', '411b586d3d4f0d5a307e81bcc05388be', 'battle_rule_v1:880274ce7e5acbdff6b6bac0b95165e0', '{"_composite_rule_components":[{"battle_model_scope":"xmage_counter_target_spell_v1","effect":"counter","target":"activated_ability","target_constraints":{"stack_object":"activated_ability","zone":"stack"},"xmage_effect_class":"CounterTargetEffect"},{"battle_model_scope":"xmage_fixed_source_controller_draw_spell_v1","compose_on_resolution":true,"count":1,"effect":"draw_cards","xmage_effect_class":"DrawCardSourceControllerEffect"}],"battle_model_scope":"xmage_counter_target_and_draw_card_spell_v1","count":1,"draw_count":1,"draw_on_counter":1,"effect":"counter","instant":true,"sorcery":false,"target":"activated_ability","target_constraints":{"stack_object":"activated_ability","zone":"stack"},"xmage_effect_classes":["CounterTargetEffect","DrawCardSourceControllerEffect"]}'::jsonb, '{"category":"protection","effect":"counter","target":"activated_ability","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Bind translated into ManaLoom runtime scope xmage_counter_target_and_draw_card_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('squelch', 'Squelch', '411b586d3d4f0d5a307e81bcc05388be', 'battle_rule_v1:880274ce7e5acbdff6b6bac0b95165e0', '{"_composite_rule_components":[{"battle_model_scope":"xmage_counter_target_spell_v1","effect":"counter","target":"activated_ability","target_constraints":{"stack_object":"activated_ability","zone":"stack"},"xmage_effect_class":"CounterTargetEffect"},{"battle_model_scope":"xmage_fixed_source_controller_draw_spell_v1","compose_on_resolution":true,"count":1,"effect":"draw_cards","xmage_effect_class":"DrawCardSourceControllerEffect"}],"battle_model_scope":"xmage_counter_target_and_draw_card_spell_v1","count":1,"draw_count":1,"draw_on_counter":1,"effect":"counter","instant":true,"sorcery":false,"target":"activated_ability","target_constraints":{"stack_object":"activated_ability","zone":"stack"},"xmage_effect_classes":["CounterTargetEffect","DrawCardSourceControllerEffect"]}'::jsonb, '{"category":"protection","effect":"counter","target":"activated_ability","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Squelch translated into ManaLoom runtime scope xmage_counter_target_and_draw_card_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
