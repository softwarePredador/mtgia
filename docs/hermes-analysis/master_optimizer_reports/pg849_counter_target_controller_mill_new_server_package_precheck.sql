WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('countermand', 'Countermand', '37339221401fd8154c74806cb83bd49a', 'battle_rule_v1:f402fd7b0ba896c377a82bcafb4211c0', '{"_composite_rule_components":[{"battle_model_scope":"xmage_counter_target_spell_v1","effect":"counter","target":"spell","target_constraints":{"stack_object":"spell","zone":"stack"},"xmage_effect_class":"CounterTargetEffect"},{"battle_model_scope":"xmage_fixed_target_player_mill_spell_v1","compose_on_resolution":true,"count":4,"effect":"mill_cards","mill_count":4,"target":"target_controller","target_player_mill":true,"xmage_effect_class":"CountermandEffect"}],"battle_model_scope":"xmage_counter_target_and_target_controller_mill_spell_v1","effect":"counter","instant":true,"mill_count":4,"resolution_order":"counter_then_target_controller_mill","sorcery":false,"target":"spell","target_constraints":{"stack_object":"spell","zone":"stack"},"target_controller_mill_on_counter":4,"target_player_mill":true,"xmage_effect_classes":["CountermandEffect","OneShotEffect"]}'::jsonb, '{"category":"protection","effect":"counter","target":"spell","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Countermand translated into ManaLoom runtime scope xmage_counter_target_and_target_controller_mill_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('didn''t say please', 'Didn''t Say Please', '1d9b8324a53964a8dc4a4b79ca4e0ac2', 'battle_rule_v1:3c0bee9a432ecc6ed6777b2f880a5145', '{"_composite_rule_components":[{"battle_model_scope":"xmage_counter_target_spell_v1","effect":"counter","target":"spell","target_constraints":{"stack_object":"spell","zone":"stack"},"xmage_effect_class":"CounterTargetEffect"},{"battle_model_scope":"xmage_fixed_target_player_mill_spell_v1","compose_on_resolution":true,"count":3,"effect":"mill_cards","mill_count":3,"target":"target_controller","target_player_mill":true,"xmage_effect_class":"DidntSayPleaseEffect"}],"battle_model_scope":"xmage_counter_target_and_target_controller_mill_spell_v1","effect":"counter","instant":true,"mill_count":3,"resolution_order":"counter_then_target_controller_mill","sorcery":false,"target":"spell","target_constraints":{"stack_object":"spell","zone":"stack"},"target_controller_mill_on_counter":3,"target_player_mill":true,"xmage_effect_classes":["CounterTargetEffect","DidntSayPleaseEffect","OneShotEffect"]}'::jsonb, '{"category":"protection","effect":"counter","target":"spell","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class DidntSayPlease translated into ManaLoom runtime scope xmage_counter_target_and_target_controller_mill_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('psychic strike', 'Psychic Strike', 'cdc9a084c42879b19393966222db8237', 'battle_rule_v1:57349935a74c3f3e23997e05f68a8b1a', '{"_composite_rule_components":[{"battle_model_scope":"xmage_counter_target_spell_v1","effect":"counter","target":"spell","target_constraints":{"stack_object":"spell","zone":"stack"},"xmage_effect_class":"CounterTargetEffect"},{"battle_model_scope":"xmage_fixed_target_player_mill_spell_v1","compose_on_resolution":true,"count":2,"effect":"mill_cards","mill_count":2,"target":"target_controller","target_player_mill":true,"xmage_effect_class":"PsychicStrikeEffect"}],"battle_model_scope":"xmage_counter_target_and_target_controller_mill_spell_v1","effect":"counter","instant":true,"mill_count":2,"resolution_order":"counter_then_target_controller_mill","sorcery":false,"target":"spell","target_constraints":{"stack_object":"spell","zone":"stack"},"target_controller_mill_on_counter":2,"target_player_mill":true,"xmage_effect_classes":["OneShotEffect","PsychicStrikeEffect"]}'::jsonb, '{"category":"protection","effect":"counter","target":"spell","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class PsychicStrike translated into ManaLoom runtime scope xmage_counter_target_and_target_controller_mill_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('thought collapse', 'Thought Collapse', '1d9b8324a53964a8dc4a4b79ca4e0ac2', 'battle_rule_v1:be6aee29492f6a8dda8894351e7e3474', '{"_composite_rule_components":[{"battle_model_scope":"xmage_counter_target_spell_v1","effect":"counter","target":"spell","target_constraints":{"stack_object":"spell","zone":"stack"},"xmage_effect_class":"CounterTargetEffect"},{"battle_model_scope":"xmage_fixed_target_player_mill_spell_v1","compose_on_resolution":true,"count":3,"effect":"mill_cards","mill_count":3,"target":"target_controller","target_player_mill":true,"xmage_effect_class":"ThoughtCollapseEffect"}],"battle_model_scope":"xmage_counter_target_and_target_controller_mill_spell_v1","effect":"counter","instant":true,"mill_count":3,"resolution_order":"counter_then_target_controller_mill","sorcery":false,"target":"spell","target_constraints":{"stack_object":"spell","zone":"stack"},"target_controller_mill_on_counter":3,"target_player_mill":true,"xmage_effect_classes":["CounterTargetEffect","OneShotEffect","ThoughtCollapseEffect"]}'::jsonb, '{"category":"protection","effect":"counter","target":"spell","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ThoughtCollapse translated into ManaLoom runtime scope xmage_counter_target_and_target_controller_mill_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
