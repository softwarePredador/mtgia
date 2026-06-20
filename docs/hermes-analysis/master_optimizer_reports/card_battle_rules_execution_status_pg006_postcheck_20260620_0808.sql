\echo 'PG-006 postcheck - card_battle_rules execution_status migration drift'

BEGIN TRANSACTION READ ONLY;

SELECT
  'migration_029_status' AS section,
  version,
  name,
  executed_at
FROM schema_migrations
WHERE version = '029';

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
  'remaining_needs_review_not_review_only' AS section,
  COUNT(*) AS rows
FROM card_battle_rules
WHERE review_status = 'needs_review'
  AND execution_status <> 'review_only';

SELECT
  'rollback_backup_rows' AS section,
  COUNT(*) AS rows
FROM manaloom_deploy_audit.pg006_card_battle_rules_execution_status_20260620_0808;

SELECT
  'card_intelligence_snapshot_view' AS section,
  pg_get_viewdef('public.card_intelligence_snapshot'::regclass, true) ILIKE '%execution_status%' AS mentions_execution_status;

SELECT
  'optimize_candidate_quality_summary_view' AS section,
  pg_get_viewdef('public.optimize_candidate_quality_summary'::regclass, true) ILIKE '%execution_status%' AS mentions_execution_status;

ROLLBACK;
