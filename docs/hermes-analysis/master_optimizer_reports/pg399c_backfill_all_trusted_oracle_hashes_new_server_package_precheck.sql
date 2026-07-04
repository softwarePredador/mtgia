SELECT
  card_name,
  normalized_name,
  logical_rule_key,
  source,
  review_status,
  execution_status,
  rule_version,
  card_id,
  md5(coalesce(c.oracle_text, '')) AS computed_oracle_hash,
  length(coalesce(c.oracle_text, '')) AS oracle_text_length
FROM public.card_battle_rules r
JOIN public.cards c
  ON c.id = r.card_id
WHERE r.source IN ('curated', 'manual')
  AND r.review_status IN ('verified', 'active')
  AND r.execution_status IN ('auto', 'executable')
  AND coalesce(r.oracle_hash, '') = ''
  AND coalesce(c.oracle_text, '') <> ''
ORDER BY card_name, logical_rule_key;

SELECT
  count(*) AS trusted_executable_rules_missing_oracle_hash_with_oracle_text
FROM public.card_battle_rules r
JOIN public.cards c
  ON c.id = r.card_id
WHERE r.source IN ('curated', 'manual')
  AND r.review_status IN ('verified', 'active')
  AND r.execution_status IN ('auto', 'executable')
  AND coalesce(r.oracle_hash, '') = ''
  AND coalesce(c.oracle_text, '') <> '';
