WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('accomplished alchemist', 'Accomplished Alchemist', 'c9e44029a1331371a86431a87d427627', 'battle_rule_v1:0037c915258cdef18a28daeff7ccf288', '{"ability_kind":"activated_mana","activation_requires_tap":true,"battle_model_scope":"xmage_dynamic_any_one_color_mana_source_permanent_v1","conditional_mana_modes":[{"color":"W","mode":"dynamic_any_one_color","restriction":"any_spell","status":"runtime_executor_v1"},{"color":"U","mode":"dynamic_any_one_color","restriction":"any_spell","status":"runtime_executor_v1"},{"color":"B","mode":"dynamic_any_one_color","restriction":"any_spell","status":"runtime_executor_v1"},{"color":"R","mode":"dynamic_any_one_color","restriction":"any_spell","status":"runtime_executor_v1"},{"color":"G","mode":"dynamic_any_one_color","restriction":"any_spell","status":"runtime_executor_v1"}],"conditional_mana_modes_status":"runtime_executor_v1","conditional_mana_same_color_choice":true,"dynamic_mana_amount_source":"controller_life_gained_this_turn","dynamic_mana_minimum_produced":1,"dynamic_mana_minimum_source":"independent_any_color_mana_ability","effect":"ramp_permanent","is_mana_source":true,"mana_activation_requires_tap":true,"mana_produced":1,"permanent_type":"creature","produced_mana_symbols":["W","U","B","R","G"],"produces":"WUBRG","source_mana_cost":"{3}{G}","source_type_line":"Creature \u2014 Elf Druid","xmage_ability_classes":["AnyColorManaAbility","DynamicManaAbility"],"xmage_effect_classes":[],"xmage_mana_ability_classes":["AnyColorManaAbility","DynamicManaAbility"]}'::jsonb, '{"category":"ramp","effect":"ramp_permanent"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class AccomplishedAlchemist translated into ManaLoom runtime scope xmage_dynamic_any_one_color_mana_source_permanent_v1. This row is package-ready only because the source signature is a narrow activated mana-source permanent with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
  (SELECT count(*) FROM manaloom_deploy_audit.pg848_life_gained_dynamic_mana_new_serve_20260712_222154) AS backup_rows
FROM proposed p
LEFT JOIN rule_rows r
  ON r.normalized_name = p.normalized_name
 AND r.logical_rule_key = p.logical_rule_key
 AND r.oracle_hash = p.oracle_hash
GROUP BY p.card_name, p.normalized_name, p.logical_rule_key, p.oracle_hash
ORDER BY p.card_name;
