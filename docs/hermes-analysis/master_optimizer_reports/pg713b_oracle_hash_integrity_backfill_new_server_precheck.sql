WITH candidate_hashes AS (
  SELECT
    r.normalized_name,
    r.logical_rule_key,
    r.card_name,
    r.review_status,
    r.execution_status,
    count(DISTINCT md5(c.oracle_text)) AS distinct_hashes,
    min(md5(c.oracle_text)) AS oracle_hash
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
  GROUP BY r.normalized_name, r.logical_rule_key, r.card_name, r.review_status, r.execution_status
), safe_candidates AS (
  SELECT *
  FROM candidate_hashes
  WHERE distinct_hashes = 1
)
SELECT review_status, count(*) AS safe_backfill_rows
FROM safe_candidates
GROUP BY review_status
ORDER BY review_status;

WITH candidate_hashes AS (
  SELECT
    r.normalized_name,
    r.logical_rule_key,
    r.card_name,
    r.review_status,
    r.execution_status,
    count(DISTINCT md5(c.oracle_text)) AS distinct_hashes,
    min(md5(c.oracle_text)) AS oracle_hash
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
  GROUP BY r.normalized_name, r.logical_rule_key, r.card_name, r.review_status, r.execution_status
)
SELECT distinct_hashes, count(*) AS candidate_rows
FROM candidate_hashes
GROUP BY distinct_hashes
ORDER BY distinct_hashes;
