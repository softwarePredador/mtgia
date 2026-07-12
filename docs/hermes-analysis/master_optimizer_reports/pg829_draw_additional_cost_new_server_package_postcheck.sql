WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('necrologia', 'Necrologia', 'ff1ec55dd2171e6f761f7501aabee03f', 'battle_rule_v1:e3bf57c754ce063817330ee3cebe8ba5', '{"additional_cost":"pay_life","battle_model_scope":"xmage_fixed_source_controller_draw_spell_v1","count":0,"draw_count":0,"draw_count_source":"x_value","effect":"draw_cards","instant":true,"pay_life_amount":0,"pay_life_amount_source":"x_value","requires_pay_life":true,"sorcery":false,"xmage_additional_cost_class":"PayVariableLifeCost","xmage_effect_class":"DrawCardSourceControllerEffect"}'::jsonb, '{"category":"draw","effect":"draw_cards","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Necrologia translated into ManaLoom runtime scope xmage_fixed_source_controller_draw_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('shared discovery', 'Shared Discovery', 'e5a07adfb35c4dd27e1a8d4db23adc53', 'battle_rule_v1:293b839a6e5308eb46342ecfe620afae', '{"additional_cost":"tap_untapped_creatures","battle_model_scope":"xmage_fixed_source_controller_draw_spell_v1","count":3,"effect":"draw_cards","instant":false,"requires_tap_untapped_creature_count":4,"sorcery":true,"xmage_additional_cost_class":"TapTargetCost","xmage_additional_cost_target":"controlled_untapped_creatures","xmage_effect_class":"DrawCardSourceControllerEffect"}'::jsonb, '{"category":"draw","effect":"draw_cards"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class SharedDiscovery translated into ManaLoom runtime scope xmage_fixed_source_controller_draw_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
  (SELECT count(*) FROM manaloom_deploy_audit.pg829_draw_additional_cost_new_server_20260712_114509) AS backup_rows
FROM proposed p
LEFT JOIN rule_rows r
  ON r.normalized_name = p.normalized_name
 AND r.logical_rule_key = p.logical_rule_key
 AND r.oracle_hash = p.oracle_hash
GROUP BY p.card_name, p.normalized_name, p.logical_rule_key, p.oracle_hash
ORDER BY p.card_name;
