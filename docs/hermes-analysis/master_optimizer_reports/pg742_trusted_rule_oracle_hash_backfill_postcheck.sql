SELECT
  count(*) AS trusted_executable_rules_missing_oracle_hash
FROM public.card_battle_rules r
WHERE r.review_status IN ('verified', 'active')
  AND r.execution_status = 'auto'
  AND coalesce(r.oracle_hash, '') = '';

SELECT
  count(*) AS backup_rows
FROM manaloom_deploy_audit.pg742_trusted_rule_oracle_hash_backfill_20260711;
