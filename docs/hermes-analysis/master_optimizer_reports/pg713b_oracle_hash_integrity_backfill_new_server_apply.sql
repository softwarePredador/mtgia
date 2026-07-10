BEGIN;

CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit;

CREATE TABLE manaloom_deploy_audit.pg713b_oracle_hash_integrity_backfill_20260710 AS
WITH candidate_hashes AS (
  SELECT
    r.normalized_name,
    r.logical_rule_key,
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
  GROUP BY r.normalized_name, r.logical_rule_key
), safe_candidates AS (
  SELECT normalized_name, logical_rule_key, oracle_hash
  FROM candidate_hashes
  WHERE distinct_hashes = 1
)
SELECT r.*
FROM public.card_battle_rules r
JOIN safe_candidates s
  ON s.normalized_name = r.normalized_name
 AND s.logical_rule_key = r.logical_rule_key;

WITH candidate_hashes AS (
  SELECT
    r.normalized_name,
    r.logical_rule_key,
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
  GROUP BY r.normalized_name, r.logical_rule_key
), safe_candidates AS (
  SELECT normalized_name, logical_rule_key, oracle_hash
  FROM candidate_hashes
  WHERE distinct_hashes = 1
), updated AS (
  UPDATE public.card_battle_rules r
     SET oracle_hash = s.oracle_hash,
         updated_at = CURRENT_TIMESTAMP
    FROM safe_candidates s
   WHERE r.normalized_name = s.normalized_name
     AND r.logical_rule_key = s.logical_rule_key
     AND r.review_status IN ('verified', 'active')
     AND r.execution_status = 'auto'
     AND coalesce(r.oracle_hash, '') = ''
   RETURNING r.normalized_name, r.logical_rule_key
)
SELECT count(*) AS updated_rows
FROM updated;

COMMIT;
