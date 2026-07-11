WITH remaining AS (
  SELECT
    r.card_name,
    r.normalized_name,
    r.logical_rule_key,
    r.review_status,
    r.execution_status,
    r.rule_version,
    r.source
  FROM public.card_battle_rules r
  WHERE r.execution_status = 'auto'
    AND r.review_status IN ('verified', 'active')
    AND nullif(r.oracle_hash, '') IS NULL
)
SELECT count(*) AS trusted_executable_rules_missing_oracle_hash
FROM remaining;

SELECT
  count(*) AS backup_rows
FROM manaloom_deploy_audit.pg747_hash_backfill_20260711_0730;

SELECT
  r.card_name,
  r.normalized_name,
  r.logical_rule_key,
  r.oracle_hash,
  md5(coalesce(c.oracle_text, '')) AS current_oracle_hash,
  (r.oracle_hash = md5(coalesce(c.oracle_text, ''))) AS hash_matches_current_oracle
FROM public.card_battle_rules r
JOIN manaloom_deploy_audit.pg747_hash_backfill_20260711_0730 b
  ON b.normalized_name = r.normalized_name
 AND b.logical_rule_key = r.logical_rule_key
JOIN public.cards c
  ON c.id = r.card_id
ORDER BY r.normalized_name, r.logical_rule_key
LIMIT 80;
