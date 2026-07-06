WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('countersquall', 'Countersquall', 'd11f89ab2042320e17aa9df329f10dc7', 'battle_rule_v1:f447ed982ad715fdcb2e953a58d5165c', '{"_composite_rule_components":[{"battle_model_scope":"xmage_counter_target_spell_v1","effect":"counter","target":"noncreature_spell","target_constraints":{"exclude_card_types":["creature"],"stack_object":"spell","zone":"stack"},"xmage_effect_class":"CounterTargetEffect"},{"battle_model_scope":"xmage_fixed_controller_gain_life_spell_v1","compose_on_resolution":true,"effect":"life_total_change","life_loss_amount":2,"target":"target_controller","xmage_effect_class":"LoseLifeTargetControllerEffect"}],"battle_model_scope":"xmage_counter_target_and_target_controller_loses_life_spell_v1","effect":"counter","instant":true,"life_loss_amount":2,"life_loss_on_counter":2,"resolution_order":"counter_then_target_controller_life_loss","sorcery":false,"target":"noncreature_spell","target_constraints":{"exclude_card_types":["creature"],"stack_object":"spell","zone":"stack"},"target_controller_life_loss_on_counter":2,"xmage_effect_classes":["CounterTargetEffect","LoseLifeTargetControllerEffect"]}'::jsonb, '{"category":"protection","effect":"counter","target":"noncreature_spell","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Countersquall translated into ManaLoom runtime scope xmage_counter_target_and_target_controller_loses_life_spell_v1. This row is package-ready only because the source signature is a narrow fixed counter-target spell with target-controller life loss with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('psychic barrier', 'Psychic Barrier', '24afa1ac0b2f719e88b1ab657b86243e', 'battle_rule_v1:06b4050177f0ce18ffc74b822d1c8e89', '{"_composite_rule_components":[{"battle_model_scope":"xmage_counter_target_spell_v1","effect":"counter","target":"creature_spell","target_constraints":{"card_types":["creature"],"stack_object":"spell","zone":"stack"},"xmage_effect_class":"CounterTargetEffect"},{"battle_model_scope":"xmage_fixed_controller_gain_life_spell_v1","compose_on_resolution":true,"effect":"life_total_change","life_loss_amount":1,"target":"target_controller","xmage_effect_class":"LoseLifeTargetControllerEffect"}],"battle_model_scope":"xmage_counter_target_and_target_controller_loses_life_spell_v1","effect":"counter","instant":true,"life_loss_amount":1,"life_loss_on_counter":1,"resolution_order":"counter_then_target_controller_life_loss","sorcery":false,"target":"creature_spell","target_constraints":{"card_types":["creature"],"stack_object":"spell","zone":"stack"},"target_controller_life_loss_on_counter":1,"xmage_effect_classes":["CounterTargetEffect","LoseLifeTargetControllerEffect"]}'::jsonb, '{"category":"protection","effect":"counter","target":"creature_spell","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class PsychicBarrier translated into ManaLoom runtime scope xmage_counter_target_and_target_controller_loses_life_spell_v1. This row is package-ready only because the source signature is a narrow fixed counter-target spell with target-controller life loss with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('undermine', 'Undermine', 'a2fafff02a4e52fdfb9778567baa5a7b', 'battle_rule_v1:712f2d24087fbcb90adbc83f61d36f86', '{"_composite_rule_components":[{"battle_model_scope":"xmage_counter_target_spell_v1","effect":"counter","target":"spell","target_constraints":{"stack_object":"spell","zone":"stack"},"xmage_effect_class":"CounterTargetEffect"},{"battle_model_scope":"xmage_fixed_controller_gain_life_spell_v1","compose_on_resolution":true,"effect":"life_total_change","life_loss_amount":3,"target":"target_controller","xmage_effect_class":"LoseLifeTargetControllerEffect"}],"battle_model_scope":"xmage_counter_target_and_target_controller_loses_life_spell_v1","effect":"counter","instant":true,"life_loss_amount":3,"life_loss_on_counter":3,"resolution_order":"counter_then_target_controller_life_loss","sorcery":false,"target":"spell","target_constraints":{"stack_object":"spell","zone":"stack"},"target_controller_life_loss_on_counter":3,"xmage_effect_classes":["CounterTargetEffect","LoseLifeTargetControllerEffect"]}'::jsonb, '{"category":"protection","effect":"counter","target":"spell","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Undermine translated into ManaLoom runtime scope xmage_counter_target_and_target_controller_loses_life_spell_v1. This row is package-ready only because the source signature is a narrow fixed counter-target spell with target-controller life loss with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
  (SELECT count(*) FROM manaloom_deploy_audit.pg567_counter_life_loss_new_server_20260706_124236) AS backup_rows
FROM proposed p
LEFT JOIN rule_rows r
  ON r.normalized_name = p.normalized_name
 AND r.logical_rule_key = p.logical_rule_key
 AND r.oracle_hash = p.oracle_hash
GROUP BY p.card_name, p.normalized_name, p.logical_rule_key, p.oracle_hash
ORDER BY p.card_name;
