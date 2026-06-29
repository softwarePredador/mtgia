SELECT
  count(*) AS target_rows,
  count(*) FILTER (
    WHERE normalized_name = 'erode'
      AND logical_rule_key = 'battle_rule_v1:dd175af9c77feea940de97138a916fe3'
      AND effect_json ->> 'basic_land_compensation_status' = 'runtime_executor_v1'
      AND effect_json ->> 'battle_model_scope' = 'destroy_creature_or_planeswalker_target_controller_basic_land_tapped_runtime_v1'
      AND effect_json ->> 'oracle_runtime_scope' = 'target_controller_basic_land_search_to_battlefield_tapped_runtime_v1'
      AND rule_version >= 3
      AND reviewed_by = 'codex-pgc061'
  ) AS erode_runtime_rows,
  count(*) FILTER (
    WHERE normalized_name = 'sundering eruption // volcanic fissure'
      AND logical_rule_key = 'battle_rule_v1:98d0006543fc622cfc1d82991bd5a66a'
      AND effect_json ->> 'basic_land_compensation_status' = 'runtime_executor_v1'
      AND effect_json ->> 'battle_model_scope' = 'destroy_target_land_target_controller_basic_land_tapped_runtime_nonfliers_cant_block_annotation_v1'
      AND effect_json ->> 'oracle_runtime_scope' = 'target_controller_basic_land_search_to_battlefield_tapped_runtime_v1'
      AND effect_json ->> 'cant_block_mode_status' = 'annotation_only'
      AND rule_version >= 3
      AND reviewed_by = 'codex-pgc061'
  ) AS sundering_basic_land_runtime_rows,
  (
    SELECT count(*)
    FROM manaloom_deploy_audit.pgc061_basic_land_compensation_runtime_20260629
  ) AS backup_rows
FROM public.card_battle_rules
WHERE (normalized_name = 'erode'
   AND logical_rule_key = 'battle_rule_v1:dd175af9c77feea940de97138a916fe3')
   OR (normalized_name = 'sundering eruption // volcanic fissure'
   AND logical_rule_key = 'battle_rule_v1:98d0006543fc622cfc1d82991bd5a66a');
