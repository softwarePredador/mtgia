WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('firecannon blast', 'Firecannon Blast', '47cfd7a34116710a8f9cbeda2c06de8a', 'battle_rule_v1:2984588a243c46a2591bacf6c0ae20b0', '{"amount":3,"battle_model_scope":"xmage_conditional_fixed_damage_target_spell_v1","conditional_damage_amount":6,"conditional_damage_base_amount":3,"conditional_damage_condition":"controller_attacked_this_turn","damage":3,"effect":"direct_damage","instant":false,"sorcery":true,"target":"creature","target_constraints":{"card_types":["creature"]},"xmage_effect_classes":["ConditionalOneShotEffect","DamageTargetEffect"]}'::jsonb, '{"category":"unknown","effect":"direct_damage","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class FirecannonBlast translated into ManaLoom runtime scope xmage_conditional_fixed_damage_target_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('frost bite', 'Frost Bite', 'ce179d0eda2766b0ed58b46fabd849f1', 'battle_rule_v1:d573ebd9da37db9bfeed461264eddc46', '{"amount":2,"battle_model_scope":"xmage_conditional_fixed_damage_target_spell_v1","conditional_damage_amount":3,"conditional_damage_base_amount":2,"conditional_damage_condition":"controlled_snow_permanents_gte","conditional_damage_snow_permanent_threshold":3,"damage":2,"effect":"direct_damage","instant":true,"sorcery":false,"target":"creature_or_planeswalker","target_constraints":{"card_types":["creature","planeswalker"]},"xmage_effect_classes":["ConditionalOneShotEffect","DamageTargetEffect"]}'::jsonb, '{"category":"unknown","effect":"direct_damage","target":"creature_or_planeswalker","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class FrostBite translated into ManaLoom runtime scope xmage_conditional_fixed_damage_target_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('galvanize', 'Galvanize', '721ea83b1a8ef5e01f9f3af7a2845ebd', 'battle_rule_v1:ab1d802755e83221a1c21e756a294fe8', '{"amount":3,"battle_model_scope":"xmage_conditional_fixed_damage_target_spell_v1","conditional_damage_amount":5,"conditional_damage_base_amount":3,"conditional_damage_condition":"controller_drawn_cards_this_turn_gte","conditional_damage_drawn_cards_threshold":2,"damage":3,"effect":"direct_damage","instant":true,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"]},"xmage_effect_classes":["ConditionalOneShotEffect","DamageTargetEffect"]}'::jsonb, '{"category":"unknown","effect":"direct_damage","target":"creature","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Galvanize translated into ManaLoom runtime scope xmage_conditional_fixed_damage_target_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('invasive maneuvers', 'Invasive Maneuvers', '4f0eb20f8763ea60824ff41c076654d3', 'battle_rule_v1:32d9770589b3cff9f9e4c20d7f8c4829', '{"amount":3,"battle_model_scope":"xmage_conditional_fixed_damage_target_spell_v1","conditional_damage_amount":5,"conditional_damage_base_amount":3,"conditional_damage_condition":"controls_permanent_subtype","conditional_damage_required_subtype":"Spacecraft","damage":3,"effect":"direct_damage","instant":true,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"]},"xmage_effect_classes":["ConditionalOneShotEffect","DamageTargetEffect"]}'::jsonb, '{"category":"unknown","effect":"direct_damage","target":"creature","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class InvasiveManeuvers translated into ManaLoom runtime scope xmage_conditional_fixed_damage_target_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
  (SELECT count(*) FROM manaloom_deploy_audit.pg771_contextual_conditional_damage_new_20260711_155411) AS backup_rows
FROM proposed p
LEFT JOIN rule_rows r
  ON r.normalized_name = p.normalized_name
 AND r.logical_rule_key = p.logical_rule_key
 AND r.oracle_hash = p.oracle_hash
GROUP BY p.card_name, p.normalized_name, p.logical_rule_key, p.oracle_hash
ORDER BY p.card_name;
