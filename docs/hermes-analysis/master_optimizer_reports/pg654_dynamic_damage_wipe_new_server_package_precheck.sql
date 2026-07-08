WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('calamitous cave-in', 'Calamitous Cave-In', '4069479e2214edce819d6a9edc3da97f', 'battle_rule_v1:ff384c2972d27eae1173bbbb12bcd2e0', '{"amount":0,"battle_model_scope":"xmage_fixed_damage_all_matching_permanents_spell_v1","damage":0,"damage_amount_source":"caves_controlled_plus_cave_cards_in_graveyard","damage_base_amount":0,"damage_per_count":1,"damage_scope":"each_creature_and_planeswalker","effect":"damage_wipe","instant":false,"sorcery":true,"xmage_effect_class":"DamageAllEffect"}'::jsonb, '{"category":"wipe","effect":"damage_wipe"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class CalamitousCaveIn translated into ManaLoom runtime scope xmage_fixed_damage_all_matching_permanents_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('chain reaction', 'Chain Reaction', '7133da1b111adf3a50a495277840c796', 'battle_rule_v1:b721248b835b2a566a36928f7de5f211', '{"amount":0,"battle_model_scope":"xmage_fixed_damage_all_matching_permanents_spell_v1","battlefield_count_card_types":["creature"],"battlefield_count_scope":"all_battlefields","damage":0,"damage_amount_source":"battlefield_permanent_count","damage_base_amount":0,"damage_per_count":1,"damage_scope":"each_creature","effect":"damage_wipe","instant":false,"sorcery":true,"xmage_effect_class":"DamageAllEffect"}'::jsonb, '{"category":"wipe","effect":"damage_wipe"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ChainReaction translated into ManaLoom runtime scope xmage_fixed_damage_all_matching_permanents_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('gates ablaze', 'Gates Ablaze', '93d9ca2d64d6702472f1beba1505cc00', 'battle_rule_v1:bce9b09587369ceddee79a4d87b2639d', '{"amount":0,"battle_model_scope":"xmage_fixed_damage_all_matching_permanents_spell_v1","battlefield_count_scope":"controller_battlefield","battlefield_count_subtypes":["gate"],"damage":0,"damage_amount_source":"battlefield_permanent_count","damage_base_amount":0,"damage_per_count":1,"damage_scope":"each_creature","effect":"damage_wipe","instant":false,"sorcery":true,"xmage_effect_class":"DamageAllEffect"}'::jsonb, '{"category":"wipe","effect":"damage_wipe"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class GatesAblaze translated into ManaLoom runtime scope xmage_fixed_damage_all_matching_permanents_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('immolating gyre', 'Immolating Gyre', '92e197d6b4ce1c5741779d0b5f327e0e', 'battle_rule_v1:3a36e4c65fe5fbd1658a5dc91815619d', '{"amount":0,"battle_model_scope":"xmage_fixed_damage_all_matching_permanents_spell_v1","damage":0,"damage_amount_source":"graveyard_card_count","damage_base_amount":0,"damage_per_count":1,"damage_scope":"each_creature_and_planeswalker_opponents_control","effect":"damage_wipe","graveyard_count_card_types":["instant","sorcery"],"graveyard_count_scope":"controller_graveyard","instant":false,"sorcery":true,"xmage_effect_class":"DamageAllEffect"}'::jsonb, '{"category":"wipe","effect":"damage_wipe"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ImmolatingGyre translated into ManaLoom runtime scope xmage_fixed_damage_all_matching_permanents_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('skyreaping', 'Skyreaping', '0c832362e9df1c38970d782accc8a1c3', 'battle_rule_v1:e00622e2a40dda1f82a2eb04c0b22f91', '{"amount":0,"battle_model_scope":"xmage_fixed_damage_all_matching_permanents_spell_v1","damage":0,"damage_amount_source":"devotion_to_green","damage_base_amount":0,"damage_per_count":1,"damage_scope":"each_flying_creature","effect":"damage_wipe","instant":false,"sorcery":true,"xmage_effect_class":"DamageAllEffect"}'::jsonb, '{"category":"wipe","effect":"damage_wipe"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Skyreaping translated into ManaLoom runtime scope xmage_fixed_damage_all_matching_permanents_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
