\echo 'PG716b trusted rule oracle_hash backfill precheck'

WITH missing AS (
  SELECT normalized_name, logical_rule_key
  FROM public.card_battle_rules
  WHERE review_status IN ('verified', 'active')
    AND execution_status = 'auto'
    AND coalesce(oracle_hash, '') = ''
), candidate_hashes AS (
  SELECT
    r.normalized_name,
    r.logical_rule_key,
    count(DISTINCT md5(c.oracle_text)) AS distinct_hashes,
    min(md5(c.oracle_text)) AS oracle_hash,
    count(c.*) AS matched_card_rows
  FROM public.card_battle_rules r
  JOIN public.cards c
    ON (
      r.card_id = c.id
      OR r.normalized_name = lower(trim(c.name))
      OR r.normalized_name = lower(trim(split_part(c.name, ' // ', 1)))
    )
  WHERE r.review_status IN ('verified', 'active')
    AND r.execution_status = 'auto'
    AND coalesce(r.oracle_hash, '') = ''
    AND coalesce(c.oracle_text, '') <> ''
  GROUP BY r.normalized_name, r.logical_rule_key
), safe_candidates AS (
  SELECT normalized_name, logical_rule_key, oracle_hash, matched_card_rows
  FROM candidate_hashes
  WHERE distinct_hashes = 1
), unsafe_candidates AS (
  SELECT normalized_name, logical_rule_key, distinct_hashes
  FROM candidate_hashes
  WHERE distinct_hashes <> 1
)
SELECT
  (SELECT count(*) FROM missing) AS trusted_auto_missing_hash_rows,
  (SELECT count(*) FROM safe_candidates) AS safe_backfillable_rows,
  (SELECT coalesce(sum(matched_card_rows), 0) FROM safe_candidates) AS matched_card_rows,
  (SELECT count(*) FROM unsafe_candidates) AS unsafe_distinct_hash_rows,
  (
    SELECT count(*)
    FROM missing m
    LEFT JOIN candidate_hashes c
      ON c.normalized_name = m.normalized_name
     AND c.logical_rule_key = m.logical_rule_key
    WHERE c.logical_rule_key IS NULL
  ) AS unmatched_missing_hash_rows;

WITH candidate_hashes AS (
  SELECT
    r.normalized_name,
    r.logical_rule_key,
    count(DISTINCT md5(c.oracle_text)) AS distinct_hashes,
    min(md5(c.oracle_text)) AS oracle_hash,
    count(c.*) AS matched_card_rows
  FROM public.card_battle_rules r
  JOIN public.cards c
    ON (
      r.card_id = c.id
      OR r.normalized_name = lower(trim(c.name))
      OR r.normalized_name = lower(trim(split_part(c.name, ' // ', 1)))
    )
  WHERE r.review_status IN ('verified', 'active')
    AND r.execution_status = 'auto'
    AND coalesce(r.oracle_hash, '') = ''
    AND coalesce(c.oracle_text, '') <> ''
  GROUP BY r.normalized_name, r.logical_rule_key
)
SELECT
  normalized_name,
  logical_rule_key,
  matched_card_rows,
  oracle_hash
FROM candidate_hashes
WHERE distinct_hashes = 1
ORDER BY normalized_name, logical_rule_key
LIMIT 80;
