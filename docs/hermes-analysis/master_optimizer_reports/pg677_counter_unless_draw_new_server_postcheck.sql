WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('disrupt', 'Disrupt', '7eb63b220b62a5e201d34d9e8378ea26', 'battle_rule_v1:b3467f5b0804e31ce6bab1d1d3bc7dd0', '{"_composite_rule_components":[{"battle_model_scope":"xmage_counter_target_spell_unless_controller_pays_generic_v1","counter_unless_pays_generic":1,"effect":"counter","target":"instant_or_sorcery_spell","target_constraints":{"spell_types":["instant","sorcery"],"stack_object":"spell","zone":"stack"},"xmage_effect_class":"CounterUnlessPaysEffect"},{"battle_model_scope":"xmage_fixed_source_controller_draw_spell_v1","compose_on_resolution":true,"count":1,"effect":"draw_cards","xmage_effect_class":"DrawCardSourceControllerEffect"}],"battle_model_scope":"xmage_counter_target_spell_unless_controller_pays_generic_draw_card_v1","count":1,"counter_unless_pays_generic":1,"draw_count":1,"draw_on_counter":1,"effect":"counter","instant":true,"sorcery":false,"target":"instant_or_sorcery_spell","target_constraints":{"spell_types":["instant","sorcery"],"stack_object":"spell","zone":"stack"},"xmage_effect_classes":["CounterUnlessPaysEffect","DrawCardSourceControllerEffect"]}'::jsonb, '{"category":"protection","effect":"counter","target":"instant_or_sorcery_spell","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Disrupt translated into ManaLoom runtime scope xmage_counter_target_spell_unless_controller_pays_generic_draw_card_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('runeboggle', 'Runeboggle', 'eb94011d3ca7b5421aed33f13d1eaff7', 'battle_rule_v1:6bc73f3dcf446ce7026fbbe903537b75', '{"_composite_rule_components":[{"battle_model_scope":"xmage_counter_target_spell_unless_controller_pays_generic_v1","counter_unless_pays_generic":1,"effect":"counter","target":"spell","target_constraints":{"stack_object":"spell","zone":"stack"},"xmage_effect_class":"CounterUnlessPaysEffect"},{"battle_model_scope":"xmage_fixed_source_controller_draw_spell_v1","compose_on_resolution":true,"count":1,"effect":"draw_cards","xmage_effect_class":"DrawCardSourceControllerEffect"}],"battle_model_scope":"xmage_counter_target_spell_unless_controller_pays_generic_draw_card_v1","count":1,"counter_unless_pays_generic":1,"draw_count":1,"draw_on_counter":1,"effect":"counter","instant":true,"sorcery":false,"target":"spell","target_constraints":{"stack_object":"spell","zone":"stack"},"xmage_effect_classes":["CounterUnlessPaysEffect","DrawCardSourceControllerEffect"]}'::jsonb, '{"category":"protection","effect":"counter","target":"spell","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Runeboggle translated into ManaLoom runtime scope xmage_counter_target_spell_unless_controller_pays_generic_draw_card_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
  (SELECT count(*) FROM manaloom_deploy_audit.pg677_counter_unless_draw_new_server_20260708_232921) AS backup_rows
FROM proposed p
LEFT JOIN rule_rows r
  ON r.normalized_name = p.normalized_name
 AND r.logical_rule_key = p.logical_rule_key
 AND r.oracle_hash = p.oracle_hash
GROUP BY p.card_name, p.normalized_name, p.logical_rule_key, p.oracle_hash
ORDER BY p.card_name;
