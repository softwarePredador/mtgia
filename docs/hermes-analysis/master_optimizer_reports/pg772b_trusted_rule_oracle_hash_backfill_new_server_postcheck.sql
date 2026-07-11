WITH backup AS (
  SELECT *
  FROM manaloom_deploy_audit.pg772b_trusted_rule_oracle_hash_backfill_new_server_20260711
),
remaining AS (
  SELECT count(*) AS rows
  FROM public.card_battle_rules r
  WHERE r.source IN ('curated', 'manual')
    AND r.review_status IN ('verified', 'active')
    AND r.execution_status IN ('auto', 'executable')
    AND coalesce(r.oracle_hash, '') = ''
),
updated AS (
  SELECT count(*) AS rows
  FROM public.card_battle_rules r
  JOIN public.cards c
    ON c.id = r.card_id
  JOIN backup b
    ON b.normalized_name = r.normalized_name
   AND b.logical_rule_key = r.logical_rule_key
  WHERE coalesce(r.oracle_hash, '') = md5(coalesce(c.oracle_text, ''))
)
SELECT
  (SELECT rows FROM remaining) AS trusted_executable_rules_missing_oracle_hash,
  (SELECT count(*) FROM backup) AS backup_rows,
  (SELECT rows FROM updated) AS updated_rows_with_current_oracle_hash;
