SELECT
  count(*) AS trusted_executable_rules_missing_oracle_hash
FROM public.card_battle_rules r
WHERE r.source = 'curated'
  AND r.review_status IN ('verified', 'active')
  AND r.execution_status = 'auto'
  AND coalesce(r.oracle_hash, '') = '';

SELECT
  count(*) AS backup_rows
FROM manaloom_deploy_audit.pg424b_backfill_trusted_oracle_hashes_new_server_20260704_1923;
