\echo 'PG641 trusted rule oracle_hash backfill precheck'

SELECT
  COUNT(*) AS trusted_executable_rules_missing_oracle_hash
FROM public.card_battle_rules r
WHERE r.source IN ('manual', 'curated')
  AND r.review_status IN ('verified', 'active')
  AND r.execution_status IN ('auto', 'executable')
  AND COALESCE(r.oracle_hash, '') = '';

SELECT
  COUNT(*) AS updateable_missing_oracle_hash_rows
FROM public.card_battle_rules r
JOIN public.cards c ON c.id = r.card_id
WHERE r.source IN ('manual', 'curated')
  AND r.review_status IN ('verified', 'active')
  AND r.execution_status IN ('auto', 'executable')
  AND COALESCE(r.oracle_hash, '') = ''
  AND COALESCE(c.oracle_text, '') <> '';

SELECT
  COUNT(*) AS missing_hash_rows_without_oracle_text
FROM public.card_battle_rules r
LEFT JOIN public.cards c ON c.id = r.card_id
WHERE r.source IN ('manual', 'curated')
  AND r.review_status IN ('verified', 'active')
  AND r.execution_status IN ('auto', 'executable')
  AND COALESCE(r.oracle_hash, '') = ''
  AND COALESCE(c.oracle_text, '') = '';

SELECT
  r.card_name,
  r.normalized_name,
  r.logical_rule_key,
  md5(COALESCE(c.oracle_text, '')) AS expected_oracle_hash
FROM public.card_battle_rules r
JOIN public.cards c ON c.id = r.card_id
WHERE r.source IN ('manual', 'curated')
  AND r.review_status IN ('verified', 'active')
  AND r.execution_status IN ('auto', 'executable')
  AND COALESCE(r.oracle_hash, '') = ''
  AND COALESCE(c.oracle_text, '') <> ''
ORDER BY r.card_name, r.logical_rule_key
LIMIT 60;
