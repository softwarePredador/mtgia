WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('bind', 'Bind', '411b586d3d4f0d5a307e81bcc05388be', 'battle_rule_v1:880274ce7e5acbdff6b6bac0b95165e0', '{"_composite_rule_components":[{"battle_model_scope":"xmage_counter_target_spell_v1","effect":"counter","target":"activated_ability","target_constraints":{"stack_object":"activated_ability","zone":"stack"},"xmage_effect_class":"CounterTargetEffect"},{"battle_model_scope":"xmage_fixed_source_controller_draw_spell_v1","compose_on_resolution":true,"count":1,"effect":"draw_cards","xmage_effect_class":"DrawCardSourceControllerEffect"}],"battle_model_scope":"xmage_counter_target_and_draw_card_spell_v1","count":1,"draw_count":1,"draw_on_counter":1,"effect":"counter","instant":true,"sorcery":false,"target":"activated_ability","target_constraints":{"stack_object":"activated_ability","zone":"stack"},"xmage_effect_classes":["CounterTargetEffect","DrawCardSourceControllerEffect"]}'::jsonb, '{"category":"protection","effect":"counter","target":"activated_ability","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Bind translated into ManaLoom runtime scope xmage_counter_target_and_draw_card_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('bind // liberate', 'Bind // Liberate', '411b586d3d4f0d5a307e81bcc05388be', 'battle_rule_v1:880274ce7e5acbdff6b6bac0b95165e0', '{"_composite_rule_components":[{"battle_model_scope":"xmage_counter_target_spell_v1","effect":"counter","target":"activated_ability","target_constraints":{"stack_object":"activated_ability","zone":"stack"},"xmage_effect_class":"CounterTargetEffect"},{"battle_model_scope":"xmage_fixed_source_controller_draw_spell_v1","compose_on_resolution":true,"count":1,"effect":"draw_cards","xmage_effect_class":"DrawCardSourceControllerEffect"}],"battle_model_scope":"xmage_counter_target_and_draw_card_spell_v1","count":1,"draw_count":1,"draw_on_counter":1,"effect":"counter","instant":true,"sorcery":false,"target":"activated_ability","target_constraints":{"stack_object":"activated_ability","zone":"stack"},"xmage_effect_classes":["CounterTargetEffect","DrawCardSourceControllerEffect"]}'::jsonb, '{"category":"protection","effect":"counter","target":"activated_ability","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Bind translated into ManaLoom runtime scope xmage_counter_target_and_draw_card_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('squelch', 'Squelch', '411b586d3d4f0d5a307e81bcc05388be', 'battle_rule_v1:880274ce7e5acbdff6b6bac0b95165e0', '{"_composite_rule_components":[{"battle_model_scope":"xmage_counter_target_spell_v1","effect":"counter","target":"activated_ability","target_constraints":{"stack_object":"activated_ability","zone":"stack"},"xmage_effect_class":"CounterTargetEffect"},{"battle_model_scope":"xmage_fixed_source_controller_draw_spell_v1","compose_on_resolution":true,"count":1,"effect":"draw_cards","xmage_effect_class":"DrawCardSourceControllerEffect"}],"battle_model_scope":"xmage_counter_target_and_draw_card_spell_v1","count":1,"draw_count":1,"draw_on_counter":1,"effect":"counter","instant":true,"sorcery":false,"target":"activated_ability","target_constraints":{"stack_object":"activated_ability","zone":"stack"},"xmage_effect_classes":["CounterTargetEffect","DrawCardSourceControllerEffect"]}'::jsonb, '{"category":"protection","effect":"counter","target":"activated_ability","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Squelch translated into ManaLoom runtime scope xmage_counter_target_and_draw_card_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
  (SELECT count(*) FROM manaloom_deploy_audit.pg864_counter_activated_draw_new_server_20260713_051122) AS backup_rows
FROM proposed p
LEFT JOIN rule_rows r
  ON r.normalized_name = p.normalized_name
 AND r.logical_rule_key = p.logical_rule_key
 AND r.oracle_hash = p.oracle_hash
GROUP BY p.card_name, p.normalized_name, p.logical_rule_key, p.oracle_hash
ORDER BY p.card_name;
