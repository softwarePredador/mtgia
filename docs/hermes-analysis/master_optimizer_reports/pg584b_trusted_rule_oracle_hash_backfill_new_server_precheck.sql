SELECT
  r.normalized_name,
  r.card_name,
  r.logical_rule_key,
  r.source,
  r.review_status,
  r.execution_status,
  r.rule_version,
  md5(coalesce(c.oracle_text, '')) AS computed_oracle_hash
FROM public.card_battle_rules r
JOIN public.cards c ON c.id = r.card_id
WHERE r.source IN ('manual', 'curated')
  AND r.review_status IN ('verified', 'active')
  AND r.execution_status IN ('auto', 'executable')
  AND COALESCE(r.oracle_hash, '') = ''
  AND COALESCE(c.oracle_text, '') <> ''
ORDER BY r.normalized_name, r.logical_rule_key;
