SELECT
  count(*) AS trusted_executable_rules_missing_oracle_hash
FROM public.card_battle_rules
WHERE source IN ('curated', 'manual')
  AND review_status IN ('verified', 'active')
  AND execution_status IN ('auto', 'executable')
  AND coalesce(oracle_hash, '') = '';

SELECT
  count(*) AS backup_rows,
  count(*) FILTER (WHERE r.oracle_hash = md5(coalesce(c.oracle_text, ''))) AS restored_hash_matches
FROM manaloom_deploy_audit.pg411_oracle_hash_integrity_backfill_new_server_20260704_152449 b
JOIN public.card_battle_rules r
  ON r.normalized_name = b.normalized_name
 AND r.logical_rule_key = b.logical_rule_key
JOIN public.cards c
  ON c.id = r.card_id;

SELECT
  r.card_name,
  r.normalized_name,
  r.logical_rule_key,
  r.oracle_hash,
  md5(coalesce(c.oracle_text, '')) AS computed_oracle_hash,
  (r.oracle_hash = md5(coalesce(c.oracle_text, ''))) AS oracle_hash_matches
FROM manaloom_deploy_audit.pg411_oracle_hash_integrity_backfill_new_server_20260704_152449 b
JOIN public.card_battle_rules r
  ON r.normalized_name = b.normalized_name
 AND r.logical_rule_key = b.logical_rule_key
JOIN public.cards c
  ON c.id = r.card_id
ORDER BY r.card_name, r.logical_rule_key
LIMIT 80;
