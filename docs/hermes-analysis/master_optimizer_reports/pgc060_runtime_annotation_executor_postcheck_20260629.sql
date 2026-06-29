SELECT
  count(*) AS target_rows,
  count(*) FILTER (
    WHERE normalized_name = 'furygale flocking'
      AND effect_json ->> 'attack_each_opponent_this_turn_status' = 'runtime_executor_v1'
      AND effect_json ->> 'battle_model_scope' = 'per_opponent_two_3_3_flying_hasty_elementals_graveyard_cost_reduction_runtime_attack_requirement_v1'
      AND effect_json ->> 'oracle_runtime_scope' = 'graveyard_instant_sorcery_cost_reduction_runtime_per_opponent_tokens_attack_requirement_v1'
      AND rule_version >= 4
      AND reviewed_by = 'codex-pgc060'
  ) AS furygale_runtime_rows,
  count(*) FILTER (
    WHERE normalized_name = 'tempt with bunnies'
      AND effect_json ->> 'tempting_offer_opponent_choice_status' = 'runtime_executor_v1'
      AND effect_json ->> 'battle_model_scope' IN (
        'tempting_offer_base_create_1_1_white_rabbit_component_runtime_v1',
        'tempting_offer_base_draw_one_component_runtime_v1'
      )
      AND rule_version >= 3
      AND reviewed_by = 'codex-pgc060'
  ) AS tempt_runtime_rows,
  (
    SELECT count(*)
    FROM manaloom_deploy_audit.pgc060_runtime_annotation_executor_20260629
  ) AS backup_rows
FROM public.card_battle_rules
WHERE (normalized_name = 'furygale flocking'
   AND logical_rule_key = 'battle_rule_v1:63b66f50aad09aa5669ac693b2fca7e5')
   OR (normalized_name = 'tempt with bunnies'
   AND logical_rule_key IN (
     'battle_rule_v1:64814289c1def19e7cd5bb7462c4cf86',
     'battle_rule_v1:ac96c7799172699f5d7b6b0dc5e4aa80'
   ));
