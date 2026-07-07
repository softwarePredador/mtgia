-- PG634 postcheck.
-- Expected after apply:
--   backup_rows = rows backed up before mutation
--   backed_up_rows_with_hash_now = backup_rows
--   trusted_executable_missing_oracle_hash = 0

WITH backup AS (
  SELECT normalized_name, logical_rule_key
  FROM manaloom_deploy_audit.pg634_trusted_rule_oracle_hash_backfill_20260707
),
current_backup_rows AS (
  SELECT cbr.*
  FROM public.card_battle_rules cbr
  JOIN backup b USING (normalized_name, logical_rule_key)
)
SELECT 'backup_rows' AS check_name, COUNT(*)::text AS value FROM backup
UNION ALL
SELECT 'backed_up_rows_with_hash_now', COUNT(*)::text
FROM current_backup_rows
WHERE COALESCE(oracle_hash, '') <> ''
UNION ALL
SELECT 'trusted_executable_missing_oracle_hash', COUNT(*)::text
FROM public.card_battle_rules cbr
JOIN public.cards c ON c.id = cbr.card_id
WHERE cbr.source IN ('curated', 'manual')
  AND cbr.review_status IN ('verified', 'active')
  AND cbr.execution_status IN ('auto', 'executable')
  AND COALESCE(cbr.oracle_hash, '') = ''
  AND COALESCE(c.oracle_text, '') <> '';
