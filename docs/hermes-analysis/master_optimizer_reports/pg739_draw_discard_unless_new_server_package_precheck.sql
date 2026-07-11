WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('mystic meditation', 'Mystic Meditation', '01d3b4c57212f046fe7fc11df5443477', 'battle_rule_v1:c678f64df56cf307c5d9c3a15cad897a', '{"battle_model_scope":"xmage_fixed_draw_discard_spell_v1","count":3,"discard_count":2,"discard_random":false,"discard_unless_card_types":["creature"],"discard_unless_count":1,"discard_unless_filter":"creature_card","discard_unless_status":"runtime_executor_v1","draw_count":3,"draw_discard_order":"draw_then_discard","draw_discard_spell":true,"effect":"draw_cards","instant":false,"sorcery":true,"xmage_effect_classes":["DrawCardSourceControllerEffect","DiscardControllerEffect"]}'::jsonb, '{"category":"draw","effect":"draw_cards"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class MysticMeditation translated into ManaLoom runtime scope xmage_fixed_draw_discard_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('thirst for discovery', 'Thirst for Discovery', '9de9e1308d1010387496685c78374e66', 'battle_rule_v1:aefeda576530cf9ef2de5aed32c96bac', '{"battle_model_scope":"xmage_fixed_draw_discard_spell_v1","count":3,"discard_count":2,"discard_random":false,"discard_unless_basic_land":true,"discard_unless_card_types":["land"],"discard_unless_count":1,"discard_unless_filter":"basic_land_card","discard_unless_status":"runtime_executor_v1","draw_count":3,"draw_discard_order":"draw_then_discard","draw_discard_spell":true,"effect":"draw_cards","instant":true,"sorcery":false,"xmage_effect_classes":["DrawCardSourceControllerEffect","DiscardControllerEffect"]}'::jsonb, '{"category":"draw","effect":"draw_cards","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ThirstForDiscovery translated into ManaLoom runtime scope xmage_fixed_draw_discard_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('thirst for identity', 'Thirst for Identity', '01d3b4c57212f046fe7fc11df5443477', 'battle_rule_v1:236da04cc9f3583da4986ec711e3148b', '{"battle_model_scope":"xmage_fixed_draw_discard_spell_v1","count":3,"discard_count":2,"discard_random":false,"discard_unless_card_types":["creature"],"discard_unless_count":1,"discard_unless_filter":"creature_card","discard_unless_status":"runtime_executor_v1","draw_count":3,"draw_discard_order":"draw_then_discard","draw_discard_spell":true,"effect":"draw_cards","instant":true,"sorcery":false,"xmage_effect_classes":["DrawCardSourceControllerEffect","DiscardControllerEffect"]}'::jsonb, '{"category":"draw","effect":"draw_cards","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ThirstForIdentity translated into ManaLoom runtime scope xmage_fixed_draw_discard_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('thirst for knowledge', 'Thirst for Knowledge', '0f757e71e8213ba2a660219d9262cecb', 'battle_rule_v1:02810d99f1cb96bec4b8d39623ba0751', '{"battle_model_scope":"xmage_fixed_draw_discard_spell_v1","count":3,"discard_count":2,"discard_random":false,"discard_unless_card_types":["artifact"],"discard_unless_count":1,"discard_unless_filter":"artifact_card","discard_unless_status":"runtime_executor_v1","draw_count":3,"draw_discard_order":"draw_then_discard","draw_discard_spell":true,"effect":"draw_cards","instant":true,"sorcery":false,"xmage_effect_classes":["DrawCardSourceControllerEffect","DiscardControllerEffect"]}'::jsonb, '{"category":"draw","effect":"draw_cards","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ThirstForKnowledge translated into ManaLoom runtime scope xmage_fixed_draw_discard_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('thirst for meaning', 'Thirst for Meaning', '7433d8f7f2b705ff1783ccf16c296b2f', 'battle_rule_v1:e9b8c97c26e35decce39a5544d12253f', '{"battle_model_scope":"xmage_fixed_draw_discard_spell_v1","count":3,"discard_count":2,"discard_random":false,"discard_unless_card_types":["enchantment"],"discard_unless_count":1,"discard_unless_filter":"enchantment_card","discard_unless_status":"runtime_executor_v1","draw_count":3,"draw_discard_order":"draw_then_discard","draw_discard_spell":true,"effect":"draw_cards","instant":true,"sorcery":false,"xmage_effect_classes":["DrawCardSourceControllerEffect","DiscardControllerEffect"]}'::jsonb, '{"category":"draw","effect":"draw_cards","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ThirstForMeaning translated into ManaLoom runtime scope xmage_fixed_draw_discard_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
