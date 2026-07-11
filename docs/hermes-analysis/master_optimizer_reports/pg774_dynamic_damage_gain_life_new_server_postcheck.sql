WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('consuming corruption', 'Consuming Corruption', 'af956e7b74ab1df3c33d564d77a62693', 'battle_rule_v1:e0345ec72a1a9085224c544ad9a6b2d6', '{"amount":0,"battle_model_scope":"xmage_dynamic_damage_target_and_controller_gain_life_spell_v1","battlefield_count_card_types":["land"],"battlefield_count_scope":"controller_battlefield","battlefield_count_subtypes":["swamp"],"controller_gain_life":0,"controller_gain_life_source":"damage_amount","damage":0,"damage_amount_source":"battlefield_permanent_count","damage_base_amount":0,"damage_per_count":1,"effect":"direct_damage","gain_life":0,"instant":true,"sorcery":false,"target":"creature_or_planeswalker","target_constraints":{"card_types":["creature","planeswalker"]},"xmage_effect_classes":["DamageTargetEffect","GainLifeEffect"]}'::jsonb, '{"category":"unknown","effect":"direct_damage","target":"creature_or_planeswalker","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ConsumingCorruption translated into ManaLoom runtime scope xmage_dynamic_damage_target_and_controller_gain_life_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('death grasp', 'Death Grasp', '4dace2593a568b5d9e64c1178332df27', 'battle_rule_v1:e03362aed2ffa35c48380cb2f1c191e4', '{"amount":0,"battle_model_scope":"xmage_dynamic_damage_target_and_controller_gain_life_spell_v1","controller_gain_life":0,"controller_gain_life_source":"damage_amount","damage":0,"damage_amount_source":"x_value","damage_base_amount":0,"damage_per_count":1,"effect":"direct_damage","gain_life":0,"instant":false,"sorcery":true,"target":"any_target","target_constraints":{"scope":"any_target"},"xmage_effect_classes":["DamageTargetEffect","GainLifeEffect"]}'::jsonb, '{"category":"unknown","effect":"direct_damage","target":"any_target"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class DeathGrasp translated into ManaLoom runtime scope xmage_dynamic_damage_target_and_controller_gain_life_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('harsh sustenance', 'Harsh Sustenance', '764ea219c19528e0443d02ec62abda1c', 'battle_rule_v1:8857cbd74c68f8aa10cd3bf0b32bd0a6', '{"amount":0,"battle_model_scope":"xmage_dynamic_damage_target_and_controller_gain_life_spell_v1","battlefield_count_card_types":["creature"],"battlefield_count_scope":"controller_battlefield","controller_gain_life":0,"controller_gain_life_source":"damage_amount","damage":0,"damage_amount_source":"battlefield_permanent_count","damage_base_amount":0,"damage_per_count":1,"effect":"direct_damage","gain_life":0,"instant":true,"sorcery":false,"target":"any_target","target_constraints":{"scope":"any_target"},"xmage_effect_classes":["DamageTargetEffect","GainLifeEffect"]}'::jsonb, '{"category":"unknown","effect":"direct_damage","target":"any_target","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class HarshSustenance translated into ManaLoom runtime scope xmage_dynamic_damage_target_and_controller_gain_life_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('swallowing plague', 'Swallowing Plague', '49256ef5c1c1b4cdb36ffd9dc68ed6ed', 'battle_rule_v1:d000dac089c864c9ea84b818f98c41fa', '{"amount":0,"battle_model_scope":"xmage_dynamic_damage_target_and_controller_gain_life_spell_v1","controller_gain_life":0,"controller_gain_life_source":"damage_amount","damage":0,"damage_amount_source":"x_value","damage_base_amount":0,"damage_per_count":1,"effect":"direct_damage","gain_life":0,"instant":false,"sorcery":true,"target":"creature","target_constraints":{"card_types":["creature"]},"xmage_effect_classes":["DamageTargetEffect","GainLifeEffect"]}'::jsonb, '{"category":"unknown","effect":"direct_damage","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class SwallowingPlague translated into ManaLoom runtime scope xmage_dynamic_damage_target_and_controller_gain_life_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('tendrils of corruption', 'Tendrils of Corruption', '7f1fcb8181dce09ca30cc4aca709c961', 'battle_rule_v1:3a1beb9f7e7b1408c0ae723d21e2f73a', '{"amount":0,"battle_model_scope":"xmage_dynamic_damage_target_and_controller_gain_life_spell_v1","battlefield_count_card_types":["land"],"battlefield_count_scope":"controller_battlefield","battlefield_count_subtypes":["swamp"],"controller_gain_life":0,"controller_gain_life_source":"damage_amount","damage":0,"damage_amount_source":"battlefield_permanent_count","damage_base_amount":0,"damage_per_count":1,"effect":"direct_damage","gain_life":0,"instant":true,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"]},"xmage_effect_classes":["DamageTargetEffect","GainLifeEffect"]}'::jsonb, '{"category":"unknown","effect":"direct_damage","target":"creature","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class TendrilsOfCorruption translated into ManaLoom runtime scope xmage_dynamic_damage_target_and_controller_gain_life_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
  (SELECT count(*) FROM manaloom_deploy_audit.pg774_dynamic_damage_gain_life_new_serve_20260711_164958) AS backup_rows
FROM proposed p
LEFT JOIN rule_rows r
  ON r.normalized_name = p.normalized_name
 AND r.logical_rule_key = p.logical_rule_key
 AND r.oracle_hash = p.oracle_hash
GROUP BY p.card_name, p.normalized_name, p.logical_rule_key, p.oracle_hash
ORDER BY p.card_name;
