WITH target AS (
  SELECT
    r.normalized_name,
    r.logical_rule_key,
    r.oracle_hash AS current_oracle_hash,
    md5(coalesce(c.oracle_text, '')) AS computed_oracle_hash,
    r.effect_json,
    r.review_status,
    r.execution_status
  FROM public.card_battle_rules r
  JOIN public.cards c
    ON c.id = r.card_id
  WHERE r.normalized_name = 'angel''s grace'
    AND r.logical_rule_key = 'battle_rule_v1:2833836fd4d943d3e02d1cfa2d284227'
)
SELECT
  count(*) AS target_rows,
  count(*) FILTER (
    WHERE computed_oracle_hash = '627c4ce7adf5be44b93e2b850159e5d9'
  ) AS expected_hash_rows,
  count(*) FILTER (
    WHERE current_oracle_hash IS DISTINCT FROM computed_oracle_hash
  ) AS hash_drift_rows,
  count(*) FILTER (
    WHERE coalesce(effect_json ->> 'battle_model_scope', '') = ''
       OR coalesce(effect_json ->> 'oracle_runtime_scope', '') = ''
       OR coalesce(effect_json ->> 'split_second', '') = ''
       OR coalesce(effect_json ->> 'opponents_cant_win_this_turn', '') = ''
  ) AS runtime_metadata_drift_rows,
  count(*) FILTER (
    WHERE review_status = 'verified'
      AND execution_status = 'auto'
  ) AS verified_auto_rows,
  CASE
    WHEN to_regclass('manaloom_deploy_audit.pgc055_angels_grace_oracle_hash_repair_20260629') IS NULL
      THEN 0
    ELSE 1
  END AS backup_table_exists
FROM target;
