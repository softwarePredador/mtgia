\echo 'PG857B trusted rule oracle_hash backfill precheck'

WITH missing AS (
  SELECT
    br.card_id,
    br.card_name,
    br.normalized_name,
    br.logical_rule_key,
    br.source,
    br.review_status,
    br.execution_status,
    br.rule_version
  FROM public.card_battle_rules br
  WHERE br.source IN ('curated', 'manual')
    AND br.review_status = 'verified'
    AND br.execution_status IN ('auto', 'executable')
    AND COALESCE(br.oracle_hash, '') = ''
),
matched AS (
  SELECT
    m.*,
    COUNT(c.id) FILTER (WHERE COALESCE(BTRIM(c.oracle_text), '') <> '') AS matched_card_rows,
    COUNT(DISTINCT md5(c.oracle_text)) FILTER (WHERE COALESCE(BTRIM(c.oracle_text), '') <> '') AS distinct_oracle_hashes,
    MIN(md5(c.oracle_text)) FILTER (WHERE COALESCE(BTRIM(c.oracle_text), '') <> '') AS proposed_oracle_hash
  FROM missing m
  LEFT JOIN public.cards c
    ON c.id = m.card_id
  GROUP BY
    m.card_id,
    m.card_name,
    m.normalized_name,
    m.logical_rule_key,
    m.source,
    m.review_status,
    m.execution_status,
    m.rule_version
)
SELECT
  COUNT(*) AS missing_verified_executable_rows,
  COUNT(*) FILTER (
    WHERE matched_card_rows = 1
      AND distinct_oracle_hashes = 1
      AND proposed_oracle_hash IS NOT NULL
  ) AS safe_to_backfill,
  COUNT(*) FILTER (
    WHERE matched_card_rows <> 1
       OR distinct_oracle_hashes <> 1
       OR proposed_oracle_hash IS NULL
  ) AS unsafe_to_backfill
FROM matched;

SELECT EXISTS (
  SELECT 1
  FROM information_schema.tables
  WHERE table_schema = 'manaloom_deploy_audit'
    AND table_name = 'pg857b_trusted_rule_oracle_hash_backfill_new_server_20260713'
) AS backup_table_already_exists;

WITH missing AS (
  SELECT
    br.card_id,
    br.card_name,
    br.normalized_name,
    br.logical_rule_key,
    br.source,
    br.review_status,
    br.execution_status,
    br.rule_version
  FROM public.card_battle_rules br
  WHERE br.source IN ('curated', 'manual')
    AND br.review_status = 'verified'
    AND br.execution_status IN ('auto', 'executable')
    AND COALESCE(br.oracle_hash, '') = ''
),
matched AS (
  SELECT
    m.*,
    c.name AS matched_card_name,
    md5(c.oracle_text) AS proposed_oracle_hash
  FROM missing m
  LEFT JOIN public.cards c
    ON c.id = m.card_id
   AND COALESCE(BTRIM(c.oracle_text), '') <> ''
)
SELECT
  card_name,
  normalized_name,
  logical_rule_key,
  source,
  rule_version,
  matched_card_name,
  proposed_oracle_hash
FROM matched
ORDER BY card_name, logical_rule_key;
