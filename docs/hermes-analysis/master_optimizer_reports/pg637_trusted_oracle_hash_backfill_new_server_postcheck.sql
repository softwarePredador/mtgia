WITH remaining AS (
  SELECT r.*
  FROM public.card_battle_rules r
  WHERE r.review_status IN ('verified', 'active')
    AND r.execution_status IN ('auto', 'executable')
    AND nullif(r.oracle_hash, '') IS NULL
),
updated AS (
  SELECT r.normalized_name, r.logical_rule_key, r.oracle_hash
  FROM public.card_battle_rules r
  JOIN manaloom_deploy_audit.pg637_trusted_oracle_hash_backfill_new_server_20260707_202000 b
    ON b.normalized_name = r.normalized_name
   AND b.logical_rule_key = r.logical_rule_key
)
SELECT
  (SELECT count(*) FROM manaloom_deploy_audit.pg637_trusted_oracle_hash_backfill_new_server_20260707_202000) AS backup_rows,
  (SELECT count(*) FROM updated) AS updated_rows,
  (SELECT count(*) FROM remaining) AS trusted_executable_rules_missing_oracle_hash;

SELECT
  r.normalized_name,
  r.card_name,
  r.logical_rule_key,
  r.oracle_hash,
  md5(coalesce(c.oracle_text, '')) AS expected_oracle_hash,
  r.oracle_hash = md5(coalesce(c.oracle_text, '')) AS hash_matches_cards_oracle
FROM public.card_battle_rules r
JOIN public.cards c
  ON c.id = r.card_id
JOIN manaloom_deploy_audit.pg637_trusted_oracle_hash_backfill_new_server_20260707_202000 b
  ON b.normalized_name = r.normalized_name
 AND b.logical_rule_key = r.logical_rule_key
ORDER BY r.normalized_name, r.logical_rule_key;
