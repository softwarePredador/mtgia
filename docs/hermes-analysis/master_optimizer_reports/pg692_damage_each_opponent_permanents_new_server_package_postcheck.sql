WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('end the festivities', 'End the Festivities', 'f123365122f5b951c3e2711b234f326f', 'battle_rule_v1:409676e1f7059572e6cdf142e6089094', '{"_composite_rule_components":[{"ability_kind":"one_shot","amount":1,"battle_model_scope":"spell_damage_each_opponent_v1","compose_on_resolution":true,"damage":1,"effect":"damage_each_opponent","target_controller":"opponents","xmage_effect_class":"DamagePlayersEffect"},{"ability_kind":"one_shot","amount":1,"battle_model_scope":"xmage_fixed_damage_all_matching_permanents_spell_v1","compose_on_resolution":true,"damage":1,"damage_scope":"each_creature_and_planeswalker_opponents_control","effect":"damage_wipe","target_controller":"opponents","xmage_effect_class":"DamageAllEffect"}],"ability_kind":"one_shot","amount":1,"battle_model_scope":"xmage_damage_each_opponent_and_their_permanents_spell_v1","damage":1,"damage_scope":"each_creature_and_planeswalker_opponents_control","effect":"composite_resolution","instant":false,"resolution_order":"damage_opponents_then_their_permanents","sorcery":true,"target_controller":"opponents","xmage_effect_classes":["DamagePlayersEffect","DamageAllEffect"]}'::jsonb, '{"category":"draw","effect":"composite_resolution"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class EndTheFestivities translated into ManaLoom runtime scope xmage_damage_each_opponent_and_their_permanents_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('tectonic hazard', 'Tectonic Hazard', '1ed517ee6d21d82c06be6f7f8d90a46f', 'battle_rule_v1:2c92b9d4398bfccba9c71a4263a1542a', '{"_composite_rule_components":[{"ability_kind":"one_shot","amount":1,"battle_model_scope":"spell_damage_each_opponent_v1","compose_on_resolution":true,"damage":1,"effect":"damage_each_opponent","target_controller":"opponents","xmage_effect_class":"DamagePlayersEffect"},{"ability_kind":"one_shot","amount":1,"battle_model_scope":"xmage_fixed_damage_all_matching_permanents_spell_v1","compose_on_resolution":true,"damage":1,"damage_scope":"each_creature_opponents_control","effect":"damage_wipe","target_controller":"opponents","xmage_effect_class":"DamageAllEffect"}],"ability_kind":"one_shot","amount":1,"battle_model_scope":"xmage_damage_each_opponent_and_their_permanents_spell_v1","damage":1,"damage_scope":"each_creature_opponents_control","effect":"composite_resolution","instant":false,"resolution_order":"damage_opponents_then_their_permanents","sorcery":true,"target_controller":"opponents","xmage_effect_classes":["DamagePlayersEffect","DamageAllEffect"]}'::jsonb, '{"category":"draw","effect":"composite_resolution"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class TectonicHazard translated into ManaLoom runtime scope xmage_damage_each_opponent_and_their_permanents_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows')
),
rule_rows AS (
  SELECT
    r.normalized_name,
    r.logical_rule_key,
    r.oracle_hash,
    r.review_status,
    r.execution_status
  FROM proposed p
  LEFT JOIN public.card_battle_rules r
    ON (
         r.normalized_name = p.normalized_name
         OR r.normalized_name LIKE p.normalized_name || ' // %'
       )
   AND r.logical_rule_key = p.logical_rule_key
)
SELECT
  p.card_name,
  p.normalized_name,
  p.logical_rule_key,
  count(r.*) FILTER (WHERE r.logical_rule_key = p.logical_rule_key) AS promoted_rule_rows,
  count(r.*) FILTER (WHERE r.review_status = 'verified' AND r.execution_status = 'auto') AS promoted_verified_auto_rows,
  count(r.*) FILTER (WHERE r.oracle_hash = p.oracle_hash) AS promoted_oracle_hash_rows,
  (SELECT count(*) FROM manaloom_deploy_audit.pg692_damage_each_opponent_permanents_20260709_051144) AS backup_rows
FROM proposed p
LEFT JOIN rule_rows r
  ON r.normalized_name = p.normalized_name
 AND r.logical_rule_key = p.logical_rule_key
 AND r.oracle_hash = p.oracle_hash
GROUP BY p.card_name, p.normalized_name, p.logical_rule_key, p.oracle_hash
ORDER BY p.card_name;
