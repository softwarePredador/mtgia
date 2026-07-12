WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('countermand', 'Countermand', '37339221401fd8154c74806cb83bd49a', 'battle_rule_v1:f402fd7b0ba896c377a82bcafb4211c0', '{"_composite_rule_components":[{"battle_model_scope":"xmage_counter_target_spell_v1","effect":"counter","target":"spell","target_constraints":{"stack_object":"spell","zone":"stack"},"xmage_effect_class":"CounterTargetEffect"},{"battle_model_scope":"xmage_fixed_target_player_mill_spell_v1","compose_on_resolution":true,"count":4,"effect":"mill_cards","mill_count":4,"target":"target_controller","target_player_mill":true,"xmage_effect_class":"CountermandEffect"}],"battle_model_scope":"xmage_counter_target_and_target_controller_mill_spell_v1","effect":"counter","instant":true,"mill_count":4,"resolution_order":"counter_then_target_controller_mill","sorcery":false,"target":"spell","target_constraints":{"stack_object":"spell","zone":"stack"},"target_controller_mill_on_counter":4,"target_player_mill":true,"xmage_effect_classes":["CountermandEffect","OneShotEffect"]}'::jsonb, '{"category":"protection","effect":"counter","target":"spell","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Countermand translated into ManaLoom runtime scope xmage_counter_target_and_target_controller_mill_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('didn''t say please', 'Didn''t Say Please', '1d9b8324a53964a8dc4a4b79ca4e0ac2', 'battle_rule_v1:3c0bee9a432ecc6ed6777b2f880a5145', '{"_composite_rule_components":[{"battle_model_scope":"xmage_counter_target_spell_v1","effect":"counter","target":"spell","target_constraints":{"stack_object":"spell","zone":"stack"},"xmage_effect_class":"CounterTargetEffect"},{"battle_model_scope":"xmage_fixed_target_player_mill_spell_v1","compose_on_resolution":true,"count":3,"effect":"mill_cards","mill_count":3,"target":"target_controller","target_player_mill":true,"xmage_effect_class":"DidntSayPleaseEffect"}],"battle_model_scope":"xmage_counter_target_and_target_controller_mill_spell_v1","effect":"counter","instant":true,"mill_count":3,"resolution_order":"counter_then_target_controller_mill","sorcery":false,"target":"spell","target_constraints":{"stack_object":"spell","zone":"stack"},"target_controller_mill_on_counter":3,"target_player_mill":true,"xmage_effect_classes":["CounterTargetEffect","DidntSayPleaseEffect","OneShotEffect"]}'::jsonb, '{"category":"protection","effect":"counter","target":"spell","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class DidntSayPlease translated into ManaLoom runtime scope xmage_counter_target_and_target_controller_mill_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('psychic strike', 'Psychic Strike', 'cdc9a084c42879b19393966222db8237', 'battle_rule_v1:57349935a74c3f3e23997e05f68a8b1a', '{"_composite_rule_components":[{"battle_model_scope":"xmage_counter_target_spell_v1","effect":"counter","target":"spell","target_constraints":{"stack_object":"spell","zone":"stack"},"xmage_effect_class":"CounterTargetEffect"},{"battle_model_scope":"xmage_fixed_target_player_mill_spell_v1","compose_on_resolution":true,"count":2,"effect":"mill_cards","mill_count":2,"target":"target_controller","target_player_mill":true,"xmage_effect_class":"PsychicStrikeEffect"}],"battle_model_scope":"xmage_counter_target_and_target_controller_mill_spell_v1","effect":"counter","instant":true,"mill_count":2,"resolution_order":"counter_then_target_controller_mill","sorcery":false,"target":"spell","target_constraints":{"stack_object":"spell","zone":"stack"},"target_controller_mill_on_counter":2,"target_player_mill":true,"xmage_effect_classes":["OneShotEffect","PsychicStrikeEffect"]}'::jsonb, '{"category":"protection","effect":"counter","target":"spell","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class PsychicStrike translated into ManaLoom runtime scope xmage_counter_target_and_target_controller_mill_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('thought collapse', 'Thought Collapse', '1d9b8324a53964a8dc4a4b79ca4e0ac2', 'battle_rule_v1:be6aee29492f6a8dda8894351e7e3474', '{"_composite_rule_components":[{"battle_model_scope":"xmage_counter_target_spell_v1","effect":"counter","target":"spell","target_constraints":{"stack_object":"spell","zone":"stack"},"xmage_effect_class":"CounterTargetEffect"},{"battle_model_scope":"xmage_fixed_target_player_mill_spell_v1","compose_on_resolution":true,"count":3,"effect":"mill_cards","mill_count":3,"target":"target_controller","target_player_mill":true,"xmage_effect_class":"ThoughtCollapseEffect"}],"battle_model_scope":"xmage_counter_target_and_target_controller_mill_spell_v1","effect":"counter","instant":true,"mill_count":3,"resolution_order":"counter_then_target_controller_mill","sorcery":false,"target":"spell","target_constraints":{"stack_object":"spell","zone":"stack"},"target_controller_mill_on_counter":3,"target_player_mill":true,"xmage_effect_classes":["CounterTargetEffect","OneShotEffect","ThoughtCollapseEffect"]}'::jsonb, '{"category":"protection","effect":"counter","target":"spell","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ThoughtCollapse translated into ManaLoom runtime scope xmage_counter_target_and_target_controller_mill_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
  (SELECT count(*) FROM manaloom_deploy_audit.pg849_counter_target_controller_mill_new_20260712_224816) AS backup_rows
FROM proposed p
LEFT JOIN rule_rows r
  ON r.normalized_name = p.normalized_name
 AND r.logical_rule_key = p.logical_rule_key
 AND r.oracle_hash = p.oracle_hash
GROUP BY p.card_name, p.normalized_name, p.logical_rule_key, p.oracle_hash
ORDER BY p.card_name;
