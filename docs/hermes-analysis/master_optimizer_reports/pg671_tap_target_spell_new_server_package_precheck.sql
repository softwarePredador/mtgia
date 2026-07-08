WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('downpour', 'Downpour', 'd68899a467f06f7eb5a4978ed3531b0f', 'battle_rule_v1:97b5de80477f9460ef784533e6024927', '{"battle_model_scope":"xmage_tap_target_spell_v1","effect":"tap_target","instant":true,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"]},"target_count":3,"target_count_max":3,"up_to_count":true,"xmage_effect_class":"TapTargetEffect"}'::jsonb, '{"category":"unknown","effect":"tap_target","target":"creature","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Downpour translated into ManaLoom runtime scope xmage_tap_target_spell_v1. This row is package-ready only because the source signature is a narrow instant or sorcery spell that taps exact target permanents with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('early frost', 'Early Frost', '92375c3d37f9d764358fb389cadb5e48', 'battle_rule_v1:4fc24a112121a24561daf0f372287872', '{"battle_model_scope":"xmage_tap_target_spell_v1","effect":"tap_target","instant":true,"sorcery":false,"target":"land","target_constraints":{"card_types":["land"]},"target_count":3,"target_count_max":3,"up_to_count":true,"xmage_effect_class":"TapTargetEffect"}'::jsonb, '{"category":"unknown","effect":"tap_target","target":"land","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class EarlyFrost translated into ManaLoom runtime scope xmage_tap_target_spell_v1. This row is package-ready only because the source signature is a narrow instant or sorcery spell that taps exact target permanents with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('gridlock', 'Gridlock', 'f3799a0d79c5a1e04a784fdd1702acea', 'battle_rule_v1:5bebfc1427545887eb7efb9e503d4fe8', '{"battle_model_scope":"xmage_tap_target_spell_v1","effect":"tap_target","instant":true,"sorcery":false,"target":"nonland_permanent","target_constraints":{"card_types":["permanent"],"exclude_card_types":["land"]},"target_count_from_x":true,"target_count_source":"x_value","up_to_count":false,"xmage_effect_class":"TapTargetEffect"}'::jsonb, '{"category":"unknown","effect":"tap_target","target":"nonland_permanent","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Gridlock translated into ManaLoom runtime scope xmage_tap_target_spell_v1. This row is package-ready only because the source signature is a narrow instant or sorcery spell that taps exact target permanents with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('lead astray', 'Lead Astray', 'c9ce98f65a5953a641363e2edeb41de7', 'battle_rule_v1:db6c12f90bdf648e5a86a83c2164ff64', '{"battle_model_scope":"xmage_tap_target_spell_v1","effect":"tap_target","instant":true,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"]},"target_count":2,"target_count_max":2,"up_to_count":true,"xmage_effect_class":"TapTargetEffect"}'::jsonb, '{"category":"unknown","effect":"tap_target","target":"creature","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class LeadAstray translated into ManaLoom runtime scope xmage_tap_target_spell_v1. This row is package-ready only because the source signature is a narrow instant or sorcery spell that taps exact target permanents with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('terashi''s cry', 'Terashi''s Cry', 'd68899a467f06f7eb5a4978ed3531b0f', 'battle_rule_v1:005cb5d615bbf9ed00e95157bdae79f4', '{"battle_model_scope":"xmage_tap_target_spell_v1","effect":"tap_target","instant":false,"sorcery":true,"target":"creature","target_constraints":{"card_types":["creature"]},"target_count":3,"target_count_max":3,"up_to_count":true,"xmage_effect_class":"TapTargetEffect"}'::jsonb, '{"category":"unknown","effect":"tap_target","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class TerashisCry translated into ManaLoom runtime scope xmage_tap_target_spell_v1. This row is package-ready only because the source signature is a narrow instant or sorcery spell that taps exact target permanents with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('word of binding', 'Word of Binding', '61e37e31093d1088e19be84db7c70d19', 'battle_rule_v1:a28fb929f055841a3fbe611c9dc7ca67', '{"battle_model_scope":"xmage_tap_target_spell_v1","effect":"tap_target","instant":false,"sorcery":true,"target":"creature","target_constraints":{"card_types":["creature"]},"target_count_from_x":true,"target_count_source":"x_value","up_to_count":false,"xmage_effect_class":"TapTargetEffect"}'::jsonb, '{"category":"unknown","effect":"tap_target","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class WordOfBinding translated into ManaLoom runtime scope xmage_tap_target_spell_v1. This row is package-ready only because the source signature is a narrow instant or sorcery spell that taps exact target permanents with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
