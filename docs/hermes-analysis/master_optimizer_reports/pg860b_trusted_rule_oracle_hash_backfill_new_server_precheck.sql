\echo 'PG860B trusted rule oracle_hash backfill precheck'

WITH target AS (
  SELECT
    br.card_id,
    br.normalized_name,
    br.card_name,
    br.logical_rule_key,
    br.source,
    br.review_status,
    br.execution_status,
    br.rule_version,
    br.oracle_hash AS old_oracle_hash,
    md5(c.oracle_text) AS new_oracle_hash,
    c.oracle_text
  FROM public.card_battle_rules br
  JOIN public.cards c ON c.id = br.card_id
  WHERE br.source IN ('curated', 'manual')
    AND br.review_status IN ('verified', 'active')
    AND br.execution_status IN ('auto', 'executable')
    AND COALESCE(br.oracle_hash, '') = ''
    AND COALESCE(BTRIM(c.oracle_text), '') <> ''
)
SELECT
  COUNT(*) AS would_backfill_rows,
  COUNT(DISTINCT card_id) AS distinct_cards,
  COUNT(DISTINCT (card_id, normalized_name, logical_rule_key, source)) AS distinct_rule_keys,
  COUNT(*) FILTER (WHERE review_status = 'verified') AS verified_rows,
  COUNT(*) FILTER (WHERE review_status = 'active') AS active_rows,
  COUNT(*) FILTER (WHERE old_oracle_hash IS NULL) AS null_hash_rows,
  COUNT(*) FILTER (WHERE old_oracle_hash = '') AS empty_hash_rows,
  COUNT(*) FILTER (WHERE new_oracle_hash = md5('')) AS empty_oracle_hash_rows
FROM target;

SELECT EXISTS (
  SELECT 1
  FROM information_schema.tables
  WHERE table_schema = 'manaloom_deploy_audit'
    AND table_name = 'pg860b_trusted_rule_oracle_hash_backfill_new_server_20260713'
) AS backup_table_already_exists;

WITH target AS (
  SELECT
    br.card_name,
    br.normalized_name,
    br.source,
    br.review_status,
    br.execution_status,
    br.rule_version,
    br.logical_rule_key,
    md5(c.oracle_text) AS new_oracle_hash
  FROM public.card_battle_rules br
  JOIN public.cards c ON c.id = br.card_id
  WHERE br.source IN ('curated', 'manual')
    AND br.review_status IN ('verified', 'active')
    AND br.execution_status IN ('auto', 'executable')
    AND COALESCE(br.oracle_hash, '') = ''
    AND COALESCE(BTRIM(c.oracle_text), '') <> ''
)
SELECT *
FROM target
ORDER BY card_name, logical_rule_key
LIMIT 80;
