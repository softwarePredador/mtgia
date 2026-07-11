SELECT
  count(*) AS trusted_executable_rules_missing_oracle_hash
FROM public.card_battle_rules r
WHERE r.review_status IN ('verified', 'active')
  AND r.execution_status = 'auto'
  AND coalesce(r.oracle_hash, '') = '';

SELECT
  count(*) AS backup_rows
FROM manaloom_deploy_audit.pg757b_trusted_rule_oracle_hash_backfill_20260711;

SELECT
  count(*) AS backfilled_rows_matching_current_oracle_hash
FROM public.card_battle_rules r
JOIN public.cards c ON c.id = r.card_id
JOIN manaloom_deploy_audit.pg757b_trusted_rule_oracle_hash_backfill_20260711 b
  ON b.card_id = r.card_id
 AND b.logical_rule_key = r.logical_rule_key
WHERE r.review_status IN ('verified', 'active')
  AND r.execution_status = 'auto'
  AND r.oracle_hash = md5(coalesce(c.oracle_text, ''));
