-- PG780B trusted oracle_hash backfill precheck.
-- Target: new-server PostgreSQL via server/bin/with_new_server_pg.sh.

WITH target AS (
  SELECT
    br.normalized_name,
    br.card_name,
    br.logical_rule_key,
    br.source,
    br.review_status,
    br.execution_status,
    md5(c.oracle_text) AS expected_oracle_hash
  FROM public.card_battle_rules br
  JOIN public.cards c ON c.id = br.card_id
  WHERE br.source = 'curated'
    AND br.review_status IN ('verified', 'active')
    AND br.execution_status = 'auto'
    AND COALESCE(br.oracle_hash, '') = ''
    AND COALESCE(c.oracle_text, '') <> ''
)
SELECT
  COUNT(*) AS target_rows,
  COUNT(DISTINCT normalized_name) AS target_normalized_names,
  COUNT(DISTINCT expected_oracle_hash) AS distinct_expected_hashes
FROM target;

SELECT
  normalized_name,
  card_name,
  logical_rule_key,
  expected_oracle_hash
FROM (
  SELECT
    br.normalized_name,
    br.card_name,
    br.logical_rule_key,
    md5(c.oracle_text) AS expected_oracle_hash
  FROM public.card_battle_rules br
  JOIN public.cards c ON c.id = br.card_id
  WHERE br.source = 'curated'
    AND br.review_status IN ('verified', 'active')
    AND br.execution_status = 'auto'
    AND COALESCE(br.oracle_hash, '') = ''
    AND COALESCE(c.oracle_text, '') <> ''
) target
ORDER BY card_name, logical_rule_key;
