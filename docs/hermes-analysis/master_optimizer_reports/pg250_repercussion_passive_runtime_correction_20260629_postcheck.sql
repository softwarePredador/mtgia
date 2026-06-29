WITH current_rules AS (
  SELECT
    normalized_name,
    logical_rule_key,
    review_status,
    execution_status,
    oracle_hash,
    effect_json->>'effect' AS effect,
    effect_json->>'battle_model_scope' AS battle_model_scope,
    effect_json->>'trigger' AS trigger,
    effect_json->>'trigger_effect' AS trigger_effect,
    effect_json->>'global_creature_damage_reflect_to_controller' AS global_creature_damage_reflect_to_controller
  FROM public.card_battle_rules
  WHERE normalized_name = 'repercussion'
     OR normalized_name LIKE 'repercussion // %'
)
SELECT
  count(*) FILTER (
    WHERE logical_rule_key = 'battle_rule_v1:d1a0c5cc0035945ec8bfd795da52d017'
      AND review_status = 'verified'
      AND execution_status = 'auto'
      AND oracle_hash = '8e1ed4f8063ab89dd8906878a6232862'
      AND effect = 'passive'
      AND battle_model_scope = 'creature_damage_controller_reflect_global_v1'
      AND trigger = 'creature_dealt_damage'
      AND trigger_effect = 'damage_creature_controller'
      AND global_creature_damage_reflect_to_controller = 'true'
  ) AS promoted_passive_rows,
  count(*) FILTER (
    WHERE logical_rule_key <> 'battle_rule_v1:d1a0c5cc0035945ec8bfd795da52d017'
      AND review_status IN ('verified', 'active')
      AND execution_status IN ('auto', 'executable')
  ) AS active_nonmatching_rows,
  jsonb_agg(to_jsonb(current_rules) ORDER BY logical_rule_key) AS current_rules
FROM current_rules;
