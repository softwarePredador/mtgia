SELECT count(*) AS trusted_executable_rules_missing_oracle_hash
FROM public.card_battle_rules
WHERE source IN ('manual', 'curated')
  AND review_status IN ('verified', 'active')
  AND execution_status IN ('auto', 'executable')
  AND COALESCE(oracle_hash, '') = '';

SELECT count(*) AS backup_rows
FROM manaloom_deploy_audit.pg582_trusted_rule_oracle_hash_backfill_backup;
