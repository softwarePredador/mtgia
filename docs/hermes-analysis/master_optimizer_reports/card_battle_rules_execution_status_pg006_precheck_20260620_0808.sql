\echo 'PG-006 precheck - card_battle_rules execution_status migration drift'

BEGIN TRANSACTION READ ONLY;

SELECT
  'migration_029_status' AS section,
  EXISTS (
    SELECT 1
    FROM schema_migrations
    WHERE version = '029'
  ) AS migration_029_recorded;

SELECT
  'execution_status_column' AS section,
  column_name,
  is_nullable,
  column_default
FROM information_schema.columns
WHERE table_schema = 'public'
  AND table_name = 'card_battle_rules'
  AND column_name = 'execution_status';

SELECT
  'execution_status_constraint' AS section,
  conname,
  pg_get_constraintdef(oid) AS definition
FROM pg_constraint
WHERE conrelid = 'public.card_battle_rules'::regclass
  AND conname = 'chk_card_battle_rules_execution_status';

SELECT
  'execution_status_counts' AS section,
  execution_status,
  COUNT(*) AS rows
FROM card_battle_rules
GROUP BY execution_status
ORDER BY execution_status;

SELECT
  'source_review_execution_counts' AS section,
  source,
  review_status,
  execution_status,
  COUNT(*) AS rows
FROM card_battle_rules
GROUP BY source, review_status, execution_status
ORDER BY source, review_status, execution_status;

SELECT
  'pg006_rows_to_normalize' AS section,
  COUNT(*) AS rows
FROM card_battle_rules
WHERE execution_status IS NULL
   OR execution_status = ''
   OR (
        review_status = 'needs_review'
        AND execution_status IS DISTINCT FROM 'review_only'
      )
   OR (
        review_status IN ('rejected', 'deprecated')
        AND execution_status IS DISTINCT FROM 'disabled'
      );

SELECT
  'card_intelligence_snapshot_view' AS section,
  pg_get_viewdef('public.card_intelligence_snapshot'::regclass, true) ILIKE '%execution_status%' AS mentions_execution_status;

SELECT
  'optimize_candidate_quality_summary_view' AS section,
  pg_get_viewdef('public.optimize_candidate_quality_summary'::regclass, true) ILIKE '%execution_status%' AS mentions_execution_status;

SELECT
  'needs_review_auto_samples' AS section,
  card_name,
  source,
  review_status,
  execution_status,
  logical_rule_key
FROM card_battle_rules
WHERE review_status = 'needs_review'
  AND execution_status = 'auto'
ORDER BY card_name, logical_rule_key
LIMIT 12;

ROLLBACK;
