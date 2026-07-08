WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('avoid fate', 'Avoid Fate', '247fe0d287580539b1a5d1d7c4c2c9e3', 'battle_rule_v1:1ab07f98d615423be90bceaf1f36809f', '{"battle_model_scope":"xmage_counter_target_spell_v1","effect":"counter","instant":true,"sorcery":false,"target":"instant_or_aura_spell_targeting_permanent_you_control","target_constraints":{"any_of":[{"spell_types":["instant"]},{"spell_subtypes":["aura"]}],"spell_targets":"permanent_you_control","stack_object":"spell","zone":"stack"},"xmage_effect_class":"CounterTargetEffect"}'::jsonb, '{"category":"protection","effect":"counter","target":"instant_or_aura_spell_targeting_permanent_you_control","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class AvoidFate translated into ManaLoom runtime scope xmage_counter_target_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('double negative', 'Double Negative', '8c0e2236e17f1116023c514803871142', 'battle_rule_v1:a28bd14d1761b96b8a5098e10a592d23', '{"battle_model_scope":"xmage_counter_target_spell_v1","effect":"counter","instant":true,"max_targets":2,"sorcery":false,"target":"spell","target_constraints":{"stack_object":"spell","zone":"stack"},"target_count":2,"target_count_max":2,"target_count_min":0,"up_to_count":true,"xmage_effect_class":"CounterTargetEffect"}'::jsonb, '{"category":"protection","effect":"counter","target":"spell","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class DoubleNegative translated into ManaLoom runtime scope xmage_counter_target_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('outwit', 'Outwit', '24613df0ad9bf5d7b822df6729feae90', 'battle_rule_v1:6fb9c8def6ed30ea4fe726171e69e50d', '{"battle_model_scope":"xmage_counter_target_spell_v1","effect":"counter","instant":true,"sorcery":false,"target":"spell_targeting_player","target_constraints":{"spell_targets":"player","stack_object":"spell","zone":"stack"},"xmage_effect_class":"CounterTargetEffect"}'::jsonb, '{"category":"protection","effect":"counter","target":"spell_targeting_player","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Outwit translated into ManaLoom runtime scope xmage_counter_target_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('second guess', 'Second Guess', '44125098597f0f4640d14aba657de868', 'battle_rule_v1:dc290b2d1a7523365619629d95f138af', '{"battle_model_scope":"xmage_counter_target_spell_v1","effect":"counter","instant":true,"sorcery":false,"target":"spell_second_spell_this_turn","target_constraints":{"spell_order_this_turn":2,"stack_object":"spell","zone":"stack"},"xmage_effect_class":"CounterTargetEffect"}'::jsonb, '{"category":"protection","effect":"counter","target":"spell_second_spell_this_turn","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class SecondGuess translated into ManaLoom runtime scope xmage_counter_target_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
