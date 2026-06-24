SELECT
  count(*) FILTER (
    WHERE r.oracle_hash = md5(coalesce(c.oracle_text, ''))
  ) AS matching_oracle_hash_rows,
  count(*) FILTER (
    WHERE r.review_status = 'verified' AND r.execution_status = 'auto'
  ) AS verified_auto_rows,
  (SELECT count(*) FROM manaloom_deploy_audit.pg182_seething_song_oracle_hash_20260624) AS backup_rows
FROM public.card_battle_rules r
JOIN public.cards c
  ON lower(c.name) = r.normalized_name
WHERE r.normalized_name = 'seething song'
  AND r.logical_rule_key = 'battle_rule_v1:3eb15dc581c6b913158f9b63c023f3d7';
