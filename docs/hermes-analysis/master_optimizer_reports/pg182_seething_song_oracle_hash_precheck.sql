SELECT
  r.normalized_name,
  r.logical_rule_key,
  r.oracle_hash AS current_rule_oracle_hash,
  md5(coalesce(c.oracle_text, '')) AS expected_oracle_hash,
  r.review_status,
  r.execution_status
FROM public.card_battle_rules r
JOIN public.cards c
  ON lower(c.name) = r.normalized_name
WHERE r.normalized_name = 'seething song'
  AND r.logical_rule_key = 'battle_rule_v1:3eb15dc581c6b913158f9b63c023f3d7';
