SELECT
  count(*) AS remaining_pg_missing_oracle_hash_rows
FROM public.card_battle_rules
WHERE source = 'curated'
  AND execution_status = 'auto'
  AND review_status IN ('active', 'verified')
  AND coalesce(oracle_hash, '') = '';

SELECT
  count(*) AS backup_rows
FROM manaloom_deploy_audit.pg601_static_filtered_hash_backfill_20260707;

SELECT
  r.card_name,
  r.normalized_name,
  r.logical_rule_key,
  r.oracle_hash,
  md5(coalesce(c.oracle_text, '')) AS expected_oracle_hash
FROM public.card_battle_rules r
JOIN manaloom_deploy_audit.pg601_static_filtered_hash_backfill_20260707 b
  ON b.normalized_name = r.normalized_name
 AND b.logical_rule_key = r.logical_rule_key
JOIN public.cards c
  ON c.id = r.card_id
WHERE r.oracle_hash <> md5(coalesce(c.oracle_text, ''))
ORDER BY r.card_name, r.logical_rule_key;
