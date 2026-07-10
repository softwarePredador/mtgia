WITH remaining AS (
  SELECT cbr.*
  FROM public.card_battle_rules cbr
  WHERE cbr.review_status IN ('verified', 'active')
    AND cbr.execution_status IN ('auto', 'executable')
    AND COALESCE(btrim(cbr.oracle_hash), '') = ''
)
SELECT count(*) AS trusted_executable_rules_missing_oracle_hash
FROM remaining;

SELECT
  count(*) AS backup_rows
FROM manaloom_deploy_audit.pg722b_trusted_oracle_hash_backfill_20260710;

SELECT
  cbr.card_name,
  cbr.normalized_name,
  cbr.logical_rule_key,
  cbr.oracle_hash,
  md5(c.oracle_text) AS expected_oracle_hash,
  (cbr.oracle_hash = md5(c.oracle_text)) AS hash_matches
FROM public.card_battle_rules cbr
JOIN public.cards c ON c.id = cbr.card_id
JOIN manaloom_deploy_audit.pg722b_trusted_oracle_hash_backfill_20260710 b
  ON b.normalized_name = cbr.normalized_name
 AND b.logical_rule_key = cbr.logical_rule_key
ORDER BY cbr.normalized_name, cbr.logical_rule_key;
