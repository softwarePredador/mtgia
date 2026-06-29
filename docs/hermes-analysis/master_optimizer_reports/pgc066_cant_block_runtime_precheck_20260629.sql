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
    FROM pg_class c
    JOIN pg_namespace n ON n.oid = c.relnamespace
    WHERE n.nspname = 'manaloom_deploy_audit'
      AND c.relname = 'pgc066_cant_block_runtime_20260629'
  ) AS backup_table_exists,
  count(*) AS target_rows,
  count(*) FILTER (
    WHERE review_status = 'verified'
      AND execution_status = 'auto'
  ) AS trusted_target_rows,
  count(*) FILTER (
    WHERE effect_json->>'cant_block_mode_status' = 'annotation_only'
  ) AS current_cant_block_annotation_rows,
  count(*) FILTER (
    WHERE effect_json->>'cant_block_mode_status' = 'runtime_executor_v1'
  ) AS current_cant_block_runtime_rows,
  count(*) FILTER (
    WHERE effect_json::text LIKE '%annotation_only%'
  ) AS current_annotation_rows
FROM target_rules;
