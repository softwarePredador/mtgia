\echo 'PG819 trusted rule oracle_hash backfill postcheck'

WITH backup AS (
  SELECT *
  FROM manaloom_deploy_audit.pg819_trusted_rule_oracle_hash_backfill_new_server_20260712
),
remaining AS (
  SELECT COUNT(*) AS rows
  FROM public.card_battle_rules br
  JOIN public.cards c ON c.id = br.card_id
  WHERE br.review_status = 'verified'
    AND br.execution_status = 'auto'
    AND COALESCE(BTRIM(br.oracle_hash), '') = ''
    AND NULLIF(BTRIM(c.oracle_text), '') IS NOT NULL
),
updated AS (
  SELECT COUNT(*) AS rows
  FROM public.card_battle_rules br
  JOIN public.cards c ON c.id = br.card_id
  JOIN backup b
    ON b.card_id = br.card_id
   AND b.normalized_name IS NOT DISTINCT FROM br.normalized_name
   AND b.logical_rule_key IS NOT DISTINCT FROM br.logical_rule_key
   AND b.source IS NOT DISTINCT FROM br.source
  WHERE br.oracle_hash = md5(c.oracle_text)
)
SELECT
  (SELECT rows FROM remaining) AS trusted_verified_auto_rules_missing_oracle_hash,
  (SELECT COUNT(*) FROM backup) AS backup_rows,
  (SELECT rows FROM updated) AS updated_rows_with_current_oracle_hash;

SELECT
  br.card_name,
  br.normalized_name,
  br.source,
  br.review_status,
  br.execution_status,
  br.logical_rule_key,
  br.effect_json ->> 'battle_model_scope' AS battle_model_scope
FROM public.card_battle_rules br
JOIN public.cards c ON c.id = br.card_id
WHERE br.review_status = 'verified'
  AND br.execution_status = 'auto'
  AND COALESCE(BTRIM(br.oracle_hash), '') = ''
  AND NULLIF(BTRIM(c.oracle_text), '') IS NOT NULL
ORDER BY br.card_name, br.logical_rule_key, br.source
LIMIT 120;
