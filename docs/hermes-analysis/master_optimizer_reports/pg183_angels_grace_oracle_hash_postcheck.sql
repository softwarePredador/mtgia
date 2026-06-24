SELECT
  count(*) FILTER (
    WHERE r.oracle_hash = md5(coalesce(c.oracle_text, ''))
  ) AS matching_oracle_hash_rows,
  count(*) FILTER (
    WHERE r.review_status = 'verified' AND r.execution_status = 'auto'
  ) AS verified_auto_rows,
  (SELECT count(*) FROM manaloom_deploy_audit.pg183_angels_grace_oracle_hash_20260624) AS backup_rows
FROM public.card_battle_rules r
JOIN public.cards c
  ON lower(c.name) = r.normalized_name
WHERE r.normalized_name = 'angel''s grace'
  AND r.logical_rule_key = 'battle_rule_v1:2833836fd4d943d3e02d1cfa2d284227';
