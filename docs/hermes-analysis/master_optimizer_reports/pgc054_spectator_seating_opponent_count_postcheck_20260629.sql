-- PGC054 Spectator Seating opponent-count ETB runtime postcheck.

WITH target_rules AS (
  SELECT *
  FROM card_battle_rules
  WHERE normalized_name = 'spectator seating'
)
SELECT 'target_rule_rows' AS metric, count(*)::text AS value
FROM target_rules
UNION ALL
SELECT 'curated_pgc054_rows', count(*)::text
FROM target_rules
WHERE source = 'curated'
  AND reviewed_by = 'codex-pgc054'
UNION ALL
SELECT 'curated_rule_version_gte2_rows', count(*)::text
FROM target_rules
WHERE source = 'curated'
  AND rule_version >= 2
UNION ALL
SELECT 'opponent_count_runtime_rows', count(*)::text
FROM target_rules
WHERE source = 'curated'
  AND effect_json->>'opponent_count_status' = 'runtime_executor_v1'
UNION ALL
SELECT 'opponent_threshold_rows', count(*)::text
FROM target_rules
WHERE source = 'curated'
  AND (effect_json->>'enters_tapped_unless_opponent_count')::int = 2
UNION ALL
SELECT 'battle_scope_rows', count(*)::text
FROM target_rules
WHERE source = 'curated'
  AND effect_json->>'battle_model_scope' = 'bond_land_dual_source_etb_opponent_count_runtime_v1'
UNION ALL
SELECT 'oracle_scope_rows', count(*)::text
FROM target_rules
WHERE source = 'curated'
  AND effect_json->>'oracle_runtime_scope' = 'red_white_mana_enters_tapped_unless_two_or_more_opponents_runtime_v1'
UNION ALL
SELECT 'generated_non_disabled_rows', count(*)::text
FROM target_rules
WHERE source = 'generated'
  AND execution_status <> 'disabled'
UNION ALL
SELECT 'backup_rows', count(*)::text
FROM manaloom_deploy_audit.pgc054_spectator_seating_opponent_count_20260629;

SELECT
  card_name,
  normalized_name,
  source,
  review_status,
  execution_status,
  rule_version,
  logical_rule_key,
  oracle_hash,
  reviewed_by,
  reviewed_at,
  effect_json::text AS effect_json,
  left(coalesce(notes, ''), 420) AS notes
FROM card_battle_rules
WHERE normalized_name = 'spectator seating'
ORDER BY source, review_status, logical_rule_key;
