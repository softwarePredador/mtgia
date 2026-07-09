WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('assert authority', 'Assert Authority', 'e7e55ff661b00c18b06a0440ae09f5c3', 'battle_rule_v1:b93da3b7d54ae3de7cb4445ca5d21f27', '{"battle_model_scope":"xmage_counter_target_spell_v1","countered_spell_to_exile":true,"countered_spell_to_exile_reason":"counter_target_exile_replacement","effect":"counter","instant":true,"sorcery":false,"target":"spell","target_constraints":{"stack_object":"spell","zone":"stack"},"xmage_effect_class":"CounterTargetWithReplacementEffect"}'::jsonb, '{"category":"protection","effect":"counter","target":"spell","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class AssertAuthority translated into ManaLoom runtime scope xmage_counter_target_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('deny existence', 'Deny Existence', '9ef9d5e5c3a197765e7ed3fc010d4694', 'battle_rule_v1:9a8fc3452aadc7a476e2a80a40933258', '{"battle_model_scope":"xmage_counter_target_spell_v1","countered_spell_to_exile":true,"countered_spell_to_exile_reason":"counter_target_exile_replacement","effect":"counter","instant":true,"sorcery":false,"target":"creature_spell","target_constraints":{"card_types":["creature"],"stack_object":"spell","zone":"stack"},"xmage_effect_class":"CounterTargetWithReplacementEffect"}'::jsonb, '{"category":"protection","effect":"counter","target":"creature_spell","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class DenyExistence translated into ManaLoom runtime scope xmage_counter_target_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('deny the divine', 'Deny the Divine', '0b49f6a07dfab50146e385e07f91d0cd', 'battle_rule_v1:a93f6af5442ff3883dd9f67b59aabc33', '{"battle_model_scope":"xmage_counter_target_spell_v1","countered_spell_to_exile":true,"countered_spell_to_exile_reason":"counter_target_exile_replacement","effect":"counter","instant":true,"sorcery":false,"target":"creature_or_enchantment_spell","target_constraints":{"card_types":["creature","enchantment"],"stack_object":"spell","zone":"stack"},"xmage_effect_class":"CounterTargetWithReplacementEffect"}'::jsonb, '{"category":"protection","effect":"counter","target":"creature_or_enchantment_spell","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class DenyTheDivine translated into ManaLoom runtime scope xmage_counter_target_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('dissipate', 'Dissipate', '307fb6896c67fa1a3661968432a66241', 'battle_rule_v1:b93da3b7d54ae3de7cb4445ca5d21f27', '{"battle_model_scope":"xmage_counter_target_spell_v1","countered_spell_to_exile":true,"countered_spell_to_exile_reason":"counter_target_exile_replacement","effect":"counter","instant":true,"sorcery":false,"target":"spell","target_constraints":{"stack_object":"spell","zone":"stack"},"xmage_effect_class":"CounterTargetWithReplacementEffect"}'::jsonb, '{"category":"protection","effect":"counter","target":"spell","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Dissipate translated into ManaLoom runtime scope xmage_counter_target_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('faerie trickery', 'Faerie Trickery', '191228b05399a640b3409b2bce5a32e5', 'battle_rule_v1:02debaf82ed6175dfb4cd42134317ce8', '{"battle_model_scope":"xmage_counter_target_spell_v1","countered_spell_to_exile":true,"countered_spell_to_exile_reason":"counter_target_exile_replacement","effect":"counter","instant":true,"sorcery":false,"target":"nonfaerie_spell","target_constraints":{"exclude_spell_subtypes":["faerie"],"stack_object":"spell","zone":"stack"},"xmage_effect_class":"CounterTargetWithReplacementEffect"}'::jsonb, '{"category":"protection","effect":"counter","target":"nonfaerie_spell","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class FaerieTrickery translated into ManaLoom runtime scope xmage_counter_target_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('horribly awry', 'Horribly Awry', '769649f9202fe62cde39074275097cb4', 'battle_rule_v1:7f961c618cf035b3060297e5be43e3a4', '{"battle_model_scope":"xmage_counter_target_spell_v1","countered_spell_to_exile":true,"countered_spell_to_exile_reason":"counter_target_exile_replacement","effect":"counter","instant":true,"sorcery":false,"target":"creature_spell_mana_value_4_or_less","target_constraints":{"card_types":["creature"],"counter_target_mana_value_max":4,"stack_object":"spell","zone":"stack"},"xmage_effect_class":"CounterTargetWithReplacementEffect"}'::jsonb, '{"category":"protection","effect":"counter","target":"creature_spell_mana_value_4_or_less","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class HorriblyAwry translated into ManaLoom runtime scope xmage_counter_target_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('liquify', 'Liquify', '4c9c8c008370e7284d2f03bc4e614c96', 'battle_rule_v1:2069ef74d49c4461854d1fca3258cbcc', '{"battle_model_scope":"xmage_counter_target_spell_v1","countered_spell_to_exile":true,"countered_spell_to_exile_reason":"counter_target_exile_replacement","effect":"counter","instant":true,"sorcery":false,"target":"spell_mana_value_3_or_less","target_constraints":{"counter_target_mana_value_max":3,"stack_object":"spell","zone":"stack"},"xmage_effect_class":"CounterTargetWithReplacementEffect"}'::jsonb, '{"category":"protection","effect":"counter","target":"spell_mana_value_3_or_less","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Liquify translated into ManaLoom runtime scope xmage_counter_target_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('void shatter', 'Void Shatter', '591fc6fc6eae405e727724e6255ae015', 'battle_rule_v1:b93da3b7d54ae3de7cb4445ca5d21f27', '{"battle_model_scope":"xmage_counter_target_spell_v1","countered_spell_to_exile":true,"countered_spell_to_exile_reason":"counter_target_exile_replacement","effect":"counter","instant":true,"sorcery":false,"target":"spell","target_constraints":{"stack_object":"spell","zone":"stack"},"xmage_effect_class":"CounterTargetWithReplacementEffect"}'::jsonb, '{"category":"protection","effect":"counter","target":"spell","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class VoidShatter translated into ManaLoom runtime scope xmage_counter_target_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
