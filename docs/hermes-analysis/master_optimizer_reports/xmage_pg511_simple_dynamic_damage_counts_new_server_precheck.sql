WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('runeflare trap', 'Runeflare Trap', '9ed6a2b25bb33ab63a5e733b7354d270', 'battle_rule_v1:f86cf719c13e031f50a9270dc8564003', '{"amount":0,"battle_model_scope":"xmage_dynamic_count_damage_spell_v1","damage":0,"damage_amount_source":"target_hand_count","damage_base_amount":0,"damage_per_count":1,"effect":"direct_damage","instant":true,"sorcery":false,"target":"player","target_constraints":{"scope":"player"},"xmage_effect_class":"DamageTargetEffect"}'::jsonb, '{"category":"unknown","effect":"direct_damage","target":"player","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class RuneflareTrap translated into ManaLoom runtime scope xmage_dynamic_count_damage_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('storm seeker', 'Storm Seeker', '432038c0d3717ce675fac8ddfb615e9e', 'battle_rule_v1:f86cf719c13e031f50a9270dc8564003', '{"amount":0,"battle_model_scope":"xmage_dynamic_count_damage_spell_v1","damage":0,"damage_amount_source":"target_hand_count","damage_base_amount":0,"damage_per_count":1,"effect":"direct_damage","instant":true,"sorcery":false,"target":"player","target_constraints":{"scope":"player"},"xmage_effect_class":"DamageTargetEffect"}'::jsonb, '{"category":"unknown","effect":"direct_damage","target":"player","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class StormSeeker translated into ManaLoom runtime scope xmage_dynamic_count_damage_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('sudden impact', 'Sudden Impact', '8bc700f1247132390e805ef5c1d72e98', 'battle_rule_v1:f86cf719c13e031f50a9270dc8564003', '{"amount":0,"battle_model_scope":"xmage_dynamic_count_damage_spell_v1","damage":0,"damage_amount_source":"target_hand_count","damage_base_amount":0,"damage_per_count":1,"effect":"direct_damage","instant":true,"sorcery":false,"target":"player","target_constraints":{"scope":"player"},"xmage_effect_class":"DamageTargetEffect"}'::jsonb, '{"category":"unknown","effect":"direct_damage","target":"player","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class SuddenImpact translated into ManaLoom runtime scope xmage_dynamic_count_damage_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('thunder salvo', 'Thunder Salvo', '0f8d6f811660e869eac237246dd8cdd5', 'battle_rule_v1:102529d74981d821d4e9827b80d25c5a', '{"amount":0,"battle_model_scope":"xmage_dynamic_count_damage_spell_v1","damage":0,"damage_amount_source":"other_spells_cast_this_turn","damage_base_amount":2,"damage_per_count":1,"effect":"direct_damage","instant":true,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"]},"xmage_effect_class":"DamageTargetEffect"}'::jsonb, '{"category":"unknown","effect":"direct_damage","target":"creature","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ThunderSalvo translated into ManaLoom runtime scope xmage_dynamic_count_damage_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
