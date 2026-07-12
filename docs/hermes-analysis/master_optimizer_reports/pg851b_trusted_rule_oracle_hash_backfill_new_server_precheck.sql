\echo 'PG851B trusted rule oracle_hash backfill precheck'

WITH missing AS (
  SELECT
    br.ctid AS br_ctid,
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
    c.id AS matched_card_id,
    c.name AS matched_card_name,
    md5(c.oracle_text) AS proposed_oracle_hash,
    COUNT(c.id) OVER (PARTITION BY m.br_ctid) AS match_count
  FROM missing m
  LEFT JOIN public.cards c
    ON (
         m.card_id IS NOT NULL AND c.id = m.card_id
       )
    OR (
         m.card_id IS NULL
         AND (
           lower(c.name) = m.normalized_name
           OR split_part(lower(c.name), ' // ', 1) = m.normalized_name
         )
       )
   AND COALESCE(BTRIM(c.oracle_text), '') <> ''
)
SELECT
  COUNT(*) AS missing_verified_executable_rows,
  COUNT(*) FILTER (WHERE match_count = 1 AND proposed_oracle_hash IS NOT NULL) AS uniquely_matchable_with_oracle,
  COUNT(*) FILTER (WHERE match_count <> 1 OR proposed_oracle_hash IS NULL) AS not_safe_to_backfill
FROM matched;

SELECT EXISTS (
  SELECT 1
  FROM information_schema.tables
  WHERE table_schema = 'manaloom_deploy_audit'
    AND table_name = 'pg851b_trusted_rule_oracle_hash_backfill_new_server_20260712'
) AS backup_table_already_exists;

WITH missing AS (
  SELECT
    br.ctid AS br_ctid,
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
    md5(c.oracle_text) AS proposed_oracle_hash,
    COUNT(c.id) OVER (PARTITION BY m.br_ctid) AS match_count
  FROM missing m
  LEFT JOIN public.cards c
    ON (
         m.card_id IS NOT NULL AND c.id = m.card_id
       )
    OR (
         m.card_id IS NULL
         AND (
           lower(c.name) = m.normalized_name
           OR split_part(lower(c.name), ' // ', 1) = m.normalized_name
         )
       )
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
