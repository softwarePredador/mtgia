WITH target AS (
  SELECT
    r.normalized_name,
    r.logical_rule_key,
    r.card_name,
    r.review_status,
    r.execution_status,
    r.source,
    r.confidence,
    r.rule_version,
    r.oracle_hash,
    r.effect_json,
    md5(COALESCE(c.oracle_text, '')) AS card_oracle_hash
  FROM card_battle_rules r
  JOIN cards c ON c.id = r.card_id
  WHERE r.normalized_name = 'valakut awakening'
    AND r.logical_rule_key = 'battle_rule_v1:245b8d2627720fadfd7a30464d07605a'
),
split_rule AS (
  SELECT count(*) AS rows
  FROM card_battle_rules
  WHERE normalized_name = 'valakut awakening // valakut stoneforge'
    AND logical_rule_key = 'battle_rule_v1:6e1f3b876822abafe1de47610f46858d'
    AND oracle_hash = '22b42fcc181b7aed71f78b2e1e51e887'
    AND effect_json->>'battle_model_scope' = 'bottom_then_draw_plus_one_mdfc_land_v1'
    AND review_status IN ('verified', 'active')
    AND execution_status = 'auto'
)
SELECT
  count(*) AS target_rule_rows,
  count(*) FILTER (WHERE card_oracle_hash = '22b42fcc181b7aed71f78b2e1e51e887') AS card_oracle_hash_match_rows,
  count(*) FILTER (WHERE oracle_hash IS NULL OR oracle_hash = '') AS rows_needing_hash_restore,
  count(*) FILTER (WHERE review_status <> 'active') AS rows_needing_status_restore,
  count(*) FILTER (WHERE execution_status <> 'auto') AS rows_needing_execution_restore,
  count(*) FILTER (WHERE effect_json->>'battle_model_scope' = 'bottom_then_draw_plus_one_v1') AS expected_scope_rows,
  (SELECT rows FROM split_rule) AS split_mdfc_rule_rows,
  to_regclass('manaloom_deploy_audit.pg097_valakut_simple_hash_restore_20260623_113918') IS NOT NULL AS backup_table_already_exists
FROM target;
