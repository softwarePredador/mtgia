WITH target_rules AS (
  SELECT *
  FROM public.card_battle_rules
  WHERE (
      normalized_name = 'return the favor'
      AND logical_rule_key = 'battle_rule_v1:fb3ee27205e34477fa9753b38433e9a2'
      AND oracle_hash = 'a24911b7ea2027ebba59bb6792eee776'
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
      AND c.relname = 'pgc065_modal_target_change_runtime_20260629'
  ) AS backup_table_exists,
  count(*) AS target_rows,
  count(*) FILTER (
    WHERE review_status = 'verified'
      AND execution_status = 'auto'
  ) AS trusted_target_rows,
  count(*) FILTER (
    WHERE normalized_name = 'return the favor'
      AND effect_json->>'change_target_mode_status' = 'annotation_only'
  ) AS return_change_target_annotation_rows,
  count(*) FILTER (
    WHERE normalized_name = 'untimely malfunction'
      AND effect_json->>'redirect_target_mode_status' = 'annotation_only'
  ) AS untimely_redirect_annotation_rows,
  count(*) FILTER (
    WHERE effect_json::text LIKE '%annotation_only%'
  ) AS current_annotation_rows
FROM target_rules;
