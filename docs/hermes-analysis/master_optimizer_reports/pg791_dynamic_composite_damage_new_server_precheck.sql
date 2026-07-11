WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('focus fire', 'Focus Fire', 'dadac04a003dabbc0c02353de974b38e', 'battle_rule_v1:0a77c01b41e8b01edc7700293d29c782', '{"amount":0,"battle_model_scope":"xmage_dynamic_count_damage_spell_v1","battlefield_count_components":[{"battlefield_count_card_types":["creature"],"battlefield_count_scope":"controller_battlefield"},{"battlefield_count_scope":"controller_battlefield","battlefield_count_subtypes":["spacecraft"]}],"battlefield_count_composite_mode":"union","damage":0,"damage_amount_source":"composite_battlefield_permanent_count","damage_base_amount":2,"damage_per_count":1,"effect":"direct_damage","instant":true,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"],"combat_state":"attacking_or_blocking"},"xmage_effect_class":"DamageTargetEffect"}'::jsonb, '{"category":"unknown","effect":"direct_damage","target":"creature","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class FocusFire translated into ManaLoom runtime scope xmage_dynamic_count_damage_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('hobbit''s sting', 'Hobbit''s Sting', 'c96fc623db953d300e37f66bcdd6e2a8', 'battle_rule_v1:4cc57a6a390ad2b30a79ce8a740c05ae', '{"amount":0,"battle_model_scope":"xmage_dynamic_count_damage_spell_v1","battlefield_count_components":[{"battlefield_count_card_types":["creature"],"battlefield_count_scope":"controller_battlefield"},{"battlefield_count_scope":"controller_battlefield","battlefield_count_subtypes":["food"]}],"battlefield_count_composite_mode":"sum","damage":0,"damage_amount_source":"composite_battlefield_permanent_count","damage_base_amount":0,"damage_per_count":1,"effect":"direct_damage","instant":true,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"]},"xmage_effect_class":"DamageTargetEffect"}'::jsonb, '{"category":"unknown","effect":"direct_damage","target":"creature","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class HobbitsSting translated into ManaLoom runtime scope xmage_dynamic_count_damage_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('road rage', 'Road Rage', 'ade79182ddf63f024acbdd66cb9dbf78', 'battle_rule_v1:7aafa4698684da859113cb2b62e71232', '{"amount":0,"battle_model_scope":"xmage_dynamic_count_damage_spell_v1","battlefield_count_components":[{"battlefield_count_scope":"controller_battlefield","battlefield_count_subtypes":["mount"]},{"battlefield_count_scope":"controller_battlefield","battlefield_count_subtypes":["vehicle"]}],"battlefield_count_composite_mode":"union","damage":0,"damage_amount_source":"composite_battlefield_permanent_count","damage_base_amount":2,"damage_per_count":1,"effect":"direct_damage","instant":true,"sorcery":false,"target":"creature_or_planeswalker","target_constraints":{"card_types":["creature","planeswalker"]},"xmage_effect_class":"DamageTargetEffect"}'::jsonb, '{"category":"unknown","effect":"direct_damage","target":"creature_or_planeswalker","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class RoadRage translated into ManaLoom runtime scope xmage_dynamic_count_damage_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('slash of light', 'Slash of Light', 'cf5f56d8ffa98e6d77f5cc73369073c3', 'battle_rule_v1:d458a10a448c0e3796f48d5e721a36b0', '{"amount":0,"battle_model_scope":"xmage_dynamic_count_damage_spell_v1","battlefield_count_components":[{"battlefield_count_card_types":["creature"],"battlefield_count_scope":"controller_battlefield"},{"battlefield_count_card_types":["artifact"],"battlefield_count_scope":"controller_battlefield","battlefield_count_subtypes":["equipment"]}],"battlefield_count_composite_mode":"sum","damage":0,"damage_amount_source":"composite_battlefield_permanent_count","damage_base_amount":0,"damage_per_count":1,"effect":"direct_damage","instant":true,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"]},"xmage_effect_class":"DamageTargetEffect"}'::jsonb, '{"category":"unknown","effect":"direct_damage","target":"creature","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class SlashOfLight translated into ManaLoom runtime scope xmage_dynamic_count_damage_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
