\echo 'PG833B trusted rule oracle_hash backfill postcheck'

WITH backup AS (
  SELECT *
  FROM manaloom_deploy_audit.pg833b_trusted_rule_oracle_hash_backfill_new_server_20260712
),
remaining AS (
  SELECT COUNT(*) AS rows
  FROM public.card_battle_rules br
  JOIN public.cards c ON c.id = br.card_id
  WHERE br.source IN ('curated', 'manual')
    AND br.review_status IN ('verified', 'active')
    AND br.execution_status IN ('auto', 'executable')
    AND COALESCE(br.oracle_hash, '') = ''
    AND COALESCE(BTRIM(c.oracle_text), '') <> ''
),
updated AS (
  SELECT COUNT(*) AS rows
  FROM public.card_battle_rules br
  JOIN public.cards c ON c.id = br.card_id
  JOIN backup b
    ON b.card_id = br.card_id
   AND b.normalized_name = br.normalized_name
   AND b.logical_rule_key = br.logical_rule_key
   AND b.source = br.source
  WHERE br.oracle_hash = md5(c.oracle_text)
)
SELECT
  (SELECT rows FROM remaining) AS trusted_executable_rules_missing_oracle_hash,
  (SELECT COUNT(*) FROM backup) AS backup_rows,
  (SELECT rows FROM updated) AS updated_rows_with_current_oracle_hash;

SELECT
  br.card_name,
  br.normalized_name,
  br.source,
  br.review_status,
  br.execution_status,
  br.logical_rule_key
FROM public.card_battle_rules br
JOIN public.cards c ON c.id = br.card_id
WHERE br.source IN ('curated', 'manual')
  AND br.review_status IN ('verified', 'active')
  AND br.execution_status IN ('auto', 'executable')
  AND COALESCE(br.oracle_hash, '') = ''
  AND COALESCE(BTRIM(c.oracle_text), '') <> ''
ORDER BY br.card_name, br.logical_rule_key
LIMIT 80;
