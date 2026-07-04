WITH remaining AS (
  SELECT r.*
  FROM public.card_battle_rules r
  JOIN public.cards c
    ON c.id = r.card_id
  WHERE r.source IN ('curated', 'manual')
    AND r.review_status IN ('verified', 'active')
    AND r.execution_status IN ('auto', 'executable')
    AND coalesce(r.oracle_hash, '') = ''
    AND coalesce(c.oracle_text, '') <> ''
),
backup AS (
  SELECT *
  FROM manaloom_deploy_audit.pg420b_oracle_hash_integrity_backfill_new_server_20260704
),
restored AS (
  SELECT r.*
  FROM public.card_battle_rules r
  JOIN backup b
    ON b.normalized_name = r.normalized_name
   AND b.logical_rule_key = r.logical_rule_key
  WHERE coalesce(r.oracle_hash, '') <> ''
)
SELECT
  (SELECT count(*) FROM backup) AS backup_rows,
  (SELECT count(*) FROM restored) AS restored_rows,
  (SELECT count(*) FROM remaining) AS remaining_missing_hash_rows;

SELECT
  r.card_name,
  r.normalized_name,
  r.logical_rule_key,
  r.oracle_hash
FROM public.card_battle_rules r
JOIN manaloom_deploy_audit.pg420b_oracle_hash_integrity_backfill_new_server_20260704 b
  ON b.normalized_name = r.normalized_name
 AND b.logical_rule_key = r.logical_rule_key
ORDER BY r.normalized_name, r.logical_rule_key
LIMIT 80;
