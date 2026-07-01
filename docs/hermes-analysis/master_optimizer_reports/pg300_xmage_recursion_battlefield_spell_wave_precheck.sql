WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('argivian restoration', 'Argivian Restoration', '8e7d6e6d898113c74f02dd1711125e2a', 'battle_rule_v1:d28dc68f4c31a93694dcb4be850ea0a4', '{"battle_model_scope":"xmage_return_target_graveyard_card_to_battlefield_spell_v1","count":1,"destination":"battlefield","effect":"recursion","instant":false,"sorcery":true,"target":"artifact","target_constraints":{"card_types":["artifact"],"controller":"self","zone":"graveyard"},"target_controller":"self","xmage_effect_class":"ReturnFromGraveyardToBattlefieldTargetEffect"}'::jsonb, '{"category":"engine","effect":"recursion","target":"artifact"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ArgivianRestoration translated into ManaLoom runtime scope xmage_return_target_graveyard_card_to_battlefield_spell_v1. This row is package-ready only because the source signature is a narrow instant/sorcery spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('breath of life', 'Breath of Life', '68b4cdebdb2d674f9aa24d95a2b74c9f', 'battle_rule_v1:b0046c8fa58ed98eb9754ac4148782be', '{"battle_model_scope":"xmage_return_target_graveyard_card_to_battlefield_spell_v1","count":1,"destination":"battlefield","effect":"recursion","instant":false,"sorcery":true,"target":"creature","target_constraints":{"card_types":["creature"],"controller":"self","zone":"graveyard"},"target_controller":"self","xmage_effect_class":"ReturnFromGraveyardToBattlefieldTargetEffect"}'::jsonb, '{"category":"engine","effect":"recursion","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class BreathOfLife translated into ManaLoom runtime scope xmage_return_target_graveyard_card_to_battlefield_spell_v1. This row is package-ready only because the source signature is a narrow instant/sorcery spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('false defeat', 'False Defeat', '68b4cdebdb2d674f9aa24d95a2b74c9f', 'battle_rule_v1:b0046c8fa58ed98eb9754ac4148782be', '{"battle_model_scope":"xmage_return_target_graveyard_card_to_battlefield_spell_v1","count":1,"destination":"battlefield","effect":"recursion","instant":false,"sorcery":true,"target":"creature","target_constraints":{"card_types":["creature"],"controller":"self","zone":"graveyard"},"target_controller":"self","xmage_effect_class":"ReturnFromGraveyardToBattlefieldTargetEffect"}'::jsonb, '{"category":"engine","effect":"recursion","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class FalseDefeat translated into ManaLoom runtime scope xmage_return_target_graveyard_card_to_battlefield_spell_v1. This row is package-ready only because the source signature is a narrow instant/sorcery spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('obzedat''s aid', 'Obzedat''s Aid', 'd640c0b86638a9ae30425fb27c9a4bbb', 'battle_rule_v1:0fbc3ef723d43c6064a5bc2c78287927', '{"battle_model_scope":"xmage_return_target_graveyard_card_to_battlefield_spell_v1","count":1,"destination":"battlefield","effect":"recursion","instant":false,"sorcery":true,"target":"permanent","target_constraints":{"card_types":["artifact","creature","enchantment","planeswalker","battle","land"],"controller":"self","zone":"graveyard"},"target_controller":"self","xmage_effect_class":"ReturnFromGraveyardToBattlefieldTargetEffect"}'::jsonb, '{"category":"engine","effect":"recursion","target":"permanent"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ObzedatsAid translated into ManaLoom runtime scope xmage_return_target_graveyard_card_to_battlefield_spell_v1. This row is package-ready only because the source signature is a narrow instant/sorcery spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('refurbish', 'Refurbish', '8e7d6e6d898113c74f02dd1711125e2a', 'battle_rule_v1:d28dc68f4c31a93694dcb4be850ea0a4', '{"battle_model_scope":"xmage_return_target_graveyard_card_to_battlefield_spell_v1","count":1,"destination":"battlefield","effect":"recursion","instant":false,"sorcery":true,"target":"artifact","target_constraints":{"card_types":["artifact"],"controller":"self","zone":"graveyard"},"target_controller":"self","xmage_effect_class":"ReturnFromGraveyardToBattlefieldTargetEffect"}'::jsonb, '{"category":"engine","effect":"recursion","target":"artifact"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Refurbish translated into ManaLoom runtime scope xmage_return_target_graveyard_card_to_battlefield_spell_v1. This row is package-ready only because the source signature is a narrow instant/sorcery spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('resurrection', 'Resurrection', '68b4cdebdb2d674f9aa24d95a2b74c9f', 'battle_rule_v1:b0046c8fa58ed98eb9754ac4148782be', '{"battle_model_scope":"xmage_return_target_graveyard_card_to_battlefield_spell_v1","count":1,"destination":"battlefield","effect":"recursion","instant":false,"sorcery":true,"target":"creature","target_constraints":{"card_types":["creature"],"controller":"self","zone":"graveyard"},"target_controller":"self","xmage_effect_class":"ReturnFromGraveyardToBattlefieldTargetEffect"}'::jsonb, '{"category":"engine","effect":"recursion","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Resurrection translated into ManaLoom runtime scope xmage_return_target_graveyard_card_to_battlefield_spell_v1. This row is package-ready only because the source signature is a narrow instant/sorcery spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('rise again', 'Rise Again', '68b4cdebdb2d674f9aa24d95a2b74c9f', 'battle_rule_v1:b0046c8fa58ed98eb9754ac4148782be', '{"battle_model_scope":"xmage_return_target_graveyard_card_to_battlefield_spell_v1","count":1,"destination":"battlefield","effect":"recursion","instant":false,"sorcery":true,"target":"creature","target_constraints":{"card_types":["creature"],"controller":"self","zone":"graveyard"},"target_controller":"self","xmage_effect_class":"ReturnFromGraveyardToBattlefieldTargetEffect"}'::jsonb, '{"category":"engine","effect":"recursion","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class RiseAgain translated into ManaLoom runtime scope xmage_return_target_graveyard_card_to_battlefield_spell_v1. This row is package-ready only because the source signature is a narrow instant/sorcery spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('zombify', 'Zombify', '68b4cdebdb2d674f9aa24d95a2b74c9f', 'battle_rule_v1:b0046c8fa58ed98eb9754ac4148782be', '{"battle_model_scope":"xmage_return_target_graveyard_card_to_battlefield_spell_v1","count":1,"destination":"battlefield","effect":"recursion","instant":false,"sorcery":true,"target":"creature","target_constraints":{"card_types":["creature"],"controller":"self","zone":"graveyard"},"target_controller":"self","xmage_effect_class":"ReturnFromGraveyardToBattlefieldTargetEffect"}'::jsonb, '{"category":"engine","effect":"recursion","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Zombify translated into ManaLoom runtime scope xmage_return_target_graveyard_card_to_battlefield_spell_v1. This row is package-ready only because the source signature is a narrow instant/sorcery spell with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
