WITH remaining AS (
  SELECT count(*) AS rows
  FROM public.card_battle_rules r
  WHERE r.review_status IN ('verified', 'active')
    AND r.execution_status = 'auto'
    AND nullif(btrim(coalesce(r.oracle_hash, '')), '') IS NULL
),
backup AS (
  SELECT count(*) AS rows
  FROM manaloom_deploy_audit.pg764b_trusted_rule_oracle_hash_backfill_new_server_20260711
),
updated AS (
  SELECT count(*) AS rows
  FROM public.card_battle_rules r
  JOIN public.cards c ON c.id = r.card_id
  JOIN manaloom_deploy_audit.pg764b_trusted_rule_oracle_hash_backfill_new_server_20260711 b
    ON b.normalized_name = r.normalized_name
   AND b.logical_rule_key = r.logical_rule_key
  WHERE r.oracle_hash = md5(coalesce(c.oracle_text, ''))
)
SELECT
  (SELECT rows FROM remaining) AS trusted_executable_rules_missing_oracle_hash,
  (SELECT rows FROM backup) AS backup_rows,
  (SELECT rows FROM updated) AS updated_rows_with_current_oracle_hash;
