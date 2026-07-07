WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('disallow', 'Disallow', 'dab97474ff3f3f0c35c8a01c3841de37', 'battle_rule_v1:5072c4680123be4302b45c3d15980230', '{"battle_model_scope":"xmage_counter_target_spell_v1","effect":"counter","instant":true,"sorcery":false,"target":"spell_or_activated_or_triggered_ability","target_constraints":{"any_of":[{"stack_object":"spell"},{"stack_object":"activated_ability"},{"stack_object":"triggered_ability"}],"zone":"stack"},"xmage_effect_class":"CounterTargetEffect"}'::jsonb, '{"category":"protection","effect":"counter","target":"spell_or_activated_or_triggered_ability","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Disallow translated into ManaLoom runtime scope xmage_counter_target_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('stern scolding', 'Stern Scolding', 'f26dd82537e6e5c9206d47a50fa691c3', 'battle_rule_v1:5286b6c6a626a88c60e657c46eef1105', '{"battle_model_scope":"xmage_counter_target_spell_v1","effect":"counter","instant":true,"sorcery":false,"target":"creature_spell_power_or_toughness_2_or_less","target_constraints":{"card_types":["creature"],"power_or_toughness_max":2,"stack_object":"spell","zone":"stack"},"xmage_effect_class":"CounterTargetEffect"}'::jsonb, '{"category":"protection","effect":"counter","target":"creature_spell_power_or_toughness_2_or_less","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class SternScolding translated into ManaLoom runtime scope xmage_counter_target_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('tale''s end', 'Tale''s End', '1347d000d1e4acf8d2675e1ed216b6f7', 'battle_rule_v1:f70b57cccbd61a55ec60298342a6613c', '{"battle_model_scope":"xmage_counter_target_spell_v1","effect":"counter","instant":true,"sorcery":false,"target":"activated_or_triggered_ability_or_legendary_spell","target_constraints":{"any_of":[{"stack_object":"activated_ability"},{"stack_object":"triggered_ability"},{"require_legendary":true,"stack_object":"spell"}],"zone":"stack"},"xmage_effect_class":"CounterTargetEffect"}'::jsonb, '{"category":"protection","effect":"counter","target":"activated_or_triggered_ability_or_legendary_spell","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class TalesEnd translated into ManaLoom runtime scope xmage_counter_target_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('voidslime', 'Voidslime', 'dab97474ff3f3f0c35c8a01c3841de37', 'battle_rule_v1:5072c4680123be4302b45c3d15980230', '{"battle_model_scope":"xmage_counter_target_spell_v1","effect":"counter","instant":true,"sorcery":false,"target":"spell_or_activated_or_triggered_ability","target_constraints":{"any_of":[{"stack_object":"spell"},{"stack_object":"activated_ability"},{"stack_object":"triggered_ability"}],"zone":"stack"},"xmage_effect_class":"CounterTargetEffect"}'::jsonb, '{"category":"protection","effect":"counter","target":"spell_or_activated_or_triggered_ability","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Voidslime translated into ManaLoom runtime scope xmage_counter_target_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
