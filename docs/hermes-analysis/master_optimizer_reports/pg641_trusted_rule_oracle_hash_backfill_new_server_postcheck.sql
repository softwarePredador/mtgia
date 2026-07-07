\echo 'PG641 trusted rule oracle_hash backfill postcheck'

SELECT
  COUNT(*) AS trusted_executable_rules_missing_oracle_hash
FROM public.card_battle_rules r
WHERE r.source IN ('manual', 'curated')
  AND r.review_status IN ('verified', 'active')
  AND r.execution_status IN ('auto', 'executable')
  AND COALESCE(r.oracle_hash, '') = '';

SELECT
  COUNT(*) AS backed_up_rows
FROM manaloom_deploy_audit.pg641_trusted_rule_oracle_hash_backfill_new_server_20260707;

SELECT
  COUNT(*) AS rows_with_expected_hash
FROM public.card_battle_rules r
JOIN public.cards c ON c.id = r.card_id
JOIN manaloom_deploy_audit.pg641_trusted_rule_oracle_hash_backfill_new_server_20260707 b
  ON b.normalized_name = r.normalized_name
 AND b.logical_rule_key = r.logical_rule_key
WHERE r.oracle_hash = md5(COALESCE(c.oracle_text, ''));

SELECT
  r.card_name,
  r.logical_rule_key,
  r.oracle_hash
FROM public.card_battle_rules r
JOIN manaloom_deploy_audit.pg641_trusted_rule_oracle_hash_backfill_new_server_20260707 b
  ON b.normalized_name = r.normalized_name
 AND b.logical_rule_key = r.logical_rule_key
WHERE COALESCE(r.oracle_hash, '') = ''
ORDER BY r.card_name
LIMIT 20;
