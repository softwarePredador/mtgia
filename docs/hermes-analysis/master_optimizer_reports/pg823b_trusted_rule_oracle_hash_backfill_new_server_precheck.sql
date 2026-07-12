\echo 'PG823B trusted rule oracle_hash backfill precheck'

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
  WHERE br.review_status = 'verified'
    AND br.execution_status = 'auto'
    AND COALESCE(br.oracle_hash, '') = ''
    AND COALESCE(BTRIM(c.oracle_text), '') <> ''
),
hash_groups AS (
  SELECT
    normalized_name,
    logical_rule_key,
    COUNT(DISTINCT new_oracle_hash) AS distinct_hashes
  FROM target
  GROUP BY normalized_name, logical_rule_key
)
SELECT
  COUNT(*) AS would_backfill_rows,
  COUNT(DISTINCT card_id) AS distinct_cards,
  COUNT(DISTINCT (normalized_name, logical_rule_key)) AS distinct_rule_keys,
  COUNT(*) FILTER (WHERE old_oracle_hash IS NULL) AS null_hash_rows,
  COUNT(*) FILTER (WHERE old_oracle_hash = '') AS empty_hash_rows,
  COUNT(*) FILTER (WHERE new_oracle_hash = md5('')) AS empty_oracle_hash_rows,
  (SELECT COUNT(*) FROM hash_groups WHERE distinct_hashes = 1) AS safe_hash_groups,
  (SELECT COUNT(*) FROM hash_groups WHERE distinct_hashes <> 1) AS unsafe_hash_groups
FROM target;

SELECT EXISTS (
  SELECT 1
  FROM information_schema.tables
  WHERE table_schema = 'manaloom_deploy_audit'
    AND table_name = 'pg823b_trusted_rule_oracle_hash_backfill_new_server_20260712'
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
  WHERE br.review_status = 'verified'
    AND br.execution_status = 'auto'
    AND COALESCE(br.oracle_hash, '') = ''
    AND COALESCE(BTRIM(c.oracle_text), '') <> ''
)
SELECT *
FROM target
ORDER BY card_name, logical_rule_key
LIMIT 80;
