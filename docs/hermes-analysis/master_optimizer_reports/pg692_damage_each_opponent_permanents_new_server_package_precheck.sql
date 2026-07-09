WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('end the festivities', 'End the Festivities', 'f123365122f5b951c3e2711b234f326f', 'battle_rule_v1:409676e1f7059572e6cdf142e6089094', '{"_composite_rule_components":[{"ability_kind":"one_shot","amount":1,"battle_model_scope":"spell_damage_each_opponent_v1","compose_on_resolution":true,"damage":1,"effect":"damage_each_opponent","target_controller":"opponents","xmage_effect_class":"DamagePlayersEffect"},{"ability_kind":"one_shot","amount":1,"battle_model_scope":"xmage_fixed_damage_all_matching_permanents_spell_v1","compose_on_resolution":true,"damage":1,"damage_scope":"each_creature_and_planeswalker_opponents_control","effect":"damage_wipe","target_controller":"opponents","xmage_effect_class":"DamageAllEffect"}],"ability_kind":"one_shot","amount":1,"battle_model_scope":"xmage_damage_each_opponent_and_their_permanents_spell_v1","damage":1,"damage_scope":"each_creature_and_planeswalker_opponents_control","effect":"composite_resolution","instant":false,"resolution_order":"damage_opponents_then_their_permanents","sorcery":true,"target_controller":"opponents","xmage_effect_classes":["DamagePlayersEffect","DamageAllEffect"]}'::jsonb, '{"category":"draw","effect":"composite_resolution"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class EndTheFestivities translated into ManaLoom runtime scope xmage_damage_each_opponent_and_their_permanents_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('tectonic hazard', 'Tectonic Hazard', '1ed517ee6d21d82c06be6f7f8d90a46f', 'battle_rule_v1:2c92b9d4398bfccba9c71a4263a1542a', '{"_composite_rule_components":[{"ability_kind":"one_shot","amount":1,"battle_model_scope":"spell_damage_each_opponent_v1","compose_on_resolution":true,"damage":1,"effect":"damage_each_opponent","target_controller":"opponents","xmage_effect_class":"DamagePlayersEffect"},{"ability_kind":"one_shot","amount":1,"battle_model_scope":"xmage_fixed_damage_all_matching_permanents_spell_v1","compose_on_resolution":true,"damage":1,"damage_scope":"each_creature_opponents_control","effect":"damage_wipe","target_controller":"opponents","xmage_effect_class":"DamageAllEffect"}],"ability_kind":"one_shot","amount":1,"battle_model_scope":"xmage_damage_each_opponent_and_their_permanents_spell_v1","damage":1,"damage_scope":"each_creature_opponents_control","effect":"composite_resolution","instant":false,"resolution_order":"damage_opponents_then_their_permanents","sorcery":true,"target_controller":"opponents","xmage_effect_classes":["DamagePlayersEffect","DamageAllEffect"]}'::jsonb, '{"category":"draw","effect":"composite_resolution"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class TectonicHazard translated into ManaLoom runtime scope xmage_damage_each_opponent_and_their_permanents_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
