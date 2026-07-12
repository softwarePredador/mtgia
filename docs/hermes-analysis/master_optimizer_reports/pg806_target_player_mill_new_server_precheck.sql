WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('glimpse the unthinkable', 'Glimpse the Unthinkable', 'e16b3be95a08354fc076ff23a883f997', 'battle_rule_v1:26e090742b0b13e87d1f9bf6fc965891', '{"battle_model_scope":"xmage_fixed_target_player_mill_spell_v1","count":10,"effect":"mill_cards","instant":false,"mill_count":10,"sorcery":true,"target":"player","target_constraints":{"players":["any"]},"target_controller":"target_player","target_player_mill":true,"target_player_scope":"any","target_preference":"opponent","xmage_effect_class":"MillCardsTargetEffect"}'::jsonb, '{"category":"wincon","effect":"mill_cards","subtype":"library_mill","target":"player"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class GlimpseTheUnthinkable translated into ManaLoom runtime scope xmage_fixed_target_player_mill_spell_v1. This row is package-ready only because the source signature is a narrow fixed target-player mill spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('mind sculpt', 'Mind Sculpt', 'f42f6fc25a0f27270644bb87317e60ce', 'battle_rule_v1:88cc251a233283c4f9a4337283de4c3a', '{"battle_model_scope":"xmage_fixed_target_player_mill_spell_v1","count":7,"effect":"mill_cards","instant":false,"mill_count":7,"sorcery":true,"target":"player","target_constraints":{"players":["opponent"]},"target_controller":"target_player","target_player_mill":true,"target_player_scope":"opponent","target_preference":"opponent","xmage_effect_class":"MillCardsTargetEffect"}'::jsonb, '{"category":"wincon","effect":"mill_cards","subtype":"library_mill","target":"player"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class MindSculpt translated into ManaLoom runtime scope xmage_fixed_target_player_mill_spell_v1. This row is package-ready only because the source signature is a narrow fixed target-player mill spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('tome scour', 'Tome Scour', 'abf0b04f9971161f7dfaf8449ebbdc8f', 'battle_rule_v1:38770bcda919ef9e031373d431e6297d', '{"battle_model_scope":"xmage_fixed_target_player_mill_spell_v1","count":5,"effect":"mill_cards","instant":false,"mill_count":5,"sorcery":true,"target":"player","target_constraints":{"players":["any"]},"target_controller":"target_player","target_player_mill":true,"target_player_scope":"any","target_preference":"opponent","xmage_effect_class":"MillCardsTargetEffect"}'::jsonb, '{"category":"wincon","effect":"mill_cards","subtype":"library_mill","target":"player"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class TomeScour translated into ManaLoom runtime scope xmage_fixed_target_player_mill_spell_v1. This row is package-ready only because the source signature is a narrow fixed target-player mill spell with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
