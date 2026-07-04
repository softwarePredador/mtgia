SELECT
  count(*) AS trusted_executable_rules_missing_oracle_hash
FROM public.card_battle_rules
WHERE source IN ('curated', 'manual')
  AND review_status IN ('verified', 'active')
  AND execution_status IN ('auto', 'executable')
  AND coalesce(oracle_hash, '') = '';

SELECT
  card_name,
  normalized_name,
  logical_rule_key,
  oracle_hash,
  md5(coalesce(c.oracle_text, '')) AS computed_oracle_hash,
  (r.oracle_hash = md5(coalesce(c.oracle_text, ''))) AS oracle_hash_matches
FROM public.card_battle_rules r
JOIN public.cards c
  ON c.id = r.card_id
WHERE (r.normalized_name, r.logical_rule_key) IN (
  SELECT normalized_name, logical_rule_key
  FROM manaloom_deploy_audit.pg399c_backfill_all_trusted_oracle_hashes_new_server
)
ORDER BY card_name, logical_rule_key;
