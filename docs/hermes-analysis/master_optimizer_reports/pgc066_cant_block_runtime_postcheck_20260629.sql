WITH target_rules AS (
  SELECT *
  FROM public.card_battle_rules
  WHERE (
      normalized_name = 'sundering eruption // volcanic fissure'
      AND logical_rule_key = 'battle_rule_v1:98d0006543fc622cfc1d82991bd5a66a'
      AND oracle_hash = '09148a5a6f4d14c04a30bf19819e20b8'
    )
    OR (
      normalized_name = 'untimely malfunction'
      AND logical_rule_key = 'battle_rule_v1:667ba8e5e69696402f9cd213886e57a8'
      AND oracle_hash = '877f2d75c90c7886ca9536135829bb90'
    )
)
SELECT
  (
    SELECT count(*)
    FROM manaloom_deploy_audit.pgc066_cant_block_runtime_20260629
  ) AS backup_rows,
  count(*) AS target_rows,
  count(*) FILTER (
    WHERE normalized_name = 'sundering eruption // volcanic fissure'
      AND effect_json->>'cant_block_mode_status' = 'runtime_executor_v1'
      AND effect_json->>'cant_block_target_restriction' = 'creatures_without_flying'
      AND effect_json->>'battle_model_scope' = 'destroy_target_land_target_controller_basic_land_tapped_runtime_nonfliers_cant_block_runtime_v1'
  ) AS sundering_cant_block_runtime_rows,
  count(*) FILTER (
    WHERE normalized_name = 'untimely malfunction'
      AND effect_json->>'cant_block_mode_status' = 'runtime_executor_v1'
      AND effect_json->>'redirect_target_mode_status' = 'runtime_executor_v1'
      AND effect_json->>'battle_model_scope' = 'modal_destroy_artifact_redirect_target_cant_block_runtime_v1'
  ) AS untimely_cant_block_runtime_rows,
  count(*) FILTER (
    WHERE effect_json::text LIKE '%annotation_only%'
  ) AS remaining_annotation_rows
FROM target_rules;
